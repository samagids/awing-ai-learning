#!/usr/bin/env python3
"""
apply_contributions.py — Apply approved contributions to Dart data files.

Reads approved_contributions.json from the contributions/ folder and applies
spelling corrections, pronunciation fixes, and new words/sentences to the
Dart source files in lib/data/.

Usage:
    python scripts/apply_contributions.py                  # Apply all approved
    python scripts/apply_contributions.py --list           # List pending changes
    python scripts/apply_contributions.py --dry-run        # Preview without modifying
    python scripts/apply_contributions.py --clean          # Remove processed file
    python scripts/apply_contributions.py --reset-version  # Re-pull every approved
                                                           # contribution from the
                                                           # webhook (useful after a
                                                           # server-side schema change)
    python scripts/apply_contributions.py --download       # Download only, don't apply
    python scripts/apply_contributions.py --refetch-audio  # Re-download m4a + re-run
                                                           # Whisper for pronunciation
                                                           # fixes already archived in
                                                           # contributions/applied/.
                                                           # Use after redeploying the
                                                           # webhook so you don't have
                                                           # to re-record the word.

The build_and_run.bat script calls this automatically before generating audio.

Pronunciation fix design (v2 — reference-only):
  The developer's raw recording is NEVER played in the app. Instead:
    1. The m4a is downloaded from Drive and saved as a REFERENCE file at
       contributions/voice_references/{key}.m4a (overwrites on re-record —
       latest wins). This is a training corpus for future model fine-tuning.
    2. If a pronunciationGuide was typed by the developer, it becomes the
       speakable_override for Edge TTS.
    3. Otherwise, if OpenAI Whisper is installed, the recording is
       transcribed (Swahili-biased) and the transcription becomes the
       speakable_override.
    4. Otherwise the fix still queues for Edge TTS regeneration using the
       default awing_to_speakable() pronunciation mapping.
  Edge TTS then regenerates the word in all 6 character voices using the
  override — the learner always hears the mode-appropriate character voice
  (boy/girl for beginner, young_man/young_woman for medium, man/woman for
  expert), not the developer's voice.

Latest-wins dedup:
  When the same target word is approved multiple times, only the
  highest-version contribution per (type, target) is applied. Older
  duplicates are discarded so we never apply an outdated correction.
"""

import json
import os
import re
import sys
import shutil
import unicodedata
import subprocess
import tempfile
import urllib.request
import urllib.error
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CONTRIBUTIONS_DIR = os.path.join(PROJECT_DIR, 'contributions')
APPROVED_FILE = os.path.join(CONTRIBUTIONS_DIR, 'approved_contributions.json')
APPLIED_DIR = os.path.join(CONTRIBUTIONS_DIR, 'applied')
WEBHOOKS_FILE = os.path.join(PROJECT_DIR, 'config', 'webhooks.json')
VERSION_FILE = os.path.join(CONTRIBUTIONS_DIR, 'last_version.txt')

REGENERATE_FILE = os.path.join(CONTRIBUTIONS_DIR, 'regenerate_words.json')
# Developer voice recordings are archived here as a future training corpus.
# They are NEVER played directly in the app — the 6 Edge TTS character voices
# are always what the learner hears.
VOICE_REFERENCES_DIR = os.path.join(CONTRIBUTIONS_DIR, 'voice_references')
# Legacy file from the v1 pronunciationFix design (Session 48) that installed
# the raw recording into every voice directory. If found, we delete it on
# first run so the refactored pipeline starts clean.
LEGACY_NATIVE_RECORDINGS_FILE = os.path.join(CONTRIBUTIONS_DIR, 'native_recordings.json')

# Dart data files
VOCAB_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_vocabulary.dart')
ALPHABET_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_alphabet.dart')
TONES_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_tones.dart')

# PAD asset pack audio directory — where Edge TTS writes, and where
# native speaker recordings are copied so the app can use them.
AUDIO_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main', 'assets', 'audio'
)
VOICE_DIRS = ['boy', 'girl', 'young_man', 'young_woman', 'man', 'woman']


def ensure_directories():
    """Create contributions/, contributions/applied/, and the voice
    references archive dir if they don't exist."""
    os.makedirs(CONTRIBUTIONS_DIR, exist_ok=True)
    os.makedirs(APPLIED_DIR, exist_ok=True)
    os.makedirs(VOICE_REFERENCES_DIR, exist_ok=True)
    # One-time cleanup of the legacy v1 state file, if present.
    if os.path.exists(LEGACY_NATIVE_RECORDINGS_FILE):
        try:
            os.remove(LEGACY_NATIVE_RECORDINGS_FILE)
        except OSError:
            pass


# ------------------------------------------------------------------
# Audio helpers (native speaker recording pipeline)
# ------------------------------------------------------------------

def _audio_key(awing_text):
    """Convert an Awing word to a safe ASCII filename.

    MUST match the logic in both:
      - scripts/generate_audio_edge.py  `_audio_key()`
      - lib/services/pronunciation_service.dart  `_audioKey()`

    Alphabet special chars (single char like 'ɛ', 'ə', 'ɨ', 'ɔ', 'ŋ') map
    to named keys (epsilon, schwa, barred_i, open_o, eng) that match the
    alphabet audio filenames the app expects. Otherwise we strip tone
    diacritics, map special vowels to ASCII, drop apostrophes, and keep
    only lowercase alphanumerics.
    """
    if not awing_text:
        return ''
    text = unicodedata.normalize('NFC', awing_text.strip().lower())

    # Alphabet letter names (must match pronunciation_service.dart)
    special_map = {
        'ɛ': 'epsilon', 'ə': 'schwa', 'ɨ': 'barred_i',
        'ɔ': 'open_o', 'ŋ': 'eng',
    }
    if text in special_map:
        return special_map[text]

    # Strip tone diacritics (acute, grave, circumflex, caron, tilde)
    tone_marks = ('\u0301', '\u0300', '\u0302', '\u030C', '\u0303')
    out_chars = []
    for ch in text:
        decomposed = unicodedata.normalize('NFD', ch)
        cleaned = ''.join(c for c in decomposed if not (
            unicodedata.category(c).startswith('M') and c in tone_marks))
        out_chars.append(unicodedata.normalize('NFC', cleaned))
    text = ''.join(out_chars)

    # Map special Awing vowels/nasals to ASCII equivalents
    for old, new in (('ɛ', 'e'), ('ɔ', 'o'), ('ə', 'e'),
                     ('ɨ', 'i'), ('ŋ', 'ng')):
        text = text.replace(old, new)

    # Drop glottal-stop apostrophes
    for q in ("'", '\u2019', '\u2018'):
        text = text.replace(q, '')

    # Keep only lowercase alphanumerics
    return re.sub(r'[^a-z0-9]', '', text)


