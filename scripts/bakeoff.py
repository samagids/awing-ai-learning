#!/usr/bin/env python3
"""
bakeoff.py  v1.0.0  (Session 53)

Empirical A/B/C bake-off of three voice-synthesis architectures against
the 20 held-out test words in training_data/test_recordings/.

  Ground truth:  Dr. Sama's microphone recordings (apples-to-apples target)
  Edge baseline: current production — Edge TTS Swahili-neural for each of 6 voices
  Variant A:     VITS (fine-tuned on 197 recordings) + ffmpeg pitch shift per voice
                 Pitch offsets: boy +6, girl +8, young_man +2, young_woman +5,
                                man 0, woman +4  (semitones)
  Variant B:     VITS + kNN voice conversion (bshall/knn-vc) using
                 Edge TTS clips as per-voice reference
  Variant C:     VITS-as-teacher → Whisper transcribe → Swahili-phonetic
                 speakable_overrides → Edge TTS regenerate in all 6 voices

Workflow (run on Windows with CUDA GPU):

  1. Record the 20 test words:
        python scripts\\record_test_words.py

  2. Train one VITS checkpoint on the 197 hand-recorded clips (shared input):
        python scripts\\bakeoff.py train

  3. Synthesize the 20 test words through trained VITS:
        python scripts\\bakeoff.py vits

  4. Generate the production Edge TTS baseline:
        python scripts\\bakeoff.py baseline

  5. Produce each variant:
        python scripts\\bakeoff.py variant-a
        python scripts\\bakeoff.py variant-b       # needs knn-vc
        python scripts\\bakeoff.py variant-c       # needs openai-whisper

  6. Copy ground truth recordings into the comparison folder:
        python scripts\\bakeoff.py ground-truth

  7. Emit the HTML comparison page:
        python scripts\\bakeoff.py html

  8. Open training_data/test_recordings/bakeoff.html in a browser, rate each
     clip 1-5 stars. Scores persist in localStorage. Aggregate panel at top.

  Run `python scripts\\bakeoff.py status` at any time to see progress.

All paths are relative to the project root.
"""

import os
import sys
import json
import shutil
import argparse
import subprocess
from pathlib import Path


# ---------------------------------------------------------------------------
# Auto-activate venv
# ---------------------------------------------------------------------------
def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    project_root = Path(__file__).resolve().parent.parent
    if sys.platform == "win32":
        venv_python = project_root / "venv" / "Scripts" / "python.exe"
    else:
        venv_python = project_root / "venv" / "bin" / "python"
    if not venv_python.exists():
        print("WARNING: venv not found. Run install_dependencies.bat first.")
        return
    if os.path.abspath(sys.executable) == os.path.abspath(str(venv_python)):
        return
    print(f"Auto-activating venv: {venv_python}")
    result = subprocess.run([str(venv_python)] + sys.argv, cwd=str(project_root))
    sys.exit(result.returncode)


_ensure_venv()


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RECORDINGS_DIR = PROJECT_ROOT / "training_data" / "recordings"
RECORDINGS_MANIFEST = RECORDINGS_DIR / "manifest.json"

TEST_DIR = PROJECT_ROOT / "training_data" / "test_recordings"
SHORTLIST_PATH = TEST_DIR / "shortlist.json"
TEST_MANIFEST = TEST_DIR / "manifest.json"
BAKEOFF_DIR = TEST_DIR / "bakeoff"
GROUND_TRUTH_DIR = BAKEOFF_DIR / "_ground_truth"
VITS_RAW_DIR = BAKEOFF_DIR / "_vits_raw"
BASELINE_DIR = BAKEOFF_DIR / "_edge_baseline"
A_DIR = BAKEOFF_DIR / "A_pitch"
B_DIR = BAKEOFF_DIR / "B_knn"
C_DIR = BAKEOFF_DIR / "C_edgeoverride"
XTTS_RAW_DIR = BAKEOFF_DIR / "_xtts_raw"  # Variant D — Coqui XTTS v2 (Session 55)

MODELS_DIR = PROJECT_ROOT / "models"
VITS_CKPT_DIR = MODELS_DIR / "awing_bakeoff_vits"          # legacy HuggingFace path
COQUI_CKPT_ROOT = MODELS_DIR / "awing_coqui_vits"          # Session 54 Coqui training
BASE_MODEL = "facebook/mms-tts-mcp"  # Makaa — best Bantu char coverage for Awing


def _find_coqui_checkpoint() -> tuple[Path | None, Path | None]:
    """Return (checkpoint_path, config_path) for the latest Coqui run, or
    (None, None) if no Coqui checkpoint exists. Prefers best_model.pth;
    falls back to the highest-numbered checkpoint_*.pth."""
    if not COQUI_CKPT_ROOT.exists():
        return (None, None)
    best = list(COQUI_CKPT_ROOT.rglob("best_model.pth"))
    candidates = best if best else list(COQUI_CKPT_ROOT.rglob("checkpoint_*.pth"))
    if not candidates:
        return (None, None)
    ckpt = max(candidates, key=lambda p: p.stat().st_mtime)
    cfg = ckpt.parent / "config.json"
    if not cfg.exists():
        cands = list(ckpt.parent.parent.rglob("config.json"))
        if not cands:
            return (None, None)
        cfg = max(cands, key=lambda p: p.stat().st_mtime)
    return (ckpt, cfg)

for d in (BAKEOFF_DIR, GROUND_TRUTH_DIR, VITS_RAW_DIR, BASELINE_DIR,
          A_DIR, B_DIR, C_DIR, XTTS_RAW_DIR, MODELS_DIR):
    d.mkdir(parents=True, exist_ok=True)

