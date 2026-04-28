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
import unicodedata
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
# AwingPhrase literals live in awing_vocabulary.dart alongside AwingWord.
# AwingSentence literals live in sentences_screen.dart.
# StorySentence literals live in stories_screen.dart.
PHRASES_FILE = VOCAB_FILE
SENTENCES_FILE = PROJECT_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
STORIES_FILE = PROJECT_ROOT / "lib" / "screens" / "stories_screen.dart"
# Default output: PAD install-time asset pack (for Play Store size limits)
# Override with --output-dir flag
OUTPUT_DIR = PROJECT_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "images" / "vocabulary"
EMOJI_CACHE_DIR = SCRIPT_DIR / "_emoji_cache"

# Filename length cap for sentence/story keys. Very long Awing sentences would
# produce illegal filenames on some filesystems; cap at 60 chars of the
# audio_key portion (excluding the "sentence_"/"story_" prefix).
MULTI_WORD_KEY_MAX = 60

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

    # Numbers (extended)
    "eleven": "cartoon number 11 with eleven stars",
    "twelve": "cartoon number 12 with twelve circles",
    "twenty": "cartoon number 20 with twenty dots",
    "thirty": "cartoon number 30",
    "forty": "cartoon number 40",
    "fifty": "cartoon number 50",
    "sixty": "cartoon number 60",
    "seventy": "cartoon number 70",
    "eighty": "cartoon number 80",
    "ninety": "cartoon number 90",
    "thirteen": "cartoon number 13",
    "fourteen": "cartoon number 14",
    "fifteen": "cartoon number 15",
    "sixteen": "cartoon number 16",
    "seventeen": "cartoon number 17",
    "eighteen": "cartoon number 18",
    "nineteen": "cartoon number 19",
    "twenty-one": "cartoon number 21",
    "twenty-two": "cartoon number 22",
    "twenty-three": "cartoon number 23",
    "twenty-four": "cartoon number 24",
    "twenty-five": "cartoon number 25",
    "two hundred": "cartoon number 200",
    "three hundred": "cartoon number 300",
    "four hundred": "cartoon number 400",
    "five hundred": "cartoon number 500",
    "hundred": "cartoon number 100 with confetti",
    "thousand": "cartoon number 1000 with fireworks",

    # Time & abstract concepts
    "month": "a cartoon calendar page showing one month",
    "moon": "a cartoon crescent moon in a night sky",
    "week": "a cartoon calendar showing seven days in a row",
    "day": "a cartoon bright sunny day with blue sky",
    "year": "a cartoon calendar with all twelve months",
    "time": "a cartoon colorful clock with happy face",
    "today": "a cartoon sun with the word TODAY on a calendar",
    "tomorrow": "a cartoon sunrise over hills with an arrow pointing forward",
    "yesterday": "a cartoon sunset with an arrow pointing backward",
    "morning": "a cartoon sunrise with a rooster crowing",
    "noon, mid-day": "a cartoon bright sun directly overhead at noon",
    "now": "a cartoon clock with hands pointing to the current moment",
    "early": "a cartoon child waking up at dawn with alarm clock",
    "late": "a cartoon child running to school in a hurry",
    "later": "a cartoon hourglass with sand flowing",
    "dawn": "a cartoon pink and orange dawn sky over hills",
    "season": "cartoon four seasons in quadrants: spring flowers, summer sun, autumn leaves, winter snow",
    "second": "a cartoon stopwatch showing one second tick",
    "never": "a cartoon circle with a line through it",
    "often/usually": "a cartoon repeating pattern of sunny days",
    "period (countable)": "a cartoon hourglass measuring time",
    "darkness": "a cartoon dark room with glowing eyes peeking out",

    # Pronouns & question words
    "he/she": "a cartoon boy and girl standing side by side waving",
    "you (singular)": "a cartoon finger pointing at the viewer friendly",
    "and": "a cartoon plus sign connecting two happy friends",

    # Body parts (additional)
    "armpit": "a cartoon child raising arm showing armpit",
    "anus": "a cartoon medical anatomy diagram simple",
    "bladder": "a cartoon simple kidney and bladder medical diagram",
    "lip": "a cartoon big smiling lips",
    "skull": "a cartoon friendly pirate skull with crossbones",
    "skeleton": "a cartoon friendly dancing skeleton",
    "nape of neck": "a cartoon showing the back of a childs head and neck",
    "palate": "a cartoon open mouth showing the roof of the mouth",
    "fist": "a cartoon raised fist bump",
    "knuckle, joint": "a cartoon hand making a fist showing knuckles",
    "joint": "a cartoon knee joint bending",
    "lung": "a cartoon pair of happy pink lungs breathing",
    "lungs, especially of animals": "a cartoon pair of lungs with air bubbles",
    "kidney": "a cartoon friendly kidney organ with a smile",
    "side (of body)": "a cartoon child pointing to their side",
    "sole of foot": "a cartoon bare foot showing the sole",
    "abdomen (external), stomach": "a cartoon child patting their tummy",
    "molar tooth": "a cartoon big molar tooth with a smile",
    "cartilage": "a cartoon ear showing cartilage",
    "vein. 2) root": "a cartoon tree with visible roots",
    "womb": "a cartoon stork carrying a baby bundle",
    "bile, gall": "a cartoon green gallbladder organ",
    "flesh, of living person": "a cartoon strong arm flexing muscle",

    # Medical & health
    "hernia": "a cartoon doctor examining a patient",
    "pus": "a cartoon small bandage on a scraped knee",
    "mucus": "a cartoon child with a runny nose and tissue",
    "nasal mucus": "a cartoon child blowing nose into tissue",
    "cough": "a cartoon child coughing into elbow",
    "sneeze": "a cartoon child sneezing with tissue",
    "illness": "a cartoon child in bed feeling unwell",
    "illness, of the skin": "a cartoon arm with red spots and itching",
    "exzema": "a cartoon arm with red itchy patches",
    "conjunctivitis": "a cartoon eye that looks red and irritated",
    "swelling": "a cartoon swollen finger with ice pack",
    "rheumatism": "a cartoon elderly person rubbing sore knee",
    "whooping cough": "a cartoon child coughing hard",
    "ringworm": "a cartoon circular red rash on skin",
    "scar": "a cartoon arm with a small healed scar",
    "bruise": "a cartoon knee with a purple bruise mark",
    "hiccough": "a cartoon child hiccupping with surprise",
    "frontal headache": "a cartoon child holding forehead in pain",
    "side pain": "a cartoon child holding their side",
    "blind person": "a cartoon person with sunglasses and white cane",
    "deaf person": "a cartoon person pointing to ear with hand cupped",
    "medicine man, traditional healer": "a cartoon friendly African healer with herbs",
    "traditional doctor": "a cartoon friendly doctor with herbal medicine",
    "spiritual healer": "a cartoon peaceful person meditating with light",
    "nurse": "a cartoon friendly nurse with cap and clipboard",
    "midwife": "a cartoon friendly nurse holding a baby",
    "hospital": "a cartoon hospital building with red cross",
    "disease, sort of": "a cartoon thermometer showing fever",
    "symtom of disease": "a cartoon child looking unwell with question marks",
    "poison": "a cartoon bottle with skull and crossbones warning label",
    "madness": "a cartoon swirly dizzy stars around a head",
    "mad person": "a cartoon dizzy person with stars around head",

    # Cultural terms
    "dowry (v)": "a cartoon bride and groom exchanging gifts at ceremony",
    "charm (fetish)": "a cartoon colorful African beaded necklace charm",
    "mask": "a cartoon colorful African ceremonial mask",
    "ancestors; les ancetre": "a cartoon family tree with old photos",
    "paramount chief": "a cartoon African king on a colorful throne",
    "chief/ruler": "a cartoon friendly chief with crown and staff",
    "compound": "a cartoon African village compound with several huts",
    "compound, residence": "a cartoon traditional African homestead",
    "courtyard": "a cartoon open courtyard with trees and benches",
    "council/meeting": "a cartoon group of people sitting in a circle talking",
    "balafon": "a cartoon colorful African xylophone instrument",
    "talking drum": "a cartoon hourglass-shaped African talking drum",
    "rattle (musical instrument)": "a cartoon colorful maraca shaker",
    "cowrie shell": "a cartoon shiny cowrie shell necklace",
    "cola nut": "a cartoon brown cola nut split open",
    "raffia palm": "a cartoon tall raffia palm tree",
    "palm wine": "a cartoon gourd with palm wine being tapped from tree",
    "palm tree": "a cartoon tropical palm tree",
    "palm fruit": "a cartoon bunch of red palm fruits",
    "palm branch": "a cartoon green palm leaf branch",
    "palm (of hand)": "a cartoon open palm of a hand",
    "palm oil": "a cartoon bottle of red palm oil",
    "dance group": "cartoon children in colorful costumes dancing together",
    "latrine": "a cartoon small outdoor toilet hut",
    "toilet, of the public": "a cartoon public restroom sign",
    "incense": "a cartoon incense stick with curling smoke",

    # Animals (additional)
    "cockroach": "a cartoon silly cockroach with big eyes",
    "caterpillar": "a cute cartoon green caterpillar on a leaf",
    "chameleon": "a colorful cartoon chameleon changing colors",
    "porcupine": "a cute cartoon porcupine with pointy quills",
    "bat. 2) fruit bat": "a cute cartoon fruit bat hanging upside down",
    "jackal": "a cartoon jackal in the savanna",
    "scorpion": "a cartoon scorpion with big claws",
    "worm": "a cute cartoon pink worm in soil",
    "termite": "a cartoon termite on a piece of wood",
    "hawk": "a cartoon hawk soaring in the sky",
    "dove": "a cartoon white dove with olive branch",
    "parrot": "a colorful cartoon parrot on a branch",
    "weaver-bird": "a cartoon weaver bird building a nest",
    "waxbill": "a cartoon small colorful waxbill bird",
    "cricket": "a cartoon cricket insect chirping",
    "grasshopper": "a cute cartoon grasshopper jumping",
    "mudfish": "a cartoon mudfish in shallow water",
    "crab": "a cute cartoon red crab on a beach",
    "pangolin": "a cute cartoon pangolin curled up",
    "buffalo": "a cartoon African buffalo in grassland",
    "wild cat": "a cartoon wild cat in the jungle",
    "lizard": "a cartoon colorful lizard on a rock",
    "army ant, soldier ant": "cartoon line of marching ants carrying leaves",
    "moth": "a cartoon moth flying near a lamp",
    "domestic animal": "a cartoon farm with chickens, goats and dog",
    "wild animal": "a cartoon lion and elephant in the wild",
    "guard dog": "a cartoon loyal guard dog sitting alert",
    "he-goat": "a cartoon male goat with horns",
    "hen": "a cartoon hen sitting on eggs in a nest",
    "shrew, name of animal": "a cartoon tiny shrew with a pointy nose",
    "puff adder": "a cartoon patterned puff adder snake",
    "insect": "cartoon colorful bugs and insects collection",
    "maggot (found in rotten meat)": "a cartoon wiggly white grub",

    # Nature (additional)
    "rainbow": "a cartoon bright rainbow over green hills",
    "swamp": "a cartoon marshy swamp with frogs and reeds",
    "marsh": "a cartoon wetland with tall grasses and birds",
    "lake": "a cartoon peaceful blue lake surrounded by trees",
    "sea": "a cartoon blue ocean with waves and fish",
    "ocean/sea": "a cartoon blue ocean with a sailing boat",
    "pool": "a cartoon deep blue pool of water",
    "hill": "a cartoon green grassy hill",
    "cave": "a cartoon dark cave entrance in a hillside",
    "ditch": "a cartoon ditch in the ground",
    "path": "a cartoon winding dirt path through trees",
    "sand": "a cartoon sandy beach with shells",
    "rust": "a cartoon rusty old key",
    "flood waters": "a cartoon river overflowing its banks",
    "drizzle": "cartoon light rain drizzle from grey clouds",
    "storm or wind; vent": "a cartoon stormy sky with wind and rain",
    "heaven": "a cartoon beautiful golden clouds with sunbeams",
    "dry season": "a cartoon dry brown savanna landscape with hot sun",
    "thorn": "a cartoon rose stem with sharp thorns",
    "leaf": "a cartoon bright green leaf",
    "flower": "a cartoon colorful flower blooming",
    "stem, of banana": "a cartoon banana plant stem with fruit",
    "seed": "a cartoon seed sprouting in soil",
    "mushroom": "a cartoon cute red and white mushroom",
    "beans": "cartoon colorful beans in a bowl",
    "groundnuts": "cartoon peanuts in their shells",
    "okra": "a cartoon green okra vegetable",
    "plantain": "a cartoon bunch of plantain bananas",
    "date palm": "a cartoon date palm tree with fruit clusters",
    "fig (tree)": "a cartoon fig tree with purple figs",
    "elephant grass": "a cartoon tall grass swaying in the wind",

    # Food (additional)
    "fufu corn": "a cartoon bowl of yellow fufu corn meal",
    "flour": "a cartoon bag of white flour",
    "sugar": "a cartoon pile of white sugar crystals",
    "sugar cane": "a cartoon stick of green sugar cane",
    "salt": "a cartoon salt shaker",
    "oil": "a cartoon bottle of cooking oil",
    "cooked rice": "a cartoon plate of steaming cooked rice",
    "breakfast": "a cartoon breakfast plate with eggs and toast",
    "food/meal": "a cartoon plate full of colorful food",
    "soup/sauce": "a cartoon bowl of soup with steam rising",
    "guinea corn": "a cartoon stalk of guinea corn grain",
    "fresh corn": "a cartoon ear of fresh green corn",
    "green pepper": "a cartoon green bell pepper",
    "red pepper": "a cartoon red hot pepper",
    "pumpkin": "a cartoon orange pumpkin",
    "carrot-like food": "a cartoon orange carrot",
    "pounded cocoyam": "a cartoon bowl of pounded cocoyam fufu",

    # Things/Objects (additional)
    "axe": "a cartoon woodcutting axe in a tree stump",
    "hoe": "a cartoon garden hoe tool",
    "needle": "a cartoon sewing needle with thread",
    "razor": "a cartoon razor blade",
    "chisel": "a cartoon chisel tool and wood",
    "sickle": "a cartoon curved sickle tool",
    "pestle": "a cartoon wooden pestle",
    "mortar": "a cartoon mortar bowl for grinding",
    "grinding stone": "a cartoon traditional grinding stone",
    "ladder": "a cartoon wooden ladder leaning on wall",
    "fence": "a cartoon wooden picket fence",
    "gate": "a cartoon colorful garden gate",
    "bridge": "a cartoon stone bridge over a river",
    "window": "a cartoon open window with curtains blowing",
    "roof of a house": "a cartoon thatched roof on a house",
    "ceiling": "a cartoon room looking up at the ceiling",
    "wall of a house": "a cartoon brick wall of a house",
    "wall, of a house": "a cartoon colorful house wall",
    "pillow": "a cartoon soft fluffy white pillow",
    "matress": "a cartoon bed mattress",
    "calabash": "a cartoon African gourd calabash",
    "goblet": "a cartoon golden goblet cup",
    "bowl": "a cartoon colorful ceramic bowl",
    "cooking pot": "a cartoon clay cooking pot on fire",
    "container": "a cartoon storage container with lid",
    "sieve": "a cartoon kitchen sieve strainer",
    "comb": "a cartoon colorful hair comb",
    "bracelet": "a cartoon colorful beaded bracelet",
    "necklace": "a cartoon colorful bead necklace",
    "helmet": "a cartoon safety helmet",
    "ring of any sort": "a cartoon shiny golden ring",
    "wire": "a cartoon coil of wire",
    "nail": "a cartoon metal nail and hammer",
    "peg": "a cartoon wooden clothes peg",
    "gun": "cartoon water gun toy squirting water",
    "trap": "a cartoon animal trap in the forest",
    "trap of any sort": "a cartoon mouse trap with cheese",
    "candle": "a cartoon glowing lit candle",
    "lamp": "a cartoon bright oil lamp glowing",
    "metal": "a cartoon shiny metal bar",
    "rubber": "a cartoon rubber band stretched",
    "chalk": "a cartoon piece of white chalk on blackboard",
    "thread": "a cartoon spool of colorful thread",
    "string": "a cartoon ball of string",
    "stick/staff": "a cartoon wooden walking stick",
    "firewood": "a cartoon bundle of firewood logs",
    "bulb": "a cartoon bright light bulb glowing",

    # Family & people (additional)
    "mother-in-law": "a cartoon friendly older woman with kind smile",
    "sister-in-law": "a cartoon friendly young woman waving",
    "sister/sibling": "cartoon two children as brother and sister together",
    "brother": "a cartoon boy with his arm around his brother",
    "nephew": "a cartoon young boy being hugged by uncle",
    "descendant": "a cartoon family tree showing generations",
    "acquaintance": "two cartoon people shaking hands meeting",
    "age group": "cartoon group of children same age playing together",
    "beggar": "a cartoon humble person sitting with a bowl",
    "hunter": "a cartoon hunter with bow and arrows in forest",
    "owner": "a cartoon person proudly holding a key to a house",
    "traveller, very mobile person": "a cartoon person walking with a bag on a journey",
    "messenger": "a cartoon person running to deliver a letter",
    "tax collector": "a cartoon person with clipboard collecting",
    "giver": "a cartoon child handing a gift to another",
    "seller or somebody who sells": "a cartoon market vendor at a stall",
    "reader": "a cartoon child reading a book happily",
    "host, \"nga nga ngedtapona owner of the compound": "a cartoon welcoming host at a door",
    "lazy person": "a cartoon person sleeping on a couch",
    "stupid person / fool": "a cartoon silly clown making a funny face",
    "deceitful person": "a cartoon person with crossed fingers behind back",
    "unmarried person": "a cartoon single person standing alone happy",
    "crowd": "a cartoon crowd of diverse happy people",
    "enemy": "two cartoon children with arms crossed facing away",
    "co-wife": "two cartoon women standing together",
    "disciple, follower": "a cartoon child following a teacher",

    # Actions (additional)
    "ask": "a cartoon child raising hand to ask a question",
    "ask, request": "a cartoon child politely asking with hands together",
    "agree": "two cartoon children shaking hands nodding",
    "announce, inform": "a cartoon child with a megaphone",
    "blow": "a cartoon child blowing out birthday candles",
    "bite": "a cartoon apple with a bite taken out",
    "breathe": "a cartoon child taking a deep breath of fresh air",
    "burn": "a cartoon campfire with bright flames",
    "chase": "a cartoon child chasing a butterfly",
    "chew": "a cartoon child chewing bubblegum with a bubble",
    "choose": "a cartoon child pointing at one of three colorful doors",
    "come": "a cartoon child walking toward with arms open",
    "come, approach": "a cartoon child walking toward with welcoming gesture",
    "cover": "a cartoon child covering a pot with a lid",
    "crawl": "a cartoon baby crawling on the floor happily",
    "cry, weep": "a cartoon child crying with big tears",
    "descend": "a cartoon child going down a slide",
    "destroy": "a cartoon child knocking down a block tower",
    "die": "a cartoon withered flower drooping",
    "disappear": "a cartoon magician making a rabbit vanish with poof",
    "dream": "a cartoon child sleeping with dream cloud above",
    "drip": "a cartoon water faucet dripping drops",
    "drown (intr)": "a cartoon person in water waving for help with lifering",
    "embrace": "two cartoon children hugging each other",
    "embrace, hug": "a cartoon parent hugging a child warmly",
    "enter": "a cartoon child walking through a doorway",
    "escape capture easily, skilled in evading capture": "a cartoon rabbit quickly escaping from a fox",
    "exchange": "two cartoon children trading toys",
    "fade": "a cartoon flower slowly losing its color",
    "fail, not work as planned": "a cartoon broken machine with smoke",
    "fill": "a cartoon glass being filled with orange juice",
    "find": "a cartoon child finding treasure in a box",
    "finish": "a cartoon child crossing a finish line with ribbon",
    "float": "a cartoon rubber duck floating on water",
    "fly": "a cartoon bird flying in the blue sky",
    "follow": "cartoon ducklings following their mother duck",
    "frighten": "a cartoon ghost saying boo to a surprised child",
    "fry": "a cartoon pan frying an egg with sizzle",
    "go": "a cartoon child walking forward on a path",
    "greet": "two cartoon children waving hello to each other",
    "groan": "a cartoon child moaning holding stomach",
    "growl": "a cartoon dog growling showing teeth playfully",
    "guard": "a cartoon guard standing at attention",
    "hang up": "a cartoon child hanging clothes on a clothesline",
    "have": "a cartoon child holding a toy proudly",
    "heal": "a cartoon wound with a bandage getting better with sparkles",
    "hear": "a cartoon child cupping ear to listen",
    "hide": "a cartoon child hiding behind a tree playing",
    "hit, strike (with hand)": "a cartoon hand hitting a drum",
    "hunt": "a cartoon archer aiming at a target",
    "imitate": "a cartoon child copying a monkey pose",
    "insult": "a cartoon angry speech bubble with scribbles",
    "join": "cartoon puzzle pieces clicking together",
    "keep": "a cartoon child putting coins in a piggy bank",
    "kiss": "a cartoon mother kissing childs forehead",
    "lack": "a cartoon empty shelf with cobwebs",
    "laugh": "a cartoon child laughing with tears of joy",
    "lick": "a cartoon child licking an ice cream cone",
    "lie (falsehood)": "a cartoon child with a growing Pinocchio nose",
    "lie down": "a cartoon child lying down on a soft mat",
    "lift": "a cartoon child lifting a box up",
    "limp": "a cartoon person walking with a limp and bandaged foot",
    "listen": "a cartoon child with headphones listening to music",
    "look at": "a cartoon child looking through a magnifying glass",
    "look for something": "a cartoon child searching under furniture for a lost toy",
    "love": "a cartoon big red heart with sparkles",
    "make": "a cartoon child making something with clay",
    "marry": "a cartoon happy wedding couple",
    "measure": "a cartoon child using a ruler to measure height",
    "melt": "a cartoon snowman melting in the sun",
    "mix": "a cartoon child stirring a bowl of colorful batter",
    "obey": "a cartoon child following instructions from teacher",
    "obtain": "a cartoon child receiving a trophy",
    "paint": "a cartoon child painting on an easel with bright colors",
    "pay": "a cartoon child handing coins to a shopkeeper",
    "peel many things": "a cartoon child peeling oranges",
    "persuade": "a cartoon child convincing friend to play",
    "pluck": "a cartoon child plucking fruit from a tree",
    "pound (with mortar)": "a cartoon person pounding food in a mortar",
    "pour": "a cartoon child pouring water from a pitcher",
    "praise": "a cartoon child clapping and cheering",
    "pray": "a cartoon child with hands together praying",
    "press": "a cartoon hand pressing a big red button",
    "protect": "a cartoon shield protecting a small animal",
    "quarrel": "two cartoon children arguing with speech bubbles",
    "read": "a cartoon child reading a book under a tree",
    "refuse": "a cartoon child shaking head no with crossed arms",
    "reject": "a cartoon hand pushing something away",
    "remember, remind": "a cartoon child with lightbulb above head remembering",
    "remove": "a cartoon child removing items from a box",
    "repent": "a cartoon child looking sorry with head down",
    "return": "a cartoon child walking back home with arrow",
    "save": "a cartoon superhero child saving a kitten from tree",
    "say/speak": "a cartoon child speaking with colorful speech bubble",
    "scatter, spread out (maize) (tr)": "a cartoon child spreading seeds on the ground",
    "search": "a cartoon child with magnifying glass searching",
    "see": "a cartoon pair of eyes looking with wonder",
    "sell": "a cartoon child at a market stall selling fruits",
    "send": "a cartoon child sending a paper airplane message",
    "separate": "cartoon two groups of colored blocks being sorted apart",
    "serve": "a cartoon child serving food on a plate",
    "sew": "a cartoon needle and thread sewing fabric",
    "share": "two cartoon children sharing a cookie",
    "sharpen": "a cartoon pencil being sharpened in a sharpener",
    "shine": "a cartoon sun shining brightly with rays",
    "shoot": "cartoon child shooting a basketball at a hoop",
    "shout": "a cartoon child shouting through cupped hands",
    "show": "a cartoon child pointing at something excitedly",
    "shut": "a cartoon door being closed",
    "sing": "a cartoon child singing with music notes floating",
    "smell": "a cartoon child smelling a flower happily",
    "snatch": "a cartoon bird snatching a fish from water",
    "snore": "a cartoon person sleeping with ZZZ above head",
    "speak, talk": "a cartoon child talking to a friend with speech bubbles",
    "spit": "a cartoon child spitting out yucky food",
    "spoil": "a cartoon broken toy on the floor",
    "squeeze": "a cartoon hand squeezing a lemon",
    "stab": "a cartoon fork poking into food",
    "stagger": "a cartoon dizzy person wobbling",
    "startle, surprise": "a cartoon child jumping in surprise",
    "step on, stamp (with feet)": "a cartoon foot stomping in a puddle",
    "stretch": "a cartoon child stretching arms wide in the morning",
    "stumble": "a cartoon child tripping over a rock",
    "suck": "a cartoon baby sucking on a pacifier",
    "suffer": "a cartoon sad child sitting in the rain",
    "survive": "a cartoon plant growing through a crack in concrete",
    "swallow": "a cartoon child swallowing medicine",
    "sweep (with broom)": "a cartoon child sweeping the floor with a broom",
    "swing": "a cartoon child swinging on a playground swing",
    "talk": "two cartoon children talking with speech bubbles",
    "tangle": "a cartoon ball of tangled yarn",
    "teach": "a cartoon teacher writing on a blackboard",
    "thank": "a cartoon child saying thank you with a bow",
    "think": "a cartoon child thinking with thought bubble",
    "threaten": "a cartoon storm cloud with lightning looking angry",
    "tickle": "a cartoon child being tickled and laughing",
    "trample": "cartoon footprints stomping through a garden",
    "try": "a cartoon child trying to reach a high shelf",
    "twist": "a cartoon twisted rope",
    "untie": "a cartoon child untying a knot in a rope",
    "urinate": "a cartoon child running to the bathroom urgently",
    "visit": "a cartoon child knocking on friends door",
    "wander": "a cartoon child walking through a meadow exploring",
    "wake up (intr)": "a cartoon child waking up and stretching in bed",
    "weave": "a cartoon person weaving a colorful basket",
    "whip, beat up": "a cartoon whip cracking in the air",
    "whistle": "a cartoon child whistling with music notes",
    "wipe": "a cartoon child wiping a table clean",
    "yawn": "a cartoon child yawning widely and sleepy",

    # Emotions & states
    "anger": "a cartoon angry red face with steam coming from ears",
    "happiness": "a cartoon child jumping with joy and sparkles",
    "fear": "a cartoon scared child hiding under blanket",
    "shame": "a cartoon child blushing and covering face",
    "pride": "a cartoon peacock with tail feathers spread",
    "confusion, disorder": "a cartoon child with swirly eyes and question marks",
    "excitement": "a cartoon child jumping up and down with joy",
    "disappointment": "a cartoon child with drooping shoulders and frown",
    "loneliness": "a cartoon child sitting alone looking out window",
    "hate": "a cartoon broken heart in two pieces",
    "hunger": "a cartoon child with empty plate and grumbling tummy",
    "patience": "a cartoon child calmly waiting with arms crossed",
    "kindness": "a cartoon child helping a small bird",
    "hope": "a cartoon child reaching for a bright star",
    "truth": "a cartoon shining golden light beam",
    "peace": "a cartoon dove flying with olive branch over rainbow",
    "evil": "a cartoon dark shadow with glowing red eyes",
    "sin": "a cartoon child looking guilty with broken vase",
    "blessing": "a cartoon golden sparkles falling from above",
    "comfort, petting": "a cartoon child gently petting a kitten",
    "luck, fortune": "a cartoon four-leaf clover with sparkles",
    "wisdom": "a cartoon wise owl wearing glasses reading a book",
    "strength": "a cartoon strong tree with deep roots",
    "trouble": "a cartoon child tangled in a mess of yarn",
    "hardship": "a cartoon child walking uphill in rain",
    "tiredness, fatigue": "a cartoon child dragging feet looking exhausted",
    "restlessness": "a cartoon child tossing and turning in bed",
    "forgiveness": "two cartoon children making up after a fight",
    "forgetfulness": "a cartoon child with thought bubble disappearing",
    "jealousy": "a cartoon child enviously looking at anothers toy",

    # Descriptive (additional)
    "black": "a cartoon solid black circle",
    "white": "a cartoon fluffy white cloud",
    "red": "a cartoon shiny red apple",
    "blue/green/dark": "a cartoon blue and green swirly ball",
    "narrow": "a cartoon narrow alleyway between buildings",
    "wide": "a cartoon wide open field with blue sky",
    "deep": "a cartoon deep swimming pool with depth markers",
    "sharp": "a cartoon sharp pencil point",
    "raw": "a cartoon raw egg cracked open",
    "raw/uncooked": "a cartoon raw vegetable and uncooked meat",
    "ripe/ready": "a cartoon ripe red tomato",
    "mature": "a cartoon tall fully grown tree",
    "salty": "a cartoon pretzel covered in salt crystals",
    "sour/bitter": "a cartoon lemon with puckered face",
    "sweet (like honey)": "a cartoon honey dripping from honeycomb",
    "loud/noisy": "a cartoon big speaker with sound waves",
    "quiet/silent": "a cartoon child with finger to lips saying shh",
    "difficult": "a cartoon child puzzling over a hard math problem",
    "crazy": "a cartoon swirly spiral doodle pattern",
    "lazy": "a cartoon cat sleeping on a hammock",
    "native": "a cartoon person in traditional African clothing",
    "average": "a cartoon scale perfectly balanced in the middle",
    "bony": "a cartoon thin fish showing bones",
    "broken": "a cartoon cracked plate in pieces",
    "important": "a cartoon golden trophy with star on top",
    "nice": "a cartoon child giving thumbs up with sparkly smile",
    "strange": "a cartoon alien with big curious eyes",
    "unusual, strange": "a cartoon weird-shaped purple cloud",
    "vain": "a cartoon peacock looking at itself in a mirror",
    "same": "cartoon two identical red apples side by side",
    "whole, total": "a cartoon complete circle pie chart",
    "few/little": "cartoon just two small marbles",
    "many/much": "cartoon overflowing basket of colorful marbles",
    "bright/clean": "a cartoon sparkling clean diamond",
    "clever/smart": "a cartoon child solving a puzzle easily",
    "hard/strong": "a cartoon solid rock",
    "fast/quick": "a cartoon rocket zooming through space",
    "slow/careful": "a cartoon turtle walking carefully",
    "fat/thick": "a cartoon round chubby hamster",
    "new/fresh": "a cartoon freshly picked bright flower",
    "long/far": "a cartoon very long road stretching into distance",
    "good/kind": "a cartoon child sharing food with a friend",
    "light (not heavy)": "a cartoon feather floating in air",
    "thin, lanky": "a cartoon tall thin giraffe",
    "round/circular": "a cartoon collection of circles and balls",
    "straight": "a cartoon straight arrow pointing forward",
    "digusting, dirty": "a cartoon muddy puddle with flies",

    # Abstract & misc concepts
    "life": "a cartoon tree of life with colorful leaves",
    "word": "a cartoon colorful word in a speech bubble",
    "word/language": "cartoon speech bubbles in many languages",
    "language": "a cartoon globe with speech bubbles around it",
    "name": "a cartoon name tag sticker saying HELLO",
    "song": "cartoon colorful music notes floating in the air",
    "voice": "a cartoon child singing with visible sound waves",
    "noise": "a cartoon drum making loud noise with motion lines",
    "news, message": "a cartoon newspaper with headlines",
    "message": "a cartoon sealed envelope with letter inside",
    "story/tale": "a cartoon open storybook with characters",
    "dream": "a cartoon child sleeping with colorful dream cloud",
    "idea": "a cartoon bright light bulb above a childs head",
    "mystery": "a cartoon question mark inside a treasure chest",
    "magic": "a cartoon magic wand with sparkles and stars",
    "number": "cartoon colorful numbers 1 2 3 floating",
    "class": "a cartoon classroom with desks and blackboard",
    "exam": "a cartoon child writing a test with pencil",
    "fashion": "a cartoon child in stylish colorful outfit",
    "habit": "a cartoon child brushing teeth routinely",
    "profit": "a cartoon graph going up with money symbols",
    "wealth": "a cartoon treasure chest overflowing with gold",
    "wealth, property": "a cartoon house with garden and car",
    "payment": "a cartoon hand giving coins to another hand",
    "subscription": "a cartoon magazine arriving in mailbox",
    "market": "a cartoon busy colorful outdoor market",
    "market stall": "a cartoon market stall with fruits and vegetables",
    "farm": "a cartoon farm with crops and animals",
    "village": "a cartoon small village with huts and trees",
    "village/villages": "a cartoon group of village huts among trees",
    "country": "a cartoon map with flag and mountains",
    "country/land": "a cartoon landscape with green hills and river",
    "place": "a cartoon signpost pointing to different places",
    "school": "a cartoon colorful school building with flag",
    "church": "a cartoon small church building with cross on top",
    "prison. 2) penalty, pumshment": "a cartoon cage with lock",
    "christianity": "a cartoon simple cross with golden light",
    "worshipping": "a cartoon person kneeling in prayer",
    "law": "a cartoon gavel and law book",
    "punishment": "a cartoon child in timeout corner",
    "theft": "a cartoon mask and bag of stolen goods",
    "thief": "a cartoon sneaky raccoon tiptoeing",
    "battle": "cartoon two toy armies facing each other",
    "war/wars": "cartoon toy soldiers and flags on a board game",
    "journey": "a cartoon winding road leading to mountains",
    "appearance": "a cartoon mirror showing a happy reflection",
    "direction of": "a cartoon compass with arrows pointing",
    "weight": "a cartoon scale with objects being weighed",
    "height": "a cartoon measuring tape next to a growing child",
    "speed": "a cartoon speedometer needle moving fast",
    "translation": "cartoon two speech bubbles with different languages",
    "response, answer": "a cartoon child raising hand to answer a question",
    "request, question": "a cartoon child with raised hand and question mark",
    "complaint, especially in court": "a cartoon person talking to a judge",
    "gossip": "two cartoon children whispering to each other",

    # Household & daily life
    "kitchen": "a cartoon colorful kitchen with pots and pans",
    "food or drinks given to a house of mourning": "a cartoon basket of food being delivered to a house",
    "entrance": "a cartoon welcoming doorway with welcome mat",
    "entrance hut": "a cartoon small hut at a village entrance",
    "playground. 2) palace assembly ground": "a cartoon playground with slides and swings",
    "inside": "a cartoon child peeking inside a box",
    "outside": "a cartoon child playing outside in the sun",
    "outside area": "a cartoon open yard with trees",
    "top, on top": "a cartoon bird sitting on top of a pole",
    "stool/chair (traditional)": "a cartoon traditional African wooden stool",
    "cloth, tied by women": "a cartoon woman in colorful wrapped cloth",

    # Senses & bodily functions
    "breath, soul, spirit (of living person)": "a cartoon person breathing out visible air",
    "saliva": "a cartoon child drooling over delicious food",
    "sweat": "a cartoon child sweating in the hot sun",
    "excrement": "a cartoon poop emoji with flies",
    "urine": "a cartoon yellow puddle with embarrassed face",
    "odour": "a cartoon wavy green smell lines from a sock",
    "perspire, sweat": "a cartoon child wiping sweat from forehead",

    # Religion & spiritual
    "saviour": "a cartoon heroic figure with cape saving someone",
    "supreme being": "a cartoon golden light from above in clouds",
    "baptise": "a cartoon person being sprinkled with water",
    "baptism": "a cartoon baptism with water drops and light",

    # Nature processes
    "growth ( of plants)": "a cartoon seed growing stages into a flower",
    "harvest": "a cartoon child picking ripe fruit from trees",
    "sow": "a cartoon child scattering seeds in soil",
    "wither eg a plant": "a cartoon plant wilting and drooping",
    "spread, of disease": "cartoon germs spreading from one person to another",

    # Qualities & states of things
    "color, kind, pattern": "a cartoon palette with many bright colors",
    "mark of identification. 2) ritual scar": "a cartoon badge or ID card",
    "spot, speckle": "a cartoon dalmatian dog with spots",
    "equivalent": "a cartoon equal sign between two objects",
    "togetherness": "cartoon children holding hands in a circle",
    "companionship": "a cartoon child walking with a dog companion",
    "possession": "a cartoon child holding their favorite toy tight",
    "total": "a cartoon calculator showing a sum total",

    # Misc actions & verbs
    "act, do": "a cartoon child performing in a play on stage",
    "appease": "a cartoon child offering a flower to make peace",
    "bark": "a cartoon dog barking with woof speech bubble",
    "bellow": "a cartoon cow mooing loudly",
    "bend down, stoop": "a cartoon child bending down to pick up a ball",
    "boast": "a cartoon child flexing muscles and bragging",
    "break": "a cartoon glass breaking into pieces",
    "carry on head": "a cartoon African woman carrying basket on head",
    "cheat": "a cartoon child peeking at another childs paper",
    "contradict": "two cartoon speech bubbles with opposite symbols",
    "crawl": "a cartoon baby crawling happily",
    "cross, traverse, pass through": "a cartoon child crossing a bridge",
    "despise": "a cartoon child turning nose up at vegetables",
    "domesticate": "a cartoon child training a puppy",
    "drag on the grown": "a cartoon child dragging a heavy bag on ground",
    "flatten": "a cartoon rolling pin flattening dough",
    "flip over": "a cartoon pancake being flipped in a pan",
    "gnaw": "a cartoon beaver gnawing on a log",
    "go round, surround": "cartoon children forming a circle around a tree",
    "grumble, complain": "a cartoon child with crossed arms grumbling",
    "harden": "a cartoon clay pot hardening in a kiln",
    "hasten up, hurry, be fast": "a cartoon child running fast with speed lines",
    "husk (corn)": "a cartoon ear of corn being husked",
    "insist, press on": "a cartoon determined child pushing a boulder",
    "lengthen": "a cartoon rubber band being stretched long",
    "lower (tr), decrease (intr)": "a cartoon arrow pointing downward",
    "manufacture": "a cartoon factory with colorful products",
    "mumble": "a cartoon child mumbling with fuzzy speech bubble",
    "overtake": "a cartoon rabbit running past a turtle",
    "provoke, taunt": "a cartoon child sticking tongue out teasing",
    "reduce ( eg sth that is overful or much)": "a cartoon shrinking pile of blocks",
    "replant": "a cartoon child replanting a small tree",
    "straighten": "a cartoon child straightening a bent wire",
    "succeed, make it": "a cartoon child reaching the top of a mountain",
    "support": "a cartoon child helping friend stand up",
    "swamp": "a cartoon marshy wetland with reeds",
    "tether (sheep, goats)": "a cartoon goat tied to a post in a field",
    "widen": "a cartoon road getting wider",
    "wring out, sqeeze": "a cartoon child wringing water from a cloth",

    # Slash-separated variants (matching logic only splits on space, not slash)
    "dog/dogs": "a cartoon happy puppy wagging its tail",
    "bag/bags": "cartoon colorful bags and backpacks",
    "bed/beds": "a cartoon cozy bed with blanket and pillow",
    "bed/beds (alt)": "a cartoon wooden bed frame with mattress",
    "boy/son": "a cartoon happy boy waving",
    "girl/daughter": "a cartoon happy girl playing",
    "leg/legs": "cartoon pair of legs running fast",
    "pot/pots": "cartoon collection of clay pots",
    "rope/ropes": "cartoon coiled ropes",
    "neck/necks": "a cartoon giraffe with long neck",
    "road/path": "a cartoon winding road through countryside",
    "river/stream": "a cartoon flowing river with rocks",
    "tree/trees": "cartoon group of colorful trees",
    "father/fathers": "a cartoon father and children",
    "father/parent": "a cartoon loving parent holding child hand",
    "mother/mothers": "a cartoon mother with children",
    "teacher/teachers": "a cartoon teacher in front of class",
    "hammer/hammers": "a cartoon hammer tool",
    "village/villages": "cartoon small village with huts",
    "war/wars": "cartoon toy soldiers on a board game",
    "corn/maize": "a cartoon ear of yellow corn",
    "food/meal": "a cartoon plate of colorful food",
    "soup/sauce": "a cartoon bowl of soup steaming",
    "word/language": "cartoon speech bubbles with words",
    "soul/spirit": "a cartoon glowing spirit light with sparkles",
    "kick/shoot": "a cartoon child kicking a soccer ball",
    "cry/weep": "a cartoon child crying with tears",
    "edge/end": "a cartoon cliff edge overlooking a valley",
    "ground/earth": "a cartoon earth soil with grass",
    "few/little": "cartoon just a few small marbles",
    "many/much": "cartoon very many colorful objects",
    "fat/thick": "a cartoon round chubby bear",
    "hard/strong": "a cartoon solid rock",
    "fast/quick": "a cartoon cheetah running with speed lines",
    "slow/careful": "a cartoon turtle walking carefully on a path",
    "bright/clean": "a cartoon sparkling clean surface",
    "clever/smart": "a cartoon child with graduation cap thinking",
    "new/fresh": "a cartoon shiny new gift in a box",
    "long/far": "a cartoon road stretching far into the distance",
    "good/kind": "a cartoon child sharing food with friend",
    "round/circular": "a cartoon perfect circle ball",
    "book/school": "a cartoon school building with books",
    "fire/burn": "a cartoon bright orange campfire",
    "machete/cutlass": "a cartoon farming machete tool",
    "catch/harvest": "a cartoon child catching fruit from tree",
    "count/calculate": "a cartoon child counting on abacus",
    "share/divide": "two cartoon children splitting a pie",
    "want/desire": "a cartoon child wishing on a star",
    "walk/travel": "a cartoon child walking on a journey",
    "say/speak": "a cartoon child talking with speech bubbles",
    "think/reflect": "a cartoon child sitting and thinking deeply",
    "mix/stir": "a cartoon spoon stirring a colorful mixture",
    "truly/really": "a cartoon checkmark in a green circle",
    "truly, really": "a cartoon shining truth badge",
    "stranger/visitor": "a cartoon person arriving at a door",
    "letter/writing": "a cartoon handwritten letter with envelope",
    "chief/ruler": "a cartoon chief with crown sitting on throne",
    "chicken, fowl": "a cartoon hen pecking at grain",
    "cheek, jaw": "a cartoon face showing cheek and jaw",

    # Common verbs with "be" prefix (state descriptions)
    "be heavy": "a cartoon elephant standing on a tiny scale",
    "be hot": "a cartoon thermometer in the red zone",
    "be kind": "a cartoon child offering flowers to friend",
    "be mad": "a cartoon dizzy swirly-eyed character",
    "be sick, (be) ill": "a cartoon child sick in bed with thermometer",
    "be tired": "a cartoon exhausted child slumping",
    "be clean": "a cartoon sparkling clean room",
    "be red": "a cartoon bright red circle",
    "be thin": "a cartoon very thin stick figure",
    "be fat, (be) thick": "a cartoon round puffy cloud",
    "be old (not young, not new)": "a cartoon ancient crumbling castle",
    "be smart": "a cartoon child in glasses solving a puzzle",
    "be pleased": "a cartoon happy child clapping hands",
    "be mature": "a cartoon fully grown tree with fruit",
    "be heavy": "a cartoon heavy anvil",
    "be jealous, be envious": "a cartoon child looking enviously at toy",
    "be wrong": "a cartoon red X mark",
    "be wide": "a cartoon very wide river",
    "be sticky": "a cartoon honey dripping sticky",
    "be stupid": "a cartoon confused person with question marks",
    "be used up": "a cartoon empty container turned upside down",
    "be blunt, eg a knife": "a cartoon dull butter knife",
    "be abundant, be much": "a cartoon overflowing basket of fruit",
    "be frugal": "a cartoon piggy bank with coins",
    "be restless, be unsettled": "a cartoon child tossing in bed",
    "be disappointed, witness the unexpected": "a cartoon child with dropped jaw surprise",
    "be too excited": "a cartoon child bouncing with excitement",

    # Common remaining words
    "ashes": "a cartoon pile of grey wood ashes",
    "ashes, wood ash": "a cartoon fireplace with grey ashes",
    "agreement": "two cartoon people shaking hands smiling",
    "birth day": "a cartoon birthday cake with candles",
    "blame": "a cartoon finger pointing accusingly",
    "braid/plait": "a cartoon girl with braided hair",
    "break": "a cartoon glass breaking into pieces",
    "butcher": "a cartoon butcher with apron at a meat counter",
    "bunch of banana": "a cartoon bunch of yellow bananas",
    "camp, encampment": "a cartoon campsite with tent and campfire",
    "cane, walking stick, club, cudgel": "a cartoon wooden walking cane",
    "claw": "a cartoon eagle claw",
    "clearing": "a cartoon forest clearing with sunlight",
    "decoration, embelishment": "cartoon colorful party decorations and streamers",
    "end": "a cartoon finish line with checkered flag",
    "everything": "a cartoon box overflowing with all kinds of objects",
    "fan": "a cartoon colorful handheld fan",
    "frown(n)": "a cartoon child frowning with eyebrows down",
    "hammer": "a cartoon claw hammer tool",
    "handle": "a cartoon door handle being turned",
    "harp": "a cartoon golden harp instrument",
    "hearth": "a cartoon warm fireplace hearth with fire",
    "hearth stone": "a cartoon stone fireplace with warm fire",
    "herd": "a cartoon herd of cows in a green field",
    "hippopotamus": "a cartoon happy hippo in water",
    "hole/pit": "a cartoon hole in the ground",
    "hunchback": "a cartoon turtle with a big shell on its back",
    "hunting": "a cartoon bow and arrow with target",
    "intestines": "a cartoon simplified digestive system diagram",
    "jigger": "a cartoon tiny bug under magnifying glass",
    "judge": "a cartoon wise judge with gavel",
    "kind": "a cartoon child being kind helping a bird",
    "kola nut": "a cartoon brown cola nut split open",
    "lance, spear": "a cartoon African spear",
    "little": "a cartoon tiny ant next to a big leaf",
    "lock": "a cartoon padlock with key",
    "lock of hair": "a cartoon curly lock of hair",
    "mad": "a cartoon angry face with steam",
    "medicine": "a cartoon bottle of medicine with spoon",
    "misplace": "a cartoon child looking for lost keys",
    "mistake": "a cartoon oops speech bubble with eraser",
    "mourning, crying": "a cartoon person crying at a memorial",
    "musical instrument": "cartoon colorful collection of musical instruments",
    "nest": "a cartoon birds nest with eggs in a tree",
    "pit": "a cartoon deep pit in the ground",
    "poorly": "a cartoon sick child wrapped in blanket",
    "ready": "a cartoon child in starting position for a race",
    "response": "a cartoon speech bubble with reply arrow",
    "stone": "a cartoon smooth grey stone",
    "tax": "a cartoon stack of coins with receipt",
    "thing": "a cartoon mystery box with question mark",
    "thing, something": "a cartoon colorful wrapped present",
    "twins": "cartoon identical twin children smiling together",
    "venom (of snake), stinger": "a cartoon snake with drops of venom",
    "watch/wait": "a cartoon child watching and waiting patiently",
    "wise saying": "a cartoon owl with wise speech bubble",
    "worry, feel disturbed": "a cartoon child with worried thought bubble",
    "worry, restlessness": "a cartoon anxious child biting nails",
    "widowhood": "a cartoon gentle woman in remembrance",
    "spark of fire": "a cartoon bright orange spark flying from flint",
    "excrement": "a cartoon brown poop emoji with flies",
    "stool/chair (traditional)": "a cartoon traditional wooden African stool",
    "physical exercise": "a cartoon child doing jumping jacks",
    "dream": "a cartoon child sleeping with colorful dream cloud",
    "journey": "a cartoon winding road leading to sunset mountains",
    "sing": "a cartoon child singing with floating music notes",
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
    """Convert Awing word to safe ASCII filename (matches pronunciation_service.dart).

    This is the AUDIO namespace key — one clip per (awing) spelling regardless
    of English gloss. Used by generate_audio_edge.py for MP3 filenames AND by
    the app's pronunciation_service.dart to look up recordings.

    For IMAGE filenames, use `image_key(awing, english)` instead — that key
    appends a slug of the English gloss so homonyms (té1 "learn" vs té2 "sit")
    each get their own illustration.
    """
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


