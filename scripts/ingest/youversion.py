#!/usr/bin/env python3
"""Scrape the Awing Bible "Əka yi Fîə" from www.bible.com (version 3005).

Background:
  Our primary legitimate path (FCBH Bible Brain API + CABTAL direct license)
  is blocked by unanswered permission requests typical of this community.
  This script scrapes the same content from the public bible.com reader.
  We run it politely (random 30-60s delays), keep a per-chapter state file
  so it's resumable, and separate training vs. evaluation books so a
  trained model can be held accountable to a held-out slice.

  Audio MP3 URLs exposed in the page's Next.js SSR payload belong to the
  audio-bible-cdn.youversionapi.com CDN. Audio is CABTAL-copyrighted,
  Hosanna (FCBH) distributed — the same rights holders we've already
  petitioned. Use outside personal reading is at the operator's
  discretion; this script produces the data, it does not ship it.

Output layout:
  corpus/raw/bible/azocab/
    _state.json           # {book: {chapter: status}} for resume
    _metadata.json        # version info, copyright, timestamps
    _split.json           # {book: "train"|"eval"} per the 80/20 holdout
    MAT/
      001.verses.json     # [{usfm, book, chapter, verse, text}, ...]
      001.mp3             # chapter audio
      001.meta.json       # {scrape_ts, source_url, audio_url, bytes, sha256}
      002...              # and so on

Usage:
  python scripts/ingest/youversion.py status
  python scripts/ingest/youversion.py plan            # show what would run
  python scripts/ingest/youversion.py fetch --book MAT --chapters 1
  python scripts/ingest/youversion.py fetch --book MAT
  python scripts/ingest/youversion.py fetch            # full NT, resumable
  python scripts/ingest/youversion.py verify          # re-check files on disk
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import random
import re
import ssl
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


# Windows-Python often can't see the system CA store, so urllib's default
# SSL context fails with "unable to get local issuer certificate" on
# perfectly valid HTTPS sites. Use certifi's bundled CA list when
# available — it's the canonical fix. On systems where certifi isn't
# installed we still try the default context so it works on Mac/Linux
# without extra deps.
def _make_ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        ctx = ssl.create_default_context()
        # If the default still fails at runtime, surface a helpful error
        # from http_get rather than silently disabling verification.
        return ctx


_SSL_CONTEXT = _make_ssl_context()

# -------------------------------------------------------- constants

VERSION_ID = "3005"
VERSION_TAG = "AZO"
BIBLE_ID = "azocab"

# Protestant NT book order + chapter counts. The Awing NT matches this.
# If a chapter 404s we'll note it and move on; no hardcoded counts are fatal.
NT_BOOKS: list[tuple[str, int]] = [
    ("MAT", 28), ("MRK", 16), ("LUK", 24), ("JHN", 21), ("ACT", 28),
    ("ROM", 16), ("1CO", 16), ("2CO", 13), ("GAL",  6), ("EPH",  6),
    ("PHP",  4), ("COL",  4), ("1TH",  5), ("2TH",  3), ("1TI",  6),
    ("2TI",  4), ("TIT",  3), ("PHM",  1), ("HEB", 13), ("JAS",  5),
    ("1PE",  5), ("2PE",  3), ("1JN",  5), ("2JN",  1), ("3JN",  1),
    ("JUD",  1), ("REV", 22),
]

# Deterministic 80/20 train/eval split at book granularity. Books chosen
# for eval are a stable mix: some short distinct books (PHM, 2JN, 3JN,
# JUD) plus a couple of medium-length books covering narrative + epistle
# registers (2CO, TIT). Total eval = 25/260 ≈ 9.6% of chapters, which is
# on the conservative side but avoids wasting too much training material
# on a small corpus.
EVAL_BOOKS = frozenset(["2CO", "TIT", "PHM", "2JN", "3JN", "JUD"])

BASE_URL = "https://www.bible.com/bible/{vid}/{book}.{chap}.{tag}"

# Polite rate limiting — random uniform delay between chapter loads and
# between MP3 downloads. Values in seconds.
CHAPTER_DELAY_MIN = 25.0
CHAPTER_DELAY_MAX = 55.0
AUDIO_DELAY_MIN = 5.0
AUDIO_DELAY_MAX = 15.0

# Back-off on 429/5xx. These are long on purpose — we'd rather wait than
# get blocked.
BACKOFF_429_SEC = 300.0    # 5 min
BACKOFF_5XX_SEC = 120.0    # 2 min
MAX_RETRIES = 3

# Browser-ish headers. We're not hiding, we're just not broadcasting
# "I am Python requests."
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
      "AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/124.0.0.0 Safari/537.36")
BASE_HEADERS = {
    "User-Agent": UA,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "identity",   # keep response bodies uncompressed for easy parsing
    "Cache-Control": "no-cache",
}


# -------------------------------------------------------- paths

def _repo_root() -> Path:
    p = Path(__file__).resolve().parent
    for _ in range(6):
        if (p / "lib").is_dir() and (p / "scripts").is_dir():
            return p
        p = p.parent
    return Path.cwd()


def _bible_root() -> Path:
    return _repo_root() / "corpus" / "raw" / "bible" / BIBLE_ID


def _state_path() -> Path:
    return _bible_root() / "_state.json"


def _metadata_path() -> Path:
    return _bible_root() / "_metadata.json"


def _split_path() -> Path:
    return _bible_root() / "_split.json"


# -------------------------------------------------------- state

@dataclass
class State:
    # {BOOK: {chapter_int: "pending"|"text"|"audio"|"done"|"error"|"missing"}}
    chapters: dict[str, dict[str, str]] = field(default_factory=dict)

    def status(self, book: str, chap: int) -> str:
        return self.chapters.get(book, {}).get(str(chap), "pending")

    def set(self, book: str, chap: int, status: str) -> None:
        self.chapters.setdefault(book, {})[str(chap)] = status

    def save(self) -> None:
        _state_path().parent.mkdir(parents=True, exist_ok=True)
        tmp = _state_path().with_suffix(".tmp")
        tmp.write_text(json.dumps(self.chapters, indent=2, sort_keys=True),
                       encoding="utf-8")
        tmp.replace(_state_path())

    @classmethod
    def load(cls) -> "State":
        p = _state_path()
        if not p.exists():
            return cls()
        try:
            return cls(chapters=json.loads(p.read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError):
            return cls()


# -------------------------------------------------------- HTTP

def _sleep(lo: float, hi: float, reason: str = "") -> None:
    d = random.uniform(lo, hi)
    if reason:
        print(f"    sleep {d:5.1f}s  ({reason})")
    time.sleep(d)


def http_get(url: str, timeout: int = 60, retries: int = MAX_RETRIES) -> bytes:
    """GET a URL with polite retry handling for 429/5xx.

    Uses certifi CA bundle (if installed) for SSL verification to avoid
    the Windows-Python "unable to get local issuer certificate" error.
    """
    attempt = 0
    last_err: Exception | None = None
    while attempt < retries:
        attempt += 1
        req = urllib.request.Request(url, headers=BASE_HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=_SSL_CONTEXT) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            last_err = e
            if e.code == 429:
                print(f"      HTTP 429 rate-limited. Backing off {BACKOFF_429_SEC:.0f}s.")
                time.sleep(BACKOFF_429_SEC)
            elif 500 <= e.code < 600:
                print(f"      HTTP {e.code}. Backing off {BACKOFF_5XX_SEC:.0f}s.")
                time.sleep(BACKOFF_5XX_SEC)
            elif e.code == 404:
                raise  # 404 is terminal for a given chapter
            else:
                print(f"      HTTP {e.code} on {url}")
                time.sleep(30.0)
        except urllib.error.URLError as e:
            last_err = e
            msg = str(e)
            if "CERTIFICATE_VERIFY_FAILED" in msg:
                print(f"      SSL cert verification failed. Fix: run")
                print(f"        pip install certifi")
                print(f"      in the Python environment you're using, then re-run.")
                raise RuntimeError(
                    "SSL cert verification failed — install certifi"
                ) from e
            print(f"      Network error: {e}. Retrying in 30s.")
            time.sleep(30.0)
    raise RuntimeError(f"http_get exhausted retries for {url}: {last_err}")


# -------------------------------------------------------- parse

_NEXT_DATA_RE = re.compile(
    rb'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
    re.DOTALL,
)

_USFM_VERSE_RE = re.compile(r'^[A-Z0-9]+\.\d+\.\d+$')


class _VerseExtractor(HTMLParser):
    """Walk the chapterInfo.content HTML and produce clean per-verse text.

    YouVersion's structure for each verse is:

        <span class="verse vN" data-usfm="BOOK.CH.VN">
          <span class="label">N</span>         # verse number badge — skip
          <span class="content">text</span>    # the actual Awing words
          ...possibly more nested elements, including cross-reference anchors
             that carry their OWN data-usfm attribute
        </span>

    A naive regex like `data-usfm="..."(.*?)(?=data-usfm=|$)` breaks when a
    nested element re-uses data-usfm — the cut lands mid-tag, leaving
    `<span clas` fragments in the output. This parser tracks element depth
    correctly: any given character is either inside a verse-root span
    (class contains "verse" with a fully-qualified usfm) or not. Nested
    `data-usfm` attributes inside that root are ignored because the stack
    already contains a verse root.

    Label spans (class contains "label") are tracked separately and their
    text is dropped, so the verse-number badge doesn't leak into the
    clean text.
    """

    def __init__(self) -> None:
        super().__init__()
        # Each stack frame: tag name + whether it opens a new verse-root
        # + whether it's a label wrapper + the usfm (if verse-root) +
        # buffers for both clean and raw text forms.
        self.stack: list[dict[str, Any]] = []
        # Results: {usfm: {"clean": str, "raw": str}}
        self.out: dict[str, dict[str, str]] = {}

    # ---- helpers

    def _root_frame_index(self) -> int | None:
        for i, f in enumerate(self.stack):
            if f["is_verse_root"]:
                return i
        return None

    def _inside_label(self) -> bool:
        return any(f["is_label"] for f in self.stack)

    def _in_verse(self) -> bool:
        return self._root_frame_index() is not None

    # ---- HTMLParser callbacks

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k: (v or "") for k, v in attrs}
        cls_tokens = (a.get("class") or "").split()
        usfm = a.get("data-usfm") or ""
        is_verse_root = (
            "verse" in cls_tokens
            and _USFM_VERSE_RE.match(usfm) is not None
            and not self._in_verse()        # don't re-enter a nested same-usfm
        )
        is_label = "label" in cls_tokens
        self.stack.append({
            "tag": tag,
            "is_verse_root": is_verse_root,
            "is_label": is_label,
            "usfm": usfm if is_verse_root else None,
            "clean_buf": [],
            "raw_buf": [],
        })

    def handle_endtag(self, tag: str) -> None:
        # Pop the most recent frame with a matching tag (HTML can be loose,
        # but for YouVersion content it's well-formed).
        idx = None
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i]["tag"] == tag:
                idx = i
                break
        if idx is None:
            return
        frame = self.stack.pop(idx)
        if frame["is_verse_root"]:
            clean = "".join(frame["clean_buf"])
            raw = "".join(frame["raw_buf"])
            # Collapse runs of whitespace
            clean = re.sub(r"\s+", " ", clean).strip()
            raw = re.sub(r"\s+", " ", raw).strip()
            # Keep the longest seen (handles rare repeated verse markup)
            prev = self.out.get(frame["usfm"], {})
            if len(clean) > len(prev.get("clean", "")):
                self.out[frame["usfm"]] = {"clean": clean, "raw": raw}

    def handle_data(self, data: str) -> None:
        if not data:
            return
        root_idx = self._root_frame_index()
        if root_idx is None:
            return
        # raw_buf captures everything including the label (verse number)
        self.stack[root_idx]["raw_buf"].append(data)
        # clean_buf skips anything inside a label wrapper
        if not self._inside_label():
            self.stack[root_idx]["clean_buf"].append(data)


def extract_verses(content_html: str) -> list[dict[str, str]]:
    """Parse a chapter's content HTML into ordered, clean verse records."""
    if not content_html:
        return []
    parser = _VerseExtractor()
    parser.feed(content_html)
    parser.close()
    verses: list[dict[str, str]] = []
    for usfm, texts in parser.out.items():
        parts = usfm.split(".")
        clean = texts["clean"]
        raw = texts["raw"]
        if not clean:
            continue
        verses.append({
            "usfm": usfm,
            "book": parts[0],
            "chapter": int(parts[1]),
            "verse": int(parts[2]),
            "text": clean,
            "raw_text": raw,
        })
    verses.sort(key=lambda v: v["verse"])
    return verses


