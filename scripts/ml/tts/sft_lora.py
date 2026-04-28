#!/usr/bin/env python3
"""LoRA fine-tune Qwen3-TTS-12Hz-1.7B-Base on Awing.

Why this exists (vs. upstream sft_12hz.py)
------------------------------------------
sft_12hz.py does FULL fine-tuning: every weight is trainable, AdamW
holds two fp32 states (m, v) per parameter. For the 1.7B base that's
~13.6 GB of optimizer state alone — busts the 12 GB RTX 5070 even
after gradient checkpointing + 8-bit AdamW + batch=1.

This script swaps in PEFT LoRA:
  - Base model: frozen, no gradients, no optimizer state. Just sits in
    bf16 at ~3.4 GB.
  - LoRA adapters on q/k/v/o/gate/up/down projections across all 28
    talker decoder layers + 5 code_predictor layers. ~10-20M trainable
    params total (vs 1.7B for full fine-tune).
  - Selectively unfrozen modules: codec_embedding, text_projection,
    code_predictor.lm_head — the small Awing-acoustics-critical pieces
    that LoRA's rank-r approximation may not capture well.
  - 8-bit AdamW from bitsandbytes covers the small set of trainable
    params.

Memory budget on 12 GB card:
  Base bf16:                ~3.4 GB
  LoRA adapter + grads:     ~50 MB
  Optimizer state (8-bit):  ~150 MB (covers LoRA + unfrozen modules)
  Activations (checkpoint): ~1-2 GB
  Speaker enc + ref audio:  ~0.5 GB
  Total peak:               ~5-6 GB (comfortable headroom)

Output
------
  <output_model_path>/checkpoint-epoch-N/
      adapter_model.safetensors    — LoRA weights (~50 MB)
      adapter_config.json          — PEFT config
      modules_to_save_state.pt     — state for unfrozen non-LoRA modules
      target_speaker_embedding.pt  — captured during training, used at
                                     inference to set codec_embedding[3000]

Inference: load base, then peft.PeftModel.from_pretrained(base, ckpt_dir),
then load modules_to_save_state.pt and target_speaker_embedding.pt.
"""

from __future__ import annotations

import argparse
import atexit
import json
import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

import torch
from torch.utils.data import DataLoader

# Suppress noisy upstream "torch_dtype deprecated" + "use_cache=False" lines
# during long training runs.
import warnings
warnings.filterwarnings("ignore", message=".*torch_dtype.*")
warnings.filterwarnings("ignore", message=".*use_cache=True.*")


def _find_latest_checkpoint(output_dir: Path):
    """Return (epoch_num, dir_path) of the highest-numbered
    checkpoint-epoch-N under output_dir, or None if none found.
    """
    if not output_dir.exists():
        return None
    candidates = []
    for d in output_dir.iterdir():
        if d.is_dir() and d.name.startswith("checkpoint-epoch-"):
            try:
                n = int(d.name.rsplit("-", 1)[-1])
                # Verify it has at least the LoRA adapter
                if (d / "adapter_model.safetensors").exists() or \
                   (d / "adapter_model.bin").exists():
                    candidates.append((n, d))
            except ValueError:
                continue
    if not candidates:
        return None
    candidates.sort()
    return candidates[-1]


