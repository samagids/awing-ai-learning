#!/usr/bin/env python3
"""Generate Awing audio with a fine-tuned LoRA voice.

Loads:
  1. The base model (Qwen3-TTS-12Hz-0.6B-Base)
  2. The LoRA adapter from <checkpoint_dir>/  (saved by sft_lora.py)
  3. The manually-unfrozen state from <checkpoint_dir>/manual_unfrozen_state.safetensors
  4. A reference audio (default: the locked voice WAV from voice_prompts.json)

Generates audio for a small set of Awing test words/phrases and writes
WAVs into a sibling test_output/ directory under the checkpoint.

Run inside WSL with venv_qwen3 active:
  source ~/venv_qwen3/bin/activate
  python3 scripts/ml/tts/generate_awing.py boy

  # or specify a different epoch's checkpoint:
  python3 scripts/ml/tts/generate_awing.py boy --epoch 2

  # custom test phrases:
  python3 scripts/ml/tts/generate_awing.py boy --texts "apô" "kɨ́'ə" "Lɛ̌ ndzaŋ"

Listens at:
  ~/awing_models/qwen3_awing_<voice>/test_output/<text>.wav
  (Or wherever the checkpoint dir lives.)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

# Suppress noisy upstream warnings
import warnings
warnings.filterwarnings("ignore", message=".*torch_dtype.*")
warnings.filterwarnings("ignore", message=".*use_cache=True.*")

REPO_ROOT = Path(__file__).resolve().parents[3]
VOICE_PROMPTS = REPO_ROOT / "scripts" / "ml" / "tts" / "voice_prompts.json"

DEFAULT_TEXTS = [
    "apô",                            # hand
    "ndě",                            # neck (or water)
    "kɨ́'ə",                           # prevent
    "Móonə",                          # baby
    "ŋgóonɛ́",                         # snail
    "Ghǒ ghɛnɔ́ lə əfó?",             # Where are you going?
    "Lɛ̌ ndzaŋ pətǎ",                 # opening of the gospel of Matthew
]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("voice", help="Voice name (boy, girl, young_man, young_woman, man, woman)")
    ap.add_argument("--checkpoint_dir", type=str, default=None,
                    help="Override checkpoint dir. Default: "
                         "~/awing_models/qwen3_awing_<voice>/checkpoint-epoch-<latest>/")
    ap.add_argument("--epoch", type=int, default=None,
                    help="Specific epoch number to load (default: latest available)")
    ap.add_argument("--base_model", type=str,
                    default="Qwen/Qwen3-TTS-12Hz-0.6B-Base",
                    help="Base model the adapter was trained against")
    ap.add_argument("--ref_audio", type=str, default=None,
                    help="Path to reference voice WAV. Default: read from voice_prompts.json")
    ap.add_argument("--texts", nargs="+", default=None,
                    help="Awing texts to synthesize. Default: a small built-in set.")
    ap.add_argument("--language", type=str, default="English",
                    help="Language hint passed to the model. Awing isn't supported, "
                         "but English/Portuguese are useful approximations.")
    ap.add_argument("--out_dir", type=str, default=None,
                    help="Where to write WAVs. Default: <checkpoint_dir>/test_output/")
    args = ap.parse_args()

    # --- Resolve voice config ----------------------------------------
    if not VOICE_PROMPTS.exists():
        print(f"ERROR: voice_prompts.json missing at {VOICE_PROMPTS}")
        return 1
    voice_cfg = json.loads(VOICE_PROMPTS.read_text(encoding="utf-8"))
    if args.voice not in voice_cfg["voices"]:
        print(f"ERROR: unknown voice '{args.voice}'. Known: "
              f"{list(voice_cfg['voices'].keys())}")
        return 1
    vinfo = voice_cfg["voices"][args.voice]

    # --- Resolve checkpoint dir --------------------------------------
    if args.checkpoint_dir:
        ckpt_dir = Path(args.checkpoint_dir)
    else:
        # Default location is ~/awing_models per train_voice.sh.
        # Fall back to the OneDrive path if that doesn't exist (older runs).
        candidates = [
            Path.home() / "awing_models" / f"qwen3_awing_{args.voice}",
            REPO_ROOT / "models" / f"qwen3_awing_{args.voice}",
        ]
        base_dir = next((c for c in candidates if c.exists()), None)
        if base_dir is None:
            print(f"ERROR: no checkpoint base dir found. Tried:")
            for c in candidates:
                print(f"  {c}")
            return 1
        # Find checkpoint-epoch-N
        ep_dirs = []
        for d in base_dir.iterdir():
            if d.is_dir() and d.name.startswith("checkpoint-epoch-"):
                try:
                    ep_dirs.append((int(d.name.rsplit("-", 1)[-1]), d))
                except ValueError:
                    continue
        if not ep_dirs:
            print(f"ERROR: no checkpoint-epoch-N dirs in {base_dir}")
            return 1
        ep_dirs.sort()
        if args.epoch is not None:
            match = [d for n, d in ep_dirs if n == args.epoch]
            if not match:
                print(f"ERROR: epoch {args.epoch} not found. Available: "
                      f"{[n for n, _ in ep_dirs]}")
                return 1
            ckpt_dir = match[0]
        else:
            ckpt_dir = ep_dirs[-1][1]

    print(f"Voice:       {args.voice}")
    print(f"Checkpoint:  {ckpt_dir}")

    # --- Resolve ref audio -------------------------------------------
    if args.ref_audio:
        ref_audio = Path(args.ref_audio)
    else:
        ref_audio = REPO_ROOT / vinfo["ref_wav"]
    if not ref_audio.exists():
        print(f"ERROR: ref_audio missing: {ref_audio}")
        return 1
    print(f"Ref audio:   {ref_audio}")

    # --- Resolve out dir + texts -------------------------------------
    out_dir = Path(args.out_dir) if args.out_dir else (ckpt_dir / "test_output")
    out_dir.mkdir(parents=True, exist_ok=True)
    texts = args.texts if args.texts else DEFAULT_TEXTS
    print(f"Output dir:  {out_dir}")
    print(f"Texts:       {len(texts)} to synthesize")
    print()

    # --- Load model + adapter ----------------------------------------
    import torch
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available.")
        return 1

    print("Loading base model on GPU (device_map='cuda:0')...")
    from qwen_tts import Qwen3TTSModel
    qwen3tts = Qwen3TTSModel.from_pretrained(
        args.base_model,
        dtype=torch.bfloat16,
        attn_implementation="sdpa",
        device_map="cuda:0",
    )

    print("Applying LoRA adapter from checkpoint...")
    from peft import PeftModel
    qwen3tts.model.talker = PeftModel.from_pretrained(
        qwen3tts.model.talker, str(ckpt_dir)
    ).to("cuda:0")

    # Load manually-unfrozen state (codec_embedding + lm_head)
    manual_file = ckpt_dir / "manual_unfrozen_state.safetensors"
    if manual_file.exists():
        from safetensors.torch import load_file
        manual_state = load_file(str(manual_file), device="cuda:0")
        result = qwen3tts.model.load_state_dict(manual_state, strict=False)
        unexpected = [k for k in result.unexpected_keys if "lora_" not in k]
        print(f"  Manual state loaded: {len(manual_state)} tensors")
        if unexpected:
            print(f"  WARNING: {len(unexpected)} unexpected keys (e.g. {unexpected[:2]})")

    # --- The codec_embedding[3000] patch (Option 1's actual content) -
    # sft_12hz.py performs this at save time; we didn't. The trained
    # target_speaker_embedding gets written into the slot that the
    # custom_voice inference path expects to find the speaker
    # conditioning. Plus we register the speaker_name -> 3000 mapping
    # in the model config so the inference path can resolve the name.
    spk_emb_file = ckpt_dir / "target_speaker_embedding.pt"
    speaker_name = f"awing_{args.voice}"
    if spk_emb_file.exists():
        spk_emb = torch.load(str(spk_emb_file), map_location="cuda:0", weights_only=True)
        # Find the actual codec_embedding nn.Embedding through PEFT wrap
        # and write our trained speaker into slot 3000.
        try:
            talker_inner = qwen3tts.model.talker.base_model.model.model
            with torch.no_grad():
                # spk_emb shape may be (D,) or (1, D) — flatten safely
                if spk_emb.ndim > 1:
                    spk_emb = spk_emb.squeeze(0)
                talker_inner.codec_embedding.weight.data[3000] = spk_emb.to(
                    talker_inner.codec_embedding.weight.dtype
                ).to(talker_inner.codec_embedding.weight.device)
            print(f"  Patched codec_embedding[3000] with target_speaker_embedding "
                  f"(shape {tuple(spk_emb.shape)})")
        except AttributeError as e:
            print(f"  WARNING: couldn't patch codec_embedding[3000]: {e}")

        # Register the spk_id mapping in the live config object.
        try:
            talker_cfg = qwen3tts.model.config.talker_config
            existing = getattr(talker_cfg, "spk_id", None) or {}
            if isinstance(existing, dict):
                existing[speaker_name] = 3000
                if hasattr(talker_cfg, "spk_id"):
                    talker_cfg.spk_id = existing
                else:
                    setattr(talker_cfg, "spk_id", existing)
            existing_dialect = getattr(talker_cfg, "spk_is_dialect", None) or {}
            if isinstance(existing_dialect, dict):
                existing_dialect[speaker_name] = False
                setattr(talker_cfg, "spk_is_dialect", existing_dialect)
            qwen3tts.model.config.tts_model_type = "custom_voice"
            print(f"  Registered speaker '{speaker_name}' -> slot 3000 in talker_config")
        except Exception as e:
            print(f"  WARNING: couldn't register spk_id: {e}")
    else:
        print(f"  WARNING: target_speaker_embedding.pt not found, skipping patch")

    qwen3tts.model.eval()
    print(f"Model loaded. VRAM: {torch.cuda.memory_allocated() / 1e9:.1f} GB\n")

    # --- Generate ----------------------------------------------------
    import soundfile as sf

    # The boy_v2.wav transcript (from voice_prompts.json — the test
    # sentence we used to generate it via VoiceDesign back in the
    # smoke test). We pass this as ref_text for ICL-mode inference.
    ref_text = voice_cfg.get(
        "test_sentence",
        "The voice of the people speaking together creates a great sound.",
    )
    print(f"  ICL ref_text: {ref_text!r}")
    print()

    # Multi-strategy synthesis. For each test phrase try every approach
    # in sequence; save whatever produces audio under a strategy-suffixed
    # filename so you can A/B them.
    strategies = [
        ("icl", "ICL: ref_audio + ref_text"),
        ("xvec", "x_vector_only_mode (was the original try)"),
        ("design", "VoiceDesign-style instruct prompt"),
    ]

    for i, text in enumerate(texts):
        safe_name = "".join(c if c.isalnum() else "_" for c in text)[:32]
        print(f"[{i:02d}] {text!r}")

        for strat_id, strat_label in strategies:
            out_path = out_dir / f"{i:02d}_{safe_name}__{strat_id}.wav"
            try:
                if strat_id == "icl":
                    wavs, sr = qwen3tts.generate_voice_clone(
                        text=text,
                        language=args.language,
                        ref_audio=str(ref_audio),
                        ref_text=ref_text,
                        x_vector_only_mode=False,
                    )
                elif strat_id == "xvec":
                    wavs, sr = qwen3tts.generate_voice_clone(
                        text=text,
                        language=args.language,
                        ref_audio=str(ref_audio),
                        x_vector_only_mode=True,
                    )
                elif strat_id == "design":
                    if not hasattr(qwen3tts, "generate_voice_design"):
                        print(f"     {strat_id:6s} skipped (Base model has no voice_design)")
                        continue
                    wavs, sr = qwen3tts.generate_voice_design(
                        text=text,
                        language=args.language,
                        instruct=vinfo.get("instruct", "A clear voice"),
                    )
                else:
                    continue
                sf.write(str(out_path), wavs[0], sr)
                duration = len(wavs[0]) / sr
                print(f"     {strat_id:6s} -> {out_path.name}  ({duration:.2f}s)")
            except Exception as e:
                msg = str(e)[:120]
                print(f"     {strat_id:6s} FAILED: {type(e).__name__}: {msg}")

    print()
    print(f"Done. Listen to outputs in {out_dir}/")
    print()
    print("From Windows, browse to:")
    s = str(out_dir)
    if s.startswith("/mnt/"):
        # /mnt/c/Users/... -> C:\Users\...
        drive = s[5].upper()
        win_path = drive + ":" + s[6:].replace("/", "\\")
    elif s.startswith("/home/"):
        # /home/samag/... -> \\wsl.localhost\Ubuntu\home\samag\...
        win_path = "\\\\wsl.localhost\\Ubuntu" + s.replace("/", "\\")
    else:
        win_path = s
    print(f"  {win_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
