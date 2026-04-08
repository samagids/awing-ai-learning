#!/usr/bin/env python3
"""
Awing Google Cloud TTS Audio Generator v1.0.0
==============================================
Generates pronunciation audio for the Awing language using Google Cloud
Text-to-Speech API with Swahili WaveNet/Neural2 voices.

Voice Characters (6 voices — 2 per difficulty level):
  Beginner:  boy (child male) + girl (child female)     — slower, higher pitch
  Medium:    young_man + young_woman                     — moderate pace
  Expert:    man (adult male) + woman (adult female)     — natural pace, deeper

Uses Swahili (Bantu family) neural voices — Swahili shares prenasalized stops
(mb, nd, ng), open syllable structure, and similar vowels with Awing.

Free tier: 1M characters/month (WaveNet), 4M characters/month (Standard).

Audio output structure:
  assets/audio/{boy,girl,young_man,young_woman,man,woman}/{alphabet,vocabulary,sentences,stories}/

Setup:
  1. Go to https://console.cloud.google.com/
  2. Create a project (or use existing)
  3. Enable "Cloud Text-to-Speech API"
  4. Create a service account key (JSON) at IAM & Admin > Service Accounts
  5. Set GOOGLE_APPLICATION_CREDENTIALS env var to the JSON key path
  6. pip install google-cloud-texttospeech

Usage:
    python scripts/generate_audio_google.py generate         # Generate all voices
    python scripts/generate_audio_google.py speak "apô"      # Speak a word (all voices)
    python scripts/generate_audio_google.py test              # Test sample words
    python scripts/generate_audio_google.py voices            # List available Swahili voices
    python scripts/generate_audio_google.py status            # Show status
    python scripts/generate_audio_google.py setup             # Interactive setup guide

Requires: pip install google-cloud-texttospeech
"""

import os
import sys
import shutil
import argparse
import unicodedata
import re
from pathlib import Path

# ====================================================================
# CONFIGURATION
# ====================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent
AUDIO_DIR = PROJECT_DIR / "assets" / "audio"
TEMP_DIR = SCRIPT_DIR / "_google_tts_temp"

VERSION = "1.0.0"

# 6 character voices — 2 per difficulty level
# Google Cloud TTS Swahili voices with SSML pitch/rate control
VOICE_CHARACTERS = {
    # --- Beginner: child voices (slower, higher pitch) ---
    "boy": {
        "language_code": "sw-KE",
        "voice_name": None,  # Auto-select best available male voice
        "gender": "MALE",
        "pitch": 6.0,        # Semitones up for child voice
        "rate": 0.75,        # Slower for beginners (1.0 = normal)
        "description": "Boy (Beginner)",
        "level": "beginner",
    },
    "girl": {
        "language_code": "sw-KE",
        "voice_name": None,  # Auto-select best available female voice
        "gender": "FEMALE",
        "pitch": 8.0,        # Higher pitch for child voice
        "rate": 0.75,        # Slower for beginners
        "description": "Girl (Beginner)",
        "level": "beginner",
    },
    # --- Medium: young adult voices (moderate pace) ---
    "young_man": {
        "language_code": "sw-KE",
        "voice_name": None,
        "gender": "MALE",
        "pitch": 2.0,        # Slightly higher for young adult
        "rate": 0.85,        # Moderate pace
        "description": "Young man (Medium)",
        "level": "medium",
    },
    "young_woman": {
        "language_code": "sw-KE",
        "voice_name": None,
        "gender": "FEMALE",
        "pitch": 3.0,        # Slightly higher for young adult
        "rate": 0.85,        # Moderate pace
        "description": "Young woman (Medium)",
        "level": "medium",
    },
    # --- Expert: adult voices (natural pace, deeper) ---
    "man": {
        "language_code": "sw-KE",
        "voice_name": None,
        "gender": "MALE",
        "pitch": -2.0,       # Deeper adult voice
        "rate": 0.95,        # Near-natural pace
        "description": "Adult man (Expert)",
        "level": "expert",
    },
    "woman": {
        "language_code": "sw-KE",
        "voice_name": None,
        "gender": "FEMALE",
        "pitch": 0.0,        # Natural adult pitch
        "rate": 0.95,        # Near-natural pace
        "description": "Adult woman (Expert)",
        "level": "expert",
    },
}


