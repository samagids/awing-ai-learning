#!/usr/bin/env python3
"""
apply_contributions.py — Apply approved contributions to Dart data files.

Reads approved_contributions.json from the contributions/ folder and applies
spelling corrections, pronunciation fixes, and new words/sentences to the
Dart source files in lib/data/.

Usage:
    python scripts/apply_contributions.py              # Apply all approved
    python scripts/apply_contributions.py --list       # List pending changes
    python scripts/apply_contributions.py --dry-run    # Preview without modifying
    python scripts/apply_contributions.py --clean      # Remove processed file

The build_and_run.bat script calls this automatically before generating audio.
"""

import json
import os
import re
import sys
import shutil
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

# Dart data files
VOCAB_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_vocabulary.dart')
ALPHABET_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_alphabet.dart')
TONES_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_tones.dart')


def ensure_directories():
    """Create contributions/ and contributions/applied/ if they don't exist."""
    os.makedirs(CONTRIBUTIONS_DIR, exist_ok=True)
    os.makedirs(APPLIED_DIR, exist_ok=True)


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

    # Deduplicate by ID
    existing_ids = {c.get('id') for c in existing}
    for update in updates:
        if update.get('id') not in existing_ids:
            existing.append(update)

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

    for c in contributions:
        ctype = c.get('type', '')
        target = c.get('targetWord', '')
        correction = c.get('correction', '')
        english = c.get('englishMeaning', '')
        category = c.get('category', 'other')
        pronunciation = c.get('pronunciationGuide', '')
        profile = c.get('profileName', 'Unknown')

        print(f"\nApplying: [{ctype}] '{target}' → '{correction}' (from {profile})")

        if ctype == 'spellingCorrection':
            # Try vocabulary file first
            vocab_content, changed = apply_spelling_correction(
                vocab_content, target, correction)
            if changed:
                vocab_modified = True
                applied_count += 1
                print(f"  ✓ Updated spelling in awing_vocabulary.dart")
                continue

            # Try alphabet file
            alphabet_content, changed = apply_spelling_correction(
                alphabet_content, target, correction)
            if changed:
                alphabet_modified = True
                applied_count += 1
                print(f"  ✓ Updated spelling in awing_alphabet.dart")
                continue

            # Try tones file
            if tones_content:
                tones_content, changed = apply_spelling_correction(
                    tones_content, target, correction)
                if changed:
                    tones_modified = True
                    applied_count += 1
                    print(f"  ✓ Updated spelling in awing_tones.dart")
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
            # Pronunciation fixes just need audio regeneration
            # The word itself doesn't change in the Dart files
            if pronunciation:
                print(f"  → Pronunciation fix — guide: '{pronunciation}'")
                print(f"    Audio will be regenerated by Edge TTS")
            else:
                print(f"  → Pronunciation fix — audio will be regenerated by Edge TTS")
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
