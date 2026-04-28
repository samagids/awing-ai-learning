#!/usr/bin/env python3
"""
Awing Edge TTS Audio Generator v5.1.0
======================================
Generates pronunciation audio for the Awing language using 6 original character
voices from Microsoft Edge TTS neural engine — 2 per difficulty level.

v5.1.0: awing_to_speakable() now collapses "gh" to "g". Awing "gh" = IPA /ɣ/
(voiced velar fricative), which Swahili TTS cannot synthesize. When left as
"gh" the neural voice spelled out the letters ("g-h-o" for ghǒ). Mapping to
plain "g" produces a proper syllable. Use speakable_override in
regenerate_words.json for word-specific fine-tuning.

v5.0.0: Level-filtered content — each voice only generates audio for words at
its difficulty level: beginner vocab for boy/girl, medium for young_man/woman,
expert for man/woman. Reduces total clips and ensures voices match their mode.

v4.0.0: Per-syllable tonal pitch synthesis — each syllable is generated at the
pitch matching its Awing tone (High, Mid, Low, Rising, Falling), then
concatenated with ffmpeg for natural-sounding tonal pronunciation.

Voice Characters (level-filtered):
  Beginner:  boy + girl          — alphabet + beginner vocab + sentences
  Medium:    young_man + woman   — alphabet + beginner+medium vocab + sentences
  Expert:    man + woman         — alphabet + sentences + stories (NO vocabulary)

Uses Swahili (Bantu family) neural voices as the base — Swahili shares
prenasalized stops (mb, nd, ng), open syllable structure, and similar vowels
with Awing. Edge TTS is FREE (no API key needed).

Audio output structure:
  assets/audio/boy/         — Beginner child male (beginner content only)
  assets/audio/girl/        — Beginner child female (beginner content only)
  assets/audio/young_man/   — Medium young adult male (beginner+medium content)
  assets/audio/young_woman/ — Medium young adult female (beginner+medium content)
  assets/audio/man/         — Expert adult male (all content)
  assets/audio/woman/       — Expert adult female (all content)

Usage:
    python scripts/generate_audio_edge.py generate         # Generate all voices
    python scripts/generate_audio_edge.py speak "apô"      # Speak a word (all voices)
    python scripts/generate_audio_edge.py test              # Test sample words
    python scripts/generate_audio_edge.py voices            # List available voices
    python scripts/generate_audio_edge.py status            # Show status

Requires: pip install edge-tts
          ffmpeg (for per-syllable concatenation — falls back to flat pitch without it)
"""

import os
import sys
import asyncio
import shutil
import argparse
import json
import unicodedata
import re
from pathlib import Path

# ====================================================================
# CONFIGURATION
# ====================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent
# Default audio output: PAD install-time asset pack (for Play Store size limits)
# Override with --output-dir flag
AUDIO_DIR = PROJECT_DIR / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio"
TEMP_DIR = SCRIPT_DIR / "_edge_tts_temp"

VERSION = "5.2.0"
# 5.2.0 — Removed native-recording skip logic. Developer recordings are now
#         archived by apply_contributions.py as TRAINING REFERENCES only and
#         are never played in the app. Edge TTS always generates all 6
#         character voices; when the developer supplies a pronunciationGuide
#         (or Whisper ASR text), it arrives here via regenerate_words.json
#         as a speakable_override to shape the TTS pronunciation.

# Awing tone → pitch offset (Hz relative to character's base pitch)
# High tone is distinctly higher, low is distinctly lower, mid is neutral
TONE_PITCH_OFFSETS = {
    "high":    "+30Hz",   # á — distinctly raised pitch
    "mid":     "+0Hz",    # unmarked — neutral baseline
    "low":     "-30Hz",   # à — distinctly lowered pitch
    "rising":  "+10Hz",   # ǎ — starts low, ends high (average: slightly above mid)
    "falling": "-10Hz",   # â — starts high, ends low (average: slightly below mid)
}

# Whether ffmpeg is available (checked once at startup)
_ffmpeg_available = None

def _check_ffmpeg():
    """Check if ffmpeg is available for per-syllable concatenation."""
    global _ffmpeg_available
    if _ffmpeg_available is None:
        _ffmpeg_available = shutil.which("ffmpeg") is not None
    return _ffmpeg_available


# 6 character voices — 2 per difficulty level
# Using Swahili voices (Bantu family, closest to Awing phonology)
VOICE_CHARACTERS = {
    # --- Beginner: child voices (slower, higher pitch) ---
    "boy": {
        "voice": "sw-KE-RafikiNeural",      # Swahili Kenya male
        "pitch": "+15Hz",                     # Higher pitch for child voice
        "rate": "-35%",                       # Slower for beginners
        "description": "Boy (Beginner)",
        "level": "beginner",
    },
    "girl": {
        "voice": "sw-KE-ZuriNeural",        # Swahili Kenya female
        "pitch": "+20Hz",                     # Higher pitch for child voice
        "rate": "-35%",                       # Slower for beginners
        "description": "Girl (Beginner)",
        "level": "beginner",
    },
    # --- Medium: young adult voices (moderate pace) ---
    "young_man": {
        "voice": "sw-TZ-DaudiNeural",       # Swahili Tanzania male
        "pitch": "+5Hz",                      # Slightly higher for young adult
        "rate": "-25%",                       # Moderate pace
        "description": "Young man (Medium)",
        "level": "medium",
    },
    "young_woman": {
        "voice": "sw-TZ-RehemaNeural",      # Swahili Tanzania female
        "pitch": "+10Hz",                     # Slightly higher for young adult
        "rate": "-25%",                       # Moderate pace
        "description": "Young woman (Medium)",
        "level": "medium",
    },
    # --- Expert: adult voices (natural pace, deeper) ---
    "man": {
        "voice": "sw-TZ-DaudiNeural",       # Swahili Tanzania male
        "pitch": "-5Hz",                      # Deeper adult voice
        "rate": "-15%",                       # Natural pace
        "description": "Adult man (Expert)",
        "level": "expert",
    },
    "woman": {
        "voice": "sw-TZ-RehemaNeural",      # Swahili Tanzania female
        "pitch": "+0Hz",                      # Natural adult pitch
        "rate": "-15%",                       # Natural pace
        "description": "Adult woman (Expert)",
        "level": "expert",
    },
}

