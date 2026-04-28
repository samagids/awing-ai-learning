#!/usr/bin/env python3
"""
Merge dictionary extraction (3,094 entries from Claude vision PDF read of
Awing English Dictionary, 2007) into lib/data/awing_vocabulary.dart.

Replaces the existing OCR-extracted `dictionaryEntries` block (Session 29,
PyMuPDF) with a clean, deduplicated, categorized version.

Dedup strategy:
  - Normalize headwords to lowercase + strip tone diacritics (NFD)
  - Skip new entries whose normalized headword already exists in any
    curated category list (pronouns, timeWords, bodyParts, animalsNature,
    foodDrink, actions, thingsObjects, familyPeople, numbers, moreActions,
    moreThings, descriptiveWords, advancedVocabulary)
  - Within the new set, keep only first occurrence per normalized headword
    (subsequent homonyms are skipped — the dictionary already disambiguates
    them in the english field).

Categorization: keyword-match on english definition + part-of-speech.
Difficulty: 1=common kid words, 2=intermediate, 3=ideo./rare/abstract.
"""
import json
import os
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXTRACT_DIR = ROOT / "contributions" / "dictionary_extract"
DART_FILE = ROOT / "lib" / "data" / "awing_vocabulary.dart"

# ---------------------------------------------------------------------------
# Step 1: Load all extracted JSON entries
# ---------------------------------------------------------------------------

def load_extracted_entries():
    """Load all 18 JSON files. Handle both legacy list and dict formats."""
    files = sorted(os.listdir(EXTRACT_DIR))
    entries = []
    for f in files:
        path = EXTRACT_DIR / f
        with open(path, encoding="utf-8") as fp:
            data = json.load(fp)
        if isinstance(data, list):
            for e in data:
                # legacy uses 'pos' field
                entries.append({
                    "awing": (e.get("awing") or "").strip(),
                    "english": (e.get("english") or "").strip(),
                    "pos": (e.get("pos") or "").strip().rstrip("."),
                    "noun_class": (e.get("noun_class") or "").strip(),
                    "phonetic": "",
                    "note": "",
                    "source_file": f,
                })
        else:
            for e in data.get("entries", []):
                # dict format uses 'class' field
                entries.append({
                    "awing": (e.get("awing") or "").strip(),
                    "english": (e.get("english") or "").strip(),
                    "pos": (e.get("class") or "").strip().rstrip("."),
                    "noun_class": "",
                    "phonetic": (e.get("phonetic") or "").strip(),
                    "note": (e.get("note") or "").strip(),
                    "source_file": f,
                })
    return entries


# ---------------------------------------------------------------------------
# Step 2: Normalize for dedup — strip tone diacritics + lowercase
# ---------------------------------------------------------------------------

# Combining marks used for Awing tones
TONE_MARKS = "".join([
    "\u0301",  # acute (high tone)
    "\u0300",  # grave (low tone)
    "\u0302",  # circumflex (falling tone)
    "\u030C",  # caron (rising tone)
    "\u0304",  # macron (mid tone — sometimes shown)
    "\u0303",  # tilde
    "\u0307",  # dot above
    "\u0308",  # diaeresis
])

def normalize_headword(s):
    """Lowercase, strip tone diacritics, drop trailing whitespace.

    Keeps base characters including ɛ, ɔ, ə, ɨ, ŋ, ' (glottal stop).
    """
    if not s:
        return ""
    # NFD decomposes accented chars into base + combining marks
    decomposed = unicodedata.normalize("NFD", s)
    # Remove tone combining marks
    stripped = "".join(c for c in decomposed if c not in TONE_MARKS)
    # Re-compose to NFC for safety
    recomposed = unicodedata.normalize("NFC", stripped)
    return recomposed.lower().strip()


# ---------------------------------------------------------------------------
# Step 3: Load existing AwingWord entries from the .dart file
# ---------------------------------------------------------------------------

# Match `AwingWord(awing: '...', ...)` — we only need the awing field.
# Awing strings may contain backslash-escaped quotes via \'
_AWING_PATTERN = re.compile(
    r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*)'",
    re.MULTILINE,
)

