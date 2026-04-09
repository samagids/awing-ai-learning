# Vocabulary Image Generation Script

## Overview

`generate_images.py` creates clean, kid-friendly vocabulary illustration images for the Awing AI Learning app. Each image is a 256x256 PNG with:

- **Category-colored gradient background** (pink for body, green for animals, etc.)
- **Large emoji symbol** (96px) representing the word
- **English label** at the bottom in white text
- **Clean, modern design** suitable for children

## Features

- Reads vocabulary directly from `lib/data/awing_vocabulary.dart` (always in sync)
- Converts Awing orthography to safe ASCII filenames (matches audio keys)
- 1,427+ vocabulary entries with emoji mappings
- Category-based color schemes
- Smart fallbacks for unmapped words
- Incremental generation (skips existing images)
- Force regeneration with `--force` flag

## Installation

No extra dependencies beyond Pillow (PIL):

```bash
pip install Pillow
```

Or use the project's standard setup:

```bash
python scripts/install_dependencies.bat  # Windows
# or
pip install -r scripts/requirements.txt  # All platforms
```

## Usage

### Generate all vocabulary images

```bash
python scripts/generate_images.py generate
```

Generates 1,427 images in `assets/images/vocabulary/`:

```
Generated: 1427
Skipped: 0 (existing)
Failed: 0
Output: .../assets/images/vocabulary
```

### Generate for a specific category

```bash
python scripts/generate_images.py generate --category body
python scripts/generate_images.py generate --category animals
python scripts/generate_images.py generate --category food
```

Available categories:
- `body` (110 words)
- `animals` (113 words)
- `nature` (97 words)
- `food` (75 words)
- `actions` (340 words)
- `things` (390 words)
- `family` (144 words)
- `descriptive` (141 words)
- `numbers` (17 words)

### Regenerate existing images

```bash
python scripts/generate_images.py generate --force
```

Ignores existing files and regenerates all images.

### List generation status

```bash
python scripts/generate_images.py list
```

Output:

```
Vocabulary Status:
  Total words: 1427
  Generated images: 1427
  Missing images: 0

By category:
  actions         :  340 words
  animals         :  113 words
  body            :  110 words
  descriptive     :  141 words
  family          :  144 words
  food            :   75 words
  nature          :   97 words
  numbers         :   17 words
  things          :  390 words

Image directory: .../assets/images/vocabulary
  Existing PNG files: 1427
```

### Clean generated images

```bash
python scripts/generate_images.py clean
```

Removes all generated PNG files:

```
Cleaned 1427 image files from .../assets/images/vocabulary
```

## Image Details

### Dimensions
- **Size:** 256x256 pixels
- **Emoji:** 96px (large, kid-friendly)
- **Label:** 14pt, white text with shadow

### Color Schemes (gradient backgrounds)