# Fallback voices in case primary isn't available
FALLBACK_VOICES = {
    "male":   ["sw-KE-RafikiNeural", "sw-TZ-DaudiNeural", "zu-ZA-ThembaNeural", "en-KE-ChilembaNeural"],
    "female": ["sw-KE-ZuriNeural", "sw-TZ-RehemaNeural", "zu-ZA-ThandoNeural", "en-KE-AsiliaNeural"],
}


# ====================================================================
# AWING VOCABULARY DATA
# ====================================================================

# Alphabet sounds: each value is a phonetic spelling that a Swahili TTS voice
# will SOUND OUT as the phoneme, not read as a letter name.
# Vowels: repeated/elongated so TTS produces the actual sound.
# Consonants: consonant + "ah" to produce the phoneme sound (like "bah", "dah").
ALPHABET_SOUNDS = {
    # Vowels — elongated so TTS produces the vowel sound, not letter name
    "a": "aah",  "e": "eh",  "epsilon": "eh",  "schwa": "uh",
    "i": "eeh",  "barred_i": "ih",  "o": "ooh",  "open_o": "oh",  "u": "ooh",
    # Consonants — consonant + short "ah" vowel to produce the sound
    "b": "bah",  "ch": "chah",  "d": "dah",  "f": "fah",
    "g": "gah",  "gh": "ghah",  "j": "jah",  "k": "kah",
    "l": "lah",  "m": "mah",  "n": "nah",  "ny": "nyah",
    "eng": "ngah",  "p": "pah",  "s": "sah",  "sh": "shah",
    "t": "tah",  "ts": "tsah",  "w": "wah",  "y": "yah",
    "z": "zah",  "glottal": "ah ah",
}


def _audio_key(awing_text):
    """Convert Awing word to safe ASCII filename (matches pronunciation_service.dart _audioKey)."""
    text = unicodedata.normalize("NFC", awing_text.strip().lower())

    # Special character filename mappings (must match Dart pronunciation_service.dart)
    special_map = {
        'ɛ': 'epsilon', 'ə': 'schwa', 'ɨ': 'barred_i',
        'ɔ': 'open_o', 'ŋ': 'eng',
    }

    # Check if it's a single special character (alphabet sounds)
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

    # Replace special vowels
    replacements = [
        ('ɛ', 'e'), ('ɔ', 'o'), ('ə', 'e'), ('ɨ', 'i'), ('ŋ', 'ng'),
    ]
    for old, new in replacements:
        text = text.replace(old, new)

    # Remove apostrophes (glottal stops) and non-alphanumeric
    text = text.replace("'", "").replace("\u2019", "").replace("\u2018", "")
    text = re.sub(r'[^a-z0-9]', '', text)

    return text


def _load_vocabulary_from_dart():
    """Read vocabulary directly from awing_vocabulary.dart to stay in sync.
    Returns dict of {audio_key: (awing_text, difficulty)} for all AwingWord entries.
    difficulty: 1=beginner, 2=medium, 3=expert."""
    dart_file = PROJECT_DIR / "lib" / "data" / "awing_vocabulary.dart"
    if not dart_file.exists():
        print(f"  Warning: {dart_file} not found, using built-in vocabulary")
        return None

    vocab = {}
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Match AwingWord entries with awing text and optional difficulty
    for m in re.finditer(r"AwingWord\(([^)]*)\)", content, re.DOTALL):
        block = m.group(1)
        awing_match = re.search(r"awing:\s*['\"]([^'\"]+)['\"]", block)
        if not awing_match:
            continue
        awing_text = awing_match.group(1)
        key = _audio_key(awing_text)
        if not key or key in vocab:
            continue
        # Extract difficulty (default 1 if not specified)
        diff_match = re.search(r"difficulty:\s*(\d+)", block)
        difficulty = int(diff_match.group(1)) if diff_match else 1
        vocab[key] = (awing_text, difficulty)

    return vocab if vocab else None


def _filter_vocab_for_level(vocab, level):
    """Filter vocabulary dict to only include words at or below the given level.
    Level mapping: beginner=1, medium=2, expert=3.
    Returns dict of {audio_key: awing_text} (strips difficulty)."""
    max_diff = {"beginner": 1, "medium": 2, "expert": 3}.get(level, 3)
    return {k: v[0] for k, v in vocab.items() if v[1] <= max_diff}


def _load_phrases_from_dart():
    """Read phrases from awing_vocabulary.dart. Returns dict of {clip_key: awing_text}."""
    dart_file = PROJECT_DIR / "lib" / "data" / "awing_vocabulary.dart"
    if not dart_file.exists():
        return None

    phrases = {}
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Match AwingPhrase entries with clipKey and awing text
    for m in re.finditer(
        r"AwingPhrase\([^)]*awing:\s*['\"]([^'\"]+)['\"][^)]*clipKey:\s*['\"]([^'\"]+)['\"]",
        content, re.DOTALL
    ):
        awing_text = m.group(1)
        clip_key = m.group(2)
        phrases[clip_key] = awing_text

    return phrases if phrases else None