def load_existing_headwords(dart_text):
    """Extract all `awing:` headwords from existing AwingWord literals."""
    return _AWING_PATTERN.findall(dart_text)


# ---------------------------------------------------------------------------
# Step 4: Categorize entries based on English + part of speech
# ---------------------------------------------------------------------------

# Keyword sets — order matters: more specific first.
BODY_KEYWORDS = {
    # external
    "eye", "eyes", "ear", "ears", "nose", "mouth", "tooth", "teeth", "tongue",
    "lip", "lips", "cheek", "chin", "jaw", "head", "hair", "neck", "shoulder",
    "back", "chest", "breast", "stomach", "belly", "navel", "waist", "hip",
    "buttock", "leg", "knee", "thigh", "calf", "ankle", "foot", "feet", "toe",
    "toes", "heel", "arm", "elbow", "wrist", "hand", "hands", "finger",
    "fingers", "thumb", "palm", "nail", "skin", "face", "forehead", "eyebrow",
    "eyelash", "eyelid", "throat", "armpit", "rib",
    # internal
    "bone", "bones", "blood", "heart", "lung", "liver", "kidney", "brain",
    "vein", "muscle", "nerve", "tendon", "intestine", "spleen",
    # body fluids/products (also in advanced)
    "saliva", "tear", "tears", "sweat", "spit",
    # body actions involving body parts
}

ANIMAL_KEYWORDS = {
    "dog", "cat", "cow", "goat", "sheep", "pig", "chicken", "rooster", "hen",
    "bird", "fish", "snake", "lion", "elephant", "monkey", "rat", "mouse",
    "horse", "donkey", "antelope", "rabbit", "buffalo", "frog", "toad",
    "lizard", "snail", "crab", "shrimp", "crocodile", "turtle", "tortoise",
    "spider", "ant", "bee", "wasp", "fly", "butterfly", "mosquito", "louse",
    "lice", "tick", "worm", "insect", "beetle", "centipede", "scorpion",
    "leopard", "hippo", "hippopotamus", "giraffe", "rhino", "rhinoceros",
    "squirrel", "bat", "duck", "goose", "owl", "eagle", "hawk", "parrot",
    "porcupine", "warthog", "gorilla", "chimpanzee", "kingfisher", "vulture",
    "ram", "calf", "lamb", "kid", "kitten", "puppy", "bull", "ewe", "sow",
    "boar", "drake", "stallion", "mare", "kitten", "cub", "fawn",
    "hyena", "fox", "wolf", "deer", "zebra", "ostrich",
    "locust", "grasshopper", "cricket", "cockroach", "termite", "earthworm",
}

NATURE_KEYWORDS = {
    "tree", "trees", "leaf", "leaves", "flower", "grass", "plant", "branch",
    "root", "fruit", "seed", "bark", "thorn", "vine",
    "sky", "sun", "moon", "star", "stars", "cloud", "rain", "wind",
    "thunder", "lightning", "storm", "rainbow", "fog", "mist",
    "river", "stream", "lake", "sea", "ocean", "waterfall", "spring",
    "well", "pond", "pool",
    "mountain", "hill", "valley", "rock", "stone", "earth", "soil",
    "ground", "sand", "mud", "dust", "ashes", "fire", "smoke",
    "morning", "evening", "night", "noon", "afternoon", "dawn", "dusk",
    "day", "week", "month", "year", "season", "shadow", "darkness",
    "moonlight", "sunlight", "sunshine",
    "road", "path", "way", "bridge", "field", "farm", "forest", "bush",
    "village", "town", "country",
}

FOOD_KEYWORDS = {
    "food", "meal", "meat", "soup", "stew", "porridge", "rice", "bread",
    "yam", "cocoyam", "cassava", "corn", "maize", "millet", "sorghum",
    "banana", "plantain", "potato", "sweet potato", "groundnut", "peanut",
    "egg", "milk", "honey", "salt", "sugar", "pepper", "oil", "wine",
    "beer", "tea", "coffee", "juice", "water (drink)",
    "fruit", "vegetable", "tomato", "onion", "garlic", "ginger", "pepper",
    "orange", "lemon", "mango", "pawpaw", "papaya", "pineapple", "guava",
    "avocado", "coconut", "grape", "apple", "watermelon", "cabbage",
    "okra", "carrot", "spinach", "beans", "bean", "peas", "pea",
    "fufu", "achu", "ndole", "kwacoco", "puff puff",
    "bamboo wine", "palm wine", "raffia wine",
    "drink", "beverage",
    "cane", "sugar cane",
}

