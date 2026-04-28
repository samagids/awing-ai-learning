"""
generate_ios_screenshots.py — convert Play Store screenshots to App Store sizes.

Source: store_listing/screenshot_{1..5}.png (1080x1920, 9:16 portrait, ratio 0.562)
Target: Apple App Store Connect required sizes (taller aspect ratios, ratio ~0.460):

  - 6.9" iPhone (Pro Max class — iPhone 15/16/17 Pro Max):  1320 x 2868
  - 6.5" iPhone (Plus class — iPhone 8 Plus through 14 Plus): 1284 x 2778

  iPad: NOT generated. Xcode TARGETED_DEVICE_FAMILY = "1" (iPhone only) per the
  v1 release decision documented in CLAUDE.md Session 57c.

Strategy: scale source to target width (preserves the existing UI layout exactly),
center vertically, and fill the remaining top/bottom space with a branded bar.
This is the safest approach because cropping the sides would clip the actual UI
content (the original screenshots are tightly framed against device chrome).

Top bar: white background, app name + tagline, brand color accent strip.
Bottom bar: white background, single feature line (varies per screenshot).

Also generates:
  - app_store_icon_1024.png  — 1024x1024 PNG with NO alpha (Apple requirement,
    they apply the rounded-corner mask themselves and reject icons that already
    have one). Repurposes store_listing/icon_512.png upscaled with Lanczos.

Usage:
  python scripts/generate_ios_screenshots.py        # generate everything
  python scripts/generate_ios_screenshots.py --size 6.9   # only 6.9"
  python scripts/generate_ios_screenshots.py --icon-only  # just the 1024 icon

Requires Pillow (already in scripts/requirements.txt).

Run from the repo root.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover
    print(
        "ERROR: Pillow not installed. Run: pip install Pillow",
        file=sys.stderr,
    )
    sys.exit(1)


# ---------------------------------------------------------------------------
# Paths

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = REPO_ROOT / "store_listing"
OUTPUT_DIR = REPO_ROOT / "store_listing" / "ios"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Apple required dimensions (App Store Connect, valid as of 2026-04)

APPLE_SIZES: dict[str, tuple[int, int]] = {
    # display class -> (width, height) in pixels, portrait
    "6.9": (1320, 2868),  # iPhone 16 Pro Max class (mandatory)
    "6.5": (1284, 2778),  # iPhone Plus class (recommended fallback)
}


# ---------------------------------------------------------------------------
# Brand colors and copy

BRAND_GREEN = (76, 175, 80)        # Material Green 500 — matches the app theme
BRAND_GREEN_DARK = (56, 142, 60)   # Material Green 700
WHITE = (255, 255, 255)
NEAR_BLACK = (33, 33, 33)
SOFT_GRAY = (117, 117, 117)

APP_NAME = "Awing AI Learning"
TAGLINE = "Learn the Awing language"

# Per-screenshot bottom captions. Index 0 = screenshot_1.png. Keep each string
# short (< 50 chars) so it doesn't wrap on the narrow target width.
BOTTOM_CAPTIONS = [
    "3,000+ Awing words at your fingertips",
    "Six character voices for every level",
    "Practice tones, vowels, and clusters",
    "Quiz packs with instant feedback",
    "Classroom exam mode — no internet needed",
]

# Fallback caption when more screenshots than captions exist
DEFAULT_CAPTION = "Free, offline, kid-friendly"


# ---------------------------------------------------------------------------
# Helpers


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Try several font paths; fall back to PIL's bundled default."""
    candidates_bold = [
        "/usr/share/fonts/truetype/dejavu/DejaVu-Sans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
    ]
    candidates_reg = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibri.ttf",
    ]
    for path in (candidates_bold if bold else candidates_reg):
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def _draw_centered(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    box_x: int,
    box_y: int,
    box_w: int,
    box_h: int,
    color: tuple[int, int, int],
) -> None:
    """Draw `text` centered within the (box_x, box_y, box_w, box_h) rectangle."""
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = box_x + (box_w - text_w) // 2 - bbox[0]
    y = box_y + (box_h - text_h) // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=color)