# ====================================================================
# AWING VOCABULARY DATA (fallback — prefer loading from Dart files)
# ====================================================================

ALPHABET_SOUNDS = {
    "a": "a", "e": "e", "epsilon": "ɛ", "schwa": "ə",
    "i": "i", "barred_i": "ɨ", "o": "o", "open_o": "ɔ", "u": "u",
    "b": "bə́", "ch": "chə́", "d": "də́", "f": "fə́",
    "g": "gə́", "gh": "ghə́", "j": "jə́", "k": "kə́",
    "l": "lə́", "m": "mə́", "n": "nə́", "ny": "nyə́",
    "eng": "ŋə́", "p": "pə́", "s": "sə́", "sh": "shə́",
    "t": "tə́", "ts": "tsə́", "w": "wə́", "y": "yə́",
    "z": "zə́", "glottal": "ə́'ə́",
}

VOCABULARY_WORDS = {
    "apo": "apô", "atue": "atûə", "aloeme": "alɔ́əmə",
    "fele": "fɛlə", "nelwie": "nəlwîə", "nde": "ndě",
    "nkadte": "nkadtə", "mbete": "mbe'tə", "achie": "achîə",
    "eshue": "əshûə", "konge": "koŋə", "noole": "nóolə",
    "atie": "atîə", "no": "nô", "lume": "lúmə",
    "mie": "mîə", "pene": "pɛ́nə", "ko": "ko",
    "ma": "mǎ", "ye": "yə", "alae": "alá'ə",
}

SENTENCES = {
    "greeting_chatoo": "Cha'tɔ́!",
    "greeting_chatoo_yiiee": "Cha'tɔ́! Yə yîə?",
    "greeting_kwae": "Yə kwa'ə.",
    "daily_market": "A kə ghɛnɔ́ mətéenɔ́.",
    "daily_pumpkin": "Lɛ̌ nəpɔ'ɔ́.",
}

STORIES = {
    "story_1_title": "Ŋwáŋə́ ə́ Kwɨ̌tə́",
    "story_1_line_1": "Kwɨ̌tə́ á ghə̂ə əfóo á lə̀.",
    "story_1_line_2": "Á kóolə́ ənyîɛ́ á tə̀.",
    "story_1_line_3": "Mbə̌ə á fyɛ́ á ŋgóonɛ́.",
}


# ====================================================================
# AWING → SPEAKABLE TEXT CONVERTER
# ====================================================================

def awing_to_speakable(text):
    """Convert Awing text to speakable text for a Bantu TTS voice.
    Strips tone diacritics and maps special Awing vowels to Swahili equivalents."""
    text = unicodedata.normalize("NFC", text)

    # Strip tone diacritics (TTS handles its own prosody)
    result = []
    for char in text:
        decomposed = unicodedata.normalize("NFD", char)
        clean = ""
        for c in decomposed:
            cat = unicodedata.category(c)
            if cat.startswith("M"):
                if c in ('\u0301', '\u0300', '\u0302', '\u030C', '\u0303'):
                    continue
            clean += c
        result.append(unicodedata.normalize("NFC", clean))
    text = "".join(result)

    # Handle ŋg/ŋk clusters BEFORE isolated ŋ
    text = text.replace("ŋg", "ngg")
    text = text.replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk")
    text = text.replace("Ŋk", "Nk")

    replacements = [
        ("Ɛ", "E"), ("ɛ", "e"),
        ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"),
        ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"),
        ("ɣ", "gh"),
        ("ʼ", ""), ("\u2019", ""), ("\u2018", ""), ("'", ""),
    ]

    for old, new in replacements:
        text = text.replace(old, new)

    text = re.sub(r'\s+', ' ', text).strip()
    return text


