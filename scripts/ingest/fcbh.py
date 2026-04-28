#!/usr/bin/env python3
"""Ingest Bible Brain (FCBH) content into corpus/raw/bible/.

This script turns a valid Bible Brain API key + a bible_id (e.g. `azocab`
for Awing) into a tidy per-verse `(text, audio, timestamps)` corpus
layout on disk.

Usage:
  # First run — probe what's available for Awing
  python scripts/ingest/fcbh.py probe --bible azocab

  # Check per-Bible copyright (critical — resolves per-translation
  # restrictions that the generic FCBH license Section 4 mentions)
  python scripts/ingest/fcbh.py copyright --bible azocab

  # Download all available content for azocab
  python scripts/ingest/fcbh.py fetch --bible azocab

  # Or a specific book
  python scripts/ingest/fcbh.py fetch --bible azocab --book MAT

Key must be provided via:
  --key <KEY>       (explicit flag)
  $FCBH_API_KEY     (environment variable; preferred for scripts)
  ~/.fcbh_key       (file; first line = key; useful for local dev)

License sanity checks built in:
  Before ANY download, this script calls /bibles/{id}/copyright and
  displays the licensor restrictions to the console. If the response
  indicates a licensor that restricts development-partner distribution,
  the script refuses to proceed and tells you what to do (likely: get
  direct permission from that licensor).

Output layout:
  corpus/raw/bible/{bible_id}/
    manifest.json                      # overall bible metadata
    copyright.json                     # /copyright response verbatim
    {book_id}/
      metadata.json                    # book info (chapters, etc.)
      chapter_{N:03d}.txt              # plaintext verses, one per line
      chapter_{N:03d}.verses.json      # per-verse {verse_number, text}
      chapter_{N:03d}.mp3              # audio (if available)
      chapter_{N:03d}.timestamps.json  # verse-aligned timestamps
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


API_BASE = "https://4.dbt.io/api"
API_V = "4"


# ------------------------------------------------------------------ key

def load_api_key(flag_value: str | None) -> str:
    """Resolve the FCBH API key from CLI flag > env var > ~/.fcbh_key."""
    if flag_value:
        return flag_value.strip()
    env = os.environ.get("FCBH_API_KEY")
    if env:
        return env.strip()
    keyfile = Path.home() / ".fcbh_key"
    if keyfile.is_file():
        k = keyfile.read_text(encoding="utf-8").strip()
        if k:
            return k
    sys.stderr.write(
        "ERROR: No Bible Brain API key found. Provide one of:\n"
        "  --key <KEY>\n"
        "  $FCBH_API_KEY environment variable\n"
        "  ~/.fcbh_key (first line = key)\n"
        "Request a free key at https://4.dbt.io/api_key/request\n"
    )
    sys.exit(2)


# ------------------------------------------------------------------ http

def get_json(path: str, key: str, **params: Any) -> dict[str, Any]:
    """GET a Bible Brain endpoint, return parsed JSON.

    Automatically adds `v` (API version) and `key` params. Raises on
    non-200 with the FCBH error body included.
    """
    qs = dict(params)
    qs.setdefault("v", API_V)
    qs["key"] = key
    url = f"{API_BASE}{path}?{urllib.parse.urlencode(qs)}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = (e.read() or b"").decode("utf-8", errors="replace")
        raise RuntimeError(
            f"FCBH API error {e.code} on {path}: {body[:500]}"
        ) from e


def download_file(url: str, dest: Path, timeout: int = 120) -> int:
    """Download `url` to `dest`, streaming. Returns bytes written."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"Accept": "*/*"})
    total = 0
    with urllib.request.urlopen(req, timeout=timeout) as resp, \
            open(dest, "wb") as f:
        while True:
            chunk = resp.read(64 * 1024)
            if not chunk:
                break
            f.write(chunk)
            total += len(chunk)
    return total


# ------------------------------------------------------------------ commands

def cmd_probe(args: argparse.Namespace, key: str) -> int:
    """Show what's available for a bible_id without downloading anything."""
    bid = args.bible
    print(f"Probing Bible Brain for bible_id={bid}\n")

    # Bible metadata
    meta = get_json(f"/bibles/{bid}", key)
    data = meta.get("data", meta)
    # The shape can be {data: {...}} or {...} depending on endpoint.
    print(f"  name:       {data.get('vname') or data.get('name')}")
    print(f"  language:   {data.get('language') or data.get('language_name')}")
    print(f"  lang code:  {data.get('iso') or data.get('language_code')}")
    print(f"  country:    {data.get('country')}")
    print(f"  date:       {data.get('date')}")

    # Filesets — this is the critical piece: what formats exist
    filesets = data.get("filesets", {})
    print(f"\n  Filesets available:")
    if not filesets:
        print("    (none)")
    else:
        for env_key, fslist in filesets.items():
            print(f"    [{env_key}]")
            for fs in fslist or []:
                print(f"      - {fs.get('id'):30s}  type={fs.get('type'):15}  "
                      f"size={fs.get('size'):10}  drama={fs.get('set_size_code')}")

    # Books coverage
    try:
        books = get_json(f"/bibles/{bid}/book", key)
        book_list = books.get("data", books)
        if isinstance(book_list, list):
            book_ids = [b.get("book_id") or b.get("id") for b in book_list]
            print(f"\n  Books covered ({len(book_ids)}):")
            print(f"    {', '.join(str(b) for b in book_ids if b)}")
    except RuntimeError as e:
        print(f"\n  Could not fetch books list: {e}")

    return 0


def cmd_copyright(args: argparse.Namespace, key: str) -> int:
    """Fetch /copyright and display licensor restrictions verbatim."""
    bid = args.bible
    print(f"Fetching copyright / licensor data for bible_id={bid}\n")
    resp = get_json(f"/bibles/{bid}/copyright", key)
    print(json.dumps(resp, indent=2, ensure_ascii=False))

    # Save next to the corpus even before full fetch, so we have the
    # receipt on disk.
    out_dir = _bible_dir(bid)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "copyright.json").write_text(
        json.dumps(resp, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"\nSaved to {out_dir / 'copyright.json'}")
    return 0


def cmd_fetch(args: argparse.Namespace, key: str) -> int:
    """Download all text + audio + timestamps for a bible_id.

    Per the Bible Brain License Section 4, the ONLY filesets we may copy
    to local disk (outside live runtime API consumption) are those
    exposed via /download endpoint — i.e. flagged for "Limited Content
    Use." We intersect the bible's filesets with the /download/list
    allowlist and refuse to fetch anything else.
    """
    bid = args.bible

    # Step 1 — sanity check licensor restrictions
    print(f"[1/4] Checking /bibles/{bid}/copyright ...")
    try:
        cr = get_json(f"/bibles/{bid}/copyright", key)
    except RuntimeError as e:
        print(f"  ERROR: {e}")
        return 1
    _warn_on_licensor_restrictions(cr)

    # Step 2 — list download-allowed filesets
    print(f"\n[2/4] Checking /download/list for {bid} ...")
    dl_list = get_json("/download/list", key)
    allowed = _filter_downloadable(dl_list, bid)
    if not allowed:
        print(f"  FCBH's /download/list does NOT include any filesets for {bid}.")
        print("  This means: the runtime API can serve this content, but the")
        print("  FCBH License does not permit copying it to disk outside live")
        print("  consumption. Use the runtime API path or obtain direct license")
        print("  from the translation's upstream licensor (CABTAL for azocab).")
        return 1

    print(f"  Downloadable filesets:")
    for fs in allowed:
        print(f"    - {fs.get('id'):30s}  type={fs.get('type'):15}  size={fs.get('size')}")

    # Step 3 — probe books
    print(f"\n[3/4] Listing books ...")
    books_resp = get_json(f"/bibles/{bid}/book", key)
    books = books_resp.get("data", books_resp)
    if args.book:
        books = [b for b in books if (b.get("book_id") == args.book or b.get("id") == args.book)]

    # Step 4 — per-book per-chapter download
    print(f"\n[4/4] Fetching {len(books)} book(s) ...")
    out_root = _bible_dir(bid)
    out_root.mkdir(parents=True, exist_ok=True)
    (out_root / "copyright.json").write_text(
        json.dumps(cr, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    total_chapters = 0
    for book in books:
        book_id = book.get("book_id") or book.get("id")
        if not book_id:
            continue
        n_chapters = int(book.get("number_of_chapters") or book.get("chapters") or 0)
        print(f"  {book_id} ({n_chapters} chapters)")
        book_dir = out_root / book_id
        book_dir.mkdir(parents=True, exist_ok=True)
        (book_dir / "metadata.json").write_text(
            json.dumps(book, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        for ch in range(1, n_chapters + 1):
            _fetch_chapter(bid, book_id, ch, allowed, key, book_dir, args.force)
            total_chapters += 1

    print(f"\nDone. Downloaded content for {len(books)} book(s), "
          f"{total_chapters} chapter(s) under {out_root}/")
    print("Next: run `python scripts/ingest/build_manifest.py --refresh` to re-index.")
    return 0


# ------------------------------------------------------------------ helpers

def _bible_dir(bible_id: str) -> Path:
    """corpus/raw/bible/{bible_id}/ relative to repo root."""
    here = Path(__file__).resolve()
    root = here.parent.parent.parent
    return root / "corpus" / "raw" / "bible" / bible_id


def _warn_on_licensor_restrictions(cr: dict) -> None:
    """Print the copyright response and any red flags we can detect."""
    print(f"  Copyright response:")
    data = cr.get("data", cr)
    # Shape varies; dump a readable snippet
    if isinstance(data, list):
        for d in data:
            org = d.get("organization", {})
            print(f"    - org:    {org.get('organization_name') or org.get('name')}")
            print(f"      url:    {org.get('url') or org.get('email')}")
            print(f"      role:   {d.get('role')}")
            if d.get("copyright"):
                print(f"      note:   {str(d['copyright'])[:200]}")
    else:
        # Fall back to JSON dump, truncated
        print(f"    {json.dumps(data, ensure_ascii=False)[:500]}")


def _filter_downloadable(dl_list: dict, bible_id: str) -> list[dict]:
    """From /download/list response, extract filesets belonging to bible_id."""
    data = dl_list.get("data", dl_list)
    out = []
    if isinstance(data, list):
        for fs in data:
            if (fs.get("bible_id") == bible_id or
                    fs.get("abbr") == bible_id or
                    str(fs.get("id", "")).startswith(bible_id)):
                out.append(fs)
    elif isinstance(data, dict):
        for key_, fslist in data.items():
            if not isinstance(fslist, list):
                continue
            for fs in fslist:
                if (fs.get("bible_id") == bible_id or
                        fs.get("abbr") == bible_id or
                        str(fs.get("id", "")).startswith(bible_id)):
                    out.append(fs)
    return out


def _fetch_chapter(
    bible_id: str, book_id: str, chapter: int,
    allowed_filesets: list[dict], key: str, book_dir: Path, force: bool,
) -> None:
    """Download text, audio, and timestamps for one chapter.

    For each downloadable fileset of this bible:
      - type="text_plain"  → write chapter_{N:03d}.txt
      - type="text_json"   → write chapter_{N:03d}.verses.json
      - type="audio"       → write chapter_{N:03d}.mp3
    Plus /timestamps/{fs}/{book}/{chapter} → chapter_{N:03d}.timestamps.json
    """
    tag = f"chapter_{chapter:03d}"
    have_audio = False
    have_timestamps = False
    audio_fileset_id = None

    for fs in allowed_filesets:
        fs_id = fs.get("id")
        fs_type = (fs.get("type") or "").lower()
        try:
            if "text" in fs_type:
                resp = get_json(f"/bibles/filesets/{fs_id}/{book_id}/{chapter}", key)
                verses = resp.get("data", resp)
                # Plain text
                if isinstance(verses, list):
                    (book_dir / f"{tag}.verses.json").write_text(
                        json.dumps(verses, indent=2, ensure_ascii=False),
                        encoding="utf-8",
                    )
                    (book_dir / f"{tag}.txt").write_text(
                        "\n".join((v.get("verse_text") or v.get("verse") or "")
                                  for v in verses),
                        encoding="utf-8",
                    )
            elif "audio" in fs_type:
                audio_fileset_id = fs_id
                # Ask FCBH for the download URL via /download endpoint
                try:
                    resp = get_json(
                        f"/download/{fs_id}/{book_id}/{chapter}", key
                    )
                except RuntimeError:
                    continue
                # Response commonly: {data: [{path: "https://...", ...}]}
                urls = []
                data = resp.get("data", resp)
                if isinstance(data, list):
                    for item in data:
                        u = item.get("path") or item.get("url")
                        if u:
                            urls.append(u)
                elif isinstance(data, dict):
                    u = data.get("path") or data.get("url")
                    if u:
                        urls.append(u)
                for u in urls:
                    dest = book_dir / f"{tag}.mp3"
                    if dest.exists() and not force:
                        have_audio = True
                        break
                    n = download_file(u, dest)
                    print(f"      audio  ch{chapter:3d}  {n // 1024} KB")
                    have_audio = True
        except RuntimeError as e:
            print(f"      WARN ch{chapter:3d}  {fs_type}: {e}")

    # Timestamps — only meaningful if we have the corresponding audio
    if audio_fileset_id:
        try:
            ts = get_json(f"/timestamps/{audio_fileset_id}/{book_id}/{chapter}", key)
            (book_dir / f"{tag}.timestamps.json").write_text(
                json.dumps(ts, indent=2, ensure_ascii=False), encoding="utf-8"
            )
            have_timestamps = True
        except RuntimeError:
            pass

    flags = []
    if have_audio: flags.append("audio")
    if have_timestamps: flags.append("timestamps")
    if flags:
        print(f"    ch{chapter:3d}: {', '.join(flags)}")


# ------------------------------------------------------------------ main

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--key", help="Bible Brain API key (else $FCBH_API_KEY or ~/.fcbh_key)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("probe", help="List metadata + filesets for a bible_id")
    p.add_argument("--bible", required=True, help="Bible ID, e.g. azocab")

    p = sub.add_parser("copyright",
                       help="Fetch /copyright for a bible_id and print verbatim")
    p.add_argument("--bible", required=True)

    p = sub.add_parser("fetch",
                       help="Download text, audio, timestamps for a bible_id")
    p.add_argument("--bible", required=True)
    p.add_argument("--book", help="Restrict to one book (e.g. MAT, GEN)")
    p.add_argument("--force", action="store_true",
                   help="Re-download files that already exist")

    args = ap.parse_args(argv)
    key = load_api_key(args.key)

    if args.cmd == "probe":
        return cmd_probe(args, key)
    if args.cmd == "copyright":
        return cmd_copyright(args, key)
    if args.cmd == "fetch":
        return cmd_fetch(args, key)
    ap.error(f"unknown command {args.cmd}")
    return 2


if __name__ == "__main__":
    sys.exit(main())
