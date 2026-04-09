#!/usr/bin/env python3
"""
Generate vocabulary illustration images for Awing AI Learning app.

Uses SDXL Turbo (Stable Diffusion XL Turbo) running locally on your NVIDIA GPU
to generate kid-friendly cartoon illustrations. No internet needed after first
model download (~5GB). Falls back to Twemoji emoji when GPU is unavailable.

Usage:
  python generate_images.py generate                    # Generate all (GPU + emoji fallback)
  python generate_images.py generate --category body    # Generate for one category
  python generate_images.py generate --force            # Regenerate existing images
  python generate_images.py generate --emoji-only       # Use only emoji (no GPU)
  python generate_images.py list                        # Show status
  python generate_images.py clean                       # Remove generated images
  python generate_images.py test                        # Generate 5 test images

Requirements:
  pip install diffusers transformers accelerate Pillow
  NVIDIA GPU with >= 4GB VRAM (CUDA)
  First run downloads SDXL Turbo model (~5GB, cached in ~/.cache/huggingface/)
"""

import os
import sys
import re
import json
import time
import argparse
import hashlib
from pathlib import Path
from io import BytesIO

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

# ============================================================
# CONFIGURATION
# ============================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
VOCAB_FILE = PROJECT_ROOT / "lib" / "data" / "awing_vocabulary.dart"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "images" / "vocabulary"
EMOJI_CACHE_DIR = SCRIPT_DIR / "_emoji_cache"

# Image settings
IMAGE_SIZE = 256
CORNER_RADIUS = 24
BORDER_WIDTH = 6

# SDXL Turbo generates at 512x512, we downscale to 256x256
GENERATION_SIZE = 512

# Model: SDXL Turbo — 1-step generation, fast, ~4GB VRAM
SDXL_TURBO_MODEL = "stabilityai/sdxl-turbo"

# Twemoji CDN (fallback when GPU unavailable)
TWEMOJI_BASE = "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72"

# Category colors for border/accent
CATEGORY_COLORS = {
    "body":        (219, 112, 147),
    "animals":     (60, 179, 113),
    "nature":      (70, 130, 180),
    "food":        (255, 140, 50),
    "actions":     (138, 90, 220),
    "things":      (160, 120, 80),
    "family":      (32, 178, 170),
    "descriptive": (255, 165, 0),
    "numbers":     (220, 60, 60),
    "default":     (130, 130, 150),
}

# ============================================================
# AI PROMPT STYLE
# Every prompt gets this suffix for consistent kid-friendly style
# ============================================================

STYLE_SUFFIX = (
    "cute cartoon illustration for children, "
    "simple flat design, bright colorful, "
    "friendly and cheerful, "
    "white background, no text, no words, "
    "digital art, clipart style"
)

# ============================================================
# PROMPT OVERRIDES
# Custom AI prompts for words where the English definition alone
# doesn't produce good results. All prompts are kid-friendly.
# ============================================================