VOCABULARY_WORDS = {
    # Body parts (11)
    "apo": "apô",          # hand
    "atue": "atûə",        # head
    "aloeme": "alɔ́əmə",   # tongue
    "fele": "fɛlə",        # breastbone
    "nelwie": "nəlwîə",    # nose
    "nde": "ndě",           # neck
    "nkadte": "nkadtə",    # back
    "mbete": "mbe'tə",     # shoulder
    "achie": "achîə",      # blood
    "neto": "nətô",        # intestine
    "nepe": "nəpe",        # liver
    # Animals and nature (12)
    "eshue": "əshûə",      # fish
    "konge": "koŋə",       # owl
    "anyenge": "anyeŋə",   # claw
    "nenjwinne": "nənjwínnə",  # fly
    "ankoome": "ankoomə",  # ram
    "ngeo": "ngə'ɔ́",      # termite
    "noole": "nóolə",      # snake
    "atie": "atîə",        # tree
    "akoobo": "akoobɔ́",   # forest
    "ngee": "ngə'ə",       # stone
    "waako": "wâakɔ́",     # sand
    "newue": "nəwûə",      # death
    # Actions (18)
    "no": "nô",            # drink
    "lume": "lúmə",        # bite
    "mie": "mîə",          # swallow
    "pime": "pímə",        # believe
    "tsoe": "tsó'ə",       # heal
    "zoe": "zó'ə",         # hear
    "jage": "jágə",        # yawn
    "yike": "yîkə",        # harden
    "ledno": "lɛdnɔ́",     # sweat
    "pene": "pɛ́nə",       # dance
    "shie": "shîə",        # stretch
    "chato": "cha'tɔ́",    # greet
    "kwage": "kwágə",      # cough
    "lyange": "lyáŋə",     # hide
    "toge": "tɔ́gə",       # blow
    "fyaale": "fyáalə",    # chase
    "ko": "ko",            # take
    "yie": "yîə",          # come
    # Things and objects (11)
    "ajume": "ajúmə",      # thing
    "ajwike": "ajwikə",    # window
    "afue": "afûə",        # leaf/medicine
    "nese": "nəse",        # grave
    "mbeene": "mbéenə",    # nail
    "ndzo": "ndzǒ",        # beans
    "nepoo": "nəpɔ'ɔ́",   # pumpkin
    "fwoe": "fwɔ'ə",      # chisel
    "shwaa": "shwa'a",     # razor
    "ekwuno": "əkwunɔ́",   # bed
    "ndue": "nduə",        # hammer
    # Family and people (7)
    "ma": "mǎ",            # mother
    "ye": "yə",            # he/she
    "apeele": "apɛ̌ɛlə",   # mad person
    "efego": "əfəgɔ́",     # blind person
    "alae": "alá'ə",       # village
    "ngye": "ngye",         # voice
    "ayange": "ayáŋə",     # wisdom
    # Food and daily life (8)
    "apeeme": "apeemə",    # bag
    "apeene": "apéenə",    # flour
    "negoomo": "nəgoomɔ́", # plantain
    "ngwange": "ngwáŋə",   # salt
    "mandzo": "mândzǒ",    # groundnuts
    "akwe": "akwe",         # response
    "metwe": "mətwé",      # saliva
    "nekengo": "nəkəŋɔ́",  # pot
    # House and home (7) - items already in other sections, shared keys
    "ntumke": "ntúmkə",       # entrance hut
    "nechwele": "nəchwélə",   # hearth
    "waare": "wâarə",         # slaughter
    # Numbers (10)
    "emo": "əmɔ́",             # one
    "epa": "əpá",              # two
    "ele": "əlɛ́",             # three
    "ekwa": "əkwá",            # four
    "etaane": "ətáanə",        # five
    "ntuu": "ntúu",            # six
    "tsombi": "tsɔ̂mbí",       # seven
    "neng": "nɛ̂ŋ",            # eight
    "ebwa": "əbwá",            # nine
    "egham": "əghám",          # ten
    # More actions (14)
    "toeme": "tɔ́əmə",        # choke
    "tume": "túmə",            # send
    "kangto": "kaŋtɔ́",        # stumble
    "sedno": "sɛdnɔ́",        # turn round
    "lenge": "léŋə",          # lick
    "nyaglo": "nyaglɔ́",      # tickle
    "ngae": "ŋá'ə",           # open
    "neo": "ne'ɔ́",            # limp
    "nonge": "nɔ́ŋə",         # suck
    "fe": "fê",                # give
    "fine": "fínə",            # sell
    "pwone": "pwɔ́nə",        # appease
    # More things (10)
    "atsange": "atsáŋə",      # punishment
    "azago": "azagɔ́",         # odour
    "mbeeno": "mbéenɔ́",      # abscess
    "ntsoole": "ntsoolə",     # war
    "ngwaglo": "ŋwáglɔ́",     # bell
    "eleele": "əlɛɛlə",       # bridge/beard
    "nepeene": "nəpéenə",     # crown of head
    "ndzoeme": "ndzoəmə",     # dream
    "negho": "nəghǒ",         # grinding stone
    "eghaa": "əghâa",         # season
}