def _audio_key(awing_text):
    """Convert Awing word to safe ASCII filename (matches pronunciation_service.dart _audioKey)."""
    text = unicodedata.normalize("NFC", awing_text.strip().lower())

    # Special character filename mappings
    special_map = {
        'ɛ': 'epsilon', 'ə': 'schwa', 'ɨ': 'barred_i',
        'ɔ': 'open_o', 'ŋ': 'eng',
    }

    if text in special_map:
        return special_map[text]

    # Strip tone diacritics
    result = []
    for char in text:
        decomposed = unicodedata.normalize("NFD", char)
        clean = ""
        for c in decomposed:
            cat = unicodedata.category(c)
            if cat.startswith("M") and c in ('\u0301', '\u0300', '\u0302', '\u030C', '\u0303'):
                continue
            clean += c
        result.append(unicodedata.normalize("NFC", clean))
    text = "".join(result)

    replacements = [
        ('ɛ', 'e'), ('ɔ', 'o'), ('ə', 'e'), ('ɨ', 'i'), ('ŋ', 'ng'),
    ]
    for old, new in replacements:
        text = text.replace(old, new)

    text = text.replace("'", "").replace("\u2019", "").replace("\u2018", "")
    text = re.sub(r'[^a-z0-9]', '', text)

    return text


def _load_vocabulary_from_dart():
    """Read vocabulary directly from awing_vocabulary.dart to stay in sync."""
    dart_file = PROJECT_DIR / "lib" / "data" / "awing_vocabulary.dart"
    if not dart_file.exists():
        print(f"  Warning: {dart_file} not found, using built-in vocabulary")
        return None

    vocab = {}
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()

    for m in re.finditer(r"AwingWord\([^)]*awing:\s*['\"]([^'\"]+)['\"]", content):
        awing_text = m.group(1)
        key = _audio_key(awing_text)
        if key and key not in vocab:
            vocab[key] = awing_text

    return vocab if vocab else None


def _load_phrases_from_dart():
    """Read phrases from awing_vocabulary.dart."""
    dart_file = PROJECT_DIR / "lib" / "data" / "awing_vocabulary.dart"
    if not dart_file.exists():
        return None

    phrases = {}
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()

    for m in re.finditer(
        r"AwingPhrase\([^)]*awing:\s*['\"]([^'\"]+)['\"][^)]*clipKey:\s*['\"]([^'\"]+)['\"]",
        content, re.DOTALL
    ):
        awing_text = m.group(1)
        clip_key = m.group(2)
        phrases[clip_key] = awing_text

    return phrases if phrases else None


# ====================================================================
# GOOGLE CLOUD TTS ENGINE
# ====================================================================

_client = None
_available_voices_cache = None


def _get_client():
    """Get or create the Google Cloud TTS client."""
    global _client
    if _client is None:
        from google.cloud import texttospeech
        _client = texttospeech.TextToSpeechClient()
    return _client


def _list_swahili_voices():
    """List all available Swahili voices from Google Cloud TTS."""
    global _available_voices_cache
    if _available_voices_cache is not None:
        return _available_voices_cache

    from google.cloud import texttospeech
    client = _get_client()
    response = client.list_voices(language_code="sw")

    voices = []
    for voice in response.voices:
        for lang in voice.language_codes:
            if lang.startswith("sw"):
                voices.append({
                    "name": voice.name,
                    "language": lang,
                    "gender": texttospeech.SsmlVoiceGender(voice.ssml_gender).name,
                    "rate": voice.natural_sample_rate_hertz,
                })

    _available_voices_cache = voices
    return voices


def _select_voice(char_config):
    """Select the best available voice for a character config.

    Priority: WaveNet > Neural2 > Standard (higher quality first).
    Matches gender from character config.
    """
    from google.cloud import texttospeech

    # If a specific voice name is configured, use it
    if char_config.get("voice_name"):
        return char_config["voice_name"]

    voices = _list_swahili_voices()
    lang = char_config["language_code"]
    gender = char_config["gender"]

    # Filter by language and gender
    candidates = [v for v in voices
                  if v["language"].startswith(lang[:2])
                  and v["gender"] == gender]

    if not candidates:
        # Try any Swahili voice with right gender
        candidates = [v for v in voices if v["gender"] == gender]

    if not candidates:
        # Try any Swahili voice at all
        candidates = voices

    if not candidates:
        print(f"  WARNING: No Swahili voices found! Using default.")
        return None

    # Sort by quality tier: WaveNet > Neural2 > Chirp > Standard
    def voice_priority(v):
        name = v["name"].lower()
        if "wavenet" in name:
            return 0
        elif "neural2" in name:
            return 1
        elif "chirp" in name:
            return 2
        elif "standard" in name:
            return 3
        return 4

    candidates.sort(key=voice_priority)
    selected = candidates[0]
    return selected["name"]