FAMILY_KEYWORDS = {
    "father", "mother", "brother", "sister", "son", "daughter", "child",
    "children", "baby", "infant", "boy", "girl", "man", "woman", "person",
    "people", "elder", "elders", "old man", "old woman", "young man",
    "young woman", "youth", "adult", "uncle", "aunt", "cousin", "nephew",
    "niece", "grandfather", "grandmother", "grandson", "granddaughter",
    "grandchild", "grandparent", "husband", "wife", "spouse", "fiancé",
    "fiancée", "in-law", "father-in-law", "mother-in-law", "brother-in-law",
    "sister-in-law", "son-in-law", "daughter-in-law",
    "friend", "neighbor", "neighbour", "stranger", "guest", "visitor",
    "chief", "king", "queen", "prince", "princess", "ruler", "leader",
    "owner", "servant", "slave", "master", "follower", "disciple",
    "teacher", "student", "pupil", "doctor", "nurse", "farmer", "hunter",
    "fisherman", "blacksmith", "carpenter", "weaver", "potter", "mason",
    "trader", "seller", "buyer", "messenger", "soldier", "warrior",
    "priest", "pastor", "prophet", "witch", "wizard", "thief", "robber",
    "butcher", "smith",
    "family", "clan", "tribe", "lineage", "ancestor",
}

ACTION_VERBS_HINTS = {
    "to ", "be ", "make ", "do ", "go ", "come ", "give ", "take ", "see ",
    "hear ", "speak ", "say ", "tell ", "ask ", "answer ", "call ", "shout ",
    "whisper ", "sing ", "dance ", "run ", "walk ", "jump ", "climb ", "fall ",
    "stand ", "sit ", "lie ", "sleep ", "wake ", "eat ", "drink ", "chew ",
    "swallow ", "spit ", "vomit ", "wash ", "bathe ", "clean ", "cook ",
    "boil ", "fry ", "roast ", "bake ", "grind ", "pound ", "beat ", "hit ",
    "kick ", "push ", "pull ", "carry ", "lift ", "drop ", "throw ", "catch ",
    "hold ", "grab ", "release ", "open ", "close ", "lock ", "unlock ",
    "build ", "break ", "destroy ", "fix ", "mend ", "tie ", "untie ", "cut ",
    "tear ", "rip ", "burn ", "extinguish ", "light ", "blow ", "wipe ",
    "rub ", "scratch ", "tickle ", "kiss ", "hug ", "embrace ", "love ",
    "hate ", "like ", "dislike ", "want ", "need ", "have ", "lack ",
    "possess ", "own ", "buy ", "sell ", "trade ", "borrow ", "lend ",
    "pay ", "spend ", "save ", "give ", "receive ", "send ", "bring ",
    "fetch ", "find ", "lose ", "search ", "hide ", "reveal ", "show ",
    "look ", "watch ", "stare ", "glance ", "blink ", "wink ", "smile ",
    "laugh ", "cry ", "weep ", "scream ", "moan ", "groan ", "sigh ",
    "yawn ", "sneeze ", "cough ", "snore ", "breathe ", "die ", "live ",
    "kill ", "wound ", "heal ", "cure ", "save ", "rescue ", "help ",
    "harm ", "hurt ", "bite ", "sting ", "scratch ", "lick ", "smell ",
    "taste ", "feel ", "touch ", "pinch ", "squeeze ", "press ", "pour ",
    "spill ", "fill ", "empty ", "measure ", "count ", "calculate ",
    "read ", "write ", "draw ", "paint ", "play ", "work ", "rest ",
    "study ", "learn ", "teach ", "remember ", "forget ", "think ",
    "know ", "understand ", "believe ", "doubt ", "trust ", "fear ",
    "hope ", "wait ", "watch ", "guard ", "protect ", "attack ", "defend ",
    "fight ", "argue ", "agree ", "disagree ", "promise ", "swear ",
    "curse ", "bless ", "forgive ", "apologize ", "thank ", "greet ",
    "welcome ", "invite ", "marry ", "divorce ", "give birth ", "born ",
    "raise ", "grow ", "plant ", "harvest ", "reap ", "sow ", "weed ",
    "fish ", "hunt ", "trap ",
}