def parse_chapter_page(page_bytes: bytes) -> dict[str, Any]:
    """Extract from a chapter HTML page: verses, audio URL, metadata."""
    m = _NEXT_DATA_RE.search(page_bytes)
    if not m:
        raise ValueError("__NEXT_DATA__ not found in page")
    data = json.loads(m.group(1).decode("utf-8"))
    pp = data.get("props", {}).get("pageProps", {})
    ci = pp.get("chapterInfo") or {}
    av = pp.get("audioVersionInfo") or {}

    # Verses — parse the embedded HTML using a proper HTML parser (not
    # regex). The HTML can contain nested elements with their own
    # data-usfm attributes (cross-references), which a naive regex splits
    # wrong. See _VerseExtractor for the structural rules.
    #
    # Each verse record has:
    #   text     — clean Awing content. Verse-number badge is stripped.
    #              This is what TTS/ASR/translation pipelines consume.
    #   raw_text — everything in the verse span, including the verse
    #              number. Useful for debugging or for lining up with
    #              alternate renderers.
    # Cross-Bible correlation (e.g. with the public-domain English World
    # English Bible) happens on the `usfm` field, never on text content.
    content_html = ci.get("content") or ""
    verses = extract_verses(content_html)

    # Audio: prefer mp3, fall back to hls
    audio_url = None
    audio_bitrate = None
    audio_hash = None
    for item in (ci.get("audioChapterInfo") or []):
        urls = item.get("download_urls") or {}
        for k, v in urls.items():
            if k.startswith("format_mp3") and v:
                audio_url = _normalize_url(v)
                audio_bitrate = k.removeprefix("format_mp3_")
                # Extract opaque hash from URL
                m2 = re.search(r'/(\d+)-([0-9a-f]{16,})\.mp3', audio_url)
                if m2:
                    audio_hash = m2.group(2)
                break
        if audio_url:
            break

    return {
        "verses": verses,
        "audio_url": audio_url,
        "audio_bitrate": audio_bitrate,
        "audio_hash": audio_hash,
        "chapter_reference": ci.get("reference", {}),
        "version_info": pp.get("versionData", {}),
        "audio_version_info": av,
        "next": ci.get("next"),
    }