def _fit_font(
    text: str,
    max_size: int,
    min_size: int,
    max_width: int,
    bold: bool,
) -> ImageFont.FreeTypeFont:
    """
    Find the largest font size in [min_size, max_size] whose rendered `text`
    width is <= max_width. Binary search keeps this fast.
    """
    # Single-line measurement helper (uses a throwaway draw context)
    def _measure(size: int) -> int:
        f = _load_font(size, bold=bold)
        # textlength is robust across Pillow versions
        try:
            return int(ImageDraw.Draw(Image.new("RGB", (1, 1))).textlength(text, font=f))
        except AttributeError:
            bb = ImageDraw.Draw(Image.new("RGB", (1, 1))).textbbox((0, 0), text, font=f)
            return bb[2] - bb[0]

    lo, hi = min_size, max_size
    best = min_size
    while lo <= hi:
        mid = (lo + hi) // 2
        if _measure(mid) <= max_width:
            best = mid
            lo = mid + 1
        else:
            hi = mid - 1
    return _load_font(best, bold=bold)


def _build_canvas(
    src: Image.Image,
    target_w: int,
    target_h: int,
    caption: str,
) -> Image.Image:
    """
    Resize source (preserving aspect) to fit target_w, then center vertically and
    fill top + bottom margins with branded bars.
    """
    src_w, src_h = src.size
    scale = target_w / src_w
    scaled_h = int(round(src_h * scale))
    scaled = src.resize((target_w, scaled_h), Image.LANCZOS)

    # Total vertical margin to distribute between top and bottom bars
    total_margin = max(target_h - scaled_h, 0)
    if total_margin == 0:
        # Source already too tall — crop equally top/bottom (rare)
        excess = scaled_h - target_h
        top_crop = excess // 2
        scaled = scaled.crop((0, top_crop, target_w, top_crop + target_h))
        return scaled

    # Asymmetric split: more space on top for header, smaller bottom band
    # If there's enough margin to render comfortable text, use it; otherwise
    # split evenly.
    if total_margin >= 200:
        top_h = int(total_margin * 0.55)
        bot_h = total_margin - top_h
    else:
        top_h = total_margin // 2
        bot_h = total_margin - top_h

    canvas = Image.new("RGB", (target_w, target_h), WHITE)
    canvas.paste(scaled, (0, top_h))

    draw = ImageDraw.Draw(canvas)

    # ---- Top bar: app name + tagline + accent strip ----
    if top_h > 0:
        # Background (white)
        draw.rectangle([(0, 0), (target_w, top_h)], fill=WHITE)
        # Brand accent strip along the bottom of the top bar (subtle separator)
        strip_h = max(6, top_h // 80)
        draw.rectangle(
            [(0, top_h - strip_h), (target_w, top_h)], fill=BRAND_GREEN
        )

        # App name — auto-fit so it always sits within a comfortable margin
        side_margin = max(60, target_w // 22)
        usable_w = target_w - 2 * side_margin
        name_max = max(48, int(top_h * 0.34))
        name_font = _fit_font(APP_NAME, max_size=name_max, min_size=36,
                              max_width=usable_w, bold=True)
        tag_max = max(28, int(top_h * 0.18))
        tag_font = _fit_font(TAGLINE, max_size=tag_max, min_size=24,
                             max_width=usable_w, bold=False)

        # Vertical layout: title above tagline, both centered as a group
        # Compute combined height
        name_bbox = draw.textbbox((0, 0), APP_NAME, font=name_font)
        tag_bbox = draw.textbbox((0, 0), TAGLINE, font=tag_font)
        name_h = name_bbox[3] - name_bbox[1]
        tag_h = tag_bbox[3] - tag_bbox[1]
        gap = int(name_h * 0.25)
        group_h = name_h + gap + tag_h
        group_top = (top_h - strip_h - group_h) // 2

        # Draw title
        _draw_centered(
            draw, APP_NAME, name_font, 0, group_top, target_w, name_h, BRAND_GREEN_DARK
        )
        # Draw tagline below title
        _draw_centered(
            draw,
            TAGLINE,
            tag_font,
            0,
            group_top + name_h + gap,
            target_w,
            tag_h,
            SOFT_GRAY,
        )

    # ---- Bottom bar: caption ----
    if bot_h > 0:
        # Background (white)
        bot_y0 = top_h + scaled_h
        draw.rectangle([(0, bot_y0), (target_w, target_h)], fill=WHITE)
        # Brand accent strip along the top of the bottom bar
        strip_h = max(6, bot_h // 60)
        draw.rectangle(
            [(0, bot_y0), (target_w, bot_y0 + strip_h)], fill=BRAND_GREEN
        )

        side_margin = max(60, target_w // 22)
        usable_w = target_w - 2 * side_margin
        cap_max = max(34, int(bot_h * 0.32))
        cap_font = _fit_font(caption, max_size=cap_max, min_size=24,
                             max_width=usable_w, bold=True)
        cap_bbox = draw.textbbox((0, 0), caption, font=cap_font)
        cap_h = cap_bbox[3] - cap_bbox[1]
        cap_top = bot_y0 + strip_h + (bot_h - strip_h - cap_h) // 2
        _draw_centered(
            draw, caption, cap_font, 0, cap_top, target_w, cap_h, NEAR_BLACK
        )

    return canvas


# ---------------------------------------------------------------------------
# Pipelines


def generate_screenshots(sizes: list[str]) -> int:
    sources = sorted(SOURCE_DIR.glob("screenshot_*.png"))
    if not sources:
        print(
            f"ERROR: no source screenshots found at {SOURCE_DIR}/screenshot_*.png",
            file=sys.stderr,
        )
        return 1

    total = 0
    for size_key in sizes:
        if size_key not in APPLE_SIZES:
            print(f"WARN: unknown size {size_key!r}, skipping", file=sys.stderr)
            continue
        target_w, target_h = APPLE_SIZES[size_key]
        out_subdir = OUTPUT_DIR / f"iphone_{size_key.replace('.', '_')}"
        out_subdir.mkdir(parents=True, exist_ok=True)

        print(
            f"\n[{size_key}\"]  target {target_w}x{target_h}  ->  {out_subdir.name}/"
        )
        for idx, src_path in enumerate(sources):
            with Image.open(src_path) as src:
                # Drop alpha if present (Apple does not require it for screenshots,
                # but some uploaders mis-handle alpha. Convert to RGB explicitly.)
                if src.mode != "RGB":
                    src = src.convert("RGB")
                caption = (
                    BOTTOM_CAPTIONS[idx]
                    if idx < len(BOTTOM_CAPTIONS)
                    else DEFAULT_CAPTION
                )
                out_img = _build_canvas(src, target_w, target_h, caption)
                out_path = out_subdir / f"{src_path.stem}.png"
                out_img.save(out_path, "PNG", optimize=True)
                print(f"  {src_path.name}  ->  {out_path.relative_to(REPO_ROOT)}")
                total += 1
    return 0 if total > 0 else 1


def generate_icon_1024() -> int:
    """Apple requires a 1024x1024 PNG with NO alpha and NO rounded corners."""
    src_path = SOURCE_DIR / "icon_512.png"
    if not src_path.exists():
        print(f"ERROR: source icon not found at {src_path}", file=sys.stderr)
        return 1
    with Image.open(src_path) as src:
        # Flatten alpha onto a white background — Apple rejects icons with alpha
        if src.mode in ("RGBA", "LA", "PA"):
            bg = Image.new("RGB", src.size, WHITE)
            bg.paste(src, mask=src.split()[-1] if src.mode == "RGBA" else None)
            src = bg
        elif src.mode != "RGB":
            src = src.convert("RGB")
        # Upscale 512 -> 1024 with Lanczos
        out = src.resize((1024, 1024), Image.LANCZOS)
        out_path = OUTPUT_DIR / "app_store_icon_1024.png"
        out.save(out_path, "PNG", optimize=True)
        print(f"app_store_icon_1024.png  ->  {out_path.relative_to(REPO_ROOT)}")
    return 0


# ---------------------------------------------------------------------------
# CLI


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--size",
        choices=sorted(APPLE_SIZES.keys()),
        action="append",
        default=None,
        help='Display class to render (repeatable). Defaults to all.',
    )
    parser.add_argument(
        "--icon-only",
        action="store_true",
        help="Skip screenshots, only regenerate the 1024 icon.",
    )
    parser.add_argument(
        "--no-icon",
        action="store_true",
        help="Skip the 1024 icon, only regenerate screenshots.",
    )
    args = parser.parse_args()

    if args.icon_only:
        return generate_icon_1024()

    sizes = args.size or sorted(APPLE_SIZES.keys())
    rc = generate_screenshots(sizes)
    if rc != 0:
        return rc
    if not args.no_icon:
        rc = generate_icon_1024()
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
