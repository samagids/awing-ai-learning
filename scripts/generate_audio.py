"""
Awing Audio Clip Generator
===========================
Generates pronunciation audio clips for every alphabet sound and vocabulary word
in the Awing AI Learning app using Microsoft Edge TTS with IPA phoneme input.

Usage:
  pip install edge-tts
  python scripts/generate_audio.py

Output:
  assets/audio/alphabet/*.mp3   (31 clips)
  assets/audio/vocabulary/*.mp3 (67 clips)

The app automatically detects and uses these files instead of the TTS fallback.
"""

import asyncio
import os
import re
import sys

try:
    import edge_tts
except ImportError:
    print("ERROR: edge-tts not installed. Run: pip install edge-tts")
    sys.exit(1)

# --- Configuration ---
# en-KE (Kenya) or en-NG (Nigeria) voices sound more natural for African languages.
# Fallback to en-US if those aren't available.
PREFERRED_VOICES = [
    "en-KE-AsiliaNeural",   # Kenyan English (female) — best for African phonemes
    "en-NG-AbeoNeural",     # Nigerian English (male)
    "en-NG-EzinneNeural",   # Nigerian English (female)
    "en-KE-ChilembaNeural", # Kenyan English (male)
    "en-ZA-LeahNeural",     # South African English (female)
    "en-US-AriaNeural",     # US English fallback
]

# Slow rate for clear pronunciation
RATE = "-30%"  # 30% slower than normal
VOLUME = "+0%"

# Output directories (relative to project root)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ALPHABET_DIR = os.path.join(PROJECT_ROOT, "assets", "audio", "alphabet")
VOCABULARY_DIR = os.path.join(PROJECT_ROOT, "assets", "audio", "vocabulary")

# ============================================================
# ALPHABET DATA
# Each entry: (filename, display_letter, ipa_phoneme, ssml_phonetic_text)
# We use SSML <phoneme> tags with IPA for accurate pronunciation,
# with a plain-text fallback as backup.
# ============================================================
ALPHABET = [
    # Vowels
    ("a",        "a",  "aː",   "ah"),
    ("e",        "e",  "e",    "eh"),
    ("epsilon",  "ɛ",  "ɛ",    "air"),        # open-mid front
    ("schwa",    "ə",  "ə",    "uh"),          # schwa
    ("i",        "i",  "iː",   "ee"),
    ("barred_i", "ɨ",  "ɨ",    "ih"),          # close central
    ("o",        "o",  "oː",   "oh"),
    ("open_o",   "ɔ",  "ɔ",    "aw"),          # open-mid back
    ("u",        "u",  "uː",   "oo"),
    # Consonants
    ("b",   "b",  "b",   "buh"),
    ("ch",  "ch", "tʃ",  "chuh"),
    ("d",   "d",  "d",   "duh"),
    ("f",   "f",  "f",   "fuh"),
    ("g",   "g",  "ɡ",   "guh"),
    ("gh",  "gh", "ɣ",   "ghuh"),              # voiced velar fricative
    ("j",   "j",  "dʒ",  "juh"),
    ("k",   "k",  "k",   "kuh"),
    ("l",   "l",  "l",   "luh"),
    ("m",   "m",  "m",   "muh"),
    ("n",   "n",  "n",   "nuh"),
    ("ny",  "ny", "ɲ",   "nyuh"),              # palatal nasal
    ("eng", "ŋ",  "ŋ",   "ng"),               # velar nasal
    ("p",   "p",  "p",   "puh"),
    ("s",   "s",  "s",   "suh"),
    ("sh",  "sh", "ʃ",   "shuh"),
    ("t",   "t",  "t",   "tuh"),
    ("ts",  "ts", "ts",  "tsuh"),
    ("w",   "w",  "w",   "wuh"),
    ("y",   "y",  "j",   "yuh"),
    ("z",   "z",  "z",   "zuh"),
    ("glottal", "'", "ʔ", "uh-oh"),            # glottal stop
]

