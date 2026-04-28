"""Awing multi-speaker TTS pipeline.

Two architecture candidates are scaffolded here. We smoke-test BOTH
before committing to one for the full Awing fine-tune. Whichever
architecture's smoke test produces the 6 character voices we need
(in particular: convincing child voices for boy/girl) is the one we
proceed with.

Path Y — YourTTS (multi-speaker pretrained pool)
================================================
Coqui's YourTTS ships with ~10-15 pretrained adult speaker embeddings
(VCTK + multilingual). Approach: fine-tune on the Awing Bible corpus
with the speaker embedding layer FROZEN so the pretrained voices are
preserved while the text encoder + decoder learn Awing acoustics.
At inference: pass any preserved speaker_id + Awing text → Awing
speech in that speaker's vocal timbre.

  setup_wsl.sh       — WSL Coqui install with Blackwell cu128
  smoke_test.py      — verify YourTTS produces English in different voices

Smoke-test outcome (Session 56): all pretrained YourTTS speakers are
adults. No child voices in the pool. Dr. Sama rejected pitch-shifting
adults to fake children. → Path Y blocked on the boy/girl roles.

Path Q — Qwen3-TTS-VoiceDesign (natural-language voice prompts)
================================================================
Alibaba's Qwen3-TTS-12Hz-1.7B-VoiceDesign (open-sourced Jan 2026)
generates a voice from a NATURAL-LANGUAGE PROMPT — no fixed speaker
pool. We can prompt for "a 7-year-old boy with a high, light voice"
and the model synthesises that voice on the spot. If the smoke test
shows the boy/girl prompts produce convincing children, this is the
architecture we fine-tune on Awing.

  setup_qwen3_wsl.sh    — WSL qwen-tts install with Blackwell cu128
  smoke_test_qwen3.py   — generate the 6 app roles from voice-design
                          prompts, render an audition page

Downstream pipeline (whichever architecture wins)
=================================================
  prep_metadata.py       — add narrator/role column to LJSpeech metadata
  train_<model>.py       — fine-tune the chosen model on Awing
  audition_voices.py     — generate Awing samples for each role
  export_onnx.py         — export to ONNX for Flutter app integration
"""