DESCRIPTIVE_HINTS = {
    "big", "small", "large", "tiny", "huge", "great", "long", "short",
    "tall", "high", "low", "wide", "narrow", "thick", "thin", "fat",
    "lean", "heavy", "light", "fast", "quick", "slow", "old", "new",
    "young", "fresh", "stale", "ripe", "unripe", "raw", "cooked", "hot",
    "cold", "warm", "cool", "wet", "dry", "soft", "hard", "smooth",
    "rough", "sharp", "blunt", "dull", "bright", "dim", "loud", "quiet",
    "silent", "noisy", "good", "bad", "kind", "cruel", "evil", "wicked",
    "honest", "dishonest", "true", "false", "right", "wrong", "correct",
    "incorrect", "clean", "dirty", "neat", "untidy", "beautiful", "ugly",
    "pretty", "handsome", "rich", "poor", "wealthy", "needy", "happy",
    "sad", "angry", "calm", "afraid", "brave", "shy", "bold", "wise",
    "foolish", "clever", "smart", "stupid", "lazy", "diligent", "strong",
    "weak", "healthy", "sick", "ill", "alive", "dead", "full", "empty",
    "open", "closed", "near", "far", "early", "late", "first", "last",
    "many", "few", "much", "little", "all", "some", "any", "none",
    "every", "each", "other", "same", "different", "similar", "alike",
    "alone", "together", "alone", "white", "black", "red", "blue",
    "green", "yellow", "brown", "grey", "gray", "orange", "purple",
    "pink", "round", "square", "flat", "straight", "crooked", "bent",
    "curved", "broken", "whole", "complete", "partial",
}

NUMBER_KEYWORDS = {
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen", "twenty", "thirty", "forty", "fifty",
    "sixty", "seventy", "eighty", "ninety", "hundred", "thousand", "million",
    "first", "second", "third", "fourth", "fifth", "half", "double", "triple",
}

# Words that, when found in the english field, indicate the entry refers
# to a household/general thing (not body, not animal, not action)
THING_KEYWORDS = {
    "house", "hut", "room", "wall", "roof", "door", "window", "floor",
    "ceiling", "table", "chair", "bed", "stool", "mat", "blanket", "pillow",
    "lamp", "candle", "torch", "fire (cooking)", "stove", "pot", "pan",
    "plate", "bowl", "cup", "spoon", "knife", "fork", "basket", "bag",
    "box", "bucket", "calabash", "jar", "bottle", "rope", "cord", "string",
    "thread", "needle", "scissors", "hammer", "axe", "machete", "hoe",
    "spear", "arrow", "bow", "gun", "trap", "net", "fishing rod",
    "drum", "flute", "horn", "bell", "instrument",
    "clothes", "shirt", "trousers", "skirt", "dress", "hat", "cap",
    "shoe", "shoes", "sandal", "belt", "bracelet", "necklace", "ring",
    "earring", "comb", "brush",
    "money", "coin", "note", "book", "paper", "pen", "pencil",
    "letter", "newspaper",
    "car", "bicycle", "motorcycle", "lorry", "bus", "boat", "canoe",
    "ship",
    "school", "church", "market", "shop", "store", "hospital", "office",
    "prison", "jail", "court", "bank", "post office", "place", "compound",
    "yard",
    "thing", "object", "stuff", "matter", "load", "burden", "tool",
    "weapon", "instrument",
}


