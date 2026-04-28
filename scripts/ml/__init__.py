"""Awing machine learning pipelines.

This package builds training corpora from the manifest-indexed raw data in
corpus/raw/ and drives model training (TTS, ASR, translation). Every
pipeline is a clean function of (manifest entries, model config) → derived
corpus, so re-running it is deterministic and the outputs are inspectable.

Modules:
  prep_piper_dataset — aligns Bible chapter audio to per-verse clips using
                       torchaudio MMS forced alignment, emits LJSpeech
                       format for Piper TTS fine-tuning.
"""