PROMPT_OVERRIDES = {
    # Body parts — clear simple illustrations
    "hand": "a child's hand waving hello",
    "head": "a happy child's face and head",
    "nose": "a cartoon face showing a cute nose",
    "neck": "a cartoon giraffe with a long neck",
    "back": "a child stretching showing their back",
    "shoulder": "a cartoon child pointing to shoulder",
    "blood": "a cartoon red blood drop with a happy face",
    "leg": "a cartoon child's leg running",
    "tongue": "a funny cartoon face sticking tongue out",
    "body": "a happy cartoon child standing with arms out",
    "eye": "a big sparkling cartoon eye",
    "ear": "a cartoon bunny with big ears",
    "liver": "a friendly cartoon liver organ with a smile",
    "intestine": "a cartoon digestive system simple illustration",
    "chest": "a cartoon superhero child showing chest",
    "breastbone": "a cartoon skeleton chest bone",
    "mouth": "a big cartoon smiling mouth",
    "tooth": "a happy cartoon white tooth with a smile",
    "hair": "a cartoon child with colorful wild hair",
    "bone": "a cartoon dog bone",
    "stomach": "a cartoon child holding tummy after eating",
    "hip": "a cartoon child dancing showing hips",
    "foot": "a cartoon bare foot",
    "crown": "a golden cartoon crown on a head",
    "beard": "a friendly cartoon man with a fluffy beard",
    "breast": "a cartoon mother holding a baby lovingly",
    "knee": "a cartoon child with a bandage on knee",
    "wing": "a cartoon bird with colorful spread wings",
    "navel": "a cartoon baby belly button",
    "thigh": "a cartoon chicken drumstick",
    "soul": "a glowing cartoon heart with sparkles",
    "spirit": "a cartoon white dove flying in sunshine",
    "heart": "a big red cartoon heart with sparkles",
    "cheek": "a cartoon child with rosy pink cheeks",
    "chin": "a cartoon face pointing at chin",
    "elbow": "a cartoon arm bent at the elbow",
    "finger": "a cartoon hand with one finger pointing up",
    "jaw": "a cartoon dinosaur with a big jaw",
    "forehead": "a cartoon child thinking with hand on forehead",
    "rib": "a cartoon rib bones",
    "palm": "a cartoon open palm hand",
    "throat": "a cartoon child singing loudly",
    "skin": "a cartoon child with smooth skin smiling",
    "waist": "a cartoon hula hoop around a child's waist",

    # Animals — cute cartoon versions
    "ram": "a cute cartoon ram with curly horns",
    "louse": "a tiny cartoon louse bug with big eyes",
    "locust": "a cute cartoon grasshopper on a leaf",
    "antelope": "a cute cartoon antelope running in savanna",
    "fish": "a colorful cartoon tropical fish",
    "snake": "a cute friendly cartoon green snake smiling",
    "dog": "a happy cartoon puppy wagging its tail",
    "cat": "a cute cartoon kitten playing with yarn",
    "chicken": "a cartoon hen with baby chicks",
    "bird": "a colorful cartoon bird singing on a branch",
    "elephant": "a cute baby cartoon elephant with big ears",
    "lion": "a friendly cartoon lion cub with a fluffy mane",
    "hippo": "a happy cartoon hippo in water",
    "mosquito": "a funny cartoon mosquito with big eyes",
    "tortoise": "a cute cartoon tortoise with a patterned shell",
    "pig": "a cute pink cartoon piglet in mud",
    "frog": "a happy green cartoon frog on a lily pad",
    "toad": "a cartoon bumpy toad sitting on a rock",
    "giraffe": "a cute tall cartoon giraffe eating leaves",
    "donkey": "a friendly cartoon donkey with big ears",
    "leopard": "a cute cartoon leopard cub with spots",
    "butterfly": "a beautiful colorful cartoon butterfly",
    "rat": "a cute cartoon mouse with big round ears",
    "shrimp": "a cute cartoon pink shrimp",
    "squirrel": "a cute cartoon squirrel holding an acorn",
    "rooster": "a colorful cartoon rooster crowing at sunrise",
    "spider": "a cute friendly cartoon spider with big eyes",
    "cow": "a friendly cartoon cow in a green field",
    "monkey": "a playful cartoon monkey swinging from a vine",
    "snail": "a cute cartoon snail with a colorful shell",
    "owl": "a cute cartoon owl on a branch at night",
    "duck": "a cute cartoon yellow duck in water",
    "goat": "a cute cartoon goat on a hill",
    "bee": "a cute cartoon bumblebee on a flower",
    "ant": "a cartoon ant carrying a leaf",

    # Nature — bright colorful scenes
    "river": "a cartoon river flowing through green hills",
    "water": "a cartoon splash of blue water drops",
    "sky": "a cartoon blue sky with fluffy white clouds",
    "sun": "a happy cartoon sun with a smiling face",
    "rain": "cartoon rain drops falling from clouds with rainbow",
    "wind": "cartoon leaves blowing in the wind",
    "grass": "cartoon bright green grass with flowers",
    "thunder": "cartoon lightning bolt in dark clouds",
    "night": "cartoon night sky with moon and stars",
    "morning": "cartoon sunrise over green hills",
    "evening": "cartoon orange sunset sky",
    "road": "cartoon winding road through countryside",
    "waterfall": "cartoon beautiful waterfall in jungle",
    "ground": "cartoon earth soil cross-section with worm",
    "shadow": "cartoon child making shadow puppet",
    "valley": "cartoon green valley between mountains",
    "mountain": "cartoon snowy mountain peak",
    "moonlight": "cartoon full moon shining over landscape",
    "forest": "cartoon colorful forest with friendly animals",
    "tree": "a big cartoon tree with green leaves",
    "flower": "a colorful cartoon flower in bloom",
    "rock": "a cartoon grey rock",
    "cloud": "a fluffy white cartoon cloud",
    "star": "a bright sparkling cartoon star",
    "dust": "cartoon dust cloud in the air",
    "stream": "a cartoon babbling brook with pebbles",

    # Food — appetizing cartoon illustrations
    "food": "a cartoon plate with colorful food",
    "meal": "a cartoon family dinner table with food",
    "banana": "a bright yellow cartoon banana",
    "yam": "a cartoon yam tuber vegetable",
    "cocoyam": "a cartoon taro root vegetable",
    "corn": "a cartoon yellow corn on the cob",
    "honey": "a cartoon honey jar with bees",
    "vegetable": "cartoon colorful vegetables in a basket",
    "potato": "a cartoon potato with a smile",
    "pawpaw": "a cartoon papaya fruit cut in half",
    "egg": "a cartoon cracked egg with yolk",
    "meat": "a cartoon meat drumstick",
    "rice": "a cartoon bowl of steaming white rice",
    "milk": "a cartoon glass of white milk",
    "orange": "a cartoon orange fruit",
    "tomato": "a cartoon red shiny tomato",
    "soup": "a cartoon bowl of colorful soup steaming",
    "guava": "a cartoon green guava fruit",
    "pineapple": "a cartoon pineapple with sunglasses",
    "coffee": "a cartoon steaming cup of coffee",
    "avocado": "a cartoon avocado cut in half",
    "onion": "a cartoon purple onion",
    "cassava": "a cartoon cassava root vegetable",
    "grape": "cartoon bunch of purple grapes",
    "pepper": "a cartoon red chili pepper",
    "mango": "a cartoon ripe mango fruit",
    "coconut": "a cartoon coconut cut open",
    "bread": "a cartoon loaf of bread",

    # Actions — show kids doing activities
    "eat": "a happy cartoon child eating food",
    "sleep": "a cartoon child sleeping peacefully in bed",
    "rest": "a cartoon child relaxing on a couch",
    "buy": "a cartoon child shopping at a store",
    "catch": "a cartoon child catching a ball",
    "walk": "a cartoon child walking happily",
    "kick": "a cartoon child kicking a soccer ball",
    "say": "a cartoon child talking with speech bubble",
    "laugh": "a cartoon child laughing out loud",
    "smile": "a cartoon child with a big smile",
    "cry": "a cartoon child with tears",
    "sing": "a cartoon child singing with music notes",
    "write": "a cartoon child writing with a pencil",
    "teach": "a cartoon teacher at a blackboard",
    "learn": "a cartoon child reading a book",
    "wash": "a cartoon child washing hands with soap",
    "prepare": "a cartoon child helping cook in kitchen",
    "run": "a cartoon child running fast",
    "jump": "a cartoon child jumping with joy",
    "dance": "a cartoon child dancing to music",
    "swim": "a cartoon child swimming in a pool",
    "climb": "a cartoon child climbing a tree",
    "fall": "a cartoon leaf falling from a tree",
    "fight": "two cartoon kids play-wrestling and laughing",
    "carry": "a cartoon child carrying a basket on head",
    "throw": "a cartoon child throwing a ball",
    "dig": "a cartoon child digging in a garden",
    "plant": "a cartoon child planting a seed in soil",
    "build": "a cartoon child building with blocks",
    "cook": "a cartoon child helping cook food",
    "drink": "a cartoon child drinking juice",
    "open": "a cartoon child opening a door",
    "close": "a cartoon child closing a box",
    "give": "a cartoon child giving a gift to friend",
    "take": "a cartoon child receiving a present",
    "sit": "a cartoon child sitting on a chair",
    "stand": "a cartoon child standing tall",
    "play": "cartoon children playing together happily",
    "work": "a cartoon person working at a desk",
    "call": "a cartoon child talking on a phone",
    "help": "a cartoon child helping another child up",
    "cut": "a cartoon child cutting paper with scissors",
    "pull": "a cartoon child pulling a wagon",
    "push": "a cartoon child pushing a toy car",
    "pour": "a cartoon child pouring water from a jug",
    "sew": "cartoon sewing needle and colorful thread",
    "grind": "cartoon mortar and pestle grinding grain",
    "harvest": "cartoon child picking vegetables in garden",
    "hunt": "cartoon bow and arrow target",
    "sell": "cartoon child at a lemonade stand",
    "count": "cartoon child counting on fingers",
    "measure": "cartoon ruler measuring something",
    "believe": "a cartoon child with hands together",
    "forget": "a cartoon confused child with question marks",
    "remember": "a cartoon child with lightbulb above head",
    "goodbye": "a cartoon child waving goodbye",

    # Things — colorful object illustrations
    "house": "a colorful cartoon house with a garden",
    "hut": "a cartoon African thatched roof hut",
    "room": "a cartoon bedroom with bed and toys",
    "soap": "a cartoon bar of soap with bubbles",
    "clothes": "cartoon colorful shirts and pants on a line",
    "car": "a cartoon red toy car",
    "book": "a cartoon open colorful book",
    "school": "a cartoon school building with children",
    "fire": "a cartoon campfire with orange flames",
    "chain": "cartoon colorful chain links",
    "rope": "a cartoon coiled rope",
    "box": "a cartoon open cardboard box",
    "ball": "a cartoon colorful bouncing ball",
    "door": "a cartoon colorful wooden door",
    "basket": "a cartoon woven basket with fruit",
    "plate": "a cartoon dinner plate",
    "trousers": "cartoon blue jeans trousers",
    "money": "cartoon gold coins and dollar bills",
    "instrument": "cartoon colorful musical instruments",
    "horn": "a cartoon musical horn trumpet",
    "mat": "a cartoon colorful woven mat",
    "machete": "a cartoon garden tool",
    "bamboo": "cartoon tall green bamboo stalks",
    "drum": "a cartoon colorful African drum",
    "key": "a cartoon golden key",
    "lamp": "a cartoon bright lamp glowing",
    "mirror": "a cartoon mirror with reflection",
    "broom": "a cartoon colorful broom",
    "bag": "a cartoon colorful school bag",
    "hat": "a cartoon colorful hat",
    "shoe": "a cartoon pair of colorful sneakers",
    "bell": "a cartoon golden bell ringing",
    "table": "a cartoon wooden table",
    "chair": "a cartoon colorful chair",
    "bed": "a cartoon cozy bed with pillow",
    "pot": "a cartoon cooking pot",
    "cup": "a cartoon colorful cup",
    "spoon": "a cartoon shiny spoon",
    "knife": "a cartoon butter knife",
    "candle": "a cartoon lit candle with warm glow",
    "bucket": "a cartoon colorful bucket",
    "pen": "a cartoon colorful pen",

    # Family — friendly diverse cartoon people
    "father": "a cartoon happy father with children",
    "mother": "a cartoon happy mother hugging child",
    "friend": "two cartoon children holding hands as friends",
    "husband": "a cartoon happy man",
    "wife": "a cartoon happy woman",
    "elder": "a cartoon friendly smiling grandfather with white hair",
    "chief": "a cartoon friendly African chief with colorful hat",
    "person": "a cartoon happy person waving",
    "boy": "a cartoon happy boy playing",
    "girl": "a cartoon happy girl playing",
    "baby": "a cute cartoon baby laughing",
    "child": "a cartoon happy child playing in garden",
    "servant": "a cartoon helpful person carrying items",
    "stranger": "a cartoon person waving hello",
    "orphan": "a cartoon gentle child alone",
    "widow": "a cartoon gentle woman",
    "twin": "cartoon twin children smiling identically",
    "warrior": "a cartoon brave kid superhero",
    "grandmother": "a cartoon friendly smiling grandmother",
    "grandfather": "a cartoon friendly smiling grandfather",
    "teacher": "a cartoon friendly teacher with books",
    "doctor": "a cartoon friendly doctor with stethoscope",
    "family": "a cartoon happy family together",

    # Descriptive — visual concept illustrations
    "big": "a cartoon big elephant next to a tiny mouse",
    "small": "a cartoon tiny ant next to a big shoe",
    "long": "a cartoon very long snake",
    "short": "a cartoon short penguin next to tall giraffe",
    "fat": "a cartoon round chubby cat",
    "thin": "a cartoon thin stick figure",
    "hard": "a cartoon solid grey rock",
    "soft": "a cartoon fluffy white pillow",
    "heavy": "a cartoon elephant standing on a scale",
    "light": "a cartoon floating feather in the air",
    "fast": "a cartoon cheetah running fast with speed lines",
    "slow": "a cute cartoon slow turtle",
    "hot": "a cartoon thermometer showing hot with sun",
    "cold": "a cartoon snowman in winter",
    "clean": "a cartoon sparkling clean room",
    "dirty": "a cartoon muddy dog",
    "bright": "a cartoon bright sun with rainbow",
    "dark": "a cartoon dark night with stars and moon",
    "beautiful": "a cartoon beautiful flower garden",
    "ugly": "a cartoon funny silly monster making a face",
    "clever": "a cartoon smart child with graduation cap",
    "empty": "a cartoon empty glass jar",
    "full": "a cartoon jar overflowing with candy",
    "round": "a cartoon collection of round balls",
    "straight": "a cartoon straight road to the horizon",
    "sweet": "cartoon colorful candies and lollipops",
    "bitter": "a cartoon lemon with a sour face",
    "dry": "a cartoon desert with cactus",
    "wet": "a cartoon child playing in rain puddle",
    "rich": "a cartoon treasure chest full of gold coins",
    "poor": "a cartoon simple small house",
    "alive": "a cartoon green plant growing from seed",
    "dead": "a cartoon withered brown tree",
    "happy": "a cartoon very happy smiling child",
    "sad": "a cartoon sad child with a tear",
    "angry": "a cartoon child with an angry face",
    "afraid": "a cartoon child scared hiding behind pillow",
    "tired": "a cartoon child yawning and sleepy",
    "hungry": "a cartoon child with empty plate looking sad",
    "sick": "a cartoon child in bed with thermometer",
    "young": "a cartoon cute baby",
    "old": "a cartoon friendly old man with walking stick",
    "new": "a cartoon shiny new toy in a box",
    "many": "cartoon many many colorful marbles",
    "few": "cartoon just three marbles",
    "tall": "a cartoon very tall giraffe",
    "alone": "a cartoon child sitting alone under a tree",
    "good": "a cartoon child giving thumbs up",
    "bad": "a cartoon broken toy",
    "strong": "a cartoon strong child flexing muscles",

    # Numbers
    "one": "cartoon number 1 with one apple",
    "two": "cartoon number 2 with two bananas",
    "three": "cartoon number 3 with three stars",
    "four": "cartoon number 4 with four flowers",
    "five": "cartoon number 5 with five fingers",
    "six": "cartoon number 6 with six butterflies",
    "seven": "cartoon number 7 with seven birds",
    "eight": "cartoon number 8 with eight balls",
    "nine": "cartoon number 9 with nine hearts",
    "ten": "cartoon number 10 with ten balloons",
}


