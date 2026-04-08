#!/usr/bin/env python3
"""
Awing eSpeak-NG TTS Engine v3.0.0
==================================
Full text-to-speech engine for the Awing language (ISO 639-3: azo).

This script:
1. Installs custom Awing voice + phoneme files into a local eSpeak-NG data copy
2. Converts Awing text to eSpeak phonemes via a Python phonemizer (no dictionary compilation)
3. Generates audio with per-syllable pitch variation for tonal accuracy
4. Generates audio for any Awing text — single words, phrases, sentences, or stories

Key features (v3.0):
- Per-syllable tonal pitch: High=82, Mid=62, Low=38, Rising=55, Falling=65
- Voice priority: custom Awing (azo) → Swahili (sw) → English (en)
- Custom Awing voice uses specialized formants for Bantu vowels
- Voice file uses 'dictionary en' to bypass Windows dictionary compilation bug

Usage:
    python scripts/generate_audio_espeak.py setup          # First-time setup: clone + compile
    python scripts/generate_audio_espeak.py compile        # Recompile after editing language files
    python scripts/generate_audio_espeak.py speak "apô"    # Speak a single word (plays audio)
    python scripts/generate_audio_espeak.py generate       # Generate all app audio clips
    python scripts/generate_audio_espeak.py generate-all   # Generate clips for ALL dictionary words
    python scripts/generate_audio_espeak.py speak-file input.txt output.wav  # Convert text file to audio
    python scripts/generate_audio_espeak.py test           # Test pronunciation of sample words
    python scripts/generate_audio_espeak.py status         # Show setup status
    python scripts/generate_audio_espeak.py list           # Show generated audio files
    python scripts/generate_audio_espeak.py clean          # Remove temp files

Author: Generated for Awing AI Learning project
"""

import os
import sys
import subprocess
import shutil
import json
import re
import argparse
import glob
from pathlib import Path

# ====================================================================
# CONFIGURATION
# ====================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent
ESPEAK_DIR = PROJECT_DIR / "espeak"          # Our custom language files
ESPEAK_NG_DIR = PROJECT_DIR / "espeak-ng"    # Cloned espeak-ng source
AUDIO_DIR = PROJECT_DIR / "assets" / "audio"
ALPHABET_DIR = AUDIO_DIR / "alphabet"
VOCABULARY_DIR = AUDIO_DIR / "vocabulary"
SENTENCES_DIR = AUDIO_DIR / "sentences"
STORIES_DIR = AUDIO_DIR / "stories"
TEMP_DIR = SCRIPT_DIR / "_espeak_temp"

# eSpeak-NG repository
ESPEAK_NG_REPO = "https://github.com/espeak-ng/espeak-ng.git"

# Version
VERSION = "3.0.0"


# ====================================================================
# AWING VOCABULARY DATA
# Extracted from lib/data/awing_alphabet.dart and awing_vocabulary.dart
# This is the MINIMUM set for the app. The engine can speak ANY text.
# ====================================================================

ALPHABET_SOUNDS = {
    # Vowels (9)
    "a": "a", "e": "e", "epsilon": "ɛ", "schwa": "ə",
    "i": "i", "barred_i": "ɨ", "o": "o", "open_o": "ɔ", "u": "u",
    # Consonants (22)
    "b": "bə́", "ch": "chə́", "d": "də́", "f": "fə́",
    "g": "gə́", "gh": "ghə́", "j": "jə́", "k": "kə́",
    "l": "lə́", "m": "mə́", "n": "nə́", "ny": "nyə́",
    "eng": "ŋə́", "p": "pə́", "s": "sə́", "sh": "shə́",
    "t": "tə́", "ts": "tsə́", "w": "wə́", "y": "yə́",
    "z": "zə́", "glottal": "ə́'ə́",
}

VOCABULARY_WORDS = {
    # Body parts
    "apo": "apô", "atuo": "atûə", "alo": "alɔ́",
    "nde": "ndě", "etuo": "ətûə", "eghang": "əghàŋə́",
    "fele": "fɛlə",
    # Animals & Nature
    "eshue": "əshûə", "nyi": "nyì", "ewue": "əwûə",
    "ekuo": "əkûə", "fufe": "fúfé", "ngong": "ŋgɔ́ŋə́",
    # Actions
    "kolo": "kóolə", "no": "nô", "lumo": "lúmə",
    "nso": "nsɔ́", "ko": "kó", "fye": "fyɛ́",
    "sedne": "sɛdnɔ́",
    # Things
    "apeemo": "apɛ̌ɛmɔ́", "akwe": "ákwé", "nsoole": "nsóolə",
    "ndwigto": "ndwígtɔ́", "achio": "achîə",
    # Family
    "tata": "tátá", "mama": "mámá", "wane": "wánɛ́",
    "mbengne": "mbɛ́ŋnɛ́", "mbelengne": "mbɛ́lɛ́ŋnɛ́",
    # Daily life
    "aleme": "álɛ́mɛ́", "mbe_to": "mbɛ́'tə́", "efoo": "əfóo",
    "ngoone": "ŋgóonɛ́", "njwe": "njwɛ́",
    # Additional vocabulary from dictionary
    "kwite": "kwɨ̌tə́", "neemo": "nɛ́ɛmɔ́", "afue": "áfûə",
    "nkadto": "nkádtɔ́", "ankoomo": "ánkóomɔ́",
    "ngoomo": "ŋgóomɔ́", "azepo": "ázɛ́pɔ́",
    "mbooto": "mbóotɔ́", "ndoone": "ndóonɛ́",
    "alangne": "áláŋnɛ́", "ambeene": "ámbɛ́ɛnɛ́",
    "echie": "əchîɛ́", "eghone": "əghɔ́nɛ́",
    "etie": "ətîɛ́", "efwone": "əfwɔ́nɛ́",
    "ewine": "əwǐnɛ́", "enyie": "ənyîɛ́",
    "elie": "əlîɛ́", "ejie": "əjîɛ́",
    "eshe": "əshɛ́", "etse": "ətsɛ́",
}

# Sentences for Medium module
SENTENCES = {
    "greeting_1": "Ə́ mbɔ́ŋ wó?",            # How are you?
    "greeting_2": "Mə́ mbɔ́ŋ.",                # I am fine.
    "greeting_3": "Á nyɛ̀ wó!",               # Welcome!
    "introduce_1": "Ǹtsə́ mə́ á Guidion.",    # My name is Guidion.
    "introduce_2": "Mə́ fúú ə́ Awing.",       # I come from Awing.
    "daily_1": "Mə́ kó ndô.",                  # I drink water.
    "daily_2": "Á lúmə́ mə́.",                 # He/She bites me.
    "daily_3": "Mbə̌ə kóolə́.",               # I will catch it.
}

# Stories for storytelling mode
STORIES = {
    "story_1_title": "Ŋwáŋə́ ə́ Kwɨ̌tə́",    # The Tortoise Story
    "story_1_line_1": "Kwɨ̌tə́ á ghə̂ə əfóo á lə̀.",
    "story_1_line_2": "Á kóolə́ ənyîɛ́ á tə̀.",
    "story_1_line_3": "Mbə̌ə á fyɛ́ á ŋgóonɛ́.",
}


# ====================================================================
# PYTHON PHONEMIZER
# Converts Awing orthography → eSpeak phoneme strings in Python.
# This completely replaces the eSpeak-NG dictionary (azo_dict), which
# could never be compiled on Windows 1.52 due to a path resolution bug.
# Instead, we pass phonemes directly using eSpeak's [[ ]] inline syntax.
# ====================================================================

import unicodedata

def _normalize_awing(text):
    """Normalize Unicode: NFC compose, fix combining sequences."""
    # NFC normalization first
    text = unicodedata.normalize("NFC", text)
    return text


def _get_tone(char):
    """Extract tone from a vowel character. Returns (base_vowel, tone_number).
    Tone 1=High(acute), 3=Low(unmarked), 4=Rising(caron), 5=Falling(circumflex)."""
    # Decompose to check for combining marks
    decomposed = unicodedata.normalize("NFD", char)
    base = ""
    tone = "3"  # default = Low (unmarked)

    for c in decomposed:
        cat = unicodedata.category(c)
        if cat.startswith("M"):  # combining mark
            if c == '\u0301':    # combining acute accent
                tone = "1"      # High
            elif c == '\u0302':  # combining circumflex
                tone = "5"      # Falling
            elif c == '\u030C':  # combining caron
                tone = "4"      # Rising
            elif c == '\u0300':  # combining grave accent
                tone = "3"      # Low (explicit)
            # else: ignore other combining marks
        else:
            base += c

    return base, tone