# Maximum chars of the english slug appended to image filenames. Keeps
# `{audio_key}__{english_slug}.png` filenames well under common filesystem
# limits (Windows MAX_PATH + PAD asset name sanity) even when audio_key is
# itself long (phrase_*/sentence_*/story_* namespaces already cap at 60).
ENGLISH_SLUG_MAX = 32


def english_slug(english: str) -> str:
    """Slugify an English gloss for use as a filename suffix.

    Design goals:
    - Deterministic across runs so cached images are reused.
    - Short (<= ENGLISH_SLUG_MAX chars) — filename hygiene.
    - Preserves enough word identity that homonyms produce different slugs,
      while collapsing punctuation/case differences so trivial edits to the
      gloss don't invalidate the cache.
    - Must match `_englishSlug()` in lib/services/image_service.dart — same
    normalization, same truncation point. Any change here MUST be mirrored
    there or the app will look for images under a different filename than
    the generator wrote.

    Examples:
      "neck (body part)"              -> "neck_body_part"
      "learn; study"                  -> "learn_study"
      "to walk quickly"               -> "to_walk_quickly"
      "a very long definition ..."    -> truncated to ENGLISH_SLUG_MAX
    """
    s = english.lower()
    # Strip accents/diacritics so the slug is pure ASCII.
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    # Anything non-alphanumeric -> underscore.
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = s.strip("_")
    if not s:
        # Pathological: english field was all punctuation. Fall back to a
        # stable hash so we still produce a unique filename.
        s = hashlib.md5(english.encode("utf-8")).hexdigest()[:8]
    if len(s) > ENGLISH_SLUG_MAX:
        s = s[:ENGLISH_SLUG_MAX].rstrip("_")
    return s


