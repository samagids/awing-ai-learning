/// Awing tone system data from AwingOrthography2005.pdf
///
/// Awing has 3 tone levels + 2 glides:
///   High (á) — marked with acute accent
///   Mid (a)  — unmarked (same diacritic as high in practice)
///   Low (a)  — unmarked (no diacritic)
///   Rising (ǎ) — marked with caron
///   Falling (â) — marked with circumflex

class ToneInfo {
  final String name;
  final String symbol;
  final String ipaNotation;
  final String description;
  final String exampleWord;
  final String exampleEnglish;

  const ToneInfo({
    required this.name,
    required this.symbol,
    required this.ipaNotation,
    required this.description,
    required this.exampleWord,
    required this.exampleEnglish,
  });
}

const List<ToneInfo> awingTones = [
  ToneInfo(
    name: 'High',
    symbol: 'á',
    ipaNotation: '[á]',
    description: 'Your voice goes UP. Like asking a question!',
    exampleWord: 'kóŋɔ́',
    exampleEnglish: 'ditch',
  ),
  ToneInfo(
    name: 'Mid',
    symbol: 'a',
    ipaNotation: '[ā]',
    description: 'Your voice stays in the MIDDLE. Nice and steady!',
    exampleWord: 'kóŋə',
    exampleEnglish: 'flow',
  ),
  ToneInfo(
    name: 'Low',
    symbol: 'a',
    ipaNotation: '[à]',
    description: 'Your voice goes DOWN. Like a deep hum!',
    exampleWord: 'koŋə',
    exampleEnglish: 'owl',
  ),
  ToneInfo(
    name: 'Rising',
    symbol: 'ǎ',
    ipaNotation: '[ǎ]',
    description: 'Your voice starts low then goes UP — like a siren!',
    exampleWord: 'mǎ',
    exampleEnglish: 'mother',
  ),
  ToneInfo(
    name: 'Falling',
    symbol: 'â',
    ipaNotation: '[â]',
    description: 'Your voice starts high then goes DOWN — like sliding!',
    exampleWord: 'nətô',
    exampleEnglish: 'intestine',
  ),
];

/// Rules for kids to remember about tones
const List<String> toneRulesForKids = [
  'Tone can change the meaning of a word completely!',
  '"kóŋɔ́" (high) = ditch, "koŋə" (low) = owl — same sound, different tone!',
  'High tone: voice goes UP ↑',
  'Low tone: voice goes DOWN ↓',
  'Rising tone: voice slides UP from low ↗',
  'Falling tone: voice slides DOWN from high ↘',
  'When two vowels are next to each other, only mark tone on the FIRST one.',
];

/// Consonant cluster types for medium/expert levels
class ConsonantCluster {
  final String type; // 'prenasalized', 'palatalized', 'labialized'
  final String cluster;
  final String grapheme;
  final String exampleWord;
  final String exampleEnglish;
  final String description;

  const ConsonantCluster({
    required this.type,
    required this.cluster,
    required this.grapheme,
    required this.exampleWord,
    required this.exampleEnglish,
    required this.description,
  });
}

const List<ConsonantCluster> prenasalizedClusters = [
  ConsonantCluster(type: 'prenasalized', cluster: '/Ǹb/', grapheme: 'Mb mb', exampleWord: "mbe'tə", exampleEnglish: 'shoulder', description: 'Say "m" then "b" quickly together'),
  ConsonantCluster(type: 'prenasalized', cluster: '/Ǹt/', grapheme: 'Nt nt', exampleWord: 'ntɔ́əmə', exampleEnglish: 'heart', description: 'Say "n" then "t" quickly together'),
  ConsonantCluster(type: 'prenasalized', cluster: '/Ǹd/', grapheme: 'Nd nd', exampleWord: 'ndě', exampleEnglish: 'neck', description: 'Say "n" then "d" quickly together'),
  ConsonantCluster(type: 'prenasalized', cluster: '/Ǹk/', grapheme: 'Nk nk', exampleWord: 'nkadtə', exampleEnglish: 'back', description: 'Say "n" then "k" quickly together'),
  ConsonantCluster(type: 'prenasalized', cluster: '/Ǹg/', grapheme: 'Ng ng', exampleWord: "ngɔ́'ə", exampleEnglish: 'hardship', description: 'Say "n" then "g" quickly together'),
];