# Vowel orthography → eSpeak phoneme mapping
_VOWEL_MAP = {
    "a": "a", "e": "e", "ɛ": "E", "ə": "@",
    "i": "i", "ɨ": "I", "o": "o", "ɔ": "O", "u": "u",
}

# Consonant cluster/digraph rules — LONGEST MATCH FIRST
# Each entry: (orthography, phoneme_string)
_CONSONANT_RULES = [
    # Prenasalized + palatalized/labialized (4-char)
    ("nchw", "n^tSw"), ("njw", "n^Zw"),
    # Prenasalized (3-char)
    ("nch", "n^tS"), ("nts", "nts"), ("ndz", "ndz"), ("nny", "n^n^"),
    ("shw", "Sw"), ("chw", "tSw"),
    # Prenasalized (2-char)
    ("mb", "mb"), ("nt", "nt"), ("nd", "nd"), ("nk", "Nk"),
    ("ng", "Ng"), ("ŋg", "Ng"), ("ŋk", "Nk"),
    ("mm", "mm"), ("nn", "nn"), ("nj", "n^Z"),
    ("nw", "nw"),
    # Palatalized (2-char)
    ("ty", "tj"), ("ky", "kj"), ("py", "pj"), ("by", "bj"),
    ("gy", "gj"), ("fy", "fj"), ("ly", "lj"), ("my", "mj"),
    # Labialized (2-char)
    ("tw", "tw"), ("kw", "kw"), ("pw", "pw"), ("bw", "bw"),
    ("dw", "dw"), ("gw", "gw"), ("fw", "fw"), ("lw", "lw"),
    ("jw", "Zw"),
    # Digraphs (2-char)
    ("gh", "Q"), ("sh", "S"), ("ch", "tS"), ("ts", "ts"), ("ny", "n^"),
    # Single consonants
    ("b", "b"), ("d", "d"), ("f", "f"), ("g", "g"), ("j", "Z"),
    ("k", "k"), ("l", "l"), ("m", "m"), ("n", "n"), ("p", "p"),
    ("s", "s"), ("t", "t"), ("w", "w"), ("y", "j"), ("z", "z"),
    # Special
    ("ŋ", "N"), ("'", "?"), ("\u2019", "?"), ("\u2018", "?"),
]

# Syllabic nasal prefixes (with high tone — tone 1 before the nasal)
_SYLLABIC_NASALS = {
    "ḿ": "1m", "ń": "1n", "ŋ́": "1N",
}


def _split_graphemes(text):
    """Split text into grapheme clusters (base char + combining marks).

    Python iterates by code point, but Awing vowels like ɛ́ are stored as
    two code points: ɛ (U+025B) + ◌́ (U+0301 combining acute). This function
    groups each base character with its trailing combining marks so that
    tone detection works correctly.
    """
    clusters = []
    current = ""
    for ch in text:
        if unicodedata.category(ch).startswith("M") and current:
            # Combining mark — append to current cluster
            current += ch
        else:
            if current:
                clusters.append(current)
            current = ch
    if current:
        clusters.append(current)
    return clusters


def awing_to_phonemes(text):
    """Convert Awing orthography text to eSpeak phoneme string.

    This implements the same rules as azo_rules but in Python, producing
    phoneme strings compatible with eSpeak-NG's base1 phoneme table.
    The output can be passed to eSpeak using [[ ]] inline phoneme syntax.

    Returns: phoneme string (e.g., "a3po5" for "apô")
    """
    text = _normalize_awing(text.strip())
    result = []
    words = text.split()

    for wi, word in enumerate(words):
        if wi > 0:
            result.append(" ")  # word boundary

        # Split into grapheme clusters (handles combining marks)
        clusters = _split_graphemes(word)
        i = 0

        while i < len(clusters):
            cluster = clusters[i]

            # Check syllabic nasals (ḿ, ń, ŋ́)
            matched_nasal = False
            for nasal_orth, nasal_ph in _SYLLABIC_NASALS.items():
                # Compare NFC forms for reliable matching
                nfc_cluster = unicodedata.normalize("NFC", cluster)
                nfc_nasal = unicodedata.normalize("NFC", nasal_orth)
                if nfc_cluster == nfc_nasal:
                    result.append(nasal_ph)
                    i += 1
                    matched_nasal = True
                    break
            if matched_nasal:
                continue

            # Check if current cluster is a vowel (strip tone to check)
            base_char, tone = _get_tone(cluster)
            base_lower = base_char.lower()

            if base_lower in _VOWEL_MAP:
                phoneme = _VOWEL_MAP[base_lower]

                # Check for long vowel (doubled) or diphthong — look ahead
                if i + 1 < len(clusters):
                    next_base, next_tone = _get_tone(clusters[i + 1])
                    next_lower = next_base.lower()

                    # Diphthongs: iə, ɨə, uə
                    if base_lower in ("i", "ɨ", "u") and next_lower == "ə":
                        diph_tone = tone if tone != "3" else next_tone
                        if base_lower == "i":
                            result.append(f"{diph_tone}i@")
                        elif base_lower == "ɨ":
                            result.append(f"{diph_tone}I@")
                        else:  # u
                            result.append(f"{diph_tone}u@")
                        i += 2
                        continue

                    # Long vowel (same base vowel repeated)
                    if next_lower == base_lower:
                        long_tone = tone if tone != "3" else next_tone
                        result.append(f"{long_tone}{phoneme}:")
                        i += 2
                        continue

                # Short vowel — stress number BEFORE the vowel
                result.append(f"{tone}{phoneme}")
                i += 1
                continue

            # Try consonant rules (longest match first)
            # Build a lowercase string from remaining clusters for matching
            remaining = "".join(clusters[i:]).lower()
            # Strip combining marks for consonant matching
            remaining_base = unicodedata.normalize("NFD", remaining)
            remaining_base = "".join(c for c in remaining_base
                                     if not unicodedata.category(c).startswith("M"))

            matched = False
            for orth, ph in _CONSONANT_RULES:
                if remaining_base.startswith(orth):
                    result.append(ph)
                    # Advance by the number of grapheme clusters consumed
                    consumed = len(orth)
                    chars_consumed = 0
                    ci = i
                    while ci < len(clusters) and chars_consumed < consumed:
                        base_only = unicodedata.normalize("NFD", clusters[ci])
                        base_only = "".join(c for c in base_only
                                            if not unicodedata.category(c).startswith("M"))
                        chars_consumed += len(base_only)
                        ci += 1
                    i = ci
                    matched = True
                    break

            if not matched:
                # Unknown character — skip it
                i += 1

    # eSpeak [[ ]] inline phonemes are space-separated
    return " ".join(result)


def find_espeak_ng():
    """Find espeak-ng executable — check local build first, then system."""
    # Check our local build
    local_paths = [
        ESPEAK_NG_DIR / "build" / "espeak-ng.exe",
        ESPEAK_NG_DIR / "build" / "Release" / "espeak-ng.exe",
        ESPEAK_NG_DIR / "build" / "Debug" / "espeak-ng.exe",
        ESPEAK_NG_DIR / "src" / "espeak-ng.exe",
    ]
    for p in local_paths:
        if p.exists():
            return str(p)

    # Check system installation
    espeak = shutil.which("espeak-ng")
    if espeak:
        return espeak

    # Check common Windows install locations
    program_paths = [
        Path(os.environ.get("ProgramFiles", "C:\\Program Files")) / "eSpeak NG" / "espeak-ng.exe",
        Path(os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)")) / "eSpeak NG" / "espeak-ng.exe",
        Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "eSpeak NG" / "espeak-ng.exe",
    ]
    for p in program_paths:
        if p.exists():
            return str(p)

    return None


def find_system_espeak_data():
    """Find the system eSpeak-NG data directory (read-only, for copying)."""
    system_paths = [
        Path(os.environ.get("ProgramFiles", "C:\\Program Files")) / "eSpeak NG" / "espeak-ng-data",
        Path(os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)")) / "eSpeak NG" / "espeak-ng-data",
        Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "eSpeak NG" / "espeak-ng-data",
        Path("/usr/share/espeak-ng-data"),
        Path("/usr/lib/espeak-ng-data"),
    ]
    for p in system_paths:
        if p.exists():
            return p
    return None


# Local data directory — we copy espeak-ng-data here so we can write to it
# without admin privileges. ESPEAK_DATA_PATH points espeak-ng here.
LOCAL_ESPEAK_DATA = PROJECT_DIR / "espeak-ng-data"