def _resume_from_checkpoint(qwen3tts_model, ckpt_dir: Path) -> None:
    """Load LoRA adapter + manually-unfrozen state from a previous
    checkpoint into the already-PEFT-wrapped model in place.

    Strict=False because the LoRA-wrapped state_dict has a slightly
    different naming pattern from the saved adapter; missing/unexpected
    keys are normal as long as the numbers are small.
    """
    from safetensors.torch import load_file

    print(f"  Resuming from {ckpt_dir}")

    # 1. LoRA adapter weights — saved by PeftModel.save_pretrained()
    adapter_file = ckpt_dir / "adapter_model.safetensors"
    if not adapter_file.exists():
        adapter_file = ckpt_dir / "adapter_model.bin"
    if adapter_file.exists():
        adapter_state = load_file(str(adapter_file)) if adapter_file.suffix == ".safetensors" \
            else torch.load(str(adapter_file), map_location="cpu", weights_only=True)
        # Talker is PeftModel; load_state_dict on it handles the LoRA
        # naming. modules_to_save (text_projection) state is also in this
        # file because PEFT serialises both together.
        result = qwen3tts_model.talker.load_state_dict(adapter_state, strict=False)
        missing, unexpected = result.missing_keys, result.unexpected_keys
        # Filter out the expected misses (frozen base weights aren't in adapter)
        unexpected = [k for k in unexpected if "lora_" not in k]
        print(f"    Adapter loaded: {len(adapter_state)} tensors")
        if unexpected:
            print(f"    Unexpected adapter keys: {len(unexpected)} (first 3: {unexpected[:3]})")

    # 2. Manually-unfrozen state (codec_embedding + lm_head ModuleList)
    manual_file = ckpt_dir / "manual_unfrozen_state.safetensors"
    if manual_file.exists():
        manual_state = load_file(str(manual_file))
        result = qwen3tts_model.load_state_dict(manual_state, strict=False)
        # Most keys will be "missing" because we're only providing the
        # manually-unfrozen subset. We just want to confirm no UNEXPECTED.
        unexpected = [k for k in result.unexpected_keys if "lora_" not in k]
        print(f"    Manual state loaded: {len(manual_state)} tensors")
        if unexpected:
            print(f"    Unexpected manual keys: {len(unexpected)}")
    else:
        print(f"    WARNING: {manual_file.name} not found — codec_embedding "
              f"and lm_head will start from base weights")