def _generate_clip(char_config, text, output_path, rate_override=None):
    """Generate a single audio clip using Google Cloud TTS.

    Args:
        char_config: Voice character configuration dict
        text: Awing text to speak
        output_path: Path to save MP3 file
        rate_override: Optional speaking rate override (float, 1.0 = normal)

    Returns True on success, False on failure.
    """
    from google.cloud import texttospeech

    speakable = awing_to_speakable(text)

    try:
        client = _get_client()

        voice_name = _select_voice(char_config)
        lang_code = char_config["language_code"]
        gender_str = char_config["gender"]
        pitch = char_config["pitch"]
        rate = rate_override if rate_override else char_config["rate"]

        # Map gender string to enum
        gender_map = {
            "MALE": texttospeech.SsmlVoiceGender.MALE,
            "FEMALE": texttospeech.SsmlVoiceGender.FEMALE,
        }
        gender = gender_map.get(gender_str, texttospeech.SsmlVoiceGender.NEUTRAL)

        # Voice selection
        voice_params = texttospeech.VoiceSelectionParams(
            language_code=lang_code,
            ssml_gender=gender,
        )
        if voice_name:
            voice_params = texttospeech.VoiceSelectionParams(
                language_code=lang_code,
                name=voice_name,
            )

        # Audio config with pitch and rate
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=rate,
            pitch=pitch,
        )

        # Synthesis input
        synthesis_input = texttospeech.SynthesisInput(text=speakable)

        # Generate
        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice_params,
            audio_config=audio_config,
        )

        if response.audio_content and len(response.audio_content) > 500:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(response.audio_content)
            return True

    except Exception as e:
        print(f"    Error: {e}")
    return False


def _generate_character_clips(char_name, char_config, vocab_override=None, phrases_override=None):
    """Generate all audio clips for one character voice."""
    desc = char_config["description"]
    rate = char_config["rate"]

    vocab = vocab_override if vocab_override else VOCABULARY_WORDS
    sentences = phrases_override if phrases_override else SENTENCES

    voice_name = _select_voice(char_config)

    char_dir = AUDIO_DIR / char_name
    print(f"\n{'='*50}")
    print(f"  Generating: {char_name} — {desc}")
    print(f"  Voice: {voice_name}")
    print(f"  Pitch: {char_config['pitch']} st | Rate: {rate}x")
    print(f"  Output: {char_dir}")
    print(f"{'='*50}")

    total = 0
    success = 0
    failed = []

    # Alphabet
    print(f"\n  --- Alphabet ({len(ALPHABET_SOUNDS)} sounds) ---")
    for key, text in ALPHABET_SOUNDS.items():
        total += 1
        output = char_dir / "alphabet" / f"{key}.mp3"
        # Slower rate for alphabet (isolated sounds)
        alpha_rate = max(0.5, rate - 0.2)
        if _generate_clip(char_config, text, output, rate_override=alpha_rate):
            success += 1
            print(f"    + {key}")
        else:
            failed.append(key)
            print(f"    x {key} FAILED")

    # Vocabulary
    print(f"\n  --- Vocabulary ({len(vocab)} words) ---")
    for key, text in vocab.items():
        total += 1
        output = char_dir / "vocabulary" / f"{key}.mp3"
        if _generate_clip(char_config, text, output):
            success += 1
            print(f"    + {key}")
        else:
            failed.append(key)
            print(f"    x {key} FAILED")

    # Sentences
    print(f"\n  --- Sentences ({len(sentences)} clips) ---")
    for key, text in sentences.items():
        total += 1
        output = char_dir / "sentences" / f"{key}.mp3"
        # Slightly faster for sentences
        sent_rate = min(1.2, rate + 0.1)
        if _generate_clip(char_config, text, output, rate_override=sent_rate):
            success += 1
            print(f"    + {key}")
        else:
            failed.append(key)
            print(f"    x {key} FAILED")

    # Stories
    print(f"\n  --- Stories ({len(STORIES)} clips) ---")
    for key, text in STORIES.items():
        total += 1
        output = char_dir / "stories" / f"{key}.mp3"
        story_rate = min(1.2, rate + 0.1)
        if _generate_clip(char_config, text, output, rate_override=story_rate):
            success += 1
            print(f"    + {key}")
        else:
            failed.append(key)
            print(f"    x {key} FAILED")

    print(f"\n  {char_name}: {success}/{total} clips generated")
    if failed:
        print(f"  Failed: {', '.join(failed[:10])}")
    return success, total


