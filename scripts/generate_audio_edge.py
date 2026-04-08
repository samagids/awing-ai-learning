#!/usr/bin/env python3
"""
Awing Edge TTS Audio Generator v4.0.0
======================================
Generates pronunciation audio for the Awing language using 6 original character
voices from Microsoft Edge TTS neural engine — 2 per difficulty level.

v4.0.0: Per-syllable tonal pitch synthesis — each syllable is generated at the
pitch matching its Awing tone (High, Mid, Low, Rising, Falling), then
concatenated with ffmpeg for natural-sounding tonal pronunciation.

Voice Characters:
  Beginner:  boy (child male) + girl (child female)     — slower, higher pitch
  Medium:    young_man + young_woman                     — moderate pace
  Expert:    man (adult male) + woman (adult female)     — natural pace, deeper

Uses Swahili (Bantu family) neural voices as the base — Swahili shares
prenasalized stops (mb, nd, ng), open syllable structure, and similar vowels
with Awing. Edge TTS is FREE (no API key needed).

Audio output structure:
  assets/audio/boy/         — Beginner child male
  assets/audio/girl/        — Beginner child female
  assets/audio/young_man/   — Medium young adult male
  assets/audio/young_woman/ — Medium young adult female
  assets/audio/man/         — Expert adult male
  assets/audio/woman/       — Expert adult female

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
import unicodedata
import re
from pathlib import Path

# ====================================================================
# CONFIGURATION
# ====================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent
AUDIO_DIR = PROJECT_DIR / "assets" / "audio"
TEMP_DIR = SCRIPT_DIR / "_edge_tts_temp"

VERSION = "4.0.0"

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
    Returns dict of {audio_key: awing_text} for all AwingWord entries."""
    dart_file = PROJECT_DIR / "lib" / "data" / "awing_vocabulary.dart"
    if not dart_file.exists():
        print(f"  Warning: {dart_file} not found, using built-in vocabulary")
        return None

    vocab = {}
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Match: awing: 'text' or awing: "text"
    for m in re.finditer(r"AwingWord\([^)]*awing:\s*['\"]([^'\"]+)['\"]", content):
        awing_text = m.group(1)
        key = _audio_key(awing_text)
        if key and key not in vocab:
            vocab[key] = awing_text

    return vocab if vocab else None


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


async def _generate_clip_simple(voice_name, text, output_path, rate="-20%", pitch="+0Hz"):
    """Generate a single audio clip using Edge TTS (flat pitch, no tonal variation)."""
    import edge_tts

    speakable = awing_to_speakable(text)

    try:
        communicate = edge_tts.Communicate(speakable, voice_name, rate=rate, pitch=pitch)
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        temp_mp3 = TEMP_DIR / "temp_edge.mp3"
        await communicate.save(str(temp_mp3))

        if temp_mp3.exists() and temp_mp3.stat().st_size > 500:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(temp_mp3, output_path)
            return True
    except Exception as e:
        print(f"    Error: {e}")
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


async def _generate_character_clips(char_name, char_config, vocab_override=None, phrases_override=None):
    """Generate all audio clips for one character voice."""
    voice = char_config["voice"]
    pitch = char_config["pitch"]
    rate = char_config["rate"]
    desc = char_config["description"]

    # Use Dart-loaded vocabulary if available, else fall back to built-in
    vocab = vocab_override if vocab_override else VOCABULARY_WORDS
    sentences = phrases_override if phrases_override else SENTENCES

    # Resolve actual available voice
    gender = "female" if char_name in ("girl", "young_woman", "woman") else "male"
    actual_voice = await _find_available_voice(voice, gender)
    if actual_voice != voice:
        print(f"  Note: {voice} unavailable, using {actual_voice}")

    char_dir = AUDIO_DIR / char_name
    print(f"\n{'='*50}")
    print(f"  Generating: {char_name} — {desc}")
    print(f"  Voice: {actual_voice} | Pitch: {pitch} | Rate: {rate}")
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
        # Slower rate for alphabet (isolated sounds), no tonal for single sounds
        alpha_rate = rate.replace("-15%", "-30%").replace("-25%", "-40%").replace("-35%", "-45%")
        if await _generate_clip(actual_voice, text, output, rate=alpha_rate, pitch=pitch):
            success += 1
            print(f"    ✓ {key}")
        else:
            failed.append(f"{key}")
            print(f"    ✗ {key} FAILED")

    # Vocabulary
    print(f"\n  --- Vocabulary ({len(vocab)} words) ---")
    for key, text in vocab.items():
        total += 1
        output = char_dir / "vocabulary" / f"{key}.mp3"
        if await _generate_clip(actual_voice, text, output, rate=rate, pitch=pitch):
            success += 1
            print(f"    ✓ {key}")
        else:
            failed.append(f"{key}")
            print(f"    ✗ {key} FAILED")

    # Sentences
    print(f"\n  --- Sentences ({len(sentences)} clips) ---")
    for key, text in sentences.items():
        total += 1
        output = char_dir / "sentences" / f"{key}.mp3"
        # Slightly faster for sentences
        sent_rate = rate.replace("-15%", "-10%").replace("-25%", "-15%").replace("-35%", "-20%")
        if await _generate_clip(actual_voice, text, output, rate=sent_rate, pitch=pitch):
            success += 1
            print(f"    ✓ {key}")
        else:
            failed.append(f"{key}")
            print(f"    ✗ {key} FAILED")

    # Stories
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
        print(f"Loaded {len(dart_vocab)} words from awing_vocabulary.dart")
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
                phrases_override=dart_phrases
            )
            grand_success += s
            grand_total += t

        print(f"\n{'='*50}")
        print(f"  ALL DONE: {grand_success}/{grand_total} clips across 6 voices")
        clips_per_voice = grand_total // 6
        print(f"  {clips_per_voice} clips per voice x 6 voices = {grand_total} total")
        print(f"\n  Voices saved to:")
        print(f"    assets/audio/boy/         — Beginner (child male)")
        print(f"    assets/audio/girl/        — Beginner (child female)")
        print(f"    assets/audio/young_man/   — Medium (young adult male)")
        print(f"    assets/audio/young_woman/ — Medium (young adult female)")
        print(f"    assets/audio/man/         — Expert (adult male)")
        print(f"    assets/audio/woman/       — Expert (adult female)")
        print(f"{'='*50}")
        return grand_success == grand_total

    return asyncio.run(run())


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
    parser = argparse.ArgumentParser(
        description=f"Awing Edge TTS Audio Generator v{VERSION}")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("generate", help="Generate all 6 character voices")
    sp = subparsers.add_parser("speak", help="Speak Awing text in all voices")
    sp.add_argument("text", nargs="*", help="Text to speak")
    subparsers.add_parser("test", help="Test sample pronunciations")
    subparsers.add_parser("voices", help="List voice configuration")
    subparsers.add_parser("status", help="Show status")

    args = parser.parse_args()

    commands = {
        "generate": cmd_generate,
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