# ============================================================
# EMOJI FALLBACK
# ============================================================

CATEGORY_FALLBACK_EMOJI = {
    "body": "1f9b4",
    "animals": "1f43e",
    "nature": "1f33f",
    "food": "1f37d-fe0f",
    "actions": "26a1",
    "things": "1f4e6",
    "family": "1f465",
    "descriptive": "1f4a1",
    "numbers": "1f522",
    "default": "2753",
}

EMOJI_CODEPOINTS = {
    # Body parts
    "hand": "270b", "head": "1f3a9", "nose": "1f443", "neck": "1f9e3",
    "back": "1f9ce", "shoulder": "1f933", "blood": "1fa78", "leg": "1f9b5",
    "tongue": "1f445", "body": "1f3cb-fe0f", "eye": "1f441-fe0f", "ear": "1f442",
    "liver": "2695-fe0f", "intestine": "1f9ec", "chest": "1f3bd", "breastbone": "1f9b4",
    "mouth": "1f444", "tooth": "1f9b7", "hair": "1f487", "bone": "1f9b4",
    "stomach": "1f95e", "hip": "1f57a", "foot": "1f9b6", "crown": "1f451",
    "beard": "1f9d4", "breast": "1f476", "knee": "1fa7c", "wing": "1fab6",
    "navel": "1faa2", "thigh": "1f356", "soul": "1f4ab", "spirit": "1f54a-fe0f",
    "heart": "2764-fe0f", "cheek": "1f48b", "chin": "1f910", "elbow": "1f4a2",
    "finger": "1f446", "jaw": "1f62c", "forehead": "1f9e0", "rib": "1f9b4",
    "palm": "1f91a", "throat": "1f3a4", "skin": "270d-fe0f", "waist": "1fa73",

    # Animals
    "fish": "1f41f", "owl": "1f989", "snake": "1f40d", "ram": "1f40f",
    "goat": "1f410", "dog": "1f415", "duck": "1f986", "cricket": "1f997",
    "chicken": "1f414", "cat": "1f408", "bird": "1f426", "elephant": "1f418",
    "lion": "1f981", "hippo": "1f99b", "antelope": "1f98c", "mosquito": "1f99f",
    "tortoise": "1f422", "pig": "1f437", "frog": "1f438", "toad": "1f438",
    "giraffe": "1f992", "donkey": "1facf", "leopard": "1f406", "butterfly": "1f98b",
    "rat": "1f400", "louse": "1fab3", "shrimp": "1f990", "locust": "1f997",
    "squirrel": "1f43f-fe0f", "rooster": "1f413", "bee": "1f41d", "ant": "1f41c",
    "spider": "1f577-fe0f", "cow": "1f404", "sheep": "1f411", "horse": "1f40e",
    "monkey": "1f435", "snail": "1f40c", "turtle": "1f422", "rabbit": "1f407",
    "mouse": "1f401", "bat": "1f987", "parrot": "1f99c", "whale": "1f40b",

    # Nature
    "river": "1f3de-fe0f", "water": "1f4a7", "sky": "1f30c", "sun": "2600-fe0f",
    "rain": "1f327-fe0f", "wind": "1f4a8", "grass": "1f33f", "thunder": "26a1",
    "night": "1f319", "morning": "1f305", "evening": "1f307", "road": "1f6e3-fe0f",
    "waterfall": "1f4a6", "ground": "1f3d5-fe0f", "shadow": "1f311",
    "valley": "1f304", "mountain": "1f3d4-fe0f", "moonlight": "1f31c",
    "forest": "1f332", "tree": "1f333", "flower": "1f338", "leaf": "1f343",
    "rock": "1faa8", "stone": "1faa8", "moon": "1f319", "star": "2b50",
    "cloud": "2601-fe0f", "lightning": "26a1", "storm": "26c8-fe0f",
    "snow": "2744-fe0f", "ice": "1f9ca", "lake": "1f30a", "sea": "1f30a",
    "stream": "1f30a", "dust": "1f32b-fe0f", "sand": "1f3d6-fe0f",
    "soil": "1f331", "hill": "26f0-fe0f",

    # Food
    "food": "1f37d-fe0f", "meal": "1f958", "banana": "1f34c", "yam": "1f360",
    "cocoyam": "1f96e", "corn": "1f33d", "honey": "1f36f", "vegetable": "1f96c",
    "potato": "1f954", "pawpaw": "1f348", "egg": "1f95a", "meat": "1f357",
    "rice": "1f35a", "milk": "1f95b", "orange": "1f34a", "tomato": "1f345",
    "soup": "1f372", "guava": "1f34f", "pineapple": "1f34d", "coffee": "2615",
    "avocado": "1f951", "onion": "1f9c5", "cassava": "1f96f", "grape": "1f347",
    "pepper": "1f336-fe0f", "bread": "1f35e", "salt": "1f9c2", "bean": "1fad8",
    "mango": "1f96d", "coconut": "1f965", "mushroom": "1f344", "nut": "1f330",
    "oil": "1fad7", "wine": "1f377", "beer": "1f37a", "tea": "1f375",

    # Actions
    "eat": "1f374", "sleep": "1f634", "rest": "1f6cb-fe0f", "buy": "1f6d2",
    "catch": "1f932", "walk": "1f6b6", "kick": "1f94b", "say": "1f5e3-fe0f",
    "laugh": "1f602", "smile": "1f604", "cry": "1f62d", "sing": "1f3b5",
    "write": "270f-fe0f", "teach": "1f468-200d-1f3eb", "learn": "1f4da",
    "goodbye": "1f44b", "wash": "1f6bf", "prepare": "1f373",
    "want": "1f914", "remember": "1f4cc", "believe": "1f64f", "forget": "1f635",
    "run": "1f3c3", "jump": "1f938", "give": "1f381", "take": "1f4e5",
    "come": "1f449", "go": "1f448", "sit": "1fa91", "stand": "1f9cd",
    "play": "1f3ae", "work": "1f4bc", "dance": "1f483", "swim": "1f3ca",
    "climb": "1f9d7", "fall": "2b07-fe0f", "drink": "1f964", "cook": "1f373",
    "fight": "1f94a", "die": "1f480", "love": "2764-fe0f", "hate": "1f620",
    "know": "1f393", "think": "1f4ad", "see": "1f440", "hear": "1f442",
    "call": "1f4de", "send": "1f4e8", "open": "1f513", "close": "274c",
    "begin": "25b6-fe0f", "finish": "1f3c1", "help": "1f198",
    "build": "1f3d7-fe0f", "break": "1f4a5", "cut": "2702-fe0f",
    "pull": "1f3a3", "push": "1f91b", "carry": "1f4e6", "throw": "1f93e",
    "pour": "1fad6", "sew": "1f9f5", "grind": "2699-fe0f", "dig": "26cf-fe0f",
    "plant": "1f331", "harvest": "1f33e", "hunt": "1f3f9", "kill": "1f5e1-fe0f",
    "steal": "1f977", "borrow": "1f91d", "lend": "1f4b3", "pay": "1f4b5",
    "sell": "1f3ea", "count": "1f522", "measure": "1f4cf",

    # Things
    "house": "1f3e0", "hut": "1f6d6", "room": "1f6aa", "soap": "1f9fc",
    "clothes": "1f455", "car": "1f697", "book": "1f4da", "school": "1f3eb",
    "fire": "1f525", "chain": "26d3-fe0f", "rope": "1f9f6", "box": "1f4e6",
    "ball": "26bd", "door": "1f6aa", "basket": "1f9fa", "plate": "1f37d-fe0f",
    "trousers": "1f456", "money": "1f4b0", "instrument": "1f3b8", "horn": "1f4ef",
    "mat": "1f9f1", "machete": "1fa93", "bamboo": "1f38b", "tax": "1f4b8",
    "table": "1f4cb", "chair": "1fa91", "bed": "1f6cf-fe0f", "pot": "1fad5",
    "cup": "1f943", "spoon": "1f944", "knife": "1f52a", "candle": "1f56f-fe0f",
    "hammer": "1f528", "axe": "1fa93", "needle": "1faa1", "bucket": "1faa3",
    "key": "1f511", "lock": "1f512", "mirror": "1fa9e", "broom": "1f9f9",
    "bag": "1f45c", "hat": "1f452", "shoe": "1f45f", "ring": "1f48d",
    "bell": "1f514", "drum": "1fa98", "flute": "1fa88", "gun": "1f52b",
    "bow": "1f3f9", "arrow": "1f3f9", "shield": "1f6e1-fe0f", "spear": "1fa93",
    "lamp": "1f4a1", "radio": "1f4fb", "phone": "1f4f1", "clock": "1f552",
    "picture": "1f5bc-fe0f", "flag": "1f3f3-fe0f", "cross": "271d-fe0f",
    "medicine": "1f48a", "pen": "1f58a-fe0f", "paper": "1f4c4",

    # Family
    "father": "1f468", "mother": "1f469", "friend": "1f46b", "husband": "1f468",
    "wife": "1f469", "elder": "1f474", "chief": "1f468-200d-2696-fe0f",
    "person": "1f9d1", "boy": "1f466", "son": "1f466", "girl": "1f467",
    "daughter": "1f467", "child": "1f476", "owner": "1f3e0", "servant": "1f9d1",
    "butcher": "1f52a", "country": "1f30d", "farm": "1f69c",
    "compound": "1f3d8-fe0f", "place": "1f4cd", "hospital": "1f3e5",
    "church": "26ea", "grandmother": "1f475", "grandfather": "1f474",
    "uncle": "1f468", "aunt": "1f469", "brother": "1f466", "sister": "1f467",
    "baby": "1f9d2", "teacher": "1f468-200d-1f3eb",
    "doctor": "1f468-200d-2695-fe0f", "king": "1f451", "queen": "1f478",
    "thief": "1f977", "stranger": "1f47e", "enemy": "1f47f",
    "neighbor": "1f3e1", "twin": "1f46c", "orphan": "1f97a",
    "widow": "1f469", "warrior": "1f93a", "judge": "1f468-200d-2696-fe0f",
    "woman": "1f469", "man": "1f468", "people": "1f465",

    # Descriptive
    "black": "2b1b", "white": "2b1c", "red": "1f534", "blue": "1f535",
    "green": "1f7e2", "big": "1f418", "small": "1f90f", "long": "27a1-fe0f",
    "short": "2b06-fe0f", "fat": "1f4a3", "thin": "1faa1", "good": "1f44d",
    "beautiful": "2728", "hot": "1f525", "cold": "2744-fe0f", "hard": "1faa8",
    "strong": "1f4aa", "new": "1f195", "old": "1f474", "many": "1f4ca",
    "few": "1f447", "today": "1f4c5", "tomorrow": "1f4c6", "yesterday": "1f4c3",
    "often": "1f504", "ugly": "1f616", "alone": "1f9cd", "truly": "2705",
    "clever": "1f9d0", "light": "2600-fe0f", "empty": "1fad9", "full": "1fad8",
    "clean": "1f9f9", "dirty": "1f922", "tall": "1f3e2", "dark": "1f319",
    "bright": "1f31e", "soft": "1fab6", "heavy": "1f3cb-fe0f", "fast": "1f3c3",
    "slow": "1f422", "happy": "1f60a", "sad": "1f622", "angry": "1f620",
    "afraid": "1f628", "tired": "1f62b", "hungry": "1f924", "sick": "1f912",
    "alive": "1f33b", "dead": "1f480", "rich": "1f911", "poor": "1f614",
    "young": "1f476", "sweet": "1f36c", "bitter": "1f43b", "dry": "1f3dc-fe0f",
    "wet": "1f4a6", "round": "1f7e0", "straight": "1f4d0",

    # Numbers
    "one": "31-fe0f-20e3", "two": "32-fe0f-20e3", "three": "33-fe0f-20e3",
    "four": "34-fe0f-20e3", "five": "35-fe0f-20e3", "six": "36-fe0f-20e3",
    "seven": "37-fe0f-20e3", "eight": "38-fe0f-20e3", "nine": "39-fe0f-20e3",
    "ten": "1f51f", "zero": "30-fe0f-20e3",
}