def normalize_pos(pos):
    """Normalize part-of-speech tag from either format."""
    p = pos.lower().strip().rstrip(".").strip()
    # Common normalizations
    if p.startswith("n"):
        return "n"
    if p.startswith("v"):
        return "v"
    if p.startswith("adj"):
        return "adj"
    if p.startswith("adv"):
        return "adv"
    if p.startswith("ideo"):
        return "ideo"
    if p.startswith("num"):
        return "num"
    if p.startswith("prn") or p == "pronoun":
        return "prn"
    if p.startswith("prep"):
        return "prep"
    if p.startswith("conj"):
        return "conj"
    if p.startswith("excl") or p.startswith("inter"):
        return "excl"
    if p.startswith("dem"):
        return "dem"
    return p or ""


def categorize(entry):
    """Return one of: body, animals, nature, food, family, actions,
    descriptive, things, numbers."""
    eng_full = entry["english"].lower()
    eng_first = re.split(r"[.,;:(]", eng_full, 1)[0].strip()
    pos = normalize_pos(entry["pos"])

    # First: numbers
    if pos == "num":
        return "numbers"
    for kw in NUMBER_KEYWORDS:
        if re.fullmatch(rf"\W*{kw}\W*", eng_first):
            return "numbers"

    # Body parts
    body_words = set(re.findall(r"\b\w+\b", eng_first))
    if body_words & BODY_KEYWORDS:
        return "body"

    # Animals (often nouns)
    if pos == "n":
        animal_words = set(re.findall(r"\b\w+\b", eng_first))
        if animal_words & ANIMAL_KEYWORDS:
            return "animals"

    # Food
    food_words = set(re.findall(r"\b\w+\b", eng_first))
    if food_words & FOOD_KEYWORDS:
        return "food"

    # Family / people
    if pos in ("n", ""):
        family_words = set(re.findall(r"\b\w+\b", eng_first))
        if family_words & FAMILY_KEYWORDS:
            return "family"

    # Nature (broader than animals — sky, river, tree, time-of-day)
    nature_words = set(re.findall(r"\b\w+\b", eng_first))
    if nature_words & NATURE_KEYWORDS:
        return "nature"

    # Actions — verbs
    if pos == "v":
        return "actions"
    # Sometimes verbs are tagged as "" but english starts with "to ..."
    if eng_first.startswith("to ") or eng_first.startswith("be "):
        return "actions"

    # Descriptive — adjectives
    if pos == "adj":
        return "descriptive"
    descr_words = set(re.findall(r"\b\w+\b", eng_first))
    if descr_words & DESCRIPTIVE_HINTS:
        return "descriptive"

    # Things — common nouns (default for nouns)
    if pos == "n":
        return "things"
    thing_words = set(re.findall(r"\b\w+\b", eng_first))
    if thing_words & THING_KEYWORDS:
        return "things"

    # Default: things (catch-all for unclassified)
    return "things"


# ---------------------------------------------------------------------------
# Step 5: Difficulty assignment
# ---------------------------------------------------------------------------

def assign_difficulty(entry, category):
    """1=common kid words, 2=intermediate, 3=rare/abstract."""
    pos = normalize_pos(entry["pos"])
    eng = entry["english"].lower()
    note = entry.get("note", "").lower()

    # ideo. (ideophones — Awing-specific sound words) → expert
    if pos == "ideo":
        return 3
    # tns/asp/foc markers, particles → expert (grammatical)
    if pos in ("conj", "prep") or any(x in entry["pos"].lower() for x in
                                       ["mk", "asp", "foc", "tns", "part"]):
        return 3
    # Rare / archaic / colloquial / vulgar markers
    if any(x in eng for x in ["archaic", "vulgar", "obscene", "rude",
                               "insult", "curse", "taboo", "sex", "genital"]):
        return 3
    # Compound nouns (n.p) and phrasal verbs (v.p) → medium
    raw_pos = entry["pos"].lower().strip().rstrip(".")
    if raw_pos in ("n.p", "v.p", "adj.p", "adv.p", "c.n"):
        return 2
    # Multiple-word english (description-y) → medium
    word_count = len(re.findall(r"\b\w+\b", eng))
    if word_count > 6:
        return 2
    # Common single-word English (one or two words) → beginner
    if word_count <= 2 and pos in ("n", "v", "adj"):
        return 1
    # Pronouns/numbers → beginner
    if pos in ("prn", "num"):
        return 1
    # Default
    return 2