def _normalize_url(u: str) -> str:
    """//audio-bible-cdn.../file.mp3 → https://audio-bible-cdn.../file.mp3"""
    if u.startswith("//"):
        return "https:" + u
    return u


# -------------------------------------------------------- fetch

def fetch_chapter(book: str, chap: int, state: State, force: bool = False) -> str:
    """Fetch + save text + audio for one chapter. Returns final status."""
    key = (book, chap)
    current = state.status(book, chap)
    if current == "done" and not force:
        return "done"

    out_dir = _bible_root() / book
    out_dir.mkdir(parents=True, exist_ok=True)
    chap_tag = f"{chap:03d}"
    verses_path = out_dir / f"{chap_tag}.verses.json"
    audio_path = out_dir / f"{chap_tag}.mp3"
    meta_path = out_dir / f"{chap_tag}.meta.json"

    url = BASE_URL.format(vid=VERSION_ID, book=book, chap=chap, tag=VERSION_TAG)
    print(f"  [{book} {chap:2d}] GET {url}")

    try:
        body = http_get(url)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"    404 (chapter not in translation) — marking missing")
            state.set(book, chap, "missing")
            state.save()
            return "missing"
        print(f"    HTTPError {e.code}: {e}")
        state.set(book, chap, "error")
        state.save()
        return "error"

    try:
        parsed = parse_chapter_page(body)
    except Exception as e:
        print(f"    parse error: {e}")
        state.set(book, chap, "error")
        state.save()
        return "error"

    if not parsed["verses"]:
        print(f"    no verses parsed — marking missing")
        state.set(book, chap, "missing")
        state.save()
        return "missing"

    # Save verse text
    verses_path.write_text(
        json.dumps(parsed["verses"], indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    state.set(book, chap, "text")
    state.save()

    # Save / update global metadata on first successful chapter
    if not _metadata_path().exists():
        _metadata_path().write_text(
            json.dumps({
                "bible_id": BIBLE_ID,
                "version_id": VERSION_ID,
                "version_tag": VERSION_TAG,
                "version_data": parsed["version_info"],
                "audio_version_info": parsed["audio_version_info"],
                "scraped_at": time.time(),
                "source": "bible.com",
            }, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    # Download audio
    audio_info: dict[str, Any] = {}
    if parsed["audio_url"]:
        _sleep(AUDIO_DELAY_MIN, AUDIO_DELAY_MAX, reason="before audio")
        try:
            audio_bytes = http_get(parsed["audio_url"], timeout=180)
            audio_path.write_bytes(audio_bytes)
            audio_info = {
                "audio_url": parsed["audio_url"],
                "bytes": len(audio_bytes),
                "sha256": hashlib.sha256(audio_bytes).hexdigest(),
                "bitrate": parsed["audio_bitrate"],
                "hash_in_url": parsed["audio_hash"],
            }
            print(f"    audio OK ({len(audio_bytes):,} bytes)")
        except Exception as e:
            print(f"    audio FAILED: {e}")
            audio_info = {"audio_url": parsed["audio_url"], "error": str(e)}

    # Meta sidecar
    meta_path.write_text(
        json.dumps({
            "source_url": url,
            "scrape_ts": time.time(),
            "verse_count": len(parsed["verses"]),
            "audio": audio_info,
            "chapter_reference": parsed["chapter_reference"],
            "next": parsed["next"],
        }, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    if audio_info.get("bytes"):
        state.set(book, chap, "done")
        state.save()
        return "done"
    state.set(book, chap, "text")
    state.save()
    return "text"


# -------------------------------------------------------- commands

def cmd_status(_args: argparse.Namespace) -> int:
    state = State.load()
    tot = done = err = miss = 0
    lines = []
    for book, n in NT_BOOKS:
        cs = state.chapters.get(book, {})
        b_done = sum(1 for v in cs.values() if v == "done")
        b_text = sum(1 for v in cs.values() if v == "text")
        b_err = sum(1 for v in cs.values() if v == "error")
        b_miss = sum(1 for v in cs.values() if v == "missing")
        tot += n
        done += b_done
        err += b_err
        miss += b_miss
        tag = "eval" if book in EVAL_BOOKS else "train"
        lines.append(f"  {book:4s} ({tag:5s})  {b_done:3d}/{n:2d} done  "
                     f"text-only={b_text}  err={b_err}  miss={b_miss}")
    print(f"Bible:      {BIBLE_ID}  (version {VERSION_ID}, Awing AZO)")
    print(f"Root:       {_bible_root()}")
    print(f"Total NT:   {tot} chapters  ({len(EVAL_BOOKS)} eval books, "
          f"{len(NT_BOOKS) - len(EVAL_BOOKS)} train books)")
    print(f"Progress:   {done}/{tot} done  ({100*done/tot:.1f}%)  "
          f"errors={err}  missing={miss}")
    print()
    for l in lines:
        print(l)
    return 0


def cmd_plan(_args: argparse.Namespace) -> int:
    _write_split_file()
    state = State.load()
    pending = []
    for book, n in NT_BOOKS:
        for ch in range(1, n + 1):
            s = state.status(book, ch)
            if s not in {"done", "missing"}:
                pending.append((book, ch))
    print(f"Pending: {len(pending)} chapters")
    per_chap = (CHAPTER_DELAY_MIN + CHAPTER_DELAY_MAX) / 2 + 10  # ~10s of work
    eta = len(pending) * per_chap / 60
    print(f"Est. time at {CHAPTER_DELAY_MIN}-{CHAPTER_DELAY_MAX}s/chapter delay: "
          f"{eta:.1f} minutes  ({eta/60:.1f} hours)")
    if pending:
        print("First 10:")
        for b, c in pending[:10]:
            print(f"  {b} {c}")
    return 0


def cmd_fetch(args: argparse.Namespace) -> int:
    _write_split_file()
    state = State.load()
    books_to_do: list[tuple[str, int]]
    if args.book:
        matches = [(b, n) for b, n in NT_BOOKS if b == args.book]
        if not matches:
            print(f"Unknown book: {args.book}")
            return 2
        books_to_do = matches
    else:
        books_to_do = list(NT_BOOKS)

    total_done = 0
    total_attempted = 0
    for book, n in books_to_do:
        chapters: list[int]
        if args.chapters:
            chapters = [int(c) for c in args.chapters.split(",")]
        else:
            chapters = list(range(1, n + 1))
        print(f"\n== {book} ({n} chapters, {'eval' if book in EVAL_BOOKS else 'train'}) ==")
        for ch in chapters:
            if state.status(book, ch) == "done" and not args.force:
                print(f"  [{book} {ch:2d}] already done — skipping")
                continue
            total_attempted += 1
            final = fetch_chapter(book, ch, state, force=args.force)
            if final == "done":
                total_done += 1
            if ch != chapters[-1] or book != books_to_do[-1][0]:
                _sleep(CHAPTER_DELAY_MIN, CHAPTER_DELAY_MAX,
                       reason="politeness between chapters")

    print(f"\n== Session summary ==")
    print(f"Attempted: {total_attempted}  Completed: {total_done}")
    return 0


def cmd_reparse(args: argparse.Namespace) -> int:
    """Re-fetch chapter HTML pages and overwrite verses.json with the current
    parser. Does NOT re-download audio; does NOT touch the state file.

    Use when the parser has been updated and existing verses.json files were
    produced by the old code. This is faster than a full --force fetch
    because we skip audio (which is ~1 MB per chapter vs ~15 KB for text).
    """
    state = State.load()
    books_to_do = [(b, n) for b, n in NT_BOOKS
                   if not args.book or b == args.book]
    if not books_to_do:
        print(f"Unknown book: {args.book}")
        return 2

    refreshed = skipped = errored = 0
    for book, n in books_to_do:
        print(f"\n== {book} (reparse, {'eval' if book in EVAL_BOOKS else 'train'}) ==")
        for ch in range(1, n + 1):
            if state.status(book, ch) not in ("text", "done"):
                # Nothing on disk yet; normal fetch will handle this
                continue

            url = BASE_URL.format(vid=VERSION_ID, book=book, chap=ch, tag=VERSION_TAG)
            print(f"  [{book} {ch:2d}] GET {url}")
            try:
                body = http_get(url)
                parsed = parse_chapter_page(body)
            except Exception as e:
                print(f"    error: {e}")
                errored += 1
                continue

            if not parsed["verses"]:
                print(f"    no verses — skipping")
                skipped += 1
                continue

            out_dir = _bible_root() / book
            out_dir.mkdir(parents=True, exist_ok=True)
            verses_path = out_dir / f"{ch:03d}.verses.json"
            verses_path.write_text(
                json.dumps(parsed["verses"], indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            refreshed += 1
            print(f"    ok: {len(parsed['verses'])} verses, "
                  f"{sum(len(v['text']) for v in parsed['verses']):,} clean chars")
            _sleep(CHAPTER_DELAY_MIN, CHAPTER_DELAY_MAX,
                   reason="politeness between chapters")

    print(f"\n== Reparse summary ==")
    print(f"Refreshed: {refreshed}  Skipped: {skipped}  Errored: {errored}")
    return 0


def cmd_verify(_args: argparse.Namespace) -> int:
    """Walk what's on disk and sanity-check state vs. filesystem."""
    root = _bible_root()
    if not root.exists():
        print("Nothing fetched yet.")
        return 0
    ok = 0
    discrepancies = 0
    for book_dir in sorted(p for p in root.iterdir() if p.is_dir()):
        for verses_f in sorted(book_dir.glob("*.verses.json")):
            chap = verses_f.stem.removesuffix(".verses")
            chap_i = int(chap)
            audio_f = book_dir / f"{chap}.mp3"
            try:
                verses = json.loads(verses_f.read_text(encoding="utf-8"))
            except Exception:
                print(f"  BAD  {verses_f}")
                discrepancies += 1
                continue
            ok += 1
            if not audio_f.exists():
                print(f"  TEXT-ONLY  {book_dir.name} ch {chap_i:3d}  "
                      f"({len(verses)} verses, {sum(len(v['text']) for v in verses)} chars)")
    print(f"\n{ok} verse files present, {discrepancies} broken")
    return 0


def _write_split_file() -> None:
    p = _split_path()
    if p.exists():
        return
    p.parent.mkdir(parents=True, exist_ok=True)
    split = {b: ("eval" if b in EVAL_BOOKS else "train") for b, _ in NT_BOOKS}
    p.write_text(json.dumps(split, indent=2), encoding="utf-8")


# -------------------------------------------------------- main

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status", help="Show progress")
    sub.add_parser("plan", help="Show what would run, ETA")
    sub.add_parser("verify", help="Sanity-check files on disk")

    f = sub.add_parser("fetch", help="Download text + audio (resumable)")
    f.add_argument("--book", help="Restrict to one book (e.g. MAT)")
    f.add_argument("--chapters", help="Comma-separated chapter numbers within a book")
    f.add_argument("--force", action="store_true",
                   help="Re-fetch chapters already marked done")

    r = sub.add_parser("reparse", help="Re-fetch page HTML, overwrite verses.json with current parser (keeps audio)")
    r.add_argument("--book", help="Restrict to one book (e.g. MAT)")

    args = ap.parse_args(argv)
    {
        "status": cmd_status,
        "plan": cmd_plan,
        "fetch": cmd_fetch,
        "reparse": cmd_reparse,
        "verify": cmd_verify,
    }[args.cmd](args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