def _start_memory_monitor(out_path: Path, interval_s: float = 2.0):
    """Background thread that logs VRAM, system RAM, and GPU util every
    interval_s seconds to a CSV. Survives system freezes — the file is
    fsync'd every line so recovery after a hard reset still tells us
    what the last sample looked like before the freeze.
    """
    out_path.parent.mkdir(parents=True, exist_ok=True)
    stop = threading.Event()

    def _read_meminfo():
        with open("/proc/meminfo") as f:
            d = {}
            for line in f:
                k, _, v = line.partition(":")
                d[k.strip()] = int(v.strip().split()[0])  # KB
        total = d.get("MemTotal", 0)
        avail = d.get("MemAvailable", 0)
        return total, avail

    def _read_gpu():
        try:
            out = subprocess.check_output(
                ["nvidia-smi",
                 "--query-gpu=memory.used,memory.total,utilization.gpu,utilization.memory,temperature.gpu",
                 "--format=csv,noheader,nounits"],
                timeout=2,
            ).decode().strip()
            used_mb, total_mb, gpu_util, mem_util, temp = out.split(", ")
            return int(used_mb), int(total_mb), int(gpu_util), int(mem_util), int(temp)
        except Exception:
            return 0, 0, 0, 0, 0

    def _loop():
        f = open(out_path, "w", buffering=1)  # line-buffered
        f.write("ts,wall_s,sys_ram_used_gb,sys_ram_total_gb,vram_used_gb,vram_total_gb,gpu_util_pct,vram_util_pct,gpu_temp_c,torch_alloc_gb,torch_reserved_gb\n")
        f.flush()
        os.fsync(f.fileno())
        t0 = time.time()
        while not stop.is_set():
            mt_kb, ma_kb = _read_meminfo()
            sys_ram_used_gb = (mt_kb - ma_kb) / 1024 / 1024
            sys_ram_total_gb = mt_kb / 1024 / 1024
            vmu, vmt, gu, mu, tc = _read_gpu()
            try:
                torch_alloc = torch.cuda.memory_allocated() / 1e9
                torch_reserved = torch.cuda.memory_reserved() / 1e9
            except Exception:
                torch_alloc = 0
                torch_reserved = 0
            f.write(f"{time.time():.0f},{time.time()-t0:.1f},"
                    f"{sys_ram_used_gb:.2f},{sys_ram_total_gb:.2f},"
                    f"{vmu/1024:.2f},{vmt/1024:.2f},"
                    f"{gu},{mu},{tc},"
                    f"{torch_alloc:.2f},{torch_reserved:.2f}\n")
            f.flush()
            os.fsync(f.fileno())
            stop.wait(interval_s)
        f.close()

    t = threading.Thread(target=_loop, daemon=True)
    t.start()

    def _stop():
        stop.set()
        t.join(timeout=interval_s + 1)
    atexit.register(_stop)
    return _stop


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--init_model_path", type=str,
                        default="Qwen/Qwen3-TTS-12Hz-0.6B-Base")
    parser.add_argument("--output_model_path", type=str, default="output")
    parser.add_argument("--train_jsonl", type=str, required=True)
    parser.add_argument("--batch_size", type=int, default=1)
    parser.add_argument("--lr", type=float, default=1e-4,
                        help="LoRA fine-tunes use higher LR than full FT "
                             "(2e-6). 1e-4 is the PEFT community default.")
    parser.add_argument("--num_epochs", type=int, default=10)
    parser.add_argument("--speaker_name", type=str, default="awing_voice")
    parser.add_argument("--lora_r", type=int, default=16,
                        help="LoRA rank. r=16 is standard; raise to 32 if "
                             "underfitting suspected.")
    parser.add_argument("--lora_alpha", type=int, default=32,
                        help="LoRA alpha (scaling). Convention: alpha = 2*r.")
    parser.add_argument("--lora_dropout", type=float, default=0.05)
    parser.add_argument("--grad_accum", type=int, default=4,
                        help="Gradient accumulation steps. Effective batch "
                             "= batch_size * grad_accum. Default 4 -> eff. 4.")
    parser.add_argument("--vram_fraction", type=float, default=0.65,
                        help="Cap PyTorch VRAM usage at this fraction of "
                             "total. PREVENTS PC FREEZES caused by Windows "
                             "shared-memory swap. On a 12 GB card, 0.65 = "
                             "7.8 GB hard cap. Beyond this PyTorch raises a "
                             "clean OOM instead of thrashing the system.")
    parser.add_argument("--num_workers", type=int, default=0,
                        help="DataLoader worker count. 0 = main-process only "
                             "(safest, no extra RAM overhead from forked "
                             "workers). Default 0.")
    args = parser.parse_args()

    print("=" * 60)
    print("Qwen3-TTS Awing LoRA fine-tune")
    print(f"  Base model:   {args.init_model_path}")
    print(f"  Output:       {args.output_model_path}")
    print(f"  Train data:   {args.train_jsonl}")
    print(f"  LoRA:         r={args.lora_r}  alpha={args.lora_alpha}  "
          f"dropout={args.lora_dropout}")
    print(f"  Optim:        lr={args.lr}  batch={args.batch_size}  "
          f"grad_accum={args.grad_accum}  epochs={args.num_epochs}")
    print("=" * 60)

    # Start memory monitor BEFORE any heavy allocations. Writes
    # <output_model_path>/memory_log.csv every 2 seconds. Survives
    # freezes (line-buffered + fsync'd), so after recovery we can see
    # the last few samples leading up to the failure.
    out_dir = Path(args.output_model_path)
    out_dir.mkdir(parents=True, exist_ok=True)
    mem_log_path = out_dir / "memory_log.csv"
    _start_memory_monitor(mem_log_path, interval_s=2.0)
    print(f"  Memory monitor: {mem_log_path}  (sampling every 2 s)")
    print("=" * 60)

    # System RAM sanity — fail fast if WSL2 isn't capped.
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    total_kb = int(line.split()[1])
                    total_gb = total_kb / 1024 / 1024
                    print(f"  System RAM (WSL2): {total_gb:.1f} GB available")
                    if total_gb > 12:
                        print(f"  WARNING: WSL2 RAM looks UNCAPPED. If your "
                              f"host has 16+ GB RAM, edit %USERPROFILE%\\.wslconfig:")
                        print(f"    [wsl2]\n    memory=10GB\n    swap=4GB")
                        print(f"  Then `wsl --shutdown` and reopen WSL.")
                    break
    except Exception:
        pass

    # --- 1. CUDA / VRAM sanity + freeze guards -----------------------
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available.")
        return 1
    cap = torch.cuda.get_device_capability(0)
    total_vram = torch.cuda.get_device_properties(0).total_memory / 1e9
    print(f"  GPU: {torch.cuda.get_device_name(0)} | sm_{cap[0]}{cap[1]}"
          f" | {total_vram:.1f} GB VRAM")

    # PYTORCH_CUDA_ALLOC_CONF: expandable_segments reduces fragmentation
    # (Sessions 15-16). max_split_size_mb prevents very large allocations
    # from fragmenting the heap.
    os.environ.setdefault(
        "PYTORCH_CUDA_ALLOC_CONF",
        "expandable_segments:True,max_split_size_mb:512",
    )

    # --- HARD VRAM CAP — the freeze guard ----------------------------
    # On Windows + WSL, when a CUDA process fills its VRAM, NVIDIA's
    # driver transparently spills to "shared GPU memory" (system RAM),
    # which thrashes the whole system into a freeze instead of raising
    # OOM. set_per_process_memory_fraction caps the active CUDA
    # context's allocator so PyTorch raises a clean OOM long BEFORE
    # the swap zone — your machine stays responsive.
    cap_gb = total_vram * args.vram_fraction
    torch.cuda.set_per_process_memory_fraction(args.vram_fraction, device=0)
    print(f"  VRAM cap: {cap_gb:.1f} GB (= {args.vram_fraction*100:.0f}% of {total_vram:.1f} GB)")
    print(f"  PyTorch will raise OOM cleanly if training tries to exceed this —")
    print(f"  no shared-memory swap, no PC freeze.")

    # cuDNN benchmark off — kernel-selection runs allocate+free large
    # workspaces during the first few steps, briefly spiking VRAM
    # in ways that can trip the cap. Stable allocator > fastest kernels.
    torch.backends.cudnn.benchmark = False

    # --- 2. Imports (deferred so the cuda check runs first) ----------
    from accelerate import Accelerator
    from peft import LoraConfig, get_peft_model, TaskType
    from safetensors.torch import save_file
    from transformers import AutoConfig
    from qwen_tts import Qwen3TTSModel

    try:
        from bitsandbytes.optim import AdamW8bit
        OPT_CLS = AdamW8bit
        print("  Optimizer: bitsandbytes 8-bit AdamW")
    except ImportError:
        from torch.optim import AdamW
        OPT_CLS = AdamW
        print("  Optimizer: torch.optim.AdamW (bitsandbytes not installed — "
              "may run out of memory for trainable params on small GPUs)")

    # --- 3. Accelerator (mirrors sft_12hz.py + the project_dir patch) -
    accelerator = Accelerator(
        gradient_accumulation_steps=args.grad_accum,
        mixed_precision="bf16",
        log_with="tensorboard",
        project_dir=args.output_model_path,
    )

    # --- 4. Load base in bf16, frozen --------------------------------
    print("\nLoading base model (frozen, bf16, sdpa)...")
    qwen3tts = Qwen3TTSModel.from_pretrained(
        args.init_model_path,
        dtype=torch.bfloat16,
        attn_implementation="sdpa",
    )
    config = AutoConfig.from_pretrained(args.init_model_path)

    # Freeze everything first, then unfreeze the small set of modules
    # that LoRA's rank-r approximation may not capture. Speaker encoder
    # stays frozen (we use its outputs but don't adapt it).
    for param in qwen3tts.model.parameters():
        param.requires_grad = False

    # --- 5. Apply LoRA to talker + code_predictor decoder layers -----
    # The Talker classes use standard q/k/v/o + gate/up/down naming
    # (verified by inspecting the local install). Targeting all seven
    # gives the adapter capacity to model both attention patterns AND
    # MLP transformations needed for new phonemes.

    lora_target_modules = [
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ]

    # PEFT modules_to_save: any module whose name ENDS with one of these
    # suffixes is kept fully trainable AND serialised alongside the LoRA
    # adapter at save_pretrained() time. PEFT matches by leaf-name
    # suffix.
    #
    # Restrictions we have to dance around:
    #  1. PEFT can ONLY wrap leaf-style modules (Linear, Embedding) —
    #     never nn.ModuleList.
    #  2. The model has SEVERAL leaves with the same name in different
    #     paths. Specifically:
    #       talker.model.codec_embedding              -> nn.Embedding (OK)
    #       talker.code_predictor.model.codec_embedding -> nn.ModuleList (BAD)
    #     PEFT's suffix match catches both, so we cannot pass
    #     "codec_embedding" without crashing on the ModuleList.
    #
    # text_projection is unique (only one in the whole model) and is a
    # single nn.Module — safe for modules_to_save.
    # Everything else (codec_embedding both flavours, lm_head ModuleList)
    # we unfreeze manually after PEFT wraps and save by name at
    # checkpoint time.
    extra_save_modules = ["text_projection"]
    manual_unfreeze_substrings = [
        ".codec_embedding",   # main talker's nn.Embedding + SubTalker's ModuleList
        ".lm_head.",          # SubTalker's 15 output heads (ModuleList)
    ]

    lora_cfg = LoraConfig(
        r=args.lora_r,
        lora_alpha=args.lora_alpha,
        lora_dropout=args.lora_dropout,
        bias="none",
        target_modules=lora_target_modules,
        modules_to_save=extra_save_modules,
        task_type=TaskType.FEATURE_EXTRACTION,
    )

    # Wrap only the talker submodule with LoRA. The base qwen3tts.model
    # has talker, thinker (text encoder), speaker_encoder. Wrapping the
    # full top-level model would also LoRA-ify the thinker — wasteful
    # since text encoding doesn't need Awing adaptation; we want
    # acoustic modeling to adapt.
    qwen3tts.model.talker = get_peft_model(qwen3tts.model.talker, lora_cfg)

    # Manually unfreeze the leaves PEFT can't handle (ModuleList types
    # and ambiguous suffixes — see the modules_to_save comment block).
    # Save them by name at checkpoint time below.
    manually_unfrozen = []
    for name, p in qwen3tts.model.named_parameters():
        if any(sub in name for sub in manual_unfreeze_substrings):
            p.requires_grad = True
            manually_unfrozen.append(name)

    # Print trainable summary so it's obvious what's being adapted.
    n_trainable, n_total = 0, 0
    for p in qwen3tts.model.parameters():
        n_total += p.numel()
        if p.requires_grad:
            n_trainable += p.numel()
    print(f"\nLoRA wrap done:")
    print(f"  Trainable: {n_trainable:,} params "
          f"({100*n_trainable/n_total:.2f}% of {n_total:,} total)")
    print(f"  LoRA target: {lora_target_modules}")
    print(f"  Modules saved in full (PEFT): {extra_save_modules}")
    print(f"  Manually unfrozen (saved separately): {len(manually_unfrozen)} params")
    if manually_unfrozen:
        # Show a sample — full list is too long
        sample = manually_unfrozen[:3] + (["..."] if len(manually_unfrozen) > 3 else [])
        for s in sample:
            print(f"    {s}")

    # --- 6b. Resume from checkpoint if one exists --------------------
    # Look in args.output_model_path for the highest-numbered
    # checkpoint-epoch-N and load adapter + manual state from it.
    # Sets start_epoch so the training loop skips already-completed
    # epochs. If no checkpoint, start_epoch stays at 0.
    start_epoch = 0
    latest = _find_latest_checkpoint(Path(args.output_model_path))
    if latest is not None:
        last_epoch_n, last_ckpt_dir = latest
        _resume_from_checkpoint(qwen3tts.model, last_ckpt_dir)
        start_epoch = last_epoch_n + 1
        if start_epoch >= args.num_epochs:
            print(f"  All {args.num_epochs} epochs already complete. Nothing to do.")
            print(f"  To re-train, delete {args.output_model_path} or pass --num_epochs N (N > {start_epoch}).")
            return 0
        print(f"  Continuing from epoch {start_epoch} / {args.num_epochs}")
    else:
        print(f"  No prior checkpoint found in {args.output_model_path} — training from base weights")

    # --- 7. Gradient checkpointing -----------------------------------
    qwen3tts.model.talker.gradient_checkpointing_enable()
    if hasattr(qwen3tts.model.talker, "enable_input_require_grads"):
        # PEFT's helper — needed when base is frozen and grad checkpoint is on,
        # otherwise gradients won't propagate through the frozen embeddings.
        qwen3tts.model.talker.enable_input_require_grads()

    # --- 8. Dataset / dataloader (same as sft_12hz.py) ---------------
    # Defer the import so the original module's globals are available.
    sys.path.insert(0, str(Path.home() / "Qwen3-TTS" / "finetuning"))
    try:
        from dataset import TTSDataset
    except ImportError as e:
        print(f"ERROR importing TTSDataset from ~/Qwen3-TTS/finetuning/: {e}")
        return 1

    print(f"Loading training data from {args.train_jsonl}...")
    train_data = [json.loads(l) for l in open(args.train_jsonl)]
    dataset = TTSDataset(train_data, qwen3tts.processor, config)
    train_dataloader = DataLoader(
        dataset, batch_size=args.batch_size, shuffle=True,
        collate_fn=dataset.collate_fn,
        num_workers=args.num_workers,    # 0 by default — no forked workers
        pin_memory=False,                # avoids pinning 7k clips into RAM
    )
    print(f"  {len(train_data)} samples, {len(train_dataloader)} batches/epoch")

    # --- 9. Optimizer over trainable params only ---------------------
    trainable_params = [p for p in qwen3tts.model.parameters() if p.requires_grad]
    optimizer = OPT_CLS(trainable_params, lr=args.lr, weight_decay=0.01)

    # --- 10. Accelerator prepare -------------------------------------
    model, optimizer, train_dataloader = accelerator.prepare(
        qwen3tts.model, optimizer, train_dataloader
    )

    # --- 11. Training loop -------------------------------------------
    target_speaker_embedding = None
    model.train()

    # Resolve the PEFT-wrapped talker internals once. After
    # get_peft_model(), `model.talker` is a PeftModel that adds an
    # extra indirection level. PEFT's __getattr__ forwards unknown
    # attrs to base_model.model (the original Qwen3TTS-
    # TalkerForConditionalGeneration). So:
    #   model.talker                      -> PeftModel
    #   model.talker.model                -> Qwen3TTSTalkerForConditionalGeneration
    #   model.talker.model.model          -> Qwen3TTSTalkerModel (inner)
    #   model.talker.model.text_projection -> the 2048->1024 MLP
    #   model.talker.model.code_predictor -> SubTalker predictor
    # We cache these once so the forward pass reads cleanly.
    talker_pft = model.talker
    talker_for_cg = talker_pft.model            # Qwen3TTSTalkerForConditionalGeneration
    talker_inner = talker_for_cg.model           # Qwen3TTSTalkerModel
    text_projection = talker_for_cg.text_projection
    text_embedding = talker_inner.text_embedding
    codec_embedding = talker_inner.codec_embedding
    code_predictor = talker_for_cg.code_predictor

    if start_epoch > 0:
        print(f"\nResuming training at epoch {start_epoch} of {args.num_epochs}.\n")
    else:
        print("\nStarting training. First step ETA: ~1-3 min for compile.\n")

    for epoch in range(start_epoch, args.num_epochs):
        for step, batch in enumerate(train_dataloader):
            with accelerator.accumulate(model):
                input_ids = batch["input_ids"]
                codec_ids = batch["codec_ids"]
                ref_mels = batch["ref_mels"]
                text_embedding_mask = batch["text_embedding_mask"]
                codec_embedding_mask = batch["codec_embedding_mask"]
                attention_mask = batch["attention_mask"]
                codec_0_labels = batch["codec_0_labels"]
                codec_mask = batch["codec_mask"]

                with torch.no_grad():
                    speaker_embedding = model.speaker_encoder(
                        ref_mels.to(model.device).to(model.dtype)
                    ).detach()
                if target_speaker_embedding is None:
                    target_speaker_embedding = speaker_embedding

                input_text_ids = input_ids[:, :, 0]
                input_codec_ids = input_ids[:, :, 1]

                # Use cached references (resolved once outside the loop).
                # Routes text through text_projection so dims match
                # codec_embedding — identity-shaped on 1.7B but matches
                # the inference code path for both sizes.
                input_text_embedding = text_projection(
                    text_embedding(input_text_ids)
                ) * text_embedding_mask
                input_codec_embedding = (
                    codec_embedding(input_codec_ids) * codec_embedding_mask
                )
                input_codec_embedding[:, 6, :] = speaker_embedding
                input_embeddings = input_text_embedding + input_codec_embedding

                for i in range(1, 16):
                    codec_i_emb = code_predictor.get_input_embeddings()[i - 1](
                        codec_ids[:, :, i]
                    )
                    codec_i_emb = codec_i_emb * codec_mask.unsqueeze(-1)
                    input_embeddings = input_embeddings + codec_i_emb

                # talker_pft is the PeftModel; calling it forwards through
                # the LoRA adapter into the underlying ForCG forward().
                outputs = talker_pft(
                    inputs_embeds=input_embeddings[:, :-1, :],
                    attention_mask=attention_mask[:, :-1],
                    labels=codec_0_labels[:, 1:],
                    output_hidden_states=True,
                )

                hidden_states = outputs.hidden_states[0][-1]
                talker_hidden_states = hidden_states[codec_mask[:, :-1]]
                talker_codec_ids = codec_ids[codec_mask]

                sub_talker_logits, sub_talker_loss = (
                    talker_for_cg.forward_sub_talker_finetune(
                        talker_codec_ids, talker_hidden_states
                    )
                )
                loss = outputs.loss + 0.3 * sub_talker_loss

                accelerator.backward(loss)
                if accelerator.sync_gradients:
                    accelerator.clip_grad_norm_(trainable_params, 1.0)

                optimizer.step()
                optimizer.zero_grad()

                if step % 10 == 0:
                    vram_gb = torch.cuda.memory_allocated() / 1e9
                    accelerator.print(
                        f"Epoch {epoch} | Step {step:4d} | "
                        f"Loss: {loss.item():.4f} | "
                        f"VRAM: {vram_gb:.1f} GB"
                    )

        # --- End-of-epoch checkpoint ---------------------------------
        if accelerator.is_main_process:
            ckpt_dir = Path(args.output_model_path) / f"checkpoint-epoch-{epoch}"
            ckpt_dir.mkdir(parents=True, exist_ok=True)

            unwrapped = accelerator.unwrap_model(model)

            # Save the LoRA adapter via PEFT's standard format. PEFT also
            # serialises modules_to_save (codec_embedding, text_projection)
            # into the same checkpoint dir automatically.
            unwrapped.talker.save_pretrained(str(ckpt_dir))

            # Manually save the params PEFT couldn't include in
            # modules_to_save (codec_embedding + lm_head — both have
            # ModuleList variants). At inference these need to be
            # loaded back into the corresponding paths in the base
            # model BEFORE applying the LoRA adapter.
            manual_state = {}
            for name, param in unwrapped.named_parameters():
                if any(sub in name for sub in manual_unfreeze_substrings):
                    manual_state[name] = param.detach().to("cpu")
            if manual_state:
                save_file(manual_state, str(ckpt_dir / "manual_unfrozen_state.safetensors"))

            # Save the captured speaker embedding for inference-time
            # codec_embedding[3000] override (mirrors sft_12hz.py).
            if target_speaker_embedding is not None:
                torch.save(
                    target_speaker_embedding[0].detach().to("cpu"),
                    ckpt_dir / "target_speaker_embedding.pt",
                )

            # Persist a small inference-helper config noting the speaker
            # name + base model id, so we can reload at inference time
            # without guessing.
            (ckpt_dir / "awing_lora_meta.json").write_text(json.dumps({
                "base_model": args.init_model_path,
                "speaker_name": args.speaker_name,
                "lora_r": args.lora_r,
                "lora_alpha": args.lora_alpha,
                "epoch": epoch,
                "modules_to_save": extra_save_modules,
            }, indent=2), encoding="utf-8")

            accelerator.print(f"  -> checkpoint saved at {ckpt_dir}")

    accelerator.print("\nTraining complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