# ---------------------------------------------------------------------------
# Step 6: Tone pattern detection from awing diacritics
# ---------------------------------------------------------------------------

def detect_tone(awing):
    """Detect the dominant tone pattern from diacritics."""
    if not awing:
        return None
    decomposed = unicodedata.normalize("NFD", awing)
    tones = set()
    for c in decomposed:
        if c == "\u0301":
            tones.add("high")
        elif c == "\u0300":
            tones.add("low")
        elif c == "\u0302":
            tones.add("falling")
        elif c == "\u030C":
            tones.add("rising")
    # Priority: rising > falling > high > low > None
    for t in ("rising", "falling", "high", "low"):
        if t in tones:
            return t
    return None


# ---------------------------------------------------------------------------
# Step 7: Dart literal escaping
# ---------------------------------------------------------------------------

def dart_escape(s):
    """Escape a string for safe inclusion in single-quoted Dart literal."""
    if s is None:
        return ""
    # Replace backslashes first, then single quotes
    s = s.replace("\\", "\\\\").replace("'", "\\'")
    # Strip newlines and tabs
    s = s.replace("\n", " ").replace("\r", " ").replace("\t", " ")
    # Collapse runs of whitespace
    s = re.sub(r"\s+", " ", s).strip()
    return s


def make_awing_word(entry, category, difficulty, tone):
    """Build a Dart `AwingWord(...)` literal."""
    parts = [
        f"awing: '{dart_escape(entry['awing'])}'",
        f"english: '{dart_escape(entry['english'])}'",
        f"category: '{category}'",
    ]
    if tone:
        parts.append(f"tonePattern: '{tone}'")
    if difficulty != 1:
        parts.append(f"difficulty: {difficulty}")
    return "AwingWord(" + ", ".join(parts) + ")"


# ---------------------------------------------------------------------------
# Step 8: Validation — skip junk entries
# ---------------------------------------------------------------------------

def is_valid_entry(entry):
    """Reject obviously broken / non-Awing-word entries."""
    awing = entry.get("awing", "").strip()
    english = entry.get("english", "").strip()
    if not awing or not english:
        return False
    # Awing headwords are short — anything over 30 chars is likely junk
    if len(awing) > 35:
        return False
    # Reject if awing field looks like English prose
    if awing.count(" ") > 4:
        return False
    # Reject pure-ASCII dictionary headwords with no Awing characters AND
    # that look like an English sentence (5+ ASCII words). Compound Awing
    # phrases use only basic letters but are usually short.
    return True


# ---------------------------------------------------------------------------
# Main merge logic
# ---------------------------------------------------------------------------