def image_key(awing_word: str, english: str) -> str:
    """Filename key for the illustration of a single AwingWord entry.

    Format: '{audio_key(awing_word)}__{english_slug(english)}'

    Unlike `audio_key()`, this includes the English gloss so homonyms
    (té1/té2) and near-homonyms that collapse under the lossy audio_key
    normalization (high-tone vs low-tone pairs) each produce their own image.

    Double underscore separator is chosen because `audio_key` output is
    `[a-z0-9]` only — no underscores — so the separator is unambiguous and
    the suffix can be split back off if needed.
    """
    return f"{audio_key(awing_word)}__{english_slug(english)}"


def parse_vocabulary() -> dict:
    """Parse Dart vocabulary file and extract all AwingWord entries.

    Notes:
    - Dart strings can be single- or double-quoted and contain escape
      sequences like \\' inside a single-quoted string. The previous regex
      (`[^'\\\"]+`) silently dropped any entry whose english field contained
      an escaped apostrophe — that was ~700 entries from the merged
      dictionary block.
    - Keys are built via `image_key(awing, english)` so each literal in the
      Dart source produces its OWN filename. Homonyms (té1 "learn" vs té2
      "sit"), low/high-tone pairs that collapse under the lossy audio_key,
      and near-homographs all survive as independent images.
    - When two literals share BOTH awing spelling AND english gloss (a true
      source-data duplicate in awing_vocabulary.dart), we still give each its
      own unique image key by appending `__N` where N is the 2-based ordinal
      of the duplicate (first occurrence = base key, second = `__2`, etc.).
      The Dart-side `imageKey(awing, english)` lookup computes the BASE key
      only, so the app always displays the first-occurrence image; the
      indexed variants exist on disk to satisfy "one image per literal"
      bookkeeping but are not consumed by the app until/unless a smarter
      picker is added. If you'd prefer one image per unique (awing, english)
      pair instead, de-dupe the Dart file and this function will naturally
      stop emitting `__N` suffixes.
    """
    vocabulary: dict = {}
    if not VOCAB_FILE.exists():
        print(f"ERROR: Vocabulary file not found: {VOCAB_FILE}")
        sys.exit(1)

    with open(VOCAB_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Dart string body: single-quoted (allows \\') OR double-quoted (allows \\").
    sq = r"'((?:\\.|[^'\\])*)'"      # 'foo bar', 'don\'t'
    dq = r'"((?:\\.|[^"\\])*)"'      # "foo bar"
    s = rf"(?:{sq}|{dq})"

    # Build full pattern. Each string slot has TWO capture groups (sq, dq); we
    # take whichever matched. dotall lets multi-line AwingWord(...) entries match.
    pattern = (
        r"AwingWord\(\s*"
        r"awing:\s*" + s + r"\s*,\s*"
        r"english:\s*" + s + r"\s*,\s*"
        r"category:\s*" + s
    )

    def _unescape(s: str) -> str:
        return re.sub(r"\\(.)", r"\1", s)

    total_literals = 0
    source_duplicates = 0
    # Count how many times each base key has been seen, so we can append
    # `__2`, `__3`, ... for source-data duplicates.
    base_key_occurrence: dict = {}
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        # groups: (awing_sq, awing_dq, english_sq, english_dq, category_sq, category_dq)
        awing = _unescape(g[0] if g[0] is not None else g[1]).strip()
        english = _unescape(g[2] if g[2] is not None else g[3]).strip()
        category = _unescape(g[4] if g[4] is not None else g[5]).strip()
        if not awing or not english or not category:
            continue

        total_literals += 1
        base = image_key(awing, english)
        seen = base_key_occurrence.get(base, 0)
        if seen == 0:
            key = base
        else:
            # Nth occurrence (N starts at 2). These extra files are written to
            # disk but NOT looked up by the app — see docstring.
            key = f"{base}__{seen + 1}"
            source_duplicates += 1
        base_key_occurrence[base] = seen + 1

        vocabulary[key] = {
            "awing": awing,
            "english": english,
            "category": category,
        }

    if total_literals:
        msg = (f"Parsed {total_literals} AwingWord literals -> "
               f"{len(vocabulary)} unique image keys")
        if source_duplicates:
            msg += (f"  [NOTE: {source_duplicates} indexed variants "
                    f"(source-data duplicates)]")
        print(msg)
    return vocabulary


# Dart string body: single-quoted (allows \\') OR double-quoted (allows \\").
_DART_SQ = r"'((?:\\.|[^'\\])*)'"
_DART_DQ = r'"((?:\\.|[^"\\])*)"'
_DART_STR = rf"(?:{_DART_SQ}|{_DART_DQ})"


def _dart_unescape(s: str) -> str:
    return re.sub(r"\\(.)", r"\1", s)


def _pick(groups: tuple, idx: int) -> str:
    """Pick whichever of two adjacent (sq, dq) capture groups matched."""
    return _dart_unescape(groups[idx] if groups[idx] is not None else groups[idx + 1]).strip()


def _multi_word_key(prefix: str, awing: str) -> str:
    """Build namespaced key for phrase/sentence/story.

    Format: '{prefix}_{audio_key(awing)[:MULTI_WORD_KEY_MAX]}'
    The cap keeps Play Asset Pack filenames sane (max path length + reasonable
    filesystem hygiene) while remaining deterministic under reorderings —
    two sentences with the same first ~60 ASCII-normalized chars would
    collide, but that's vanishingly unlikely across our 70-item corpus.
    """
    k = audio_key(awing)
    if len(k) > MULTI_WORD_KEY_MAX:
        k = k[:MULTI_WORD_KEY_MAX]
    return f"{prefix}_{k}"


def parse_phrases() -> dict:
    """Parse AwingPhrase literals from awing_vocabulary.dart.

    Keys are prefixed 'phrase_' to avoid colliding with AwingWord image keys.
    Returns: {key: {awing, english, category}}. The 'category' slot uses the
    phrase's own category field (greeting/daily/question/classroom/farewell)
    so get_ai_prompt() can branch on it.
    """
    if not PHRASES_FILE.exists():
        return {}

    with open(PHRASES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # AwingPhrase(awing: '...', english: '...', ...category: '...'...)
    # The category field comes later in the literal — capture it separately
    # with a non-greedy lookahead so we don't overrun into the next literal.
    pattern = (
        r"AwingPhrase\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR + r"\s*,"
        r"(?:[^)]*?category:\s*" + _DART_STR + r")?"
    )

    phrases: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        # groups: (awing_sq, awing_dq, english_sq, english_dq, category_sq?, category_dq?)
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        # Category may be missing from the regex match; default to "phrase".
        category = ""
        if len(g) >= 6 and (g[4] is not None or g[5] is not None):
            category = _pick(g, 4)
        total += 1
        key = _multi_word_key("phrase", awing)
        phrases[key] = {
            "awing": awing,
            "english": english,
            "category": "phrase",  # always route through phrase prompt
            "subcategory": category,  # greeting/daily/question/...
        }

    if total:
        print(f"Parsed {total} AwingPhrase literals -> {len(phrases)} unique phrase keys")
    return phrases


def parse_sentences() -> dict:
    """Parse AwingSentence literals from sentences_screen.dart.

    Keys are prefixed 'sentence_' to avoid colliding with any other image keys.
    AwingSentence schema: {awing: String, english: String, words: List<AwingWord>}.
    """
    if not SENTENCES_FILE.exists():
        return {}

    with open(SENTENCES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = (
        r"AwingSentence\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR
    )

    sentences: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        total += 1
        key = _multi_word_key("sentence", awing)
        sentences[key] = {
            "awing": awing,
            "english": english,
            "category": "sentence",
        }

    if total:
        print(f"Parsed {total} AwingSentence literals -> {len(sentences)} unique sentence keys")
    return sentences


def parse_stories() -> dict:
    """Parse StorySentence literals from stories_screen.dart.

    Keys are prefixed 'story_' to avoid colliding with any other image keys.
    StorySentence schema: {awing: String, english: String}.
    """
    if not STORIES_FILE.exists():
        return {}

    with open(STORIES_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = (
        r"StorySentence\(\s*"
        r"awing:\s*" + _DART_STR + r"\s*,\s*"
        r"english:\s*" + _DART_STR
    )

    stories: dict = {}
    total = 0
    for match in re.finditer(pattern, content, flags=re.DOTALL):
        g = match.groups()
        awing = _pick(g, 0)
        english = _pick(g, 2)
        if not awing or not english:
            continue
        total += 1
        key = _multi_word_key("story", awing)
        stories[key] = {
            "awing": awing,
            "english": english,
            "category": "story",
        }

    if total:
        print(f"Parsed {total} StorySentence literals -> {len(stories)} unique story keys")
    return stories


def shorten_english_for_prompt(english_word: str) -> str:
    """Reduce a (possibly long) dictionary definition to a short noun/verb phrase
    suitable for SDXL/CLIP. CLIP truncates at 77 tokens, so feeding it a full
    definition like "ya. some children are very greedy such that you give
    something to a child and ask for it the same moment and he hardens the
    hand. v. s : ńtyantə" both wastes prompt budget AND drops the actual word.
    Goal: extract the first short concrete English gloss.
    """
    s = english_word.strip().lower()

    # 1. Strip parentheticals: "hand (body part)" -> "hand"
    s = re.sub(r"\s*\(.*?\)", "", s).strip()

    # 2. Drop everything after cross-reference markers or heavy punctuation.
    #    "foo; see bar" -> "foo". Include "v. s" / "n. s" as cross-ref cues
    #    (Awing dict uses them to point at a synonym in another entry).
    s = re.split(
        r"[;:]|\bsee\b|\bcf\b|\bsyn\b|\bant\b|\be\.?g\.?\b|\bi\.?e\.?\b|\bv\.\s*s\b|\bn\.\s*s\b",
        s, maxsplit=1)[0].strip()

    # 3. Drop leading part-of-speech tags (BEFORE splitting on period — the
    #    "n." in "n. house" is a POS abbreviation, not a sentence boundary).
    s = re.sub(r"^(?:n\.p|v\.p|n\.|v\.|adj\.|adv\.|pron\.|prep\.|conj\.|interj\.|num\.|ideo\.|c\.n)\s+",
               "", s).strip()

    # 4. Drop leading interjection-style prefix like "ya.", "oh,", "well,".
    #    Must come BEFORE sentence-boundary split so "ya. children are greedy"
    #    becomes "children are greedy" not "ya".
    s = re.sub(r"^(?:ya|oh|well|hey|ah|er|um|hmm)[,.\s]+", "", s).strip()

    # 5. Split on sentence boundary — keep first sentence only, to drop long
    #    example clauses. BUT: if the first sentence is 2 words or fewer, it's
    #    probably a headword repetition like "house." and we want the rest.
    parts = re.split(r"\.\s+", s, maxsplit=1)
    if len(parts) == 2 and len(parts[0].split()) <= 2 and len(parts[1].strip()) >= 3:
        s = parts[1]
    else:
        s = parts[0]
    s = s.rstrip(".").strip()

    # 6. Strip leading POS again in case it was embedded: "v. walk quickly"
    #    after cross-ref split becomes "v. walk quickly".
    s = re.sub(r"^(?:n\.p|v\.p|n\.|v\.|adj\.|adv\.|pron\.|prep\.|conj\.|interj\.|num\.|ideo\.|c\.n)\s+",
               "", s).strip()

    # 7. Numbered glosses: "1) abdomen 2) buttock" -> "abdomen"
    m = re.match(r"^\s*\d+\)\s*([^0-9)]+?)(?:\s*\d+\)|$)", s)
    if m:
        s = m.group(1).strip()

    # 8. Collapse whitespace, cap at first 6 words. CLIP token budget after
    #    the STYLE_SUFFIX is ~30 tokens; 6 short English words fits comfortably.
    s = re.sub(r"\s+", " ", s).strip(",.;: ")
    words = s.split()
    if len(words) > 6:
        s = " ".join(words[:6])
    return s or english_word.strip().lower()


def get_ai_prompt(english_word: str, category: str) -> str:
    """Build an AI image generation prompt for a vocabulary word/phrase/sentence/story."""

    # Multi-word content (phrase / sentence / story) takes a different prompt
    # path. Their english field is a full translation like "He went to the
    # market" or "Mbachia, Apena and Mbyaabo are climbing a tree" — running
    # those through shorten_english_for_prompt() (which is tuned to distil
    # dictionary entries down to a single gloss word) would mangle the
    # meaning. Use the full sentence, capped at ~15 words so the final
    # prompt (with STYLE_SUFFIX appended) stays under CLIP's 77-token budget.
    if category in ("phrase", "sentence", "story"):
        text = english_word.strip().rstrip(".!?\"'").strip()
        words = text.split()
        if len(words) > 15:
            text = " ".join(words[:15])
        templates = {
            "phrase": f"a cartoon scene of a child saying: {text}",
            "sentence": f"a cartoon scene illustrating: {text}",
            "story": f"a cartoon storybook scene showing: {text}",
        }
        return f"{templates[category]}, {STYLE_SUFFIX}"

    word_lower = english_word.lower().strip()

    # Reduce long dictionary definitions to short gloss BEFORE override lookup
    # so the override check actually matches the headword (not the long defn).
    short_word = shorten_english_for_prompt(english_word)

    # Strip parenthetical disambiguations like "(body part)" or "(drink)"
    clean_word = re.sub(r'\s*\(.*?\)', '', short_word).strip()

    # Check overrides: short gloss first, then cleaned word, then first word
    for w in [short_word, clean_word, clean_word.split()[0] if ' ' in clean_word else None]:
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
        cap = torch.cuda.get_device_capability(0)
        print(f"GPU: {gpu_name} ({vram_gb:.1f} GB VRAM, compute capability sm_{cap[0]}{cap[1]})")
        print(f"PyTorch: {torch.__version__} (CUDA build: {torch.version.cuda})")

        # Detect compute-capability mismatch up front. The "no kernel image"
        # error happens silently per-tensor otherwise.
        try:
            _probe = torch.zeros(1, device="cuda")
            _probe = _probe + 1.0
            torch.cuda.synchronize()
        except Exception as e:
            msg = str(e)
            if "no kernel image" in msg.lower() or "kernel image" in msg.lower():
                print()
                print("=" * 70)
                print("ERROR: PyTorch wheel does not support your GPU.")
                print(f"  GPU compute capability: sm_{cap[0]}{cap[1]}")
                print(f"  PyTorch CUDA build:     {torch.version.cuda}")
                print()
                print("Likely fix (newer GPU like RTX 50-series, Blackwell sm_120):")
                print("  venv\\Scripts\\pip install --upgrade --force-reinstall \\")
                print("    torch torchvision torchaudio \\")
                print("    --index-url https://download.pytorch.org/whl/cu128")
                print()
                print("Older GPU (Maxwell sm_50, Pascal sm_61, etc.) — try nightly:")
                print("  venv\\Scripts\\pip install --upgrade --force-reinstall \\")
                print("    --pre torch torchvision torchaudio \\")
                print("    --index-url https://download.pytorch.org/whl/nightly/cu124")
                print()
                print("Or skip GPU generation (uses emoji fallback for new words):")
                print("  python scripts\\generate_images.py generate --emoji-only")
                print("=" * 70)
                return None
            raise

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
    """Generate vocabulary images (plus phrases, sentences, stories)."""
    vocabulary = parse_vocabulary()
    if not vocabulary:
        print("ERROR: No vocabulary found in Dart file")
        sys.exit(1)

    # Merge phrases, sentences, and stories into the same generation pass.
    # Their parsers emit namespaced keys (phrase_*, sentence_*, story_*) so
    # they can't collide with word keys, and their category slot routes them
    # through the multi-word branch of get_ai_prompt().
    phrase_count = sentence_count = story_count = 0
    phrases = parse_phrases()
    if phrases:
        phrase_count = len(phrases)
        vocabulary.update(phrases)
    sentences = parse_sentences()
    if sentences:
        sentence_count = len(sentences)
        vocabulary.update(sentences)
    stories = parse_stories()
    if stories:
        story_count = len(stories)
        vocabulary.update(stories)

    word_count = len(vocabulary) - phrase_count - sentence_count - story_count
    print(f"Sources:  {word_count} words + {phrase_count} phrases + "
          f"{sentence_count} sentences + {story_count} stories "
          f"= {len(vocabulary)} total")

    if args.category:
        vocabulary = {k: v for k, v in vocabulary.items() if v["category"] == args.category}
        print(f"Generating {len(vocabulary)} images for category '{args.category}'...")

    # --word filter: match against audio_key, english_slug, full compound key, english gloss,
    # or Awing word (case-insensitive, substring OK for gloss and compound key).
    # Use when SDXL Turbo drifts off-prompt and you need to regenerate a handful of specific
    # words without rerunning the full 15-min pipeline. Implicit --force: matched words
    # always overwrite their existing images.
    #
    # Since image keys are now compound ({audio_key}__{english_slug}), bare "ap" no longer
    # equals any key. We match against the audio_key component AND the english_slug component
    # AND the full compound key via substring, so users can target words by any unambiguous
    # fragment they remember.
    if getattr(args, "word", None):
        needles = [w.strip().lower() for w in args.word.split(",") if w.strip()]
        filtered = {}
        for k, v in vocabulary.items():
            eng_lc = v["english"].lower()
            awing_lc = v.get("awing", "").lower()
            ak = audio_key(v["awing"])
            es = english_slug(v["english"])
            match = False
            for n in needles:
                if n == ak or n == es or n == awing_lc:
                    match = True
                    break
                if n in k or n in eng_lc:
                    match = True
                    break
            if match:
                filtered[k] = v
        if not filtered:
            print(f"ERROR: No vocabulary matched --word={args.word}")
            print(f"       Tried matching against audio_key, english_slug, compound key,")
            print(f"       english gloss (substring), and Awing word.")
            sys.exit(1)
        vocabulary = filtered
        args.force = True  # implicit — user asked for these specific words
        print(f"Regenerating {len(vocabulary)} image(s) matching --word={args.word}:")
        for k, v in sorted(vocabulary.items()):
            print(f"  {k:40}  {v['awing']:20}  ({v['english']})")
        print()
    elif not args.category:
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
    """List status of generated images across all 4 namespaces."""
    words = parse_vocabulary()
    phrases = parse_phrases()
    sentences = parse_sentences()
    stories = parse_stories()

    if not words:
        print("ERROR: No vocabulary found")
        sys.exit(1)

    def _status(label: str, source: dict) -> None:
        if not source:
            print(f"  {label:12}: (none)")
            return
        existing = sum(1 for k in source if (OUTPUT_DIR / f"{k}.png").exists())
        print(f"  {label:12}: {existing:4}/{len(source):4}  ({len(source) - existing} missing)")

    print(f"Image Status (by namespace):")
    _status("Words",     words)
    _status("Phrases",   phrases)
    _status("Sentences", sentences)
    _status("Stories",   stories)

    total_source = len(words) + len(phrases) + len(sentences) + len(stories)
    total_generated = (
        sum(1 for k in words     if (OUTPUT_DIR / f"{k}.png").exists())
        + sum(1 for k in phrases   if (OUTPUT_DIR / f"{k}.png").exists())
        + sum(1 for k in sentences if (OUTPUT_DIR / f"{k}.png").exists())
        + sum(1 for k in stories   if (OUTPUT_DIR / f"{k}.png").exists())
    )
    print(f"\nTotal: {total_generated}/{total_source} images generated "
          f"({total_source - total_generated} missing)")

    categories = {}
    for word_data in words.values():
        cat = word_data["category"]
        categories[cat] = categories.get(cat, 0) + 1

    print(f"\nWord categories:")
    for cat in sorted(categories):
        count = categories[cat]
        existing = sum(1 for k, v in words.items()
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
    global OUTPUT_DIR
    ensure_venv()

    parser = argparse.ArgumentParser(
        description="Generate vocabulary images for Awing AI Learning (GPU AI + emoji)"
    )
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Override image output directory")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    gen_parser = subparsers.add_parser("generate", help="Generate vocabulary images")
    gen_parser.add_argument("--category", help="Generate for specific category only")
    gen_parser.add_argument("--force", action="store_true", help="Regenerate existing images")
    gen_parser.add_argument("--emoji-only", action="store_true", help="Use only emoji (skip GPU)")
    gen_parser.add_argument("--word",
                            help="Only regenerate specific words (comma-separated). "
                                 "Matches against audio_key, Awing word, or English gloss. "
                                 "Implies --force. Examples: --word=bird  --word=sange,mbene,goat")
    gen_parser.set_defaults(func=cmd_generate)

    test_parser = subparsers.add_parser("test", help="Generate 5 test images")
    test_parser.set_defaults(func=cmd_test)

    list_parser = subparsers.add_parser("list", help="Show generation status")
    list_parser.set_defaults(func=cmd_list)

    clean_parser = subparsers.add_parser("clean", help="Remove generated images")
    clean_parser.add_argument("--cache", action="store_true", help="Also clear emoji cache")
    clean_parser.set_defaults(func=cmd_clean)

    args = parser.parse_args()

    # Override output directory if specified
    if args.output_dir:
        OUTPUT_DIR = Path(args.output_dir)

    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