const List<ConsonantCluster> palatalizedClusters = [
  ConsonantCluster(type: 'palatalized', cluster: '/tj/', grapheme: 'Ty ty', exampleWord: "tyá'lə", exampleEnglish: 'straddle', description: 'Say "t" with a "y" sound after it'),
  ConsonantCluster(type: 'palatalized', cluster: '/kj/', grapheme: 'Ky ky', exampleWord: 'kyagɔ́', exampleEnglish: 'untie', description: 'Say "k" with a "y" sound after it'),
  ConsonantCluster(type: 'palatalized', cluster: '/fj/', grapheme: 'Fy fy', exampleWord: 'fyáalə', exampleEnglish: 'chase', description: 'Say "f" with a "y" sound after it'),
];

const List<ConsonantCluster> labializedClusters = [
  ConsonantCluster(type: 'labialized', cluster: '/tw/', grapheme: 'Tw tw', exampleWord: 'twɔ́ŋə', exampleEnglish: 'bury', description: 'Say "t" with rounded lips like "w"'),
  ConsonantCluster(type: 'labialized', cluster: '/kw/', grapheme: 'Kw kw', exampleWord: 'kwágə', exampleEnglish: 'cough', description: 'Say "k" with rounded lips like "w"'),
  ConsonantCluster(type: 'labialized', cluster: '/fw/', grapheme: 'Fw fw', exampleWord: "fwɔ'ə", exampleEnglish: 'chisel', description: 'Say "f" with rounded lips like "w"'),
];

/// Orthography rules from the PDF — important for writing correctly
const List<String> consonantOrthographyRules = [
  'Never write "r" — if you hear an "r", write "l" instead.',
  'Never write "\'" or "d" at the beginning of a word.',
  'Never write "b" at the beginning — write "p" or "mb" instead.',
  'Never write "p" after "m" — write "b" instead.',
  'Never write a consonant as the last letter (except nda\' = "only").',
  'Nasal before "b" → write "m". Nasal before anything else → write "n".',
  'Always write "gh" (never just "g") at the beginning of words.',
  'Always write "ng" (never "ngh") when "g" follows a nasal.',
];

const List<String> vowelOrthographyRules = [
  'Never write "yə" after a consonant — write "iə" instead.',
  'Never write "wə" after a consonant — write "uə" instead.',
  'Never write "e" at the beginning of a word — write "ə" instead.',
];

/// ── Phonology data from "A Phonological Sketch of Awing" (van den Berg, 2009)

/// Vowel chart: 9 vowels arranged by height and position (3×3 grid)
class AwingVowel {
  final String vowel;
  final String height; // 'high', 'mid', 'low'
  final String position; // 'front', 'central', 'back'
  final String description;
  final String exampleWord;
  final String exampleEnglish;
  final bool hasLongForm;

  const AwingVowel({
    required this.vowel,
    required this.height,
    required this.position,
    required this.description,
    required this.exampleWord,
    required this.exampleEnglish,
    this.hasLongForm = false,
  });
}

const List<AwingVowel> awingVowels = [
  AwingVowel(vowel: 'i', height: 'high', position: 'front', description: 'Like "ee" in "see"', exampleWord: 'pímə', exampleEnglish: 'see', hasLongForm: false),
  AwingVowel(vowel: 'ɨ', height: 'high', position: 'central', description: 'Between "i" and "u" — lips neutral', exampleWord: 'yîkə', exampleEnglish: 'harden', hasLongForm: false),
  AwingVowel(vowel: 'u', height: 'high', position: 'back', description: 'Like "oo" in "food"', exampleWord: 'lúmə', exampleEnglish: 'bite', hasLongForm: true),
  AwingVowel(vowel: 'e', height: 'mid', position: 'front', description: 'Like "ay" in "say"', exampleWord: 'ndě', exampleEnglish: 'neck', hasLongForm: true),
  AwingVowel(vowel: 'ə', height: 'mid', position: 'central', description: 'Like "a" in "about" — schwa', exampleWord: 'əshûə', exampleEnglish: 'fish', hasLongForm: true),
  AwingVowel(vowel: 'o', height: 'mid', position: 'back', description: 'Like "o" in "go"', exampleWord: 'nô', exampleEnglish: 'drink', hasLongForm: true),
  AwingVowel(vowel: 'ɛ', height: 'low', position: 'front', description: 'Like "e" in "bed"', exampleWord: 'fɛlə', exampleEnglish: 'breastbone', hasLongForm: true),
  AwingVowel(vowel: 'a', height: 'low', position: 'central', description: 'Like "a" in "father"', exampleWord: 'apô', exampleEnglish: 'hand', hasLongForm: true),
  AwingVowel(vowel: 'ɔ', height: 'low', position: 'back', description: 'Like "aw" in "law"', exampleWord: 'nəkəŋɔ́', exampleEnglish: 'pot', hasLongForm: true),
];