# ============================================================
# VOCABULARY DATA
# Each entry: (filename, awing_word, english, ipa_transcription)
# IPA transcriptions are approximated from the Awing orthography rules
# in AwingOrthography2005.pdf
# ============================================================
VOCABULARY = [
    # Body parts
    ("apo",       "apô",       "hand",        "àpô"),
    ("atue",      "atûə",      "head",        "àtûə"),
    ("aloeme",    "alɔ́əmə",    "tongue",      "àlɔ́əmə"),
    ("fele",      "fɛlə",      "breastbone",  "fɛ̀lə"),
    ("nelwie",    "nəlwîə",    "nose",        "nəlwîə"),
    ("nde",       "ndě",       "neck",        "ndě"),
    ("nkadte",    "nkadtə",    "back",        "nkàdtə"),
    ("mbete",     "mbe'tə",    "shoulder",    "mbèʔtə"),
    ("achie",     "achîə",     "blood",       "àtʃîə"),
    ("neto",      "nətô",      "intestine",   "nətô"),
    ("nepe",      "nəpe",      "liver",       "nəpè"),
    # Animals & Nature
    ("eshue",     "əshûə",     "fish",        "əʃûə"),
    ("konge",     "koŋə",      "owl",         "kòŋə"),
    ("anyenge",   "anyeŋə",    "claw",        "àɲèŋə"),
    ("nenjwinne", "nənjwínnə", "fly",         "nəndʒwínnə"),
    ("ankoome",   "ankoomə",   "ram",         "ànkòːmə"),
    ("ngeo",      "ngə'ɔ́",     "termite",     "ŋəʔɔ́"),
    ("noole",     "nóolə",     "snake",       "nóːlə"),
    ("atie",      "atîə",      "tree",        "àtîə"),
    ("akoobo",    "akoobɔ́",    "forest",      "àkòːbɔ́"),
    ("ngee",      "ngə'ə",     "stone",       "ŋəʔə"),
    ("waako",     "wâakɔ́",     "sand",        "wâːkɔ́"),
    ("newue",     "nəwûə",     "death",       "nəwûə"),
    # Actions
    ("no",        "nô",        "drink",       "nô"),
    ("lume",      "lúmə",      "bite",        "lúmə"),
    ("mie",       "mîə",       "swallow",     "mîə"),
    ("pime",      "pímə",      "believe",     "pímə"),
    ("tsoe",      "tsó'ə",     "heal",        "tsóʔə"),
    ("zoe",       "zó'ə",      "hear",        "zóʔə"),
    ("jage",      "jágə",      "yawn",        "dʒáɡə"),
    ("yike",      "yîkə",      "harden",      "jîkə"),
    ("ledno",     "lɛdnɔ́",     "sweat",       "lɛ̀dnɔ́"),
    ("pene",      "pɛ́nə",      "dance",       "pɛ́nə"),
    ("shie",      "shîə",      "stretch",     "ʃîə"),
    ("chato",     "cha'tɔ́",    "greet",       "tʃàʔtɔ́"),
    ("kwage",     "kwágə",     "cough",       "kwáɡə"),
    ("lyange",    "lyáŋə",     "hide",        "ljáŋə"),
    ("toge",      "tɔ́gə",      "blow",        "tɔ́ɡə"),
    ("fyaale",    "fyáalə",    "chase",       "fjáːlə"),
    ("ko",        "ko",        "take",        "kò"),
    ("yie",       "yîə",       "come",        "jîə"),
    # Things & Objects
    ("ajume",     "ajúmə",     "thing",       "àdʒúmə"),
    ("ajwike",    "ajwikə",    "window",      "àdʒwìkə"),
    ("afue",      "afûə",      "leaf",        "àfûə"),
    ("nese",      "nəse",      "grave",       "nəsè"),
    ("mbeene",    "mbéenə",    "nail",        "mbéːnə"),
    ("ndzo",      "ndzǒ",      "beans",       "ndzǒ"),
    ("nepoo",     "nəpɔ'ɔ́",    "pumpkin",     "nəpɔ̀ʔɔ́"),
    ("fwoe",      "fwɔ'ə",     "chisel",      "fwɔ̀ʔə"),
    ("shwaa",     "shwa'a",    "razor",       "ʃwàʔà"),
    ("ekwuno",    "əkwunɔ́",    "bed",         "əkwùnɔ́"),
    ("ndue",      "nduə",      "hammer",      "ndùə"),
    # Family & People
    ("ma",        "mǎ",        "mother",      "mǎ"),
    ("ye",        "yə",        "he/she",      "jə̀"),
    ("apeele",    "apɛ̌ɛlə",    "mad person",  "àpɛ̌ːlə"),
    ("efego",     "əfəgɔ́",     "blind person","əfəɡɔ́"),
    ("alae",      "alá'ə",     "village",     "àláʔə"),
    ("ngye",      "ngye",      "voice",       "ŋɡjè"),
    ("ayange",    "ayáŋə",     "wisdom",      "àjáŋə"),
    # Food & Daily Life
    ("apeeme",    "apeemə",    "bag",         "àpèːmə"),
    ("apeene",    "apéenə",    "flour",       "àpéːnə"),
    ("negoomo",   "nəgoomɔ́",   "plantain",    "nəɡòːmɔ́"),
    ("ngwange",   "ngwáŋə",    "salt",        "ŋwáŋə"),
    ("mandzo",    "mândzǒ",    "groundnuts",  "mândzǒ"),
    ("akwe",      "akwe",      "response",    "àkwè"),
    ("metwe",     "mətwé",     "saliva",      "mətwé"),
    ("nekengo",   "nəkəŋɔ́",    "pot",         "nəkəŋɔ́"),
]