# ============================================================
# UTILITY FUNCTIONS
# ============================================================

def audio_key(awing_word: str) -> str:
    """Convert Awing word to safe ASCII filename (matches pronunciation_service.dart)."""
    char_map = {
        '\u025b': 'e', '\u0254': 'o', '\u0259': 'e', '\u0268': 'i',
        '\u014b': 'ng', "'": '', '"': '', "\u2019": '', "\u2018": '',
        '\u00e1': 'a', '\u00e0': 'a', '\u00e2': 'a', '\u01ce': 'a',
        '\u00e9': 'e', '\u00e8': 'e', '\u00ea': 'e', '\u011b': 'e',
        '\u00ed': 'i', '\u00ec': 'i', '\u00ee': 'i', '\u01d0': 'i',
        '\u00f3': 'o', '\u00f2': 'o', '\u00f4': 'o', '\u01d2': 'o',
        '\u00fa': 'u', '\u00f9': 'u', '\u00fb': 'u', '\u01d4': 'u',
        '\u025b\u0301': 'e', '\u025b\u0302': 'e', '\u025b\u030c': 'e',
        '\u0259\u0301': 'e', '\u0259\u0302': 'e', '\u0259\u030c': 'e',
        '\u0254\u0301': 'o', '\u0254\u0302': 'o', '\u0254\u030c': 'o',
        '\u0268\u0301': 'i', '\u0268\u0302': 'i', '\u0268\u030c': 'i',
    }
    result = ""
    for char in awing_word:
        result += char_map.get(char, char)
    result = result.lower()
    result = re.sub(r'[^a-z0-9]', '', result)
    return result