/// 7 contrastive long vowels (only in first syllable of root)
const List<Map<String, String>> longVowelExamples = [
  {'vowel': 'eː', 'word': 'apéenə', 'english': 'bread', 'contrast': 'apènə (outside)'},
  {'vowel': 'ɛː', 'word': 'tsɛ̀ːrɔ́', 'english': 'defeat', 'contrast': 'tsɛ́rə (stop up)'},
  {'vowel': 'əː', 'word': 'dzəːmə', 'english': 'dream', 'contrast': 'dzəmə (back)'},
  {'vowel': 'aː', 'word': 'akuáːrə', 'english': 'support', 'contrast': 'short a is very common'},
  {'vowel': 'oː', 'word': 'afòːnə', 'english': 'hunting', 'contrast': 'short o is very common'},
  {'vowel': 'ɔː', 'word': 'fwɔ̀ːtə', 'english': 'mumble', 'contrast': 'fwɔ̀ʔə (hollow out)'},
  {'vowel': 'uː', 'word': 'nəkwùːnɔ́', 'english': 'entrance', 'contrast': 'nəkwúnə (local rice)'},
];

/// 3 vowel sequences (high vowel + ə)
const List<Map<String, String>> vowelSequences = [
  {'sequence': 'iə', 'example': 'atîə', 'english': 'tree', 'note': 'Most common — many examples'},
  {'sequence': 'ɨə', 'example': 'only one known occurrence', 'english': '—', 'note': 'Very rare'},
  {'sequence': 'uə', 'example': 'əshûə', 'english': 'fish', 'note': 'Common — the stem ends with high vowel, schwa is suffix'},
];

/// 6 basic syllable types in Awing (S = semivowel)
class SyllableType {
  final String pattern;
  final String example;
  final String english;
  final String description;
  final List<String> whereUsed; // 'functors', 'prefixes', 'roots', 'suffixes'

  const SyllableType({
    required this.pattern,
    required this.example,
    required this.english,
    required this.description,
    required this.whereUsed,
  });
}

const List<SyllableType> syllableTypes = [
  SyllableType(pattern: 'V', example: 'à-lě', english: 'day', description: 'Just a vowel', whereUsed: ['functors', 'prefixes', 'suffixes']),
  SyllableType(pattern: 'N', example: 'ḿ-bê', english: 'knife', description: 'Syllabic nasal', whereUsed: ['functors', 'prefixes']),
  SyllableType(pattern: 'CV', example: 'kǒ', english: 'snore', description: 'Consonant + vowel', whereUsed: ['functors', 'prefixes', 'roots', 'suffixes']),
  SyllableType(pattern: 'CVC', example: 'kòŋ-tə́', english: 'be pleased', description: 'Consonant + vowel + consonant', whereUsed: ['functors', 'roots']),
  SyllableType(pattern: 'CSV', example: 'kjê', english: 'pluck', description: 'Consonant + semivowel + vowel', whereUsed: ['roots']),
  SyllableType(pattern: 'CSVC', example: 'kwúb-tə', english: 'close', description: 'Consonant + semivowel + vowel + consonant', whereUsed: ['roots']),
];

/// Verb suffixes with meanings (from §4.2.1)
class VerbSuffix {
  final String suffix;
  final String meaning;
  final String example;
  final String exampleEnglish;

  const VerbSuffix({
    required this.suffix,
    required this.meaning,
    required this.example,
    required this.exampleEnglish,
  });
}