def find_espeak_data_dir():
    """Find eSpeak-NG data directory. Prefers our local writable copy."""
    # Check environment variable first
    data_env = os.environ.get("ESPEAK_DATA_PATH")
    if data_env and Path(data_env).exists():
        return Path(data_env)

    # Check our local project copy (writable, no admin needed)
    if LOCAL_ESPEAK_DATA.exists():
        return LOCAL_ESPEAK_DATA

    # Check local build
    local_data = ESPEAK_NG_DIR / "espeak-ng-data"
    if local_data.exists():
        return local_data

    # Fall back to system installation (may be read-only)
    return find_system_espeak_data()


def download_phsource(target_dir):
    """Download the phsource/ directory from the eSpeak-NG GitHub repo.

    The binary MSI release of eSpeak-NG does NOT include phsource/ (phoneme
    source definitions). We need it to register and compile our custom 'azo'
    phoneme table. This function does a sparse Git checkout of just phsource/
    from the official repo.

    IMPORTANT: eSpeak-NG expects phsource/ as a SIBLING of espeak-ng-data/,
    not inside it. The compiler resolves: espeak-ng-data/../phsource/phonemes
    So target_dir should be the PARENT directory of espeak-ng-data/.
    """
    phsource = target_dir / "phsource"
    master_phonemes = phsource / "phonemes"

    # Already have it?
    if master_phonemes.exists():
        return True

    print("\n  phsource/ not found (binary install only).")
    print(f"  Downloading phoneme source files from eSpeak-NG GitHub to: {phsource}")

    git_exe = shutil.which("git")
    if not git_exe:
        print("  ERROR: git not found. Cannot download phsource/.")
        return False

    # Clone just the phsource/ directory using sparse checkout
    clone_dir = TEMP_DIR / "espeak-ng-src"
    if clone_dir.exists():
        shutil.rmtree(clone_dir, ignore_errors=True)

    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    try:
        # Shallow clone with no checkout
        subprocess.run(
            [git_exe, "clone", "--depth", "1", "--filter=blob:none",
             "--sparse", "--no-checkout", ESPEAK_NG_REPO, str(clone_dir)],
            capture_output=True, text=True, check=True, timeout=120
        )
        # Set sparse checkout to only phsource/
        subprocess.run(
            [git_exe, "-C", str(clone_dir), "sparse-checkout", "set", "phsource"],
            capture_output=True, text=True, check=True, timeout=30
        )
        # Checkout just phsource/
        subprocess.run(
            [git_exe, "-C", str(clone_dir), "checkout"],
            capture_output=True, text=True, check=True, timeout=60
        )

        src_phsource = clone_dir / "phsource"
        if src_phsource.exists() and (src_phsource / "phonemes").exists():
            # Copy phsource/ to the target directory (sibling of espeak-ng-data)
            if phsource.exists():
                shutil.rmtree(phsource)
            shutil.copytree(src_phsource, phsource)
            print(f"  Downloaded phsource/ ({len(list(phsource.rglob('*')))} files)")
            return True
        else:
            print("  ERROR: phsource/phonemes not found in downloaded repo")
            return False

    except subprocess.TimeoutExpired:
        print("  ERROR: Git clone timed out. Check your internet connection.")
        return False
    except subprocess.CalledProcessError as e:
        print(f"  ERROR: Git command failed: {e}")
        if e.stderr:
            print(f"  {e.stderr[:300]}")
        return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False
    finally:
        # Clean up clone dir
        if clone_dir.exists():
            shutil.rmtree(clone_dir, ignore_errors=True)


def install_language_files(data_dir):
    """Install Awing language files into the eSpeak-NG data directory.
    If the data dir is read-only (e.g. Program Files), creates a local
    writable copy first. Downloads phsource/ from GitHub if missing."""
    print("\n--- Installing Awing language files ---")

    # Test if we can write to data_dir
    try:
        test_dir = data_dir / "lang" / "nic"
        test_dir.mkdir(parents=True, exist_ok=True)
        # Can write — use it directly
    except PermissionError:
        # Can't write (Program Files) — create local copy
        print(f"  System data dir is read-only: {data_dir}")
        print(f"  Creating local writable copy at: {LOCAL_ESPEAK_DATA}")
        if not LOCAL_ESPEAK_DATA.exists():
            shutil.copytree(data_dir, LOCAL_ESPEAK_DATA)
            print(f"  Copied {data_dir} → {LOCAL_ESPEAK_DATA}")
        data_dir = LOCAL_ESPEAK_DATA

    # 1. Voice file
    lang_dir = data_dir / "lang" / "nic"  # Niger-Congo language family
    lang_dir.mkdir(parents=True, exist_ok=True)
    voice_src = ESPEAK_DIR / "voices" / "nic" / "azo"
    voice_dst = lang_dir / "azo"
    shutil.copy2(voice_src, voice_dst)
    print(f"  Voice file: {voice_dst}")

    # Also copy to voices directory if it exists
    voices_dir = data_dir / "voices" / "!v"
    if voices_dir.parent.exists():
        voices_nic = data_dir / "voices" / "nic"
        voices_nic.mkdir(parents=True, exist_ok=True)
        shutil.copy2(voice_src, voices_nic / "azo")

    # 2. Download phsource/ from GitHub if not present (binary installs lack it)
    # IMPORTANT: eSpeak-NG expects phsource/ as a SIBLING of espeak-ng-data/,
    # not inside it. The compiler resolves: espeak-ng-data/../phsource/phonemes
    if data_dir.name == "espeak-ng-data":
        phsource_parent = data_dir.parent  # sibling level
    else:
        phsource_parent = data_dir
    phsource = phsource_parent / "phsource"
    master_phonemes = phsource / "phonemes"

    # Migration: if phsource was incorrectly placed INSIDE espeak-ng-data, move it
    wrong_phsource = data_dir / "phsource"
    if wrong_phsource.exists() and wrong_phsource != phsource:
        if not phsource.exists():
            print(f"  Migrating phsource/ from inside espeak-ng-data to sibling location")
            shutil.move(str(wrong_phsource), str(phsource))
        else:
            shutil.rmtree(wrong_phsource, ignore_errors=True)

    if not master_phonemes.exists():
        download_phsource(phsource_parent)

    # 3. Register phoneme table in master phonemes file
    if not phsource.exists():
        phsource.mkdir(parents=True, exist_ok=True)

    # Copy our phoneme definition
    ph_src = ESPEAK_DIR / "phsource" / "ph_awing"
    shutil.copy2(ph_src, phsource / "ph_awing")

    # Add to master phonemes file
    if master_phonemes.exists():
        content = master_phonemes.read_text(encoding="utf-8", errors="replace")
        if "phonemetable azo" not in content:
            addition = "\n\nphonemetable azo base1\ninclude ph_awing\n"
            with open(master_phonemes, "a", encoding="utf-8") as f:
                f.write(addition)
            print("  Registered phonemetable azo in master phonemes file")
        else:
            print("  Phonemetable azo already registered")
    else:
        print("  WARNING: No master phonemes file found — could not download phsource/.")
        print("  Will use base1 phonemes as fallback.")

    # 4. Copy dictionary source files
    # espeak-ng --compile=azo looks for dictsource/ INSIDE espeak-ng-data/
    # (path_home/dictsource/azo_rules where path_home = espeak-ng-data)
    dictsource = data_dir / "dictsource"
    dictsource.mkdir(parents=True, exist_ok=True)

    rules_src = ESPEAK_DIR / "dictsource" / "azo_rules"
    list_src = ESPEAK_DIR / "dictsource" / "azo_list"
    shutil.copy2(rules_src, dictsource / "azo_rules")
    shutil.copy2(list_src, dictsource / "azo_list")
    print(f"  Dictionary sources: {dictsource}")

    print("  Awing language files installed.")
    return data_dir  # Return the actual data dir used (may have changed)