# ====================================================================
# COMMANDS
# ====================================================================

def cmd_setup(args):
    """Interactive setup guide for Google Cloud TTS."""
    print(f"=== Google Cloud TTS Setup Guide ===\n")

    # Check if credentials are set
    creds = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if creds and Path(creds).exists():
        print(f"  [OK] Credentials found: {creds}")
    else:
        print("  [!] GOOGLE_APPLICATION_CREDENTIALS not set or file not found.\n")
        print("  Follow these steps:\n")
        print("  1. Go to https://console.cloud.google.com/")
        print("  2. Create a new project (or select existing)")
        print("  3. Search for 'Cloud Text-to-Speech API' and ENABLE it")
        print("  4. Go to IAM & Admin > Service Accounts")
        print("  5. Click '+ CREATE SERVICE ACCOUNT'")
        print("     - Name: awing-tts")
        print("     - Role: (none needed for TTS)")
        print("  6. Click on the new service account > Keys tab")
        print("  7. Add Key > Create new key > JSON > Create")
        print("  8. Save the JSON file (e.g., to your project folder)")
        print("  9. Set the environment variable:\n")
        print('     Windows (PowerShell):')
        print('       $env:GOOGLE_APPLICATION_CREDENTIALS="C:\\path\\to\\key.json"')
        print('     Windows (permanent):')
        print('       setx GOOGLE_APPLICATION_CREDENTIALS "C:\\path\\to\\key.json"')
        print()
        return False

    # Check if package is installed
    try:
        from google.cloud import texttospeech
        print(f"  [OK] google-cloud-texttospeech package installed")
    except ImportError:
        print("  [!] Package not installed. Run:")
        print("      pip install google-cloud-texttospeech")
        return False

    # Try to list voices
    try:
        voices = _list_swahili_voices()
        print(f"  [OK] API working — found {len(voices)} Swahili voices")
        for v in voices:
            tier = "WaveNet" if "wavenet" in v["name"].lower() else \
                   "Neural2" if "neural2" in v["name"].lower() else \
                   "Standard" if "standard" in v["name"].lower() else "Other"
            print(f"       {v['name']:40s} {v['gender']:8s} {tier}")
    except Exception as e:
        print(f"  [!] API error: {e}")
        print("      Make sure the Text-to-Speech API is enabled in your project.")
        return False

    print(f"\n  Setup complete! Run: python scripts/generate_audio_google.py generate")
    return True