def _is_alphabet_letter(awing_word):
    """Heuristic: check if a target word is an alphabet letter.

    Alphabet keys in the app correspond to single letters / digraphs /
    trigraphs from awing_alphabet.dart — they're short (typically 1-4
    chars) and the key appears in the alphabet Dart file.
    """
    if not awing_word or len(awing_word) > 4:
        return False
    try:
        with open(ALPHABET_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False
    # Look for `letter: 'X'` or `letter: "X"` exactly matching the target
    pat_s = re.compile(r"letter:\s*'" + re.escape(awing_word) + r"'", re.UNICODE)
    pat_d = re.compile(r'letter:\s*"' + re.escape(awing_word) + r'"', re.UNICODE)
    return bool(pat_s.search(content) or pat_d.search(content))


def _guess_category(awing_word):
    """Pick the audio subdirectory (alphabet/vocabulary/sentences/stories)
    based on the contribution's target word.

    Heuristic:
      - Contains spaces → 'sentences' (multi-word phrase or sentence)
      - Matches an alphabet letter → 'alphabet'
      - Otherwise → 'vocabulary'
    """
    if not awing_word:
        return 'vocabulary'
    if ' ' in awing_word.strip():
        return 'sentences'
    if _is_alphabet_letter(awing_word):
        return 'alphabet'
    return 'vocabulary'


def _extract_drive_file_id(url):
    """Parse a Google Drive share URL to extract the file ID.

    Handles:
      https://drive.google.com/file/d/FILEID/view?usp=...
      https://drive.google.com/uc?id=FILEID&export=download
      https://drive.google.com/open?id=FILEID
    Returns the file id string or None.
    """
    if not url:
        return None
    m = re.search(r'/file/d/([a-zA-Z0-9_-]+)', url)
    if m:
        return m.group(1)
    m = re.search(r'[?&]id=([a-zA-Z0-9_-]+)', url)
    if m:
        return m.group(1)
    return None


def _download_drive_file(audio_url, dest_path):
    """Download a Google Drive audio file to dest_path.

    Converts share-link URLs to direct-download URLs. Returns True on
    success, False on any failure (non-fatal — caller falls back to
    Edge TTS regeneration).
    """
    file_id = _extract_drive_file_id(audio_url)
    if not file_id:
        print(f"  ✗ Could not parse Drive URL: {audio_url}")
        return False

    direct_url = f"https://drive.google.com/uc?export=download&id={file_id}"
    try:
        req = urllib.request.Request(direct_url, headers={
            'User-Agent': 'Mozilla/5.0 (apply_contributions)',
        })
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        if len(data) < 1024:
            # Probably an HTML error page, not the audio — Drive sometimes
            # shows a virus-scan page for files > 100 MB, but m4a clips are
            # tiny so we should always get the binary.
            print(f"  ✗ Drive response too small ({len(data)} bytes) — probably an error page")
            return False
        with open(dest_path, 'wb') as f:
            f.write(data)
        return True
    except Exception as e:
        print(f"  ✗ Drive download failed: {e}")
        return False


def _find_ffmpeg():
    """Locate the ffmpeg binary. Returns path or None."""
    for candidate in ['ffmpeg', 'ffmpeg.exe']:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    return None


def _convert_m4a_to_mp3(m4a_path, mp3_path):
    """Convert m4a → mp3 via ffmpeg. Returns True on success."""
    ffmpeg = _find_ffmpeg()
    if not ffmpeg:
        print(f"  ✗ ffmpeg not found on PATH — cannot convert {m4a_path}")
        return False
    try:
        result = subprocess.run(
            [ffmpeg, '-y', '-loglevel', 'error',
             '-i', m4a_path,
             '-codec:a', 'libmp3lame', '-q:a', '4',
             mp3_path],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode != 0:
            print(f"  ✗ ffmpeg failed: {result.stderr.strip()}")
            return False
        return os.path.exists(mp3_path) and os.path.getsize(mp3_path) > 0
    except Exception as e:
        print(f"  ✗ ffmpeg error: {e}")
        return False


def _archive_voice_reference(audio_url, awing_word, dry_run=False):
    """Download the developer's recording and save it as a REFERENCE file
    at contributions/voice_references/{key}.m4a.

    The recording is NEVER played in the app — it is a future training
    corpus for fine-tuning the character voices. Re-recording the same
    word simply overwrites the previous reference, implementing
    latest-wins for the archive.

    Returns (archived: bool, key: str, m4a_path: Optional[str]).
    `m4a_path` is only set on success and is passed to the optional
    Whisper transcription step.
    """
    key = _audio_key(awing_word)
    if not key:
        print(f"  ✗ Could not derive audio key from '{awing_word}'")
        return False, '', None

    dest_path = os.path.join(VOICE_REFERENCES_DIR, f'{key}.m4a')

    if dry_run:
        print(f"  [DRY RUN] Would download {audio_url}")
        print(f"  [DRY RUN] Would archive to {dest_path} (overwrites if exists)")
        return True, key, None

    os.makedirs(VOICE_REFERENCES_DIR, exist_ok=True)
    print(f"  → Downloading voice reference from Drive...")
    if not _download_drive_file(audio_url, dest_path):
        return False, key, None

    size_kb = os.path.getsize(dest_path) / 1024.0
    print(f"  ✓ Archived reference: voice_references/{key}.m4a ({size_kb:.1f} KB)")
    return True, key, dest_path


# Module-level flag so we only print the "Whisper missing" banner once
# per run even when dozens of pronunciation fixes are processed in a loop.
_WHISPER_WARNED = False


def _whisper_transcribe(m4a_path, awing_hint=''):
    """Attempt to transcribe a recording with OpenAI Whisper.

    Whisper's multilingual model produces a Swahili-biased phonetic
    approximation of Awing words — that transcription becomes the
    speakable_override for Edge TTS, which is how the 6 character voices
    learn to pronounce the word correctly. Without Whisper the character
    voices fall back to the naive awing_to_speakable() mapping.

    If Whisper is not installed we print a LOUD warning (once per run) and
    return None. The caller will emit its own per-word warning and the
    word will end up in regenerate_words.json without an override.

    `awing_hint` is passed as the initial_prompt so Whisper is nudged
    toward the intended word.
    """
    global _WHISPER_WARNED

    if not m4a_path or not os.path.exists(m4a_path):
        return None
    try:
        import whisper  # type: ignore
    except ImportError:
        if not _WHISPER_WARNED:
            _WHISPER_WARNED = True
            print()
            print("  " + "=" * 64)
            print("  !! OpenAI Whisper is NOT installed.")
            print("  !! The character voices can only be trained to pronounce")
            print("  !! recorded words correctly when Whisper transcribes them.")
            print("  !! Without it, Edge TTS falls back to its default mapping")
            print("  !! (which is why ghǒ currently sounds spelled out).")
            print("  !!")
            print("  !! Fix with ONE command:")
            print("  !!     venv\\Scripts\\pip install openai-whisper")
            print("  !! Then rerun: python scripts\\apply_contributions.py")
            print("  " + "=" * 64)
            print()
        return None

    try:
        # Default to the small multilingual model — a balance of quality
        # and download size. Callers can override WHISPER_MODEL in env.
        model_name = os.environ.get('WHISPER_MODEL', 'small')
        print(f"  → Transcribing with Whisper ({model_name})...")
        model = whisper.load_model(model_name)
        result = model.transcribe(
            m4a_path,
            language='sw',           # Swahili bias — closest Bantu language
            task='transcribe',
            initial_prompt=awing_hint or None,
            fp16=False,
        )
        text = (result.get('text') or '').strip()
        if not text:
            return None
        print(f"    Whisper says: '{text}'")
        return text
    except Exception as e:
        print(f"    ⚠ Whisper transcription failed: {e}")
        return None


def reset_version():
    """Delete last_version.txt so the next run re-pulls every approved
    contribution from the webhook. Useful after a server-side schema
    change (e.g. we now send audioUrl in the response)."""
    if os.path.exists(VERSION_FILE):
        os.remove(VERSION_FILE)
        print(f"✓ Reset {VERSION_FILE} — next run will re-download every approved contribution.")
    else:
        print(f"  {VERSION_FILE} does not exist — nothing to reset.")


def get_webhook_url():
    """Load the contributions webhook URL from config/webhooks.json."""
    if not os.path.exists(WEBHOOKS_FILE):
        return None
    try:
        with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
        url = config.get('contributions_url', '')
        if url and url.startswith('https://'):
            return url
    except Exception as e:
        print(f"  Warning: Could not read webhooks.json: {e}")
    return None


def get_last_version():
    """Get the last content version we applied (stored locally)."""
    if not os.path.exists(VERSION_FILE):
        return 0
    try:
        with open(VERSION_FILE, 'r') as f:
            return int(f.read().strip())
    except (ValueError, OSError):
        return 0


def save_last_version(version):
    """Save the last content version we applied."""
    ensure_directories()
    with open(VERSION_FILE, 'w') as f:
        f.write(str(version))


def download_approved():
    """Download approved contributions from the Google Apps Script webhook.

    Checks the current content version against the server, downloads any
    new approved contributions, and saves them to approved_contributions.json.

    Returns the number of new contributions downloaded.
    """
    webhook_url = get_webhook_url()
    if not webhook_url:
        return 0

    current_version = get_last_version()
    print(f"  Checking for new approved contributions (local version: {current_version})...")

    # Ask the webhook for updates since our version
    payload = json.dumps({
        'action': 'check_version',
        'currentVersion': current_version,
    }).encode('utf-8')

    try:
        req = urllib.request.Request(
            webhook_url,
            data=payload,
            headers={'Content-Type': 'application/json'},
            method='POST',
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode('utf-8'))
    except urllib.error.URLError as e:
        print(f"  Warning: Could not reach webhook: {e}")
        return 0
    except Exception as e:
        print(f"  Warning: Download failed: {e}")
        return 0

    if result.get('status') != 'ok':
        print(f"  Warning: Webhook error: {result.get('message', 'unknown')}")
        return 0

    server_version = result.get('version', 0)
    updates = result.get('updates', [])

    if not updates:
        print(f"  No new contributions (server version: {server_version}).")
        save_last_version(server_version)
        return 0

    print(f"  Found {len(updates)} new approved contributions (server v{server_version}).")

    # Merge with any existing local approved file
    ensure_directories()
    existing = []
    if os.path.exists(APPROVED_FILE):
        try:
            with open(APPROVED_FILE, 'r', encoding='utf-8') as f:
                existing = json.load(f)
                if isinstance(existing, dict):
                    existing = [existing]
        except Exception:
            existing = []

    # Deduplicate by ID. The server's Approved sheet was NOT idempotent in
    # earlier versions — if `handleApproval` was called twice for the same
    # contribution id (which happens when the offline-queue retry resends an
    # approval the server already processed), it appended a SECOND row with
    # a higher version. `handleVersionCheck` returns BOTH rows. We collapse
    # them here, keeping only the highest-version row per id. The server's
    # JSON uses key `version` (not `itemVersion`); we accept both for safety.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    by_id = {}
    for c in existing:
        cid = c.get('id')
        if not cid:
            by_id[f"__noid_existing_{len(by_id)}"] = c
            continue
        prev = by_id.get(cid)
        if prev is None or _ver(c) >= _ver(prev):
            by_id[cid] = c
    for update in updates:
        cid = update.get('id')
        if not cid:
            by_id[f"__noid_update_{len(by_id)}"] = update
            continue
        prev = by_id.get(cid)
        if prev is None or _ver(update) >= _ver(prev):
            by_id[cid] = update
    existing = list(by_id.values())

    # Save merged file
    with open(APPROVED_FILE, 'w', encoding='utf-8') as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)

    print(f"  Saved {len(existing)} total contributions to approved_contributions.json")

    # Save the new version number (after successful apply, not here)
    # We'll save it after apply_contributions() succeeds
    return len(updates)


def load_contributions():
    """Load approved contributions from JSON file."""
    if not os.path.exists(APPROVED_FILE):
        return []

    with open(APPROVED_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if isinstance(data, dict):
        return [data]
    return data


def apply_spelling_correction(content, target_word, correction):
    """Replace a word's Awing spelling in a Dart file.

    Handles both regular strings and strings with apostrophes.
    Returns (modified_content, was_changed).
    """
    changed = False

    # Pattern 1: awing: 'target_word' (single-quoted)
    pattern1 = re.compile(
        r"(awing:\s*')(" + re.escape(target_word) + r")(')",
        re.UNICODE
    )
    if pattern1.search(content):
        content = pattern1.sub(r'\g<1>' + correction + r'\3', content)
        changed = True

    # Pattern 2: awing: "target_word" (double-quoted)
    pattern2 = re.compile(
        r'(awing:\s*")(' + re.escape(target_word) + r')(")',
        re.UNICODE
    )
    if pattern2.search(content):
        content = pattern2.sub(r'\g<1>' + correction + r'\3', content)
        changed = True

    # Pattern 3: letter: 'target_word' (for alphabet data)
    pattern3 = re.compile(
        r"(letter:\s*')(" + re.escape(target_word) + r")(')",
        re.UNICODE
    )
    if pattern3.search(content):
        content = pattern3.sub(r'\g<1>' + correction + r'\3', content)
        changed = True

    return content, changed


def apply_new_word(content, word, english, category):
    """Add a new word to the appropriate category list in awing_vocabulary.dart.

    Returns (modified_content, was_added).
    """
    # Map categories to list variable names
    category_map = {
        'body': 'bodyParts',
        'animals': 'animalsNature',
        'nature': 'animalsNature',
        'actions': 'actions',
        'things': 'thingsPlaces',
        'family': 'familyPeople',
        'daily': 'dailyLife',
        'greeting': 'dailyLife',
        'question': 'dailyLife',
        'farewell': 'dailyLife',
        'other': 'dailyLife',
    }

    list_name = category_map.get(category, 'dailyLife')

    # Check if word already exists
    if re.search(re.escape(word), content, re.UNICODE):
        print(f"  Word '{word}' already exists in vocabulary, skipping")
        return content, False

    # Find the closing bracket of the target list: ];
    # We look for the pattern: const List<AwingWord> listName = [\n...\n];
    pattern = re.compile(
        r"(const List<AwingWord> " + list_name + r" = \[)(.*?)(^\];)",
        re.MULTILINE | re.DOTALL
    )
    match = pattern.search(content)
    if not match:
        print(f"  Could not find list '{list_name}' for category '{category}'")
        return content, False

    # Determine quoting: use double quotes if word contains apostrophe
    if "'" in word:
        awing_quoted = f'"{word}"'
    else:
        awing_quoted = f"'{word}'"

    # Build the new entry
    new_entry = (
        f"  AwingWord(awing: {awing_quoted}, english: '{english}', "
        f"category: '{category}'),\n"
    )

    # Insert before the closing ];
    insert_pos = match.end(2)
    content = content[:insert_pos] + new_entry + content[insert_pos:]

    return content, True


def apply_new_sentence(tones_content, awing_text, english_text):
    """Add a new sentence to the sentences list in awing_tones.dart.

    Returns (modified_content, was_added).
    """
    # Check if already exists
    if re.search(re.escape(awing_text), tones_content, re.UNICODE):
        print(f"  Sentence '{awing_text[:30]}...' already exists, skipping")
        return tones_content, False

    # Find the awingSentences list
    pattern = re.compile(
        r"(const List<AwingSentence> awingSentences = \[)(.*?)(^\];)",
        re.MULTILINE | re.DOTALL
    )
    match = pattern.search(tones_content)
    if not match:
        print("  Could not find awingSentences list in awing_tones.dart")
        return tones_content, False

    # Determine quoting
    if "'" in awing_text:
        awing_q = f'"{awing_text}"'
    else:
        awing_q = f"'{awing_text}'"

    if "'" in english_text:
        eng_q = f'"{english_text}"'
    else:
        eng_q = f"'{english_text}'"

    new_entry = (
        f"  AwingSentence(\n"
        f"    awing: {awing_q},\n"
        f"    english: {eng_q},\n"
        f"    wordByWord: [],\n"
        f"  ),\n"
    )

    insert_pos = match.end(2)
    tones_content = tones_content[:insert_pos] + new_entry + tones_content[insert_pos:]

    return tones_content, True


def apply_contributions(contributions, dry_run=False):
    """Apply all contributions to the Dart data files."""
    if not contributions:
        print("No contributions to apply.")
        return 0

    # Two-stage dedup:
    #   1. By id — collapses server-side duplicates where `handleApproval`
    #      was called twice for the same contribution id (the Session 48
    #      idempotency fix prevents new duplicates, but legacy data may
    #      still have them).
    #   2. By (type, normalized target) — latest-wins. When the developer
    #      re-records or re-corrects the SAME word (different ids, same
    #      target), only the highest-version row is applied so we never
    #      apply an outdated correction.
    # Server JSON uses key `version`; older data may use `itemVersion`.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    def _norm_target(c):
        ctype = (c.get('type') or '').strip()
        target = (c.get('targetWord') or '').strip()
        # Normalize to the audio key for pronunciationFix so differently
        # diacritized spellings of the same recording collapse. For every
        # other type we key off the raw target since spelling matters.
        if ctype == 'pronunciationFix':
            return (ctype, _audio_key(target))
        return (ctype, target.lower())

    # Stage 1 — by id
    by_id = {}
    kept = []
    for c in contributions:
        cid = c.get('id')
        if not cid:
            kept.append(c)
            continue
        prev = by_id.get(cid)
        if prev is None:
            by_id[cid] = c
            kept.append(c)
        elif _ver(c) > _ver(prev):
            kept[kept.index(prev)] = c
            by_id[cid] = c
    before_id = len(contributions)
    contributions = kept
    if len(contributions) < before_id:
        print(f"  Dedup by id: {before_id} → {len(contributions)} "
              f"(removed {before_id - len(contributions)} duplicate id(s))")

    # Stage 2 — latest-wins by (type, normalized target)
    by_target = {}
    kept2 = []
    for c in contributions:
        key = _norm_target(c)
        # No target or unknown type → can't dedupe, keep it
        if not key[1]:
            kept2.append(c)
            continue
        prev = by_target.get(key)
        if prev is None:
            by_target[key] = c
            kept2.append(c)
        elif _ver(c) >= _ver(prev):
            kept2[kept2.index(prev)] = c
            by_target[key] = c
    before_target = len(contributions)
    contributions = kept2
    if len(contributions) < before_target:
        print(f"  Dedup latest-wins by target: {before_target} → "
              f"{len(contributions)} (kept only the latest version of each "
              f"(type, target))")

    # Read current Dart files
    with open(VOCAB_FILE, 'r', encoding='utf-8') as f:
        vocab_content = f.read()
    with open(ALPHABET_FILE, 'r', encoding='utf-8') as f:
        alphabet_content = f.read()

    tones_content = None
    if os.path.exists(TONES_FILE):
        with open(TONES_FILE, 'r', encoding='utf-8') as f:
            tones_content = f.read()

    applied_count = 0
    vocab_modified = False
    alphabet_modified = False
    tones_modified = False
    regenerate_words = []  # Words needing audio regeneration (all pronunciationFix + spelling changes)
    archived_references = []  # Developer recordings archived to voice_references/

    for c in contributions:
        ctype = c.get('type', '')
        target = c.get('targetWord', '')
        correction = c.get('correction', '')
        english = c.get('englishMeaning', '')
        category = c.get('category', 'other')
        pronunciation = c.get('pronunciationGuide', '')
        profile = c.get('profileName', 'Unknown')
        audio_url = c.get('audioUrl') or ''

        print(f"\nApplying: [{ctype}] '{target}' → '{correction}' (from {profile})")

        if ctype == 'spellingCorrection':
            # Try vocabulary file first
            vocab_content, changed = apply_spelling_correction(
                vocab_content, target, correction)
            if changed:
                vocab_modified = True
                applied_count += 1
                # Spelling changed → audio key changed → regenerate audio for new word
                regenerate_words.append({
                    'awing': correction,
                    'english': english or '',
                    'category': category,
                })
                print(f"  ✓ Updated spelling in awing_vocabulary.dart")
                print(f"    Audio will be regenerated for corrected word '{correction}'")
                continue

            # Try alphabet file
            alphabet_content, changed = apply_spelling_correction(
                alphabet_content, target, correction)
            if changed:
                alphabet_modified = True
                applied_count += 1
                regenerate_words.append({
                    'awing': correction,
                    'english': english or '',
                    'category': category,
                })
                print(f"  ✓ Updated spelling in awing_alphabet.dart")
                print(f"    Audio will be regenerated for corrected word '{correction}'")
                continue

            # Try tones file
            if tones_content:
                tones_content, changed = apply_spelling_correction(
                    tones_content, target, correction)
                if changed:
                    tones_modified = True
                    applied_count += 1
                    regenerate_words.append({
                        'awing': correction,
                        'english': english or '',
                        'category': category,
                    })
                    print(f"  ✓ Updated spelling in awing_tones.dart")
                    print(f"    Audio will be regenerated for corrected word '{correction}'")
                    continue

            print(f"  ✗ Word '{target}' not found in any data file")

        elif ctype == 'newWord':
            vocab_content, added = apply_new_word(
                vocab_content, correction or target, english, category)
            if added:
                vocab_modified = True
                applied_count += 1
                print(f"  ✓ Added new word to awing_vocabulary.dart")

        elif ctype == 'newSentence' or ctype == 'newPhrase':
            if tones_content:
                tones_content, added = apply_new_sentence(
                    tones_content, correction or target, english or correction)
                if added:
                    tones_modified = True
                    applied_count += 1
                    print(f"  ✓ Added new sentence to awing_tones.dart")

        elif ctype == 'pronunciationFix':
            # Reference-only pronunciation fixes (v2 design):
            # The developer's recording is NEVER played in the app. Instead:
            #   1. Archive the m4a to voice_references/{key}.m4a as a future
            #      training corpus. Re-records overwrite, so latest wins.
            #   2. Derive a speakable_override for Edge TTS from (in order):
            #        a. the developer's typed pronunciationGuide
            #        b. an optional Whisper ASR transcription (Swahili-biased)
            #        c. no override — Edge TTS uses its default
            #           awing_to_speakable() mapping
            #   3. Queue the word for Edge TTS regeneration. The learner
            #      always hears the mode-appropriate character voice
            #      (boy/girl for beginner, young_man/young_woman for medium,
            #      man/woman for expert) — not the developer's voice.
            m4a_path = None
            if audio_url:
                archived, key, m4a_path = _archive_voice_reference(
                    audio_url, target, dry_run=dry_run)
                if archived:
                    archived_references.append({
                        'key': key,
                        'awing': target,
                        'english': english or '',
                        'archived_at': datetime.now().isoformat(),
                    })
                else:
                    print(f"  ⚠ Voice reference archive failed — continuing with TTS regen")
            else:
                # The webhook's response did NOT include an audioUrl for this
                # pronunciationFix. Without the recording we can't run Whisper
                # to learn how the word should be pronounced, so the character
                # voices will fall back to Edge TTS's default spelling-based
                # mapping — exactly the bug the developer recorded the fix to
                # solve. Almost always caused by an older deployment of
                # scripts/contributions_webapp.gs that predates the change
                # which puts audioUrl into handleVersionCheck responses.
                print()
                print("  " + "!" * 64)
                print(f"  !! NO AUDIO URL for '{target}' — the character voices will")
                print("  !! NOT learn from the recording!")
                print("  !!")
                print("  !! Root cause: the deployed Apps Script webhook is outdated")
                print("  !! and is not returning audioUrl in check_version responses.")
                print("  !!")
                print("  !! Fix (2 steps):")
                print("  !!   1. Redeploy the webhook:")
                print("  !!      cd scripts\\clasp_contributions")
                print("  !!      clasp push --force && clasp deploy")
                print("  !!   2. Rerun with --refetch-audio to recover the recording")
                print("  !!      for already-applied contributions:")
                print("  !!      python scripts\\apply_contributions.py --refetch-audio")
                print("  " + "!" * 64)
                print()

            speakable_override = ''
            override_source = ''
            if pronunciation:
                speakable_override = pronunciation
                override_source = 'pronunciationGuide'
            elif m4a_path and not dry_run:
                whisper_text = _whisper_transcribe(m4a_path, awing_hint=target)
                if whisper_text:
                    speakable_override = whisper_text
                    override_source = 'whisper'
                else:
                    # Whisper either isn't installed (banner already printed
                    # by _whisper_transcribe) or produced nothing for this
                    # recording — warn so the user understands this specific
                    # word won't get a trained-from-recording override.
                    print(f"  ⚠ Whisper produced no transcription for '{target}'")
                    print(f"    → Edge TTS will fall back to default mapping for this word")

            word_entry = {
                'awing': target,
                'english': english or '',
                'category': category,
            }
            if speakable_override:
                word_entry['speakable_override'] = speakable_override
                print(f"  → Speakable override ({override_source}): '{speakable_override}'")
            else:
                print(f"  → No override — Edge TTS will use default pronunciation mapping")
            print(f"    Queued for regeneration in all 6 character voices")
            regenerate_words.append(word_entry)
            applied_count += 1

        elif ctype == 'generalFeedback':
            print(f"  → Feedback noted: {c.get('notes', correction)}")

    # Write modified files
    if not dry_run:
        if vocab_modified:
            with open(VOCAB_FILE, 'w', encoding='utf-8') as f:
                f.write(vocab_content)
            print(f"\n✓ Saved {VOCAB_FILE}")

        if alphabet_modified:
            with open(ALPHABET_FILE, 'w', encoding='utf-8') as f:
                f.write(alphabet_content)
            print(f"✓ Saved {ALPHABET_FILE}")

        if tones_modified and tones_content:
            with open(TONES_FILE, 'w', encoding='utf-8') as f:
                f.write(tones_content)
            print(f"✓ Saved {TONES_FILE}")

        # Write regeneration list for Edge TTS (any spelling/pronunciation
        # change queues its word here so all 6 character voices get a fresh
        # clip, with an optional speakable_override to shape pronunciation).
        if regenerate_words:
            # De-duplicate by awing — a contribution pass may queue the
            # same word twice if both the spelling and the pronunciation
            # changed. Keep the LAST entry (which has any override set).
            seen = {}
            for w in regenerate_words:
                seen[w.get('awing', '')] = w
            regenerate_words = list(seen.values())
            with open(REGENERATE_FILE, 'w', encoding='utf-8') as f:
                json.dump(regenerate_words, f, ensure_ascii=False, indent=2)
            print(f"\n✓ Wrote {len(regenerate_words)} word(s) to {REGENERATE_FILE}")
            print(f"  Edge TTS will force-regenerate these words for all 6 voices")

        # Summarize archived voice references. These are training material
        # for future fine-tuning of the character voices — the app never
        # plays them directly.
        if archived_references:
            print(f"\n✓ Archived {len(archived_references)} developer recording(s) "
                  f"to {VOICE_REFERENCES_DIR}")
            print(f"  These are future training material — the app plays the "
                  f"character TTS voices, not the recording itself.")

        # Archive the processed file
        os.makedirs(APPLIED_DIR, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        archive_path = os.path.join(APPLIED_DIR, f'applied_{timestamp}.json')
        shutil.move(APPROVED_FILE, archive_path)
        print(f"✓ Archived contributions to {archive_path}")
    else:
        print("\n[DRY RUN] No files were modified.")

    return applied_count


def list_contributions():
    """List all pending approved contributions."""
    contributions = load_contributions()
    if not contributions:
        print("No approved contributions found.")
        print(f"Place approved_contributions.json in: {CONTRIBUTIONS_DIR}")
        return

    print(f"\n{'='*60}")
    print(f"  {len(contributions)} Approved Contributions")
    print(f"{'='*60}")

    for i, c in enumerate(contributions, 1):
        ctype = c.get('type', 'unknown')
        target = c.get('targetWord', '')
        correction = c.get('correction', '')
        profile = c.get('profileName', 'Unknown')
        date = c.get('submittedAt', '')[:10]

        icon = {
            'spellingCorrection': '📝',
            'pronunciationFix': '🎤',
            'newWord': '➕',
            'newSentence': '📖',
            'newPhrase': '💬',
            'generalFeedback': '💡',
        }.get(ctype, '❓')

        print(f"\n  {i}. {icon} [{ctype}]")
        print(f"     Word: {target}")
        if correction:
            print(f"     → {correction}")
        if c.get('englishMeaning'):
            print(f"     English: {c['englishMeaning']}")
        if c.get('category'):
            print(f"     Category: {c['category']}")
        if c.get('pronunciationGuide'):
            print(f"     Pronunciation: {c['pronunciationGuide']}")
        print(f"     From: {profile} ({date})")


def clean_applied():
    """Remove all applied contribution archives."""
    if os.path.exists(APPLIED_DIR):
        shutil.rmtree(APPLIED_DIR)
        print(f"Cleaned: {APPLIED_DIR}")
    if os.path.exists(APPROVED_FILE):
        os.remove(APPROVED_FILE)
        print(f"Removed: {APPROVED_FILE}")
    print("Done.")


def refetch_audio():
    """Re-download m4a recordings + re-run Whisper for every pronunciationFix
    contribution that was already applied earlier.

    Why this exists:
      Earlier versions of scripts/contributions_webapp.gs didn't include
      audioUrl in handleVersionCheck's response. Contributions approved
      during that window were applied without the recording, so the
      character voices never learned the correct pronunciation — they
      fell back to Edge TTS's default awing_to_speakable() mapping, which
      is exactly the bug the developer recorded the fix to solve.

      After redeploying the updated webhook, this command walks every
      applied_*.json archive, asks the server for the audioUrl for each
      pronunciationFix id (via the 'fetch_audio' webhook endpoint), and
      then runs the SAME archive + Whisper pipeline apply_contributions()
      would have run if the audio had been present the first time. The
      resulting speakable_override values are merged into
      regenerate_words.json so the next Edge TTS run produces the right
      audio for every character voice, in every mode.

    This function does NOT re-apply Dart edits — those already ran the
    first time. It only recovers the missing audio → override pipeline.
    """
    webhook_url = get_webhook_url()
    if not webhook_url:
        print("  ✗ No webhook URL configured in config/webhooks.json — cannot refetch.")
        return

    if not os.path.exists(APPLIED_DIR):
        print(f"  {APPLIED_DIR} does not exist — no applied contributions to recover.")
        return

    # Gather every pronunciationFix that was ever applied
    applied_files = sorted(
        f for f in os.listdir(APPLIED_DIR)
        if f.startswith('applied_') and f.endswith('.json')
    )
    if not applied_files:
        print("  No applied_*.json archives found — nothing to refetch.")
        return

    print(f"\nScanning {len(applied_files)} applied archive(s) for pronunciation fixes...")

    pron_fixes = []
    for fname in applied_files:
        path = os.path.join(APPLIED_DIR, fname)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            print(f"  ⚠ Could not read {fname}: {e}")
            continue
        if isinstance(data, dict):
            data = [data]
        for c in data:
            if (c.get('type') or '') != 'pronunciationFix':
                continue
            cid = c.get('id')
            target = c.get('targetWord', '')
            if not cid or not target:
                continue
            pron_fixes.append(c)

    if not pron_fixes:
        print("  No pronunciationFix contributions found in applied archives.")
        return

    # Latest-wins per (type, normalized target). We only need to fetch and
    # re-transcribe the newest recording for each word; older ones would be
    # shadowed by the latest-wins dedup in apply_contributions anyway.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    by_target = {}
    for c in pron_fixes:
        key = _audio_key(c.get('targetWord', ''))
        if not key:
            continue
        prev = by_target.get(key)
        if prev is None or _ver(c) >= _ver(prev):
            by_target[key] = c

    kept = list(by_target.values())
    print(f"  Found {len(pron_fixes)} pronunciation fixes, {len(kept)} "
          f"unique target(s) after latest-wins dedup.")

    ids = [c.get('id') for c in kept if c.get('id')]
    if not ids:
        print("  ⚠ None of the pronunciation fixes have an id — cannot fetch audio.")
        return

    # Ask the webhook for the audioUrl of each contribution id.
    # Requires the deployed webhook to implement the 'fetch_audio' action
    # (added in contributions_webapp.gs this session). If the endpoint
    # doesn't exist we'll get back an empty `audio` map and exit cleanly.
    print(f"  → Asking webhook for audioUrls of {len(ids)} contribution(s)...")
    payload = json.dumps({
        'action': 'fetch_audio',
        'ids': ids,
    }).encode('utf-8')
    try:
        req = urllib.request.Request(
            webhook_url,
            data=payload,
            headers={'Content-Type': 'application/json; charset=utf-8'},
            method='POST',
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print(f"  ✗ Webhook call failed: {e}")
        print(f"     Make sure you've redeployed the webhook:")
        print(f"       cd scripts\\clasp_contributions && clasp push --force && clasp deploy")
        return

    if result.get('status') != 'ok':
        print(f"  ✗ Webhook error: {result.get('message', 'unknown')}")
        return

    audio_by_id = result.get('audio') or {}
    if not audio_by_id:
        print(f"  ⚠ Webhook returned no audioUrls. Either the deployed version")
        print(f"    doesn't implement the 'fetch_audio' action yet, or none of")
        print(f"    these submissions have a recording on file.")
        print(f"    Redeploy and re-run:")
        print(f"      cd scripts\\clasp_contributions && clasp push --force && clasp deploy")
        return

    print(f"  ✓ Got audioUrls for {len(audio_by_id)} / {len(ids)} contribution(s).")

    # Load any existing regenerate_words.json so we merge rather than overwrite
    existing_regen = []
    if os.path.exists(REGENERATE_FILE):
        try:
            with open(REGENERATE_FILE, 'r', encoding='utf-8') as f:
                existing_regen = json.load(f)
            if isinstance(existing_regen, dict):
                existing_regen = [existing_regen]
        except Exception:
            existing_regen = []

    regen_by_key = {}
    for w in existing_regen:
        regen_by_key[_audio_key(w.get('awing', ''))] = w

    fetched = 0
    transcribed = 0
    for c in kept:
        cid = c.get('id')
        target = c.get('targetWord', '')
        english = c.get('englishMeaning', '')
        category = c.get('category', 'other')
        pronunciation = c.get('pronunciationGuide', '')

        audio_url = audio_by_id.get(cid)
        if not audio_url:
            print(f"\n  ✗ No audio on server for '{target}' (id={cid}) — skipping")
            continue

        print(f"\n  Recovering: '{target}' (from {c.get('profileName', 'Unknown')})")
        archived, key, m4a_path = _archive_voice_reference(audio_url, target)
        if not archived or not m4a_path:
            continue
        fetched += 1

        # Prefer a typed pronunciationGuide if the developer provided one;
        # otherwise fall back to Whisper transcription of the recording.
        speakable_override = ''
        override_source = ''
        if pronunciation:
            speakable_override = pronunciation
            override_source = 'pronunciationGuide'
        else:
            whisper_text = _whisper_transcribe(m4a_path, awing_hint=target)
            if whisper_text:
                speakable_override = whisper_text
                override_source = 'whisper'
                transcribed += 1
            else:
                print(f"    ⚠ Whisper produced no transcription — no override set for '{target}'")

        entry = {
            'awing': target,
            'english': english or '',
            'category': category,
        }
        if speakable_override:
            entry['speakable_override'] = speakable_override
            print(f"    → Speakable override ({override_source}): '{speakable_override}'")

        regen_by_key[key] = entry

    if regen_by_key:
        merged = list(regen_by_key.values())
        with open(REGENERATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(merged, f, ensure_ascii=False, indent=2)
        print(f"\n✓ Wrote {len(merged)} word(s) to {REGENERATE_FILE}")
        print(f"  Fetched audio for {fetched}, transcribed {transcribed} with Whisper.")
        print(f"\nNext step:")
        print(f"  .\\scripts\\build_and_run.bat")
        print(f"  (or just: python scripts\\generate_audio_edge.py regenerate)")
    else:
        print(f"\n  Nothing written to {REGENERATE_FILE}.")


def main():
    args = sys.argv[1:]

    if '--help' in args or '-h' in args:
        print(__doc__)
        return

    # Always ensure directories exist
    ensure_directories()

    if '--list' in args:
        list_contributions()
        return

    if '--clean' in args:
        clean_applied()
        return

    if '--refetch-audio' in args:
        # Recovery path: for pronunciationFix contributions that were
        # applied BEFORE the webhook started returning audioUrl, pull the
        # recording from the server, re-run Whisper, and merge the override
        # into regenerate_words.json. Does NOT re-apply Dart edits.
        refetch_audio()
        return

    if '--reset-version' in args:
        reset_version()
        # Allow --reset-version + normal run to re-pull and apply in one go
        args = [a for a in args if a != '--reset-version']

    if '--download' in args:
        # Download only, don't apply
        count = download_approved()
        if count > 0:
            print(f"\nDownloaded {count} new contributions.")
            print(f"Run without --download to apply them.")
        return

    dry_run = '--dry-run' in args

    # Step 1: Try to download new approved contributions from the webhook (if configured)
    webhook_url = get_webhook_url()
    if webhook_url:
        download_approved()

    # Step 2: Load and apply local contributions
    contributions = load_contributions()
    if not contributions:
        print("No approved contributions to apply.")
        print("Skipping contribution application.")
        return

    print(f"\nFound {len(contributions)} approved contributions.")
    applied = apply_contributions(contributions, dry_run=dry_run)
    print(f"\n{'='*60}")
    print(f"  Applied: {applied}/{len(contributions)} contributions")
    print(f"{'='*60}")

    if applied > 0 and not dry_run:
        # Save the server version so we don't re-download these next time
        if webhook_url:
            try:
                # Re-check to get the latest version number
                payload = json.dumps({
                    'action': 'check_version',
                    'currentVersion': 999999,
                }).encode('utf-8')
                req = urllib.request.Request(
                    webhook_url,
                    data=payload,
                    headers={'Content-Type': 'application/json'},
                    method='POST',
                )
                with urllib.request.urlopen(req, timeout=15) as resp:
                    result = json.loads(resp.read().decode('utf-8'))
                    save_last_version(result.get('version', 0))
            except Exception:
                pass  # Non-critical

        print("\nNext steps:")
        print("  1. Audio will be regenerated by build_and_run.bat")
        print("  2. APK will be built with the updated content")
        print("  3. Verify on device before pushing to app stores")


if __name__ == '__main__':
    main()