def main():
    print("=" * 70)
    print("Merging dictionary extraction into awing_vocabulary.dart")
    print("=" * 70)

    # ------------------------------------------------------------------
    # Load existing Dart file
    # ------------------------------------------------------------------
    print(f"\n[1/6] Reading {DART_FILE.relative_to(ROOT)}...")
    with open(DART_FILE, encoding="utf-8") as fp:
        dart_text = fp.read()

    # ------------------------------------------------------------------
    # Locate the existing dictionaryEntries block (REPLACE target)
    # ------------------------------------------------------------------
    block_start_pat = re.compile(
        r"// =+\n// DICTIONARY ENTRIES.*?\n// =+\n"
        r"const List<AwingWord> dictionaryEntries = \[",
        re.DOTALL,
    )
    m_start = block_start_pat.search(dart_text)
    if not m_start:
        print("ERROR: Could not find existing dictionaryEntries block start")
        sys.exit(1)
    # Find the closing `];` after the start
    block_close = dart_text.find("];", m_start.end())
    if block_close == -1:
        print("ERROR: Could not find closing `];` of dictionaryEntries")
        sys.exit(1)
    block_close += 2  # include the `];`
    print(f"      Found existing block: chars {m_start.start()}–{block_close}")

    # ------------------------------------------------------------------
    # Extract existing curated headwords (everything OUTSIDE the block)
    # ------------------------------------------------------------------
    outside_text = dart_text[:m_start.start()] + dart_text[block_close:]
    curated_headwords = load_existing_headwords(outside_text)
    curated_set = {normalize_headword(h) for h in curated_headwords}
    # Drop empty
    curated_set.discard("")
    print(f"[2/6] {len(curated_headwords)} curated headwords found "
          f"({len(curated_set)} unique normalized)")

    # ------------------------------------------------------------------
    # Load all extracted entries
    # ------------------------------------------------------------------
    print("\n[3/6] Loading extracted entries...")
    entries = load_extracted_entries()
    print(f"      Loaded {len(entries)} raw entries")

    # ------------------------------------------------------------------
    # Validate, dedup against curated, dedup within new set
    # ------------------------------------------------------------------
    print("\n[4/6] Validating and deduplicating...")
    seen = set()
    new_entries = []
    skipped_invalid = 0
    skipped_curated_dup = 0
    skipped_internal_dup = 0
    for e in entries:
        if not is_valid_entry(e):
            skipped_invalid += 1
            continue
        norm = normalize_headword(e["awing"])
        if not norm:
            skipped_invalid += 1
            continue
        if norm in curated_set:
            skipped_curated_dup += 1
            continue
        if norm in seen:
            skipped_internal_dup += 1
            continue
        seen.add(norm)
        new_entries.append(e)
    print(f"      Invalid (empty/junk): {skipped_invalid}")
    print(f"      Already in curated lists: {skipped_curated_dup}")
    print(f"      Internal duplicates (homonyms): {skipped_internal_dup}")
    print(f"      Net new entries: {len(new_entries)}")

    # ------------------------------------------------------------------
    # Categorize, assign difficulty, build Dart literals
    # ------------------------------------------------------------------
    print("\n[5/6] Categorizing and building Dart literals...")
    by_category = {}
    cat_counts = Counter()
    diff_counts = Counter()
    for e in new_entries:
        cat = categorize(e)
        diff = assign_difficulty(e, cat)
        tone = detect_tone(e["awing"])
        literal = make_awing_word(e, cat, diff, tone)
        by_category.setdefault(cat, []).append(literal)
        cat_counts[cat] += 1
        diff_counts[diff] += 1

    print("      Category distribution:")
    for cat, n in cat_counts.most_common():
        print(f"        {cat:15} {n}")
    print("      Difficulty distribution:")
    for d in sorted(diff_counts):
        print(f"        diff={d}  {diff_counts[d]}")

    # ------------------------------------------------------------------
    # Assemble new dictionaryEntries block
    # ------------------------------------------------------------------
    print("\n[6/6] Assembling new dictionaryEntries block...")
    cat_order = ["body", "family", "animals", "nature", "food", "actions",
                 "descriptive", "things", "numbers"]
    # Append any unexpected categories
    for c in sorted(by_category):
        if c not in cat_order:
            cat_order.append(c)

    lines = [
        "// ============================================================",
        "// DICTIONARY ENTRIES — extracted from Awing English Dictionary",
        "// (Alomofor Christian, CABTAL, 2007) via Claude vision PDF read",
        f"// Total: {len(new_entries)} additional entries",
        "// ============================================================",
        "const List<AwingWord> dictionaryEntries = [",
    ]
    for cat in cat_order:
        items = by_category.get(cat, [])
        if not items:
            continue
        lines.append(f"  // {cat} ({len(items)})")
        for lit in items:
            lines.append(f"  {lit},")
        lines.append("")
    # Trim trailing empty line before close
    if lines[-1] == "":
        lines.pop()
    lines.append("];")
    new_block = "\n".join(lines)

    # ------------------------------------------------------------------
    # Splice into Dart file
    # ------------------------------------------------------------------
    new_dart = dart_text[:m_start.start()] + new_block + dart_text[block_close:]
    with open(DART_FILE, "w", encoding="utf-8") as fp:
        fp.write(new_dart)
    print(f"\n✓ Wrote {len(new_entries)} entries to "
          f"{DART_FILE.relative_to(ROOT)}")
    print(f"  Total file lines: {len(new_dart.splitlines())} "
          f"(was {len(dart_text.splitlines())})")


if __name__ == "__main__":
    main()