const List<VerbSuffix> verbSuffixes = [
  VerbSuffix(suffix: '-ə', meaning: 'Default (unspecified vowel)', example: 'lúmə', exampleEnglish: 'bite'),
  VerbSuffix(suffix: '-tə', meaning: '"a lot", "many things", or "a bit"', example: 'kwúbtə', exampleEnglish: 'close'),
  VerbSuffix(suffix: '-kə', meaning: 'Same as -tə (alternate form)', example: 'yîkə', exampleEnglish: 'harden'),
  VerbSuffix(suffix: '-nə', meaning: '"each other" (reciprocal)', example: 'zó\'nə', exampleEnglish: 'hear each other'),
  VerbSuffix(suffix: '-rə / -lə', meaning: 'After long vowels or nasals', example: 'tsɛ̀ːrɔ́', exampleEnglish: 'defeat'),
  VerbSuffix(suffix: '-mə', meaning: 'After long vowels əː, eː, oː only', example: 'dzəːmə', exampleEnglish: 'dream'),
];

/// Allophonic rules — how consonants change in different positions
class AllophonicRule {
  final String phoneme;
  final String description;
  final List<Map<String, String>> examples; // {'surface': ..., 'environment': ..., 'word': ..., 'english': ...}

  const AllophonicRule({
    required this.phoneme,
    required this.description,
    required this.examples,
  });
}

const List<AllophonicRule> allophonicRules = [
  AllophonicRule(
    phoneme: '/b/',
    description: 'Realized as [p] at the start of a word, [b] after a nasal or between vowels.',
    examples: [
      {'surface': '[p]', 'environment': 'Word-initial', 'word': 'pá\'ə', 'english': 'braid'},
      {'surface': '[b]', 'environment': 'After nasal (mb)', 'word': 'mbe\'tə', 'english': 'shoulder'},
      {'surface': '[b]', 'environment': 'Between vowels', 'word': 'apóːbə', 'english': 'he-goat'},
    ],
  ),
  AllophonicRule(
    phoneme: '/d/',
    description: 'Three sounds: [l] at word start, [d] after nasal, [r]/[l] between vowels.',
    examples: [
      {'surface': '[l]', 'environment': 'Word-initial', 'word': 'lɛ̀ːrə', 'english': 'hat'},
      {'surface': '[d]', 'environment': 'After nasal (nd)', 'word': 'ndě', 'english': 'neck'},
      {'surface': '[r] or [l]', 'environment': 'Between vowels', 'word': 'nɛ́rə / nɛ́lə', 'english': 'groan with pain'},
    ],
  ),
  AllophonicRule(
    phoneme: '/g/',
    description: 'Pronounced [ɣ] (friction sound) at word start, [g] (hard) after nasal.',
    examples: [
      {'surface': '[ɣ]', 'environment': 'Word-initial', 'word': 'aɣə\'ɔ́', 'english': 'cave'},
      {'surface': '[g]', 'environment': 'After nasal (ŋg)', 'word': 'ŋgàmə', 'english': 'mother-in-law'},
      {'surface': '[g]', 'environment': 'Word-final', 'word': 'móg', 'english': 'fire'},
    ],
  ),
  AllophonicRule(
    phoneme: '/k/',
    description: 'Pronounced [k] at word start and after nasals, [ʔ] (glottal stop) between vowels.',
    examples: [
      {'surface': '[k]', 'environment': 'Word-initial', 'word': 'ko', 'english': 'take'},
      {'surface': '[k]', 'environment': 'After nasal (ŋk)', 'word': 'nkadtə', 'english': 'back'},
      {'surface': '[ʔ]', 'environment': 'Between vowels', 'word': 'akɔ̀ʔə', 'english': 'chair'},
    ],
  ),
  AllophonicRule(
    phoneme: '/t/',
    description: 'Aspirated [tʰ] before high vowels (i, ɨ, u). Plain [t] elsewhere.',
    examples: [
      {'surface': '[tʰ]', 'environment': 'Before high vowel', 'word': 'tʰúə', 'english': 'pay'},
      {'surface': '[tʰ]', 'environment': 'Before high vowel', 'word': 'tʰímə', 'english': 'string beads'},
      {'surface': '[t]', 'environment': 'Before other vowels', 'word': 'atê', 'english': 'rust'},
    ],
  ),
  AllophonicRule(
    phoneme: '/s/ → [ʃ]',
    description: 'Alveolar /s/ becomes palatal [ʃ] (like "sh") before high vowels and when followed by /j/.',
    examples: [
      {'surface': '[ʃ]', 'environment': 'Before /j/', 'word': 'ʃàmnə', 'english': 'be wide'},
      {'surface': '[s]', 'environment': 'Before other vowels', 'word': 'sáŋə', 'english': 'broom'},
    ],
  ),
];