def build_ssml(ipa: str, fallback_text: str, voice: str) -> str:
    """Build SSML with IPA phoneme tag and plain-text fallback."""
    # Use phoneme tag with IPA alphabet for precise pronunciation
    return f"""<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
    <voice name="{voice}">
        <prosody rate="{RATE}" volume="{VOLUME}">
            <phoneme alphabet="ipa" ph="{ipa}">{fallback_text}</phoneme>
        </prosody>
    </voice>
</speak>"""


def build_plain_ssml(text: str, voice: str) -> str:
    """Build SSML with just plain text (no IPA) as fallback."""
    return f"""<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
    <voice name="{voice}">
        <prosody rate="{RATE}" volume="{VOLUME}">
            {text}
        </prosody>
    </voice>
</speak>"""


async def find_best_voice() -> str:
    """Find the best available voice from our preference list."""
    try:
        voices = await edge_tts.list_voices()
        available = {v["ShortName"] for v in voices}
        for pref in PREFERRED_VOICES:
            if pref in available:
                return pref
    except Exception:
        pass
    # Default fallback
    return "en-US-AriaNeural"


async def generate_clip(ssml: str, output_path: str) -> bool:
    """Generate a single audio clip from SSML."""
    try:
        communicate = edge_tts.Communicate(ssml, codec="audio-24khz-48kbitrate-mono-mp3")
        await communicate.save(output_path)
        # Verify file was created and has content
        if os.path.exists(output_path) and os.path.getsize(output_path) > 100:
            return True
    except Exception as e:
        print(f"  SSML failed, trying plain text: {e}")
    return False


async def generate_clip_plain(text: str, voice: str, output_path: str) -> bool:
    """Generate a clip using plain text (fallback when SSML/IPA fails)."""
    try:
        communicate = edge_tts.Communicate(
            text, voice=voice, rate=RATE, volume=VOLUME
        )
        await communicate.save(output_path)
        if os.path.exists(output_path) and os.path.getsize(output_path) > 100:
            return True
    except Exception as e:
        print(f"  Plain text also failed: {e}")
    return False


async def main():
    print("=" * 60)
    print("  Awing Audio Clip Generator")
    print("  Using Microsoft Edge TTS with IPA phonemes")
    print("=" * 60)

    # Create output directories
    os.makedirs(ALPHABET_DIR, exist_ok=True)
    os.makedirs(VOCABULARY_DIR, exist_ok=True)

    # Find best voice
    voice = await find_best_voice()
    print(f"\nUsing voice: {voice}")
    print()

    # --- Generate alphabet clips ---
    print(f"Generating {len(ALPHABET)} alphabet clips...")
    alphabet_success = 0
    for filename, letter, ipa, fallback in ALPHABET:
        output_path = os.path.join(ALPHABET_DIR, f"{filename}.mp3")

        # Try IPA SSML first
        ssml = build_ssml(ipa, fallback, voice)
        if await generate_clip(ssml, output_path):
            alphabet_success += 1
            print(f"  ✓ {filename}.mp3  ({letter})")
            continue

        # Fallback to plain text
        if await generate_clip_plain(fallback, voice, output_path):
            alphabet_success += 1
            print(f"  ✓ {filename}.mp3  ({letter}) [plain text fallback]")
        else:
            print(f"  ✗ {filename}.mp3  ({letter}) FAILED")

    print(f"\nAlphabet: {alphabet_success}/{len(ALPHABET)} clips generated")
    print()

    # --- Generate vocabulary clips ---
    print(f"Generating {len(VOCABULARY)} vocabulary clips...")
    vocab_success = 0
    for filename, awing, english, ipa in VOCABULARY:
        output_path = os.path.join(VOCABULARY_DIR, f"{filename}.mp3")

        # Try IPA SSML first
        ssml = build_ssml(ipa, awing, voice)
        if await generate_clip(ssml, output_path):
            vocab_success += 1
            print(f"  ✓ {filename}.mp3  ({awing} = {english})")
            continue

        # Fallback to plain text
        if await generate_clip_plain(awing, voice, output_path):
            vocab_success += 1
            print(f"  ✓ {filename}.mp3  ({awing} = {english}) [plain text fallback]")
        else:
            print(f"  ✗ {filename}.mp3  ({awing} = {english}) FAILED")

    print(f"\nVocabulary: {vocab_success}/{len(VOCABULARY)} clips generated")
    print()

    total = alphabet_success + vocab_success
    total_expected = len(ALPHABET) + len(VOCABULARY)
    print("=" * 60)
    print(f"  DONE: {total}/{total_expected} audio clips generated")
    print(f"  Alphabet:   {ALPHABET_DIR}")
    print(f"  Vocabulary: {VOCABULARY_DIR}")
    print("=" * 60)
    print()
    print("Next steps:")
    print("  1. flutter pub get")
    print("  2. flutter build apk --release")
    print("  3. The app will automatically use these audio files!")


if __name__ == "__main__":
    asyncio.run(main())