def cmd_generate(args):
    """Generate all audio clips for all 6 character voices."""
    print(f"=== Awing Google Cloud TTS Generator v{VERSION} ===")
    print(f"Generating 6 character voices: boy, girl, young_man, young_woman, man, woman\n")

    try:
        from google.cloud import texttospeech
    except ImportError:
        print("ERROR: google-cloud-texttospeech not installed.")
        print("  Install: pip install google-cloud-texttospeech")
        return False

    # Check credentials
    creds = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if not creds or not Path(creds).exists():
        print("ERROR: GOOGLE_APPLICATION_CREDENTIALS not set.")
        print("  Run: python scripts/generate_audio_google.py setup")
        return False

    # List available voices
    try:
        voices = _list_swahili_voices()
        print(f"Available Swahili voices: {len(voices)}")
        for v in voices:
            print(f"  {v['name']:40s} {v['gender']}")
    except Exception as e:
        print(f"ERROR: Cannot connect to API: {e}")
        return False

    # Load vocabulary from Dart files
    dart_vocab = _load_vocabulary_from_dart()
    dart_phrases = _load_phrases_from_dart()
    if dart_vocab:
        print(f"Loaded {len(dart_vocab)} words from awing_vocabulary.dart")
    else:
        print(f"Using built-in vocabulary ({len(VOCABULARY_WORDS)} words)")
    if dart_phrases:
        print(f"Loaded {len(dart_phrases)} phrases from awing_vocabulary.dart")

    grand_total = 0
    grand_success = 0

    for char_name, char_config in VOICE_CHARACTERS.items():
        s, t = _generate_character_clips(
            char_name, char_config,
            vocab_override=dart_vocab,
            phrases_override=dart_phrases
        )
        grand_success += s
        grand_total += t

    print(f"\n{'='*50}")
    print(f"  ALL DONE: {grand_success}/{grand_total} clips across 6 voices")
    clips_per_voice = grand_total // 6 if grand_total > 0 else 0
    print(f"  {clips_per_voice} clips per voice x 6 voices = {grand_total} total")
    print(f"\n  Voices saved to:")
    print(f"    assets/audio/boy/         — Beginner (child male)")
    print(f"    assets/audio/girl/        — Beginner (child female)")
    print(f"    assets/audio/young_man/   — Medium (young adult male)")
    print(f"    assets/audio/young_woman/ — Medium (young adult female)")
    print(f"    assets/audio/man/         — Expert (adult male)")
    print(f"    assets/audio/woman/       — Expert (adult female)")
    print(f"{'='*50}")

    # Estimate characters used
    char_count = sum(len(awing_to_speakable(t)) for t in
                     list(ALPHABET_SOUNDS.values()) +
                     list((dart_vocab or VOCABULARY_WORDS).values()) +
                     list((dart_phrases or SENTENCES).values()) +
                     list(STORIES.values()))
    total_chars = char_count * 6  # 6 voices
    print(f"\n  Estimated characters used: ~{total_chars:,}")
    print(f"  WaveNet free tier: 1,000,000 chars/month")
    print(f"  Usage: {total_chars/10000:.1f}% of free tier")

    return grand_success == grand_total


def cmd_speak(args):
    """Speak a word in all 6 voices for comparison."""
    if not args.text:
        print("Usage: speak \"awing text\"")
        return False

    try:
        from google.cloud import texttospeech
    except ImportError:
        print("ERROR: google-cloud-texttospeech not installed.")
        return False

    text = " ".join(args.text)
    speakable = awing_to_speakable(text)

    print(f"  Awing:     {text}")
    print(f"  Speakable: {speakable}\n")

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    for char_name, cfg in VOICE_CHARACTERS.items():
        output = TEMP_DIR / f"speak_{char_name}.mp3"
        ok = _generate_clip(cfg, text, output)
        size = output.stat().st_size if output.exists() else 0
        status = "+" if ok else "x"
        voice = _select_voice(cfg)
        print(f"  {status} {char_name:12s} ({cfg['description']:30s}) voice={voice} → {size}b")
        if ok and sys.platform == "win32":
            os.startfile(str(output))
            import time
            time.sleep(2)

    return True


def cmd_test(args):
    """Test with sample words across all voices."""
    print(f"=== Testing Google Cloud TTS ===\n")

    try:
        from google.cloud import texttospeech
    except ImportError:
        print("ERROR: google-cloud-texttospeech not installed.")
        return False

    test_words = [
        ("apô", "hand"),
        ("mǎ", "mother"),
        ("ŋgóonɛ́", "chicken"),
        ("Cha'tɔ́!", "greeting"),
        ("nəlwîə", "nose"),
        ("kwágə", "cough"),
    ]

    print(f"Testing {len(test_words)} words x 6 voices = {len(test_words)*6} clips\n")

    for text, desc in test_words:
        speakable = awing_to_speakable(text)
        print(f"  {text:15s} → {speakable:15s} ({desc})")
    print()

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    for char_name, cfg in VOICE_CHARACTERS.items():
        voice = _select_voice(cfg)
        ok_count = 0
        for text, desc in test_words:
            output = TEMP_DIR / f"test_{char_name}_{desc}.mp3"
            ok = _generate_clip(cfg, text, output)
            if ok:
                ok_count += 1

        print(f"  {char_name:12s}: {ok_count}/{len(test_words)} OK "
              f"(voice: {voice}, pitch: {cfg['pitch']} st)")

    return True