def compile_dictionary(espeak_exe, data_dir):
    """Compile the Awing dictionary (rules + list → azo_dict).

    eSpeak-NG 1.52 on Windows has a bug: --compile ignores --path and
    ESPEAK_DATA_PATH for dictsource resolution. The CLI approach is broken.

    Solution: Use the espeak-ng DLL directly via ctypes. The library's
    espeak_ng_CompileDictionary() function accepts an explicit dictsource
    path parameter, bypassing the broken path resolution.
    """
    print("\n--- Compiling Awing dictionary ---")

    # Ensure dictsource exists inside data_dir
    dictsource = data_dir / "dictsource"
    dictsource.mkdir(parents=True, exist_ok=True)
    rules_src = ESPEAK_DIR / "dictsource" / "azo_rules"
    list_src = ESPEAK_DIR / "dictsource" / "azo_list"
    shutil.copy2(rules_src, dictsource / "azo_rules")
    shutil.copy2(list_src, dictsource / "azo_list")

    if not (dictsource / "azo_rules").exists():
        print(f"  ERROR: azo_rules not found in {dictsource}")
        return False

    print(f"  Dictsource: {dictsource}")

    # --- Method 1: Use espeak-ng DLL via ctypes ---
    dll_path = _find_espeak_dll(espeak_exe)
    if dll_path:
        print(f"  Using DLL: {dll_path}")
        result = _compile_dict_via_dll(dll_path, data_dir, dictsource)
        if result:
            return True
        print("  DLL method failed, trying CLI fallback...")

    # --- Method 2: CLI with explicit dictsource path (comma syntax) ---
    # Some eSpeak-NG builds support: --compile=lang,/path/to/dictsource/
    print("  Trying CLI --compile with explicit path...")
    env = os.environ.copy()
    if data_dir.name == "espeak-ng-data":
        env["ESPEAK_DATA_PATH"] = str(data_dir.parent)
    else:
        env["ESPEAK_DATA_PATH"] = str(data_dir)

    # Try comma-separated path syntax
    dsource_path = str(dictsource).replace("\\", "/") + "/"
    try:
        result = subprocess.run(
            [espeak_exe, f"--compile=azo,{dsource_path}"],
            capture_output=True, text=True, env=env
        )
        dict_file = data_dir / "azo_dict"
        # Dict must be >100 bytes — an 8-byte file is just an empty header
        # meaning the rules weren't processed (phoneme table not found)
        if dict_file.exists() and dict_file.stat().st_size > 100:
            print(f"  Dictionary compiled: {dict_file} ({dict_file.stat().st_size} bytes)")
            return True
        elif dict_file.exists():
            print(f"  CLI comma syntax: dict too small ({dict_file.stat().st_size} bytes) — rules not processed")
            dict_file.unlink()  # Remove the empty dict
    except Exception:
        pass

    # --- Method 3: Copy to system dir + compile without --path ---
    # eSpeak-NG 1.52 CLI always reads from its compiled-in system path.
    # If we copy our files there, the plain --compile=azo works.
    sys_data = find_system_espeak_data()
    if sys_data and sys.platform == "win32":
        print("\n  Trying Method 3: copy to system dir + compile...")
        result = _compile_via_system_dir(espeak_exe, sys_data, dictsource, data_dir)
        if result:
            return True

    print("  ERROR: All dictionary compilation methods failed.")
    print("  The app will still work using phoneme rules for pronunciation.")
    return False


def _find_espeak_dll(espeak_exe):
    """Find the espeak-ng DLL near the executable."""
    exe_dir = Path(espeak_exe).parent
    for name in ["espeak-ng.dll", "espeak.dll", "libespeak-ng.dll"]:
        dll = exe_dir / name
        if dll.exists():
            return str(dll)
    return None


