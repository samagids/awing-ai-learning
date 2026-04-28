#!/usr/bin/env python
"""
Coqui TTS VITS training for Awing — Session 54.

Why Coqui (not HuggingFace VitsModel):
  Session 53 attempted VITS fine-tuning via HF VitsModel and the model
  collapsed to silence. Root cause: HF VitsModel is INFERENCE-ONLY — it
  does not expose adversarial / KL / mel-recon losses, so our training
  loop only had a weak waveform regulariser to optimise.

  Coqui TTS ships the full VITS training stack:
    - HiFi-GAN MPD + MSD discriminators (adversarial loss)
    - KL divergence between posterior and prior
    - Mel-spectrogram reconstruction loss
    - Feature-matching loss
    - Monotonic Alignment Search

Honesty caveat:
  We have ~197 recordings (≈5 minutes of audio). Coqui VITS recipes
  typically expect 1-10 hours. We may overfit or produce noise.
  The synthesize step measures peak amplitude on the 20 held-out test
  clips and prints a fail-loud banner if more than a third are silent.

Test set hygiene:
  20 held-out words at training_data/test_recordings/shortlist.json
  are EXCLUDED from training so the bake-off measures generalization,
  not memorization. Disjointness is enforced inside cmd_train.

Run order (Windows):
  python -m venv venv_coqui
  venv_coqui\\Scripts\\pip install -r scripts\\requirements_coqui.txt
  python scripts\\train_coqui_vits.py clean       # wipe stale S53 bake-off output
  python scripts\\train_coqui_vits.py train
  python scripts\\train_coqui_vits.py synthesize
  python scripts\\bakeoff.py variant-a
  python scripts\\bakeoff.py variant-c
  python scripts\\bakeoff.py html
  start training_data\\test_recordings\\bakeoff.html
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import unicodedata
from pathlib import Path

# ---------- Auto-venv activation (matches existing scripts) ----------
_VENV_NAME = "venv_coqui"
_REPO_ROOT = Path(__file__).resolve().parent.parent
_VENV_PY = _REPO_ROOT / _VENV_NAME / "Scripts" / "python.exe"


def _in_venv_coqui() -> bool:
    try:
        return os.path.abspath(sys.executable) == os.path.abspath(str(_VENV_PY))
    except Exception:
        return False


if not _in_venv_coqui():
    if _VENV_PY.exists():
        print(f"[coqui-vits] Re-exec via {_VENV_PY}")
        result = subprocess.run([str(_VENV_PY), __file__] + sys.argv[1:])
        sys.exit(result.returncode)
    else:
        print(f"[coqui-vits] ERROR: {_VENV_PY} not found.")
        print("Create the venv first (one-time):")
        print(f"  python -m venv {_VENV_NAME}")
        print(
            f"  {_VENV_NAME}\\Scripts\\pip install -r scripts\\requirements_coqui.txt"
        )
        sys.exit(1)

# ---------- Paths ----------
REPO = Path(__file__).resolve().parent.parent
TRAIN_DIR = REPO / "training_data" / "recordings"
MANIFEST = TRAIN_DIR / "manifest.json"
TEST_DIR = REPO / "training_data" / "test_recordings"
SHORTLIST = TEST_DIR / "shortlist.json"
COQUI_TRAIN_DIR = REPO / "training_data" / "_coqui_train"
COQUI_WAVS = COQUI_TRAIN_DIR / "wavs"
METADATA_CSV = COQUI_TRAIN_DIR / "metadata.csv"
CKPT_DIR = REPO / "models" / "awing_coqui_vits"
BAKEOFF_DIR = REPO / "training_data" / "test_recordings" / "bakeoff"
VITS_RAW_DIR = BAKEOFF_DIR / "_vits_raw"
BAKEOFF_HTML = REPO / "training_data" / "test_recordings" / "bakeoff.html"

SAMPLE_RATE = 22050

# Awing characters AFTER NFD diacritic stripping. We keep base specials
# (ɛ ɔ ə ɨ ŋ ɣ) and the apostrophe used for glottal stops.
AWING_CHARS = "abcdefghijklmnopqrstuvwxyzɛɔəɨŋɣ'"
AWING_PUNCS = " .,!?"


# ---------- Awing text normalisation ----------
def awing_to_train_text(s: str) -> str:
    """
    Coqui VITS trains on character sequences directly.
    We strip tone diacritics (combining marks) but preserve the base
    Awing characters. Tone modelling would need an explicit tone phoneme
    set or IPA — out of scope for a 197-clip training run.
    """
    if not s:
        return ""
    decomposed = unicodedata.normalize("NFD", s)
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return stripped.lower()


# ---------- cmd_train ----------
def cmd_train(args):
    print("=" * 64)
    print("Coqui TTS VITS training — Awing (Session 54)")
    print("=" * 64)

    # 1. Load manifest
    if not MANIFEST.exists():
        print(f"✗ ERROR: Training manifest not found at {MANIFEST}")
        print("  Record audio first via: python scripts\\record_audio.py")
        return False
    with open(MANIFEST, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    if isinstance(manifest, dict):
        # Some manifests use {key: entry, ...} shape
        manifest = list(manifest.values())
    print(f"✓ Loaded manifest: {len(manifest)} clips")

    # 2. Disjoint test-set hygiene
    test_keys: set[str] = set()
    if SHORTLIST.exists():
        with open(SHORTLIST, "r", encoding="utf-8") as f:
            sl_data = json.load(f)
        # shortlist.json is {description, coverage_buckets, shortlist: [...], ...}
        # The actual list of held-out words lives under the "shortlist" key.
        items = sl_data.get("shortlist") if isinstance(sl_data, dict) else sl_data
        if items is None:
            items = []
        for item in items:
            if isinstance(item, dict):
                k = item.get("key")
                if k:
                    test_keys.add(k)
            elif isinstance(item, str):
                test_keys.add(item)
        print(f"✓ Loaded test shortlist: {len(test_keys)} held-out words")
    else:
        print(f"⚠ No shortlist at {SHORTLIST} — all training data will be used")

    filtered = [c for c in manifest if c.get("key") not in test_keys]
    dropped = len(manifest) - len(filtered)
    if dropped:
        print(f"✓ Dropped {dropped} clips overlapping with test set")
    print(f"✓ Training pool: {len(filtered)} clips")

    if len(filtered) < 100:
        bar = "!" * 64
        approx_min = len(filtered) * 1.5 / 60
        print()
        print(bar)
        print(f"! WARNING: only {len(filtered)} training clips (~{approx_min:.1f} min audio).")
        print("! Coqui VITS recipes expect 1-10 hours. Expect noise, not speech.")
        print("! Proceeding anyway so you can see what the data ceiling looks like.")
        print(bar)
        print()

    # 3. Resample + write LJSpeech format
    COQUI_WAVS.mkdir(parents=True, exist_ok=True)

    try:
        import librosa
        import numpy as np
        import soundfile as sf
    except ImportError as e:
        print(f"✗ ERROR: Missing audio dep: {e}")
        print("  venv_coqui\\Scripts\\pip install -r scripts\\requirements_coqui.txt")
        return False

    print(f"\nResampling clips → {SAMPLE_RATE} Hz mono PCM16 → {COQUI_WAVS}")
    meta_rows: list[str] = []
    n_written = 0
    n_silent = 0
    n_missing = 0
    n_no_key = 0
    n_no_text = 0
    n_no_src = 0
    for entry in filtered:
        key = entry.get("key")
        text = entry.get("text") or entry.get("awing") or ""
        # record_audio.py writes "wav_path" (relative to repo root). Older
        # manifests may use "wav" / "path" / "file"; accept all.
        src = (
            entry.get("wav_path")
            or entry.get("wav")
            or entry.get("path")
            or entry.get("file")
        )
        if not key:
            n_no_key += 1
            continue
        if not text:
            n_no_text += 1
            continue
        if not src:
            n_no_src += 1
            continue
        src_path = Path(src)
        if not src_path.is_absolute():
            # Try interpreting as: (a) repo-relative, (b) TRAIN_DIR-relative,
            # (c) bare filename next to the manifest.
            for cand in (REPO / src_path, TRAIN_DIR / src_path, TRAIN_DIR / src_path.name):
                if cand.exists():
                    src_path = cand
                    break
            else:
                src_path = REPO / src_path  # for the missing-warning message
        if not src_path.exists():
            n_missing += 1
            print(f"  ⚠ Missing: {src}")
            continue

        try:
            audio, _ = librosa.load(str(src_path), sr=SAMPLE_RATE, mono=True)
        except Exception as e:
            print(f"  ⚠ Failed to load {src_path.name}: {e}")
            continue

        peak = float(np.max(np.abs(audio))) if audio.size else 0.0
        if peak < 1e-4:
            n_silent += 1
            continue
        audio = (audio / peak * 0.95).astype(np.float32)

        out_wav = COQUI_WAVS / f"{key}.wav"
        sf.write(str(out_wav), audio, SAMPLE_RATE, subtype="PCM_16")

        norm = awing_to_train_text(text)
        if not norm:
            continue
        # LJSpeech format: filename_no_ext|transcript|normalised_transcript
        meta_rows.append(f"{key}|{norm}|{norm}")
        n_written += 1

    print(f"  Wrote: {n_written}   silent-skipped: {n_silent}   missing: {n_missing}")
    if n_no_key or n_no_text or n_no_src:
        print(f"  Dropped for missing fields — no-key: {n_no_key}  "
              f"no-text: {n_no_text}  no-src: {n_no_src}")
    if n_written == 0:
        print("\n✗ ERROR: No training clips written. Aborting.")
        if n_no_src:
            print(f"  {n_no_src} entries had no source field. Manifest keys expected:")
            print(f"    wav_path / wav / path / file")
            print(f"  Inspect: python -c \"import json; print(json.load(open('training_data/recordings/manifest.json'))[0])\"")
        return False

    METADATA_CSV.write_text("\n".join(meta_rows) + "\n", encoding="utf-8")
    print(f"✓ Wrote {METADATA_CSV} with {n_written} rows")

    # 4. Coqui VITS configuration
    try:
        from TTS.tts.configs.shared_configs import (
            BaseDatasetConfig,
            CharactersConfig,
        )
        from TTS.tts.configs.vits_config import VitsConfig
        # coqpit-config 0.2.x is strict — sub-configs MUST be Coqpit instances,
        # not plain dicts. VitsAudioConfig lives in the same module as VitsConfig.
        from TTS.tts.configs.vits_config import VitsAudioConfig
        from TTS.tts.datasets import load_tts_samples
        from TTS.tts.models.vits import Vits
        from TTS.tts.utils.text.tokenizer import TTSTokenizer
        from TTS.utils.audio import AudioProcessor
        from trainer import Trainer, TrainerArgs
    except ImportError as e:
        # coqui-tts forked Coqpit → coqpit-config. If both / the wrong one is
        # installed, the error message from coqui-tts itself reads:
        #   "coqui-tts switched to a forked version of Coqpit, but you still
        #    have the original package installed. Run:
        #      pip uninstall coqpit
        #      pip install coqpit-config"
        # Auto-repair: do a THOROUGH swap and then tell the user to re-run.
        # We do NOT retry in-process because:
        #   1. Uninstalling coqpit can leave behind a namespace-package
        #      directory in site-packages (no __init__.py), which makes
        #      Python resolve `import coqpit` to a phantom location without
        #      Coqpit class. Error reads "Coqpit (unknown location)".
        #   2. `sys.modules` caches partial-import state from the first
        #      failed attempt that cannot be reliably cleared.
        # A fresh interpreter process always works, so we bail with a
        # clear "re-run the command" message after doing the pip work.
        msg = str(e)
        if "Coqpit" in msg or "coqpit" in msg:
            print(f"\n⚠ Coqpit/coqpit-config conflict detected; auto-repairing...")
            py = sys.executable
            req_path = REPO / "scripts" / "requirements_coqui.txt"

            def _verify() -> tuple[bool, str, str]:
                """Spawn a fresh interpreter and test the import chain."""
                r = subprocess.run(
                    [py, "-c",
                     "from coqpit import Coqpit; "
                     "from TTS.tts.configs.vits_config import VitsConfig; "
                     "print('ok')"],
                    capture_output=True, text=True,
                )
                ok = r.returncode == 0 and "ok" in r.stdout
                return ok, r.stdout, r.stderr

            # ---- Helper: purge the coqpit namespace-package shadow ----
            # `pip uninstall coqpit` removes __init__.py + tracked files but
            # often leaves the empty `coqpit/` directory behind. A directory
            # without __init__.py is a valid Python namespace package, and
            # Python resolves `from coqpit import Coqpit` to it FIRST,
            # finds no Coqpit symbol, and raises ImportError forever — no
            # matter how many times you reinstall coqpit-config. Same
            # hazard applies to stale dist-info dirs that confuse pip's
            # next install. We must physically delete these between
            # uninstall and install for the swap to actually take effect.
            import shutil as _shutil
            import site as _site

            def _purge_coqpit_shadow() -> int:
                """Delete leftover coqpit/ namespace dir + dist-info shards.

                Walks every site-packages dir reachable from the venv python
                and removes anything that would shadow the real
                coqpit-config package. Returns count of items removed.
                """
                sp_dirs = []
                try:
                    sp_dirs = list(_site.getsitepackages())
                except Exception:
                    pass
                # Defensive: also include the venv's own Lib\site-packages
                # in case getsitepackages() missed it.
                venv_sp = Path(py).resolve().parent.parent / "Lib" / "site-packages"
                if venv_sp.exists() and str(venv_sp) not in sp_dirs:
                    sp_dirs.append(str(venv_sp))

                purged = []
                for sp in sp_dirs:
                    sp_path = Path(sp)
                    if not sp_path.exists():
                        continue
                    # The namespace-shadow directory itself.
                    shadow = sp_path / "coqpit"
                    if shadow.exists():
                        try:
                            _shutil.rmtree(shadow, ignore_errors=True)
                            if not shadow.exists():
                                purged.append(shadow.name)
                        except Exception:
                            pass
                    # Stale dist-info dirs from either package — pip's
                    # next install gets confused if these survive a
                    # half-finished uninstall.
                    for pat in ("coqpit-*.dist-info",
                                "coqpit_config-*.dist-info"):
                        for di in sp_path.glob(pat):
                            try:
                                _shutil.rmtree(di, ignore_errors=True)
                                if not di.exists():
                                    purged.append(di.name)
                            except Exception:
                                pass
                return len(purged)

            try:
                # PASS 1 — light repair. Just swap the coqpit package; don't
                # touch coqui-tts/trainer because --no-deps on them would
                # leave their transitive deps out of sync.
                subprocess.run(
                    [py, "-m", "pip", "uninstall", "-y",
                     "coqpit", "coqpit-config"],
                    check=False,
                )
                # Critical: purge the namespace-package shadow that pip
                # uninstall doesn't clean up. Without this, the install
                # below "succeeds" but the import still fails.
                n_purged = _purge_coqpit_shadow()
                if n_purged:
                    print(f"  Purged {n_purged} namespace-shadow remnant(s)")
                subprocess.run(
                    [py, "-m", "pip", "install", "--quiet",
                     "--force-reinstall", "--no-deps", "coqpit-config"],
                    check=True,
                )
                ok, out, err = _verify()

                if not ok:
                    # Pass 1 (coqpit swap + namespace-shadow purge) wasn't
                    # enough. Show the ACTUAL verify stderr so we can see
                    # what's really failing — instead of blindly triggering
                    # a heavy `pip install --force-reinstall -r requirements`
                    # which on this Windows machine causes a cascade of
                    # `~xxx` rubble (Defender/WSearch/OneDrive-filter
                    # holding handles to native .pyd/.dll files mid-install)
                    # and never recovers.
                    print(f"\n✗ Pass 1 verify failed. Real error from a fresh interpreter:")
                    print(f"  ─────────────────────────────────────────────")
                    if out.strip():
                        print(f"  stdout: {out.strip()}")
                    if err.strip():
                        for line in err.strip().splitlines():
                            print(f"  {line}")
                    else:
                        print(f"  (no stderr — verify subprocess returned code {0 if ok else 'non-zero'})")
                    print(f"  ─────────────────────────────────────────────")
                    print(f"\n  Diagnosis steps from here, in order:")
                    print(f"    1. Read the stderr above. The ACTUAL failing import")
                    print(f"       tells you which package is broken.")
                    print(f"    2. If it's another package complaining about")
                    print(f"       coqpit-vs-coqpit-config, run:")
                    print(f"         {_VENV_NAME}\\Scripts\\pip show coqpit-config")
                    print(f"         {_VENV_NAME}\\Scripts\\pip show coqui-tts")
                    print(f"       and confirm coqpit-config is installed and")
                    print(f"       coqui-tts isn't pinned to a version that wants")
                    print(f"       the legacy coqpit package.")
                    print(f"    3. If it's a missing module (e.g. trainer, librosa),")
                    print(f"       install JUST that module with --no-deps:")
                    print(f"         {_VENV_NAME}\\Scripts\\pip install --no-deps <module>")
                    print(f"       Avoid `--force-reinstall -r requirements_coqui.txt`")
                    print(f"       on this machine — it triggers the file-lock cascade.")
                    print(f"    4. As a nuclear option, recreate the venv from scratch:")
                    print(f"         Remove-Item -Recurse -Force {_VENV_NAME}")
                    print(f"         python -m venv {_VENV_NAME}")
                    print(f"         {_VENV_NAME}\\Scripts\\pip install -r scripts\\requirements_coqui.txt")
                    print(f"       (a fresh venv has no namespace shadows or stale")
                    print(f"       dist-info to interfere.)")
                    return False

                # Repair succeeded, but our current interpreter has stale
                # sys.modules / filesystem cache. Re-run fixes that instantly.
                print("✓ Repaired. Re-run the command to pick up the new packages:")
                print(f"    {_VENV_NAME}\\Scripts\\python scripts\\train_coqui_vits.py train")
                return False
            except Exception as e2:
                print(f"\n✗ ERROR: Auto-repair failed: {e2}")
                print(f"  Run manually:")
                print(f"    {_VENV_NAME}\\Scripts\\pip uninstall -y coqpit coqpit-config coqui-tts trainer")
                print(f"    {_VENV_NAME}\\Scripts\\pip install --force-reinstall -r scripts\\requirements_coqui.txt")
                return False
        else:
            print(f"\n✗ ERROR: Coqui TTS not installed in {_VENV_NAME}: {e}")
            print(
                f"  {_VENV_NAME}\\Scripts\\pip install -r scripts\\requirements_coqui.txt"
            )
            return False

    dataset_config = BaseDatasetConfig(
        formatter="ljspeech",
        meta_file_train="metadata.csv",
        path=str(COQUI_TRAIN_DIR),
        language="awi",
    )

    characters_config = CharactersConfig(
        pad="<PAD>",
        eos="<EOS>",
        bos="<BOS>",
        blank="<BLNK>",
        characters=AWING_CHARS,
        punctuations=AWING_PUNCS,
        phonemes=None,
        is_unique=True,
        is_sorted=True,
    )

    config = VitsConfig(
        run_name="awing_coqui_vits",
        batch_size=8,
        eval_batch_size=4,
        num_loader_workers=2,
        num_eval_loader_workers=0,
        run_eval=True,
        test_delay_epochs=-1,
        epochs=1000,
        save_step=500,
        print_step=25,
        print_eval=True,
        eval_split_size=0.1,
        use_phonemes=False,
        compute_input_seq_cache=True,
        text_cleaner=None,
        characters=characters_config,
        output_path=str(CKPT_DIR),
        datasets=[dataset_config],
        # coqpit-config 0.2.x rejects plain dicts here — must be a Coqpit
        # instance. VitsAudioConfig is the right class.
        audio=VitsAudioConfig(
            sample_rate=SAMPLE_RATE,
            num_mels=80,
            hop_length=256,
            win_length=1024,
            fft_size=1024,
            mel_fmin=0.0,
            mel_fmax=None,
        ),
        lr_gen=2e-4,
        lr_disc=2e-4,
        use_speaker_embedding=False,
        mixed_precision=False,
        cudnn_enable=False,  # mirrors Session 16 stability fix
        cudnn_benchmark=False,
    )

    ap = AudioProcessor.init_from_config(config)
    tokenizer, config = TTSTokenizer.init_from_config(config)

    train_samples, eval_samples = load_tts_samples(
        dataset_config,
        eval_split=True,
        eval_split_size=config.eval_split_size,
    )
    print(
        f"✓ Train samples: {len(train_samples)}   Eval samples: {len(eval_samples)}"
    )

    model = Vits(config, ap, tokenizer, speaker_manager=None)

    CKPT_DIR.mkdir(parents=True, exist_ok=True)
    trainer = Trainer(
        TrainerArgs(),
        config,
        output_path=str(CKPT_DIR),
        model=model,
        train_samples=train_samples,
        eval_samples=eval_samples,
    )

    print()
    print("=" * 64)
    print("Starting training. Ctrl+C to stop; checkpoint saved every 500 steps.")
    print(f"Output: {CKPT_DIR}")
    print("=" * 64)
    print()
    trainer.fit()
    return True


# ---------- cmd_synthesize ----------
def cmd_synthesize(args):
    print("=" * 64)
    print("Coqui VITS synthesis — 20 held-out test words")
    print("=" * 64)

    if not SHORTLIST.exists():
        print(f"✗ ERROR: Test shortlist not found at {SHORTLIST}")
        return False
    with open(SHORTLIST, "r", encoding="utf-8") as f:
        sl_data = json.load(f)
    # shortlist.json is {description, coverage_buckets, shortlist: [...], ...}
    # The actual list of held-out word dicts lives under the "shortlist" key.
    shortlist = sl_data.get("shortlist") if isinstance(sl_data, dict) else sl_data
    if not shortlist:
        print(f"✗ ERROR: No 'shortlist' array found in {SHORTLIST}")
        return False

    # Locate the latest checkpoint. Coqui writes "best_model.pth" once an
    # eval set is available; otherwise checkpoint_*.pth files accumulate.
    ckpts: list[Path] = []
    if CKPT_DIR.exists():
        ckpts = list(CKPT_DIR.rglob("best_model.pth"))
        if not ckpts:
            ckpts = list(CKPT_DIR.rglob("checkpoint_*.pth"))
    if not ckpts:
        print(f"✗ ERROR: No checkpoint at {CKPT_DIR}")
        print("  Train first: python scripts\\train_coqui_vits.py train")
        return False
    ckpt = max(ckpts, key=lambda p: p.stat().st_mtime)
    cfg_path = ckpt.parent / "config.json"
    if not cfg_path.exists():
        cand = list(ckpt.parent.parent.rglob("config.json"))
        if cand:
            cfg_path = max(cand, key=lambda p: p.stat().st_mtime)
    if not cfg_path.exists():
        print(f"✗ ERROR: No config.json near {ckpt}")
        return False
    print(f"✓ Checkpoint: {ckpt.relative_to(REPO)}")
    print(f"✓ Config:     {cfg_path.relative_to(REPO)}")

    try:
        import numpy as np

        from TTS.utils.synthesizer import Synthesizer
    except ImportError as e:
        print(f"✗ ERROR: Coqui TTS not installed: {e}")
        return False

    # Try CUDA first; fall back to CPU on init failure
    try:
        synth = Synthesizer(
            tts_checkpoint=str(ckpt),
            tts_config_path=str(cfg_path),
            use_cuda=True,
        )
    except Exception as e:
        print(f"⚠ CUDA synthesizer init failed ({e}); retrying on CPU.")
        synth = Synthesizer(
            tts_checkpoint=str(ckpt),
            tts_config_path=str(cfg_path),
            use_cuda=False,
        )

    VITS_RAW_DIR.mkdir(parents=True, exist_ok=True)

    silent = 0
    written = 0
    for item in shortlist:
        key = item.get("key")
        awing = item.get("awing") or item.get("text") or ""
        if not (key and awing):
            continue
        norm = awing_to_train_text(awing)
        if not norm:
            continue
        try:
            wav = synth.tts(norm)
        except Exception as e:
            print(f"  ✗ {key:<14} synth error: {e}")
            continue
        wav = np.asarray(wav, dtype=np.float32)
        peak = float(np.max(np.abs(wav))) if wav.size else 0.0
        out_path = VITS_RAW_DIR / f"{key}.wav"
        synth.save_wav(wav, str(out_path))
        written += 1
        if peak < 0.01:
            silent += 1
            print(f"  ⚠ {key:<14} peak={peak:.4f}  (near-silent)")
        else:
            print(f"  ✓ {key:<14} peak={peak:.4f}  → {out_path.name}")

    print(f"\nWrote {written} clips to {VITS_RAW_DIR.relative_to(REPO)}")

    if written and silent / max(1, written) > 1 / 3:
        bar = "!" * 64
        print()
        print(bar)
        print("! FAIL-LOUD: more than 1/3 of test clips are near-silent.")
        print("! 197 recordings (~5 min audio) is below Coqui's 1-10 hr typical.")
        print("! Options:")
        print("!   1. Record more material via scripts\\record_audio.py")
        print("!   2. Stay with the per-word speakable_override pipeline")
        print("!      (Sessions 48-49) — it is production-proven and ships today.")
        print(bar)
        return False

    print("\nNext steps:")
    print("  python scripts\\bakeoff.py variant-a")
    print("  python scripts\\bakeoff.py variant-c")
    print("  python scripts\\bakeoff.py html")
    return True


# ---------- cmd_clean ----------
def _rm_dir_contents(path: Path) -> tuple[int, int]:
    """Remove all files inside a directory (non-recursive for top, recursive
    for subdirs). Returns (files_removed, dirs_removed). Leaves the directory
    itself in place. Missing dir → (0, 0)."""
    import shutil

    files = 0
    dirs = 0
    if not path.exists():
        return (0, 0)
    for child in path.iterdir():
        try:
            if child.is_file() or child.is_symlink():
                child.unlink()
                files += 1
            elif child.is_dir():
                shutil.rmtree(child)
                dirs += 1
        except Exception as e:
            print(f"  ⚠ Could not remove {child}: {e}")
    return (files, dirs)


def _rm_tree(path: Path) -> bool:
    """Remove a directory tree if present. Returns True if something was removed."""
    import shutil

    if not path.exists():
        return False
    try:
        shutil.rmtree(path)
        return True
    except Exception as e:
        print(f"  ⚠ Could not remove {path}: {e}")
        return False


def cmd_clean(args):
    print("=" * 64)
    print("Cleanup — wipe stale Session 53 bake-off artifacts")
    print("=" * 64)
    print("This removes rebuildable output so the next train/synth run is clean.")
    print("It DOES NOT touch:")
    print(f"  - {TRAIN_DIR.relative_to(REPO)} (197 training recordings)")
    print(f"  - {TEST_DIR.relative_to(REPO)}/*.wav (20 ground-truth recordings)")
    print(f"  - shortlist.json / manifest.json")
    if not args.include_checkpoint:
        print(f"  - {CKPT_DIR.relative_to(REPO)} (use --include-checkpoint to nuke)")
    print()

    total_files = 0
    total_dirs = 0

    # 1. Rebuildable training cache (cmd_train recreates this)
    if COQUI_TRAIN_DIR.exists():
        if _rm_tree(COQUI_TRAIN_DIR):
            print(f"✓ Removed {COQUI_TRAIN_DIR.relative_to(REPO)} (rebuilt by train)")
            total_dirs += 1
    else:
        print(f"  (skip) {COQUI_TRAIN_DIR.relative_to(REPO)} — not present")

    # 2. Bake-off output directories — wipe CONTENTS, keep dirs for consumers
    bakeoff_consumers = [
        VITS_RAW_DIR,                           # Coqui synthesize will refill
        BAKEOFF_DIR / "A_pitch",                # bakeoff.py variant-a refills
        BAKEOFF_DIR / "B_knn",                  # bakeoff.py variant-b refills
        BAKEOFF_DIR / "C_edgeoverride",         # bakeoff.py variant-c refills
        BAKEOFF_DIR / "_edge_baseline",         # bakeoff.py baseline refills
    ]
    for consumer in bakeoff_consumers:
        if consumer.exists():
            f, d = _rm_dir_contents(consumer)
            if f or d:
                print(
                    f"✓ Cleared {consumer.relative_to(REPO)} "
                    f"({f} file(s), {d} subdir(s))"
                )
                total_files += f
                total_dirs += d
            else:
                print(f"  (already empty) {consumer.relative_to(REPO)}")
        else:
            print(f"  (skip) {consumer.relative_to(REPO)} — not present")

    # 3. Stale HTML comparison page (bakeoff.py html regenerates it)
    if BAKEOFF_HTML.exists():
        try:
            BAKEOFF_HTML.unlink()
            print(f"✓ Removed {BAKEOFF_HTML.relative_to(REPO)} (regen with bakeoff.py html)")
            total_files += 1
        except Exception as e:
            print(f"  ⚠ Could not remove {BAKEOFF_HTML}: {e}")

    # 4. _ground_truth/ — optional, keep by default (cheap to repopulate but
    #    unnecessary to touch since the wavs inside are identical to the
    #    top-level test recordings).
    gt_dir = BAKEOFF_DIR / "_ground_truth"
    if args.include_ground_truth:
        if gt_dir.exists():
            f, d = _rm_dir_contents(gt_dir)
            print(
                f"✓ Cleared {gt_dir.relative_to(REPO)} "
                f"({f} file(s))  — rerun bakeoff.py ground-truth"
            )
            total_files += f
            total_dirs += d
    else:
        if gt_dir.exists():
            n = len(list(gt_dir.glob("*.wav")))
            print(
                f"  (preserved) {gt_dir.relative_to(REPO)} "
                f"— {n} wav(s). Use --include-ground-truth to wipe."
            )

    # 5. Checkpoints — opt-in nuke, off by default so training is resumable
    if args.include_checkpoint:
        if CKPT_DIR.exists():
            if _rm_tree(CKPT_DIR):
                print(f"✓ Removed {CKPT_DIR.relative_to(REPO)} (checkpoints gone)")
                total_dirs += 1
        else:
            print(f"  (skip) {CKPT_DIR.relative_to(REPO)} — no checkpoints present")
    else:
        if CKPT_DIR.exists():
            ckpts = list(CKPT_DIR.rglob("*.pth"))
            if ckpts:
                print(
                    f"  (preserved) {CKPT_DIR.relative_to(REPO)} "
                    f"— {len(ckpts)} checkpoint file(s). "
                    f"Use --include-checkpoint to nuke."
                )

    print()
    print(f"Done. Removed {total_files} file(s) and {total_dirs} dir(s).")
    print()
    print("Next steps:")
    print("  python scripts\\train_coqui_vits.py train")
    print("  python scripts\\train_coqui_vits.py synthesize")
    return True


# ---------- cmd_status ----------
def cmd_status(args):
    print("=" * 64)
    print("Coqui VITS pipeline status")
    print("=" * 64)

    n_manifest = 0
    if MANIFEST.exists():
        try:
            data = json.loads(MANIFEST.read_text(encoding="utf-8"))
            n_manifest = len(data) if isinstance(data, list) else len(data)
        except Exception:
            pass
    print(f"  Recordings manifest:  {n_manifest:>4} clips    {MANIFEST}")

    n_short = 0
    if SHORTLIST.exists():
        try:
            sl = json.loads(SHORTLIST.read_text(encoding="utf-8"))
            # shortlist.json is {description, coverage_buckets, shortlist: [...], ...}
            items = sl.get("shortlist") if isinstance(sl, dict) else sl
            n_short = len(items) if items else 0
        except Exception:
            pass
    print(f"  Test shortlist:       {n_short:>4} words")

    n_prepared = len(list(COQUI_WAVS.glob("*.wav"))) if COQUI_WAVS.exists() else 0
    print(f"  Prepared train wavs:  {n_prepared:>4}        {COQUI_WAVS}")

    ckpts = list(CKPT_DIR.rglob("*.pth")) if CKPT_DIR.exists() else []
    print(f"  Checkpoints:          {len(ckpts):>4} files   {CKPT_DIR}")
    if ckpts:
        latest = max(ckpts, key=lambda p: p.stat().st_mtime)
        print(f"  Latest checkpoint:         {latest.relative_to(REPO)}")

    n_raw = len(list(VITS_RAW_DIR.glob("*.wav"))) if VITS_RAW_DIR.exists() else 0
    print(f"  Synth outputs (_vits_raw): {n_raw} clips")

    print()
    if n_prepared == 0:
        print("→ Next: python scripts\\train_coqui_vits.py train")
    elif not ckpts:
        print("→ Next: python scripts\\train_coqui_vits.py train  (resume training)")
    elif n_raw < n_short:
        print("→ Next: python scripts\\train_coqui_vits.py synthesize")
    else:
        print("→ Next: python scripts\\bakeoff.py variant-a")
        print("        python scripts\\bakeoff.py variant-c")
        print("        python scripts\\bakeoff.py html")
    return True


# ---------- main ----------
def main():
    p = argparse.ArgumentParser(
        description="Coqui TTS VITS training for Awing (Session 54)"
    )
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("train", help="Fine-tune Coqui VITS on the 197 Awing recordings")
    sub.add_parser("synthesize", help="Synthesise the 20 held-out test words")
    sub.add_parser("status", help="Report pipeline state")

    p_clean = sub.add_parser(
        "clean",
        help="Remove stale Session 53 bake-off artifacts before re-running",
    )
    p_clean.add_argument(
        "--include-checkpoint",
        action="store_true",
        help="Also delete models/awing_coqui_vits/ (default: preserve for resume)",
    )
    p_clean.add_argument(
        "--include-ground-truth",
        action="store_true",
        help="Also clear bakeoff/_ground_truth/ (default: preserve)",
    )

    args = p.parse_args()
    commands = {
        "train": cmd_train,
        "synthesize": cmd_synthesize,
        "status": cmd_status,
        "clean": cmd_clean,
    }
    ok = commands[args.command](args)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
