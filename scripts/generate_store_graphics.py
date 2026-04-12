#!/usr/bin/env python3
"""
Generate Google Play Store graphics for Awing AI Learning app.
Creates: 512x512 icon, 1024x500 feature graphic, 5 phone screenshots (1080x1920 each).
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys
from pathlib import Path

# Colors (green theme for Awing learning)
COLOR_DARK_GREEN = (0, 100, 50)          # #006432
COLOR_LIGHT_GREEN = (0, 168, 107)        # #00A86B
COLOR_MEDIUM_GREEN = (0, 130, 80)        # #008250
COLOR_WHITE = (255, 255, 255)
COLOR_BLACK = (0, 0, 0)
COLOR_LIGHT_GRAY = (240, 240, 240)
COLOR_GOLD = (255, 200, 0)               # For badges/XP

OUTPUT_DIR = Path("/sessions/vibrant-lucid-albattani/mnt/Awing/store_listing")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def draw_gradient(image, start_color, end_color):
    """Draw a vertical gradient from start_color to end_color."""
    pixels = image.load()
    width, height = image.size

    for y in range(height):
        # Interpolate color from start to end
        r = int(start_color[0] + (end_color[0] - start_color[0]) * y / height)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * y / height)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * y / height)
        color = (r, g, b)

        for x in range(width):
            pixels[x, y] = color


def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = bbox
    # Corners
    draw.arc([x1, y1, x1+2*radius, y1+2*radius], 180, 270, fill=outline, width=width)
    draw.arc([x2-2*radius, y1, x2, y1+2*radius], 270, 360, fill=outline, width=width)
    draw.arc([x2-2*radius, y2-2*radius, x2, y2], 0, 90, fill=outline, width=width)
    draw.arc([x1, y2-2*radius, x1+2*radius, y2], 90, 180, fill=outline, width=width)
    # Sides and fill
    draw.rectangle([x1+radius, y1, x2-radius, y2], fill=fill)
    draw.rectangle([x1, y1+radius, x2, y2-radius], fill=fill)


def get_large_font(size):
    """Get the largest available font or default."""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except:
        try:
            return ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", size)
        except:
            return ImageFont.load_default()


def create_icon_512():
    """Create 512x512 Play Store icon."""
    img = Image.new("RGB", (512, 512))
    draw_gradient(img, COLOR_DARK_GREEN, COLOR_LIGHT_GREEN)
    draw = ImageDraw.Draw(img)

    # Draw large white "A" circle
    circle_radius = 150
    circle_x, circle_y = 256, 220
    draw.ellipse(
        [circle_x - circle_radius, circle_y - circle_radius,
         circle_x + circle_radius, circle_y + circle_radius],
        fill=COLOR_WHITE, outline=COLOR_LIGHT_GREEN, width=3
    )

    # Draw "A" letter in the circle (large)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 180)
    except:
        font = ImageFont.load_default()

    text = "A"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = circle_x - text_width // 2
    text_y = circle_y - text_height // 2 - 20
    draw.text((text_x, text_y), text, fill=COLOR_DARK_GREEN, font=font)

    # Draw speech bubble with sound waves
    bubble_x, bubble_y = 380, 100
    bubble_size = 60
    # Bubble circle
    draw.ellipse([bubble_x, bubble_y, bubble_x + bubble_size, bubble_y + bubble_size],
                 fill=COLOR_WHITE, outline=COLOR_LIGHT_GREEN, width=2)

    # Sound waves
    for i, r in enumerate([30, 45, 60]):
        draw.arc([bubble_x - 30 + i*15, bubble_y - 30 + i*15,
                  bubble_x + bubble_size + 30 - i*15, bubble_y + bubble_size + 30 - i*15],
                 0, 180, fill=COLOR_LIGHT_GREEN, width=3)

    img.save(OUTPUT_DIR / "icon_512.png")
    print(f"Created: icon_512.png (512x512)")


def create_feature_graphic():
    """Create 1024x500 feature graphic."""
    img = Image.new("RGB", (1024, 500))
    draw_gradient(img, COLOR_DARK_GREEN, COLOR_LIGHT_GREEN)
    draw = ImageDraw.Draw(img)

    # Draw decorative circles in background
    circle_colors = [COLOR_LIGHT_GREEN, COLOR_MEDIUM_GREEN, COLOR_WHITE]
    positions = [(150, 100, 80), (900, 350, 90), (100, 400, 70), (800, 150, 100)]
    for x, y, r in positions:
        draw.ellipse([x-r, y-r, x+r, y+r], fill=None, outline=COLOR_WHITE, width=2)

    # Title
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 80)
        subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 40)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()

    # Draw title
    title = "Awing AI Learning"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_x = (1024 - title_width) // 2
    draw.text((title_x, 80), title, fill=COLOR_WHITE, font=title_font)

    # Draw subtitle
    subtitle = "Learn the Awing Language"
    bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = bbox[2] - bbox[0]
    subtitle_x = (1024 - subtitle_width) // 2
    draw.text((subtitle_x, 200), subtitle, fill=COLOR_WHITE, font=subtitle_font)

    # Draw decorative speech bubbles
    bubble_y = 320
    for bubble_x in [150, 450, 750]:
        draw.ellipse([bubble_x, bubble_y, bubble_x + 50, bubble_y + 50],
                     fill=COLOR_WHITE, outline=COLOR_LIGHT_GREEN, width=2)

    img.save(OUTPUT_DIR / "feature_graphic.png")
    print(f"Created: feature_graphic.png (1024x500)")


def create_screenshot_1():
    """Screenshot 1: Learn the Alphabet."""
    img = Image.new("RGB", (1080, 1920), color=COLOR_LIGHT_GRAY)
    draw = ImageDraw.Draw(img)

    # Status bar
    draw.rectangle([0, 0, 1080, 50], fill=COLOR_DARK_GREEN)

    # App bar
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()

    draw.rectangle([0, 50, 1080, 150], fill=COLOR_MEDIUM_GREEN)
    draw.text((40, 70), "Alphabet Lesson", fill=COLOR_WHITE, font=font_title)

    # Letter cards
    card_y = 200
    letters = ["A", "B", "E", "Ɛ"]
    card_colors = [COLOR_LIGHT_GREEN, COLOR_MEDIUM_GREEN, COLOR_LIGHT_GREEN, COLOR_MEDIUM_GREEN]

    for i, (letter, card_color) in enumerate(zip(letters, card_colors)):
        if i < 2:
            card_x = 80 + i * 480
            card_y_pos = 200
        else:
            card_x = 80 + (i - 2) * 480
            card_y_pos = 650

        # Card background
        draw.rounded_rectangle([card_x, card_y_pos, card_x + 400, card_y_pos + 300],
                               radius=20, fill=card_color, outline=COLOR_WHITE, width=3)

        # Large letter
        try:
            letter_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 120)
        except:
            letter_font = ImageFont.load_default()

        bbox = draw.textbbox((0, 0), letter, font=letter_font)
        letter_width = bbox[2] - bbox[0]
        letter_x = card_x + (400 - letter_width) // 2
        draw.text((letter_x, card_y_pos + 60), letter, fill=COLOR_WHITE, font=letter_font)

        # Phoneme label
        draw.text((card_x + 40, card_y_pos + 210), "Tap to hear →", fill=COLOR_WHITE, font=font_text)

    # Bottom navigation
    draw.rectangle([0, 1800, 1080, 1920], fill=COLOR_DARK_GREEN)
    draw.text((350, 1820), "← Lessons →", fill=COLOR_WHITE, font=font_text)

    img.save(OUTPUT_DIR / "screenshot_1.png")
    print(f"Created: screenshot_1.png (1080x1920)")


def create_screenshot_2():
    """Screenshot 2: Master Vocabulary."""
    img = Image.new("RGB", (1080, 1920), color=COLOR_LIGHT_GRAY)
    draw = ImageDraw.Draw(img)

    # Status bar
    draw.rectangle([0, 0, 1080, 50], fill=COLOR_DARK_GREEN)

    # App bar
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()
        font_small = ImageFont.load_default()

    draw.rectangle([0, 50, 1080, 150], fill=COLOR_MEDIUM_GREEN)
    draw.text((40, 70), "Vocabulary", fill=COLOR_WHITE, font=font_title)

    # Large flashcard
    card_x, card_y = 100, 250
    card_w, card_h = 880, 600
    draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h],
                           radius=30, fill=COLOR_WHITE, outline=COLOR_LIGHT_GREEN, width=4)

    # Image placeholder (left half)
    img_x = card_x + 40
    img_y = card_y + 40
    img_size = 350
    draw.rectangle([img_x, img_y, img_x + img_size, img_y + img_size],
                   fill=COLOR_LIGHT_GREEN, outline=COLOR_WHITE, width=2)
    draw.text((img_x + 80, img_y + 150), "🍌", fill=COLOR_WHITE, font=font_title)

    # Word info (right half)
    text_x = img_x + img_size + 80
    text_y = img_y + 60

    # Awing word
    try:
        word_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 60)
    except:
        word_font = font_title

    draw.text((text_x, text_y), "apɛnə", fill=COLOR_DARK_GREEN, font=word_font)
    draw.text((text_x, text_y + 100), "(banana)", fill=COLOR_BLACK, font=font_text)

    # Buttons area
    button_y = card_y + card_h + 50

    # Hear it button
    button_color = COLOR_LIGHT_GREEN
    draw.rounded_rectangle([100, button_y, 400, button_y + 80],
                           radius=15, fill=button_color, outline=COLOR_DARK_GREEN, width=2)
    draw.text((140, button_y + 20), "🔊 Hear It", fill=COLOR_WHITE, font=font_text)

    # Swipe indicator
    draw.text((250, button_y + 120), "← Swipe for more →", fill=COLOR_DARK_GREEN, font=font_small)

    # Bottom navigation
    draw.rectangle([0, 1800, 1080, 1920], fill=COLOR_DARK_GREEN)
    draw.text((350, 1820), "← Categories →", fill=COLOR_WHITE, font=font_text)

    img.save(OUTPUT_DIR / "screenshot_2.png")
    print(f"Created: screenshot_2.png (1080x1920)")


def create_screenshot_3():
    """Screenshot 3: Practice Pronunciation."""
    img = Image.new("RGB", (1080, 1920), color=COLOR_LIGHT_GRAY)
    draw = ImageDraw.Draw(img)

    # Status bar
    draw.rectangle([0, 0, 1080, 50], fill=COLOR_DARK_GREEN)

    # App bar
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()
        font_small = ImageFont.load_default()

    draw.rectangle([0, 50, 1080, 150], fill=COLOR_MEDIUM_GREEN)
    draw.text((40, 70), "Pronunciation", fill=COLOR_WHITE, font=font_title)

    # Title
    draw.text((200, 250), "Say it:", fill=COLOR_DARK_GREEN, font=font_title)

    # Word display
    try:
        word_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 80)
    except:
        word_font = font_title

    draw.text((150, 400), "nkɨ́ə", fill=COLOR_MEDIUM_GREEN, font=word_font)
    draw.text((200, 550), "(tree)", fill=COLOR_BLACK, font=font_text)

    # Large microphone circle button
    mic_x, mic_y = 540, 800
    mic_radius = 120
    draw.ellipse([mic_x - mic_radius, mic_y - mic_radius,
                  mic_x + mic_radius, mic_y + mic_radius],
                 fill=COLOR_LIGHT_GREEN, outline=COLOR_DARK_GREEN, width=4)

    # Microphone icon
    draw.text((mic_x - 40, mic_y - 60), "🎤", fill=COLOR_WHITE, font=font_title)
    draw.text((mic_x - 80, mic_y + 150), "Tap to record", fill=COLOR_DARK_GREEN, font=font_small)

    # Feedback area
    feedback_y = 1200
    draw.rounded_rectangle([100, feedback_y, 980, feedback_y + 120],
                           radius=15, fill=COLOR_LIGHT_GREEN, outline=COLOR_DARK_GREEN, width=2)
    draw.text((200, feedback_y + 30), "⭐⭐⭐⭐⭐ Great job!", fill=COLOR_WHITE, font=font_text)

    # Bottom navigation
    draw.rectangle([0, 1800, 1080, 1920], fill=COLOR_DARK_GREEN)
    draw.text((300, 1820), "← More Words →", fill=COLOR_WHITE, font=font_text)

    img.save(OUTPUT_DIR / "screenshot_3.png")
    print(f"Created: screenshot_3.png (1080x1920)")


def create_screenshot_4():
    """Screenshot 4: Test Your Knowledge (Quiz)."""
    img = Image.new("RGB", (1080, 1920), color=COLOR_LIGHT_GRAY)
    draw = ImageDraw.Draw(img)

    # Status bar
    draw.rectangle([0, 0, 1080, 50], fill=COLOR_DARK_GREEN)

    # App bar with progress
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()
        font_small = ImageFont.load_default()

    draw.rectangle([0, 50, 1080, 150], fill=COLOR_MEDIUM_GREEN)
    draw.text((40, 70), "Quiz", fill=COLOR_WHITE, font=font_title)
    draw.text((900, 85), "5/20", fill=COLOR_GOLD, font=font_small)

    # Progress bar
    progress = 0.25
    draw.rectangle([100, 200, 980, 230], fill=COLOR_LIGHT_GRAY, outline=COLOR_DARK_GREEN, width=2)
    draw.rectangle([100, 200, 100 + (880 * progress), 230], fill=COLOR_GOLD)

    # Question
    draw.text((100, 300), "What does 'əpúmə' mean?", fill=COLOR_DARK_GREEN, font=font_title)

    # Multiple choice options
    options = ["A) Basket", "B) House", "C) Tree", "D) Snake"]
    option_colors = [COLOR_LIGHT_GREEN, COLOR_MEDIUM_GREEN, COLOR_LIGHT_GREEN, COLOR_MEDIUM_GREEN]

    option_y = 500
    for i, (option, color) in enumerate(zip(options, option_colors)):
        draw.rounded_rectangle([100, option_y + i*120, 980, option_y + i*120 + 100],
                               radius=15, fill=color, outline=COLOR_DARK_GREEN, width=2)
        draw.text((150, option_y + i*120 + 30), option, fill=COLOR_WHITE, font=font_text)

    # Bottom navigation
    draw.rectangle([0, 1800, 1080, 1920], fill=COLOR_DARK_GREEN)
    draw.text((350, 1820), "← Back to Lessons →", fill=COLOR_WHITE, font=font_text)

    img.save(OUTPUT_DIR / "screenshot_4.png")
    print(f"Created: screenshot_4.png (1080x1920)")


def create_screenshot_5():
    """Screenshot 5: Track Progress."""
    img = Image.new("RGB", (1080, 1920), color=COLOR_LIGHT_GRAY)
    draw = ImageDraw.Draw(img)

    # Status bar
    draw.rectangle([0, 0, 1080, 50], fill=COLOR_DARK_GREEN)

    # App bar
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 40)
        font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()
        font_small = ImageFont.load_default()

    draw.rectangle([0, 50, 1080, 150], fill=COLOR_MEDIUM_GREEN)
    draw.text((40, 70), "Your Progress", fill=COLOR_WHITE, font=font_title)

    # XP and Level card
    card_y = 200
    draw.rounded_rectangle([100, card_y, 980, card_y + 150],
                           radius=20, fill=COLOR_LIGHT_GREEN, outline=COLOR_DARK_GREEN, width=3)
    draw.text((150, card_y + 30), "Level 5", fill=COLOR_WHITE, font=font_title)
    draw.text((650, card_y + 30), "2,450 XP", fill=COLOR_GOLD, font=font_title)

    # XP bar
    xp_progress = 0.65
    bar_y = card_y + 120
    draw.rectangle([120, bar_y, 960, bar_y + 20], fill=COLOR_LIGHT_GRAY, outline=COLOR_WHITE, width=1)
    draw.rectangle([120, bar_y, 120 + (840 * xp_progress), bar_y + 20], fill=COLOR_GOLD)

    # Badges section
    draw.text((100, 450), "Achievements", fill=COLOR_DARK_GREEN, font=font_title)

    badge_data = [
        ("🌟", "Alphabet Master", "Learned all letters"),
        ("💬", "Word Wizard", "1,000 words learned"),
        ("🎯", "Quiz Master", "Perfect 5 quizzes"),
    ]

    badge_y = 550
    for emoji, title, subtitle in badge_data:
        # Badge circle
        draw.ellipse([100, badge_y, 200, badge_y + 100],
                     fill=COLOR_GOLD, outline=COLOR_DARK_GREEN, width=2)
        draw.text((125, badge_y + 20), emoji, fill=COLOR_WHITE, font=font_text)

        # Badge text
        draw.text((250, badge_y + 10), title, fill=COLOR_DARK_GREEN, font=font_text)
        draw.text((250, badge_y + 50), subtitle, fill=COLOR_BLACK, font=font_small)

        badge_y += 150

    # Streak indicator
    streak_y = 1100
    draw.rounded_rectangle([100, streak_y, 980, streak_y + 100],
                           radius=15, fill=COLOR_LIGHT_GREEN, outline=COLOR_DARK_GREEN, width=2)
    draw.text((200, streak_y + 20), "🔥 7-Day Streak!", fill=COLOR_WHITE, font=font_text)
    draw.text((200, streak_y + 60), "Keep learning every day!", fill=COLOR_WHITE, font=font_small)

    # Bottom navigation
    draw.rectangle([0, 1800, 1080, 1920], fill=COLOR_DARK_GREEN)
    draw.text((300, 1820), "← Back to Home →", fill=COLOR_WHITE, font=font_text)

    img.save(OUTPUT_DIR / "screenshot_5.png")
    print(f"Created: screenshot_5.png (1080x1920)")


def main():
    """Generate all store graphics."""
    print("Generating Google Play Store graphics for Awing AI Learning...\n")

    create_icon_512()
    create_feature_graphic()
    create_screenshot_1()
    create_screenshot_2()
    create_screenshot_3()
    create_screenshot_4()
    create_screenshot_5()

    print(f"\nAll graphics created successfully in: {OUTPUT_DIR}")

    # List files
    print("\nGenerated files:")
    for file in sorted(OUTPUT_DIR.glob("*.png")):
        size = file.stat().st_size / 1024
        print(f"  - {file.name} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