def _compile_dict_via_dll(dll_path, data_dir, dictsource):
    """Compile dictionary using espeak-ng DLL via ctypes.

    IMPORTANT: The DLL ignores the path parameter to espeak_Initialize when
    loading phoneme data — it always uses its compiled-in system path. So we
    must temporarily copy our compiled phoneme files (phondata, phonindex,
    phontab) to the system directory, initialize the DLL (which loads our
    phonemes from the system path), compile the dictionary with explicit
    dsource, then restore the original system phoneme files.
    """
    import ctypes

    # We need to temporarily install our phoneme data in the system dir
    sys_data = find_system_espeak_data()
    if not sys_data:
        print("  DLL: System espeak-ng-data not found, can't use DLL method")
        return False

    # Files we need to temporarily copy to system dir
    phoneme_files = ["phondata", "phonindex", "phontab", "intonations"]
    voice_dir = sys_data / "voices" / "nic"
    lang_dir = sys_data / "lang" / "nic"

    backups = {}
    installed_files = []

    try:
        # Step 1: Backup and copy phoneme files + voice to system dir
        for fname in phoneme_files:
            local_file = data_dir / fname
            sys_file = sys_data / fname
            if local_file.exists():
                if sys_file.exists():
                    backup_path = sys_file.with_suffix(f".{fname}.bak")
                    shutil.copy2(sys_file, backup_path)
                    backups[sys_file] = backup_path
                shutil.copy2(local_file, sys_file)
                installed_files.append(sys_file)

        # Copy voice file
        for vdir in [voice_dir, lang_dir]:
            try:
                vdir.mkdir(parents=True, exist_ok=True)
                voice_src = ESPEAK_DIR / "voices" / "nic" / "azo"
                voice_dst = vdir / "azo"
                shutil.copy2(voice_src, voice_dst)
                installed_files.append(voice_dst)
            except PermissionError:
                print(f"  DLL: Can't write to {vdir} — need admin")
                return False

    except PermissionError:
        print("  DLL: Can't write to system dir — need admin")
        # Restore any backups we already made
        for sys_file, backup_path in backups.items():
            if backup_path.exists():
                shutil.copy2(backup_path, sys_file)
                backup_path.unlink()
        return False

    try:
        # Step 2: Load DLL and initialize (will now find 'azo' phonemes in system dir)
        dll = ctypes.CDLL(dll_path)

        dll.espeak_Initialize.argtypes = [
            ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_int
        ]
        dll.espeak_Initialize.restype = ctypes.c_int

        dll.espeak_ng_CompileDictionary.argtypes = [
            ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int
        ]
        dll.espeak_ng_CompileDictionary.restype = ctypes.c_int

        # Initialize with system path (None = use default compiled-in path)
        sample_rate = dll.espeak_Initialize(1, 0, None, 0)
        if sample_rate == -1:
            print("  DLL: espeak_Initialize failed")
            return False
        print(f"  DLL: Initialized OK (sample_rate={sample_rate})")

        # Compile with explicit dictsource path
        dsource = str(dictsource).encode("utf-8") + b"\\"
        print(f"  DLL: Compiling with dsource={dsource.decode()}")
        status = dll.espeak_ng_CompileDictionary(dsource, b"azo", None, 0)
        print(f"  DLL: CompileDictionary returned status={status}")

        # Check for azo_dict — might be in our local dir (via dsource) or system dir
        dict_file = data_dir / "azo_dict"
        if dict_file.exists() and dict_file.stat().st_size > 0:
            print(f"  DLL: Dictionary compiled: {dict_file} ({dict_file.stat().st_size} bytes)")
            return True

        # Check system dir (DLL writes dict next to phondata)
        sys_dict = sys_data / "azo_dict"
        if sys_dict.exists() and sys_dict.stat().st_size > 0:
            shutil.copy2(sys_dict, dict_file)
            sys_dict.unlink(missing_ok=True)
            print(f"  DLL: Found dict in system dir, copied to {dict_file}")
            return True

        print("  DLL: azo_dict not found after compilation")
        return False

    except OSError as e:
        print(f"  DLL: Error: {e}")
        return False
    except Exception as e:
        print(f"  DLL: Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        # Step 3: Restore system dir — remove our files, restore backups
        for sys_file, backup_path in backups.items():
            if backup_path.exists():
                shutil.copy2(backup_path, sys_file)
                backup_path.unlink(missing_ok=True)
        for f in installed_files:
            if f not in backups:  # Don't remove files we backed up (already restored)
                f.unlink(missing_ok=True)


def _compile_via_system_dir(espeak_exe, sys_data, local_dictsource, local_data_dir):
    """Compile dictionary by copying files to the system eSpeak-NG directory.

    eSpeak-NG 1.52 on Windows ignores --path for --compile, always reading
    from its compiled-in system path. This method works WITH that behavior:
    1. Backup system phoneme files (phondata, phonindex, phontab)
    2. Copy our compiled phonemes + voice + dictsource to system dir
    3. Run espeak-ng --compile=azo (finds everything at expected system path)
    4. Copy resulting azo_dict to our local data directory
    5. Restore original system phoneme files and clean up

    Requires write access to system dir — tries directly first, then admin.
    """
    sys_dictsource = sys_data / "dictsource"
    phoneme_files = ["phondata", "phonindex", "phontab", "intonations"]

    # Build the admin batch script that does everything atomically:
    # backup → copy → compile → copy-back → restore
    bat_lines = ['@echo off']

    # Backup system phoneme files
    for fname in phoneme_files:
        sys_f = sys_data / fname
        bak_f = sys_data / f"{fname}.azo_bak"
        bat_lines.append(f'if exist "{sys_f}" copy /Y "{sys_f}" "{bak_f}" >nul')

    # Copy our compiled phoneme files to system dir
    for fname in phoneme_files:
        local_f = local_data_dir / fname
        sys_f = sys_data / fname
        bat_lines.append(f'if exist "{local_f}" copy /Y "{local_f}" "{sys_f}" >nul')

    # Copy voice file
    sys_voices = sys_data / "voices" / "nic"
    sys_lang = sys_data / "lang" / "nic"
    voice_src = ESPEAK_DIR / "voices" / "nic" / "azo"
    bat_lines.append(f'mkdir "{sys_voices}" 2>nul')
    bat_lines.append(f'mkdir "{sys_lang}" 2>nul')
    bat_lines.append(f'copy /Y "{voice_src}" "{sys_voices / "azo"}" >nul')
    bat_lines.append(f'copy /Y "{voice_src}" "{sys_lang / "azo"}" >nul')

    # Copy dictsource files
    bat_lines.append(f'mkdir "{sys_dictsource}" 2>nul')
    bat_lines.append(f'copy /Y "{local_dictsource / "azo_rules"}" "{sys_dictsource / "azo_rules"}" >nul')
    bat_lines.append(f'copy /Y "{local_dictsource / "azo_list"}" "{sys_dictsource / "azo_list"}" >nul')

    # Compile
    bat_lines.append(f'"{espeak_exe}" --compile=azo')

    # Copy azo_dict to our local dir
    bat_lines.append(f'copy /Y "{sys_data / "azo_dict"}" "{local_data_dir / "azo_dict"}" >nul 2>nul')

    # Restore original phoneme files
    for fname in phoneme_files:
        sys_f = sys_data / fname
        bak_f = sys_data / f"{fname}.azo_bak"
        bat_lines.append(f'if exist "{bak_f}" copy /Y "{bak_f}" "{sys_f}" >nul')
        bat_lines.append(f'if exist "{bak_f}" del /Q "{bak_f}" 2>nul')

    # Clean up voice + dictsource + dict
    bat_lines.append(f'del /Q "{sys_voices / "azo"}" 2>nul')
    bat_lines.append(f'del /Q "{sys_lang / "azo"}" 2>nul')
    bat_lines.append(f'del /Q "{sys_dictsource / "azo_rules"}" 2>nul')
    bat_lines.append(f'del /Q "{sys_dictsource / "azo_list"}" 2>nul')
    bat_lines.append(f'del /Q "{sys_data / "azo_dict"}" 2>nul')

    bat_content = "\r\n".join(bat_lines) + "\r\n"

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    bat_path = TEMP_DIR / "_admin_compile.bat"
    bat_path.write_text(bat_content, encoding="utf-8")

    print(f"  System data: {sys_data}")

    # Try without admin first (in case user has write access)
    try:
        test_file = sys_data / "_write_test.tmp"
        test_file.write_text("test")
        test_file.unlink()
        can_write = True
    except PermissionError:
        can_write = False

    if can_write:
        print("  Have write access to system dir — compiling directly...")
        result = subprocess.run(
            ["cmd", "/c", str(bat_path)],
            capture_output=True, text=True, timeout=30
        )
        local_dict = local_data_dir / "azo_dict"
        if local_dict.exists() and local_dict.stat().st_size > 0:
            print(f"  System dir: Dictionary compiled! ({local_dict.stat().st_size} bytes)")
            bat_path.unlink(missing_ok=True)
            return True
        if result.stderr:
            print(f"  stderr: {result.stderr[:500]}")

    # Need admin elevation
    print("  Need admin access to write to system directory...")
    print("  A UAC prompt will appear — please click 'Yes'.")
    try:
        ps_cmd = (
            f"Start-Process -FilePath 'cmd.exe' "
            f"-ArgumentList '/c \"{bat_path}\"' "
            f"-Verb RunAs -Wait"
        )
        subprocess.run(
            ["powershell", "-Command", ps_cmd],
            capture_output=True, text=True, timeout=60
        )

        local_dict = local_data_dir / "azo_dict"
        if local_dict.exists() and local_dict.stat().st_size > 0:
            print(f"  Admin compile: Dictionary compiled! ({local_dict.stat().st_size} bytes)")
            return True
        else:
            print("  Admin compile: azo_dict not created.")
            return False

    except subprocess.TimeoutExpired:
        print("  Admin compile: Timed out (UAC prompt may have been dismissed).")
        return False
    except Exception as e:
        print(f"  Admin compile: Error: {e}")
        return False
    finally:
        bat_path.unlink(missing_ok=True)


def compile_phonemes(espeak_exe, data_dir):
    """Compile phoneme table. Requires phsource/ as a SIBLING of espeak-ng-data/
    (downloaded from GitHub by install_language_files if missing).

    Expected directory layout:
        Awing/
        ├── espeak-ng-data/   (compiled data — data_dir)
        ├── phsource/         (phoneme sources — SIBLING of espeak-ng-data)
        │   ├── phonemes      (master file)
        │   └── ph_awing      (our custom Awing phonemes)
        └── dictsource/       (dictionary sources — SIBLING)
    """
    print("\n--- Compiling Awing phonemes ---")

    # phsource/ is a SIBLING of espeak-ng-data/, not inside it
    # eSpeak-NG resolves: espeak-ng-data/../phsource/phonemes
    if data_dir.name == "espeak-ng-data":
        work_dir = data_dir.parent
    else:
        work_dir = data_dir

    phsource = work_dir / "phsource"
    if not phsource.exists():
        print("  ERROR: phsource/ directory not found.")
        print(f"  Expected at: {phsource}")
        print("  Run 'setup' again — it will download phsource/ from GitHub.")
        return False

    # Copy our phoneme definition file
    ph_src = ESPEAK_DIR / "phsource" / "ph_awing"
    shutil.copy2(ph_src, phsource / "ph_awing")
    print(f"  Copied ph_awing to: {phsource}")

    # Check if master phonemes file exists and add our table
    master_phonemes = phsource / "phonemes"
    if not master_phonemes.exists():
        print("  ERROR: phsource/phonemes master file not found.")
        print("  Cannot register phoneme table without it.")
        return False

    content = master_phonemes.read_text(encoding="utf-8", errors="replace")
    if "phonemetable azo" not in content:
        addition = "\n\nphonemetable azo base1\ninclude ph_awing\n"
        with open(master_phonemes, "a", encoding="utf-8") as f:
            f.write(addition)
        print("  Registered phonemetable azo in master phonemes file")
    else:
        print("  Phonemetable azo already registered")

    # Compile all phonemes
    # ESPEAK_DATA_PATH points to the PARENT of espeak-ng-data/
    # --compile-phonemes looks for phsource/ at that same parent level
    env = os.environ.copy()
    env["ESPEAK_DATA_PATH"] = str(work_dir)

    print(f"  Work dir:  {work_dir}")
    print(f"  phsource:  {phsource}")
    print(f"  ESPEAK_DATA_PATH: {work_dir}")

    try:
        result = subprocess.run(
            [espeak_exe, "--compile-phonemes", f"--path={work_dir}"],
            capture_output=True, text=True, env=env,
            cwd=str(work_dir)
        )
        if result.returncode == 0:
            print("  Phonemes compiled successfully")
            return True
        else:
            print(f"  WARNING: Phoneme compilation returned code {result.returncode}")
            if result.stderr:
                print(f"  stderr: {result.stderr[:1500]}")
            if result.stdout:
                print(f"  stdout: {result.stdout[:500]}")
    except Exception as e:
        print(f"  ERROR: {e}")

    return False


def _detect_best_voice(espeak_exe, data_dir):
    """Detect the best available eSpeak-NG voice for Awing synthesis.

    Priority:
    1. 'azo' — our custom Awing voice with correct formants + tone phonemes
       (requires setup to have compiled phonemes and installed voice file)
    2. 'sw'  — Swahili (Bantu family, closer vowel inventory than English)
    3. 'en'  — English fallback (always available)

    Caches the result so we only detect once per run.
    """
    if hasattr(_detect_best_voice, "_cached"):
        return _detect_best_voice._cached

    # Build --path arg for our local data
    path_arg = []
    if data_dir and data_dir.exists():
        # --path wants the PARENT of espeak-ng-data/
        if data_dir.name == "espeak-ng-data":
            path_arg = ["--path", str(data_dir.parent)]
        else:
            path_arg = ["--path", str(data_dir)]

    for voice in ["azo", "sw", "en"]:
        try:
            cmd = [espeak_exe] + path_arg + ["-v", voice, "-q", "--phonout",
                   "-w", os.devnull, "test"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                _detect_best_voice._cached = voice
                return voice
        except Exception:
            continue

    _detect_best_voice._cached = "en"
    return "en"


# Pitch values for each Awing tone (eSpeak -p parameter, range 0-99)
# These create audible pitch contrasts that approximate Awing tonal patterns.
_TONE_PITCH = {
    "1": 82,    # High tone (á) — highest pitch
    "2": 62,    # Mid tone — middle pitch
    "3": 38,    # Low tone (unmarked) — lowest pitch
    "4": 55,    # Rising tone (ǎ) — starts lowish, we generate at mid-high
    "5": 65,    # Falling tone (â) — starts high, we generate at mid-high
}


def _syllabify_phonemes(phoneme_str):
    """Split a phoneme string into syllables with tone information.

    Each syllable is (phonemes, tone_number) where tone_number is "1"-"5"
    or "0" for untoned (consonant-only fragments).

    The phoneme string from awing_to_phonemes() has space-separated tokens.
    Tokens starting with a digit 1-5 are toned vowels (e.g., "1a", "3E:").
    Other tokens are consonants or word boundaries.
    """
    tokens = phoneme_str.split()
    syllables = []
    current_consonants = []

    for token in tokens:
        if not token:
            # Word boundary
            if current_consonants:
                syllables.append((" ".join(current_consonants), "0"))
                current_consonants = []
            syllables.append(("", "0"))  # pause
            continue

        # Check if this token starts with a tone number (1-5)
        if token and token[0] in "12345":
            tone = token[0]
            vowel_ph = token[1:]
            # Combine preceding consonants + this vowel into a syllable
            parts = current_consonants + [vowel_ph] if vowel_ph else current_consonants
            current_consonants = []
            syllables.append((" ".join(parts), tone))
        else:
            # Consonant or other — accumulate
            current_consonants.append(token)

    # Leftover consonants (e.g., final nasal)
    if current_consonants:
        syllables.append((" ".join(current_consonants), "0"))

    return syllables


def speak_text(espeak_exe, data_dir, text, output_file=None, speed=130, pitch=50):
    """Speak Awing text using eSpeak-NG with per-syllable pitch control.

    This function:
    1. Converts Awing text → phonemes via the Python phonemizer
    2. Splits phonemes into syllables with tone information
    3. Generates each syllable at the correct pitch for its tone
    4. Concatenates the syllable WAVs into one file using ffmpeg

    If ffmpeg is not available for concatenation, falls back to generating
    the whole word at a single pitch (less accurate but still works).
    """
    phonemes = awing_to_phonemes(text)
    if not phonemes.strip():
        return False

    voice = _detect_best_voice(espeak_exe, data_dir)

    # Build --path arg for our local data
    path_arg = []
    if data_dir and data_dir.exists():
        if data_dir.name == "espeak-ng-data":
            path_arg = ["--path", str(data_dir.parent)]
        else:
            path_arg = ["--path", str(data_dir)]

    # Try per-syllable pitch synthesis (tonal mode)
    if output_file:
        syllables = _syllabify_phonemes(phonemes)
        has_ffmpeg = shutil.which("ffmpeg") is not None

        # Only do per-syllable if we have multiple toned syllables and ffmpeg
        toned_count = sum(1 for _, t in syllables if t in "12345")
        if has_ffmpeg and toned_count >= 1:
            result = _generate_tonal(espeak_exe, path_arg, voice, syllables,
                                     output_file, speed)
            if result:
                return True
            # Fall through to simple mode on failure

    # Simple mode: entire phoneme string at one pitch
    phoneme_text = f"[[{phonemes}]]"
    cmd = [espeak_exe] + path_arg + ["-v", voice]
    cmd.extend(["-s", str(speed)])
    cmd.extend(["-p", str(pitch)])
    cmd.extend(["-a", "180"])

    if output_file:
        cmd.extend(["-w", str(output_file)])

    cmd.append(phoneme_text)

    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0


def _generate_tonal(espeak_exe, path_arg, voice, syllables, output_file, speed):
    """Generate audio with per-syllable pitch variation for tonal accuracy.

    Each syllable is rendered at a pitch corresponding to its Awing tone,
    then all syllables are concatenated into one seamless audio file.
    """
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    wav_parts = []
    part_idx = 0

    for phonemes, tone in syllables:
        if not phonemes:
            # Word boundary — add a tiny silence
            silence_path = TEMP_DIR / f"syl_{part_idx:03d}_silence.wav"
            try:
                subprocess.run(
                    ["ffmpeg", "-y", "-f", "lavfi", "-i",
                     "anullsrc=r=22050:cl=mono", "-t", "0.08",
                     str(silence_path)],
                    capture_output=True, text=True
                )
                if silence_path.exists() and silence_path.stat().st_size > 44:
                    wav_parts.append(silence_path)
                    part_idx += 1
            except Exception:
                pass
            continue

        # Get pitch for this tone
        syl_pitch = _TONE_PITCH.get(tone, 55)  # default mid pitch

        # For rising tone (4): generate slightly lower, rely on natural rise
        # For falling tone (5): generate slightly higher, rely on natural fall
        # (eSpeak's internal pitch envelope may add some contour within a syllable)

        syl_wav = TEMP_DIR / f"syl_{part_idx:03d}.wav"
        phoneme_text = f"[[{phonemes}]]"

        cmd = [espeak_exe] + path_arg + ["-v", voice]
        cmd.extend(["-s", str(speed)])
        cmd.extend(["-p", str(syl_pitch)])
        cmd.extend(["-a", "180"])
        cmd.extend(["-w", str(syl_wav)])
        cmd.append(phoneme_text)

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0 and syl_wav.exists() and syl_wav.stat().st_size > 44:
            wav_parts.append(syl_wav)
            part_idx += 1

    if not wav_parts:
        return False

    if len(wav_parts) == 1:
        # Only one syllable — just use it directly
        shutil.copy2(wav_parts[0], output_file)
        return output_file.exists()

    # Concatenate all syllable WAVs using ffmpeg concat filter
    list_file = TEMP_DIR / "concat_list.txt"
    with open(list_file, "w") as f:
        for wp in wav_parts:
            f.write(f"file '{wp}'\n")

    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-f", "concat", "-safe", "0",
             "-i", str(list_file), "-c:a", "pcm_s16le",
             str(output_file)],
            capture_output=True, text=True
        )
        return result.returncode == 0 and output_file.exists()
    except Exception:
        return False