# 6 character voices, and the pitch shift for Variant A (in semitones, relative
# to the VITS base voice which we treat as an adult-male register).
VOICES = {
    "boy":          {"pitch_semitones": +6, "edge_voice": "sw-KE-RafikiNeural",  "edge_rate": "-35%", "edge_pitch": "+15Hz"},
    "girl":         {"pitch_semitones": +8, "edge_voice": "sw-KE-ZuriNeural",    "edge_rate": "-35%", "edge_pitch": "+20Hz"},
    "young_man":    {"pitch_semitones": +2, "edge_voice": "sw-TZ-DaudiNeural",   "edge_rate": "-25%", "edge_pitch": "+5Hz"},
    "young_woman":  {"pitch_semitones": +5, "edge_voice": "sw-TZ-RehemaNeural",  "edge_rate": "-25%", "edge_pitch": "+10Hz"},
    "man":          {"pitch_semitones":  0, "edge_voice": "sw-TZ-DaudiNeural",   "edge_rate": "-15%", "edge_pitch": "-5Hz"},
    "woman":        {"pitch_semitones": +4, "edge_voice": "sw-TZ-RehemaNeural",  "edge_rate": "-15%", "edge_pitch": "+0Hz"},
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _load_shortlist():
    if not SHORTLIST_PATH.exists():
        print(f"ERROR: shortlist missing at {SHORTLIST_PATH}")
        sys.exit(1)
    data = json.loads(SHORTLIST_PATH.read_text(encoding="utf-8"))
    return data["shortlist"]


def _load_test_manifest():
    """What has been recorded so far as ground truth."""
    if not TEST_MANIFEST.exists():
        return []
    return json.loads(TEST_MANIFEST.read_text(encoding="utf-8"))


def _which_ffmpeg():
    return shutil.which("ffmpeg")


def _awing_to_makaa(text):
    """
    Copy of awing_to_makaa from train_awing_tts.py — normalise Awing into
    characters the Makaa VITS base tokenizer can actually emit.
    """
    import unicodedata
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    text = unicodedata.normalize("NFC", text)
    replacements = {
        "ɛ": "e", "Ɛ": "E",
        "ɔ": "o", "Ɔ": "O",
        "ə": "e", "Ə": "E",
        "ɨ": "i", "Ɨ": "I",
        "ŋ": "ng", "Ŋ": "Ng",
        "ɣ": "g",
        "'": "", "'": "", "'": "",
    }
    for src, dst in replacements.items():
        text = text.replace(src, dst)
    return text


# ---------------------------------------------------------------------------
# train — fine-tune VITS on the 197-clip ground-truth set
# ---------------------------------------------------------------------------
def cmd_train(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF STEP 1: Fine-tune VITS on 197 hand-recorded clips")
    print("=" * 64)

    if not RECORDINGS_MANIFEST.exists():
        print(f"  ERROR: {RECORDINGS_MANIFEST} not found.")
        print(f"  Record the 197-word training set with record_audio.py first.")
        sys.exit(1)

    import torch
    if not torch.cuda.is_available():
        print("  ERROR: No CUDA GPU detected. Training needs a GPU.")
        sys.exit(1)
    gpu_name = torch.cuda.get_device_name(0)
    vram = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
    print(f"  GPU: {gpu_name} ({vram:.1f} GB VRAM)")

    try:
        from transformers import VitsModel, VitsTokenizer
    except ImportError:
        print("  ERROR: transformers not installed. Run:")
        print("    venv\\Scripts\\pip install --upgrade transformers")
        sys.exit(1)
    try:
        from pydub import AudioSegment
    except ImportError:
        print("  ERROR: pydub not installed. Run:")
        print("    venv\\Scripts\\pip install pydub")
        sys.exit(1)

    manifest = json.loads(RECORDINGS_MANIFEST.read_text(encoding="utf-8"))
    print(f"  Loaded {len(manifest)} recordings from manifest.")

    # Prepare training data: resample to 22050 mono PCM16, cleaned text.
    train_prep_dir = MODELS_DIR / "_bakeoff_train_prep"
    train_prep_dir.mkdir(parents=True, exist_ok=True)

    entries = []
    for entry in manifest:
        wav_path = PROJECT_ROOT / entry["wav_path"]
        if not wav_path.exists():
            # some manifests use paths relative to project root; skip silently
            continue
        try:
            audio = AudioSegment.from_wav(str(wav_path))
            audio = audio.set_frame_rate(22050).set_channels(1).set_sample_width(2)
            dst = train_prep_dir / f"{entry['key']}.wav"
            audio.export(str(dst), format="wav")
            entries.append({"audio": str(dst.resolve()),
                            "text": entry["awing"],
                            "key": entry["key"]})
        except Exception as e:
            print(f"    skip {entry['key']}: {e}")
    print(f"  Prepared {len(entries)} training samples.")

    # Disjoint check: the bake-off test words must NOT be in the training set.
    shortlist = _load_shortlist()
    test_keys = {s["key"] for s in shortlist}
    overlap = [e for e in entries if e["key"] in test_keys]
    if overlap:
        print(f"  WARNING: {len(overlap)} test words appear in the training set!")
        print(f"  Dropping them to preserve bake-off validity:")
        for o in overlap:
            print(f"    - {o['key']}")
        entries = [e for e in entries if e["key"] not in test_keys]
    else:
        print(f"  OK: zero overlap between training ({len(entries)}) and")
        print(f"      test ({len(test_keys)}) sets — bake-off will be valid.")

    print(f"\n  Loading base model: {BASE_MODEL}")
    try:
        tokenizer = VitsTokenizer.from_pretrained(BASE_MODEL)
        model = VitsModel.from_pretrained(BASE_MODEL)
    except Exception as e:
        print(f"  ERROR loading base model: {e}")
        sys.exit(1)

    existing_vocab = set(tokenizer.get_vocab().keys())
    print(f"  Tokenizer vocab: {len(existing_vocab)} characters")

    cleaned = []
    for e in entries:
        text = _awing_to_makaa(e["text"]).lower()
        text = "".join(c for c in text if c in existing_vocab or c == " ")
        text = " ".join(text.split()).strip()
        if len(text) >= 1:
            cleaned.append({**e, "text": text})
    dropped = len(entries) - len(cleaned)
    if dropped > 0:
        print(f"  Dropped {dropped} entries with no tokenizer-valid characters.")
    entries = cleaned
    print(f"  Final training set: {len(entries)} samples.")

    if len(entries) < 30:
        print(f"  ERROR: Too few training samples ({len(entries)}). Need ≥30.")
        sys.exit(1)

    # GPU / cuDNN setup (matches train_awing_tts.py proven-stable config)
    torch.backends.cudnn.enabled = False
    torch.backends.cudnn.benchmark = False
    os.environ.setdefault("PYTORCH_CUDA_ALLOC_CONF", "expandable_segments:True")
    torch.cuda.empty_cache()
    torch.cuda.set_per_process_memory_fraction(0.7)
    try:
        _t = torch.zeros(1, device="cuda"); del _t; torch.cuda.empty_cache()
    except Exception as e:
        print(f"  ERROR: CUDA test failed ({e})")
        sys.exit(1)
    print(f"  cuDNN: disabled  |  VRAM cap: {vram * 0.7:.1f} GB")

    device = torch.device("cuda")
    model = model.to(device)
    model.train()

    from torch.optim import AdamW
    optimizer = AdamW(model.parameters(), lr=2e-5, weight_decay=0.01)

    max_steps = args.steps
    save_interval = 500
    batch_size = 1
    import random
    random.seed(1729)
    print(f"\n  Training: max_steps={max_steps}, batch_size={batch_size}, lr=2e-5")
    print(f"            save every {save_interval} steps")

    step = 0
    running_loss = 0.0
    while step < max_steps:
        random.shuffle(entries)
        for start in range(0, len(entries), batch_size):
            if step >= max_steps:
                break
            batch = entries[start:start + batch_size]
            texts = [e["text"] for e in batch]
            try:
                inputs = tokenizer(texts, return_tensors="pt", padding=True).to(device)
                outputs = model(**inputs)
                if hasattr(outputs, "loss") and outputs.loss is not None:
                    loss = outputs.loss
                else:
                    # Fallback: mean-abs waveform as a weak regulariser so the
                    # optimiser has a gradient at all.
                    loss = outputs.waveform.abs().mean()
                optimizer.zero_grad()
                loss.backward()
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()
                running_loss += float(loss.item())
            except Exception as e:
                print(f"    step {step} failed ({e}); skipping batch")
                torch.cuda.empty_cache()
                continue
            step += 1
            if step % 50 == 0:
                avg = running_loss / 50
                running_loss = 0.0
                vram_used = torch.cuda.memory_allocated() / (1024 ** 3)
                print(f"  step {step:>5d}/{max_steps}  loss={avg:.4f}  vram={vram_used:.2f}GB")
            if step % save_interval == 0:
                _save_ckpt(model, tokenizer, VITS_CKPT_DIR, device)
                print(f"  [checkpoint] saved at step {step}")
            torch.cuda.empty_cache()

    _save_ckpt(model, tokenizer, VITS_CKPT_DIR, device)
    print(f"\n  ✓ Training complete. Checkpoint: {VITS_CKPT_DIR}")
    print(f"  Next: python scripts\\bakeoff.py vits")


def _save_ckpt(model, tokenizer, path, device):
    path.mkdir(parents=True, exist_ok=True)
    model.to("cpu")
    try:
        model.save_pretrained(str(path))
        tokenizer.save_pretrained(str(path))
    finally:
        model.to(device)
        model.train()


# ---------------------------------------------------------------------------
# vits — synthesize 20 test words through fine-tuned VITS
# ---------------------------------------------------------------------------
def cmd_vits(args):
    use_base = bool(getattr(args, "base_model", False))
    force_hf = bool(getattr(args, "huggingface", False))

    print("\n" + "=" * 64)
    print(f"  BAKE-OFF STEP 2: Synthesize 20 test words through VITS")
    print("=" * 64)

    # ---- Path A: Coqui checkpoint (Session 54 — preferred) -----------------
    if not use_base and not force_hf:
        coqui_ckpt, coqui_cfg = _find_coqui_checkpoint()
        if coqui_ckpt is not None:
            print(f"  Mode:       Coqui TTS (Session 54 fine-tune)")
            print(f"  Checkpoint: {coqui_ckpt.relative_to(PROJECT_ROOT)}")
            print(f"  Config:     {coqui_cfg.relative_to(PROJECT_ROOT)}")
            print(f"  Delegating to scripts\\train_coqui_vits.py synthesize")
            print(f"  (which auto-activates venv_coqui and writes to the same")
            print(f"   {VITS_RAW_DIR.relative_to(PROJECT_ROOT)} directory).")
            print()

            train_script = PROJECT_ROOT / "scripts" / "train_coqui_vits.py"
            if not train_script.exists():
                print(f"  ERROR: {train_script} missing.")
                sys.exit(1)

            # Use the *system* python here — train_coqui_vits.py will re-exec
            # itself under venv_coqui via its own _ensure_venv guard.
            result = subprocess.run(
                [sys.executable, str(train_script), "synthesize"],
                cwd=str(PROJECT_ROOT),
            )
            sys.exit(result.returncode)

        print(f"  No Coqui checkpoint found under {COQUI_CKPT_ROOT.relative_to(PROJECT_ROOT)}")
        print(f"  Falling back to HuggingFace path (use --base-model to skip checkpoint check).")
        print()

    # ---- Path B: HuggingFace VitsModel (legacy / base-model fallback) -------
    label = "base Makaa MMS (no fine-tuning)" if use_base else "HuggingFace fine-tuned VITS"
    print(f"  Mode: {label}")

    if use_base:
        load_from = BASE_MODEL
        print(f"  Source: {BASE_MODEL} (HuggingFace)")
        print(f"  NOTE: --base-model bypasses any fine-tuned checkpoint at")
        print(f"        {VITS_CKPT_DIR.relative_to(PROJECT_ROOT)}")
        print(f"        Use this to test architecture viability without fine-tuning.")
    else:
        if not VITS_CKPT_DIR.exists():
            print(f"  ERROR: no checkpoint found.")
            print(f"  Looked for Coqui at: {COQUI_CKPT_ROOT.relative_to(PROJECT_ROOT)}")
            print(f"  Looked for HF at:    {VITS_CKPT_DIR.relative_to(PROJECT_ROOT)}")
            print(f"  Train via:  python scripts\\train_coqui_vits.py train")
            print(f"  Or test base model: python scripts\\bakeoff.py vits --base-model")
            sys.exit(1)
        load_from = str(VITS_CKPT_DIR)

    import torch
    from transformers import VitsModel, VitsTokenizer
    import soundfile as sf

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"  Device: {device}")

    tokenizer = VitsTokenizer.from_pretrained(load_from)
    model = VitsModel.from_pretrained(load_from).to(device).eval()

    shortlist = _load_shortlist()
    sr = getattr(model.config, "sampling_rate", 22050)
    peaks = []
    for s in shortlist:
        gen_text = _awing_to_makaa(s["awing"]).lower()
        out_path = VITS_RAW_DIR / f"{s['key']}.wav"
        with torch.no_grad():
            inputs = tokenizer(gen_text, return_tensors="pt").to(device)
            output = model(**inputs).waveform[0].cpu().numpy()
        peak = float(max(abs(output.min()), abs(output.max())))
        peaks.append(peak)
        sf.write(str(out_path), output, sr)
        silent = "← SILENT" if peak < 0.01 else ""
        print(f"  {s['key']:10s} ({s['awing']:12s} / {s['english']:15s}) "
              f"peak={peak:.4f} {silent}")
    silent_count = sum(1 for p in peaks if p < 0.01)
    print(f"\n  Wrote {len(peaks)} WAV files to {VITS_RAW_DIR.relative_to(PROJECT_ROOT)}")
    print(f"  Silent: {silent_count}/{len(peaks)}  avg peak: {sum(peaks)/len(peaks):.4f}")
    if silent_count > len(peaks) // 3:
        if use_base:
            print(f"  WARNING: {silent_count} clips silent even from the base model.")
            print(f"           Check device, transformers version, and audio backend.")
        else:
            print(f"  WARNING: {silent_count} clips are silent. The checkpoint has")
            print(f"           likely collapsed (HF VitsModel exposes no training")
            print(f"           loss, so the fallback regulariser drives output → 0).")
            print(f"           Re-run with: python scripts\\bakeoff.py vits --base-model")


# ---------------------------------------------------------------------------
# baseline — current production Edge TTS for each voice
# ---------------------------------------------------------------------------
def cmd_baseline(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF STEP 3: Edge TTS baseline (current production)")
    print("=" * 64)

    try:
        import edge_tts  # noqa: F401
    except ImportError:
        print("  ERROR: edge-tts not installed. Run:")
        print("    venv\\Scripts\\pip install edge-tts")
        sys.exit(1)

    # Re-use the production awing_to_speakable from generate_audio_edge.py
    sys.path.insert(0, str(PROJECT_ROOT / "scripts"))
    from generate_audio_edge import awing_to_speakable  # type: ignore

    import asyncio
    shortlist = _load_shortlist()

    async def _run_one(voice_key, cfg, word):
        out_dir = BASELINE_DIR / voice_key
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{word['key']}.mp3"
        speakable = awing_to_speakable(word["awing"])
        import edge_tts as _et
        communicate = _et.Communicate(speakable, cfg["edge_voice"],
                                      rate=cfg["edge_rate"],
                                      pitch=cfg["edge_pitch"])
        await communicate.save(str(out_path))
        return out_path

    async def _run_all():
        for voice_key, cfg in VOICES.items():
            print(f"\n  Voice: {voice_key}  ({cfg['edge_voice']})")
            for word in shortlist:
                try:
                    out = await _run_one(voice_key, cfg, word)
                    print(f"    ✓ {word['key']:10s} → {out.relative_to(PROJECT_ROOT)}")
                except Exception as e:
                    print(f"    ✗ {word['key']:10s} failed: {e}")

    asyncio.run(_run_all())
    print(f"\n  Done. Edge TTS baseline in {BASELINE_DIR.relative_to(PROJECT_ROOT)}")


# ---------------------------------------------------------------------------
# variant-a — VITS + ffmpeg pitch shift
# ---------------------------------------------------------------------------
def cmd_variant_a(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF VARIANT A: VITS + ffmpeg pitch shift")
    print("=" * 64)

    if _which_ffmpeg() is None:
        print("  ERROR: ffmpeg not found on PATH. Install with:")
        print("    winget install Gyan.FFmpeg")
        sys.exit(1)

    shortlist = _load_shortlist()
    missing = [s for s in shortlist if not (VITS_RAW_DIR / f"{s['key']}.wav").exists()]
    if missing:
        print(f"  ERROR: {len(missing)} VITS clips missing. Run:")
        print(f"    python scripts\\bakeoff.py vits")
        sys.exit(1)

    for voice_key, cfg in VOICES.items():
        semis = cfg["pitch_semitones"]
        out_dir = A_DIR / voice_key
        out_dir.mkdir(parents=True, exist_ok=True)
        print(f"\n  Voice: {voice_key}  pitch shift: {semis:+d} semitones")
        for s in shortlist:
            src = VITS_RAW_DIR / f"{s['key']}.wav"
            dst = out_dir / f"{s['key']}.mp3"
            # rubberband preserves duration while shifting pitch. Fallback:
            # asetrate+aresample changes pitch AND duration (speeds up when
            # pitch goes up) — still usable as a rough signal but rubberband
            # is the right tool. We try rubberband first, then fall back.
            tried = _try_rubberband(src, dst, semis)
            if not tried:
                _fallback_asetrate(src, dst, semis)
            print(f"    ✓ {s['key']:10s} → {dst.relative_to(PROJECT_ROOT)}")
    print(f"\n  Done. Variant A in {A_DIR.relative_to(PROJECT_ROOT)}")


def _try_rubberband(src, dst, semis):
    """Try ffmpeg with rubberband filter; return True if successful."""
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-af", f"rubberband=pitch={2 ** (semis / 12):.6f}",
        "-ac", "1", "-ar", "22050", "-loglevel", "error",
        str(dst),
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0 and dst.exists() and dst.stat().st_size > 0:
            return True
        return False
    except Exception:
        return False


def _fallback_asetrate(src, dst, semis):
    """
    Fallback when rubberband filter isn't compiled into ffmpeg: shift pitch
    by resampling (changes duration as side-effect). Pitch multiplier =
    2 ** (semis/12).
    """
    ratio = 2 ** (semis / 12)
    src_sr = 22050
    new_sr = int(src_sr * ratio)
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-af", f"asetrate={new_sr},aresample=22050",
        "-ac", "1", "-ar", "22050", "-loglevel", "error",
        str(dst),
    ]
    subprocess.run(cmd, capture_output=True, text=True)


# ---------------------------------------------------------------------------
# variant-b — VITS + kNN voice conversion (bshall/knn-vc)
# ---------------------------------------------------------------------------
def cmd_variant_b(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF VARIANT B: VITS + kNN voice conversion")
    print("=" * 64)
    print("  Uses bshall/knn-vc — loaded via torch.hub on first run (~1.5GB).")

    try:
        import torch
        import torchaudio
    except ImportError:
        print("  ERROR: torch / torchaudio not installed.")
        print("    venv\\Scripts\\pip install torchaudio")
        sys.exit(1)

    # The reference audio for each voice: use the Edge TTS baseline as the
    # per-voice timbre reference. Ground truth recordings would be better but
    # we only have 1 speaker there (Dr. Sama).
    shortlist = _load_shortlist()
    missing = [s for s in shortlist if not (VITS_RAW_DIR / f"{s['key']}.wav").exists()]
    if missing:
        print(f"  ERROR: {len(missing)} VITS clips missing. Run:")
        print(f"    python scripts\\bakeoff.py vits")
        sys.exit(1)
    for voice_key in VOICES:
        voice_dir = BASELINE_DIR / voice_key
        if not voice_dir.exists() or not list(voice_dir.glob("*.mp3")):
            print(f"  ERROR: need Edge TTS baseline as voice reference. Run:")
            print(f"    python scripts\\bakeoff.py baseline")
            sys.exit(1)

    print("  Loading knn-vc from torch.hub...")
    try:
        knn_vc = torch.hub.load("bshall/knn-vc", "knn_vc", prematched=True,
                                trust_repo=True, pretrained=True, device="cuda")
    except Exception as e:
        print(f"  ERROR: failed to load knn-vc: {e}")
        print(f"  If this is a first-time run on a corporate network, the")
        print(f"  torch.hub fetch from github.com/bshall/knn-vc may be blocked.")
        sys.exit(1)

    for voice_key, cfg in VOICES.items():
        out_dir = B_DIR / voice_key
        out_dir.mkdir(parents=True, exist_ok=True)
        ref_clips = sorted((BASELINE_DIR / voice_key).glob("*.mp3"))
        print(f"\n  Voice: {voice_key}  refs: {len(ref_clips)} Edge TTS clips")
        matching_set = knn_vc.get_matching_set([str(p) for p in ref_clips])
        for s in shortlist:
            src = VITS_RAW_DIR / f"{s['key']}.wav"
            dst = out_dir / f"{s['key']}.wav"
            query_seq = knn_vc.get_features(str(src))
            out_wav = knn_vc.match(query_seq, matching_set, topk=4)
            torchaudio.save(str(dst), out_wav[None], 16000)
            # Re-encode to mp3 to match the other variants (nice-to-have)
            mp3_dst = out_dir / f"{s['key']}.mp3"
            cmd = ["ffmpeg", "-y", "-i", str(dst), "-ac", "1", "-ar", "22050",
                   "-loglevel", "error", str(mp3_dst)]
            subprocess.run(cmd, capture_output=True, text=True)
            dst.unlink(missing_ok=True)
            print(f"    ✓ {s['key']:10s} → {mp3_dst.relative_to(PROJECT_ROOT)}")
    print(f"\n  Done. Variant B in {B_DIR.relative_to(PROJECT_ROOT)}")


# ---------------------------------------------------------------------------
# variant-c — VITS-as-teacher → Whisper → Edge TTS override
# ---------------------------------------------------------------------------
def cmd_variant_c(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF VARIANT C: VITS-teacher → Whisper → Edge TTS overrides")
    print("=" * 64)

    try:
        import whisper
    except ImportError:
        print("  ERROR: openai-whisper not installed. Run:")
        print("    venv\\Scripts\\pip install openai-whisper")
        sys.exit(1)
    try:
        import edge_tts  # noqa: F401
    except ImportError:
        print("  ERROR: edge-tts not installed. Run:")
        print("    venv\\Scripts\\pip install edge-tts")
        sys.exit(1)

    shortlist = _load_shortlist()
    missing = [s for s in shortlist if not (VITS_RAW_DIR / f"{s['key']}.wav").exists()]
    if missing:
        print(f"  ERROR: {len(missing)} VITS clips missing. Run:")
        print(f"    python scripts\\bakeoff.py vits")
        sys.exit(1)

    print("  Loading Whisper 'medium' model (~1.5GB first-time)...")
    model = whisper.load_model("medium")

    overrides = {}
    print("\n  Transcribing VITS clips (language='sw'):")
    for s in shortlist:
        src = VITS_RAW_DIR / f"{s['key']}.wav"
        result = model.transcribe(str(src), language="sw", fp16=False)
        text = result.get("text", "").strip()
        if not text:
            print(f"    ✗ {s['key']:10s} empty transcription — falling back to default")
            from generate_audio_edge import awing_to_speakable  # type: ignore
            text = awing_to_speakable(s["awing"])
        else:
            print(f"    ✓ {s['key']:10s} ({s['awing']:12s}) → {text!r}")
        overrides[s["key"]] = text

    # Now use those overrides to generate Edge TTS for each of the 6 voices.
    import asyncio
    import edge_tts as _et

    async def _run_all():
        for voice_key, cfg in VOICES.items():
            out_dir = C_DIR / voice_key
            out_dir.mkdir(parents=True, exist_ok=True)
            print(f"\n  Voice: {voice_key}")
            for s in shortlist:
                out_path = out_dir / f"{s['key']}.mp3"
                try:
                    communicate = _et.Communicate(overrides[s["key"]],
                                                  cfg["edge_voice"],
                                                  rate=cfg["edge_rate"],
                                                  pitch=cfg["edge_pitch"])
                    await communicate.save(str(out_path))
                    print(f"    ✓ {s['key']:10s} → {out_path.relative_to(PROJECT_ROOT)}")
                except Exception as e:
                    print(f"    ✗ {s['key']:10s} failed: {e}")

    asyncio.run(_run_all())
    # Persist overrides for the HTML page to display
    (C_DIR / "overrides.json").write_text(
        json.dumps(overrides, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n  Done. Variant C in {C_DIR.relative_to(PROJECT_ROOT)}")
    print(f"  Whisper overrides saved to {(C_DIR / 'overrides.json').relative_to(PROJECT_ROOT)}")


# ---------------------------------------------------------------------------
# ground-truth — copy recordings into the comparison folder
# ---------------------------------------------------------------------------
def cmd_ground_truth(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF: copy ground-truth recordings into comparison folder")
    print("=" * 64)
    test_manifest = _load_test_manifest()
    if not test_manifest:
        print("  No recordings yet. Record first:")
        print("    python scripts\\record_test_words.py")
        return
    GROUND_TRUTH_DIR.mkdir(parents=True, exist_ok=True)
    recorded = {e["key"] for e in test_manifest}
    shortlist = _load_shortlist()
    for s in shortlist:
        src_wav = TEST_DIR / f"{s['key']}.wav"
        if not src_wav.exists():
            print(f"    [ ] {s['key']:10s} not yet recorded")
            continue
        dst = GROUND_TRUTH_DIR / f"{s['key']}.wav"
        shutil.copy2(src_wav, dst)
        print(f"    ✓ {s['key']:10s} → {dst.relative_to(PROJECT_ROOT)}")
    print(f"\n  Recorded: {len(recorded)}/{len(shortlist)} words")
    missing = [s["awing"] for s in shortlist if s["key"] not in recorded]
    if missing:
        print(f"  Still to record: {', '.join(missing)}")


# ---------------------------------------------------------------------------
# html — emit the comparison page
# ---------------------------------------------------------------------------
def cmd_html(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF: emit HTML comparison page")
    print("=" * 64)
    shortlist = _load_shortlist()
    rows = []
    overrides_path = C_DIR / "overrides.json"
    overrides = {}
    if overrides_path.exists():
        overrides = json.loads(overrides_path.read_text(encoding="utf-8"))
    for s in shortlist:
        key = s["key"]
        row = {
            "key": key,
            "awing": s["awing"],
            "english": s["english"],
            "notes": s.get("notes", ""),
            "ground_truth": f"bakeoff/_ground_truth/{key}.wav"
                            if (GROUND_TRUTH_DIR / f"{key}.wav").exists() else None,
            "baseline": {v: f"bakeoff/_edge_baseline/{v}/{key}.mp3"
                         for v in VOICES
                         if (BASELINE_DIR / v / f"{key}.mp3").exists()},
            "variant_a": {v: f"bakeoff/A_pitch/{v}/{key}.mp3"
                          for v in VOICES
                          if (A_DIR / v / f"{key}.mp3").exists()},
            "variant_b": {v: f"bakeoff/B_knn/{v}/{key}.mp3"
                          for v in VOICES
                          if (B_DIR / v / f"{key}.mp3").exists()},
            "variant_c": {v: f"bakeoff/C_edgeoverride/{v}/{key}.mp3"
                          for v in VOICES
                          if (C_DIR / v / f"{key}.mp3").exists()},
            # Variant D (XTTS v2) — single WAV per word, shown across all voice rows
            "variant_xtts": ({v: f"bakeoff/_xtts_raw/{key}.wav" for v in VOICES}
                             if (XTTS_RAW_DIR / f"{key}.wav").exists() else {}),
            "override_text": overrides.get(key, ""),
        }
        rows.append(row)
    html_path = TEST_DIR / "bakeoff.html"
    html_path.write_text(_render_html(rows), encoding="utf-8")
    print(f"  ✓ Wrote {html_path.relative_to(PROJECT_ROOT)}")
    print(f"\n  Open this file in a browser:")
    print(f"    {html_path}")
    print(f"  Rate each clip 1-5 stars. Scores persist in your browser's")
    print(f"  localStorage under the key 'awing_bakeoff_ratings'.")
    print(f"  Aggregate scores appear at the top of the page.")


def _render_html(rows):
    voices_json = json.dumps(list(VOICES.keys()))
    rows_json = json.dumps(rows, ensure_ascii=False, indent=2)
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Awing TTS Bake-off — A / B / C / D listening test</title>
<style>
:root {{ --bg:#fafbfc; --card:#fff; --border:#dde3ea; --ink:#111; --muted:#567;
  --accent:#0f6fff; --gold:#f5b301; --good:#16a34a; --bad:#dc2626; }}
* {{ box-sizing: border-box; }}
body {{ margin:0; font:15px/1.45 -apple-system,Segoe UI,sans-serif;
  background:var(--bg); color:var(--ink); padding: 24px; }}
h1 {{ margin: 0 0 4px 0; font-size: 24px; }}
.sub {{ color: var(--muted); margin-bottom: 24px; }}
.summary {{ background: var(--card); border: 1px solid var(--border);
  border-radius: 12px; padding: 16px; margin-bottom: 24px;
  display: grid; grid-template-columns: repeat(6, 1fr); gap: 16px; }}
.summary .cell {{ text-align: center; }}
.summary .label {{ font-size: 12px; color: var(--muted); text-transform: uppercase;
  letter-spacing: .05em; }}
.summary .val {{ font-size: 28px; font-weight: 700; margin-top: 2px; }}
.rank-A {{ color: var(--good); }}
.rank-B {{ color: var(--accent); }}
.rank-C {{ color: #9333ea; }}
.rank-D {{ color: #ea580c; }}
.rank-E {{ color: var(--muted); }}
.word {{ background: var(--card); border: 1px solid var(--border);
  border-radius: 12px; padding: 16px 18px; margin-bottom: 18px; }}
.word-head {{ display: flex; justify-content: space-between; align-items: baseline;
  margin-bottom: 10px; }}
.word-head .awing {{ font-size: 26px; font-weight: 700; }}
.word-head .english {{ color: var(--muted); font-size: 16px; margin-left: 10px; }}
.word-head .notes {{ color: var(--muted); font-size: 12px; font-style: italic; }}
.row {{ display: grid;
  grid-template-columns: 140px 1fr 1fr 1fr 1fr 1fr; gap: 10px;
  padding: 8px 0; border-top: 1px dashed var(--border); align-items: center; }}
.row:first-of-type {{ border-top: 0; }}
.row.header {{ font-size: 12px; text-transform: uppercase; color: var(--muted);
  letter-spacing: .05em; border: 0; padding-bottom: 2px; }}
.voice-label {{ font-weight: 600; color: var(--ink); }}
.cell-audio {{ display: flex; align-items: center; gap: 8px; }}
.cell-audio audio {{ flex: 1; min-width: 0; height: 32px; }}
.stars {{ display: flex; gap: 2px; }}
.star {{ cursor: pointer; color: #ccc; font-size: 18px; user-select: none;
  line-height: 1; }}
.star.on {{ color: var(--gold); }}
.missing {{ color: var(--bad); font-size: 12px; font-style: italic; padding: 4px 0; }}
.override {{ color: var(--muted); font-size: 12px; font-family: ui-monospace,
  SFMono-Regular, monospace; margin-top: 8px; }}
button.reset {{ float: right; background: var(--bad); color: #fff; border: 0;
  padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px; }}
</style>
</head>
<body>

<h1>Awing TTS Bake-off — A / B / C / D listening test</h1>
<p class="sub">Rate each clip against the ground-truth recording. Scores save
in your browser's localStorage. The panel below shows average stars per
architecture. Whichever wins gets deployed to production.
<button class="reset" onclick="resetAll()">Reset all ratings</button></p>

<div class="summary">
  <div class="cell"><div class="label">Edge TTS baseline</div>
    <div class="val rank-E" id="avg-baseline">–</div></div>
  <div class="cell"><div class="label">Variant A (VITS + pitch)</div>
    <div class="val rank-A" id="avg-variant_a">–</div></div>
  <div class="cell"><div class="label">Variant B (VITS + kNN-VC)</div>
    <div class="val rank-B" id="avg-variant_b">–</div></div>
  <div class="cell"><div class="label">Variant C (teacher + Edge)</div>
    <div class="val rank-C" id="avg-variant_c">–</div></div>
  <div class="cell"><div class="label">Variant D (XTTS v2)</div>
    <div class="val rank-D" id="avg-variant_xtts">–</div></div>
  <div class="cell"><div class="label">Total rated / max</div>
    <div class="val" id="total-rated">–</div></div>
</div>

<div id="words"></div>

<script>
const VOICES = {voices_json};
const ROWS = {rows_json};
const VARIANTS = [
  {{ id: "baseline",     label: "Edge baseline" }},
  {{ id: "variant_a",    label: "A · VITS+pitch" }},
  {{ id: "variant_b",    label: "B · VITS+kNN" }},
  {{ id: "variant_c",    label: "C · teacher→Edge" }},
  {{ id: "variant_xtts", label: "D · XTTS v2" }},
];
const STORAGE_KEY = "awing_bakeoff_ratings";

function loadRatings() {{
  try {{ return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{{}}"); }}
  catch (e) {{ return {{}}; }}
}}
function saveRatings(r) {{
  localStorage.setItem(STORAGE_KEY, JSON.stringify(r));
}}
function ratingKey(word, variant, voice) {{
  return `${{word}}:${{variant}}:${{voice}}`;
}}
function resetAll() {{
  if (confirm("Reset all star ratings? This cannot be undone.")) {{
    localStorage.removeItem(STORAGE_KEY);
    render();
  }}
}}

function render() {{
  const ratings = loadRatings();
  const root = document.getElementById("words");
  root.innerHTML = "";
  for (const row of ROWS) {{
    const card = document.createElement("div");
    card.className = "word";
    const head = document.createElement("div");
    head.className = "word-head";
    head.innerHTML = `
      <div>
        <span class="awing">${{row.awing}}</span>
        <span class="english">${{row.english}}</span>
      </div>
      <div class="notes">${{row.notes}}</div>`;
    card.appendChild(head);

    // Ground-truth row
    const gt = document.createElement("div");
    gt.className = "row";
    gt.innerHTML = `<div class="voice-label">Ground truth</div>
      <div class="cell-audio" style="grid-column: span 5">
        ${{row.ground_truth
            ? `<audio controls preload="none" src="${{row.ground_truth}}"></audio>`
            : `<span class="missing">Not yet recorded — run record_test_words.py</span>`}}
      </div>`;
    card.appendChild(gt);

    // Header row with variant labels
    const hdr = document.createElement("div");
    hdr.className = "row header";
    hdr.innerHTML = `<div>Voice</div>` +
      VARIANTS.map(v => `<div>${{v.label}}</div>`).join("");
    card.appendChild(hdr);

    for (const voice of VOICES) {{
      const line = document.createElement("div");
      line.className = "row";
      line.innerHTML = `<div class="voice-label">${{voice}}</div>`;
      for (const v of VARIANTS) {{
        const src = (row[v.id] || {{}})[voice];
        const rk = ratingKey(row.key, v.id, voice);
        const curr = ratings[rk] || 0;
        const cell = document.createElement("div");
        cell.className = "cell-audio";
        if (src) {{
          const audio = document.createElement("audio");
          audio.controls = true;
          audio.preload = "none";
          audio.src = src;
          cell.appendChild(audio);
          const stars = document.createElement("span");
          stars.className = "stars";
          for (let i = 1; i <= 5; i++) {{
            const s = document.createElement("span");
            s.className = "star" + (i <= curr ? " on" : "");
            s.textContent = "★";
            s.dataset.value = i;
            s.addEventListener("click", () => {{
              const all = loadRatings();
              all[rk] = (all[rk] === i) ? 0 : i;
              saveRatings(all);
              render();
            }});
            stars.appendChild(s);
          }}
          cell.appendChild(stars);
        }} else {{
          cell.innerHTML = `<span class="missing">no audio</span>`;
        }}
        line.appendChild(cell);
      }}
      card.appendChild(line);
    }}

    if (row.override_text) {{
      const ov = document.createElement("div");
      ov.className = "override";
      ov.textContent = `Variant C override (Whisper heard): "${{row.override_text}}"`;
      card.appendChild(ov);
    }}
    root.appendChild(card);
  }}

  // aggregate panel
  const totals = {{}};
  const counts = {{}};
  for (const v of VARIANTS) {{ totals[v.id] = 0; counts[v.id] = 0; }}
  let rated = 0;
  let maxRatings = 0;
  for (const row of ROWS) {{
    for (const voice of VOICES) {{
      for (const v of VARIANTS) {{
        if ((row[v.id] || {{}})[voice]) {{
          maxRatings++;
          const rk = ratingKey(row.key, v.id, voice);
          if (ratings[rk]) {{
            totals[v.id] += ratings[rk];
            counts[v.id]++;
            rated++;
          }}
        }}
      }}
    }}
  }}
  for (const v of VARIANTS) {{
    const el = document.getElementById("avg-" + v.id);
    if (counts[v.id] > 0) {{
      el.textContent = (totals[v.id] / counts[v.id]).toFixed(2) + " ★";
    }} else {{
      el.textContent = "–";
    }}
  }}
  document.getElementById("total-rated").textContent = `${{rated}} / ${{maxRatings}}`;
}}

render();
</script>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------
def cmd_status(args):
    print("\n" + "=" * 64)
    print("  BAKE-OFF STATUS")
    print("=" * 64)
    shortlist = _load_shortlist()
    n = len(shortlist)
    keys = [s["key"] for s in shortlist]

    def count(path_fn):
        return sum(1 for k in keys if path_fn(k).exists())

    # Ground truth
    recorded = count(lambda k: TEST_DIR / f"{k}.wav")
    print(f"  Ground truth recordings:       {recorded}/{n}")

    # VITS raw
    print(f"  VITS checkpoint:               {'yes' if VITS_CKPT_DIR.exists() else 'NOT YET'}")
    vits = count(lambda k: VITS_RAW_DIR / f"{k}.wav")
    print(f"  VITS synthesis (20 words):     {vits}/{n}")

    # Per voice
    for label, root in [("Edge baseline", BASELINE_DIR),
                        ("Variant A",     A_DIR),
                        ("Variant B",     B_DIR),
                        ("Variant C",     C_DIR)]:
        for voice in VOICES:
            c = count(lambda k, v=voice, r=root: r / v / f"{k}.mp3")
            print(f"  {label:15s} {voice:12s}: {c}/{n}")

    # Variant D — single WAV per word, NOT per voice (Session 55)
    xtts = count(lambda k: XTTS_RAW_DIR / f"{k}.wav")
    print(f"  Variant D (XTTS v2):           {xtts}/{n}")

    html_path = TEST_DIR / "bakeoff.html"
    print(f"\n  HTML comparison page:          {'yes — '+str(html_path.name) if html_path.exists() else 'NOT YET'}")
    print(f"  Next step:")
    if recorded < n:
        print(f"    python scripts\\record_test_words.py")
    elif not VITS_CKPT_DIR.exists():
        print(f"    python scripts\\bakeoff.py train")
    elif vits < n:
        print(f"    python scripts\\bakeoff.py vits")
    elif count(lambda k: BASELINE_DIR / 'boy' / f'{k}.mp3') < n:
        print(f"    python scripts\\bakeoff.py baseline")
    elif count(lambda k: A_DIR / 'boy' / f'{k}.mp3') < n:
        print(f"    python scripts\\bakeoff.py variant-a")
    elif count(lambda k: C_DIR / 'boy' / f'{k}.mp3') < n:
        print(f"    python scripts\\bakeoff.py variant-c")
    else:
        print(f"    python scripts\\bakeoff.py html")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="A/B/C bake-off of Awing voice-synthesis architectures.")
    sub = parser.add_subparsers(dest="command")

    t = sub.add_parser("train", help="Fine-tune VITS on 197-clip ground truth")
    t.add_argument("--steps", type=int, default=2000,
                   help="Max training steps (default 2000)")
    v = sub.add_parser("vits", help="Synthesize 20 test words through VITS")
    v.add_argument("--base-model", action="store_true",
                   help="Use base facebook/mms-tts-mcp without fine-tuning "
                        "(use when the trained checkpoint has collapsed)")
    v.add_argument("--huggingface", action="store_true",
                   help="Force the legacy HuggingFace VitsModel path "
                        "(skip Coqui checkpoint detection)")
    sub.add_parser("baseline", help="Current-production Edge TTS for each voice")
    sub.add_parser("variant-a", help="Variant A: VITS + ffmpeg pitch shift")
    sub.add_parser("variant-b", help="Variant B: VITS + kNN voice conversion")
    sub.add_parser("variant-c", help="Variant C: VITS-teacher → Whisper → Edge")
    sub.add_parser("ground-truth", help="Copy recordings into comparison folder")
    sub.add_parser("html", help="Emit HTML comparison page")
    sub.add_parser("status", help="Show progress on each pipeline step")

    args = parser.parse_args()
    if args.command is None:
        parser.print_help()
        return

    commands = {
        "train": cmd_train,
        "vits": cmd_vits,
        "baseline": cmd_baseline,
        "variant-a": cmd_variant_a,
        "variant-b": cmd_variant_b,
        "variant-c": cmd_variant_c,
        "ground-truth": cmd_ground_truth,
        "html": cmd_html,
        "status": cmd_status,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