def parse_vocabulary() -> dict:
    """Parse Dart vocabulary file and extract all AwingWord entries."""
    vocabulary = {}
    if not VOCAB_FILE.exists():
        print(f"ERROR: Vocabulary file not found: {VOCAB_FILE}")
        sys.exit(1)

    with open(VOCAB_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = r"AwingWord\(\s*awing:\s*['\"]([^'\"]+)['\"]\s*,\s*english:\s*['\"]([^'\"]+)['\"]\s*,\s*category:\s*['\"]([^'\"]+)['\"]\s*"
    for match in re.finditer(pattern, content):
        awing, english, category = match.groups()
        key = audio_key(awing)
        vocabulary[key] = {
            "awing": awing,
            "english": english,
            "category": category,
        }
    return vocabulary


def get_ai_prompt(english_word: str, category: str) -> str:
    """Build an AI image generation prompt for a vocabulary word."""
    word_lower = english_word.lower().strip()

    # Strip parenthetical disambiguations like "(body part)" or "(drink)"
    clean_word = re.sub(r'\s*\(.*?\)', '', word_lower).strip()

    # Check overrides: full word, cleaned word, first word
    for w in [word_lower, clean_word, clean_word.split()[0] if ' ' in clean_word else None]:
        if w and w in PROMPT_OVERRIDES:
            return f"{PROMPT_OVERRIDES[w]}, {STYLE_SUFFIX}"

    # Default: build a prompt from the category
    category_prompts = {
        "body": f"a cartoon illustration of {clean_word} body part",
        "animals": f"a cute cartoon {clean_word} animal",
        "nature": f"a cartoon {clean_word} nature scene",
        "food": f"a cartoon {clean_word} food",
        "actions": f"a cartoon child doing {clean_word}",
        "things": f"a cartoon {clean_word}",
        "family": f"a cartoon friendly {clean_word}",
        "descriptive": f"a cartoon illustration showing the concept of {clean_word}",
        "numbers": f"cartoon number {clean_word} with objects to count",
    }
    base = category_prompts.get(category, f"a cartoon illustration of {clean_word}")
    return f"{base}, {STYLE_SUFFIX}"


# ============================================================
# LOCAL GPU IMAGE GENERATION (SDXL Turbo via diffusers)
# ============================================================

_pipeline = None  # Global pipeline — loaded once, reused for all images


def load_pipeline():
    """Load SDXL Turbo pipeline on GPU. Called once at start of generation."""
    global _pipeline
    if _pipeline is not None:
        return _pipeline

    try:
        import torch
        from diffusers import AutoPipelineForText2Image

        if not torch.cuda.is_available():
            print("ERROR: CUDA GPU not available. Use --emoji-only or install CUDA.")
            return None

        gpu_name = torch.cuda.get_device_name(0)
        vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        print(f"GPU: {gpu_name} ({vram_gb:.1f} GB VRAM)")

        print(f"Loading SDXL Turbo model (first time downloads ~5GB)...")
        _pipeline = AutoPipelineForText2Image.from_pretrained(
            SDXL_TURBO_MODEL,
            torch_dtype=torch.float16,
            variant="fp16",
        )
        _pipeline = _pipeline.to("cuda")

        # Optimize memory
        _pipeline.set_progress_bar_config(disable=True)
        try:
            _pipeline.enable_attention_slicing()
        except Exception:
            pass

        print(f"Model loaded successfully!\n")
        return _pipeline

    except ImportError as e:
        print(f"ERROR: Missing packages. Run:")
        print(f"  pip install diffusers transformers accelerate")
        print(f"  (Error: {e})")
        return None
    except Exception as e:
        print(f"ERROR loading model: {e}")
        return None


def generate_ai_image(prompt: str, seed: int) -> Image.Image | None:
    """Generate an image using SDXL Turbo on local GPU."""
    import torch

    pipe = load_pipeline()
    if pipe is None:
        return None

    try:
        generator = torch.Generator("cuda").manual_seed(seed)

        result = pipe(
            prompt=prompt,
            num_inference_steps=1,       # SDXL Turbo: 1 step is enough
            guidance_scale=0.0,          # SDXL Turbo: no guidance needed
            width=GENERATION_SIZE,
            height=GENERATION_SIZE,
            generator=generator,
        )

        img = result.images[0]
        return img.convert("RGB")

    except Exception as e:
        print(f"    GPU generation failed: {e}")
        return None


# ============================================================
# EMOJI FALLBACK
# ============================================================

def get_emoji_codepoint(english_word: str, category: str) -> str:
    """Get Twemoji codepoint for an English word, with category fallback."""
    word_lower = english_word.lower().strip()
    if word_lower in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[word_lower]
    first_word = word_lower.split()[0] if ' ' in word_lower else None
    if first_word and first_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[first_word]
    last_word = word_lower.split()[-1] if ' ' in word_lower else None
    if last_word and last_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[last_word]
    base_word = re.sub(r'\s*\(.*?\)', '', word_lower).strip()
    if base_word in EMOJI_CODEPOINTS:
        return EMOJI_CODEPOINTS[base_word]
    return CATEGORY_FALLBACK_EMOJI.get(category, CATEGORY_FALLBACK_EMOJI["default"])


def download_twemoji(codepoint: str) -> Image.Image | None:
    """Download a Twemoji PNG and return as PIL Image. Caches locally."""
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError, URLError

    EMOJI_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = EMOJI_CACHE_DIR / f"{codepoint}.png"

    if cache_file.exists() and cache_file.stat().st_size > 0:
        try:
            return Image.open(cache_file).convert("RGBA")
        except Exception:
            cache_file.unlink(missing_ok=True)

    url = f"{TWEMOJI_BASE}/{codepoint}.png"
    try:
        req = Request(url, headers={"User-Agent": "AwingAILearning/1.2"})
        with urlopen(req, timeout=10) as response:
            data = response.read()
        cache_file.write_bytes(data)
        return Image.open(cache_file).convert("RGBA")
    except (HTTPError, URLError, Exception):
        if "-fe0f" in codepoint:
            return download_twemoji(codepoint.replace("-fe0f", ""))
        return None


# ============================================================
# IMAGE POST-PROCESSING
# ============================================================

def create_rounded_rect_mask(size, radius):
    """Create a rounded rectangle alpha mask."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0]-1, size[1]-1)], radius=radius, fill=255)
    return mask


def crop_center_square(img: Image.Image) -> Image.Image:
    """Crop image to center square."""
    w, h = img.size
    size = min(w, h)
    left = (w - size) // 2
    top = (h - size) // 2
    return img.crop((left, top, left + size, top + size))


def finalize_image(img: Image.Image, category: str, output_path: Path) -> bool:
    """Apply category border, rounded corners, and save."""
    try:
        color = CATEGORY_COLORS.get(category, CATEGORY_COLORS["default"])

        # Crop to square and resize to final size
        square = crop_center_square(img)
        resized = square.resize((IMAGE_SIZE, IMAGE_SIZE), Image.LANCZOS)

        # Create canvas with colored border
        border_size = IMAGE_SIZE + BORDER_WIDTH * 2
        canvas = Image.new("RGB", (border_size, border_size), color)
        canvas.paste(resized, (BORDER_WIDTH, BORDER_WIDTH))

        # Resize back to IMAGE_SIZE (border included)
        final = canvas.resize((IMAGE_SIZE, IMAGE_SIZE), Image.LANCZOS)

        # Apply rounded corners
        mask = create_rounded_rect_mask((IMAGE_SIZE, IMAGE_SIZE), CORNER_RADIUS)
        result_rgba = final.convert("RGBA")
        bg = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (245, 245, 250, 255))
        result_rgba.putalpha(mask)
        bg.paste(result_rgba, (0, 0), result_rgba)
        final_rgb = bg.convert("RGB")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        final_rgb.save(str(output_path), "PNG", optimize=True)
        return True

    except Exception as e:
        print(f"  ERROR finalizing image: {e}")
        return False


def generate_emoji_image(english_word: str, category: str, output_path: Path) -> bool:
    """Generate a vocabulary image from Twemoji emoji (fallback)."""
    try:
        color = CATEGORY_COLORS.get(category, CATEGORY_COLORS["default"])
        top_color = tuple(min(255, c + 60) for c in color)

        # Create gradient card
        card = Image.new("RGB", (IMAGE_SIZE, IMAGE_SIZE), top_color)
        draw = ImageDraw.Draw(card)
        for y in range(IMAGE_SIZE):
            t = y / IMAGE_SIZE
            t_curved = t * t * (3 - 2 * t)
            r = int(top_color[0] + (color[0] - top_color[0]) * t_curved)
            g = int(top_color[1] + (color[1] - top_color[1]) * t_curved)
            b = int(top_color[2] + (color[2] - top_color[2]) * t_curved)
            draw.line([(0, y), (IMAGE_SIZE - 1, y)], fill=(r, g, b))

        # Get and paste emoji
        codepoint = get_emoji_codepoint(english_word, category)
        emoji_img = download_twemoji(codepoint)
        if emoji_img:
            emoji_resized = emoji_img.resize((150, 150), Image.LANCZOS)
            ex = (IMAGE_SIZE - 150) // 2
            ey = (IMAGE_SIZE - 150) // 2
            card.paste(emoji_resized, (ex, ey), emoji_resized)

        # Apply rounded corners
        mask = create_rounded_rect_mask((IMAGE_SIZE, IMAGE_SIZE), CORNER_RADIUS)
        card_rgba = card.convert("RGBA")
        card_rgba.putalpha(mask)
        bg = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (245, 245, 250, 255))
        bg.paste(card_rgba, (0, 0), card_rgba)
        final_rgb = bg.convert("RGB")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        final_rgb.save(str(output_path), "PNG", optimize=True)
        return True

    except Exception as e:
        print(f"  ERROR creating emoji image: {e}")
        return False


# ============================================================
# COMMANDS
# ============================================================

def cmd_generate(args):
    """Generate vocabulary images."""
    vocabulary = parse_vocabulary()
    if not vocabulary:
        print("ERROR: No vocabulary found in Dart file")
        sys.exit(1)

    if args.category:
        vocabulary = {k: v for k, v in vocabulary.items() if v["category"] == args.category}
        print(f"Generating {len(vocabulary)} images for category '{args.category}'...")
    else:
        print(f"Generating {len(vocabulary)} vocabulary images...")

    use_ai = not args.emoji_only

    if use_ai:
        print(f"Image source: SDXL Turbo on local GPU + emoji fallback")
        pipe = load_pipeline()
        if pipe is None:
            print("Falling back to emoji-only mode.")
            use_ai = False
    if not use_ai:
        print(f"Image source: Twemoji (emoji graphics)")

    print(f"Output: {OUTPUT_DIR}\n")

    generated = 0
    skipped = 0
    failed = 0
    ai_hits = 0
    emoji_used = 0
    start_time = time.time()

    for i, (key, word_data) in enumerate(sorted(vocabulary.items())):
        output_file = OUTPUT_DIR / f"{key}.png"

        if output_file.exists() and not args.force:
            skipped += 1
            continue

        english = word_data["english"]
        category = word_data["category"]
        used_ai = False

        # Try GPU AI generation first
        if use_ai:
            prompt = get_ai_prompt(english, category)
            seed = int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 2**31

            ai_img = generate_ai_image(prompt, seed)

            if ai_img:
                if finalize_image(ai_img, category, output_file):
                    generated += 1
                    ai_hits += 1
                    used_ai = True
                    if generated % 50 == 0 or generated <= 3:
                        elapsed = time.time() - start_time
                        rate = generated / elapsed if elapsed > 0 else 0
                        remaining = (len(vocabulary) - skipped - generated) / rate if rate > 0 else 0
                        print(f"  [{generated:4d}/{len(vocabulary)}] {english:30} (GPU) "
                              f"[{rate:.1f} img/s, ~{remaining/60:.0f}m left]")

        # Fall back to emoji
        if not used_ai:
            if generate_emoji_image(english, category, output_file):
                generated += 1
                emoji_used += 1
                if generated % 50 == 0 or (use_ai and emoji_used <= 3):
                    print(f"  [{generated:4d}/{len(vocabulary)}] {english:30} (emoji fallback)")
            else:
                failed += 1

    elapsed = time.time() - start_time
    print(f"\nGeneration complete in {elapsed:.0f}s ({elapsed/60:.1f} min):")
    print(f"  Generated: {generated}")
    print(f"  Skipped:   {skipped} (existing)")
    print(f"  Failed:    {failed}")
    if use_ai:
        print(f"  AI images: {ai_hits}")
        print(f"  Emoji:     {emoji_used} (AI failed)")
    if generated > 0:
        print(f"  Speed:     {generated / elapsed:.1f} images/second")
    print(f"  Output:    {OUTPUT_DIR}")


def cmd_test(args):
    """Generate a few test images to verify GPU pipeline works."""
    test_words = [
        ("elephant", "animals"),
        ("banana", "food"),
        ("house", "things"),
        ("happy", "descriptive"),
        ("mother", "family"),
    ]

    print("Generating 5 test images to verify GPU pipeline...\n")

    pipe = load_pipeline()
    if pipe is None:
        print("GPU not available. Cannot run test.")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for english, category in test_words:
        prompt = get_ai_prompt(english, category)
        seed = int(hashlib.md5(prompt.encode()).hexdigest()[:8], 16) % 2**31
        output_file = OUTPUT_DIR / f"_test_{english}.png"

        print(f"  Generating: {english} ...")
        start = time.time()
        img = generate_ai_image(prompt, seed)
        elapsed = time.time() - start

        if img:
            finalize_image(img, category, output_file)
            print(f"    OK ({elapsed:.1f}s) -> {output_file.name}")
        else:
            print(f"    FAILED ({elapsed:.1f}s)")

    print(f"\nTest images saved to: {OUTPUT_DIR}")
    print(f"Check _test_*.png files to verify quality before generating all images.")


def cmd_list(args):
    """List status of generated images."""
    vocabulary = parse_vocabulary()
    if not vocabulary:
        print("ERROR: No vocabulary found")
        sys.exit(1)

    categories = {}
    for word_data in vocabulary.values():
        cat = word_data["category"]
        categories[cat] = categories.get(cat, 0) + 1

    generated = sum(1 for key in vocabulary if (OUTPUT_DIR / f"{key}.png").exists())

    print(f"Vocabulary Image Status:")
    print(f"  Total words:      {len(vocabulary)}")
    print(f"  Generated images: {generated}")
    print(f"  Missing images:   {len(vocabulary) - generated}")
    print(f"\nBy category:")
    for cat in sorted(categories):
        count = categories[cat]
        existing = sum(1 for k, v in vocabulary.items()
                       if v["category"] == cat and (OUTPUT_DIR / f"{k}.png").exists())
        print(f"  {cat:15} : {existing:4}/{count:4}")

    print(f"\nImage source: SDXL Turbo (local GPU)")

    # Check GPU availability
    try:
        import torch
        if torch.cuda.is_available():
            gpu = torch.cuda.get_device_name(0)
            vram = torch.cuda.get_device_properties(0).total_memory / (1024**3)
            print(f"GPU: {gpu} ({vram:.1f} GB VRAM) - READY")
        else:
            print("GPU: CUDA not available - will use emoji fallback")
    except ImportError:
        print("GPU: diffusers not installed - will use emoji fallback")

    if EMOJI_CACHE_DIR.exists():
        cached = len(list(EMOJI_CACHE_DIR.glob("*.png")))
        print(f"Emoji cache: {cached} files")


def cmd_clean(args):
    """Remove generated images."""
    count = 0
    if OUTPUT_DIR.exists():
        for f in OUTPUT_DIR.glob("*.png"):
            if f.name != ".gitkeep":
                f.unlink()
                count += 1
    print(f"Cleaned {count} images from {OUTPUT_DIR}")

    if args.cache:
        for cache_dir in [EMOJI_CACHE_DIR]:
            cache_count = 0
            if cache_dir.exists():
                for f in cache_dir.glob("*.png"):
                    f.unlink()
                    cache_count += 1
            print(f"Cleaned {cache_count} cached files from {cache_dir}")


# ============================================================
# AUTO-VENV ACTIVATION
# ============================================================

def ensure_venv():
    """Auto-activate venv if not already active."""
    if sys.prefix != sys.base_prefix:
        return
    venv_dir = SCRIPT_DIR.parent / "venv"
    if not venv_dir.exists():
        venv_dir = SCRIPT_DIR.parent / "venv_torch"
    if venv_dir.exists():
        venv_python = venv_dir / ("Scripts" if sys.platform == "win32" else "bin") / ("python.exe" if sys.platform == "win32" else "python")
        if venv_python.exists():
            import subprocess
            result = subprocess.run([str(venv_python), __file__] + sys.argv[1:])
            sys.exit(result.returncode)


# ============================================================
# MAIN
# ============================================================

def main():
    ensure_venv()

    parser = argparse.ArgumentParser(
        description="Generate vocabulary images for Awing AI Learning (GPU AI + emoji)"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    gen_parser = subparsers.add_parser("generate", help="Generate vocabulary images")
    gen_parser.add_argument("--category", help="Generate for specific category only")
    gen_parser.add_argument("--force", action="store_true", help="Regenerate existing images")
    gen_parser.add_argument("--emoji-only", action="store_true", help="Use only emoji (skip GPU)")
    gen_parser.set_defaults(func=cmd_generate)

    test_parser = subparsers.add_parser("test", help="Generate 5 test images")
    test_parser.set_defaults(func=cmd_test)

    list_parser = subparsers.add_parser("list", help="Show generation status")
    list_parser.set_defaults(func=cmd_list)

    clean_parser = subparsers.add_parser("clean", help="Remove generated images")
    clean_parser.add_argument("--cache", action="store_true", help="Also clear emoji cache")
    clean_parser.set_defaults(func=cmd_clean)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