def generate_audio_clip(espeak_exe, data_dir, text, output_path, speed=120):
    """Generate a single audio clip: Awing text → per-syllable WAV → MP3."""
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    wav_path = TEMP_DIR / "temp_clip.wav"

    # Generate WAV with tonal pitch variation
    if not speak_text(espeak_exe, data_dir, text, wav_path, speed=speed):
        return False

    if not wav_path.exists() or wav_path.stat().st_size < 100:
        return False

    # Convert to MP3 using ffmpeg
    output_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", str(wav_path),
             "-codec:a", "libmp3lame", "-qscale:a", "2",
             str(output_path)],
            capture_output=True, text=True
        )
        if result.returncode == 0 and output_path.exists():
            return True
    except FileNotFoundError:
        # ffmpeg not found — keep as WAV
        wav_output = output_path.with_suffix(".wav")
        shutil.copy2(wav_path, wav_output)
        print(f"  WARNING: ffmpeg not found. Saved as WAV: {wav_output.name}")
        return True

    return False


# ====================================================================
# COMMANDS
# ====================================================================

def cmd_setup(args):
    """First-time setup: find/install eSpeak-NG, install language files, compile."""
    print(f"=== Awing eSpeak-NG TTS Engine v{VERSION} — Setup ===\n")

    # Step 1: Find eSpeak-NG
    espeak_exe = find_espeak_ng()
    if not espeak_exe:
        print("ERROR: eSpeak-NG not found!")
        print("\nInstall eSpeak-NG:")
        print("  Windows:  winget install espeak-ng.espeak-ng")
        print("  Linux:    sudo apt install espeak-ng")
        print("  macOS:    brew install espeak-ng")
        print("\nOr download from: https://github.com/espeak-ng/espeak-ng/releases")
        return False

    print(f"Found eSpeak-NG: {espeak_exe}")

    # Verify it works
    try:
        result = subprocess.run([espeak_exe, "--version"], capture_output=True, text=True)
        print(f"Version: {result.stdout.strip()}")
    except Exception as e:
        print(f"WARNING: Could not get version: {e}")

    # Step 2: Find data directory
    data_dir = find_espeak_data_dir()
    if not data_dir:
        print("ERROR: eSpeak-NG data directory not found!")
        print("Set ESPEAK_DATA_PATH environment variable to the espeak-ng-data directory.")
        return False

    print(f"Data directory: {data_dir}")

    # Step 3: Install language files (may create local copy if system dir is read-only)
    # This also downloads phsource/ from GitHub if the binary install lacks it.
    data_dir = install_language_files(data_dir)

    # Step 4: Compile phonemes (not strictly required for inline phoneme mode,
    # but keeps the option open for future dictionary-based TTS)
    compile_phonemes(espeak_exe, data_dir)

    # Step 5: Test — uses Python phonemizer + inline [[ ]] phonemes + tonal pitch
    print("\n--- Testing Awing TTS (tonal pitch mode) ---")
    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    voice = _detect_best_voice(espeak_exe, data_dir)
    print(f"  Best voice: {voice}" +
          (" (custom Awing formants + tones)" if voice == "azo" else
           " (Swahili Bantu)" if voice == "sw" else " (English fallback)"))

    test_words = ["apô", "ŋgóonɛ́", "kwɨ̌tə́", "mbɛ́'tə́", "tátá", "mámá"]
    ok_count = 0
    for word in test_words:
        phonemes = awing_to_phonemes(word)
        syllables = _syllabify_phonemes(phonemes)
        syl_info = ", ".join(f"[{ph}]@p{_TONE_PITCH.get(t,'?')}" for ph, t in syllables if ph)
        wav = TEMP_DIR / f"test_awing.wav"
        if speak_text(espeak_exe, data_dir, word, wav, speed=110):
            size = wav.stat().st_size if wav.exists() else 0
            if size > 100:
                print(f"  ✓ '{word}' → {syl_info} → {size} bytes")
                ok_count += 1
            else:
                print(f"  ✗ '{word}' → {syl_info} → {size} bytes (too small)")
        else:
            print(f"  ✗ '{word}' → {syl_info} — eSpeak returned error")

    print(f"\n  {ok_count}/{len(test_words)} test words produced audio")

    print("\n=== Setup complete ===")
    print(f"\nNext steps:")
    print(f"  python {Path(__file__).name} generate      # Generate app audio clips")
    print(f"  python {Path(__file__).name} generate-all  # Generate ALL dictionary words")
    print(f"  python {Path(__file__).name} speak \"apô\"   # Speak any Awing text")
    return True