| Category | Color Range | Purpose |
|----------|-------------|---------|
| body | Pink (#FFC8DC → #FFB4C8) | Body parts |
| animals | Green (#96DC96 → #78C878) | Animals |
| nature | Blue (#96C8FF → #78B4F0) | Nature/environment |
| food | Orange (#FFB464 → #FFA050) | Food & drink |
| actions | Purple (#C896FF → #B478F0) | Verbs/actions |
| things | Brown (#C89664 → #B48250) | Objects |
| family | Teal (#64C8C8 → #50B4B4) | Family/people |
| descriptive | Amber (#FFC864 → #FFB450) | Adjectives |
| numbers | Red (#FF6464 → #F05050) | Numbers |

### Emoji Mapping

The script includes 200+ emoji mappings for common English words:

**Body parts:** hand (✋), head (👤), eye (👁️), ear (👂), nose (👃), mouth (👄), etc.

**Animals:** dog (🐕), cat (🐈), bird (🐦), fish (🐟), snake (🐍), etc.

**Nature:** sun (☀️), rain (🌧️), tree (🌳), flower (🌸), river (🏞️), etc.

**Food:** banana (🍌), apple (🍎), corn (🌽), egg (🥚), milk (🥛), etc.

**Objects:** house (🏠), car (🚗), book (📚), fire (🔥), etc.

**Actions:** eat (🍴), sleep (😴), walk (🚶), run (🏃), sing (🎵), etc.

**Emotions/Adjectives:** happy (😊), sad (😭), big (📏), small (🤏), etc.

**Default fallback:** ❓ (for unmapped words)

## Filename Conversion

Words are converted to safe ASCII filenames using this process:

1. **Strip diacritics:** á→a, è→e, ô→o, etc.
2. **Map special vowels:** ɛ→e, ɔ→o, ə→e, ɨ→i
3. **Map special consonants:** ŋ→ng
4. **Remove apostrophes:** ' and " removed
5. **Lowercase & spaces:** Spaces/hyphens replaced with underscores
6. **Safe characters only:** Remove any remaining special chars

Examples:

| Awing | English | Filename |
|-------|---------|----------|
| apô | hand | apo.png |
| atûə | head | atue.png |
| ŋgɔ̀ɔnə | eye | ngooone.png |
| nóolə | snake | noole.png |
| akoolə | leg | akoole.png |
| "apo'ə" | hammer | apoe.png |

This matches the `audio_key()` function in `lib/services/pronunciation_service.dart` for consistency.

## Integration with Flutter

### Asset Declaration

The `pubspec.yaml` includes the vocabulary image directory:

```yaml
flutter:
  assets:
    - assets/images/vocabulary/
```

### Using Images in Dart

```dart
// Load image from assets
Image.asset('assets/images/vocabulary/apo.png')

// Or in vocabulary flashcards
Image.asset('assets/images/vocabulary/${audioKey}.png')

// With error handling
Image.asset(
  'assets/images/vocabulary/$audioKey.png',
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.image_not_supported);
  },
)
```

## Performance

- **Generation time:** ~5-10 seconds for all 1,427 images
- **Average file size:** 2-3 KB per image
- **Total size:** ~3-4 MB for complete set
- **Memory usage:** < 100 MB during generation

## Troubleshooting

### "No vocabulary found in Dart file"

- Verify `lib/data/awing_vocabulary.dart` exists
- Check that the file contains valid `AwingWord(...)` entries
- Ensure `awing`, `english`, and `category` fields are present

### Images not appearing in Flutter

- Run `flutter pub get` to rebuild asset manifest
- Check that `pubspec.yaml` includes `- assets/images/vocabulary/`
- Rebuild app: `flutter clean && flutter build apk`
- Verify PNG files exist in `assets/images/vocabulary/`

### Emoji displaying incorrectly

- Some emoji may render differently on different platforms
- Consider using custom SVG icons instead for future versions
- Update `EMOJI_MAP` in the script for platform-specific replacements

### Slow generation on large sets

- Run category-by-category: `python scripts/generate_images.py generate --category body`
- Skip existing images (default behavior) to only regenerate missing ones
- Use `--force` only when necessary

## Future Enhancements

1. **Custom SVG icons** — Replace emoji with hand-drawn Awing-themed illustrations
2. **Image caching** — Pre-generate on app first run
3. **Dynamic theming** — Use app's selected theme colors for backgrounds
4. **Audio playback** — Add audio waveform visualization to images
5. **Animation support** — Generate animated GIFs for vocabulary review
6. **Different sizes** — Generate multiple sizes (512x512 for splash, 128x128 for thumbnails)

## License

Part of Awing AI Learning. Generated vocabulary images are automatically created from the `AwingOrthography2005.pdf` and related linguistic sources.

---

**Created:** 2026-04-08
**Script version:** 1.0.0
**Total vocabulary:** 1,427 words
**Total images generated:** 1,427 PNG files (~3-4 MB)
