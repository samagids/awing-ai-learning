#!/usr/bin/env python3
"""Build an Awing↔English parallel Bible NT from existing assets +
World English Bible (WEB, public domain).

Inputs:
  - Awing NT verses: corpus/raw/bible/azocab/<BOOK>/<NNN>.verses.json
                     (already on disk from the YouVersion scrape)
  - English WEB NT:  downloaded once and cached at
                     corpus/raw/bible/web/<BOOK>.json
                     (public domain, no license issue)

Output:
  corpus/parallel/nt_aligned.json
    [
      {
        "ref": "MAT.1.1",
        "book": "MAT", "chapter": 1, "verse": 1,
        "awing": "Lɛ̌ ndzaŋ pətǎ pə́ pətǎ pə́ Yeso Klisto...",
        "english": "The book of the genealogy of Jesus Christ...",
        "awing_word_count": 18,
        "english_word_count": 13
      },
      ...
    ]

Usage:
  python3 scripts/build_bible_parallel.py            # Full build (downloads WEB once, ~3 MB)
  python3 scripts/build_bible_parallel.py --refresh-english  # Re-download English NT
  python3 scripts/build_bible_parallel.py --status   # What's on disk

After this runs, downstream curation scripts can pick verses by length,
book, topic — using BOTH Awing and English text from one file.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
AZOCAB_DIR = REPO_ROOT / "corpus" / "raw" / "bible" / "azocab"
WEB_DIR = REPO_ROOT / "corpus" / "raw" / "bible" / "web"
PARALLEL_OUT = REPO_ROOT / "corpus" / "parallel" / "nt_aligned.json"

# 27-book NT in standard 3-letter abbreviations (Paratext / SIL convention).
# Matches the directory layout produced by scripts/ingest/youversion.py.
NT_BOOKS = [
    "MAT", "MRK", "LUK", "JHN", "ACT",
    "ROM", "1CO", "2CO", "GAL", "EPH", "PHP", "COL",
    "1TH", "2TH", "1TI", "2TI", "TIT", "PHM",
    "HEB", "JAS", "1PE", "2PE", "1JN", "2JN", "3JN", "JUD", "REV",
]

# Public-domain WEB Bible. Primary source: bible-api.com — free JSON
# API with no auth, per-chapter endpoints. 260 NT chapters = ~3 min.
# We cache each chapter so re-runs are instant.
BIBLE_API_BASE = "https://bible-api.com"

# Chapter counts per NT book (well-known, used to drive the download loop).
NT_CHAPTER_COUNTS = {
    "MAT": 28, "MRK": 16, "LUK": 24, "JHN": 21, "ACT": 28,
    "ROM": 16, "1CO": 16, "2CO": 13, "GAL": 6, "EPH": 6,
    "PHP": 4,  "COL": 4,  "1TH": 5,  "2TH": 3, "1TI": 6,
    "2TI": 4,  "TIT": 3,  "PHM": 1,  "HEB": 13, "JAS": 5,
    "1PE": 5,  "2PE": 3,  "1JN": 5,  "2JN": 1, "3JN": 1,
    "JUD": 1,  "REV": 22,
}

# Map our 3-letter codes to the URL-friendly book names bible-api expects.
USFM_TO_API_BOOK = {
    "MAT": "matthew", "MRK": "mark", "LUK": "luke", "JHN": "john", "ACT": "acts",
    "ROM": "romans", "1CO": "1corinthians", "2CO": "2corinthians",
    "GAL": "galatians", "EPH": "ephesians", "PHP": "philippians", "COL": "colossians",
    "1TH": "1thessalonians", "2TH": "2thessalonians",
    "1TI": "1timothy", "2TI": "2timothy", "TIT": "titus", "PHM": "philemon",
    "HEB": "hebrews", "JAS": "james", "1PE": "1peter", "2PE": "2peter",
    "1JN": "1john", "2JN": "2john", "3JN": "3john", "JUD": "jude", "REV": "revelation",
}

# Manual-download instruction if all of the above fail.
WEB_MANUAL_URL = "https://ebible.org/web/web_json.zip"


# ============================================================
# Awing side: read existing corpus
# ============================================================

def load_awing_nt() -> dict[str, str]:
    """Walk corpus/raw/bible/azocab/<BOOK>/<NNN>.verses.json -> {ref: text}.

    The verses.json schema uses `usfm` as the canonical reference key
    (e.g. "1CO.1.1"). Fall back to building from book/chapter/verse if
    `usfm` is missing.
    """
    out: dict[str, str] = {}
    if not AZOCAB_DIR.exists():
        print(f"ERROR: Awing corpus missing at {AZOCAB_DIR}")
        return out
    for vj in sorted(AZOCAB_DIR.rglob("*.verses.json")):
        try:
            entries = json.loads(vj.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  skip {vj}: {e}")
            continue
        for e in entries:
            ref = e.get("usfm") or ""
            if not ref:
                book = e.get("book")
                ch = e.get("chapter")
                vn = e.get("verse")
                if book and ch and vn:
                    ref = f"{book}.{ch}.{vn}"
            text = (e.get("text") or "").strip()
            if ref and text:
                # Normalise: BOOK.CH.V form, uppercase book.
                ref = ref.replace("-", ".").replace("_", ".").upper()
                out[ref] = text
    return out


# ============================================================
# English side: download WEB once, cache locally
# ============================================================

import time

# Per-call delay between bible-api.com requests. The free service caps
# at ~5 requests / 30 seconds per IP. 6 seconds is a safe baseline.
_BIBLE_API_DELAY_S = 1.0
# When we hit 429 we wait this long before the next attempt.
_BIBLE_API_BACKOFF_S = 30.0


def _fetch(url: str, retries: int = 3) -> bytes | None:
    """HTTP GET with retry on 429 (rate limit) + exponential backoff."""
    last_err = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "awing-app/1.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            last_err = e
            if e.code == 429:
                wait = _BIBLE_API_BACKOFF_S * (attempt + 1)
                print(f"    rate-limited (429) — waiting {wait:.0f}s before retry {attempt+1}/{retries}")
                time.sleep(wait)
                continue
            elif e.code == 404:
                # Don't retry 404s.
                return None
            else:
                print(f"    fetch failed: {e}")
                return None
        except Exception as e:
            last_err = e
            time.sleep(2)
    if last_err:
        print(f"    fetch failed after {retries} retries: {last_err}")
    return None


# Mapping from common book name forms to our 3-letter USFM codes.
# Different sources use different conventions; this covers the common
# ones we encounter (full names, abbreviations, with/without spaces).
_BOOK_ALIASES = {
    "matthew": "MAT", "matt": "MAT", "mt": "MAT", "mat": "MAT",
    "mark": "MRK", "mk": "MRK", "mrk": "MRK",
    "luke": "LUK", "lk": "LUK", "luk": "LUK",
    "john": "JHN", "jn": "JHN", "jhn": "JHN",
    "acts": "ACT", "act": "ACT",
    "romans": "ROM", "rom": "ROM",
    "1 corinthians": "1CO", "1corinthians": "1CO", "1cor": "1CO",
    "1 cor": "1CO", "1co": "1CO",
    "2 corinthians": "2CO", "2corinthians": "2CO", "2cor": "2CO",
    "2 cor": "2CO", "2co": "2CO",
    "galatians": "GAL", "gal": "GAL",
    "ephesians": "EPH", "eph": "EPH",
    "philippians": "PHP", "php": "PHP", "phil": "PHP",
    "colossians": "COL", "col": "COL",
    "1 thessalonians": "1TH", "1thessalonians": "1TH", "1th": "1TH",
    "1 thes": "1TH", "1ths": "1TH",
    "2 thessalonians": "2TH", "2thessalonians": "2TH", "2th": "2TH",
    "2 thes": "2TH", "2ths": "2TH",
    "1 timothy": "1TI", "1timothy": "1TI", "1tim": "1TI", "1ti": "1TI",
    "2 timothy": "2TI", "2timothy": "2TI", "2tim": "2TI", "2ti": "2TI",
    "titus": "TIT", "tit": "TIT",
    "philemon": "PHM", "phm": "PHM",
    "hebrews": "HEB", "heb": "HEB",
    "james": "JAS", "jas": "JAS", "jms": "JAS",
    "1 peter": "1PE", "1peter": "1PE", "1pet": "1PE", "1pe": "1PE",
    "2 peter": "2PE", "2peter": "2PE", "2pet": "2PE", "2pe": "2PE",
    "1 john": "1JN", "1john": "1JN", "1jn": "1JN",
    "2 john": "2JN", "2john": "2JN", "2jn": "2JN",
    "3 john": "3JN", "3john": "3JN", "3jn": "3JN",
    "jude": "JUD", "jud": "JUD",
    "revelation": "REV", "rev": "REV",
}


def _book_to_usfm(name: str) -> str | None:
    return _BOOK_ALIASES.get(name.lower().strip())


def _try_single_file_source(refresh: bool) -> dict[str, str] | None:
    """Try downloading one of the single-file WEB Bible JSONs. The first
    that works wins. Returns {ref: english_text} or None on failure."""
    cache_path = WEB_DIR / "web_full.json"
    if not refresh and cache_path.exists():
        print(f"  Using cached full-Bible JSON: {cache_path.relative_to(REPO_ROOT)}")
        try:
            return _parse_single_file_json(cache_path.read_bytes())
        except Exception as e:
            print(f"    cached file unreadable: {e} — re-downloading")

    for url in WEB_SINGLE_FILE_SOURCES:
        print(f"  Trying single-file source: {url}")
        data = _fetch(url)
        if data is None:
            continue
        try:
            parsed = _parse_single_file_json(data)
            if parsed:
                cache_path.parent.mkdir(parents=True, exist_ok=True)
                cache_path.write_bytes(data)
                print(f"    Cached as {cache_path.relative_to(REPO_ROOT)}")
                return parsed
        except Exception as e:
            print(f"    parse failed: {e}")
    return None


def _parse_single_file_json(raw: bytes) -> dict[str, str]:
    """Single-file Bible JSON formats vary. Common shapes:
       (a) {"verses": [{"book_name": "Matthew", "chapter": 1,
                        "verse": 1, "text": "..."}, ...]}
       (b) {"resultset": {"row": [{"field": [id, b, c, v, text]}, ...]}}
       (c) [{"book": "MAT", "chapter": 1, "verse": 1, "text": "..."}, ...]
    Returns {ref: text} keyed by USFM-style refs.
    """
    data = json.loads(raw)
    out: dict[str, str] = {}

    # Form (a): {"verses": [...]}
    verses_list = data.get("verses") if isinstance(data, dict) else None
    if isinstance(verses_list, list):
        for v in verses_list:
            book_raw = v.get("book_name") or v.get("book") or v.get("book_id") or ""
            usfm = _book_to_usfm(str(book_raw))
            cn = v.get("chapter")
            vn = v.get("verse")
            text = (v.get("text") or "").strip()
            if usfm and cn and vn and text:
                out[f"{usfm}.{cn}.{vn}"] = text
        if out:
            return out

    # Form (b): {"resultset": {"row": [{"field": [id, b, c, v, text]}, ...]}}
    rs = data.get("resultset", {}) if isinstance(data, dict) else {}
    rows = rs.get("row") if isinstance(rs, dict) else None
    if isinstance(rows, list):
        # In t_web.json format: id is BBCCCVVV (book*1000000 + ch*1000 + v)
        # but book numbers are 1-66. We just need ch+v+text and a book code.
        BOOK_NUM_TO_USFM = {
            40: "MAT", 41: "MRK", 42: "LUK", 43: "JHN", 44: "ACT",
            45: "ROM", 46: "1CO", 47: "2CO", 48: "GAL", 49: "EPH",
            50: "PHP", 51: "COL", 52: "1TH", 53: "2TH", 54: "1TI",
            55: "2TI", 56: "TIT", 57: "PHM", 58: "HEB", 59: "JAS",
            60: "1PE", 61: "2PE", 62: "1JN", 63: "2JN", 64: "3JN",
            65: "JUD", 66: "REV",
        }
        for row in rows:
            field = row.get("field") if isinstance(row, dict) else None
            if not isinstance(field, list) or len(field) < 5:
                continue
            try:
                _id, book_num, ch, vn, text = field[:5]
                book_num = int(book_num)
                ch = int(ch)
                vn = int(vn)
                text = str(text).strip()
            except (TypeError, ValueError):
                continue
            usfm = BOOK_NUM_TO_USFM.get(book_num)
            if usfm and ch and vn and text:
                out[f"{usfm}.{ch}.{vn}"] = text
        if out:
            return out

    # Form (c): top-level list
    if isinstance(data, list):
        for v in data:
            if not isinstance(v, dict):
                continue
            book_raw = v.get("book_name") or v.get("book") or v.get("book_id") or ""
            usfm = _book_to_usfm(str(book_raw)) or str(book_raw).upper()
            cn = v.get("chapter")
            vn = v.get("verse")
            text = (v.get("text") or "").strip()
            if usfm and cn and vn and text:
                out[f"{usfm}.{cn}.{vn}"] = text

    return out


def _download_chapter(book: str, chapter: int, cache_path: Path) -> dict | None:
    """Fetch one chapter of WEB from bible-api.com. Cache locally.
    Returns parsed JSON dict, or None on failure. Sleeps for the
    bible-api rate limit between fresh fetches (cached hits don't sleep).
    """
    if cache_path.exists():
        try:
            return json.loads(cache_path.read_text(encoding="utf-8"))
        except Exception:
            cache_path.unlink(missing_ok=True)
    api_book = USFM_TO_API_BOOK.get(book)
    if not api_book:
        return None
    import urllib.parse as _u
    path = _u.quote(f"{api_book} {chapter}")
    url = f"{BIBLE_API_BASE}/{path}?translation=web"
    data = _fetch(url)
    # Polite delay between fresh requests so we don't trigger 429s.
    time.sleep(_BIBLE_API_DELAY_S)
    if data is None:
        return None
    try:
        parsed = json.loads(data)
    except Exception:
        return None
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(parsed, ensure_ascii=False, indent=2),
                          encoding="utf-8")
    return parsed


def load_web_nt(refresh: bool) -> dict[str, str]:
    """Returns {ref: english_text} for every WEB NT verse.

    Walks bible-api.com chapter by chapter. ~260 chapters; each cached
    on disk so re-runs are instant. ~3 min total on first run.
    """
    WEB_DIR.mkdir(parents=True, exist_ok=True)
    out: dict[str, str] = {}
    total_chapters = sum(NT_CHAPTER_COUNTS.values())
    done = 0

    for book in NT_BOOKS:
        n_ch = NT_CHAPTER_COUNTS.get(book, 0)
        if n_ch == 0:
            continue
        for ch in range(1, n_ch + 1):
            done += 1
            cache_path = WEB_DIR / book / f"{ch:03d}.json"
            if refresh and cache_path.exists():
                cache_path.unlink()
            parsed = _download_chapter(book, ch, cache_path)
            if parsed is None:
                print(f"    {book} {ch}: failed (skipping)")
                continue
            for v in parsed.get("verses") or []:
                vn = v.get("verse")
                text = (v.get("text") or "").strip()
                if vn and text:
                    out[f"{book}.{ch}.{vn}"] = text
            if done % 20 == 0:
                print(f"    progress: {done}/{total_chapters} chapters, "
                      f"{len(out)} verses so far")

    if not out:
        print()
        print("    bible-api.com fetches all failed.")
        print(f"    Manual fallback:")
        print(f"      1. Download {WEB_MANUAL_URL} on Windows, unzip,")
        print(f"         and put files into {WEB_DIR.relative_to(REPO_ROOT)}/")
        print(f"      2. Or scrape WEB from bible.com via scripts/ingest/youversion.py")
        print(f"         (translation id 206)")
    return out


# ============================================================
# Pairing
# ============================================================

def align(awing: dict[str, str], english: dict[str, str]) -> list[dict]:
    """Pair by exact reference. Returns list sorted by canonical book order."""
    book_order = {b: i for i, b in enumerate(NT_BOOKS)}
    paired = []
    for ref, awtext in awing.items():
        if ref not in english:
            continue
        try:
            book, ch, vn = ref.split(".")
        except ValueError:
            continue
        paired.append({
            "ref": ref,
            "book": book,
            "chapter": int(ch),
            "verse": int(vn),
            "awing": awtext,
            "english": english[ref],
            "awing_word_count": len(awtext.split()),
            "english_word_count": len(english[ref].split()),
        })
    paired.sort(key=lambda p: (book_order.get(p["book"], 999),
                                p["chapter"], p["verse"]))
    return paired


# ============================================================
# Status report
# ============================================================

def cmd_status() -> int:
    print("Awing corpus:")
    awing = load_awing_nt()
    print(f"  {len(awing)} verses on disk")
    if awing:
        sample_ref = next(iter(awing))
        print(f"  sample: {sample_ref}: {awing[sample_ref][:80]}...")
    print()
    print("English WEB cache:")
    cached = sorted(WEB_DIR.glob("*.json")) if WEB_DIR.exists() else []
    print(f"  {len(cached)} books cached at {WEB_DIR.relative_to(REPO_ROOT)}")
    print()
    if PARALLEL_OUT.exists():
        try:
            data = json.loads(PARALLEL_OUT.read_text(encoding="utf-8"))
            print(f"Parallel file: {PARALLEL_OUT.relative_to(REPO_ROOT)}")
            print(f"  {len(data)} verse pairs")
        except Exception:
            pass
    return 0


# ============================================================
# Main
# ============================================================

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--refresh-english", action="store_true",
                    help="Re-download English WEB NT even if cached.")
    ap.add_argument("--status", action="store_true",
                    help="Show what's on disk and exit.")
    args = ap.parse_args()

    if args.status:
        return cmd_status()

    print("Loading Awing NT from local corpus...")
    awing = load_awing_nt()
    print(f"  {len(awing)} verses")
    if not awing:
        print("ERROR: no Awing verses found. Run scripts/ingest/youversion.py first.")
        return 1
    print()

    print("Loading English WEB NT (downloads on first run)...")
    english = load_web_nt(refresh=args.refresh_english)
    print(f"  {len(english)} verses")
    if not english:
        print("ERROR: no English NT loaded. Network issue?")
        return 1
    print()

    print("Aligning by reference...")
    paired = align(awing, english)
    print(f"  {len(paired)} parallel verse pairs")
    print()

    PARALLEL_OUT.parent.mkdir(parents=True, exist_ok=True)
    PARALLEL_OUT.write_text(
        json.dumps(paired, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote: {PARALLEL_OUT.relative_to(REPO_ROOT)}")
    print()

    # Coverage summary
    covered_books = sorted({p["book"] for p in paired})
    print(f"Books covered: {len(covered_books)}/27")
    missing_books = [b for b in NT_BOOKS if b not in covered_books]
    if missing_books:
        print(f"  Missing: {', '.join(missing_books)}")

    # Length distribution (useful for downstream curation)
    aw_counts = [p["awing_word_count"] for p in paired]
    en_counts = [p["english_word_count"] for p in paired]
    print()
    print("Awing word-count distribution:")
    print(f"  min={min(aw_counts)}  median={sorted(aw_counts)[len(aw_counts)//2]}  max={max(aw_counts)}")
    print(f"  short (≤8 words):    {sum(1 for c in aw_counts if c <= 8):4d}")
    print(f"  medium (9-20 words): {sum(1 for c in aw_counts if 9 <= c <= 20):4d}")
    print(f"  long (>20 words):    {sum(1 for c in aw_counts if c > 20):4d}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