def cmd_compile(args):
    """Recompile language files after editing."""
    print(f"=== Recompiling Awing language ===\n")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    data_dir = install_language_files(data_dir)
    compile_phonemes(espeak_exe, data_dir)
    print("\n=== Recompilation complete ===")
    print("Note: Dictionary compilation skipped — using Python phonemizer instead.")
    return True


def cmd_generate(args):
    """Generate audio clips for the Flutter app (alphabet + vocabulary + sentences)."""
    print(f"=== Generating Awing audio clips ===\n")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    # Ensure language is installed (phonemizer handles the rest)
    data_dir = install_language_files(data_dir)

    voice = _detect_best_voice(espeak_exe, data_dir)
    print(f"  Using voice: {voice}" +
          (" (custom Awing)" if voice == "azo" else
           " (Swahili/Bantu)" if voice == "sw" else " (English)"))
    print(f"  Mode: per-syllable tonal pitch synthesis")

    total = 0
    success = 0
    failed = []

    # --- Alphabet sounds (slow speed for isolated sounds) ---
    print("\n--- Generating alphabet sounds ---")
    for key, text in ALPHABET_SOUNDS.items():
        total += 1
        output = ALPHABET_DIR / f"{key}.mp3"
        if generate_audio_clip(espeak_exe, data_dir, text, output, speed=90):
            success += 1
            print(f"  ✓ {key}: '{text}' → {output.name}")
        else:
            failed.append(f"alphabet/{key}")
            print(f"  ✗ {key}: '{text}' — FAILED")

    # --- Vocabulary words (moderate speed) ---
    print("\n--- Generating vocabulary sounds ---")
    for key, text in VOCABULARY_WORDS.items():
        total += 1
        output = VOCABULARY_DIR / f"{key}.mp3"
        if generate_audio_clip(espeak_exe, data_dir, text, output, speed=100):
            success += 1
            print(f"  ✓ {key}: '{text}' → {output.name}")
        else:
            failed.append(f"vocabulary/{key}")
            print(f"  ✗ {key}: '{text}' — FAILED")

    # --- Sentences (slightly faster) ---
    print("\n--- Generating sentence audio ---")
    SENTENCES_DIR.mkdir(parents=True, exist_ok=True)
    for key, text in SENTENCES.items():
        total += 1
        output = SENTENCES_DIR / f"{key}.mp3"
        if generate_audio_clip(espeak_exe, data_dir, text, output, speed=110):
            success += 1
            print(f"  ✓ {key}: '{text}' → {output.name}")
        else:
            failed.append(f"sentences/{key}")
            print(f"  ✗ {key}: '{text}' — FAILED")

    # --- Stories (normal speed) ---
    print("\n--- Generating story audio ---")
    STORIES_DIR.mkdir(parents=True, exist_ok=True)
    for key, text in STORIES.items():
        total += 1
        output = STORIES_DIR / f"{key}.mp3"
        if generate_audio_clip(espeak_exe, data_dir, text, output, speed=105):
            success += 1
            print(f"  ✓ {key}: '{text}' → {output.name}")
        else:
            failed.append(f"stories/{key}")
            print(f"  ✗ {key}: '{text}' — FAILED")

    # Summary
    print(f"\n=== Generation complete ===")
    print(f"  Total: {total} | Success: {success} | Failed: {len(failed)}")
    if failed:
        print(f"  Failed clips: {', '.join(failed[:10])}")
    return len(failed) == 0


def cmd_generate_all(args):
    """Generate audio for ALL words from the Awing-English dictionary.
    Uses OCR to extract words from the dictionary PDF."""
    print(f"=== Generating audio for ALL dictionary words ===\n")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    # First generate the standard app clips
    cmd_generate(args)

    # Check for OCR-extracted dictionary data
    dict_json = PROJECT_DIR / "training_data" / "dictionary_words.json"
    if dict_json.exists():
        print(f"\n--- Generating from dictionary data: {dict_json} ---")
        with open(dict_json, "r", encoding="utf-8") as f:
            words = json.load(f)

        all_dir = AUDIO_DIR / "dictionary"
        all_dir.mkdir(parents=True, exist_ok=True)

        total = len(words)
        success = 0
        for i, (key, text) in enumerate(words.items()):
            safe_key = re.sub(r'[^\w]', '_', key.lower())
            output = all_dir / f"{safe_key}.mp3"
            if output.exists() and not getattr(args, 'force', False):
                success += 1
                continue
            if generate_audio_clip(espeak_exe, data_dir, text, output, speed=115):
                success += 1
            if (i + 1) % 100 == 0:
                print(f"  Progress: {i+1}/{total} ({success} success)")

        print(f"\n  Dictionary words: {success}/{total} generated")
    else:
        print(f"\nNo dictionary data file found at: {dict_json}")
        print("To generate ALL dictionary words:")
        print("  1. OCR the Awing-English dictionary PDF")
        print("  2. Save as JSON: training_data/dictionary_words.json")
        print("     Format: {{\"word_key\": \"awing_text\", ...}}")
        print("\nFor now, standard app clips have been generated.")

    return True


def cmd_speak(args):
    """Speak any Awing text."""
    if not args.text:
        print("Usage: speak \"awing text here\"")
        return False

    text = " ".join(args.text)
    print(f"Speaking: {text}")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    if args.output:
        output = Path(args.output)
        if output.suffix.lower() == ".mp3":
            if generate_audio_clip(espeak_exe, data_dir, text, output):
                print(f"Saved: {output}")
                return True
        else:
            if speak_text(espeak_exe, data_dir, text, output):
                print(f"Saved: {output}")
                return True
    else:
        # Play directly (no output file)
        return speak_text(espeak_exe, data_dir, text)