SENTENCES = {
    # Greetings (from conversation dialogues)
    "greeting_chatoo": "Cha'tɔ́!",
    "greeting_chatoo_yiiee": "Cha'tɔ́! Yə yîə?",
    "greeting_kwae": "Yə kwa'ə.",
    "greeting_maa_kwate": "Ndèe, mǎ wə nə mə kwátə.",
    # Daily phrases (from dialogues and PDF)
    "daily_market": "A kə ghɛnɔ́ mətéenɔ́.",
    "daily_pumpkin": "Lɛ̌ nəpɔ'ɔ́.",
    "daily_plantain": "Ko akwe pə nəgoomɔ́.",
    "daily_its_there": "Wo'! Ee wə nə fɛ́ə.",
    "daily_sit_down": "Ee wə nə mə fɛ́ə. Ko pə asé.",
    # Questions (from dialogues)
    "question_what_thing": "Ache fɛ́ə ndo?",
    "question_what_want": "Ache kə?",
    "question_is_good": "Ee wə nə kó?",
    # Farewells (from dialogues)
    "farewell_going": "Tifwə nə pə zə wǎ lɛ́ə.",
    "farewell_come_back": "Akwe! Wə yîə ndèe.",
    "farewell_goodbye": "Ee! Cha'tɔ́ ndèe!",
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
    """Convert Awing text to speakable text for a Bantu TTS voice."""
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

    # Awing "gh" = IPA /ɣ/ (voiced velar fricative). Earlier versions
    # collapsed gh→g to stop Swahili TTS from spelling "g-h-o" for ghǒ,
    # but the Session 56 Phase-2 rule-mining audit (197-word corpus,
    # Dr. Sama's verdicts) showed preserve_gh is the single safe
    # pattern rule (+2 score: helps ghanə/ghǒ, hurts 0 good
    # pronunciations). Preserve gh here; handle any residual
    # letter-spelling via per-word speakable_override entries in
    # regenerate_words.json.

    text = re.sub(r'\s+', ' ', text).strip()
    return text


# ====================================================================
# TONAL SYLLABIFICATION
# ====================================================================

# Awing vowels (base characters, without diacritics)
_AWING_VOWELS = set("aeiouɛɔəɨAEIOUƐƆƏƖ")

# Tone-bearing combining marks (Unicode NFD)
_TONE_MARKS = {
    '\u0301': 'high',     # combining acute accent  (á)
    '\u0300': 'low',      # combining grave accent   (à)
    '\u0302': 'falling',  # combining circumflex     (â)
    '\u030C': 'rising',   # combining caron           (ǎ)
}

# Consonant clusters that should not be split
_ONSET_CLUSTERS = [
    # Prenasalized (longest first)
    'mb', 'nd', 'nj', 'nk', 'ng', 'nt', 'nz', 'ns',
    'ŋg', 'ŋk',
    # Palatalized
    'ty', 'ky', 'py', 'by', 'dy', 'gy', 'ny', 'sy', 'zy',
    # Labialized
    'tw', 'kw', 'pw', 'bw', 'dw', 'gw', 'nw', 'sw', 'zw',
    # Digraphs
    'gh', 'sh', 'ch', 'ts',
]


def _extract_tone(char):
    """Extract tone from a single character (may have combining diacritics).
    Returns (base_char, tone_name)."""
    nfd = unicodedata.normalize("NFD", char)
    base = ""
    tone = "mid"  # default: unmarked = mid tone
    for c in nfd:
        if c in _TONE_MARKS:
            tone = _TONE_MARKS[c]
        else:
            base += c
    return unicodedata.normalize("NFC", base), tone


def _split_graphemes(text):
    """Split text into grapheme clusters (base char + combining marks).
    Returns list of strings, each being one visual character."""
    text = unicodedata.normalize("NFC", text)
    graphemes = []
    current = ""
    for ch in text:
        cat = unicodedata.category(ch)
        if cat.startswith("M"):  # Combining mark — attach to previous
            current += ch
        else:
            if current:
                graphemes.append(current)
            current = ch
    if current:
        graphemes.append(current)
    return graphemes


def _syllabify_awing(text):
    """Split Awing text into syllables with tone information.

    Returns list of (syllable_text, tone_name) tuples.

    Awing syllable structure: (C)(C)V(V)(C)
    - Every syllable has exactly one vowel nucleus
    - Consonant clusters belong to the onset of the following syllable
    - Tone is carried by the vowel

    Example: "apô" → [("a", "mid"), ("pô", "falling")]
             "ŋgóonɛ́" → [("ŋgóo", "high"), ("nɛ́", "high")]
    """
    text = unicodedata.normalize("NFC", text.strip())
    if not text:
        return []

    # Split into grapheme clusters first (base char + combining marks)
    graphemes = _split_graphemes(text)

    # Build list of (grapheme, is_vowel, tone) for each grapheme cluster
    chars = []
    i = 0
    while i < len(graphemes):
        g = graphemes[i]
        base, tone = _extract_tone(g)
        base_lower = base.lower()

        # Check for multi-grapheme clusters/digraphs
        found_cluster = False
        if base_lower not in _AWING_VOWELS:
            for cluster in sorted(_ONSET_CLUSTERS, key=len, reverse=True):
                # Count how many graphemes we need to form this cluster
                cluster_graphemes = []
                cluster_base = ""
                j = i
                while j < len(graphemes) and len(cluster_base) < len(cluster):
                    gb, _ = _extract_tone(graphemes[j])
                    cluster_base += gb
                    cluster_graphemes.append(graphemes[j])
                    j += 1
                if cluster_base.lower() == cluster:
                    chars.append(("".join(cluster_graphemes), False, "mid"))
                    i = j
                    found_cluster = True
                    break

        if not found_cluster:
            is_v = base_lower in _AWING_VOWELS
            chars.append((g, is_v, tone if is_v else "mid"))
            i += 1

    # Now group into syllables using grapheme-aware tracking.
    # Each element in `chars` is a (grapheme_text, is_vowel, tone) tuple.
    # We track `current_items` as a list of these tuples to avoid splitting
    # combining marks from their base characters.
    syllables = []
    current_items = []  # list of (grapheme_text, is_vowel, tone)
    current_tone = "mid"

    def _has_vowel(items):
        return any(iv for _, iv, _ in items)

    def _items_to_text(items):
        return "".join(g for g, _, _ in items)

    def _split_at_last_vowel(items):
        """Split items into (before+vowel, consonants_after).
        Returns (syllable_items, onset_items)."""
        # Walk backwards to find last vowel
        j = len(items) - 1
        while j >= 0:
            if items[j][1]:  # is_vowel
                break
            j -= 1
        if j < len(items) - 1:
            # Consonants after the last vowel → onset of next syllable
            return items[:j+1], items[j+1:]
        return items, []

    for ch, is_v, tone in chars:
        if is_v:
            # Check if this vowel continues the current syllable
            if _has_vowel(current_items):
                # Only check long vowel/diphthong if previous item is a vowel (adjacent)
                prev_is_vowel = current_items[-1][1] if current_items else False

                if prev_is_vowel:
                    last_vowel_base, _ = _extract_tone(current_items[-1][0])
                    this_base, _ = _extract_tone(ch)

                    # Long vowel: same base repeated (aa, oo, ee, etc.)
                    if last_vowel_base.lower() == this_base.lower():
                        current_items.append((ch, is_v, tone))
                        if tone != "mid":
                            current_tone = tone
                        continue

                    # Diphthong: vowel sequences iə, ɨə, uə (keep in same syllable)
                    if this_base.lower() in ('ə',) and \
                       last_vowel_base.lower() in ('i', 'ɨ', 'u'):
                        current_items.append((ch, is_v, tone))
                        if tone != "mid":
                            current_tone = tone
                        continue

                # New vowel = new syllable — split consonants after last vowel as onset
                syl_items, onset_items = _split_at_last_vowel(current_items)
                syllables.append((_items_to_text(syl_items), current_tone))
                current_items = onset_items + [(ch, is_v, tone)]
                current_tone = tone if tone != "mid" else "mid"
            else:
                # No vowel yet — just add to current
                current_items.append((ch, is_v, tone))
                if tone != "mid":
                    current_tone = tone
        else:
            # Consonant — add to current
            current_items.append((ch, is_v, tone))

    if current_items:
        syllables.append((_items_to_text(current_items), current_tone))

    # Filter out empty syllables and syllables with only spaces/punctuation
    syllables = [(s, t) for s, t in syllables if s.strip()]

    return syllables


def _get_pitch_for_tone(tone, base_pitch_str):
    """Calculate absolute pitch string for a tone, relative to character's base pitch.

    base_pitch_str: e.g. "+15Hz", "-5Hz", "+0Hz"
    tone: "high", "mid", "low", "rising", "falling"

    Returns: pitch string like "+45Hz" or "-35Hz"
    """
    # Parse base pitch
    base = int(base_pitch_str.replace("Hz", "").replace("+", ""))

    # Parse tone offset
    offset_str = TONE_PITCH_OFFSETS.get(tone, "+0Hz")
    offset = int(offset_str.replace("Hz", "").replace("+", ""))

    total = base + offset
    sign = "+" if total >= 0 else ""
    return f"{sign}{total}Hz"


# ====================================================================
# EDGE TTS ENGINE
# ====================================================================

async def _check_voice_available(voice_name):
    """Check if a specific voice is available."""
    try:
        import edge_tts
        voices = await edge_tts.list_voices()
        available = {v["ShortName"] for v in voices}
        return voice_name in available
    except Exception:
        return False


async def _find_available_voice(preferred, gender="male"):
    """Find the best available voice, starting with preferred."""
    import edge_tts
    try:
        voices = await edge_tts.list_voices()
        available = {v["ShortName"] for v in voices}
    except Exception:
        return preferred  # Hope for the best

    if preferred in available:
        return preferred

    # Try fallbacks
    fallbacks = FALLBACK_VOICES.get(gender, FALLBACK_VOICES["male"])
    for fb in fallbacks:
        if fb in available:
            return fb

    return preferred


async def _edge_tts_save_with_retry(text, voice_name, rate, pitch, temp_path,
                                     max_attempts=3):
    """Call edge_tts.Communicate + save with retry on transient errors.

    Microsoft's Edge TTS endpoint regularly returns transient WebSocket 503s
    ("Invalid response status") due to rate limiting and backend jitter.
    These are not bugs in our code — they're public-API noise. A single
    retry with backoff recovers nearly all of them.

    Backoff schedule: 2s, 5s, 10s between attempts. Three attempts total.
    Returns True iff the final saved file is >500 bytes. On per-attempt
    failure, only the first retry is logged to avoid spamming the batch
    output; the final exception (if all attempts fail) is printed.
    """
    import edge_tts
    delays = [2.0, 5.0, 10.0]  # seconds — used between attempts

    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    last_error = None

    for attempt in range(max_attempts):
        try:
            if temp_path.exists():
                try:
                    temp_path.unlink()
                except Exception:
                    pass
            communicate = edge_tts.Communicate(
                text, voice_name, rate=rate, pitch=pitch)
            await communicate.save(str(temp_path))
            if temp_path.exists() and temp_path.stat().st_size > 500:
                return True
            last_error = "empty output"
        except Exception as e:
            last_error = str(e)

        if attempt < max_attempts - 1:
            delay = delays[attempt]
            if attempt == 0:
                # Only log on first retry so a flaky network doesn't spam
                print(f"    [retry] Edge TTS jitter, waiting {delay}s...")
            await asyncio.sleep(delay)

    print(f"    Error: {last_error}")
    return False


async def _generate_clip_simple(voice_name, text, output_path, rate="-20%", pitch="+0Hz"):
    """Generate a single audio clip using Edge TTS (flat pitch, no tonal variation)."""
    speakable = awing_to_speakable(text)
    temp_mp3 = TEMP_DIR / "temp_edge.mp3"

    if await _edge_tts_save_with_retry(speakable, voice_name, rate, pitch, temp_mp3):
        output_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(temp_mp3, output_path)
        return True
    return False


async def _generate_clip_tonal(voice_name, text, output_path, rate="-20%", pitch="+0Hz"):
    """Generate a tonal audio clip with Awing tone-aware pitch.

    Strategy (v4.1 — whole-word generation with dominant tone pitch):
    - Syllabify the word to detect tones
    - Pick the DOMINANT tone (first non-mid tone, or first syllable's tone)
    - Generate the WHOLE word at that tone's pitch (preserves natural flow)
    - This avoids the "a-------po" problem of per-syllable generation
      where Edge TTS adds padding around each isolated syllable

    For words where all syllables share the same tone, we use that tone.
    For mixed-tone words, we use the first syllable's tone (which sets the
    word's initial pitch register — most important for perception).
    """
    syllables = _syllabify_awing(text)

    if not syllables:
        return await _generate_clip_simple(voice_name, text, output_path, rate=rate, pitch=pitch)

    # Determine dominant tone for the whole word
    tones = [t for _, t in syllables]
    unique_tones = set(tones)

    if len(unique_tones) == 1:
        # All same tone — use it directly
        dominant_tone = unique_tones.pop()
    else:
        # Mixed tones — use the first non-mid tone (most perceptually important)
        dominant_tone = "mid"
        for t in tones:
            if t != "mid":
                dominant_tone = t
                break

    word_pitch = _get_pitch_for_tone(dominant_tone, pitch)
    return await _generate_clip_simple(voice_name, text, output_path, rate=rate, pitch=word_pitch)


async def _generate_clip(voice_name, text, output_path, rate="-20%", pitch="+0Hz", tonal=True):
    """Generate an audio clip — always uses simple flat-pitch generation.

    Note: Tonal per-syllable synthesis was tried (v4.0) and whole-word dominant
    tone (v4.1) but both degraded quality. The Swahili neural voice already
    produces natural-sounding Bantu prosody without pitch manipulation.
    """
    return await _generate_clip_simple(voice_name, text, output_path, rate=rate, pitch=pitch)


async def _generate_character_clips(char_name, char_config, vocab_override=None,
                                    phrases_override=None):
    """Generate audio clips for one character voice.

    Each voice only generates content for its difficulty level:
      - Beginner (boy/girl):              alphabet + vocabulary(diff=1) + sentences/phrases
      - Medium (young_man/young_woman):   alphabet + vocabulary(diff≤2) + sentences/phrases
      - Expert (man/woman):               alphabet + sentences/phrases + stories (NO vocabulary)
    """
    voice = char_config["voice"]
    pitch = char_config["pitch"]
    rate = char_config["rate"]
    desc = char_config["description"]
    level = char_config["level"]

    # Filter vocabulary by difficulty level for this voice
    if vocab_override:
        vocab = _filter_vocab_for_level(vocab_override, level)
    else:
        # Built-in fallback has no difficulty info — use all for all voices
        vocab = VOCABULARY_WORDS

    # Sentences: Medium + Expert only
    # Phrases: Beginner only (greetings, daily phrases)
    sentences = phrases_override if phrases_override else SENTENCES

    # Resolve actual available voice
    gender = "female" if char_name in ("girl", "young_woman", "woman") else "male"
    actual_voice = await _find_available_voice(voice, gender)
    if actual_voice != voice:
        print(f"  Note: {voice} unavailable, using {actual_voice}")

    char_dir = AUDIO_DIR / char_name
    print(f"\n{'='*50}")
    print(f"  Generating: {char_name} — {desc} (level={level})")
    print(f"  Voice: {actual_voice} | Pitch: {pitch} | Rate: {rate}")
    print(f"  Output: {char_dir}")
    print(f"{'='*50}")

    total = 0
    success = 0
    failed = []

    # Alphabet — all levels (used as reference across all modules)
    print(f"\n  --- Alphabet ({len(ALPHABET_SOUNDS)} sounds) ---")
    for key, text in ALPHABET_SOUNDS.items():
        total += 1
        output = char_dir / "alphabet" / f"{key}.mp3"
        # Slower rate for alphabet (isolated sounds), no tonal for single sounds
        alpha_rate = rate.replace("-15%", "-30%").replace("-25%", "-40%").replace("-35%", "-45%")
        if await _generate_clip(actual_voice, text, output, rate=alpha_rate, pitch=pitch):
            success += 1
            print(f"    ✓ {key}")
        else:
            failed.append(f"{key}")
            print(f"    ✗ {key} FAILED")

    # Vocabulary — filtered by level (beginner=1 only, medium=1+2, expert=NONE)
    if level == "expert":
        print(f"\n  --- Vocabulary: SKIPPED (expert mode has no vocabulary) ---")
    else:
        print(f"\n  --- Vocabulary ({len(vocab)} words for {level}) ---")
        for key, text in vocab.items():
            total += 1
            output = char_dir / "vocabulary" / f"{key}.mp3"
            if await _generate_clip(actual_voice, text, output, rate=rate, pitch=pitch):
                success += 1
                print(f"    ✓ {key}")
            else:
                failed.append(f"{key}")
                print(f"    ✗ {key} FAILED")

    # Sentences/Phrases — all levels (beginner uses phrases, medium/expert use sentences)
    print(f"\n  --- Sentences ({len(sentences)} clips) ---")
    for key, text in sentences.items():
        total += 1
        output = char_dir / "sentences" / f"{key}.mp3"
        sent_rate = rate.replace("-15%", "-10%").replace("-25%", "-15%").replace("-35%", "-20%")
        if await _generate_clip(actual_voice, text, output, rate=sent_rate, pitch=pitch):
            success += 1
            print(f"    ✓ {key}")
        else:
            failed.append(f"{key}")
            print(f"    ✗ {key} FAILED")

    # Stories — Expert only (advanced reading comprehension)
    if level == "expert":
        print(f"\n  --- Stories ({len(STORIES)} clips) ---")
        for key, text in STORIES.items():
            total += 1
            output = char_dir / "stories" / f"{key}.mp3"
            story_rate = rate.replace("-15%", "-10%").replace("-25%", "-15%").replace("-35%", "-20%")
            if await _generate_clip(actual_voice, text, output, rate=story_rate, pitch=pitch):
                success += 1
                print(f"    ✓ {key}")
            else:
                failed.append(f"{key}")
                print(f"    ✗ {key} FAILED")
    else:
        print(f"\n  --- Stories: SKIPPED (not in {level} level) ---")

    print(f"\n  {char_name}: {success}/{total} clips generated")
    if failed:
        print(f"  Failed: {', '.join(failed[:10])}")
    return success, total


# ====================================================================
# COMMANDS
# ====================================================================

def cmd_generate(args):
    """Generate all audio clips for all 6 character voices."""
    print(f"=== Awing Edge TTS Generator v{VERSION} ===")
    print(f"Generating 6 character voices: boy, girl, young_man, young_woman, man, woman")
    if _check_ffmpeg():
        print(f"Tonal mode: ON — per-syllable pitch variation for Awing tones")
    else:
        print(f"Tonal mode: OFF — ffmpeg not found, using flat pitch")
    print()

    try:
        import edge_tts
    except ImportError:
        print("ERROR: edge-tts not installed.")
        print("  Install: pip install edge-tts")
        return False

    # Load vocabulary from Dart files (auto-sync with app data)
    dart_vocab = _load_vocabulary_from_dart()
    dart_phrases = _load_phrases_from_dart()
    if dart_vocab:
        total_words = len(dart_vocab)
        beg_words = len(_filter_vocab_for_level(dart_vocab, "beginner"))
        med_words = len(_filter_vocab_for_level(dart_vocab, "medium"))
        exp_words = len(_filter_vocab_for_level(dart_vocab, "expert"))
        print(f"Loaded {total_words} words from awing_vocabulary.dart")
        print(f"  Beginner: {beg_words} words | Medium: {med_words} words | Expert: {exp_words} words")
    else:
        print(f"Using built-in vocabulary ({len(VOCABULARY_WORDS)} words)")
    if dart_phrases:
        print(f"Loaded {len(dart_phrases)} phrases from awing_vocabulary.dart")

    async def run():
        grand_total = 0
        grand_success = 0

        for char_name, char_config in VOICE_CHARACTERS.items():
            s, t = await _generate_character_clips(
                char_name, char_config,
                vocab_override=dart_vocab,
                phrases_override=dart_phrases,
            )
            grand_success += s
            grand_total += t

        print(f"\n{'='*50}")
        print(f"  ALL DONE: {grand_success}/{grand_total} clips across 6 voices")
        print(f"\n  Voices (level-filtered content):")
        print(f"    boy/girl         — Beginner: alphabet + beginner vocab + sentences")
        print(f"    young_man/woman  — Medium:   alphabet + beginner+medium vocab + sentences")
        print(f"    man/woman        — Expert:   alphabet + all vocab + sentences + stories")
        print(f"{'='*50}")
        # Edge TTS hits Microsoft's public endpoint, which occasionally
        # times out on individual words due to API jitter. A handful of
        # failures out of thousands of clips is normal and must NOT fail
        # the release build — losing 3 clips out of 4366 (0.07%) would
        # otherwise abort the APK build. Tolerate up to 1% failure OR 10
        # missing clips, whichever is higher. Only fail the build if
        # generation was catastrophically broken (zero clips generated,
        # network down, missing deps).
        failed = grand_total - grand_success
        if grand_total == 0:
            print("  ✗ FAIL: no clips generated at all — check edge-tts install / network")
            return False
        tolerance = max(10, int(grand_total * 0.01))
        if failed > tolerance:
            print(f"  ✗ FAIL: {failed} clips failed (tolerance: {tolerance}, >1%)")
            return False
        if failed > 0:
            print(f"  ✓ Accepted: {failed} clips failed, within tolerance ({tolerance})")
        return True

    return asyncio.run(run())


def cmd_regenerate(args):
    """Force-regenerate specific words from a regeneration list JSON file.

    Used by the pronunciation fix pipeline: when a developer approves a
    pronunciation contribution, apply_contributions.py writes a
    regenerate_words.json file listing words that need new audio.

    For each word, this deletes existing audio across ALL voice directories
    that would contain it (based on difficulty level), then regenerates
    using Edge TTS character voices. If a speakable_override is provided,
    it's used instead of the default awing_to_speakable() conversion.

    The developer's raw recording is NOT used — Edge TTS regenerates the
    word in all 6 character voices with the corrected pronunciation mapping.
    """
    regen_file = args.regenerate_file
    if not regen_file:
        # Default path
        regen_file = str(PROJECT_DIR / "contributions" / "regenerate_words.json")

    regen_path = Path(regen_file)
    if not regen_path.exists():
        print(f"No regeneration file found at: {regen_path}")
        print("Nothing to regenerate.")
        return True

    try:
        with open(regen_path, 'r', encoding='utf-8') as f:
            words = json.load(f)
    except Exception as e:
        print(f"Error reading regeneration file: {e}")
        return False

    if not words:
        print("Regeneration file is empty. Nothing to do.")
        return True

    print(f"=== Regenerating {len(words)} word(s) across 6 voices ===")

    try:
        import edge_tts
    except ImportError:
        print("ERROR: edge-tts not installed. Run: pip install edge-tts")
        return False

    # Build speakable override map: audio_key → speakable text
    speakable_overrides = {}
    word_entries = []
    for w in words:
        awing = w.get('awing', '')
        if not awing:
            continue
        key = _audio_key(awing)
        override = w.get('speakable_override', '')
        if override:
            speakable_overrides[key] = override
            print(f"  {awing} (key={key}) → speakable override: '{override}'")
        else:
            print(f"  {awing} (key={key}) → default pronunciation")
        word_entries.append((key, awing))

    if not word_entries:
        print("No valid words to regenerate.")
        return True

    async def run():
        grand_success = 0
        grand_total = 0

        for char_name, char_config in VOICE_CHARACTERS.items():
            voice = char_config["voice"]
            pitch = char_config["pitch"]
            rate = char_config["rate"]
            level = char_config["level"]

            gender = "female" if char_name in ("girl", "young_woman", "woman") else "male"
            actual_voice = await _find_available_voice(voice, gender)

            char_dir = AUDIO_DIR / char_name
            print(f"\n  --- {char_name} ({char_config['description']}) ---")

            for key, awing_text in word_entries:
                # Delete existing clip in vocabulary directory
                vocab_clip = char_dir / "vocabulary" / f"{key}.mp3"
                if vocab_clip.exists():
                    vocab_clip.unlink()
                    print(f"    Deleted: {vocab_clip}")

                # Also check alphabet directory (for letter sounds)
                alpha_clip = char_dir / "alphabet" / f"{key}.mp3"
                if alpha_clip.exists():
                    alpha_clip.unlink()
                    print(f"    Deleted: {alpha_clip}")

                # Expert voices skip vocabulary — only regenerate alphabet/sentences
                if level == "expert":
                    output = alpha_clip if alpha_clip.parent.exists() else None
                    # Only regenerate if it was an alphabet clip
                    if not (char_dir / "alphabet").exists():
                        print(f"    Skipped {key} (expert voice, no vocab)")
                        continue
                else:
                    output = vocab_clip

                # Use speakable override if provided, otherwise default
                if key in speakable_overrides:
                    # Generate with the override text directly (already speakable)
                    text_to_speak = speakable_overrides[key]
                    grand_total += 1
                    temp_mp3 = TEMP_DIR / "temp_regen.mp3"
                    if await _edge_tts_save_with_retry(
                            text_to_speak, actual_voice, rate, pitch, temp_mp3):
                        output.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(temp_mp3, output)
                        grand_success += 1
                        print(f"    ✓ {key} (override: '{text_to_speak}')")
                    else:
                        print(f"    ✗ {key} FAILED")
                else:
                    # Use default awing_to_speakable() conversion
                    grand_total += 1
                    if await _generate_clip(actual_voice, awing_text, output,
                                           rate=rate, pitch=pitch):
                        grand_success += 1
                        print(f"    ✓ {key}")
                    else:
                        print(f"    ✗ {key} FAILED")

        print(f"\n{'='*50}")
        print(f"  Regenerated: {grand_success}/{grand_total} clips across 6 voices")
        print(f"{'='*50}")
        # Same Edge TTS jitter tolerance as cmd_generate — a couple of
        # timed-out clips in a batch of pronunciation fixes shouldn't
        # abort the build and block an entire release. Regenerate is
        # stricter than generate because these are explicit developer-
        # approved corrections that the user expects to ship: tolerate
        # up to 1% failure OR 3 clips, whichever is higher.
        failed = grand_total - grand_success
        if grand_total == 0:
            print("  (no clips to regenerate — nothing to do)")
            return True
        tolerance = max(3, int(grand_total * 0.01))
        if failed > tolerance:
            print(f"  ✗ FAIL: {failed} clips failed (tolerance: {tolerance})")
            return False
        if failed > 0:
            print(f"  ✓ Accepted: {failed} clips failed, within tolerance ({tolerance})")
        return True

    success = asyncio.run(run())

    # Clean up the regeneration file after processing
    if success:
        try:
            regen_path.unlink()
            print(f"\n✓ Removed processed regeneration file: {regen_path}")
        except Exception:
            pass

    return success


def cmd_speak(args):
    """Speak a word in all 6 voices for comparison."""
    if not args.text:
        print("Usage: speak \"awing text\"")
        return False

    try:
        import edge_tts
    except ImportError:
        print("ERROR: edge-tts not installed. Run: pip install edge-tts")
        return False

    text = " ".join(args.text)
    speakable = awing_to_speakable(text)
    syllables = _syllabify_awing(text)

    async def run():
        print(f"  Awing:     {text}")
        print(f"  Speakable: {speakable}")
        print(f"  Syllables: {' | '.join(f'{s}({t})' for s, t in syllables)}")
        print(f"  Tonal:     {'YES (ffmpeg found)' if _check_ffmpeg() else 'NO (ffmpeg not found)'}\n")

        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        for char_name, cfg in VOICE_CHARACTERS.items():
            output = TEMP_DIR / f"speak_{char_name}.mp3"
            actual = await _find_available_voice(
                cfg["voice"],
                "female" if char_name in ("girl", "young_woman", "woman") else "male"
            )
            ok = await _generate_clip(actual, text, output, rate=cfg["rate"], pitch=cfg["pitch"])
            size = output.stat().st_size if output.exists() else 0
            status = "✓" if ok else "✗"
            print(f"  {status} {char_name:6s} ({cfg['description']:30s}) → {size}b")
            if ok and sys.platform == "win32":
                os.startfile(str(output))
                await asyncio.sleep(2)
        return True

    return asyncio.run(run())


def cmd_test(args):
    """Test with sample words across all voices."""
    print(f"=== Testing Awing Edge TTS ===\n")

    try:
        import edge_tts
    except ImportError:
        print("ERROR: edge-tts not installed. Run: pip install edge-tts")
        return False

    test_words = [
        ("apô", "hand"), ("tátá", "father"), ("mámá", "mother"),
        ("ŋgóonɛ́", "patient"), ("mbɛ́'tə́", "greeting"),
        ("kwɨ̌tə́", "tortoise"), ("ndě", "neck"),
        ("nəlɔ́gə", "eye"), ("sáambaŋə", "lion"),
    ]

    async def run():
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        print(f"  Testing {len(test_words)} words x 6 voices = {len(test_words)*6} clips\n")

        # Show syllabification for each word
        print("  Syllable analysis:")
        for text, desc in test_words:
            syls = _syllabify_awing(text)
            syl_str = " | ".join(f"{s}({t})" for s, t in syls)
            print(f"    {text:15s} ({desc:10s}) → {syl_str}")
        print()

        for char_name, cfg in VOICE_CHARACTERS.items():
            actual = await _find_available_voice(
                cfg["voice"],
                "female" if char_name in ("girl", "young_woman", "woman") else "male"
            )
            ok_count = 0
            for text, desc in test_words:
                output = TEMP_DIR / f"test_{char_name}_{desc}.mp3"
                ok = await _generate_clip(actual, text, output, rate=cfg["rate"], pitch=cfg["pitch"])
                if ok:
                    ok_count += 1

            print(f"  {char_name:6s}: {ok_count}/{len(test_words)} OK "
                  f"(voice: {actual}, pitch: {cfg['pitch']})")

        return True

    return asyncio.run(run())


def cmd_voices(args):
    """List available voices."""
    print(f"=== Edge TTS Voice Configuration ===\n")

    print("  Character voices for Awing AI Learning:\n")
    for name, cfg in VOICE_CHARACTERS.items():
        print(f"    {name:6s}  {cfg['voice']:30s}  pitch:{cfg['pitch']:6s}  rate:{cfg['rate']:5s}  ({cfg['description']})")

    try:
        import edge_tts
    except ImportError:
        print("\n  edge-tts not installed — cannot check availability")
        return True

    async def run():
        voices = await edge_tts.list_voices()
        available = {v["ShortName"] for v in voices}

        print(f"\n  Voice availability:")
        for name, cfg in VOICE_CHARACTERS.items():
            status = "✓" if cfg["voice"] in available else "✗ (will use fallback)"
            print(f"    {name:6s}  {cfg['voice']:30s}  {status}")

        # Show all Swahili/Zulu voices
        print(f"\n  All Bantu voices available:")
        for v in sorted(voices, key=lambda x: x["ShortName"]):
            if v["Locale"][:2] in ("sw", "zu"):
                print(f"    {v['ShortName']:35s}  {v.get('Gender',''):8s}  {v['Locale']}")

        return True

    return asyncio.run(run())


def cmd_status(args):
    """Show current status."""
    print(f"=== Awing Edge TTS Status v{VERSION} ===\n")

    try:
        import edge_tts
        print(f"  edge-tts: ✓ installed")
    except ImportError:
        print(f"  edge-tts: ✗ not installed (pip install edge-tts)")
        return False

    print(f"  ffmpeg:   {'✓ available — tonal mode ON' if _check_ffmpeg() else '✗ not found — tonal mode OFF'}")
    print(f"  Tone pitches: High={TONE_PITCH_OFFSETS['high']}, Mid={TONE_PITCH_OFFSETS['mid']}, "
          f"Low={TONE_PITCH_OFFSETS['low']}, Rising={TONE_PITCH_OFFSETS['rising']}, "
          f"Falling={TONE_PITCH_OFFSETS['falling']}")

    print(f"\n  Generated audio clips:")
    grand_total = 0
    for name in VOICE_CHARACTERS:
        char_dir = AUDIO_DIR / name
        if char_dir.exists():
            clips = list(char_dir.rglob("*.mp3"))
            total_size = sum(f.stat().st_size for f in clips)
            print(f"    {name:6s}: {len(clips):3d} clips ({total_size // 1024:5d} KB)")
            grand_total += len(clips)
        else:
            print(f"    {name:6s}:   0 clips (not generated yet)")

    print(f"    {'TOTAL':6s}: {grand_total:3d} clips")
    return True


# ====================================================================
# MAIN
# ====================================================================

def main():
    global AUDIO_DIR
    parser = argparse.ArgumentParser(
        description=f"Awing Edge TTS Audio Generator v{VERSION}")
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Override audio output directory")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("generate", help="Generate all 6 character voices")
    regen_sp = subparsers.add_parser("regenerate",
        help="Force-regenerate specific words from a JSON file (pronunciation fix pipeline)")
    regen_sp.add_argument("--regenerate-file", type=str, default=None,
        help="Path to regenerate_words.json (default: contributions/regenerate_words.json)")
    sp = subparsers.add_parser("speak", help="Speak Awing text in all voices")
    sp.add_argument("text", nargs="*", help="Text to speak")
    subparsers.add_parser("test", help="Test sample pronunciations")
    subparsers.add_parser("voices", help="List voice configuration")
    subparsers.add_parser("status", help="Show status")

    args = parser.parse_args()

    # Override output directory if specified
    if args.output_dir:
        AUDIO_DIR = Path(args.output_dir)

    commands = {
        "generate": cmd_generate,
        "regenerate": cmd_regenerate,
        "speak": cmd_speak,
        "test": cmd_test,
        "voices": cmd_voices,
        "status": cmd_status,
    }

    if args.command in commands:
        success = commands[args.command](args)
        sys.exit(0 if success else 1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