def cmd_voices(args):
    """List all available Swahili voices."""
    print(f"=== Available Swahili Voices ===\n")

    try:
        from google.cloud import texttospeech
    except ImportError:
        print("ERROR: google-cloud-texttospeech not installed.")
        return False

    try:
        voices = _list_swahili_voices()
    except Exception as e:
        print(f"ERROR: {e}")
        return False

    if not voices:
        print("  No Swahili voices found.")
        print("  Make sure Cloud Text-to-Speech API is enabled.")
        return False

    print(f"  Found {len(voices)} Swahili voices:\n")
    print(f"  {'Voice Name':<45s} {'Gender':<10s} {'Rate':<10s} {'Tier'}")
    print(f"  {'-'*45} {'-'*10} {'-'*10} {'-'*10}")

    for v in voices:
        name = v["name"]
        tier = "WaveNet" if "wavenet" in name.lower() else \
               "Neural2" if "neural2" in name.lower() else \
               "Chirp3"  if "chirp" in name.lower() else \
               "Standard"
        print(f"  {name:<45s} {v['gender']:<10s} {v['rate']:<10d} {tier}")

    print(f"\n  Our voice selection per character:")
    for char_name, cfg in VOICE_CHARACTERS.items():
        voice = _select_voice(cfg)
        print(f"    {char_name:12s} → {voice} (pitch: {cfg['pitch']} st, rate: {cfg['rate']}x)")

    return True


def cmd_status(args):
    """Show current audio clip status."""
    print(f"=== Awing Google Cloud TTS Status v{VERSION} ===\n")

    # Check credentials
    creds = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    creds_ok = creds and Path(creds).exists()
    print(f"  Credentials: {'OK (' + Path(creds).name + ')' if creds_ok else 'NOT SET'}")

    # Check package
    try:
        from google.cloud import texttospeech
        print(f"  Package:     google-cloud-texttospeech installed")
    except ImportError:
        print(f"  Package:     NOT INSTALLED (pip install google-cloud-texttospeech)")

    # Check API
    if creds_ok:
        try:
            voices = _list_swahili_voices()
            print(f"  API:         OK ({len(voices)} Swahili voices)")
        except Exception as e:
            print(f"  API:         ERROR ({e})")
    else:
        print(f"  API:         SKIPPED (no credentials)")

    print()

    # Count existing clips
    total_clips = 0
    for char_name in VOICE_CHARACTERS:
        char_dir = AUDIO_DIR / char_name
        if char_dir.exists():
            clips = list(char_dir.rglob("*.mp3"))
            total_clips += len(clips)
            print(f"  {char_name:12s}: {len(clips)} clips")
        else:
            print(f"  {char_name:12s}: (no directory)")

    # Also check legacy flat dirs
    for subdir in ["alphabet", "vocabulary", "sentences", "stories"]:
        legacy = AUDIO_DIR / subdir
        if legacy.exists():
            clips = list(legacy.glob("*.mp3"))
            if clips:
                total_clips += len(clips)
                print(f"  legacy/{subdir}: {len(clips)} clips")

    print(f"\n  Total clips: {total_clips}")
    return True


# ====================================================================
# MAIN
# ====================================================================

def main():
    parser = argparse.ArgumentParser(
        description=f"Awing Google Cloud TTS Audio Generator v{VERSION}"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    subparsers.add_parser("setup", help="Interactive setup guide")
    subparsers.add_parser("generate", help="Generate all audio clips (6 voices)")
    subparsers.add_parser("test", help="Test with sample words")
    subparsers.add_parser("voices", help="List available Swahili voices")
    subparsers.add_parser("status", help="Show audio clip status")

    speak_parser = subparsers.add_parser("speak", help="Speak a word in all voices")
    speak_parser.add_argument("text", nargs="*", help="Awing text to speak")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    commands = {
        "setup": cmd_setup,
        "generate": cmd_generate,
        "speak": cmd_speak,
        "test": cmd_test,
        "voices": cmd_voices,
        "status": cmd_status,
    }

    success = commands[args.command](args)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