def cmd_speak_file(args):
    """Convert an entire text file to audio."""
    if not args.input_file:
        print("Usage: speak-file input.txt output.wav")
        return False

    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"ERROR: File not found: {input_path}")
        return False

    text = input_path.read_text(encoding="utf-8")
    output_path = Path(args.output_file) if args.output_file else input_path.with_suffix(".wav")

    print(f"Converting: {input_path} → {output_path}")
    print(f"Text length: {len(text)} characters")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    if output_path.suffix.lower() == ".mp3":
        return generate_audio_clip(espeak_exe, data_dir, text, output_path, speed=130)
    else:
        return speak_text(espeak_exe, data_dir, text, output_path, speed=130)


def cmd_test(args):
    """Test pronunciation of sample words across all categories."""
    print(f"=== Testing Awing TTS pronunciation ===\n")

    espeak_exe = find_espeak_ng()
    data_dir = find_espeak_data_dir()

    if not espeak_exe or not data_dir:
        print("ERROR: eSpeak-NG not found. Run 'setup' first.")
        return False

    TEMP_DIR.mkdir(parents=True, exist_ok=True)

    test_cases = [
        # (category, text, description)
        ("Vowel", "a", "open front /a/"),
        ("Vowel", "ɛ", "open-mid /ɛ/"),
        ("Vowel", "ə", "schwa /ə/"),
        ("Vowel", "ɨ", "barred-i /ɨ/"),
        ("Vowel", "ɔ", "open-mid back /ɔ/"),
        ("Tone", "apô", "hand — falling tone"),
        ("Tone", "apó", "hand — high tone variant"),
        ("Tone", "ndě", "neck — rising tone"),
        ("Tone", "kó", "catch — high tone"),
        ("Cluster", "mbɛ́'tə́", "greeting — prenasalized + glottal"),
        ("Cluster", "ŋgóonɛ́", "patient — prenasalized velar"),
        ("Cluster", "ndwígtɔ́", "end — prenasalized + labialized"),
        ("Cluster", "kwɨ̌tə́", "tortoise — labialized"),
        ("Cluster", "nyì", "name — palatal nasal"),
        ("Sentence", "Ə́ mbɔ́ŋ wó?", "How are you?"),
        ("Sentence", "Mə́ mbɔ́ŋ.", "I am fine."),
        ("Long", "Mə́ fúú ə́ Awing.", "I come from Awing."),
    ]

    voice = _detect_best_voice(espeak_exe, data_dir)
    print(f"  Using voice: {voice}\n")

    success = 0
    for category, text, desc in test_cases:
        phonemes = awing_to_phonemes(text)
        syllables = _syllabify_phonemes(phonemes)
        tones = [t for _, t in syllables if t in "12345"]
        pitch_info = ",".join(str(_TONE_PITCH.get(t, "?")) for t in tones) if tones else "none"

        wav = TEMP_DIR / f"test_{success}.wav"
        ok = speak_text(espeak_exe, data_dir, text, wav, speed=110)
        size = wav.stat().st_size if wav.exists() else 0
        status = "✓" if ok and size > 100 else "✗"
        if ok and size > 100:
            success += 1
        print(f"  {status} [{category:8s}] '{text}' — {desc} (pitch:{pitch_info}, {size}b)")

    print(f"\n  Results: {success}/{len(test_cases)} passed")
    return success == len(test_cases)


def cmd_status(args):
    """Show current setup status."""
    print(f"=== Awing eSpeak-NG TTS Status ===\n")

    # eSpeak-NG executable
    espeak_exe = find_espeak_ng()
    print(f"eSpeak-NG binary: {'✓ ' + espeak_exe if espeak_exe else '✗ Not found'}")

    # Data directory
    data_dir = find_espeak_data_dir()
    print(f"Data directory:   {'✓ ' + str(data_dir) if data_dir else '✗ Not found'}")

    # Language files & voice detection
    if data_dir:
        voice_file = data_dir / "lang" / "nic" / "azo"
        print(f"Voice file:       {'✓' if voice_file.exists() else '✗'} {voice_file}")

    if espeak_exe:
        best_voice = _detect_best_voice(espeak_exe, data_dir)
        voice_desc = {"azo": "Awing (custom formants + tones)",
                      "sw": "Swahili (Bantu family)",
                      "en": "English (fallback)"}
        print(f"Active voice:     {best_voice} — {voice_desc.get(best_voice, 'unknown')}")

    # Source files
    print(f"\nSource files:")
    for f in ["voices/nic/azo", "phsource/ph_awing", "dictsource/azo_rules", "dictsource/azo_list"]:
        p = ESPEAK_DIR / f
        print(f"  {'✓' if p.exists() else '✗'} espeak/{f}")

    # Audio clips
    print(f"\nGenerated audio:")
    for name, d in [("Alphabet", ALPHABET_DIR), ("Vocabulary", VOCABULARY_DIR),
                     ("Sentences", SENTENCES_DIR), ("Stories", STORIES_DIR)]:
        if d.exists():
            mp3s = list(d.glob("*.mp3"))
            wavs = list(d.glob("*.wav"))
            print(f"  {name}: {len(mp3s)} MP3, {len(wavs)} WAV")
        else:
            print(f"  {name}: (not generated)")

    # ffmpeg
    ffmpeg = shutil.which("ffmpeg")
    print(f"\nffmpeg: {'✓ ' + ffmpeg if ffmpeg else '✗ Not found (WAV only)'}")


def cmd_list(args):
    """List all generated audio files."""
    print(f"=== Generated Audio Files ===\n")
    total = 0
    for name, d in [("Alphabet", ALPHABET_DIR), ("Vocabulary", VOCABULARY_DIR),
                     ("Sentences", SENTENCES_DIR), ("Stories", STORIES_DIR),
                     ("Dictionary", AUDIO_DIR / "dictionary")]:
        if d.exists():
            files = sorted(d.glob("*.mp3")) + sorted(d.glob("*.wav"))
            if files:
                print(f"\n{name} ({len(files)} files):")
                for f in files:
                    print(f"  {f.name} ({f.stat().st_size:,} bytes)")
                total += len(files)
    print(f"\nTotal: {total} audio files")


def cmd_clean(args):
    """Remove temporary files."""
    print("Cleaning temporary files...")
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR)
        print(f"  Removed: {TEMP_DIR}")
    print("Done.")


# ====================================================================
# MAIN
# ====================================================================

def main():
    parser = argparse.ArgumentParser(
        description=f"Awing eSpeak-NG TTS Engine v{VERSION}",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s setup                        # First-time setup
  %(prog)s compile                      # Recompile after editing language files
  %(prog)s speak "apô"                  # Speak a word
  %(prog)s speak "Mə́ mbɔ́ŋ." -o out.mp3  # Save sentence to MP3
  %(prog)s generate                     # Generate app audio clips
  %(prog)s generate-all                 # Generate ALL dictionary words
  %(prog)s speak-file story.txt -o story.mp3  # Convert text file to audio
  %(prog)s test                         # Test pronunciation
  %(prog)s status                       # Show setup status
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # setup
    subparsers.add_parser("setup", help="First-time setup: install language files + compile")

    # compile
    subparsers.add_parser("compile", help="Recompile language files")

    # speak
    speak_parser = subparsers.add_parser("speak", help="Speak Awing text")
    speak_parser.add_argument("text", nargs="*", help="Awing text to speak")
    speak_parser.add_argument("-o", "--output", help="Save to file (WAV or MP3)")

    # speak-file
    file_parser = subparsers.add_parser("speak-file", help="Convert text file to audio")
    file_parser.add_argument("input_file", help="Input text file")
    file_parser.add_argument("-o", "--output-file", help="Output audio file")

    # generate
    gen_parser = subparsers.add_parser("generate", help="Generate app audio clips")
    gen_parser.add_argument("--force", action="store_true", help="Regenerate existing clips")

    # generate-all
    genall_parser = subparsers.add_parser("generate-all", help="Generate ALL dictionary words")
    genall_parser.add_argument("--force", action="store_true", help="Regenerate existing clips")

    # test
    subparsers.add_parser("test", help="Test pronunciation of sample words")

    # status
    subparsers.add_parser("status", help="Show setup status")

    # list
    subparsers.add_parser("list", help="List generated audio files")

    # clean
    subparsers.add_parser("clean", help="Remove temporary files")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    commands = {
        "setup": cmd_setup,
        "compile": cmd_compile,
        "speak": cmd_speak,
        "speak-file": cmd_speak_file,
        "generate": cmd_generate,
        "generate-all": cmd_generate_all,
        "test": cmd_test,
        "status": cmd_status,
        "list": cmd_list,
        "clean": cmd_clean,
    }

    handler = commands.get(args.command)
    if handler:
        result = handler(args)
        sys.exit(0 if result else 1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
