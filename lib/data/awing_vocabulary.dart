/// Awing vocabulary data extracted from:
///   - AwingOrthography2005.pdf (Alomofor Christian & Stephen C. Anderson)
///   - AwingphonologyMar2009Final_U_arc.pdf (Bianca van den Berg, SIL)
///   - Awing English Dictionary (Alomofor Christian, CABTAL, 2007) — 3098 entries
/// Organized by category for lesson content.
/// Priority: simple, common words that kids and beginners can learn easily.
/// When multiple Awing words exist for the same meaning, we use the simplest one.

class AwingWord {
  final String awing;
  final String english;
  final String category;
  final String? tonePattern; // e.g. 'high', 'low', 'rising', 'falling'
  final String? pluralForm;
  final String? shortForm;
  final int difficulty; // 1=beginner, 2=medium, 3=expert

  const AwingWord({
    required this.awing,
    required this.english,
    required this.category,
    this.tonePattern,
    this.pluralForm,
    this.shortForm,
    this.difficulty = 1,
  });
}

// ============================================================
// NEW CATEGORIES (Session 37 - PDF-verified entries)
// ============================================================

/// Pronouns — personal and demonstrative pronouns
const List<AwingWord> pronouns = [
  // Source: Awing English Dictionary English-Awing Index
  AwingWord(awing: 'ghǒ', english: 'you (singular)', category: 'pronouns', difficulty: 1),
];

/// Time words — temporal expressions and temporal nouns
const List<AwingWord> timeWords = [
  // Source: Awing English Dictionary
  AwingWord(awing: "nətú'ə", english: 'night', category: 'time', difficulty: 1),  // Session 56 audit: was "ntúa'ɔ" — dict says "nətú'ə"
  AwingWord(awing: 'agha ghena', english: 'now', category: 'time', difficulty: 2),
  AwingWord(awing: 'agha yia', english: 'later', category: 'time', difficulty: 2),
  AwingWord(awing: 'təká', english: 'never', category: 'time', difficulty: 2),  // Session 56 audit: was "taká" — dict says "təká"
  AwingWord(awing: 'sáŋə', english: 'month', category: 'time', difficulty: 2),  // Session 56 audit: was "saŋ" — dict says "sáŋə"
  AwingWord(awing: 'agha', english: 'season', category: 'time', difficulty: 2),
];

// ============================================================
// BEGINNER VOCABULARY (difficulty: 1) — simple, everyday words
// ============================================================

/// Body parts — simple words kids learn first
const List<AwingWord> bodyParts = [
  // Beginner (difficulty 1) — simple body parts kids know
  AwingWord(awing: 'apô', english: 'hand', category: 'body'),
  AwingWord(awing: 'atûə', english: 'head', category: 'body'),
  AwingWord(awing: 'nəlwîə', english: 'nose', category: 'body'),
  AwingWord(awing: 'ndě', english: 'neck (body part)', category: 'body', pluralForm: 'məndě'),
  AwingWord(awing: 'nkadtə', english: 'back', category: 'body'),
  AwingWord(awing: "mbe'ta", english: 'shoulder', category: 'body'),  // Session 56 audit: was "mbe'tə" — dict says "mbe'ta"
  AwingWord(awing: 'achîə', english: 'blood', category: 'body'),
  AwingWord(awing: 'akoolə', english: 'leg', category: 'body'),
  AwingWord(awing: 'aləəmə', english: 'tongue', category: 'body'),  // Session 56 audit: was "alɔ́əmə" — dict says "aləəmə"
  AwingWord(awing: 'ŋgɔ́ɔmə', english: 'body', category: 'body'),
  AwingWord(awing: 'ŋgɔ̀ɔnə', english: 'eye', category: 'body'),
  AwingWord(awing: 'ntɔ̀ə', english: 'ear', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'nəpe', english: 'liver', category: 'body', difficulty: 2),
  AwingWord(awing: 'nətô', english: 'intestines', category: 'body', difficulty: 2),
  AwingWord(awing: 'felə', english: 'breastbone', category: 'body', difficulty: 2),  // Session 56 audit: was "fɛlə" — dict says "felə"
  AwingWord(awing: 'ghaŋə', english: 'chest', category: 'body', difficulty: 2),  // Session 56 audit: was "aghâŋə" — dict says "ghaŋə"
  AwingWord(awing: 'nəlágə', english: 'eye', category: 'body', pluralForm: 'mələ́g'),  // Session 56 audit: was "nəlɔ́gə" — dict says "nəlágə"
  AwingWord(awing: 'nətôglə', english: 'ear', category: 'body'),  // Session 56 audit: was "ntɔ̂glə" — dict says "nətôglə"
  AwingWord(awing: 'ntsoolə', english: 'mouth (body)', category: 'body', pluralForm: 'məntsoolə'),
  AwingWord(awing: 'nəsoŋə', english: 'tooth', category: 'body', pluralForm: 'məsoŋ'),  // Session 56 audit: was "nəsoŋɔ́" — dict says "nəsoŋə"
  AwingWord(awing: 'nənoŋə', english: 'hair', category: 'body', pluralForm: 'mənɔŋə'),  // Session 56 audit: was "nənɔŋə" — dict says "nənoŋə"
  AwingWord(awing: 'akwəŋó', english: 'bone', category: 'body'),  // Session 56 audit: was "akwəŋɔ́" — dict says "akwəŋó"
  AwingWord(awing: 'nəpəmə', english: 'stomach', category: 'body', pluralForm: 'məpəmə'),
  AwingWord(awing: "alu'ə", english: 'hip', category: 'body'),  // Session 56 audit: was "alu'ɔ̀" — dict says "alu'ə"
  AwingWord(awing: 'atéelə', english: 'foot', category: 'body'),
  AwingWord(awing: 'nəpéenə', english: 'crown of head', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'əleló', english: 'beard', category: 'body', difficulty: 2),  // Session 56 audit: was "ələlə" — dict says "əleló"
  AwingWord(awing: 'nəpəənə', english: 'breast', category: 'body', difficulty: 2),  // Session 56 audit: was "nəpɔ̌ɔnə" — dict says "nəpəənə"
  AwingWord(awing: 'atúəkeenə', english: 'shoulder blade', category: 'body', difficulty: 2),
  AwingWord(awing: "kwɔ'tə", english: 'knee', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəbâŋə', english: 'wing (of bird)', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəlwɛ̂ɨ', english: 'hump', category: 'body', difficulty: 3),
  AwingWord(awing: 'nətoŋə́', english: 'navel', category: 'body', difficulty: 2),  // Session 56 audit: was "nətɔŋɔ́" — dict says "nətoŋə́"
  AwingWord(awing: "nətə'ə", english: 'thigh', category: 'body', difficulty: 2),  // Session 56 audit: was "nətɔ'ə" — dict says "nətə'ə"
  AwingWord(awing: 'ntîə', english: 'height', category: 'body', difficulty: 2),
  AwingWord(awing: 'ajwíə', english: 'soul/spirit', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntéəmə', english: 'heart', category: 'body', difficulty: 2),  // Session 56 audit: was "ntɔ̂əmə" — dict says "ntéəmə"
  // New body parts from phonology/orthography PDFs
  AwingWord(awing: 'ŋgwɛ̂ŋə', english: 'cheek', category: 'body'),
  AwingWord(awing: 'ndzwîə', english: 'chin', category: 'body'),
  AwingWord(awing: 'nkwə̂ŋə', english: 'elbow', category: 'body'),
  AwingWord(awing: 'ntsə̂ŋə', english: 'finger', category: 'body'),
  AwingWord(awing: 'mbwɔ̂ŋə', english: 'neck (back of)', category: 'body', difficulty: 2),
  AwingWord(awing: 'ndɛ̂ŋə', english: 'jaw', category: 'body', difficulty: 2),
  AwingWord(awing: 'ŋgwɔ̂ŋə', english: 'forehead', category: 'body'),
  AwingWord(awing: 'ntsɔ̂ŋə', english: 'rib', category: 'body', difficulty: 2),
  AwingWord(awing: 'mbə̂ŋɔ́', english: 'palm (of hand)', category: 'body'),
  AwingWord(awing: 'nkɔ̂ŋə', english: 'throat', category: 'body'),
  AwingWord(awing: 'ŋgwɛ̀nə', english: 'skin', category: 'body'),
  AwingWord(awing: 'ŋkwâŋə', english: 'waist', category: 'body'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'nalanɔ́', english: 'joint', category: 'body', difficulty: 2),
  AwingWord(awing: "mbi'ə", english: 'kidney', category: 'body', difficulty: 3),  // Session 56 audit: was "mbî'ɔ́" — dict says "mbi'ə"
  AwingWord(awing: 'afɔ́bla', english: 'lung', category: 'body', difficulty: 3),
];

/// Animals and nature — fun for kids
const List<AwingWord> animalsNature = [
  // Beginner animals
  AwingWord(awing: 'əshûə', english: 'fish', category: 'animals'),
  // Session 52 gloss audit: was "owl" — dict says "1) crawl. 2) slither, eg of snakes"
  AwingWord(awing: 'koŋə', english: 'crawl, slither', category: 'actions'),
  AwingWord(awing: 'nóolə', english: 'snake', category: 'animals'),
  AwingWord(awing: 'aŋkoomə', english: 'ram', category: 'animals'),  // Session 56 audit: was "ankoomə" — dict says "aŋkoomə"
  AwingWord(awing: 'mbéŋə', english: 'goat', category: 'animals'),  // Session 56 audit: was "ndzô" (OCR fabrication — dict says ndzɔ=beans, mbéŋə=goat)
  AwingWord(awing: 'mbyâə', english: 'guard dog', category: 'animals'),
  AwingWord(awing: 'ndoŋə', english: 'duck', category: 'animals'),  // Session 56 audit: was "əndəŋə" — dict says "ndoŋə"
  AwingWord(awing: 'kshǐa', english: 'cricket', category: 'animals'),
  AwingWord(awing: 'mbeŋə', english: 'cockroach', category: 'animals'),  // Session 56 audit: was "mbeŋó" — dict says "mbeŋə"
  AwingWord(awing: 'kánáŋə́', english: 'chameleon', category: 'animals'),  // Session 56 audit: was "kónáŋó" — dict says "kánáŋə́"
  AwingWord(awing: 'apəabə', english: 'he-goat', category: 'animals'),  // Session 56 audit: was "apóbə" — dict says "apəabə"
  AwingWord(awing: 'ngwûə', english: 'dog', category: 'animals', pluralForm: 'məngwûə'),
  AwingWord(awing: 'ngábə', english: 'chicken', category: 'animals', pluralForm: 'məngɔ́bə'),  // Session 56 audit: was "ngɔ́bə" — dict says "ngábə"
  AwingWord(awing: 'pûshíə', english: 'cat', category: 'animals'),
  AwingWord(awing: 'sáŋə', english: 'bird', category: 'animals', pluralForm: 'pəsáŋɔ́'),  // Session 56 audit: was "sáŋɔ́" — dict says "sáŋə"
  AwingWord(awing: "təŋka'ə", english: 'elephant', category: 'animals'),  // Session 56 audit: was "tâŋka'ə" — dict says "təŋka'ə"
  AwingWord(awing: 'sáambaŋə', english: 'lion', category: 'animals'),
  AwingWord(awing: 'ambónə', english: 'hippopotamus', category: 'animals'),
  AwingWord(awing: 'chwíə', english: 'antelope', category: 'animals'),
  AwingWord(awing: 'lúmtə', english: 'mosquito', category: 'animals'),  // Session 56 audit: was "lúmtɔ́" — dict says "lúmtə"
  // REMOVED kwíŋə "tortoise" — per dict EXACT match kwíŋə = "grow up / prosper" (verb), not an animal (Session 51 audit)
  AwingWord(awing: 'kwúneemə', english: 'pig', category: 'animals'),
  AwingWord(awing: 'tətseemə', english: 'frog', category: 'animals'),  // Session 56 audit: was "tatseemə" — dict says "tətseemə"
  AwingWord(awing: 'lóolá', english: 'toad', category: 'animals'),  // Session 56 audit: was "lóolə" — dict says "lóolá"
  AwingWord(awing: 'anjwa', english: 'giraffe', category: 'animals'),
  AwingWord(awing: 'njakásə', english: 'donkey', category: 'animals'),  // Session 56 audit: was "ŋjakásə" — dict says "njakásə"
  // REMOVED nka'ə "leopard" — per dict EXACT match nka'ə = "leprosy" (not a kid-friendly word AND not a leopard) (Session 51 audit)
  AwingWord(awing: 'kígháləgháló', english: 'butterfly', category: 'animals'),
  AwingWord(awing: 'fóolá', english: 'rat', category: 'animals'),  // Session 56 audit: was "fóolɔ́" — dict says "fóolá"
  AwingWord(awing: 'anəmá', english: 'louse', category: 'animals'),  // Session 56 audit: was "anɔ́mɔ́" — dict says "anəmá"
  AwingWord(awing: 'njá', english: 'shrimp', category: 'animals'),
  AwingWord(awing: 'ngwumnə́', english: 'locust', category: 'animals'),  // Session 56 audit: was "ngwúmnɔ́" — dict says "ngwumnə́"
  AwingWord(awing: "to'lə", english: 'squirrel', category: 'animals'),  // Session 56 audit: was "tɔ'lɔ́" — dict says "to'lə"
  AwingWord(awing: "aŋkə'á", english: 'rooster', category: 'animals'),  // Session 56 audit: was "əŋka'ɔ́" — dict says "aŋkə'á"
  // Beginner nature
  AwingWord(awing: 'atɨə', english: 'tree', category: 'nature'),  // Session 56 audit: was "atîə" — dict says "atɨə"
  AwingWord(awing: 'akoobá', english: 'forest', category: 'nature'),  // Session 56 audit: was "akoobɔ́" — dict says "akoobá"
  AwingWord(awing: "ngɔ́'ə", english: 'stone', category: 'nature'),  // Session 56 audit: was "ngə'ə" — dict says "ngɔ́'ə"
  AwingWord(awing: 'wáako', english: 'sand', category: 'nature'),  // Session 56 audit: was "wâakɔ́" — dict says "wáako"
  AwingWord(awing: 'afûə', english: 'leaf', category: 'nature'),
  // REMOVED sánə "moon" — per dict EXACT match sánə = "break" (verb). The Awing word for moon is sáŋə (now corrected below) (Session 51 audit)
  // REMOVED ndě "water (drink)" — per Awing English Dictionary ndě has 3 homonyms: 1) elder/voc 2) neck (n 1/6) 3) house, inheritance (n 9/6). NONE mean water. The correct word for water/river is nkǐə (rising tone). Compounds like ndě móga "kitchen" use the "house" sense. (User-flagged Session 52)
  AwingWord(awing: 'pôb', english: 'fire', category: 'nature'),  // Session 56 audit: was "íŋə" — dict says "pôb"
  AwingWord(awing: 'àlě', english: 'day', category: 'nature'),
  AwingWord(awing: 'alóma', english: 'cloud', category: 'nature'),  // Session 56 audit: was "aləmə" — dict says "alóma"
  AwingWord(awing: 'alemó', english: 'pool', category: 'nature'),  // Session 56 audit: was "aləmó" — dict says "alemó"
  // CORRECTED nkîə "river/stream" → nkǐə "water; river" — per Awing English Dictionary EXACT match: nkǐə (rising tone, n 1/6, homonym 1) = "1) water 2) river". Same word for both per user. (User-flagged Session 52)
  AwingWord(awing: 'nkǐə', english: 'water; river', category: 'nature'),
  AwingWord(awing: 'nəpóolə', english: 'sky', category: 'nature'),
  AwingWord(awing: 'mánuma', english: 'sun', category: 'nature'),  // Session 56 audit: was "mɔ́numə" — dict says "mánuma"
  AwingWord(awing: 'mbaŋə', english: 'rain', category: 'nature'),  // Session 56 audit: was "mbəŋə" — dict says "mbaŋə"
  AwingWord(awing: 'sáma', english: 'wind', category: 'nature'),  // Session 56 audit: was "sɔ́mə" — dict says "sáma"
  AwingWord(awing: 'nəyeŋə́', english: 'grass', category: 'nature'),  // Session 56 audit: was "nəyeŋɔ́" — dict says "nəyeŋə́"
  AwingWord(awing: 'nəfaŋə', english: 'thunder', category: 'nature'),  // Session 56 audit: was "nəfáŋɔ́" — dict says "nəfaŋə"
  AwingWord(awing: "nətú'ə", english: 'night', category: 'nature'),
  // REMOVED alě "morning" — per dict EXACT match alě = "day" (which is already in line 161 as àlě). The Awing word for "morning" is not yet PDF-confirmed. (Session 51 audit)
  AwingWord(awing: 'nkwaná', english: 'evening', category: 'nature'),  // Session 56 audit: was "nkwanɔ́" — dict says "nkwaná"
  AwingWord(awing: 'alanə', english: 'road/path', category: 'nature'),
  AwingWord(awing: 'nəfógə', english: 'waterfall', category: 'nature'),
  AwingWord(awing: 'ndəsê', english: 'ground/earth', category: 'nature'),
  AwingWord(awing: 'móláglə', english: 'shadow', category: 'nature'),  // Session 56 audit: was "mɔ́lɔ̂glə" — dict says "móláglə"
  AwingWord(awing: 'ndo', english: 'valley', category: 'nature'),
  AwingWord(awing: 'nkwəənə', english: 'mountain', category: 'nature'),
  AwingWord(awing: "nkya' sáŋə", english: 'moonlight', category: 'nature'),
  // Medium/Expert
  AwingWord(awing: 'anyiŋə', english: 'claw', category: 'animals', difficulty: 2),  // Session 56 audit: was "anyeŋə" — dict says "anyiŋə"
  AwingWord(awing: 'nənjwínə', english: 'fly', category: 'animals', difficulty: 2),  // Session 56 audit: was "nənjwínnə" — dict says "nənjwínə"
  AwingWord(awing: "ngó'ə́", english: 'termite', category: 'animals', difficulty: 2),  // Session 56 audit: was "ngə'ɔ́" — dict says "ngó'ə́"
  AwingWord(awing: "njɔ́ə", english: 'groundnuts', category: 'nature', difficulty: 2),
  AwingWord(awing: "nkəŋə", english: 'peace plant', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ɔ̀fɨ̂ə', english: 'medicine', category: 'nature', difficulty: 2),
  AwingWord(awing: 'afoonə', english: 'hunting', category: 'nature', difficulty: 2),  // Session 56 audit: was "əfóonə" — dict says "afoonə"
  AwingWord(awing: 'akəghaŋə', english: 'okra', category: 'nature', difficulty: 2),  // Session 56 audit: was "əkəghanə" — dict says "akəghaŋə"
  // New from phonology PDF — more nature words
  AwingWord(awing: 'əkûə', english: 'hole/pit', category: 'nature'),
  AwingWord(awing: 'aɣə\'ɔ́', english: 'cave', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəkwuunə́', english: 'entrance', category: 'nature', difficulty: 2),  // Session 56 audit: was "nəkwùːnɔ́" — dict says "nəkwuunə́"
  AwingWord(awing: 'asháŋə', english: 'hill', category: 'nature'),
  AwingWord(awing: 'ndùə', english: 'dust', category: 'nature'),
  AwingWord(awing: 'ŋgóŋə', english: 'swamp', category: 'nature', difficulty: 2),
  AwingWord(awing: 'əfɔ̂glə', english: 'marsh', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ndzəmə', english: 'back (place)', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atsə̂ŋə', english: 'outside area', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ŋkə́ə', english: 'clearing', category: 'nature', difficulty: 2),
  // New animals from orthography/phonology PDFs
  AwingWord(awing: 'ŋgàbə', english: 'crab', category: 'animals'),
  AwingWord(awing: 'nətwéenə', english: 'spider', category: 'animals'),
  AwingWord(awing: 'ŋgwíŋə', english: 'bee', category: 'animals'),
  AwingWord(awing: 'ndzomə', english: 'worm', category: 'animals'),
  AwingWord(awing: 'əghâlə', english: 'lizard', category: 'animals'),
  // Session 52 gloss audit: was "pangolin" — dict has no "pangolin" sense; primary = "cane, walking stick, club, cudgel"
  AwingWord(awing: 'mbâŋə', english: 'cane, walking stick', category: 'things', difficulty: 2),
  AwingWord(awing: 'ŋgwâŋə', english: 'porcupine', category: 'animals', difficulty: 2),
  AwingWord(awing: 'nkwúbə', english: 'dove', category: 'animals'),
  AwingWord(awing: 'ŋkwɔ́ŋə', english: 'parrot', category: 'animals', difficulty: 2),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'máwúmə́', english: 'hawk', category: 'animals', difficulty: 2),  // Session 56 audit: was "máwúmɔ́" — dict says "máwúmə́"
  AwingWord(awing: 'pɨ̌\'ɔ', english: 'hen', category: 'animals', difficulty: 1),
  AwingWord(awing: 'njakásə', english: 'jackal', category: 'animals', difficulty: 3),  // Session 56 audit: was "njakaŋɔ" — dict says "njakásə"
  AwingWord(awing: "nkámázɔ́'ə́", english: 'monkey', category: 'animals', difficulty: 2),  // Session 56 audit: was "nkámɔ́zɔ'ɔ́" — dict says "nkámázɔ́'ə́"
  AwingWord(awing: 'nɔ́sanɔ́', english: 'ocean/sea', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkɔŋ nó ngɔ́sma', english: 'rainbow', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkya\' sáŋa', english: 'moonlight', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mɔ̀m napooɔ́la', english: 'heaven', category: 'nature', difficulty: 3),
  AwingWord(awing: 'sfoŋhasɔ́mɔ́', english: 'lake', category: 'nature', difficulty: 2),
];

/// Food and drink — things kids eat and drink
const List<AwingWord> foodDrink = [
  // Beginner — common foods
  AwingWord(awing: 'majîə', english: 'food/meal', category: 'food'),
  AwingWord(awing: "amú'á", english: 'banana', category: 'food'),  // Session 56 audit: was "amú'ɔ́" — dict says "amú'á"
  AwingWord(awing: "azó'ə", english: 'yam', category: 'food'),
  AwingWord(awing: "akwu'ó", english: 'cocoyam', category: 'food'),  // Session 56 audit: was "akwú'ɔ́" — dict says "akwu'ó"
  AwingWord(awing: 'ngəsáŋɔ́', english: 'corn/maize', category: 'food'),
  AwingWord(awing: 'nûə', english: 'honey', category: 'food'),
  AwingWord(awing: 'ndzě', english: 'vegetable', category: 'food'),
  AwingWord(awing: 'mâfɛ', english: 'sweet potato', category: 'food'),  // Session 56 audit: was "mâfe" — dict says "mâfɛ"
  AwingWord(awing: 'apopó', english: 'pawpaw', category: 'food'),
  AwingWord(awing: 'nəpumə́', english: 'egg', category: 'food', pluralForm: 'mbumɔ́'),  // Session 56 audit: was "nəpumɔ́" — dict says "nəpumə́"
  AwingWord(awing: 'neemə', english: 'meat', category: 'food'),
  AwingWord(awing: 'nəkwúnə', english: 'rice', category: 'food'),
  AwingWord(awing: 'máliga', english: 'milk', category: 'food'),  // Session 56 audit: was "mɔ́lígə" — dict says "máliga"
  AwingWord(awing: 'lámósə', english: 'orange', category: 'food'),  // Session 56 audit: was "lámɔ́sə" — dict says "lámósə"
  AwingWord(awing: 'tâmto', english: 'tomato', category: 'food'),
  AwingWord(awing: "ná'ə", english: 'soup/sauce', category: 'food'),
  AwingWord(awing: 'ngwápə', english: 'guava', category: 'food'),  // Session 56 audit: was "ngwápa" — dict says "ngwápə"
  AwingWord(awing: 'panápəələ', english: 'pineapple', category: 'food'),  // Session 56 audit: was "panɔ́paələ" — dict says "panápəələ"
  AwingWord(awing: 'akəfə', english: 'coffee', category: 'food'),  // Session 56 audit: was "akəfé" — dict says "akəfə"
  AwingWord(awing: 'pyâ', english: 'avocado', category: 'food'),
  AwingWord(awing: 'ngéemə', english: 'bunch of banana', category: 'food'),
  AwingWord(awing: "achú'ə", english: 'pounded cocoyam', category: 'food'),
  AwingWord(awing: "nələ'ə́", english: 'sweet yam', category: 'food'),  // Session 56 audit: was "nəlɔ'ɔ́" — dict says "nələ'ə́"
  AwingWord(awing: 'nkwûə', english: 'sort of okra', category: 'food'),
  AwingWord(awing: 'ónyúsə', english: 'onion', category: 'food'),  // Session 56 audit: was "ɔ́nyúsə" — dict says "ónyúsə"
  // Medium
  AwingWord(awing: 'aŋkəsálə', english: 'cassava', category: 'food', difficulty: 2),
  AwingWord(awing: 'ngəəbə', english: 'goblet', category: 'food', difficulty: 2),  // Session 56 audit: was "nəgɔ̌əbə" — dict says "ngəəbə"
  AwingWord(awing: 'apéenə', english: 'fufu corn', category: 'food', difficulty: 2),
  AwingWord(awing: 'gəlébə', english: 'grape', category: 'food', difficulty: 2),  // Session 56 audit: was "galéba" — dict says "gəlébə"
  AwingWord(awing: "shí sɔ̂ntê", english: 'green pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "paŋ sɔ̂ntê", english: 'red pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "nkɔ̂ŋ ɔ̂'lə", english: 'sugar cane', category: 'food', difficulty: 2),
  // New food from phonology/orthography PDFs
  // REMOVED ndzě ndě "water leaf" — used ndě as water (wrong; ndě = neck/elder/house). ndzě alone = "vegetable" per dict. Compound unverified. (User-flagged Session 52)
  AwingWord(awing: 'ndzě', english: 'vegetable', category: 'food'),
  AwingWord(awing: 'ŋgə̂ŋə', english: 'palm wine', category: 'food', difficulty: 2),
  AwingWord(awing: 'nkúnə', english: 'oil', category: 'food'),
  // REMOVED asháŋə ndě "cooked rice" — both wrong: rice = nəkwúnə (not asháŋə) per dict, and ndě is not water. Replaced with verified dict entry. (User-flagged Session 52)
  AwingWord(awing: 'nəkwúnə', english: 'rice', category: 'food'),
  AwingWord(awing: 'nkwə̂ə', english: 'kola nut', category: 'food', difficulty: 2),
  AwingWord(awing: 'ŋgə́ŋə', english: 'palm fruit', category: 'food', difficulty: 2),
  // REMOVED mbənə "flour" — per Awing English Dictionary mbənə is a grammatical exclamation marker, not "flour" (Session 51 audit, EXACT match)
  AwingWord(awing: 'ntsɔ́ŋə', english: 'salt (local)', category: 'food', difficulty: 2),
  AwingWord(awing: 'ŋgwénə', english: 'mushroom', category: 'food'),
  // Session 52 gloss audit: was "pepper (spice)" — dict says "1) prison. 2) penalty, punishment"
  AwingWord(awing: 'atsǎŋə', english: 'prison; penalty', category: 'things'),
  AwingWord(awing: 'ndzɔ̂ŋə', english: 'sugar', category: 'food'),
  AwingWord(awing: 'mbwáŋə', english: 'fresh corn', category: 'food'),
];

/// Simple actions (verbs) — everyday actions kids can act out
const List<AwingWord> actions = [
  // Beginner — simple everyday actions
  AwingWord(awing: 'nô', english: 'drink', category: 'actions'),
  AwingWord(awing: 'yǐə', english: 'come', category: 'actions'),
  AwingWord(awing: 'fê', english: 'give', category: 'actions'),
  AwingWord(awing: 'mîəə', english: 'swallow', category: 'actions'),  // Session 56 audit: was "mîə" — dict says "mîəə"
  AwingWord(awing: 'lúmə', english: 'bite', category: 'actions'),
  AwingWord(awing: "zó'ə", english: 'hear', category: 'actions'),
  // CORRECTED pímə "see" → "believe; accept" — per Awing English Dictionary EXACT match: "1) believe 2) accept 3) admit a truth 4) confess" (Session 51 audit, user-flagged)
  AwingWord(awing: 'pímə', english: 'believe; accept', category: 'actions'),
  AwingWord(awing: 'pɛ́nə', english: 'dance', category: 'actions'),
  AwingWord(awing: "cha'tə̂", english: 'greet', category: 'actions'),  // Session 56 audit: was "cha'tɔ́" — dict says "cha'tə̂"
  AwingWord(awing: 'túmə', english: 'send', category: 'actions'),
  AwingWord(awing: 'léŋə', english: 'lick', category: 'actions'),
  AwingWord(awing: "lyáŋə", english: 'hide', category: 'actions'),
  AwingWord(awing: 'fínə', english: 'sell', category: 'actions', shortForm: 'fi'),
  AwingWord(awing: 'ghenə̂', english: 'go', category: 'actions'),  // Session 56 audit: was "ghɛnɔ́" — dict says "ghenə̂"
  AwingWord(awing: 'pìə', english: 'give birth', category: 'actions'),
  // Session 52 gloss audit: was "smell" — dict says "continuously" / "1) also. 2) too (additive marker)"
  AwingWord(awing: 'kâ', english: 'also; too', category: 'descriptive'),
  AwingWord(awing: 'tɨ̂ə', english: 'stand', category: 'actions', shortForm: 'tî'),
  AwingWord(awing: 'kwúnə', english: 'enter', category: 'actions'),
  AwingWord(awing: 'kəənə̂', english: 'run', category: 'actions'),  // Session 56 audit: was "kə́ərə" — dict says "kəənə̂"
  // Session 52: was kíə "pay (money)" — kíə (high tone) does not exist in the
  // Awing English Dictionary. Per dict, "pay (for goods, services, etc.)" = tûə.
  AwingWord(awing: 'tûə', english: 'pay (for goods)', category: 'actions', tonePattern: 'falling', shortForm: 'ńtú'),
  AwingWord(awing: 'fɔ̂nə', english: 'read', category: 'actions'),
  AwingWord(awing: 'jwiəə', english: 'breathe', category: 'actions'),  // Session 56 audit: was "jwîə" — dict says "jwiəə"
  AwingWord(awing: 'pyáabə', english: 'watch/wait', category: 'actions'),
  AwingWord(awing: 'kyagó', english: 'untie', category: 'actions'),
  AwingWord(awing: 'náŋə', english: 'look at', category: 'actions'),  // Session 56 audit: was "ńnáŋ" — dict says "náŋə"
  AwingWord(awing: 'jíə', english: 'eat', category: 'actions'),
  AwingWord(awing: 'lê', english: 'sleep', category: 'actions'),
  // REMOVED jwítə "rest" — per Awing English Dictionary jwítə means "kill, murder" (unsafe in kids' app, dict EXACT match Session 51 audit)
  AwingWord(awing: "júnə", english: 'buy', category: 'actions'),
  AwingWord(awing: 'kóolə', english: 'catch/harvest', category: 'actions'),
  AwingWord(awing: 'ghɛdtɔ́', english: 'do a little', category: 'actions'),
  AwingWord(awing: 'nyinɔ́', english: 'walk/travel', category: 'actions'),
  AwingWord(awing: 'nyintô', english: 'take a walk', category: 'actions'),  // Session 56 audit: was "nyintɔ́" — dict says "nyintô"
  AwingWord(awing: 'tómə', english: 'kick/shoot', category: 'actions'),
  AwingWord(awing: 'sóŋə', english: 'say/speak', category: 'actions'),
  AwingWord(awing: 'wiŋə', english: 'laugh', category: 'actions'),  // Session 56 audit: was "wiŋɔ́" — dict says "wiŋə"
  AwingWord(awing: 'weŋô', english: 'smile', category: 'actions'),  // Session 56 audit: was "weŋɔ́" — dict says "weŋô"
  AwingWord(awing: 'kyéŋə', english: 'cry/weep', category: 'actions'),
  AwingWord(awing: 'zoobə̂', english: 'sing', category: 'actions'),  // Session 56 audit: was "zoobɔ́" — dict says "zoobə̂"
  AwingWord(awing: "ŋwa'lô", english: 'write', category: 'actions'),  // Session 56 audit: was "ŋwa'lɔ́" — dict says "ŋwa'lô"
  AwingWord(awing: "zé'ka", english: 'teach', category: 'actions'),  // Session 56 audit: was "zé'kə" — dict says "zé'ka"
  AwingWord(awing: "zé'ə", english: 'learn', category: 'actions'),
  AwingWord(awing: 'pookô', english: 'say goodbye', category: 'actions'),  // Session 56 audit: was "pookɔ́" — dict says "pookô"
  AwingWord(awing: 'sogə', english: 'wash', category: 'actions'),  // Session 56 audit: was "sogɔ́" — dict says "sogə"
  AwingWord(awing: 'léelə', english: 'prepare', category: 'actions'),
  AwingWord(awing: 'kamtə̂', english: 'eat hastily', category: 'actions'),  // Session 56 audit: was "kamtɔ́" — dict says "kamtə̂"
  AwingWord(awing: 'loonɔ́', english: 'desire/want', category: 'actions'),
  AwingWord(awing: "wó'tə", english: 'remember', category: 'actions'),  // Session 56 audit: was "wɔ́'tə" — dict says "wó'tə"
  AwingWord(awing: 'piímə', english: 'believe/accept', category: 'actions'),
  AwingWord(awing: 'ləgnə̂', english: 'forget', category: 'actions'),  // Session 56 audit: was "logŋə" — dict says "ləgnə̂"
  // Medium
  AwingWord(awing: "tsó'ə", english: 'heal', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwágə', english: 'cough', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fyáalə', english: 'chase', category: 'actions', difficulty: 2),
  AwingWord(awing: "ŋá'ə", english: 'open', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jágə', english: 'yawn', category: 'actions', difficulty: 2),
  AwingWord(awing: 'séenə', english: 'cut open', category: 'actions', difficulty: 2),  // Session 56 audit: was "sɛ́nə" — dict says "séenə"
  AwingWord(awing: 'tséebə', english: 'talk', category: 'actions', difficulty: 2, shortForm: 'tsáb'),  // Session 56 audit: was "tsɛ́bə" — dict says "tséebə"
  // Session 52 gloss audit: was "find" — dict says 'demonstrative adjective "this" (noun classes 5, 7, 9)'
  AwingWord(awing: 'zə́ənə', english: 'this (demonstrative)', category: 'descriptive', difficulty: 2),
  // Session 52 gloss audit: was "sell" (that is fínə, already at L293) — dict says "new" / "resemble"
  AwingWord(awing: 'fìə', english: 'new; resemble', category: 'descriptive', difficulty: 2, shortForm: 'fî'),
  AwingWord(awing: 'mwé', english: 'salty', category: 'actions', difficulty: 2),
  AwingWord(awing: "myá'á", english: 'throw away', category: 'actions', difficulty: 2),
  // New actions from phonology PDF
  // Session 52 gloss audit: was "snore" — dict says "1) take. 2) listen"
  AwingWord(awing: 'kǒ', english: 'take; listen', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pá\'ə', english: 'braid/plait', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kyê', english: 'pluck', category: 'actions', difficulty: 2),  // Session 56 audit: was "kjê" — dict says "kyê"
  AwingWord(awing: 'kəŋtə̂', english: 'be pleased', category: 'actions', difficulty: 2),  // Session 56 audit: was "kòŋtə́" — dict says "kəŋtə̂"
  AwingWord(awing: 'shǎmtə', english: 'widen', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tʰímə', english: 'string beads', category: 'actions', difficulty: 3),
  AwingWord(awing: 'nɛ́rə', english: 'groan with pain', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fwɔ̀ːtə', english: 'mumble', category: 'actions', difficulty: 3),
  // Session 52: was sáŋə "sweep (with broom)" — WRONG. Per dictionary, sáŋə = "moon, month"
  // (or homonym "bird"). The Awing word for "sweep" is zəgə (already at L2321).
  // The word for "broom" is nəsáŋə (already at L3310). Replaced with the verb that
  // ACTUALLY means sweep, but kept as a duplicate-removed comment to avoid clash with L2321.
  // sáŋə itself is preserved as a nature word elsewhere if needed.
  AwingWord(awing: 'chínə', english: 'build', category: 'actions'),  // Session 56 audit: was "tsíə" — dict says "chínə"
  AwingWord(awing: 'sɛ̀glə', english: 'weave', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kpɔ́ŋə', english: 'break', category: 'actions'),
  AwingWord(awing: 'dɛ̀ŋə', english: 'carry on head', category: 'actions'),
  AwingWord(awing: 'nyâŋə', english: 'mix/stir', category: 'actions'),
  AwingWord(awing: 'tɔ̀ŋə', english: 'pound (with mortar)', category: 'actions'),
  AwingWord(awing: 'kwelô', english: 'pour', category: 'actions'),  // Session 56 audit: was "kwɛ́nə" — dict says "kwelô"
  AwingWord(awing: 'tsɔ́mə', english: 'squeeze', category: 'actions', difficulty: 2),
  AwingWord(awing: 'shɔ́ŋə', english: 'climb', category: 'actions'),
  AwingWord(awing: 'bwɔ́nə', english: 'mould/shape', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fɔ̀ŋə', english: 'blow (fire)', category: 'actions'),
  AwingWord(awing: 'tsɛ́rə', english: 'stop up/block', category: 'actions', difficulty: 2),
  AwingWord(awing: 'dzə̀mə', english: 'think/reflect', category: 'actions'),
  AwingWord(awing: 'lwɔ̀ŋə', english: 'count/calculate', category: 'actions'),
  AwingWord(awing: 'náŋnə', english: 'cook', category: 'actions'),  // Session 56 audit: was "nə̂ŋə" — dict says "náŋnə"
  AwingWord(awing: 'tɔ̀ə', english: 'plant (seed)', category: 'actions'),
  AwingWord(awing: 'kəmtɔ́', english: 'harvest', category: 'actions'),
  AwingWord(awing: 'njwíŋə', english: 'whistle', category: 'actions'),
  AwingWord(awing: 'ŋwàŋə', english: 'return', category: 'actions'),
  AwingWord(awing: 'wúnə', english: 'ask', category: 'actions'),  // Session 56 audit: was "kwɨ̌nə" — dict says "wúnə"
  AwingWord(awing: 'pá\'tə', english: 'share/divide', category: 'actions'),
  // Session 52 gloss audit: CRITICAL FIX — was "praise", dict says "1) curse. 2) destroy. 3) spoil" (OPPOSITE meaning)
  AwingWord(awing: 'tsə́ŋə', english: 'curse; destroy; spoil', category: 'actions', difficulty: 2),
  AwingWord(awing: 'shwɔ́ŋə', english: 'pray', category: 'actions', difficulty: 2),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'kwûə', english: 'die', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwúɔ" — dict says "kwûə"
  AwingWord(awing: 'tóŋə', english: 'dig', category: 'actions', difficulty: 1),  // Session 56 audit: was "fóŋɔ" — dict says "tóŋə"
  AwingWord(awing: 'tsóolə', english: 'descend', category: 'actions', difficulty: 2),  // Session 56 audit: was "tsóolɔ" — dict says "tsóolə"
  AwingWord(awing: 'tsanɔ́', english: 'destroy', category: 'actions', difficulty: 2),
  AwingWord(awing: 'looóɔ', english: 'want/desire', category: 'actions', difficulty: 1),
  AwingWord(awing: 'túga', english: 'have', category: 'actions', difficulty: 1),
  AwingWord(awing: "zó'ə", english: 'hear', category: 'actions', difficulty: 1),  // Session 56 audit: was "zo'ɔ" — dict says "zó'ə"
  AwingWord(awing: 'kwáatə', english: 'help', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwaalɔ" — dict says "kwáatə"
  AwingWord(awing: "fi'nə̂", english: 'imitate', category: 'actions', difficulty: 2),  // Session 56 audit: was "fî'nɔ́" — dict says "fi'nə̂"
  AwingWord(awing: 'téekə', english: 'join', category: 'actions', difficulty: 1),  // Session 56 audit: was "téeka" — dict says "téekə"
  AwingWord(awing: "tá'ə", english: 'judge', category: 'actions', difficulty: 2),  // Session 56 audit: was "sá'ɔ" — dict says "tá'ə"
  AwingWord(awing: 'lîə', english: 'jump', category: 'actions', difficulty: 1),  // Session 56 audit: was "llia" — dict says "lîə"
  AwingWord(awing: "lo'kâ", english: 'keep', category: 'actions', difficulty: 2),  // Session 56 audit: was "bə'kɔ́" — dict says "lo'kâ"
  AwingWord(awing: 'chwígə', english: 'kiss', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwiɔ́ɔ" — dict says "chwígə"
  AwingWord(awing: 'póŋə', english: 'lack', category: 'actions', difficulty: 2),  // Session 56 audit: was "póŋa" — dict says "póŋə"
  AwingWord(awing: "zé'ə", english: 'learn', category: 'actions', difficulty: 1),  // Session 56 audit: was "ze'ɔ́" — dict says "zé'ə"
  AwingWord(awing: 'noŋnɔ́', english: 'lie down', category: 'actions', difficulty: 1),
  AwingWord(awing: "jwó'tə", english: 'listen', category: 'actions', difficulty: 1),  // Session 56 audit: was "jwî'ɔ́ta" — dict says "jwó'tə"
  AwingWord(awing: 'fwonə̂', english: 'lock', category: 'actions', difficulty: 2),  // Session 56 audit: was "íwna" — dict says "fwonə̂"
  AwingWord(awing: 'náŋə', english: 'look at', category: 'actions', difficulty: 1),  // Session 56 audit: was "nágɔ" — dict says "náŋə"
  AwingWord(awing: 'ta\'a', english: 'search', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tsóŋtə', english: 'make', category: 'actions', difficulty: 1),  // Session 56 audit: was "tsoŋkɔ́" — dict says "tsóŋtə"
  AwingWord(awing: "zó'ə", english: 'marry', category: 'actions', difficulty: 2),  // Session 56 audit: was "zɔ́'ɔ" — dict says "zó'ə"
  AwingWord(awing: 'ləŋə', english: 'melt', category: 'actions', difficulty: 2),  // Session 56 audit: was "loŋa" — dict says "ləŋə"
  AwingWord(awing: 'nóŋkə', english: 'nurse', category: 'actions', difficulty: 2),  // Session 56 audit: was "nɔŋka" — dict says "nóŋkə"
  AwingWord(awing: 'zo\'na', english: 'obey', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwáalə', english: 'obtain', category: 'actions', difficulty: 2),  // Session 56 audit: was "kwáala" — dict says "kwáalə"
  AwingWord(awing: 'nna\'', english: 'open', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tûə', english: 'pay', category: 'actions', difficulty: 1),  // Session 56 audit: was "tía" — dict says "tûə"
  AwingWord(awing: "kwa'ə", english: 'play', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwa'ɔ́" — dict says "kwa'ə"
  AwingWord(awing: 'píta', english: 'plant', category: 'actions', difficulty: 1),
  AwingWord(awing: "nə'â", english: 'press', category: 'actions', difficulty: 2),  // Session 56 audit: was "no'a" — dict says "nə'â"
  AwingWord(awing: "fya'â", english: 'quarrel', category: 'actions', difficulty: 2),  // Session 56 audit: was "fya'ɔ́" — dict says "fya'â"
  AwingWord(awing: 'kwúmtə', english: 'remember', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwúmtɔ́" — dict says "kwúmtə"
  // Session 52 gloss audit: was "remove" — dict says "fellow-wife (co-wife in polygamous marriage)"
  AwingWord(awing: 'fóga', english: 'fellow-wife', category: 'family', difficulty: 1),
  AwingWord(awing: 'kwúblə', english: 'repent', category: 'actions', difficulty: 3),  // Session 56 audit: was "kwúbla" — dict says "kwúblə"
  AwingWord(awing: 'kyikâ', english: 'refuse', category: 'actions', difficulty: 2),  // Session 56 audit: was "kila" — dict says "kyikâ"
  AwingWord(awing: 'chwádkə', english: 'save', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwaadka" — dict says "chwádkə"
  AwingWord(awing: 'sóŋə', english: 'say', category: 'actions', difficulty: 1),  // Session 56 audit: was "sóŋa" — dict says "sóŋə"
  AwingWord(awing: 'ghabnə̂', english: 'separate', category: 'actions', difficulty: 2),  // Session 56 audit: was "ghabnɔ" — dict says "ghabnə̂"
  AwingWord(awing: "fa'ô", english: 'serve', category: 'actions', difficulty: 2),  // Session 56 audit: was "fa'a" — dict says "fa'ô"
  AwingWord(awing: 'tímə', english: 'sew', category: 'actions', difficulty: 2),  // Session 56 audit: was "tíma" — dict says "tímə"
  AwingWord(awing: 'ghabnə̂', english: 'share', category: 'actions', difficulty: 2),  // Session 56 audit: was "ghabnɔ́" — dict says "ghabnə̂"
  AwingWord(awing: "ŋwa'ô", english: 'shine', category: 'actions', difficulty: 1),  // Session 56 audit: was "gwa'a" — dict says "ŋwa'ô"
  AwingWord(awing: 'támə', english: 'shoot', category: 'actions', difficulty: 2),  // Session 56 audit: was "tóma" — dict says "támə"
  AwingWord(awing: 'naasla', english: 'show', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kəŋə̂', english: 'shut', category: 'actions', difficulty: 1),  // Session 56 audit: was "kaŋɔ́" — dict says "kəŋə̂"
  AwingWord(awing: "gho'ə̂", english: 'grind', category: 'actions', difficulty: 1),  // Session 56 audit: was "ghə̀ŋə" — dict says "gho'ə̂"
  AwingWord(awing: 'lyǎŋə', english: 'hide', category: 'actions', difficulty: 1),
  AwingWord(awing: "tyá'la", english: 'straddle', category: 'actions', difficulty: 3),  // Session 56 audit: was "tyə́'lə" — dict says "tyá'la"
  AwingWord(awing: 'piə̀', english: 'sow', category: 'actions', difficulty: 1),
  AwingWord(awing: 'zòŋə́', english: 'follow', category: 'actions', difficulty: 1),
  AwingWord(awing: "lá'kə", english: 'thank', category: 'actions', difficulty: 1),  // Session 56 audit: was "lə́kə́" — dict says "lá'kə"
  AwingWord(awing: 'pjə́bə́', english: 'protect', category: 'actions', difficulty: 2),
];

/// Things, objects, and food — words kids encounter daily
const List<AwingWord> thingsObjects = [
  // Beginner — everyday objects and food
  AwingWord(awing: 'ajúmə', english: 'thing', category: 'things'),
  AwingWord(awing: 'nəngoomá', english: 'plantain', category: 'things'),  // Session 56 audit: was "nəgoomɔ́" — dict says "nəngoomá"
  AwingWord(awing: 'ngwáŋə', english: 'salt', category: 'things'),
  AwingWord(awing: 'ndzɔ', english: 'beans', category: 'food'),  // Session 56 audit: was "ndzǒ" — dict says "ndzɔ"; Session 57: category 'things'→'food' (beans is food)
  AwingWord(awing: 'mândzǒ', english: 'groundnuts', category: 'things'),
  AwingWord(awing: "nəpɔ́'ə", english: 'pumpkin', category: 'things'),  // Session 56 audit: was "nəpɔ'ɔ́" — dict says "nəpɔ́'ə"
  AwingWord(awing: 'ndua', english: 'hammer', category: 'things'),  // Session 56 audit: was "nduə" — dict says "ndua"
  AwingWord(awing: 'əkwuná', english: 'bed', category: 'things'),  // Session 56 audit: was "əkwunɔ́" — dict says "əkwuná"
  AwingWord(awing: 'nəkəŋ', english: 'pot', category: 'things', pluralForm: 'məkəŋɔ́'),  // Session 56 audit: was "nəkəŋɔ́" — dict says "nəkəŋ"
  AwingWord(awing: 'apeemə', english: 'bag', category: 'things', shortForm: 'apa'),
  AwingWord(awing: 'əpúmə', english: 'basket (large)', category: 'things'),
  AwingWord(awing: 'ajwika', english: 'window', category: 'things'),  // Session 56 audit: was "ajwikə" — dict says "ajwika"
  AwingWord(awing: 'mbê', english: 'knife', category: 'things'),
  AwingWord(awing: "akó'ə", english: 'chair', category: 'things'),  // Session 56 audit: was "kəíə" — dict says "akó'ə"
  AwingWord(awing: 'lɛ̀ərə', english: 'hat', category: 'things'),
  AwingWord(awing: "shwa'ə", english: 'razor', category: 'things'),  // Session 56 audit: was "shwa'a" — dict says "shwa'ə"
  AwingWord(awing: 'alóŋə', english: 'dance group', category: 'things'),  // Session 56 audit: was "əlɔ́ŋə" — dict says "alóŋə"
  AwingWord(awing: 'ŋgɛ̀ərə', english: 'gun', category: 'things'),
  AwingWord(awing: 'mətwé', english: 'saliva', category: 'things'),
  AwingWord(awing: 'akwâalə', english: 'support', category: 'things'),
  AwingWord(awing: 'əpéenə', english: 'bread', category: 'things'),
  AwingWord(awing: "nətó'ə", english: 'potato', category: 'things'),
  AwingWord(awing: 'apúə', english: 'ashes', category: 'things'),
  AwingWord(awing: 'kóŋ', english: 'ditch', category: 'things'),  // Session 56 audit: was "kóŋó" — dict says "kóŋ"
  AwingWord(awing: "əsá'ə", english: 'needle', category: 'things'),
  AwingWord(awing: 'ndê', english: 'house', category: 'things'),
  AwingWord(awing: 'ntaŋə', english: 'hut', category: 'things'),  // Session 56 audit: was "ntɔ̂ŋɔ̂" — dict says "ntaŋə"
  AwingWord(awing: 'atógə', english: 'room', category: 'things'),  // Session 56 audit: was "atɔ́gə" — dict says "atógə"
  AwingWord(awing: 'asogə', english: 'soap', category: 'things'),
  AwingWord(awing: "atsa'á", english: 'clothes', category: 'things'),  // Session 56 audit: was "atsa'ɔ́" — dict says "atsa'á"
  AwingWord(awing: 'múto', english: 'car', category: 'things'),
  AwingWord(awing: "aŋwa'lə", english: 'book/school', category: 'things'),
  // Session 52: was kíə "key (lock)" — kíə (high tone) does not exist in the
  // Awing English Dictionary. Per dict, "key (from English)" = kîə (falling tone).
  AwingWord(awing: 'kîə', english: 'key', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mógɔ́', english: 'fire/burn', category: 'things'),
  AwingWord(awing: 'chénə', english: 'chain', category: 'things'),
  AwingWord(awing: 'nkelá', english: 'rope', category: 'things', pluralForm: 'mənkelɔ́'),  // Session 56 audit: was "nkelɔ́" — dict says "nkelá"
  AwingWord(awing: 'nkwumə', english: 'box', category: 'things'),
  AwingWord(awing: 'bólə', english: 'ball', category: 'things'),  // Session 56 audit: was "bɔ̂lə" — dict says "bólə"
  AwingWord(awing: "ntso ndê", english: 'door', category: 'things'),
  AwingWord(awing: 'nkeemə́', english: 'basket', category: 'things'),  // Session 56 audit: was "nkéemɔ́" — dict says "nkeemə́"
  AwingWord(awing: "kwa'ɔ́", english: 'plate', category: 'things'),
  AwingWord(awing: 'nto', english: 'trousers', category: 'things'),
  AwingWord(awing: "ntó'ə", english: 'calabash', category: 'things'),
  AwingWord(awing: "nkéebə", english: 'money', category: 'things', pluralForm: 'mənkéebə'),
  AwingWord(awing: 'atso', english: 'musical instrument', category: 'things'),
  AwingWord(awing: 'ntaŋə', english: 'horn', category: 'things'),  // Session 56 audit: was "ntâŋɔ̂" — dict says "ntaŋə"
  AwingWord(awing: 'máta', english: 'mat', category: 'things'),
  // CORRECTED tone nkîə → nkǐə "song" — per dict, both homonyms (water/river AND song) use rising-tone nkǐə, not falling-tone nkîə (User-flagged Session 52)
  AwingWord(awing: 'nkǐə', english: 'song', category: 'things'),
  // REMOVED nda'ə "string" — per Awing English Dictionary nda'ə = "only, lone" (per CLAUDE.md, the only Awing word that does not end in a vowel; grammatical, not a kid-facing object). (Session 51 audit, EXACT match)
  AwingWord(awing: 'bɔ́bə', english: 'bulb/ball', category: 'things'),
  AwingWord(awing: 'ŋwíŋɔ́', english: 'machete/cutlass', category: 'things'),
  AwingWord(awing: 'apáŋə', english: 'bamboo', category: 'things'),  // Session 56 audit: was "ndaŋɔ́" — dict says "apáŋə"
  AwingWord(awing: 'táksə', english: 'tax', category: 'things'),  // Session 56 audit: was "táksa" — dict says "táksə"
  // Medium/Expert — less common objects
  AwingWord(awing: 'mbéenə', english: 'nail', category: 'things', difficulty: 2),
  AwingWord(awing: "fwə'ə", english: 'chisel', category: 'things', difficulty: 2),  // Session 56 audit: was "fwɔ'ə" — dict says "fwə'ə"
  AwingWord(awing: 'ndzəəmə', english: 'dream', category: 'things', difficulty: 2),  // Session 56 audit: was "ndzoəmə" — dict says "ndzəəmə"
  AwingWord(awing: 'ndwîgtə', english: 'end', category: 'things', difficulty: 2),
  AwingWord(awing: 'mətwê', english: 'saliva', category: 'things', difficulty: 2),  // Session 56 audit: was "ɔ̂twé" — dict says "mətwê"
  AwingWord(awing: "əghâa", english: 'season', category: 'things', difficulty: 3),
  // New things from phonology/orthography PDFs
  // CORRECTED sáŋə "broom" → "moon/month" — per dict EXACT match sáŋə = "1) moon 2) month" or "bird" (Session 51 audit, recategorized to nature below)
  AwingWord(awing: 'sáŋə', english: 'moon/month', category: 'nature'),
  AwingWord(awing: 'atê', english: 'rust', category: 'things', difficulty: 2),
  AwingWord(awing: 'akɔ̀\'ə', english: 'stool/chair (traditional)', category: 'things'),
  AwingWord(awing: 'ŋgwánə', english: 'pot (clay)', category: 'things'),
  AwingWord(awing: 'nkwɔ̂ŋə', english: 'stick/staff', category: 'things'),
  AwingWord(awing: 'ətsê', english: 'mortar', category: 'things'),
  AwingWord(awing: 'mbə̂ŋə', english: 'drum', category: 'things'),
  AwingWord(awing: 'ŋgwɔ̂bə', english: 'bowl', category: 'things'),
  AwingWord(awing: 'atsúŋə', english: 'fence', category: 'things'),
  AwingWord(awing: "lí'ə", english: 'hoe', category: 'things'),  // Session 56 audit: was "mbé'ə" — dict says "lí'ə"
  AwingWord(awing: 'nəkwɔ́ŋə', english: 'pestle', category: 'things'),
  AwingWord(awing: 'ŋgwə̂ə', english: 'paddle/oar', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntsɔ̂ŋə', english: 'market stall', category: 'things', difficulty: 2),
  AwingWord(awing: 'àtɔ̂glə', english: 'pillow', category: 'things'),
  AwingWord(awing: 'nkwə̂mə', english: 'container', category: 'things'),
  AwingWord(awing: 'əkə̂ŋə', english: 'cooking pot', category: 'things'),
  AwingWord(awing: 'ndwîglə', english: 'edge/end', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzɛ̀ŋə', english: 'trap', category: 'things', difficulty: 2),
  AwingWord(awing: 'atə̂ŋə', english: 'story/tale', category: 'things'),
  AwingWord(awing: 'ŋwà\'lə', english: 'letter/writing', category: 'things'),
  AwingWord(awing: 'ntɔ́gə', english: 'name', category: 'things'),
  AwingWord(awing: 'ŋkə̂ŋə', english: 'word/language', category: 'things'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'akwelə', english: 'herd', category: 'things', difficulty: 2),  // Session 56 audit: was "akwɛlɔ" — dict says "akwelə"
  AwingWord(awing: 'ndzaŋa', english: 'kind', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndé moŋa', english: 'kitchen', category: 'things', difficulty: 1),
  AwingWord(awing: "kó'ó", english: 'ladder', category: 'things', difficulty: 2),  // Session 56 audit: was "kɔ́'ɔ" — dict says "kó'ó"
  AwingWord(awing: 'atséebə', english: 'language', category: 'things', difficulty: 2),  // Session 56 audit: was "ɔ́tsĕba" — dict says "atséebə"
  AwingWord(awing: 'noŋkə', english: 'law', category: 'things', difficulty: 3),  // Session 56 audit: was "noŋka" — dict says "noŋkə"
  AwingWord(awing: 'nchîmbîə', english: 'life', category: 'things', difficulty: 2),  // Session 56 audit: was "nchímbîɔ" — dict says "nchîmbîə"
  AwingWord(awing: "nkya'ə", english: 'light', category: 'things', difficulty: 1),  // Session 56 audit: was "nkya'ɔ" — dict says "nkya'ə"
  AwingWord(awing: 'ŋwíŋə', english: 'machete', category: 'things', difficulty: 1),  // Session 56 audit: was "nwîŋa" — dict says "ŋwíŋə"
  AwingWord(awing: 'ngəsáŋə́', english: 'corn', category: 'things', difficulty: 1),  // Session 56 audit: was "ngɔ́sáŋɔ́" — dict says "ngəsáŋə́"
  AwingWord(awing: 'nkəənə', english: 'message', category: 'things', difficulty: 1),  // Session 56 audit: was "nkáɔna" — dict says "nkəənə"
  AwingWord(awing: 'ntúmə', english: 'messenger', category: 'things', difficulty: 2),  // Session 56 audit: was "ntúma" — dict says "ntúmə"
  AwingWord(awing: 'anyi ntúmɔ', english: 'metal', category: 'things', difficulty: 2),
  AwingWord(awing: 'awɛ', english: 'mirror', category: 'things', difficulty: 1),
  AwingWord(awing: 'nkéebə', english: 'money', category: 'things', difficulty: 1),  // Session 56 audit: was "nkɛɛbɔ" — dict says "nkéebə"
  AwingWord(awing: 'akɔ́ɔma', english: 'happiness', category: 'things', difficulty: 2),
  AwingWord(awing: "ngá'ə", english: 'hardship', category: 'things', difficulty: 2),  // Session 56 audit: was "ngo'ɔ" — dict says "ngá'ə"
  AwingWord(awing: 'akwaŋə', english: 'idea', category: 'things', difficulty: 2),  // Session 56 audit: was "akwɔŋa" — dict says "akwaŋə"
  AwingWord(awing: 'aghoonó', english: 'illness', category: 'things', difficulty: 2),  // Session 56 audit: was "aghoɔnɔ́" — dict says "aghoonó"
  AwingWord(awing: 'nənyinə', english: 'journey', category: 'things', difficulty: 2),  // Session 56 audit: was "nanŷina" — dict says "nənyinə"
  AwingWord(awing: "əshí'nə", english: 'kindness', category: 'things', difficulty: 2),  // Session 56 audit: was "ashî'na" — dict says "əshí'nə"
  AwingWord(awing: "ndé'ə", english: 'necklace', category: 'things', difficulty: 2),  // Session 56 audit: was "ndé'ɔ́" — dict says "ndé'ə"
  AwingWord(awing: "əsá'ə", english: 'needle', category: 'things', difficulty: 1),  // Session 56 audit: was "sɔ́'a" — dict says "əsá'ə"
  AwingWord(awing: 'nka sáŋɔ́', english: 'nest', category: 'things', difficulty: 2),
  AwingWord(awing: "ajwa'áli'ó", english: 'noise', category: 'things', difficulty: 2),  // Session 56 audit: was "ajwa'ali'ɔ́" — dict says "ajwa'áli'ó"
  AwingWord(awing: 'ndenə', english: 'number', category: 'things', difficulty: 2),  // Session 56 audit: was "ndema" — dict says "ndenə"
  AwingWord(awing: 'atía nɔ́taɔna', english: 'palm tree', category: 'things', difficulty: 2),
  AwingWord(awing: 'alaŋó', english: 'path', category: 'things', difficulty: 1),  // Session 56 audit: was "alanɔ́" — dict says "alaŋó"
  AwingWord(awing: 'awaamɔ́mbɔama', english: 'patience', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntûə', english: 'payment', category: 'things', difficulty: 2),  // Session 56 audit: was "ntía" — dict says "ntûə"
  AwingWord(awing: 'nkəŋə', english: 'peace', category: 'things', difficulty: 1),  // Session 56 audit: was "nkɔŋa" — dict says "nkəŋə"
  AwingWord(awing: "ndí'ə", english: 'poison', category: 'things', difficulty: 2),  // Session 56 audit: was "ndá'ɔ́" — dict says "ndí'ə"
  AwingWord(awing: 'naíɔ́\'ɔ', english: 'potato', category: 'things', difficulty: 1),
  AwingWord(awing: "shwa'ə", english: 'razor', category: 'things', difficulty: 2),  // Session 56 audit: was "shwa'ɔ" — dict says "shwa'ə"
  AwingWord(awing: 'ngwubə', english: 'shoe', category: 'things', difficulty: 1),  // Session 56 audit: was "ngwúba" — dict says "ngwubə"
  AwingWord(awing: 'msóm', english: 'sin', category: 'things', difficulty: 2),
  AwingWord(awing: 'asɔ́ɔma', english: 'shame', category: 'things', difficulty: 2),
  AwingWord(awing: "aŋwa'lə", english: 'school', category: 'things', difficulty: 1),  // Session 56 audit: was "agwa'la" — dict says "aŋwa'lə"
  AwingWord(awing: 'náanə', english: 'sea', category: 'things', difficulty: 1),  // Session 56 audit: was "nɔ́sana" — dict says "náanə"
  AwingWord(awing: 'sə̀bə̀ə̀bə́', english: 'thorn', category: 'things', difficulty: 2),
  AwingWord(awing: 'alědnə', english: 'wealth', category: 'things', difficulty: 2),  // Session 56 audit: was "alɛ́dnə̀" — dict says "alědnə"
  AwingWord(awing: 'ge:nə́', english: 'week', category: 'things', difficulty: 2),
  // Session 52 gloss audit: was "village" (that is alá'ə at L584) — dict says "hook" / "far future tense marker"
  AwingWord(awing: 'lá\'ə̀', english: 'hook', category: 'things', difficulty: 1),
  AwingWord(awing: 'mətuə́\'ə', english: 'caterpillar', category: 'things', difficulty: 2),
  AwingWord(awing: 'àkəỳə́', english: 'cave', category: 'things', difficulty: 2),
];

/// Family, people, and places — essential for conversations
const List<AwingWord> familyPeople = [
  // Beginner — family and common places
  AwingWord(awing: 'mǎ', english: 'mother', category: 'family', pluralForm: 'pəmǎ'),
  AwingWord(awing: 'tátə', english: 'grandfather', category: 'family'),
  AwingWord(awing: 'mábna', english: 'baby', category: 'family'),
  // REMOVED yə "he/she" — per Awing English Dictionary yə is an associative/possessive grammatical marker, not the pronoun for "he/she" (Session 51 audit, EXACT match)
  AwingWord(awing: "alá'ə", english: 'village', category: 'family', pluralForm: "əlá'ə"),
  AwingWord(awing: 'adě', english: 'house', category: 'family'),
  AwingWord(awing: 'ngye', english: 'voice', category: 'family'),
  AwingWord(awing: 'məteenə̂', english: 'market', category: 'family'),  // Session 56 audit: was "mətéenɔ́" — dict says "məteenə̂"
  AwingWord(awing: 'əfóŋə', english: 'reader', category: 'family', pluralForm: 'pəfɔ́nə'),  // Session 56 audit: was "əfɔ́nə" — dict says "əfóŋə"
  AwingWord(awing: 'ndáəshə', english: 'thief', category: 'family'),
  AwingWord(awing: 'ndimá', english: 'nephew', category: 'family'),  // Session 56 audit: was "əndìmə" — dict says "ndimá"
  AwingWord(awing: 'ngəmə́', english: 'mother-in-law', category: 'family'),  // Session 56 audit: was "ŋgàmə" — dict says "ngəmə́"
  AwingWord(awing: 'əgùərə', english: 'descendant', category: 'family'),
  AwingWord(awing: 'tǎ', english: 'father/parent', category: 'family', pluralForm: 'pətǎ'),
  AwingWord(awing: 'ngəənə', english: 'friend', category: 'family', pluralForm: 'pəghəənə'),
  AwingWord(awing: 'ndúmə', english: 'husband', category: 'family'),
  AwingWord(awing: 'mangyè', english: 'wife', category: 'family'),  // Session 56 audit: was "maŋgyè" — dict says "mangyè"
  AwingWord(awing: 'ndè', english: 'elder', category: 'family'),
  AwingWord(awing: 'əfo', english: 'chief/ruler', category: 'family'),
  AwingWord(awing: "ŋwunə", english: 'person', category: 'family', pluralForm: 'paənə'),
  AwingWord(awing: "mɔ́ mbyâŋnə", english: 'boy/son', category: 'family'),
  AwingWord(awing: "mɔ́ maŋgyè", english: 'girl/daughter', category: 'family'),
  AwingWord(awing: 'mɔ́ŋkə', english: 'child', category: 'family'),
  AwingWord(awing: 'ngaŋə', english: 'owner', category: 'family'),
  AwingWord(awing: "ngaŋəfa'ə", english: 'servant', category: 'family'),
  // Session 52 gloss audit: was "butcher" (the butcher is adzə̌ə at L637) — dict says "bucket"
  AwingWord(awing: "nkɔ́'ə", english: 'bucket', category: 'things'),
  AwingWord(awing: 'atúmə', english: 'country/land', category: 'family'),
  AwingWord(awing: 'afoonə', english: 'farm', category: 'family'),
  AwingWord(awing: 'nchîndê', english: 'compound', category: 'family'),
  // Session 52 gloss audit: was "place" — dict says "cultivated ground"
  AwingWord(awing: "ali'ə", english: 'cultivated ground', category: 'nature'),
  AwingWord(awing: 'awátə', english: 'hospital', category: 'family'),
  AwingWord(awing: 'chɔ́sə', english: 'church', category: 'family'),
  // Medium/Expert
  AwingWord(awing: 'ayáŋə', english: 'wisdom', category: 'family', difficulty: 2),
  AwingWord(awing: 'ndo', english: 'stream', category: 'family', difficulty: 2),  // Session 56 audit: was "nkɨ́ə" — dict says "ndo"
  // New family/people from phonology/orthography PDFs
  AwingWord(awing: 'mǎ wíŋɔ́', english: 'grandmother', category: 'family'),
  AwingWord(awing: 'nda', english: 'sister/sibling', category: 'family'),
  AwingWord(awing: 'nə̂ŋgə', english: 'brother', category: 'family'),
  AwingWord(awing: 'mɔ́\'ŋkə', english: 'young person', category: 'family'),
  AwingWord(awing: 'əfɔ̀nə', english: 'teacher', category: 'family'),
  AwingWord(awing: 'ətsɛ́bə', english: 'speaker/orator', category: 'family', difficulty: 2),
  AwingWord(awing: 'əzó\'ə', english: 'listener/judge', category: 'family', difficulty: 2),
  // Session 52 gloss audit: was "traditional doctor" — dict says "owner" (like ngaŋə at L603)
  AwingWord(awing: 'ngàŋə', english: 'owner', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfo wíŋɔ́', english: 'paramount chief', category: 'family', difficulty: 2),
  AwingWord(awing: 'əkwáŋə', english: 'stranger/visitor', category: 'family'),
  AwingWord(awing: 'ndzɔ̂ŋə', english: 'age group', category: 'family', difficulty: 2),
  AwingWord(awing: 'əlúmə', english: 'hunter', category: 'family', difficulty: 2),
  AwingWord(awing: 'ŋgwîə', english: 'twins', category: 'family'),
  AwingWord(awing: 'əpɔ̀ŋə', english: 'co-wife', category: 'family', difficulty: 3),
  AwingWord(awing: 'nkwə̂ŋə', english: 'council/meeting', category: 'family', difficulty: 2),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'mbɛ', english: 'chief', category: 'family', difficulty: 2),  // Session 56 audit: was "mɔ̂nə" — dict says "mbɛ"
  AwingWord(awing: 'mən\'ɔ', english: 'person', category: 'family', difficulty: 1),
  AwingWord(awing: 'məbîə', english: 'boy', category: 'family', difficulty: 1),
  AwingWord(awing: 'əbîə', english: 'girl', category: 'family', difficulty: 1),
  AwingWord(awing: 'məkwɛ́', english: 'servant', category: 'family', difficulty: 2),
  AwingWord(awing: 'adzə̌ə', english: 'butcher', category: 'family', difficulty: 2),
  AwingWord(awing: 'ndzɔ̂ŋɔ', english: 'country', category: 'family', difficulty: 2),
  // Session 52 gloss audit: was "place" — dict says 'where? (interrogative)'
  AwingWord(awing: 'àfó', english: 'where?', category: 'descriptive', difficulty: 1),
];

/// Numbers and counting
const List<AwingWord> numbers = [
  AwingWord(awing: 'wûu', english: 'one', category: 'numbers'),  // Session 56 audit: was "əmɔ́" — dict says "wûu"
  AwingWord(awing: 'pě', english: 'two', category: 'numbers'),  // Session 56 audit: was "əpá" — dict says "pě"
  AwingWord(awing: 'wô', english: 'three', category: 'numbers'),  // Session 56 audit: was "əlɛ́" — dict says "wô"
  AwingWord(awing: 'kwa', english: 'four', category: 'numbers'),  // Session 56 audit: was "əkwá" — dict says "kwa"
  AwingWord(awing: 'tênə', english: 'five', category: 'numbers'),  // Session 56 audit: was "ətáanə" — dict says "tênə"
  AwingWord(awing: 'ntogə́', english: 'six', category: 'numbers'),
  AwingWord(awing: 'asaambê', english: 'seven', category: 'numbers'),
  AwingWord(awing: 'nəfeemə́', english: 'eight', category: 'numbers'),
  AwingWord(awing: 'nəpu\'ə́', english: 'nine', category: 'numbers'),
  AwingWord(awing: 'nəghámə', english: 'ten', category: 'numbers'),  // Session 56 audit: was "əghám" — dict says "nəghámə"
  // Teens (11-19) — dictionary: ntsəb + base number
  AwingWord(awing: 'əghám nə əmɔ́', english: 'eleven', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'əghám nə əpá', english: 'twelve', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb teelə́', english: 'thirteen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb nəkwa', english: 'fourteen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb tênə', english: 'fifteen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb ntogə́', english: 'sixteen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb asaambê', english: 'seventeen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb nəfeemə́', english: 'eighteen', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'ntsəb nəpu\'ə́', english: 'nineteen', category: 'numbers', difficulty: 2),
  // Tens (20-90) — dictionary: məghə́m mén + base number
  AwingWord(awing: 'mbá', english: 'twenty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'mbá nə əghám', english: 'thirty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'mbá əpá', english: 'forty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghə́m mén tênə', english: 'fifty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghə́m mén ntogə́', english: 'sixty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghə́m mén asaambê', english: 'seventy', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghə́m mén nəfeemə́', english: 'eighty', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghə́m mén nəpu\'ə́', english: 'ninety', category: 'numbers', difficulty: 2),
  // Hundred (medium)
  AwingWord(awing: 'ŋgwú', english: 'hundred', category: 'numbers', difficulty: 2),
  // Compound twenties (21-25) — dictionary p.192
  AwingWord(awing: "məghə́m mém mbê nə́ tá'ə", english: 'twenty-one', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pém pê', english: 'twenty-two', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pén teelə́', english: 'twenty-three', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ nəkwa', english: 'twenty-four', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pén tênə', english: 'twenty-five', category: 'numbers', difficulty: 3),
  // Hundreds (200-500) — dictionary: nked + base number
  AwingWord(awing: 'nked pê', english: 'two hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked teelə́', english: 'three hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked zén nəkwa', english: 'four hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked tênə', english: 'five hundred', category: 'numbers', difficulty: 3),
  // Thousand
  AwingWord(awing: 'tóosə', english: 'thousand', category: 'numbers', difficulty: 3),  // Session 56 audit: was "tə́sə" — dict says "tóosə"
];

// ============================================================
// MEDIUM/EXPERT VOCABULARY (difficulty: 2-3) — more complex words
// ============================================================

/// More actions/verbs from the orthography & phonology PDFs
const List<AwingWord> moreActions = [
  // Medium
  AwingWord(awing: 'shîəə', english: 'stretch', category: 'actions', difficulty: 2),  // Session 56 audit: was "shîə" — dict says "shîəə"
  AwingWord(awing: 'yîkə', english: 'harden', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fágə', english: 'blow', category: 'actions', difficulty: 2),  // Session 56 audit: was "tɔ́gə" — dict says "fágə"
  AwingWord(awing: 'kaŋtə', english: 'stumble', category: 'actions', difficulty: 2),  // Session 56 audit: was "kaŋtɔ́" — dict says "kaŋtə"
  AwingWord(awing: 'sednô', english: 'turn round', category: 'actions', difficulty: 2),  // Session 56 audit: was "sɛdnɔ́" — dict says "sednô"
  AwingWord(awing: 'nyaglə', english: 'tickle', category: 'actions', difficulty: 2),  // Session 56 audit: was "nyaglɔ́" — dict says "nyaglə"
  AwingWord(awing: 'nɔ́ŋə', english: 'suck', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lednə̂', english: 'sweat', category: 'actions', difficulty: 2),  // Session 56 audit: was "lɛdnɔ́" — dict says "lednə̂"
  // Session 52 gloss audit: was "twist" — dict says "give birth (by many women or many children by one)"
  AwingWord(awing: 'pìkə', english: 'give birth', category: 'actions', difficulty: 2),
  AwingWord(awing: 'soobô', english: 'stab', category: 'actions', difficulty: 2),  // Session 56 audit: was "sɔ̀ɔbə" — dict says "soobô"
  AwingWord(awing: 'kwúbtə', english: 'close', category: 'actions', difficulty: 2),
  AwingWord(awing: 'akwúblə', english: 'exchange', category: 'actions', difficulty: 2),  // Session 56 audit: was "kwùɔbə" — dict says "akwúblə"
  AwingWord(awing: 'lóŋkə', english: 'fill', category: 'actions', difficulty: 2),  // Session 56 audit: was "lɛ̀ŋkə" — dict says "lóŋkə"
  AwingWord(awing: 'ídkə', english: 'frighten', category: 'actions', difficulty: 2),
  AwingWord(awing: 'nwâŋə', english: 'disappear', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ɔ̂ŋwâə', english: 'be clean', category: 'actions', difficulty: 2),
  AwingWord(awing: 'təənô', english: 'be mature', category: 'actions', difficulty: 2, shortForm: 'tə̂nə'),  // Session 56 audit: was "tɔ̂ənə" — dict says "təənô"
  AwingWord(awing: 'fìnə', english: 'resemble each other', category: 'actions', difficulty: 2),
  AwingWord(awing: "tyá'la", english: 'straddle', category: 'actions', difficulty: 2),  // Session 56 audit: was "tyá'lə" — dict says "tyá'la"
  AwingWord(awing: 'puónə', english: 'dip in water', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chwígə', english: 'spy', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwigó" — dict says "chwígə"
  // Expert
  AwingWord(awing: 'təəmə', english: 'choke', category: 'actions', difficulty: 3),  // Session 56 audit: was "tɔ́əmə" — dict says "təəmə"
  AwingWord(awing: "ne'â", english: 'limp', category: 'actions', difficulty: 3),  // Session 56 audit: was "ne'ɔ́" — dict says "ne'â"
  AwingWord(awing: 'pwódkə', english: 'appease', category: 'actions', difficulty: 3),  // Session 56 audit: was "pwɔ́nə" — dict says "pwódkə"
  AwingWord(awing: "ɔ̀pwə̂nənə", english: 'be kind', category: 'actions', difficulty: 3),
  AwingWord(awing: 'ntɨ́mmaə', english: 'stagger', category: 'actions', difficulty: 3),
];

/// More things/objects — medium and expert level
const List<AwingWord> moreThings = [
  AwingWord(awing: 'nəchwélə', english: 'hearth', category: 'things', difficulty: 2),
  AwingWord(awing: "ntúmkə", english: 'entrance hut', category: 'things', difficulty: 2),
  AwingWord(awing: 'əleglə', english: 'bridge', category: 'things', difficulty: 2),  // Session 56 audit: was "əlɛɛlə" — dict says "əleglə"
  AwingWord(awing: 'ŋgwɔ́ɔlə', english: 'snail', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəghǒ', english: 'grinding stone', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwé', english: 'response', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoolá', english: 'latrine', category: 'things', difficulty: 2),
  AwingWord(awing: "ashwí'ə", english: 'swelling', category: 'things', difficulty: 2),
  AwingWord(awing: 'njwîŋə', english: 'whistle', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbwódnə', english: 'blessing', category: 'things', difficulty: 2),
  // Session 52 gloss audit: was "hardship" — dict says "year" / "red-feathered bird" / "termite"
  AwingWord(awing: "ngó'ə", english: 'year', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsáŋə', english: 'punishment', category: 'things', difficulty: 3),
  AwingWord(awing: 'ŋwáglə', english: 'bell', category: 'things', difficulty: 3),  // Session 56 audit: was "ŋwáglɔ́" — dict says "ŋwáglə"
  AwingWord(awing: 'azagá', english: 'odour', category: 'things', difficulty: 3),  // Session 56 audit: was "azagɔ́" — dict says "azagá"
];

/// Descriptive words (adjectives/adverbs) — colors, sizes, qualities
const List<AwingWord> descriptiveWords = [
  // Colors and appearance
  AwingWord(awing: 'shíshíə', english: 'black', category: 'descriptive'),
  AwingWord(awing: 'fúfûə', english: 'white', category: 'descriptive'),
  AwingWord(awing: 'paŋə', english: 'red', category: 'descriptive'),  // Session 56 audit: was "paŋpaŋə" — dict says "paŋə"
  AwingWord(awing: 'sénə', english: 'blue/green/dark', category: 'descriptive'),
  // Size and shape
  AwingWord(awing: 'wíŋɔ́', english: 'big', category: 'descriptive'),
  AwingWord(awing: 'mɔ́', english: 'small', category: 'descriptive'),
  AwingWord(awing: 'sagɔ́', english: 'long/far', category: 'descriptive'),
  AwingWord(awing: 'kəmkə̂', english: 'short', category: 'descriptive'),  // Session 56 audit: was "kamkɔ̂" — dict says "kəmkə̂"
  AwingWord(awing: 'fáŋə', english: 'fat/thick', category: 'descriptive'),
  AwingWord(awing: 'ashwánə', english: 'thin', category: 'descriptive'),
  // Qualities
  // Session 52 gloss audit: was "good/kind" — dict says "trade"
  AwingWord(awing: "ashî'nə", english: 'trade', category: 'things'),
  AwingWord(awing: 'poŋô', english: 'beautiful', category: 'descriptive'),  // Session 56 audit: was "pɔ̀ŋɔ́" — dict says "poŋô"
  AwingWord(awing: 'tonô', english: 'hot', category: 'descriptive'),  // Session 56 audit: was "tɔnɔ́" — dict says "tonô"
  AwingWord(awing: 'nwâ', english: 'cold', category: 'descriptive'),
  AwingWord(awing: 'tyantɔ̌', english: 'hard/strong', category: 'descriptive'),
  AwingWord(awing: "fía", english: 'new/fresh', category: 'descriptive'),
  AwingWord(awing: 'ndenə', english: 'old', category: 'descriptive'),
  AwingWord(awing: 'mboŋɔ́', english: 'many/much', category: 'descriptive'),
  AwingWord(awing: "nta'lə", english: 'few/little', category: 'descriptive'),
  AwingWord(awing: 'senô', english: 'today', category: 'descriptive'),  // Session 56 audit: was "senɔ́" — dict says "senô"
  AwingWord(awing: "ngwe'ə́", english: 'tomorrow', category: 'descriptive'),  // Session 56 audit: was "ngwe'ɔ́" — dict says "ngwe'ə́"
  AwingWord(awing: 'zá', english: 'often/usually', category: 'descriptive'),
  // Medium difficulty
  AwingWord(awing: 'dotê', english: 'ugly', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "dɔtɔ́" — dict says "dotê"
  AwingWord(awing: "təji'ə", english: 'alone', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "tɔ̀jí'ə" — dict says "təji'ə"
  AwingWord(awing: 'páta', english: 'even though', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "pátə" — dict says "páta"
  AwingWord(awing: 'chígɔ́', english: 'truly/really', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ghâsə', english: 'clever/smart', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'zaŋkə', english: 'light (not heavy)', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "zaŋkɔ̂" — dict says "zaŋkə"
  AwingWord(awing: 'kóŋɔ́', english: 'empty', category: 'descriptive', difficulty: 2),
  // New descriptive words from phonology/orthography PDFs
  AwingWord(awing: 'kwɨ̂ŋɔ́', english: 'sweet', category: 'descriptive'),
  AwingWord(awing: 'shwàŋə', english: 'sharp', category: 'descriptive'),
  AwingWord(awing: 'kwakə̂', english: 'broken', category: 'descriptive'),  // Session 56 audit: was "kpɔ̂ŋə" — dict says "kwakə̂"
  AwingWord(awing: 'tsɛ̀ŋə', english: 'dry', category: 'descriptive'),
  // CORRECTED fúfúə "bright/clean" → "white" per Awing English Dictionary EXACT match (Session 51 audit)
  AwingWord(awing: 'fúfúə', english: 'white', category: 'descriptive'),
  AwingWord(awing: 'dzə̀mə', english: 'deep', category: 'descriptive', difficulty: 2),
  // Session 52 gloss audit: was "wide" — dict says "think" (and also "clean furrows of farm bed")
  AwingWord(awing: 'kwàŋə', english: 'think', category: 'actions'),
  AwingWord(awing: 'ntsə̂ŋə', english: 'narrow', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'tə̂ŋə', english: 'straight', category: 'descriptive'),
  // Session 52 gloss audit: was "round/circular" — dict says "ringworm"
  AwingWord(awing: 'kwə̂glə', english: 'ringworm', category: 'body'),
  AwingWord(awing: 'ataŋə', english: 'full', category: 'descriptive'),  // Session 56 audit: was "yíŋə" — dict says "ataŋə"
  AwingWord(awing: 'tsɔ̂ŋə', english: 'heavy', category: 'descriptive'),
  AwingWord(awing: 'sɛ̂ŋə', english: 'raw/uncooked', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'shɔ̂ŋə', english: 'ripe/ready', category: 'descriptive'),
  // Session 52 gloss audit: was "early" — dict says "steep place, hilly place" (primary gloss)
  AwingWord(awing: 'kə̂ŋə', english: 'steep place, hilly place', category: 'nature'),
  // Session 52 gloss audit: was "late" — dict says "cane, walking stick" (tone variant of L 208 mbâŋə)
  AwingWord(awing: 'mbàŋə', english: 'cane, walking stick', category: 'things'),
  AwingWord(awing: 'ntsɔ́ŋɔ́', english: 'fast/quick', category: 'descriptive'),
  AwingWord(awing: 'nyàŋə', english: 'slow/careful', category: 'descriptive'),
  AwingWord(awing: 'wɔ̂ŋə', english: 'quiet/silent', category: 'descriptive'),
  AwingWord(awing: 'kpɔ̀ŋɔ́', english: 'loud/noisy', category: 'descriptive', difficulty: 2),
  // Session 52: was nûə "sweet (like honey)" — WRONG. Per dictionary, nûə = "honey"
  // (the noun, already correctly at L232 in food category). Replaced with ləmkə̂
  // ("be tasty/sweet"), the actual word for the "sweet" descriptor.
  AwingWord(awing: 'ləmkə̂', english: 'sweet/tasty', category: 'descriptive', tonePattern: 'falling'),
  AwingWord(awing: 'shɨ̂ŋə', english: 'sour/bitter', category: 'descriptive'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'dotê', english: 'dirty', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "dɔ́tɔ̀" — dict says "dotê"
  AwingWord(awing: 'tyanɔ́', english: 'hard', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'yɨ̌la', english: 'difficult', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'achínə', english: 'important', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "achîna" — dict says "achínə"
  AwingWord(awing: 'lóŋnə', english: 'lazy', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "bɨ̀ŋna" — dict says "lóŋnə"
  AwingWord(awing: 'sagə', english: 'long', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "sga" — dict says "sagə"
  AwingWord(awing: 'préta', english: 'crazy', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'yéelə', english: 'mad', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "yéeta" — dict says "yéelə"
  AwingWord(awing: 'mbɔŋɔ́', english: 'many', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'tsaanɔ́', english: 'mature', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'fîə', english: 'new', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "fía" — dict says "fîə"
  AwingWord(awing: 'póŋə', english: 'poor', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "fóŋa" — dict says "póŋə"
  AwingWord(awing: 'léelə', english: 'ready', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "léeta" — dict says "léelə"
  AwingWord(awing: 'ndaŋə', english: 'same', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "ndɔŋɔ́" — dict says "ndaŋə"
  AwingWord(awing: 'ghoonə̂', english: 'sick', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "ghooɔ́nɔ́" — dict says "ghoonə̂"
  AwingWord(awing: 'zaŋkə', english: 'light', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "zaŋkɔ́" — dict says "zaŋkə"
  AwingWord(awing: 'achîna', english: 'strong', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'neebɔ', english: 'clean', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'azoŋkə', english: 'second', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "azɔŋɔ́" — dict says "azoŋkə"
  AwingWord(awing: 'ntúa\'ɔ', english: 'nice', category: 'descriptive', difficulty: 1),
];

// ============================================================
// PHRASES & GREETINGS — simple, practical phrases for daily use
// ============================================================

class AwingPhrase {
  final String awing;
  final String english;
  final String? context; // when to use it
  final String category; // greeting, daily, question, farewell, classroom
  final String? clipKey; // audio clip filename in sentences/ folder

  const AwingPhrase({
    required this.awing,
    required this.english,
    this.context,
    this.category = 'greeting',
    this.clipKey,
  });
}

/// Phrases and sentences verified from the Awing Orthography Guide (2005)
/// by Alomofor Christian and Stephen C. Anderson, and the Awing English
/// Dictionary (2007) by Alomofor Christian, CABTAL.
///
/// IMPORTANT: Only add phrases that are directly sourced from these PDFs
/// or confirmed by a native Awing speaker. Do NOT fabricate phrases.
const List<AwingPhrase> awingPhrases = [
  // === VERIFIED SENTENCES — from AwingOrthography2005.pdf ===

  // Page 9: Past tense example
  AwingPhrase(
    awing: "A kə ghɛnɔ́ məteenɔ́.",
    english: "He went to the market",
    context: "Past tense — talking about where someone went",
    category: 'daily',
    clipKey: 'daily_market',
  ),

  // Page 10: Elision / demonstrative example
  AwingPhrase(
    awing: "Lɛ̌ nəpɔ'ɔ́.",
    english: "This is a pumpkin",
    context: "Pointing at something and naming it",
    category: 'daily',
    clipKey: 'daily_this_pumpkin',
  ),

  // Page 11: Full stop / declarative sentence
  AwingPhrase(
    awing: "Móonə a tə nonnɔ́ a əkwunɔ́.",
    english: "The baby is lying on the bed",
    context: "Describing what someone is doing — present progressive",
    category: 'daily',
    clipKey: 'daily_baby_bed',
  ),

  // Page 11: Question mark / interrogative
  AwingPhrase(
    awing: "A ghɛlɔ́ lə aké?",
    english: "What is he doing?",
    context: "Asking about someone's activity — complement question",
    category: 'question',
    clipKey: 'question_what_doing',
  ),

  // Page 11: Exclamation / command
  AwingPhrase(
    awing: "Lǒ!",
    english: "Get out!",
    context: "Command — telling someone to leave",
    category: 'classroom',
    clipKey: 'classroom_get_out',
  ),

  // Page 11: Negative imperative
  AwingPhrase(
    awing: "Kə pinkɔ́ sóŋə!",
    english: "Don't mention it again!",
    context: "Telling someone not to repeat something",
    category: 'classroom',
    clipKey: 'classroom_dont_mention',
  ),

  // Page 11: Comma / two clauses
  AwingPhrase(
    awing: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə.",
    english: "They are not coming here, they are going to the stream",
    context: "Describing movement — two clauses with comma",
    category: 'daily',
    clipKey: 'daily_going_stream',
  ),

  // Page 11-12: Comma / listing possessions
  AwingPhrase(
    awing: "Ŋwu yə a túgə pəŋgyɛ̌ pɛn pəpɛ̌, məŋgɔ́b mɛn mənteelɔ́ nə tá'ə ngwûə.",
    english: "That man has two wives, three chickens and one dog",
    context: "Listing things someone has — numbers and nouns",
    category: 'daily',
    clipKey: 'daily_man_possessions',
  ),

  // Page 12: Quotation marks / direct speech
  AwingPhrase(
    awing: "Ghǒ ghɛnɔ́ lə əfó?",
    english: "Where are you going?",
    context: "Asking someone where they are headed",
    category: 'question',
    clipKey: 'question_where_going',
  ),

  // Page 12: Full quotation with speaker
  AwingPhrase(
    awing: "Máma a tə mbítə ngə, \"Ghǒ ghɛnɔ́ lə əfó?\"",
    english: "Grandmother is asking, \"Where are you going?\"",
    context: "Direct speech — quoting what grandmother said",
    category: 'daily',
    clipKey: 'daily_grandma_asking',
  ),

  // Page 12: Capitalisation / first word
  AwingPhrase(
    awing: "Po zí nóolə.",
    english: "They have seen a snake",
    context: "Reporting what happened — perfect tense",
    category: 'daily',
    clipKey: 'daily_seen_snake',
  ),

  // Page 12: Capitalisation / proper nouns
  AwingPhrase(
    awing: "Mbá'chi, Apɛnə nə Mbyáb tə nkɔ́'ə atǐə.",
    english: "Mbachia, Apena and Mbyaabo are climbing a tree",
    context: "Proper nouns are capitalized — naming people",
    category: 'daily',
    clipKey: 'daily_climbing_tree',
  ),

  // Page 12: Capitalisation / after colon
  AwingPhrase(
    awing: "Lɔ́ anuə: Táta akɛ̌ ndé chíə pó.",
    english: "It is true: Tata (grandfather) is not in the house",
    context: "Colon usage — confirming a fact",
    category: 'daily',
    clipKey: 'daily_tata_house',
  ),

  // === VERIFIED WORDS USED AS EXCLAMATIONS — from Awing English Dictionary ===
  // Page vi of dictionary: tone examples confirm these words exist

  // yə = he (p.8 orthography), yǐə = come (p.8 orthography)
  // ko = take (p.8 orthography), kǒ = snore (p.8 orthography)
  // mǎ = mother (p.9 orthography noun class table)


  // Auto-extracted from Bible NT (non-biblical-feeling)
  // JHN.10.30
  AwingPhrase(awing: 'Pəg Tǎ lə́ táʼə.”', english: 'I and the Father are one.”'),
  // 1TH.5.16
  AwingPhrase(awing: 'Tə́ nə́ ńkɔŋtə̂ əghâ ətsəmə,', english: 'Rejoice always.'),
  // 1TH.5.22
  AwingPhrase(awing: 'Lə́ʼ nə́ ndzaŋ təpɔŋ ntsəmə.', english: 'Abstain from every form of evil.'),
  // JHN.6.48
  AwingPhrase(awing: 'Maŋ lə́ apéenə məkálə́ nchîmbîə.', english: 'I am the bread of life.'),
  // 1CO.1.19
  AwingPhrase(awing: 'ə́sɛdkə̂ ajíənuə ngaŋə́ŋwaʼlə a pə́ ənukə́taŋə.”', english: 'For it is written,\n“I will destroy the wisdom of the wise,\nI will bring the discernment of the discerning to nothing.”'),
  // 1CO.15.55
  AwingPhrase(awing: 'Nəwû, ə́sɛ̂n gho ə́fó?” 15.55Osya 13.14', english: '“Death, where is your sting?\nHades, where is your victory?”'),
  // 1CO.16.14
  AwingPhrase(awing: 'Faʼ nə́ afaʼə atsəm nə́ akɔŋnə.', english: 'Let all that you do be done in love.'),
  // MAT.5.4
  AwingPhrase(awing: 'Mbɔŋə́ yə pɨ pö kyéŋ nə́,', english: 'Blessed are those who mourn,\nfor they shall be comforted.'),
  // MRK.15.13
  AwingPhrase(awing: 'Pó tɔ́ŋnə ə́sóŋ ńgə́, “Kwumtə̂ yə́!”', english: 'They cried out again, “Crucify him!”'),
  // 1CO.4.16
  AwingPhrase(awing: 'Ńdaŋ ə́lɨ́d, zoŋ nə́ ntag məkoolə mə.', english: 'I beg you therefore, be imitators of me.'),
  // ACT.14.7
  AwingPhrase(awing: 'ńtíʼə ńnáŋkə nkɨ yi əshîʼnə wə́ ə́wə́.', english: 'There they preached the Good News.'),
  // EPH.5.30
  AwingPhrase(awing: 'ńté ńgə́ pɛn lə́ əlam mbɨ píə.', english: 'because we are members of his body, of his flesh and bones.'),
  // JHN.6.4
  AwingPhrase(awing: 'Akɔŋtə ndzáʼkə Pəjusə a kə tə́ ḿbáatə.', english: 'Now the Passover, the feast of the Jews, was at hand.'),
  // JHN.12.15
  AwingPhrase(awing: 'Jɨ́ nə́, əfo əwəənə́ a tə́ ńgyǐəə,', english: '“Don’t be afraid, daughter of Zion. Behold, your King comes, sitting on a donkey’s colt.”'),
  // LUK.1.40
  AwingPhrase(awing: 'ńtíʼ ńkwúnə á ndɛ̂ Zakalya ńchaʼtə̂ Elisabɛlə.', english: 'and entered into the house of Zacharias and greeted Elizabeth.'),
  // LUK.20.30
  AwingPhrase(awing: 'Azoŋə yə́ a lɔgə̂ nkog əyǐ wə́,', english: 'The second took her as wife, and he died childless.'),
  // LUK.23.24
  AwingPhrase(awing: 'Payilɛlə a kwéʼnə ḿbí ńdzoŋ ndzəm əzoobə́.', english: 'Pilate decreed that what they asked for should be done.'),
  // LUK.24.43
  AwingPhrase(awing: 'a kwá ńkɔ́d tsɔʼə á mbi pó.', english: 'He took them, and ate in front of them.'),
  // MAT.2.18
  AwingPhrase(awing: 'Pə́ tə́ ńdzóʼ ngye yitsə̌ á Lama,', english: '“A voice was heard in Ramah,\nlamentation, weeping and great mourning,\nRachel weeping for her children;\nshe wouldn’t be comforted,\nbecause they are no more.”'),
  // MAT.4.20
  AwingPhrase(awing: 'Pó tɔ́g ḿmɛdtə̂ məŋkɛd mɔ́b ńdzoŋə̂ yə́.', english: 'They immediately left their nets and followed him.'),
  // MAT.22.38
  AwingPhrase(awing: 'Lɛ̌ ntsɛɛmbi ntəgə́ ńkə́ ḿbə́ yi ngweŋə́.', english: 'This is the first and great commandment.'),
  // MRK.4.14
  AwingPhrase(awing: 'Mbipú wə̂ a pǐ lə́ atséebə Əsê.', english: 'The farmer sows the word.'),
  // MRK.6.42
  AwingPhrase(awing: 'Ŋwu ntsəmə a nə ńjî tə ńdzɛ́lə.', english: 'They all ate, and were filled.'),
  // 1JN.5.21
  AwingPhrase(awing: 'Póonə mə, lə́ʼ nə́ wɨ́ məsê mə́ məfɨgə.', english: 'Little children, keep yourselves from idols.'),
  // ACT.19.7
  AwingPhrase(awing: 'Pó pətsəm kə pə́ lə́ ándó ntsɔb pɛ̌.', english: 'They were about twelve men in all.'),
  // ACT.19.41
  AwingPhrase(awing: 'A sóŋ ə́lɨ́d lə́, ńtíʼ ə́shamkə̂ nkyeetə zə̂.', english: 'When he had thus spoken, he dismissed the assembly.'),
  // HEB.1.12
  AwingPhrase(awing: 'Pɨ yǒ píʼtə pə́ələ́ ándó tə́sɛ atsəʼə́ əfə́gə,', english: 'You will roll them up like a mantle,\nand they will be changed;\nbut you are the same.\nYour years will not fail.”'),
  // HEB.2.12
  AwingPhrase(awing: 'maŋ yǐ ŋáŋkə gho á mə́m nkyeetə əzoobə́.”', english: 'saying,\n“I will declare your name to my brothers.\nAmong of the congregation I will sing your praise.”'),
  // HEB.10.37
  AwingPhrase(awing: '“Lə́ tsɔʼə mɔ́ akəmtə ndɛlə́ á pɛ́d nə́,', english: '“In a very little while,\nhe who comes will come, and will not wait.'),
  // JHN.12.40
  AwingPhrase(awing: 'ńtíʼ ńgyǐəə á mbô maŋ, maŋ tsóʼə ághóobə́.”', english: '“He has blinded their eyes and he hardened their heart,\nlest they should see with their eyes,\nand perceive with their heart,\nand would turn,\nand I would heal them.”'),
];

// ============================================================
// TONE MINIMAL PAIRS — words that differ only by tone
// ============================================================

class ToneMinimalPair {
  final String word1;
  final String english1;
  final String tone1;
  final String word2;
  final String english2;
  final String tone2;
  final String? word3;
  final String? english3;
  final String? tone3;

  const ToneMinimalPair({
    required this.word1,
    required this.english1,
    required this.tone1,
    required this.word2,
    required this.english2,
    required this.tone2,
    this.word3,
    this.english3,
    this.tone3,
  });
}

const List<ToneMinimalPair> toneMinimalPairs = [
  // From AwingOrthography2005.pdf page 8
  ToneMinimalPair(
    word1: 'kóŋɔ́', english1: 'ditch', tone1: 'high',
    word2: 'kɔ́ŋə', english2: 'flow', tone2: 'mid',
    word3: 'kɔ̀ŋə', english3: 'owl', tone3: 'low',
  ),
  ToneMinimalPair(
    word1: 'kô', english1: 'take', tone1: 'falling',
    word2: 'kó', english2: 'snore', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'àfɔ́gə̂', english1: 'blind person', tone1: 'high',
    word2: 'àfɔ́gə', english2: 'malaria', tone2: 'mid',
  ),
  ToneMinimalPair(
    word1: 'àlɔ́mə̂', english1: 'pool', tone1: 'high-final',
    word2: 'àlɔ́mə', english2: 'cloud', tone2: 'mid-final',
  ),
  ToneMinimalPair(
    word1: 'àkōolə̂', english1: 'latrine', tone1: 'high-final',
    word2: 'akōolə', english2: 'leg', tone2: 'mid-final',
  ),
  // From phonology PDF page 23
  ToneMinimalPair(
    word1: 'pìə', english1: 'give birth', tone1: 'low',
    word2: 'pìə̂', english2: 'sow (plant)', tone2: 'falling',
  ),
  // New minimal pairs from phonology PDF
  ToneMinimalPair(
    word1: 'ndě', english1: 'neck', tone1: 'mid',
    word2: 'ndè', english2: 'water', tone2: 'low',
  ),
  ToneMinimalPair(
    word1: 'lê', english1: 'sleep', tone1: 'falling',
    word2: 'lé', english2: 'eat (alternate)', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'nô', english1: 'drink', tone1: 'falling',
    word2: 'nó', english2: 'give', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'fê', english1: 'give', tone1: 'falling',
    word2: 'fé', english2: 'blow', tone2: 'high',
  ),
  // REMOVED tone minimal pair kíə/kìə (pay/key) — per dictionary, kíə (high) and
  // kìə (low) do not exist. "Pay (for goods)" = tûə (falling). "Key (from English)"
  // = kîə (falling). Same tone, different segments — not a tone minimal pair. (Session 52)
  // REMOVED tone minimal pair nkîə/nkíə (river/song) — per dictionary, both meanings (water/river AND song) are HOMONYMS using the SAME rising-tone word nkǐə. They are not a tone minimal pair. (User-flagged Session 52)
];

// ============================================================
// NOUN CLASSES — singular/plural patterns
// ============================================================

class NounClass {
  final int classNumber;
  final String singularExample;
  final String pluralExample;
  final String english;
  final String? prefix;

  const NounClass({
    required this.classNumber,
    required this.singularExample,
    required this.pluralExample,
    required this.english,
    this.prefix,
  });
}

const List<NounClass> nounClasses = [
  NounClass(classNumber: 1, singularExample: 'mǎ', pluralExample: 'pəmǎ', english: 'mother/mothers', prefix: 'Ø/pə-'),
  NounClass(classNumber: 3, singularExample: 'əkwunɔ́', pluralExample: 'məkwunɔ́', english: 'bed/beds', prefix: 'ə-/mə-'),
  NounClass(classNumber: 5, singularExample: 'nəkəŋɔ́', pluralExample: 'məkəŋɔ́', english: 'pot/pots', prefix: 'nə-/mə-'),
  NounClass(classNumber: 7, singularExample: "alá'ə", pluralExample: "əlá'ə", english: 'village/villages', prefix: 'a-/ə-'),
  NounClass(classNumber: 9, singularExample: 'nduə', pluralExample: 'mənduə', english: 'hammer/hammers', prefix: 'N-/mə-'),
  NounClass(classNumber: 1, singularExample: 'apeemə', pluralExample: 'əpeemə', english: 'bag/bags', prefix: 'a-/ə-'),
  NounClass(classNumber: 5, singularExample: 'ndě', pluralExample: 'məndě', english: 'neck/necks', prefix: 'N-/mə-'),
  NounClass(classNumber: 5, singularExample: 'ntsoolə', pluralExample: 'məntsoolə', english: 'war/wars', prefix: 'N-/mə-'),
  // New noun classes from phonology PDF (van den Berg 2009)
  NounClass(classNumber: 3, singularExample: 'əfɔ̀nə', pluralExample: 'pəfɔ̀nə', english: 'teacher/teachers', prefix: 'ə-/pə-'),
  NounClass(classNumber: 7, singularExample: 'atîə', pluralExample: 'ətîə', english: 'tree/trees', prefix: 'a-/ə-'),
  NounClass(classNumber: 9, singularExample: 'ngwûə', pluralExample: 'məngwûə', english: 'dog/dogs', prefix: 'N-/mə-'),
  NounClass(classNumber: 1, singularExample: 'tǎ', pluralExample: 'pətǎ', english: 'father/fathers', prefix: 'Ø/pə-'),
  NounClass(classNumber: 5, singularExample: 'nkelɔ́', pluralExample: 'mənkelɔ́', english: 'rope/ropes', prefix: 'N-/mə-'),
  NounClass(classNumber: 7, singularExample: 'akoolə', pluralExample: 'əkoolə', english: 'leg/legs', prefix: 'a-/ə-'),
  NounClass(classNumber: 3, singularExample: 'əkwunɔ́', pluralExample: 'məkwunɔ́', english: 'bed/beds (alt)', prefix: 'ə-/mə-'),
];


// ============================================================
// DICTIONARY ENTRIES — extracted from Awing English Dictionary
// (Alomofor Christian, CABTAL, 2007) via Claude vision PDF read
// Total: 2494 additional entries
// ============================================================
const List<AwingWord> dictionaryEntries = [
  // body (121)
  AwingWord(awing: 'achí yə əshi\'nə', english: 'good sign when blood twitches near the eye', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achiə təpəŋə', english: 'bad sign when blood twitches', category: 'body', difficulty: 2),
  AwingWord(awing: 'achwinə', english: 'act of provocation by twitching fingers at each other', category: 'body', difficulty: 2),
  AwingWord(awing: 'afeelókwú\'ó', english: 'small of the back', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə azánə', english: 'leaf of palm, palm needle', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəŋə', english: 'lip; edge of a hollow vessel', category: 'body', difficulty: 2),
  AwingWord(awing: 'aghəŋə ntsoolə', english: 'fat lip', category: 'body', difficulty: 2),
  AwingWord(awing: 'akəghoolámiə', english: 'nape of neck', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akə\'lə', english: 'triangular hedge on pig\'s neck to constrain it', category: 'body', difficulty: 2),
  AwingWord(awing: 'akwəŋó', english: 'bone', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwəŋó əshûə', english: 'fish bone', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwə\'tó', english: 'knee', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləəbó', english: 'growth on the neck', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləəbənófâŋə', english: 'growth in the armpit as sign of wound', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aləəmə', english: 'tongue', category: 'body', difficulty: 2),
  AwingWord(awing: 'alógántəəmə', english: 'heart break', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alə\'tó', english: 'chin', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alu\'ə', english: 'hip', category: 'body', difficulty: 2),
  AwingWord(awing: 'ambêmálo\'ə', english: 'palm rat', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'amiə', english: 'neck', category: 'body', difficulty: 2),
  AwingWord(awing: 'aŋkəələngwúə', english: 'finger-like potatoe used as medicine (genson)', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apô yə kwaabə', english: 'left hand; left direction', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apô yə təənə', english: 'right hand; right direction', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aselə', english: 'sore throat. Sore throat attacks the throat', category: 'body', difficulty: 2),
  AwingWord(awing: 'atéelə akoolə', english: 'foot. The foot is the part that we put on the ground', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atéelə apô', english: 'palm of hand', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atenə', english: 'abdomen; buttock', category: 'body', difficulty: 2),
  AwingWord(awing: 'atɨə kokonólə', english: 'coconut palm. There is no coconut tree in Awing', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə maghólə', english: 'oil palm. Oil palms are palms that produce palm nuts', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə nətəənə', english: 'palm tree. A palm tree produces red oil', category: 'body', difficulty: 2),
  AwingWord(awing: 'atogá', english: 'A certain substance in a witch\'s stomach that influences him/her to kill in order to gratify it', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atóŋnəntsoolə', english: 'long mouth (used as insult)', category: 'body', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'atoŋə', english: 'pointed mouth of a bottle or calabash', category: 'body', difficulty: 2),
  AwingWord(awing: 'atúəmbe\'tə', english: 'shoulder blade. An Awing man usually carries his load on his shoulders', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ámbəəmə', english: 'muscle. He whose flesh is resistant lives longer', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsêeblá\'ə', english: 'mother tongue, local language', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atséebántsoolə', english: 'communication by mouth', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsê', english: 'one palm leave', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atso\'ámásəŋə', english: 'tooth stick, toothbrush', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋə', english: 'palm branch', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azelándé', english: 'fold skin of neck, especially in fleshy people', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'âz', english: 'of the eyes, bear a white substance especially early in the morning from bed', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'châ\'lə', english: 'A sort of white substance from the eye that comes out usually after sleep', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó əlimá', english: 'Have many blood relations who are caring', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwá\'tə', english: 'shave one\'s hair improperly', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwí mbó', english: 'twitch fingers as a sign of agreement to contest a fight', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ fiə apô', english: 'ring of finger', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfeŋ nəlwîə', english: 'nose ring', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfeŋə akoolə', english: 'ankle ring, bangle', category: 'body', difficulty: 2),
  AwingWord(awing: 'ələələ', english: 'bamboo-skin (often fresh) used as rope', category: 'body', difficulty: 2),
  AwingWord(awing: 'əŋaŋ nələŋə', english: 'tendon', category: 'body', difficulty: 2),
  AwingWord(awing: 'əŋaŋə́', english: 'vein; root', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsâŋngyénə', english: 'rib', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əshwignə́', english: 'a sort of thread produced from raffia palm stumps', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fá', english: 'cross through thick grass or fast running water on foot', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'féekə', english: 'expose teeth especially in laughter (colloquial)', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmá', english: 'deep one\'s hands, head, feet etc into sth eg water', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fîə akoolə', english: 'toe', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fîə apô', english: 'finger', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fid nəlwîə', english: 'blow nose', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fú məlo\'ə', english: 'palm wine. There is much palm wine in Awing village', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fú nənoŋə', english: 'grey hair. Grey hair is an indication that one is aging', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghaŋə', english: 'chest', category: 'body', difficulty: 2),
  AwingWord(awing: 'ghəəbə̂', english: 'crunch soft bone (as a dog)', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jubô', english: 'skin (animal), strip off (bark), peel', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwumə', english: 'nail; roof', category: 'body', difficulty: 2),
  AwingWord(awing: 'kwumtô', english: 'nail', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'lěe', english: 'look at somebody\'s food with a watery mouth (lust for anything)', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbe\'ta', english: 'shoulder', category: 'body'),
  AwingWord(awing: 'mbó\'nəsága', english: 'buttock', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'mbi\'ə', english: 'kidney', category: 'body'),
  AwingWord(awing: 'məghód má paŋ nə̂', english: 'palm oil', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'məm nəpəmə', english: 'stomach (internal)', category: 'body', difficulty: 2),
  AwingWord(awing: 'máma apô', english: 'palm (of hand)', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'manoŋ má əli\' mbáata', english: 'pubic hair', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manoŋ má mbǎəmə', english: 'hair (of body)', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'manwáŋa', english: 'bone marrow', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'mimá', english: 'associative marker used for head nouns which are of class sixm meaning \'of\'', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó na mbeláló\'ə', english: 'calf', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəghabta', english: 'armpit', category: 'body'),
  AwingWord(awing: 'nəghagə', english: 'cheek, jaw', category: 'body'),
  AwingWord(awing: 'nəla\' nó akoolə', english: 'ankle', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəlágə', english: 'eye', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'nələŋə nó apô', english: 'hand limb', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəló\' nə́ nəlwíə', english: 'lip plug; lip disk', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənoŋ nó atûə', english: 'hair of head', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nənoŋə', english: 'hair', category: 'body'),
  AwingWord(awing: 'nəpəənə', english: 'breast', category: 'body'),
  AwingWord(awing: 'nətén nó akoolə', english: 'sole of foot', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətəənə', english: 'palm nut', category: 'body'),
  AwingWord(awing: 'nətə\'ə', english: 'thigh', category: 'body'),
  AwingWord(awing: 'nətôglə', english: 'ear', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'nətoŋə́', english: 'navel', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'nətsóŋ nó akoolə', english: 'heel', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətsóŋ nó atûə', english: 'lock of hair', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəzeŋnə́', english: 'forehead', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'ngəd nəlágə́', english: 'eyebrow', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwub mbəəmə', english: 'skin (of man)', category: 'body', difficulty: 2),
  AwingWord(awing: 'ngwub nəlágə', english: 'eyelid', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkənə apô', english: 'elbow', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkyeelá', english: 'raffia palm', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'nkyǐmégə', english: 'tears', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ntéəmə', english: 'heart', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'ntəmə akoolə', english: 'calf of leg', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntso', english: 'date palm', category: 'body'),
  AwingWord(awing: 'ntso nkyílə', english: 'head of arrow', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyíŋkə', english: 'express excitement by laughing and exposing one\'s teeth; be excited', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwaŋkô móga', english: 'blink eyes', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pe\'ə atûə', english: 'carry on head', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'péŋə achíə', english: 'bleed or lose blood. Heavy work makes people lose blood', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pipá', english: 'associative marker used for head nouns of class 2, meaning \'of\'', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'poolá', english: 'breast wear', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'pwə\'ə', english: 'spit in an unpleasant manner', category: 'body', difficulty: 2),
  AwingWord(awing: 'seelô', english: 'tear (tr)', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'səbnô', english: 'be worry; be depressed', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shágə', english: 'steal palm wine from another person\'s palm bush', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tôgndě', english: 'throat', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'twîəə', english: 'spit', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\'óto\'ə', english: 'very sweet palm wine', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'waglə', english: 'hold loosely of a tied rope round something eg round a cow\'s neck', category: 'body', difficulty: 2),
  AwingWord(awing: 'yinə̌', english: 'associative marker used for head nouns which are of class 5', category: 'body', tonePattern: 'rising', difficulty: 2),

  // family (100)
  AwingWord(awing: 'achíkə ŋwunə', english: 'old person irresponsive to bodily emotions', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'adochenə', english: 'school children\'s game played with a small ball', category: 'family', difficulty: 2),
  AwingWord(awing: 'afəmólá\'ə', english: 'land where forefathers settled within the Awing clan; quarter name', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajiəmógó', english: 'all-knowing person, proud and boastful person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmóntsoolə', english: 'greedy person, powerful person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəghə', english: 'stupid person, imbecile; stupidity', category: 'family', difficulty: 2),
  AwingWord(awing: 'akəmótógiə', english: 'deaf person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'akǒ\'nə məŋgyě', english: 'young woman', category: 'family', tonePattern: 'rising'),
  AwingWord(awing: 'akwu\'ó', english: 'travelling people (mystical, cause floods in enemy villages)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aloonətəjiə', english: 'person, discontented though rich', category: 'family', difficulty: 2),
  AwingWord(awing: 'anəələmóonə', english: 'child dedication, usually takes place in church a few months (two to three months) after birth', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apo\'ə', english: 'slave', category: 'family', difficulty: 2),
  AwingWord(awing: 'asoŋə', english: 'mystical power used by one to enrich himself by dragging away another person\'s wealth', category: 'family', difficulty: 2),
  AwingWord(awing: 'atágətatsə\'ə', english: 'stiff and unrelenting person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atássəəmə', english: 'A person who is wild and animal in nature. If you see a wild man, you should hide', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúmnə', english: 'the habit of giving too many assignments or laying too much burden on other people', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə mbó nakaŋá', english: 'potter\'s clay. The potters clay is usually found near the stream', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánkwûə', english: 'will of a dead person', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azoŋ yə mbyâŋnə', english: 'younger brother', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azoŋ yə məŋgyě', english: 'younger sister', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'azəbtə', english: 'a special signal that is understood only by an in-house or a specific person', category: 'family', difficulty: 2),
  AwingWord(awing: 'chigə ngəənə', english: 'good or true friend', category: 'family', difficulty: 2),
  AwingWord(awing: 'chigəngaŋnkéebə', english: 'billionaire; very rich man', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'dógto', english: 'doctor', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ ngɔŋə', english: 'ruler\'s bangle, especially that worn by fons', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfəgə', english: 'blind person', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfəgmógə', english: 'blind person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəmə', english: 'poor person', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfi əpúmə', english: 'seller or somebody who sells', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfi neemə', english: 'butcher', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfinə', english: 'seller or somebody who sells', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfo nəfeŋə', english: 'a very inhygenic person (in exaggerated proportions)', category: 'family', difficulty: 2),
  AwingWord(awing: 'əkə̂mátôglə', english: 'deaf person', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ələəmə', english: 'witch, the practices of a witch', category: 'family', difficulty: 2),
  AwingWord(awing: 'əlimə́', english: 'relationship by family', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əma\'ngwulə', english: 'ancestor', category: 'family'),
  AwingWord(awing: 'ənyi ntúmə', english: 'messenger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fálisîə', english: 'High Priest', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kaghog ŋwunə', english: 'man of integrity, important man', category: 'family', difficulty: 2),
  AwingWord(awing: 'mbá\' əpúmə', english: 'weaver, somebody who weaves', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbô', english: 'people of', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'mbǎəmə apóəmə', english: 'hunter', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbógə atúə', english: 'unlucky person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mbâkâ', english: 'which people, people of where, people of what (a sort of phrasal expression)', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbóŋə', english: 'poor man, needy', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbó məkəŋə', english: 'potter', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé nəlóga', english: 'pupil (of eye)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məko mó əfo', english: 'fon\'s messenger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mámé', english: 'grandmother (maternal)', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mangyè natûa', english: 'principal wife, first wife', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mápéenə', english: 'mother-in-law to the bride', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'móona', english: 'child', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mó mbyâŋnə', english: 'son, little boy; boy', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó má yi mbyâŋnə', english: 'grandson', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó má yi mangyè', english: 'granddaughter', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó nkə', english: 'child', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Mó Ŋwunə', english: 'Son of Man', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó yi mbóolə', english: 'baby', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó yi mangyè', english: 'daughter, girl child', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nden mangyè', english: 'old woman', category: 'family', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nden ŋwunə', english: 'old man', category: 'family', difficulty: 2),
  AwingWord(awing: 'ndəəmə', english: 'female witch', category: 'family'),
  AwingWord(awing: 'ndí\' məjíə', english: 'farmer', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndim mǎ yi mbyâŋnə', english: 'mother\'s brother (uncle)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim mǎ yi məngyè', english: 'mother\'s sister (aunt)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim tǎ yi mbyâŋnə', english: 'father\'s brother (uncle)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim tǎ yi məngyè', english: 'father\'s sister (aunt)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndimá', english: 'nephew; niece', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndɔ́ŋə', english: 'lazy person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'ndzɔ̂lə', english: 'thief', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'ndzoŋndzəm Yésə', english: 'disciple of Jesus, Jesus\' follower', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzoŋndzəmə', english: 'disciple, follower', category: 'family'),
  AwingWord(awing: 'nətə nó məkəŋə', english: 'potter\'s kiln', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋndzəmə', english: 'disciple, follower', category: 'family'),
  AwingWord(awing: 'ngaŋnaghéenə', english: 'guest, visitor; stranger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋtsábpê', english: 'deceitful person', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'ngəmə́', english: 'mother-in-law to the husband or groom; mother-in-law, daughter-in-law', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwad neemə', english: 'butcher', category: 'family', difficulty: 2),
  AwingWord(awing: 'ngwam əshúə', english: 'fisherman', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'ngwulə', english: 'clan, family; descendant', category: 'family', difficulty: 2),
  AwingWord(awing: 'nkwiŋə', english: 'unmarried person', category: 'family'),
  AwingWord(awing: 'nkwû əsê', english: 'spirit of a dead person (invisible)', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntáŋ məteenə́', english: 'trader', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntúmə', english: 'messenger', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'ntwîə aleemə', english: 'blacksmith', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntse mbi yi mbyâŋnə', english: 'elder brother', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntse mbi yi məngyè', english: 'elder sister', category: 'family', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ntse mbiə', english: 'elder', category: 'family'),
  AwingWord(awing: 'ŋwu Əsê', english: 'priest; pastor', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwu Əsê yi ngwiŋə́', english: 'Chief Priest; High Priest', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwu yi ńdéeləŋ nó', english: 'senile person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwunə achánə', english: 'person who turns away from others in disgust', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tă', english: 'father; parent', category: 'family', difficulty: 2),
  AwingWord(awing: 'tădmé', english: 'grandfather (maternal)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tădmé yi ndza\'kə', english: 'great grandfather (maternal)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'táko\' ŋwunə', english: 'adult', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təlénja', english: 'stranger. From: English', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təwélakámə', english: 'A sharp flute used for rallying people for emergenncies (example war, serious development projects etc)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tóondzəmə', english: 'somebody who plays a limited role in another person\'s struggles; supporter, ally', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twá nəpəmə', english: 'conceive a child, become pregnant', category: 'family', tonePattern: 'high', difficulty: 2),

  // animals (57)
  AwingWord(awing: 'atəənə akóolə əshûə', english: 'fish trap. Afish trap is found where there is water', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jwî\'lə', english: 'a sort of fly that frequents rotting things', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kaŋə', english: 'wild cat that preys on fowls', category: 'animals', difficulty: 2),
  AwingWord(awing: 'kéenó', english: 'crab', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'kíchíə', english: 'cricket (insect that thrives in dry season)', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kífəmə', english: 'a kind of big bee that lives in dry wood', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíza\'', english: 'grasshopper (delicious food for some tribes)', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó əshûə', english: 'fish in Awing lake (word that people should not fish in Awing lake)', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'konə', english: 'owl, a bird with deep eyes that cries in the night (associated with bad omens)', category: 'animals', difficulty: 2),
  AwingWord(awing: 'kwíŋ nkǐə', english: 'turtle (water turtle)', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'kwúneemə afoonə', english: 'warthog', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləəmó', english: 'horse. Only fulanis have horses in Awing', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lóolá', english: 'toad', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'mbéŋ ndzelə', english: 'sheep', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbeŋə', english: 'cockroach', category: 'animals'),
  AwingWord(awing: 'mbi təŋkə̂\'ə', english: 'elephant\'s trunk', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé sáŋə́', english: 'ostrich', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məlámchú\'ə́', english: 'sort of bee that produces a stench or smell; something that smells excessively', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məŋwédnúə', english: 'bee', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'máwúmə́', english: 'hawk', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'mó fóolə́', english: 'mouse', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mbéŋ ndzelə', english: 'lamb', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mbéŋə', english: 'little goat', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó ngwûə', english: 'puppy', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó púshîa', english: 'kitten', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'na nkîa', english: 'rhinoceros', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndi sáŋə́', english: 'vulture', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndoŋə', english: 'duck', category: 'animals'),
  AwingWord(awing: 'ndú kwúneemə', english: 'boar', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndú ləəmə́', english: 'stallion', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndú neemə', english: 'bull', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzâblə', english: 'cane rat, cutting grass, grass cutter', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndzâblə məsá\'ə', english: 'porcupine', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'néelə', english: 'buffalo', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'nəlélə', english: 'army ant, soldier ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəmaŋnə', english: 'wild cat', category: 'animals'),
  AwingWord(awing: 'nənjwínə', english: 'fly', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'nənyaglə', english: 'earthworm', category: 'animals'),
  AwingWord(awing: 'nəsoŋ nó tə̂ŋka\'ə', english: 'elephant\'s tusk', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəwelá', english: 'a sort of small bird, known to be very unstable and as jumpy as a flee', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngábə', english: 'chicken, fowl', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'ngwě kwúneemə', english: 'sow', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě ləəmə́', english: 'mare (horse)', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě mbéŋ ndzelə', english: 'ewe', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě mbéŋə', english: 'she-goat; nanny goat', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě neemə', english: 'cow', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwumnə́', english: 'locust', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'nka kíleləŋkaŋə́', english: 'spider\'s web', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkǐ əshúə', english: 'fish dam', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ntaŋ ngɔ\'ə́', english: 'hut built for collecting termite', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'samba', english: 'men dance group led by an elephant-like masked person. It is animated with xylophones', category: 'animals', difficulty: 2),
  AwingWord(awing: 'téembogla', english: 'a very big snake. From: English', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təŋka\'ə', english: 'elephant', category: 'animals', difficulty: 2),
  AwingWord(awing: 'tásélaséla', english: 'ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tásélaséla yi ndzag nə', english: 'flying ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tətseemə', english: 'frog', category: 'animals', difficulty: 2),
  AwingWord(awing: 'to\'lə', english: 'squirrel', category: 'animals', difficulty: 2),

  // nature (160)
  AwingWord(awing: 'achi\'lə', english: 'turf of grass', category: 'nature', difficulty: 2),
  AwingWord(awing: 'afédngónə', english: 'third day of the week and minor market day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə əghəmə', english: 'fig leaf used for communication; message from the fon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə nəkənə', english: 'wild grass that grows in the farm', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwigó', english: 'a day', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'ajwigó ngwe\'ó', english: 'day after tomorrow', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəblá ndəsê', english: 'clod of earth', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akəpógló', english: 'dust', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoobá', english: 'forest, bush', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoobá afəgó', english: 'indian bamboo bush', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akô\'ka', english: 'hill', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwu\'ló atìə', english: 'base of tree trunk; stump', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə akoobá', english: 'bush country, rural area', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó', english: 'path; road; destiny', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó akəpógló', english: 'dusty road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó maŋgo\'ə', english: 'bumpy road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó nətsa\'ó', english: 'muddy road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋómakálá', english: 'motorable road; paved road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alě mbîə senô', english: 'this day, today', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě məteenə', english: 'market day', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alélá\'ə', english: 'resting day, mostly used for ceremonies', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alěmbîə', english: 'day', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aləəmómógó', english: 'flame of fire', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleme', english: 'first day of the week', category: 'nature', difficulty: 2),
  AwingWord(awing: 'alemó', english: 'deep pool of water', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóma', english: 'cloud, fog', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alí\'ə', english: 'cultivated ground', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alimkə', english: 'horizontal or level road', category: 'nature', difficulty: 2),
  AwingWord(awing: 'alúmə', english: 'a red medicinal plant', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ambuə', english: 'medicinal plant that produces a sticky substance used as gum', category: 'nature', difficulty: 2),
  AwingWord(awing: 'antwə̌\'lə', english: 'little irish-like nuts from the ground, eaten as food', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aŋa\'ə', english: 'sort of tree like a fig, having large leaves', category: 'nature', difficulty: 2),
  AwingWord(awing: 'aŋkálə', english: 'large ridges that are formed by burning soil and vegetation', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apômbə\'ə', english: 'the fifth day of the week', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atəsoŋə', english: 'elephant grass', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atatsá\'ó', english: 'mud', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə akwamnə', english: 'plum tree. A plum tree produces plum', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə apoŋwiŋə', english: 'A kind of soft tree used for making xylophones', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə awaglápanêmə', english: 'a boundary stick which its leaves are used for making a public announcement', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atɨə azoomə', english: 'a plum tree', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə chaŋnə', english: 'ink tree. The ink tree grows on the hill (pasture land)', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə əghəmə', english: 'a fig tree. A fig tree is a tree god in some places', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə əleelə', english: 'A huge and hard tree used for making bridges', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə fóŋáfóŋá', english: 'A sort of smooth tree used for sawing plank. A plank tree is used for sawing plank', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə məsəbtə', english: 'tree that develops thorns. Nobody likes climbing a thorn tree', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə nəpíə', english: 'cola nut tree. A cola nut tree bears colanuts', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə nəpiəmbéŋə', english: 'quiny tree. A quiny tree is a peaceful tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'ə', english: 'raffia bush', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atúmə məyeŋá', english: 'bush dweller, fulanis (used derogatorily). Some Awing people call a bororo man, bush dweller', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə ndəsê', english: 'mud block. We use mud blocks to build houses in Awing', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azéenə', english: 'playground; palace assembly ground', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chîə mbi ndě', english: 'stay awake late into the night', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chigə məsanə', english: 'early morning', category: 'nature', difficulty: 2),
  AwingWord(awing: 'chigə náŋə', english: 'scrutinise; examine well', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chúbə', english: 'remove something in a very fast way, usually from danger or by means of forceful seizure', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáanə', english: 'cut in a crude or inhuman way', category: 'nature', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwaglə', english: 'bath oneself or wash something in an improper way', category: 'nature', difficulty: 2),
  AwingWord(awing: 'chwí\'ə', english: 'plant (cocoyams)', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'chwí\'tô', english: 'plant (cocoyams) a little', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfagə atíə', english: 'branch (of tree)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfab nɔ́lə\'ə́', english: 'plant disease that attacks sweet yams, boring holes in them', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfabâ', english: 'plant disease that attacks cocoyams', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfabátíə', english: 'plant disease that attacks trees, boring holes in it', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfo atíə', english: 'baobab tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfó\' nkǐə', english: 'dry river bed', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əfooghaəmá', english: 'lake Awing (only lake Awing is called by this name)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əghâ', english: 'season; time', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ alumə', english: 'dry season', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ magheemá', english: 'rainy season', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əlě', english: 'a rough-stemmed tree that grows in grassland areas', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əleemá', english: 'bird droplets that grow into tree branches on any tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əleglə', english: 'bridge', category: 'nature', difficulty: 2),
  AwingWord(awing: 'óláəló', english: 'yes; any thing kept by a tree god remains the same until the owner comes for it', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ənumnə natú\'ə', english: 'eclipse of the moon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əshwáŋ neemə', english: 'path of a wild animal', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwaglápanə̂mə', english: 'a boundary stick which its leaves are used for making a public announcement (a special kind that grows only in Baminyam)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əzooná yîə', english: 'day before yesterday', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féŋtə', english: 'get well, recover from illness', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəláwa', english: 'flower (Whites like planting flowers in their compounds)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmtəfəmtə', english: 'word that describes the movement of somebody who is not seeing his path, also of somebody who moves as if he is not seeing', category: 'nature', difficulty: 3),
  AwingWord(awing: 'fláwa', english: 'flower', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'foŋə̂', english: 'to flourish with fresh leaves and flower (of plants). When it rains, crops flourish in the farm', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fugə', english: 'a kind of bag used to carry products from the farm', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ghóŋə', english: 'farm bed', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghóŋə aneemə', english: 'farm bed (animal-related)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwígə', english: 'pass or a day; spend a day, make a day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwí\'kə á ndî\' mógə', english: 'smoke, dry in smoke, dry over fire', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kǎa', english: 'clean of farm beds roughly', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'kəfəələ', english: 'storm or wind; vent', category: 'nature', difficulty: 2),
  AwingWord(awing: 'kwáŋta', english: 'clean the furrows of a farm bed a little (using a hoe)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwedtâ', english: 'pour out a little of something on the ground or in a container', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwelô', english: 'pour something on ground or container (solid or liquid)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mba\' mbaŋə', english: 'rain maker or somebody who makes rain not to fall with the use of magical powers', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mba\'ə', english: 'rain maker or somebody who makes rain not to fall with the use of magical powers', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbeelə', english: 'furrow between farm beds', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbe\'nó', english: 'the eighth day of the week', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbɛ', english: 'name used only for the fon or village chief', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbǎəmə atîə', english: 'bark of tree', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbiə', english: 'seed', category: 'nature'),
  AwingWord(awing: 'mé ngo\' naghǒ', english: 'lower grinding stone', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'məgha\'tə má nkwəənə', english: 'vast and dry valley', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'móláglə', english: 'shadow', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'mánu yi ńté nó', english: 'sunshine', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mánuma', english: 'sun', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'məsâna', english: 'morning', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'məsobsoobə̂', english: 'thorn', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'móga', english: 'fire, burn', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'mó ngo\' naghǒ', english: 'upper grinding stone', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mó sáŋ ndúumbîa', english: 'morning-star (Venus)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó sáŋə', english: 'star', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nchwelə', english: 'the sixth day of the week', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nchwîa', english: 'the fourth day of the week; day of rest and also for carrying out traditional ceremonies', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndəsê yi əshí\'nə', english: 'fertile soil', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndúumbîə', english: 'the period early in the morning between 4 Am and 5 Am', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndzəmá', english: 'darkness', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'ndzəŋ mənumə', english: 'afternoon, moment or period at sun down. Come in the afternoon', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəfaŋə', english: 'thunder', category: 'nature'),
  AwingWord(awing: 'nəgho\'ə', english: 'manner of grinding something or style with which something is ground', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəkwumə́', english: 'a long kind of basket used for carrying farm products and firewood', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəŋkwâ\'lə', english: 'sand; little stones', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpeelə', english: 'boundary of field', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nətú\'ə', english: 'night', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'nətsóŋə', english: 'knot tied of any fibre product or plant, even of hair; lock e.g of hair', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəyeŋə́', english: 'grass', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'ngo\'ə', english: 'year', category: 'nature'),
  AwingWord(awing: 'ngɔ́\'ə', english: 'stone', category: 'nature', tonePattern: 'high'),
  // Session 52: was 'nkaŋ nkíə' — nkíə (high tone) does not exist. Per dict, water/river = nkǐə (rising).
  AwingWord(awing: 'nkaŋ nkǐə', english: 'river bank; sea shore', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkéebə', english: 'main market day in Awing; the seventh day of the week in Awing', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəŋə', english: 'Traditional peace plant, planted in places of worship and used in ceremonies of peace', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkǐ yi sá\' nó', english: 'spring', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkəlá', english: 'large bed of farm formed by putting soil on compost and burnt', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəŋ nelwîə', english: 'bridge (of nose)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkəŋ nó ngámə', english: 'rainbow', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkwaná', english: 'evening', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'nkweelə', english: 'the second day of the week and minor market day', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkya\' nəfaŋə́', english: 'lightning', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkya\' sáŋə́', english: 'moonlight', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkyakəpeŋə', english: 'dawn', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nô ndəpa\'ə', english: 'smoke tobacco', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntîtú\'ə', english: 'mid-night', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'ntínumnə', english: 'noon, mid-day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nwí\'ə', english: 'plant (of seeds) too close to each other', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwiŋə', english: 'tree god', category: 'nature'),
  AwingWord(awing: 'péŋə', english: 'be lost; someone missing in the forest', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pôb', english: 'sound that describes something snuffing out eg fire or breath', category: 'nature', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'póga', english: 'bark (as dog)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póokə', english: 'wither eg a plant', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pwəlô', english: 'put soil on ridges', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sáŋ yi fîə', english: 'new moon', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sáŋ yi ńdwénkə nó', english: 'full moon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáma', english: 'wind', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'shí\'nə', english: 'use one\'s labour in exchange for farm products', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shǔəə', english: 'break wind, fart', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tasa\' móga', english: 'spark of fire', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tú nkǐə', english: 'cross river', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'túmkə', english: 'make or help someone or something cross through a difficult place eg river', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wáako', english: 'sand', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəg ŋgênə', english: 'carry away by the force of wind', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wəg ńkwelə', english: 'pour down something using the force of wind', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yagə', english: 'scare away by shouting eg of animals or birds in a farm; yell out curses eg to a thief', category: 'nature', difficulty: 3),

  // food (89)
  AwingWord(awing: 'achiba', english: 'food or drinks given to console somebody (death)', category: 'food', difficulty: 2),
  AwingWord(awing: 'achibənáwûə', english: 'food or drinks given to a house of mourning', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'achú\'ə', english: 'cocoyams pounded and eaten with red soup, meat and vegetables', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə ŋgəsáŋə', english: 'corn husk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəfə', english: 'coffee', category: 'food', difficulty: 2),
  AwingWord(awing: 'akəghaŋə', english: 'okra', category: 'food', difficulty: 2),
  AwingWord(awing: 'akəká', english: 'ground corn fufu, softened with water and steamed', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoŋə ŋgəsáŋə', english: 'corn stalk, corn husk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwâ', english: 'pounded Irish potato and banana', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alífəámó', english: 'bat; fruit bat', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'á', english: 'banana', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'áchú\'ə', english: 'banana used for preparing achu', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'áfəŋə', english: 'banana not used as food but as medicinal plant', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'ámakálə', english: 'A kind of banana that is kept to ripe and is then eaten as food', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋgênə', english: 'A kind of elephant stalk that looks very much like sugar cane', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aŋkəələ', english: 'carrot-like food', category: 'food', difficulty: 2),
  AwingWord(awing: 'aŋkwúbə', english: 'a raffia fruit with a hard smooth surface', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apéenəməkálə', english: 'bread. Makala like bread, hot water and sugar in the morning', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apu\'ə məjiə', english: 'food leftovers. In Awing, food leftovers of an elder is eaten by a child', category: 'food', difficulty: 2),
  AwingWord(awing: 'aso\'ə', english: 'a carved piece of wood used for lifting achu from the motar', category: 'food', difficulty: 2),
  AwingWord(awing: 'atɨə apopó', english: 'a pawpaw tree', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'lóndé', english: 'adam\'s apple', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsá\'ə', english: 'the different divisions of a banana bunch', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atso\'ə', english: 'cob of corn. One can plant a cob of corn and it produces a bag full', category: 'food', difficulty: 2),
  AwingWord(awing: 'atso\'ə ngəsáŋə', english: 'corn cob. One can plant a cob of corn and it produces a bag full', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awa\'ə', english: 'a container for achu soup', category: 'food', difficulty: 2),
  AwingWord(awing: 'azó\'ə', english: 'yam', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'áŋwúná', english: 'A sort of yam attributed to men and usually harvested and kept in men\'s houses', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'íbo', english: 'A sort of yam that originated from Ibo land in Nigeria', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'básko', english: 'sort of short stemmed banana bearing a large stem', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bóyó', english: 'a sort of short stemmed banana bearing a large stem', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chî tə məjiə', english: 'be without food', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chib nəwûə', english: 'give food or drinks to a house of mourning', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ənɔ̌ púmə', english: 'food offered by relatives of the diseased during a dead celebration', category: 'food', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'gəlébə', english: 'grape', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gəlumáŋ', english: 'a sort of coffee branch usually cut and thrown for soaking all the water that the coffee stem needs', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghed məjîə', english: 'prepare food (mid-day meal)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jinə', english: 'exchange food, share in different aspects', category: 'food', difficulty: 2),
  AwingWord(awing: 'kagə̂', english: 'of a raffia fruit (clear its hard surface), peel raffia fruit', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ká\'lə̂', english: 'wine container made from a kind of pumpkin', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ká\'ó', english: 'a piece of plank for cutting meat, also hard surface used by butchers', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káyé məsaŋə̂', english: 'guinea corn', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'koshamə', english: 'curdled milk; cottage cheese', category: 'food', difficulty: 2),
  AwingWord(awing: 'kyaŋə', english: 'cut a big slice eg flesh or meat', category: 'food', difficulty: 2),
  AwingWord(awing: 'kyaŋtə̂', english: 'cut big slices eg flesh or meat', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyéŋtə', english: 'Cut off undesirable ends of vegetable', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lámósə', english: 'orange', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'lámósə yi ńtságnə', english: 'lemon', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lúmnə', english: 'eat food with little or no soup', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwichwí\'á', english: 'something very bitter eg fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mâfɛ', english: 'sweet potato', category: 'food', tonePattern: 'falling'),
  AwingWord(awing: 'mbəm ŋgəsánə', english: 'grain of corn, maize', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məghóla', english: 'oil', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'məji má nkwanə̂', english: 'evening meal, supper', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məjîə', english: 'food', category: 'food', tonePattern: 'falling'),
  AwingWord(awing: 'məkwúnə', english: 'rice', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'máliga', english: 'milk', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'məlo\' má məkálə̂', english: 'beer, wine, whiskies', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋ má aluma', english: 'sorghum; millett of the dry season', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məsaŋ má məgheemə̂', english: 'millet (of the rainy season)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋ má ngəsáŋə̂', english: 'the flower on the stalk of corn (at the tip of)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋə', english: 'the flower on the stalk of maize (any sort of maize)', category: 'food', difficulty: 2),
  AwingWord(awing: 'məsəngágá', english: 'corn cob that has born scanty number of grains, usually this kind bears last reason being that it was planted late', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzɔ', english: 'beans', category: 'food'),
  AwingWord(awing: 'nələ\'ə́', english: 'sweet yam', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'nənta nó atíə', english: 'fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənteemə́', english: 'fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəngoomá', english: 'plantain', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'nəpo\' nó məkálə', english: 'pawpaw', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpumə́', english: 'egg', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'nətə', english: 'the leave of a cocoyam', category: 'food', difficulty: 2),
  AwingWord(awing: 'nətó\'ə', english: 'potato', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'ngəsáŋə́', english: 'corn, maize', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'ngwápə', english: 'guava. From: English', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nju ngəsáŋə', english: 'corn silk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkagə', english: 'a 20 litres container for measuring eg coffee measurement', category: 'food', difficulty: 2),
  AwingWord(awing: 'nkəŋk ô\'lə', english: 'sugar cane', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ónyúsə', english: 'onion', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'panápəələ', english: 'pineapple', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'paŋ sêntê', english: 'pepper (red)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pi nənteemə́', english: 'bear fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shí sêntê', english: 'green pepper', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tămto', english: 'tomato. From: English', category: 'food', difficulty: 2),
  AwingWord(awing: 'tímo', english: 'a kind of insecticide used to spray on arabica coffee', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tyáala', english: 'to strain food or anything using water', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsógchwéŋə', english: 'something very sour fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zeebə', english: 'A bamboo ceiling in kitchens used for drying maize, beans, potatoes etc', category: 'food', difficulty: 2),
  AwingWord(awing: 'zédkə', english: 'make one sated up with food', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zó\'tə', english: 'apply oil a little', category: 'food', tonePattern: 'high', difficulty: 2),

  // actions (695)
  AwingWord(awing: 'achínə', english: 'be hefty, huge in build; important; powerful; great', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajía mə ghóg ná', english: 'be myopic, shortsighted', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anuə mó wam ná', english: 'be guilty, being guilty', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'blemâ', english: 'blame', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'cháabə', english: 'tightly clustered. Lice are tightly clustered on the dog\'s body', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chaakâ', english: 'accompany, lead away; send through or pass something across', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chaakâ məŋgyě', english: 'escort a bride to her groom', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chaanâ', english: 'be abundant, be much. People who steal public property have abundant wealth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'cháb-tə', english: 'tightly clustered ', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'âı', english: 'last very long. The ancient people lived very long lives', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chagâ', english: '(colloquial) smash or step on something (tr). The tyres of a car smashes all sorts of things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chágə', english: 'Of cocoyams, not get ready after it has been prepared (is usually watery)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chagtə̂', english: 'smash many times, crush many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chakâ', english: 'get smashed (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chámtə', english: 'whisper, speak quietly. If one does not want another person to here what he is saying, he whispers', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chánə', english: 'turn away from someone in disgust; talk impolitely', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chántə', english: 'be much, be abundant; be sated, satisfied', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'tə̂', english: 'greet. A polite man greets everybody he/she meets along the way', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\' əli\'ə', english: 'raise false alarm, give false value to something. It is not good to raise false alarm in peace time', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chî kətaŋə', english: 'be empty. A traditional doctor is not without supernatural powers (secret power)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\' mbe\'tə', english: 'refuse something by shrugging one\'s shoulders', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chi\' mbəəmə', english: 'puff up or demonstrate pride', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chî mbó kətaŋə', english: 'be powerless, be weak, be defenceless. The leaders of some countries are really powerless', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chǐ mə́\'á', english: 'be alone; be single, be without companion', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chǐ myā\'â', english: 'knock down, tip over', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chî ndzaŋ yi nda\'ə', english: 'be different, be contrary to expectations', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó aghoonə', english: 'be ill or sick. When somebody is ill he cannot do any kind of thing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó ajúmə', english: 'be rich, be wealthy, have money', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó apógə', english: 'be in fear. He who lives in fear cannot do any great thing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó əpo\'ə', english: 'be innocent. It is a grievous evil for a man to be imprisoned innocently', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó móonə', english: 'be pregnant, be with child. In the olden days it was terrible for an unmarried girl to be pregnant', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó nəpəmə', english: 'be pregnant, be with child', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó ŋgə́\'ə', english: 'be in difficulty, live in hardship', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó njiə', english: 'be hungry. A slave is he who has enough, yet remains hungry', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî ŋgǎ mə́\'á', english: 'be forever, be everlasting', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chî ntəblə', english: 'be naked. The earlymen were naked because they lacked dresses', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî tə nə', english: 'be thirsty', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî tə zə\' ndzə\'ə', english: 'abstain from sex, stay away from sex', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'chî tə zə́\'ə', english: 'be unmarried, stay unmarried', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî yə fɨə', english: 'be new. modern products get spoilt when they are still new', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî yə págə', english: 'be unripe, be raw. When mangoes are still unripe children still harvest it', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chibâ', english: 'be less expensive, cheap. During the rainy season raffia palm is less expensive in Awing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chibkə̂', english: 'make to appear less expensive or less valuable; make something appear ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chídtə', english: 'cut into pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chi\'â', english: 'shake (tr). When a solution is put in water, it is shaken so that it dissolves', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\'ə', english: 'rub. Medicine for frontal headache is rubbed on the forehead', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chîz', english: 'stay, inhabit, dwell; meet', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chɨə', english: 'push; support', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chɨə á məm əwə́', english: '(continued on next page)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chîə á mém təpəŋə', english: 'be part of', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə á mám təpəŋə', english: 'live in sin', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə achíə', english: 'be inborn, be a habit', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ándó neemə', english: 'be cruel (idiom)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ándó ngɔ\'ə', english: 'be numb, unemotional and inhuman (idiom)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\'ə́ asaŋɔ́', english: 'wag tail', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chîə ashamnə ashamnə', english: 'be scattered or disorganised; live apart, not together (of people)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə atíə atíə', english: 'be unstable, be unsettled', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə awata', english: 'be hospitalised, be in hospital bed', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə aweləweelə', english: 'be mixed', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə apábpéebá', english: 'be multicoloured or having many different marks', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə əsê', english: 'be low, be humble', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbiə', english: 'be infront; be ahead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbia', english: 'be alive', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbó', english: 'of a baby about to be born, said to be in hand', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mátê', english: 'be in extreme difficulties such that one cannot have a sound sleep', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ndəzeemə', english: 'be dreaming; be wandering', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə nəlyaŋnə', english: 'in a hidden place', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ntso nəwûə', english: 'be dieing or about to die', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chigə əshunə́', english: 'good friendship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə ndəlá', english: 'the right time', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə ndúmə', english: 'reliable source', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə neemə', english: 'cruel; poorly behaved', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chigə tákɔ\'ə', english: 'biggest', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíkə', english: 'push (many things)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíka', english: 'stay of many people or many places, inhabit many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chílə', english: 'cut into many little pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chi\'nâ', english: 'shake by itself (intransitive), be shaken', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chínə', english: 'be hefty, huge in build; important', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíta', english: 'cheat', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chí\'ta', english: 'rub many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chítázɔ́\'ə', english: 'be celibate', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chid ntsəənə', english: 'lie, tell a lie', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chú\' əshunə́', english: 'start a relationship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chú\' mógə', english: 'light (fire)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chúbnə', english: 'fault finding', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chú\'ə', english: 'pound', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chûə', english: 'say, used in a rather snobbish and derogatory manner', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chú\'tə', english: 'pound many times, smash many times', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chútóŋonə', english: 'wail; scream', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwâ', english: 'to clear (a field)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwa ndəlá', english: 'create, allocate or find time', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáakə', english: 'begin; generate a machine', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáakə nkyeetə', english: 'start an association', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaalâ', english: 'find, look for something; investigate', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwáalə', english: 'survive narrowly; recover from an illness', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaalâ afa\'ə', english: 'look for a job', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwaalâ ape\'ə', english: 'accumulate wealth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwaalâ ndúmə', english: 'of a pig, present signs that it is ready for crossing/mating', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwáalə nəwûə', english: 'survive death', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'chwádkə', english: 'save, deliver from danger', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwántə', english: 'cut many spots or many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaŋkə̂', english: 'grow lankily, of plants and people (tall, lacking in freshness and flesh)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwéŋtə', english: 'pour liquids', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwə\'â', english: 'soften a piece of land for planting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwí ələnə', english: 'name something or somebody', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwíəə', english: 'give a name', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwígə', english: 'spy', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwigtə', english: 'kiss a little', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chwí\'kə', english: 'make two or more things closer together', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwinɔ̂', english: 'act provocatively or threaten', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwí\'nə', english: 'get tight together; unite', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwíŋə', english: 'be thin', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwíŋtə', english: 'a little thin or less in weight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwí\'tə', english: 'accumulate, pack', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwitə ngonə', english: 'wail sharply', category: 'actions', difficulty: 2),
  AwingWord(awing: 'dotê', english: 'be dirty; be ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fablô', english: 'be fastidious', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fádtə', english: 'stuff or force in many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fa\'ô', english: 'work; serve', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagô', english: 'break, dislodge', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagkô', english: 'break in little pieces or many pieces (intransitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagtô', english: 'break in little pieces or many pieces (transitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fanô', english: 'do something terrible; become terrible', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'fankə', english: 'be wrong', category: 'actions'),
  AwingWord(awing: 'fáŋkə', english: '1) be fat (of many things)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'faŋnô', english: 'embrace, hug', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fa\'tô', english: 'work a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féelə', english: 'force or stuff in something, fasten eg a fence', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'feŋə̂', english: 'unwrap, expose, open food that has been wrapped', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féŋkə', english: 'disgrace, ridicule; defile', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fê ntəgɔ́', english: 'advice; counsel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'felə ndzɔ\'á', english: 'divorce. When a woman divorces she loses her charm', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəələ̂', english: 'blow (of fire or nose); eat heavily (derogative use)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fáənə', english: 'bend down, stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fáətə', english: 'large and pointed (used insultively for buttocks)', category: 'actions', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'fəgə̂', english: 'be blind', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fágə', english: 'blow (with fan or breath)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fágtə', english: 'blow (many times), blow a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmə', english: 'be poor', category: 'actions'),
  AwingWord(awing: 'fəmkə', english: 'drown (transitive). In war people drown their enemies in water as a way of punishing them', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fəmnə', english: 'drown (intransitive). Why is it that humans drown under water, while fish do not', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fəmtô', english: 'walk as if one is not seeing or blind. When a blind man is walking, he walks unsteadily', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'â', english: 'measure (of distance or height). One never measures his height with that of his father', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'kâ', english: 'imitate. Children learn faster because they imitate everything they see one doing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'filə', english: 'blame', category: 'actions'),
  AwingWord(awing: 'fi\'nə̂', english: 'imitate. People who work out of envy can be dangerous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'tə̂', english: 'tell. When a child is beaten, he will feel comforted to say that he will tell his mother when she comes back', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fídkə', english: 'exile, expel', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'figə̂', english: 'decieve. Some bad students decieve their peasant parents to get money', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'figtə̂', english: 'decieve (many people); decieve many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fo\'â', english: 'be rich', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fógə', english: 'pick; choose', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fónə', english: 'call. A pastor responds to a call to God\'s service, not enlisting into a job', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fónnə', english: 'call', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'fóomə', english: 'be oily', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'fu\'ô', english: 'bubble up, boil . A pot is boiling on fire', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fulâ', english: 'uncover, expose, open. A prostitute exposes his/her nakedness just anywhere', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwo\'â', english: 'hollow out . There is a machine for hollowing out trees', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwonə̂', english: 'imprison; lock or key eg a door', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwontə̂', english: 'lock (many doors); imprison, of many people', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwoŋə̂', english: 'lift or remove sth sticky. When it rains people lift a lot of mud with their feet', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwoolâ', english: 'shave, as with a blade; peel off', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwootâ', english: 'mumble. A dumb mumbles instead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyaamə̂', english: 'remove sth hanging or suspended. Remove a dress from the line (rope)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyádtə', english: 'chase (many things); insist many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fya\'â', english: 'rebuke; quarrel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fya\'ə̂', english: 'water. Water tomatoe', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyagə̂', english: 'dislodge something from another. It is difficult to dislodge two friends from each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyagtə̂', english: 'separate two things from each other. It is normal to separate two people fighting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyamtə̂', english: 'of things hanging or suspended, remove them. Remove those dresses hanging on the line', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fya\'sê', english: 'sacrifice to the dead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gómə', english: 'clue', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ghabkə̂', english: 'half done or gone. He has not gone half', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghabnə̂', english: 'divide, separate, share (intr). They have shared their property', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghabtə̂', english: 'divide, separate (tr). He has shared his belongings', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghá\'ə', english: 'be big', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gháglə', english: 'be smart. A smart woman is more pleasing to people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghagtə̂', english: 'make poorly, of furniture. He has made that bamboo chair poorly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghánə', english: 'stagger (intr). A drunk walks staggering because of the wine he has taken', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghánkə', english: 'stagger, make somebody to stagger (tr). He has made somebody to stagger and fall', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghántə', english: 'visit a little, visit many people; wonder about', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gheebə̂', english: 'divide or share, give (tr). It is good to give alms (be generous)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghéenə', english: 'visit', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ghedtô', english: 'act, do, make a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂', english: 'act, do', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghenkə̂', english: 'make go', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghə\'ə̂', english: 'frugal, be greedy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghəəkə̂', english: 'disturb, stupify', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghəənə̂', english: 'be stupid', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghəətə̂', english: 'fumble, do something wrongly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghághlə', english: 'hasten up, hurry, be fast', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghó\'kə', english: 'respect, honour, praise; worship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghoolə̂', english: 'pay dowry; marry', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghoonə̂', english: 'be sick, be ill', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghó\'tónô', english: 'be fastidious, be difficult to deal with, feel high of one\'s self', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghədkə̂', english: 'frighten', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'gho\'ə̂', english: 'crush (transitively), grind', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghəntə̂', english: 'often sick, frequently ill', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gho\'tə̂', english: 'grind a little, grind many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jáabə', english: 'reduce', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jábtə', english: 'replant', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'já\'ə', english: 'skip through, leap over', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'já\'kə', english: 'vomit', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jî əkomó', english: 'be crowned, take title of a noble through a ceremony in the palace', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî ənuə', english: 'be intelligent, be bright', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî mbəglə', english: 'be corrupt', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jîəə', english: 'begin, start', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'jimkə', english: 'wake somebody up (transitive)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jimnə̂', english: 'wake up (intransitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ji\'tə̂', english: 'be frugal, be stingy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júblə', english: 'be foolishly excited', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jubtə̂', english: 'peel many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júmə', english: 'dry up; lose weight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'júmnánáwûə', english: 'resurrect, come back to life', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júnə', english: 'buy; corrupt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwǎa', english: 'trap an object flying in the air', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'jwáabə', english: 'provoke, taunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwábtə', english: 'provoke many times, taunt continously', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwa\'ə', english: 'annoy, disturb', category: 'actions'),
  AwingWord(awing: 'jwánə', english: 'befit; suit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwó\'ə', english: 'test', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwó\'tə', english: 'listen', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwiəə', english: 'breathe; open the window to let air in', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jwikə', english: 'pant; ventilate', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jwí\'kə', english: 'boil a little in hot water so as to preserve by drying', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwitô', english: 'rest, take a rest', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'káatə', english: 'threaten', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kádtə', english: 'coil rope, rap many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká\'ə', english: 'clot (as blood)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káglə', english: 'sweep imperfectly', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kagnə̂', english: 'threaten each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kagtə̂', english: 'threaten many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kakə̂', english: 'be rough', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kamə̂', english: 'lift in big lumps', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kamtə̂', english: 'eat hastily', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kanə̂', english: 'jump from a high place', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kaŋtə', english: 'stumble', category: 'actions'),
  AwingWord(awing: 'kéelə', english: 'wrap up, coil (rope)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kéenə', english: 'be tired', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kédkə', english: 'burn in many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kélə', english: 'burn', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kábkə', english: 'cover', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kǎə', english: 'be deaf', category: 'actions', tonePattern: 'rising'),
  AwingWord(awing: 'káəbə', english: 'shell, of groundnuts and egussi', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəəkô', english: 'run (referring to many things or people running)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəələ̂', english: 'run away, flee, escape', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəətə̂', english: 'run a little or make an effort to run', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəmə̂', english: 'drive away', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəmtə̂', english: 'sprinkle a little (powder, ground etc) on something', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəŋkə̂', english: 'avoid, alienate', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəŋtə̂', english: 'shut a little; shut many', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kápkə nkwumə', english: 'close a box', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká\'tə', english: 'cut many times; cut many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kîəə', english: 'refuse, reject', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kíbnə', english: 'high, of forehead', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíbtə', english: 'shell a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kí\'tə', english: 'Obstruct many people, things or places; defend (many people, things or places)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó əsóənə', english: 'be shy (it is not good for somebody to be too timid and do wrong)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ko\'â', english: 'arrive; be enough', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kogə', english: 'be blunt', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kóga', english: 'bring up (child or young of any animal)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kógnə', english: 'behave stupidly', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ko\'nâ', english: 'right, (be) correct', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóŋkə', english: 'cause to be carried away by water current', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóo', english: 'snore', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kookâ', english: 'peel off in bits; fall off by itself', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóokə', english: 'shift blame (when a thief is caught he shifts the blame to hunger)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'koolâ', english: 'harvest fruits with impunity', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóoma', english: 'shave (as if one is mourning)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóomə', english: 'scratch eg an itching part of the body, scratch the surface of a wall to remove paint or dirt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóomálənə', english: 'pity, show sympathy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'koonâ', english: 'fall or peel off in large quantities (usually by itself)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóotə', english: 'take hold of many things (as a fishtrap traps fish)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kədkô', english: 'peel off, usually as a sign of delapidation', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kódta', english: 'eat many things, eat a little thing (before going to work)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'ə', english: 'grow, of plants; mount, for example a horse', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'kə', english: 'raise, of a child; lift', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kólə', english: 'ruminate, chew cud', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kómtə', english: 'Clean a little, usually with a hoe; clean roasted food', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'nə', english: 'Climbing, scramble of many things; Scramble around something or somebody', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kontə̂', english: 'bump, trip', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəŋnə̂', english: 'be happy with each other; be joyful with each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóŋnə', english: 'Crawl; slither, of many things (snakes are slithering in the farm)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'tə', english: 'brag', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwáakə', english: 'cackle (as of fowls), especially when a fowl lays an egg or when it senses danger', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwáalə', english: 'help', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwáankǐə', english: 'be baptised', category: 'actions', tonePattern: 'rising'),
  AwingWord(awing: 'kwáatə', english: 'help a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwa\'ə', english: 'play, make jokes', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwagtə̂', english: 'clean a little, using a hoe (usually in the coffee farm)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwakə̂', english: 'get broken', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwa\'lə̂', english: 'tempt', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwaŋtə̂', english: 'think a bit, decide', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwêe', english: 'answer; reply', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kweekô', english: 'Influence a person or an animal against another', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwê', english: '(colloquial) tell a lie (people lie in politics to such extent that one can see a black object an call it red)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwénkə', english: 'Help somebody or something go in', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwəələ̂', english: 'Ask many annoying questions', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwá\'tə', english: 'kneel', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwígə', english: 'revenge', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwíŋkə', english: 'bring up , raise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwubə̂', english: 'be frugal', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwúbkə', english: 'take in liquid medicine via the anus', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúblə', english: 'alter, change (transitive)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúblə mbimá', english: 'convert; change one\'s believes', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúdtə', english: 'tie many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwûə', english: 'be dead; die', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwúka', english: 'die, of many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwú\'kə', english: 'make sb or sth stoop, bend or bow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúlə', english: 'fasten; bind', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwum əfeemó', english: 'punish by brutal killing, usually by driving a very big nail into the forehead', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúmtə', english: 'remember, remind', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwú\'nə', english: 'stoop; bend', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwú\'tə', english: 'stoop, of many people; bend, of many people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyaalô', english: 'Lift sth soft or rotten with a hoe or spade. Clean off mess', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyáamə', english: 'wring out, squeeze', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyaatə', english: 'Do a little cleaning of mess', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kyáglə', english: 'Dirty, with marks caused by sweat, water or cosmetics', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyagtə', english: 'untie many things eg bags', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kyámtə', english: 'wring out water (just a little) from sth', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyê', english: 'abandon sth because it has been desecrated or misused', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyêe', english: 'smash grain into little pieces, using a grinding machine', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyeetə̂', english: 'Bring together, gather', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kye\'â', english: 'Make a small opening on a thing. This refers to things that can be peeled, esp. food items', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kye\'kə̂', english: 'develop openings or cracks (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyéŋə mbi əsê', english: 'confess', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kyé\'tə', english: 'hatch', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kyéɛlə', english: 'claim reimbursement', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kyímə', english: 'Cut off sth attached to another, esp. using a sharp point', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyímtə', english: 'Cut off things attached to the main part, especially using a sharp point', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ladkô', english: 'continuously, non-stop; connect, link', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ladtô', english: 'tangle', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lá\'ə', english: 'hook', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'la\'â', english: 'announce (especially of a birth); say (colloquial)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lagə', english: 'fetch, of firewood; gather or assemble, of objects', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lá\'kə', english: 'thank or give thanks', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'la\'nə̂', english: 'promise, say that one will do something', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'langa', english: 'palate, sense of taste', category: 'actions', difficulty: 2),
  AwingWord(awing: 'laŋə̂', english: 'succeed, make it', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lá\'tə', english: 'hook many times', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'leŋkə', english: 'notice or put a mark on something so as to give it identity', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lednə̂', english: 'perspire, sweat', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'leelô', english: 'float', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lelə', english: 'be heavy', category: 'actions'),
  AwingWord(awing: 'lenə', english: 'be old (not young, not new)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ləbə', english: 'slap', category: 'actions'),
  AwingWord(awing: 'lə\'ə', english: 'avoid, evade', category: 'actions'),
  AwingWord(awing: 'lógə', english: 'cut (tr); decide, put an end', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləgnə̂', english: 'forgive; forget', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lágnə', english: 'cut (tr), decide', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləmə', english: 'stink (bad or offensive); smell (intransitive verb)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ləmkə̂', english: 'smell (transitive verb), sense through the nose', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ləmnô', english: 'startle, surprise', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ləmtô', english: 'grumble, complain', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ləŋə̂', english: 'stir', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'líbkə', english: 'make or cause something to go round', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'líblə', english: 'go round, surround', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lí\'ə', english: 'cultivate, hoe (v)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lîə', english: 'jump, leap', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lóŋkə', english: 'fill, of solids', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'loonâ', english: 'want; desire', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóbtə', english: 'plan', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lo\'â', english: 'put a spell on', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóg ŋgenə', english: 'carry away', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lóg ngiə', english: 'bring, bring along', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lo\'kâ', english: 'keep; bury (euphemism)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóŋnə', english: 'be lazy', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lúmtə', english: 'gnaw', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lúnkə', english: 'fill, of solids and liquids', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwénkə', english: 'fill; be full', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwénkə nəŋkə', english: 'fulfill the law, obey law', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwîəə', english: 'be bitter', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lwigtâ', english: 'be last', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lwikô', english: 'a little bitter', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lyamkô', english: 'contaminate, spread eg a disease', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lyamnô', english: 'spread, of disease', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ma\' məlóŋə', english: 'be sad, look pitiful', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ma\'â', english: 'give, of a free gift. This done or demanded only after buying something. eg eating oil', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'máma', english: 'name used for old women; prefix used before the names of old women', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mêe', english: 'be used up', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'megtə acha\'tə', english: 'wave a greeting', category: 'actions', difficulty: 2),
  AwingWord(awing: 'medkâ', english: 'make something to become habitual', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'médkə', english: 'immerse somebody or something in water (tr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'medtô', english: 'allow, permit; cease, stop, leave', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'melô', english: 'become a habit', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'méla', english: 'immerse or dive in water', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məchína atîə', english: 'be high', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mág mimá sén nə', english: 'be dizzy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məgtə̂', english: 'finish', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məghábnə apô', english: 'be generous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məjûmnánə nəwûə', english: 'ressurrection', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məlêlənə̂', english: 'be dim', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məmtə̂', english: 'feel something through a physical touch (active voice)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məpêŋnə ajwíə', english: 'be unconscious', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məpêna məlo\'á', english: 'be drunk', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mîəə', english: 'swallow', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'mí\'tə', english: 'stutter', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'moomâ', english: 'try', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'mootô', english: 'chat, discuss', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'mya\'â', english: 'throw away; abandon', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nâ', english: 'insist, press', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'náanə', english: 'be seated; sit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'na\'ə̂', english: 'be silent, be still', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'náŋə', english: 'look at; look for', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'náŋə anuə', english: 'consult a sorcerer, find out the cause of something', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'náŋkə', english: 'announce, inform', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'náŋnə', english: 'cook, boil food', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nèe', english: 'insist, press on', category: 'actions', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'neebô', english: 'be neat, be polished', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ne\'â', english: 'limp', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'néŋ əsóomə atûə', english: 'accuse falsely', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'néŋə', english: 'put; place', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nédkə', english: 'grunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nélə', english: 'groan', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nəələ', english: 'show, explain; demonstrate', category: 'actions', difficulty: 2),
  AwingWord(awing: 'naŋê', english: 'step on, stamp (with feet)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəntə̂', english: 'trample', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nid ńgə́', english: 'imply that, mean that', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkogə́', english: 'widow (used neutrally for both man and woman)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nô ngoolə', english: 'swear, oath, make a statement that is considered as the truth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'noŋnô', english: 'lie down; be level', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nə\'â', english: 'press', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nóŋə', english: 'suckle (intr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nyaanô', english: 'sluggish, slow', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nyá\'ə', english: 'a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyaglə', english: 'tickle', category: 'actions'),
  AwingWord(awing: 'nyamnô', english: 'mix', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nyée', english: 'growl', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nyīəə', english: 'defecate, excrete', category: 'actions'),
  AwingWord(awing: 'nyinô', english: 'move; travel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nyintô', english: 'take a walk, stroll', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nyíŋnə', english: 'be restless, be unsettled', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋá\'ə', english: 'open (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋá\'kə', english: 'open (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋá\'nə', english: 'open (intr), of something opening by itself', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋáŋkə', english: 'lift', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋédtə', english: 'be crooked', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwa\'ô', english: 'clean, clear; holy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwa\'lô', english: 'write', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ŋwaŋkô', english: 'flash, of something bright eg of lightening; shine', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwéetə', english: 'be jealous, be envious', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwédlə', english: 'be too excited', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwú\'kə', english: 'make something stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwú\'nə', english: 'bow, as in greeting; stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'páatə', english: 'approach; make narrow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pábtə', english: 'make something a little warm; roast a bit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pa\'ə', english: 'plait, braid , weave', category: 'actions', difficulty: 2),
  AwingWord(awing: 'págə', english: 'ferment', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'panô', english: 'hang up', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'paŋə', english: 'be red', category: 'actions'),
  AwingWord(awing: 'paŋnə', english: 'ripen, become ripe, of many things', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pèe', english: 'sharpen', category: 'actions', tonePattern: 'low'),
  AwingWord(awing: 'péebə', english: 'bake (in ashes)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'peelô', english: 'carry on the bavk (sic: back)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'peenə', english: 'hate', category: 'actions'),
  AwingWord(awing: 'pegə', english: 'enlarge; widen', category: 'actions', difficulty: 2),
  AwingWord(awing: 'péŋkə', english: 'misplace', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'péelə', english: 'be mad. Rather than stay alive and be mad, one be dead rather', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'péntə', english: 'paint, daub with paint', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pə', english: 'then. = You told him, what then did he say?', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pá ndəŋdəŋə', english: 'be equal, be same', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pá nkaŋ nwunə', english: 'be young', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'ə', english: 'break (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'páəmə', english: '1) hunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pəglə', english: 'put in disorder, scatter', category: 'actions', difficulty: 2),
  AwingWord(awing: 'péŋnə ńgwûə', english: 'capsize, tip over and fall', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pəŋtô', english: 'contradict', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'pí\'ə', english: 'hem', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pí\'kə', english: 'twist, treat cunningly, handle cunningly', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pímnə', english: 'agree', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pítə', english: 'ask, request', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pí\'tə', english: 'fold, wrap up', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pi fê', english: 'return, give back (tr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pó\' mbeebə', english: 'flap wings', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'nə', english: 'fight, fight each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póŋə', english: 'be poor; lack', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póŋə awaamə mbəəmə', english: 'be impatient, lack patience', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pookô', english: 'say goodbye, take leave of', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'póomə', english: 'build, mold (pottery)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəbnô', english: 'squat, sit (on bear ground)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'poŋô', english: 'be good; beautiful', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pwódkə', english: 'be impotent', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pwódnə', english: 'be kind or gentle, of people; be soft, of objects', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pwónə', english: 'dip', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pyáanə', english: 'pick up', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pyáatə', english: 'examine closely (with care, love and diligence), explain diligently', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pyábtə', english: 'guide many things or people; guide a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sa\'ə', english: 'snatch', category: 'actions'),
  AwingWord(awing: 'tá\'ə', english: 'order, of someone to do something; judge', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sa\'ə məngyè', english: 'marry by taking the fiancee by trickery or by physical force', category: 'actions', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'sakə', english: 'lengthen', category: 'actions'),
  AwingWord(awing: 'sá\'kə', english: 'burst out, of many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sá\'nə', english: 'quarrel with each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sánkə', english: 'get broken', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'sántə', english: 'cut or break into many pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'séenə', english: 'saw , cut open', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'seŋtə', english: 'flatten', category: 'actions'),
  AwingWord(awing: 'sedkô', english: 'curve, bend (tr), make it go round; make something go round', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sednô', english: 'turn round (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'seekô', english: 'torn in many pieces, torn in many spots eg of a dress', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'séekə', english: 'blaze, of light; shine intensely, of light (tr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'seenô', english: 'be torn, torn eg of dress', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sábkə', english: 'swing', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'səəkə', english: 'be slippery', category: 'actions'),
  AwingWord(awing: 'səələ', english: 'slice', category: 'actions'),
  AwingWord(awing: 'səənô', english: 'slip', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sôətə', english: 'slice in many things, castrate many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'səŋə', english: 'sifter', category: 'actions'),
  AwingWord(awing: 'sô', english: 'weed', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sogə', english: 'wash (tr)', category: 'actions'),
  AwingWord(awing: 'sóŋgo\'á', english: 'crown', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sǒo', english: 'cover completely. Masqueraders wear masks', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'soobô', english: 'stab, pierce', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sóokə', english: 'pass something through, especially into a narrow place or into a place difficult to be accessed', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soolô', english: 'domesticate, tame', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sóola', english: 'go through a hole or a narrow place', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'səbtô', english: 'stab, pierce continuously', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sha\'\'tə', english: 'sprout', category: 'actions'),
  AwingWord(awing: 'shaabô', english: 'comb', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shaalô', english: 'husk (corn)', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shamkô', english: 'scatter, spread out (maize) (tr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shamnô', english: 'be wide', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sháŋə', english: 'count, number', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'shîəə', english: 'stretch', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shígə', english: 'wipe', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'shikô', english: 'deepen', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shitô', english: 'straighten', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shúmə', english: 'whip, beat up', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwaalô', english: 'be odd; be ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwánta', english: 'persuade. If you persuade somebody with good words he listens to you', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwee', english: 'miss, fail to get. If one misses something it is good to try again', category: 'actions', difficulty: 2),
  AwingWord(awing: 'shweekô', english: 'fail, not work as planned', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwə\'á', english: 'reduce in intensity . That illness is reducing in intensity', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwəənô', english: 'slither (of snake), roll', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwəətô', english: 'caress', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shwəgtô', english: 'fade', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shwíŋə', english: 'suck', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'taalô', english: 'stagger', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'táaatə', english: 'set many traps', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ta\'â', english: 'search, especially through piles of things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tágə', english: 'harvest, collect (honey from hive)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'taŋô', english: 'be sticky', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'taŋnə', english: 'suffer', category: 'actions', difficulty: 2),
  AwingWord(awing: 'táta', english: 'address, to an old man', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'téekə', english: 'meet, catch up with; join', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'téemə', english: 'set a trap; net, of fish', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tégə', english: 'meet, catch up with; join', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tegnə', english: 'already left (gone), just left (gone)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tê', english: 'hot, of pepper', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tê ndê', english: 'leave the house very early in the mourning hours, especially at mourning twilight (colloquial usage)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'teŋkə', english: 'push', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tó', english: 'functions as one of the two forms of the verb \'to be\'. He is going to the farm', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tə shîəə', english: 'be shallow', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'təələ', english: 'boast', category: 'actions', difficulty: 2),
  AwingWord(awing: 'təəmə', english: 'choke', category: 'actions', difficulty: 2),
  AwingWord(awing: 'təənô', english: 'be mature', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tóga', english: 'discipline, put on the right path', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tógə atûə', english: 'be eager, (be) zealous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tágtə', english: 'put many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tám əsóomə atûə', english: 'accuse falsely', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'támə', english: 'kick, shoot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'taŋnô', english: 'tether (sheep, goats)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tímə', english: 'sew using a needle', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí ndəŋdəŋə́', english: 'be level, be straight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí ngəələ', english: 'be hollow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tímnə', english: 'wander', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'to\'ə', english: 'become dwarf, of people; all grow, of plants', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tó\'kə nkadtə', english: 'be proud', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tó\'kə nkonə', english: 'be proud', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tômbáŋə', english: 'flip over', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'tóŋə', english: 'dig', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tóoka', english: 'overtake', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'toonô', english: 'singe; roast', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tógə', english: 'pierce (of ears) for earings', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tómtə', english: 'justify; support', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tonô', english: 'be hot', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'to\'nô', english: 'inquire curiously', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tóŋnə', english: 'shout', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tûə', english: 'pay (for goods, services, etc.)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'túəŋə', english: 'bury', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tûg əsəənə', english: 'ashamed', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'túgə', english: 'have, hold; look after, care for', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túgə akoŋnə', english: 'be happy with each other; be joyful with each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túgə apógə', english: 'be afraid', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twáamə', english: 'lift up; carry', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twéetə atwêŋə', english: 'gird up, of one\'s loins; get ready for action', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'twîə', english: 'melt iron', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'twi\'ə', english: 'delay, stay for long', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tyâ', english: 'reject', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyáatə', english: 'explain carefully with every necessary detail', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tyagə', english: 'lift, of sth sticky', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tyá\'la', english: 'straddle', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tyantô', english: 'be hard; strong', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyantə', english: 'harden', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tyantô má jí nə́', english: 'be scarce, hard to find', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsáblə', english: 'talk nonsense, talk foolishly, talk alot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsámtə', english: 'chew many things; chew a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tséebə', english: 'speak, talk', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tséemə', english: 'chew', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsé\'ə', english: 'admire', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tségnə', english: 'sneeze', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tseŋə', english: 'urinate', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tseŋnə', english: 'herd of cattle, sheep etc', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsédndzəmə', english: 'last, finalise, end', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsəələ', english: 'defeat, beat in a contest', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tséla', english: 'stop up, patch', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsentə', english: 'assemble, meet, heap up, join, put together, gather', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsəəmə', english: 'drip', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsóga', english: 'be expensive', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsoŋ aléna', english: 'slander', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsəŋkô', english: 'condemn, spoil, damage', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsəŋkô apímnə', english: 'break a promise', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsid ntsəələ', english: 'lie, tell a lie', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsímkə', english: 'trickle', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsó\'ə', english: 'heal (tr), cure', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsonkə', english: 'create, make; manufacture', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsóŋə', english: 'make a knot, tie a knot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóŋtə', english: 'make many knots, tie knots', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsoobô', english: 'imperfectly done, do imperfectly eg preparing food', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsóoka', english: 'lower (tr), decrease (intr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóoka mbəəmə', english: 'be humble', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóolə', english: 'descend, go down', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsó\' mbîəə', english: 'transplant', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\' mbô', english: 'drop (tr), let go', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\'kə', english: 'lend', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsɔɔ', english: 'taste poorly, not flavoured; of food', category: 'actions', difficulty: 2),
  AwingWord(awing: 'waalô', english: 'slaughter animals; butcher animals', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'waamô', english: 'accuse', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'waamə', english: 'hold, catch (fish), seize', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wadnô', english: 'cross, traverse, pass through', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wágə', english: 'despise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wam mbəəmə', english: 'be patient; calm one\'s self', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wamtô', english: 'tie loosely, of a rope round something eg round a cow\'s neck', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wê atsə\'á', english: 'wear clothes', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'we\'â', english: 'open', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'weŋô', english: 'smile', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'weŋkô', english: 'smile a lot, smile frequently especially without descriminating with whom this is done', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wê', english: 'weigh. From: English', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wednô', english: 'mix', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wedtô', english: 'mix (many things)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wé\'ə', english: 'curse away, purge something', category: 'actions', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'welô', english: 'weight', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wénə', english: 'draw pictures; make incisions', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wénnə', english: 'be worried, be impatient', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wáələ', english: 'worry, feel disturbed', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəg əfógə', english: 'fan', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəgô', english: 'blow of air', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wó\'tə', english: 'remember, remind', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wǔəə', english: 'fall; fail', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'wukə̂', english: 'fall many times; fall, of many people', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wúnə', english: 'invite, ask or demand that somebody should help one, often to do jobs that cannot be done by the individual', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wu\'nə nkwumə', english: 'close a box; close a coffin', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wúnta', english: 'invite, of many people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yaalô', english: 'carry, of heavy load (colloquial usage)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'yáŋə', english: 'be wise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yantə', english: 'protrude, of stomach', category: 'actions', difficulty: 3),
  AwingWord(awing: 'yénta', english: 'half-eat something (leaving teeth marks) eg as is usually done by a cat or rat', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéeka', english: 'disturb or annoy somebody or something', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéeka əli\'á', english: 'disturb or annoy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéelə', english: 'loose the mind; be mad (used colloquially)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yîəə', english: 'come, approach', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'yigə', english: 'escape capture easily, skilled in evading capture', category: 'actions', difficulty: 2),
  AwingWord(awing: 'yílə', english: 'difficult, hard', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zadtô', english: 'sprinkle', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zagə', english: 'fly', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zag náanə', english: 'alight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zá\'kə', english: 'lend, give on credit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zámkə', english: 'put (of something) on another', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zámnə', english: 'sit on something high or uplifted eg on a powerful throne', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'záŋ ndê', english: 'be angry', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'záŋə', english: 'give pain, hurt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zaŋkə', english: 'be light (not heavy)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zé\'ə', english: 'learn', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zegô', english: 'smear a surface with something sticky', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zegə̂', english: 'wipe off something sticky eg of excreta after excreting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zé\'ka', english: 'teach', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zélə', english: 'be sated', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zəələ', english: 'steal', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zəəmə̂', english: 'wake somebody from sleep', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'záənə', english: 'find; see', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zəgə', english: 'sweep', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zəgtə̂', english: 'sweep a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zá\'nə', english: 'lean against', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zó\'ə', english: 'hear; feel', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zo\'kə', english: 'make less tight', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zó\'nə', english: 'be obedient', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zoŋ pə́ pê', english: 'be third', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'zoŋkə̂', english: 'be second', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zoobə̂', english: 'sing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zoolə̂', english: 'roar', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zó\' nə məghôlə', english: 'annoint, rub with oil', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zəbtə', english: 'babble, of baby', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zəmnə̂', english: 'insult each other', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'zəmtə̂', english: 'insult', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'zoŋnə̂', english: 'fight over something', category: 'actions', tonePattern: 'falling', difficulty: 2),

  // descriptive (131)
  AwingWord(awing: 'achaakə', english: 'escort accompanying a bride to her new home', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'afélə', english: 'uninfluential; physically powerless', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afya\'ó anuə', english: 'sacrifice for the dead, libation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghaglə móchìsə', english: 'empty match box', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəəló', english: 'open gourd for washing twins', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúblə', english: 'foolish excitement, uncontrolled and misguided excitement', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwigó tapəŋə', english: 'bad company', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'akəféŋəntsoolə', english: 'obscene/immoral behaviour', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'akəghə atséebə', english: 'foolish talk', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəká\'ó', english: 'kind of basket weaved using soft interior of raffia bamboo', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəkógó atséebə', english: 'foolish talk', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akíbnə', english: 'high (of forehead)', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə mbyâŋnə', english: 'young man', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akó\' yə fíə', english: 'new generation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akweŋómbéŋə', english: 'young goat', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyâglə', english: 'dirty marks on body or clothes caused by dirty water, sweat or cosmetics', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akye\'ə', english: 'small sign or indication (usually of something bigger to come)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'alá\'ə', english: 'much, a lot', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə pakwûə', english: 'world of the dead', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alě nəwûə Yésó', english: 'good Friday', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alêtələ', english: 'sharp and alert person (colloquial)', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alaŋə', english: 'stick used to hold together two ends of a rope', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ali\' yə noŋnə nə', english: 'open place, clearing', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'anüənda\'ə', english: 'false thing', category: 'descriptive'),
  AwingWord(awing: 'anuyələnə', english: 'old fashioned practice', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'anyádlə', english: 'digusting, dirty', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'apa\'ə', english: 'a flat covering (of door, window, hut etc.)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'apáŋə', english: 'an open bamboo cupboard attached to the wall of the house used for putting kitchen utensils', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apuməŋkwúnə', english: 'small pox', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəələ', english: 'castrated', category: 'descriptive'),
  AwingWord(awing: 'asagá', english: 'A place that is open and exposed', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəglə', english: 'important, great, powerful, influential', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'asəŋə', english: 'a kind of weaved basin', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'asóŋətəzéənə', english: 'false witness; lier', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asha\'kə', english: 'ruined, disintegrated, broken', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ashwə̌lə', english: 'unusual, strange', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'ateekáŋá', english: 'something very strong', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atátəŋə', english: 'white fluid that flows from the vagina as a sign of labour (birth production)', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨəndê', english: 'first floor of a roof', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atóomə', english: 'A long drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəsá\'ó', english: 'The first menstrual flow of a girl. girls see their first menstrual flow in their teens', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəsê', english: 'bag containing a dead close relation\'s (father, mother, grand mother, grand father etc) hair, worshipped periodically for appeasement', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atsa\'áfágə', english: 'warm clothing', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atságə', english: 'bitterness, quarrelsomeness', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'atságántəəmə', english: 'ill temper', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chî əshi\'nə', english: 'be healthy, be well; be save', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chigə', english: 'real, true; important', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'chigə anuə', english: 'truth; real thing', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'chigə anuə təpəŋə', english: 'terrible evil; scandal', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'chɔ́sə məfigə', english: 'false religion', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeemá', english: 'a small stick used to facilitate wood splitting', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Nəfəmátûə', english: 'the first fon of Awing', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghó\'ə', english: 'a sort of large, delicious and expensive mushroom', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əka yi fîə', english: 'new testament', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əka yi lenə', english: 'old testament', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'əkwə̌nkwáŋə̂', english: 'bony', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'əlén təpəŋə', english: 'bad reputation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlén yi əshí\'nə', english: 'good reputation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá lum nó', english: 'hot weather', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá nwá nó', english: 'cold weather', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əloonə', english: 'a sort of blessing invoked from the dead', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'əpábpéebá', english: 'multicoloured; spotted', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpəgkáŋə', english: 'broken dishes; cymbals', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpagpagə', english: 'fragmented, be in pieces; fragments, pieces', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'əpêdpələ', english: 'corrugated; furrowed', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əshí\'ó', english: 'how many', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fya\'átûə', english: 'sacrifice to the dead. People worship the dead in Awing and this against the word of God', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂ á fóomə', english: 'make smooth', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂ á kakô', english: 'make rough', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî ntú majîə', english: 'eat first of new crops, eat first of new fruit', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kə', english: 'marker of past tense for an event that took place a few days ago', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'káféŋə', english: 'little sorts of mushroom-like plants', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kákwumə̌kókwumə', english: 'word that describes how a foolish man moves, especially into trouble', category: 'descriptive', tonePattern: 'rising', difficulty: 3),
  AwingWord(awing: 'kəlá\'ə', english: 'marker of far past tense, used for events that take place many years back', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'kəmkə̂', english: 'be short; short', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kápyagəkápyaga', english: 'word that describes how a foolish man moves, especially into trouble', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'káyé', english: 'little, small', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'kibu\'ləkibu\'lə', english: 'sound of movement by a fat person; word describing the way of movement by a person who is very fat', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'kóghá', english: 'a piece of rough iron used for sharpening metals eg matchetes and knifes', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwed ndotîa', english: 'empty garbage, throw away dirt', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyíbó', english: 'a kind of basket weaved using the hard covering of raffia bamboo', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyikâ', english: '(of babies) have the habit of refusing strangers; refuse, of many people', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóŋ', english: 'intensifies the idea that something is very black', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'mǎ pətǎ pətǎ', english: 'great grandmother (paternal)', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ma\'ô kəghoghə', english: 'give much importance to something, especially more than it is due', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi pəkwûə', english: 'abode of the dead', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mboŋô', english: 'many, much, a lot', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé', english: 'big, great, important', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé asóolə', english: 'big hoe', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé nkeelə', english: 'big drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məchína nəka\'á', english: 'being together', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məfóomə', english: 'fat', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'mətsəŋkeela', english: 'be globe shaped, be spherical; be round', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'mó kányaŋə', english: 'little; small', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó nkeelə', english: 'small drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'môkamə', english: 'A dance group in Njom. Only young men participate', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndɔ́', english: 'real, true', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'ndǎndɔ́', english: 'real, true', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'nə', english: 'marker of past tense for an event that took place a few days ago', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'nəfoonə', english: 'fat', category: 'descriptive'),
  AwingWord(awing: 'nəkólə', english: 'quarter or small unit of administration', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsog nó akwubə', english: 'bath room or any shade for bathing', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəténə', english: 'bottom; below', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkéebə', english: 'rich person', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngoŋə', english: 'sharp wail, ululation at funeral(n)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ngwəshíə', english: 'loincloth of some sort worn in the olden days, especially old women', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'njúbtə', english: 'dry. Dry corn is good for popping', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkya\'ə', english: 'light; electricity', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'nóolə akəfə́', english: 'green mamba', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nta\'lə', english: 'few, small number', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ntsêdndzəmə', english: 'last, final', category: 'descriptive', tonePattern: 'falling'),
  AwingWord(awing: 'ntsəmə', english: 'whole, total', category: 'descriptive'),
  AwingWord(awing: 'ŋá\' nkwumə', english: 'open (box)', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'panpaŋə', english: 'red', category: 'descriptive'),
  AwingWord(awing: 'pêsê', english: 'demon; evil spirit', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pá əshí\'á', english: 'how many?', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pətsá', english: 'attribute \'some\', modifying classes 2 and 8 nouns', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sagə', english: 'far; be long', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'senô', english: 'today', category: 'descriptive', tonePattern: 'falling'),
  AwingWord(awing: 'shí ŋwunə', english: 'black man', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shíshí ŋwunə', english: 'black man', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tä pətä pətä', english: 'great grandfather (paternal)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'tä pətä yi ndza\'kə', english: 'great great grandfather (paternal)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'tä\'lətä\'lə', english: 'word that describes how a sickly lean person moves', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'təji\'ə', english: 'alone', category: 'descriptive'),
  AwingWord(awing: 'təpəŋə', english: 'evil', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'táshúnə', english: 'so much, too much', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tû\'mândzəŋə', english: 'a secret group for men of same age group', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tséebə ndəŋndəŋə́', english: 'be honest; speak the truth', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsənkeelə', english: 'round; globe shaped, spherical', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'wiŋə', english: 'big; great', category: 'descriptive', difficulty: 2),

  // things (1117)
  AwingWord(awing: 'a', english: 'he, she (personal pronoun)', category: 'things'),
  AwingWord(awing: 'achábtə', english: 'dirt built up in layers on a surface, animal or body', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achánə', english: 'act of turning away from somebody in disgust', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'acha\'tə', english: 'greetings', category: 'things', difficulty: 2),
  AwingWord(awing: 'acha\'tésê', english: 'prayers', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'acha\'tésênjiə', english: 'fasting; intensive and serious prayer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'achəkelə', english: 'sieve', category: 'things', difficulty: 2),
  AwingWord(awing: 'achibamátéenə', english: 'cheap and undesirable products or goods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achíalúmə', english: 'name of a quarter in Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achiətazó\'ə', english: 'celibate, unmarried for religious reasons', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achílə ajúmə', english: 'stopper; plug', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achwí\'nə', english: 'unity, togetherness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afablə', english: 'fastidiousness', category: 'things', difficulty: 2),
  AwingWord(awing: 'afa\'ə', english: 'work', category: 'things', difficulty: 2),
  AwingWord(awing: 'afa\'ə apímnə', english: 'partnership work', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afa\'ə Əsê', english: 'religious ministry, work for God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'afanə', english: 'terrible thing; taboo', category: 'things', difficulty: 3),
  AwingWord(awing: 'afankónuə', english: 'mistake', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'afaŋŋə', english: 'embrace', category: 'things', difficulty: 2),
  AwingWord(awing: 'afeŋə', english: 'wasp', category: 'things', difficulty: 2),
  AwingWord(awing: 'afəələ', english: 'water tube used for letting water into the bowels', category: 'things', difficulty: 2),
  AwingWord(awing: 'afəələ neemə', english: 'female pig that has passed the stage of crossing', category: 'things', difficulty: 2),
  AwingWord(awing: 'afəmó', english: 'land where forefathers settled and lived', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afìə', english: 'resemblance, look very much alike', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'afi\'nónkaŋə', english: 'imitation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afo\'ə', english: 'material gain or riches', category: 'things', difficulty: 2),
  AwingWord(awing: 'afoonə ndzo\'ó', english: 'ceremony in which the bride and groom are shaved of private parts', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə atìə', english: 'one thousand francs CFA note (colloquial)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə fóolə', english: 'rat poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə məmbəmə', english: 'tablets, drugs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə ndí\'ə', english: 'antidote, anti-poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afunə', english: 'restlessness', category: 'things', difficulty: 2),
  AwingWord(awing: 'afunó', english: 'leopard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghabnə', english: 'average', category: 'things', difficulty: 2),
  AwingWord(awing: 'aghaglə', english: 'skeleton', category: 'things', difficulty: 2),
  AwingWord(awing: 'aghaglótûə', english: 'skull', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aghántə', english: 'physical exercise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'agheemə', english: 'sorcery, fortune telling, spiritism', category: 'things', difficulty: 2),
  AwingWord(awing: 'aghə\'ə', english: 'frugality', category: 'things', difficulty: 2),
  AwingWord(awing: 'agha\'ó', english: 'cave', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəŋə nəságə', english: 'pudenda', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghognə', english: 'shock, trembling; fear', category: 'things', difficulty: 2),
  AwingWord(awing: 'aghóoba', english: 'fear, trembling on hearing of death', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghoolá atûa', english: 'dowry', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aghoonó', english: 'illness, disease, malady', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghoonó móghaba', english: 'sexually transmissible disease', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'aghoonó tapəŋə', english: 'diseases contracted through sex', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'agho\'tánó', english: 'pride, considering one\'s self special or more important', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghógta', english: 'rattle (musical instrument)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghô\'ka', english: 'vomit (noun)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ajá\'ka', english: 'vomit (noun)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajía', english: 'his/hers, used for class 7 nouns (possessive)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajiəmbágló', english: 'corruption', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajíənuə', english: 'knowledge; know how; meaning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajíəŋwa\'lə', english: 'literacy; the knowledge to read and write', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aji\'tə', english: 'frugality, selfishness', category: 'things', difficulty: 2),
  AwingWord(awing: 'ajú yə pá\' nə', english: 'wickerwork', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajú yə sá nə', english: 'garri (food made from cassava)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajú yitsə', english: 'something (pronoun)', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajuba', english: 'replica, carbon copy', category: 'things', difficulty: 2),
  AwingWord(awing: 'ajúmə əzələ', english: 'stolen goods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúmə nəkwa\'ə', english: 'play instrument, toy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúməsoolə', english: 'domestic animal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúmətsə\'ə', english: 'handkerchief, piece of cloth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwa\'áli\'ó', english: 'disappointment', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajwelə', english: 'vapour', category: 'things', difficulty: 2),
  AwingWord(awing: 'ajwiə Əsê', english: 'the spirit of God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ajwika', english: 'window', category: 'things', difficulty: 2),
  AwingWord(awing: 'ajwiŋə', english: 'link; something that links two things', category: 'things', difficulty: 2),
  AwingWord(awing: 'aka\'nə', english: 'competition', category: 'things', difficulty: 2),
  AwingWord(awing: 'akán yə shí nə', english: 'bowl', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'akáŋəsê', english: 'church offering (money or material)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akáŋətûə', english: 'helmet', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'akeelə', english: 'fence, usually of wood', category: 'things', difficulty: 2),
  AwingWord(awing: 'akeelə kwúneemə', english: 'pig sty', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akéenə', english: 'tiredness, fatigue', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akô', english: 'what (interrogative pronoun)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'akóbka', english: 'covering (of door, cupboard, car, hut, blanket etc.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəghoolə', english: 'intestinal worm', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəghoolámagə', english: 'conjunctivitis', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəkógó', english: 'fool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmə', english: 'piece, half (of liquids, objects etc.)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəmə ajúmə', english: 'splinter, sliver', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmə aŋwa\'lə', english: 'note(n), piece of writing', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəmə tsáb ntê', english: 'introduction, preamble', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akəmə mbaŋə', english: 'throwing stick', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəmtə', english: 'stage, phase; round; chapter (of a book)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəŋə', english: 'covering of door, cupboard, car; something that screens', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəpu\'ə', english: 'fit; fainting fit', category: 'things', difficulty: 2),
  AwingWord(awing: 'akətûə', english: 'deaf person', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə ləəmó', english: 'colt (young horse)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə nkeelə', english: 'medium sized drum', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ako\'nə ndəŋə', english: 'bamboo chair', category: 'things', difficulty: 2),
  AwingWord(awing: 'akóolámáləŋə', english: 'grace, pity', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoolənányinə', english: 'companionship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ə', english: 'chair; throne; high office; position', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ə ndəŋə', english: 'bamboo chair', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ndê', english: 'threshold, doorstep', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akô\'kámbəəmə', english: 'fastidiousness, pride; considering one\'s self special', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akoŋə', english: 'stem, stalk (of maize, millet etc.)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoŋŋə', english: 'love, happiness, bliss of wedded couples', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoŋŋəshîə', english: 'romantic love', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akoŋtə', english: 'rejoicing; festival; feast', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwáakə', english: 'inflammables; something that keeps fire burning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwáalónkǐə', english: 'baptism', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akwagə', english: 'phlegm', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwagəntəəmə', english: 'asthmatic cough', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwagətəəmə', english: 'whooping cough', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwagətəfélə', english: 'whooping cough', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwa\'lə', english: 'question; temptation; criticism; interview', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋ yə əshi\'nə', english: 'confidence, good thoughts', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋə', english: 'idea; thought; pensiveness (especially negative)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋónuə', english: 'reasoning; idea; thought', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwaŋəsê', english: 'God\'s will', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwaŋətûə', english: 'thought; idea', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwelə', english: 'prostitute, whore', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwelə mbéŋə', english: 'flock (of sheep, goats etc.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwelə məneemə', english: 'herd of cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwelə sóŋó', english: 'crop of bird', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwenə', english: 'collaboration', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwəŋótûə', english: 'skull', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubə', english: 'crust, skin (of fruit)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwubə əshûə', english: 'fish-scale', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubə môndzó', english: 'shell (of groundnut)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubánô', english: 'flesh, of a living person', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwúblə', english: 'equivalence; something to exchange or replace with; replacement', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwûə', english: 'corpse, carcass', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwu\'ló', english: 'log', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwúláshîə', english: 'frown (noun)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwúmtə', english: 'ceremony in memory of somebody who died; remembrance; reminder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyâamə', english: 'bile, gall', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akya\'óshîə', english: 'mirror (noun)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akye\'ónuə', english: 'omen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyé', english: 'jungle dweller (wicked); men living in forest attacking passers-by for money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alabó', english: 'cloth, tied by women', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə pəŋwiŋə', english: 'spirit world, world of the gods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əkálá', english: 'Europe or America', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əmákálá', english: 'Europe or America', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əmátíə', english: 'name of a quarter in Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alagó', english: 'scar', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alamó', english: 'body part', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋnəkyîə', english: 'channel', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alaŋəpópó\'ə', english: 'public toilet', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alě atsəmə', english: 'everyday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě tsə', english: 'someday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě Yésojúmnə nə nəwûə', english: 'Easter Sunday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aleelá', english: 'trouble', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleemə', english: 'smithing', category: 'things', difficulty: 2),
  AwingWord(awing: 'aleeməmósóŋó', english: 'birdlime (adhesive to catch birds)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alegtə', english: 'flattery', category: 'things', difficulty: 2),
  AwingWord(awing: 'alegtəntəəmə', english: 'comfort, petting', category: 'things', difficulty: 2),
  AwingWord(awing: 'aléjúmə', english: 'lust (noun); strong desire', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alenápíná', english: 'birthday', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleŋ', english: 'incense', category: 'things'),
  AwingWord(awing: 'aleŋkə', english: 'mark of identification; ritual scar', category: 'things', difficulty: 2),
  AwingWord(awing: 'alědnə', english: 'wealth, property', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alógámáfûə', english: 'sickle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aləgnə', english: 'forgetfulness', category: 'things', difficulty: 2),
  AwingWord(awing: 'alámbeŋə', english: 'talking drum', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləmtə', english: 'whisper', category: 'things', difficulty: 2),
  AwingWord(awing: 'alóŋə', english: 'disease of the scalp (sticky in nature)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləŋəlóŋənófoonə', english: 'praying mantis', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləŋəmóonə', english: 'womb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləŋənófoonáse', english: 'God\'s throne, God\'s presence', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' ghenó', english: 'here', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' yə áwó', english: 'there (place that is the subject of conversation)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' yîə', english: 'there (that place)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ó', english: 'place; point', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ó ghók\'ə Əsê', english: 'sanctuary; place of worship', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ó kətaŋə', english: 'emptiness, nothing, void', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ó nəfoonə Əsê', english: 'paradise', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ali\'ófûə', english: 'traditional hospital, mostly to consult mediums', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ófya\'ónuə', english: 'ritual place', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'óká', english: 'where (inter.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmáfênə', english: 'alter', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'əmápa\'ó', english: 'toilet, WC', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmáteenó', english: 'shop', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmátsəŋnə', english: 'latrine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ándəsê', english: 'land', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ənəfoonásê', english: 'throne of God, God\'s presence', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'əsê', english: 'a place thought to host a god tree or cave', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ətəŋwunə', english: 'desolate or vocant place', category: 'things', difficulty: 2),
  AwingWord(awing: 'ali\'ətəpímnə', english: 'disunited place or neighbourhood', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ətûə', english: 'very close friend', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ətwíəleemə', english: 'forge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'átsêebə', english: 'statement, comment', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'átsəmə', english: 'Everywhere; anywhere', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóobə', english: 'cunning; deceit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóbtə', english: 'plan; estimation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alo\'ə', english: 'deformity; curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'alónə', english: 'begging', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alubə', english: 'drasina', category: 'things', difficulty: 2),
  AwingWord(awing: 'alúə', english: 'goose', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alu\'á', english: 'lumbago (muscular pain of the lumbar regions, of an illness)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alwaalə', english: 'palate', category: 'things', difficulty: 2),
  AwingWord(awing: 'alwe', english: 'filaria', category: 'things', difficulty: 2),
  AwingWord(awing: 'alya\'ə', english: 'description', category: 'things', difficulty: 2),
  AwingWord(awing: 'ama\'ə', english: 'gift, especially to a customer to encourage him', category: 'things', difficulty: 2),
  AwingWord(awing: 'ambeenə', english: 'abscess', category: 'things', difficulty: 2),
  AwingWord(awing: 'ambáŋá', english: 'a flip over', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ambo\'ə', english: 'elephantiasis', category: 'things', difficulty: 2),
  AwingWord(awing: 'amɨ\'ə', english: 'dew', category: 'things', difficulty: 2),
  AwingWord(awing: 'ándó', english: 'approximately; like, as', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ándó móonə', english: 'childishly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəələ', english: 'dedication, presentation', category: 'things'),
  AwingWord(awing: 'anəəlághoonə', english: 'symptom of disease', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəəlámbəəmə', english: 'pride', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəmá', english: 'louse', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəné', english: 'Money of the smallest value', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ánónə', english: 'exactly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'antsĕ', english: 'whistle for refereeing a football match', category: 'things', difficulty: 2),
  AwingWord(awing: 'anuə', english: 'something; concern', category: 'things', difficulty: 2),
  AwingWord(awing: 'anuə əshunə', english: 'partnership', category: 'things', difficulty: 2),
  AwingWord(awing: 'anuə nəfoonə', english: 'kingdom of', category: 'things'),
  AwingWord(awing: 'anuə ŋwu ntsəmə', english: 'event that involves everybody', category: 'things', difficulty: 2),
  AwingWord(awing: 'anuəməghabə', english: 'adultery', category: 'things'),
  AwingWord(awing: 'anüəngi\'tə', english: 'something urgent', category: 'things'),
  AwingWord(awing: 'anuəsê', english: 'christianity; religion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'anuətájiə', english: 'mystery', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'anuətámə', english: 'habit', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'anuyəfíə', english: 'fashion', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anyaŋgá', english: 'decoration, embellishment', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anyiŋə', english: 'claw', category: 'things', difficulty: 2),
  AwingWord(awing: 'anyiŋə apô', english: 'fingernail. A finger nail beautifies somebody', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'anyíŋnə', english: 'emotional instability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anatə', english: 'pride', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋkə\'á', english: 'rooster; cock', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkəndó\'á', english: 'galore, medal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkənu\'á', english: 'canoe', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkəŋâ', english: 'dove', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aŋkoomə', english: 'ram', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋkódtə', english: 'prostitute', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkwə', english: 'semen, sperm, male fertilisation fluid', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋo\'tə', english: 'frugality', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋwa\'lə', english: 'book; knowledge', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋwa\'lósê', english: 'scripture; bible', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apádnə', english: 'acquaintance', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apadtəmóonə', english: 'baby sling', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apa\'ándê', english: 'door', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apagó atsə\'ó', english: 'a piece of cloth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apanə', english: 'hook', category: 'things', difficulty: 2),
  AwingWord(awing: 'ape', english: 'profit', category: 'things', difficulty: 2),
  AwingWord(awing: 'ape\'ə', english: 'load, burden, belongings', category: 'things', difficulty: 2),
  AwingWord(awing: 'apeŋə', english: 'outside', category: 'things', difficulty: 2),
  AwingWord(awing: 'apélə', english: 'pit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apélə nkɨə', english: 'waterhole, fountain or any hole that gushes out water; well', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apenə', english: 'scar', category: 'things', difficulty: 2),
  AwingWord(awing: 'apəabə', english: 'he-goat, billy goat', category: 'things', difficulty: 2),
  AwingWord(awing: 'apəəmə', english: 'hunt', category: 'things', difficulty: 2),
  AwingWord(awing: 'apimnə', english: 'agreement', category: 'things', difficulty: 2),
  AwingWord(awing: 'apinə', english: 'curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'apitə', english: 'request, question', category: 'things', difficulty: 2),
  AwingWord(awing: 'apitə atsêebə', english: 'question', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apó\'ámbó', english: 'supplication, plea', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'apó\'ámóonə', english: 'circumcision (male). Circumcision is no longer an acceptable thing in the world today', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apoomə', english: 'covering (especially of leaves or clothing) against the sun, rain or destruction', category: 'things', difficulty: 2),
  AwingWord(awing: 'apógə', english: 'fear', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apəŋəntəəmə', english: 'Grace; pity', category: 'things', difficulty: 2),
  AwingWord(awing: 'apəŋətûə', english: 'luck, fortune', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'apu\'ə', english: 'left over', category: 'things', difficulty: 2),
  AwingWord(awing: 'apúmnə', english: 'worry, restlessness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apútə', english: 'complaint, especially in court', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asá\'ə', english: 'command', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asá\'ónuə', english: 'announcement, public announcement (usually in the market)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asagó', english: 'wall, of a house', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asagándê', english: 'wall, of a house', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asaŋó', english: 'tail', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aseelósêela', english: 'sideward', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aseemə', english: 'a site where mushrooms grow', category: 'things', difficulty: 2),
  AwingWord(awing: 'asədkátsêebə', english: 'translation. It is good to know how to translate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asêkátsə\'ó', english: 'rag. A rag is used to clean a cemented floor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asəələkwúneemə', english: 'a castrated pig', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəkə', english: 'exageration, giving of false value', category: 'things', difficulty: 2),
  AwingWord(awing: 'asəmə', english: 'swarm', category: 'things', difficulty: 2),
  AwingWord(awing: 'asogəmáyéŋ', english: 'wild beast (used as an insult)', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'asóŋətəfa\'ə', english: 'hypocrite, pretentious person', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asobnə', english: 'worry, sadness', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashaabə', english: 'comb', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashǎdnə akáŋə', english: 'plate. A plate is not good for dishing soup', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ashi\'nə', english: 'trade. People trade food when they do not have money to buy it', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashwadkə', english: 'exageration, giving of false value', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashwěnuə', english: 'a failure, a missed opportunity. This act is really a failure', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ashwí\'ə', english: 'swelling', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atálə', english: 'a courtyard in the palace where the fon sits with his subjects to debate issues', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atáŋə', english: 'mathematical problem, mathematical sum', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ataŋmóonə', english: 'a disease that makes babies to grow pale', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atáŋkə mbəəmə', english: 'wrinkle (on skin); wrinkled skin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atéemə', english: 'dangerous pit or hole', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aténkə', english: 'support', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atəələ', english: 'pride', category: 'things', difficulty: 2),
  AwingWord(awing: 'atəəmə', english: 'calabash', category: 'things', difficulty: 2),
  AwingWord(awing: 'atəəməndólə', english: 'prostitute', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atəənə', english: 'iron; trap (usually made of iron or metal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'atandó\'ə', english: 'ball. Apise plays football', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atashiə', english: 'thread', category: 'things', difficulty: 2),
  AwingWord(awing: 'atátá', english: 'courtyard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atata\'ə', english: 'snail', category: 'things', difficulty: 2),
  AwingWord(awing: 'atatsələ', english: 'insect', category: 'things', difficulty: 2),
  AwingWord(awing: 'atɨə', english: 'above, up', category: 'things', difficulty: 3),
  AwingWord(awing: 'atɨə awaglə', english: 'a boundary stick', category: 'things', difficulty: 2),
  AwingWord(awing: 'atɨəpéŋá', english: 'second floor of a roof. Awing people dry corn on the second floor of the roof', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ató\'nónkonə', english: 'hump (of hunchback). The hunchback of cattle is very tasty', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atoŋátóŋə', english: 'upside down', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atóonə', english: 'impatience', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atógə', english: 'room', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atógə əkwunə', english: 'bedroom. The bedroom is private', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atómtə', english: 'reason; justification', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'nə', english: 'prophecy', category: 'things', difficulty: 2),
  AwingWord(awing: 'atú yə júm ná', english: 'wakefulness, alertness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə ŋa\'nə ná', english: 'intelligence, high learning ability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə pó\' ná', english: 'headache. Headache is frequent in the dry season', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə tsə́\'nə ná', english: 'intelligence, high learning ability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəfa\'ə', english: 'occupation, job', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəndê', english: 'roof of a house. The most important thing for the roof of a house is the zinc', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atúənápe', english: 'side pain. Side pain is an illness of elderly people', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúənósénə', english: 'frontal headache. frontal headache causes blood to flow from one\'s nose', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə amú\'á', english: 'regime (of banana). A regime of banana is much cheaper in Awing than in all other places', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ənákəŋə', english: 'clay. Clay is sticky', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsámnə', english: 'sigh', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'atsá\'nə', english: 'greed', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsaŋá', english: 'stem, of banana', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebə', english: 'language; word', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebámakálə', english: 'English language', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebámənŋeemə', english: 'joke, play talk', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebándzəmándzəmə', english: 'gossip', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánákwa\'ə', english: 'joke, humour', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánámú\'á', english: 'parable; proverb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebápəfipámbô', english: 'sign language', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atséebásê', english: 'gospel; word of God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atseŋə', english: 'bladder', category: 'things', difficulty: 2),
  AwingWord(awing: 'atselə', english: 'peg', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsa\'á', english: 'clothes', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'á mako\'ná', english: 'shirt. Shirts are usually worn by men', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsə\'kə', english: 'criticism, the act of deminishing the value of something, the act of making something appear less important', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsəmə', english: 'whichever. Bring whichever you like', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsəmətsəmə', english: 'total. The total is what', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsóobə', english: 'fine or levy for commiting a crime', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsóokámbəəmə', english: 'humility', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awaamə', english: 'handle', category: 'things', difficulty: 2),
  AwingWord(awing: 'awaamámbəəmə', english: 'self control; patience', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awaamətəmedtə', english: 'faithful person; patient person', category: 'things', difficulty: 2),
  AwingWord(awing: 'awágə', english: 'a belittling; mockery', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awágnə', english: 'carelessness, neglect', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awakántəəmə', english: 'loose and shameless behaviour', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awé\'ə', english: 'curse', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'awelə', english: 'mixture', category: 'things', difficulty: 2),
  AwingWord(awing: 'awelówelə', english: 'assorted, variety', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awěnkɨə', english: 'A women dance group in Akuhle quarter, based in Tata Mofolo\'s compound', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'awəgə', english: 'bellow', category: 'things', difficulty: 2),
  AwingWord(awing: 'awəgáfágə', english: 'fan. A fan is necessary when there is heat', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awə́\'tə', english: 'reminder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awuəmátéenə', english: 'something in less demand or cheap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awüənuə', english: 'mistake, fault', category: 'things', difficulty: 2),
  AwingWord(awing: 'awǔ\'nə', english: 'covering for anything', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ayè\'tə', english: 'frugality', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ayéékálí\'ó', english: 'disturbance, disorder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ayéelə', english: 'confusion, disorder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ayélə', english: 'exclamation, surprise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azagá', english: 'odour, smell', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋándé', english: 'anger', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋkómbəəmə', english: 'physical exercise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azéemə', english: 'possessive pronoun \'mine\', used for class 7 nouns. Where is my own plum?', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azénə', english: 'possessive pronoun \'ours\' used for nouns of class 7', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azə́ənə', english: 'possessive plural pronoun \'yours\' used for class 7 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azú\'kə', english: 'surty, guarantee', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azəŋtə', english: 'imbecile, fool, stupid person', category: 'things', difficulty: 2),
  AwingWord(awing: 'azó', english: 'possessive singular pronoun \'yours\' used for class 7 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'ámakálá', english: 'mbecile, fool, stupid person. A sort of yam that originated from Ibo land in Nigeria', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azoŋə', english: 'junior', category: 'things', difficulty: 2),
  AwingWord(awing: 'azoobə', english: 'song, singing', category: 'things', difficulty: 2),
  AwingWord(awing: 'azoomə', english: 'plum', category: 'things', difficulty: 2),
  AwingWord(awing: 'azəgə', english: 'Lie that is told with a lot of passion and without remorse', category: 'things', difficulty: 2),
  AwingWord(awing: 'azəŋə', english: 'argument, disunity', category: 'things', difficulty: 2),
  AwingWord(awing: 'bâ', english: 'bar. Some people stay in the bar for the whole day', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'báabəələ', english: 'Bible or the word of God. The word of God is called a Bible', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bǎbtísə', english: 'baptist, refering to a christian denomination and also to those who belong to it', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'bándéchə', english: 'bandage', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'báŋə', english: 'bank. A bank is a place where we keep money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bəláibə', english: 'bribe', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bəlégə', english: 'break. All school children take break period', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bôm', english: 'sound that describes a start or sudden wake up', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'bîm', english: 'sound that describes something that is fall. When a fat person falls on the ground, he falls thump', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'bíshobə', english: 'bishop. A bishop is a high ranking person in the church', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bílɨ', english: 'sound of movement by a group or herd of cattle', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'blêmə', english: 'blame', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'bóbə', english: 'bulb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bólə', english: 'ball', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bûm', english: 'word that intensifies the sound of a traditionally made gun, or of something falling', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'búsbágə', english: 'hump (of cow). The hump (of cow) is a choiced morsel', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'châgchagchag', english: 'sound (word) that describes the dropping of water', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'cha\'tə̂ nəwûə', english: 'condole, comfort', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'cha\'tásê', english: 'pray. Pray, if you want to succeed in all your endeavours', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chê\'', english: 'sound (word) that intensifies the smooth or oily nature of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'chî kókánə́', english: 'be unhealthy, be sick; be uncomfortable', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîı', english: 'marker of negation. If a man does not marry, he is called a bachelor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə natûə', english: 'rule over, dominate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chígchəgchígchəg', english: 'sound (word) that tells how a bird cries', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chigə nó ndəlá', english: 'exactly on time', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chipó\'ə́', english: 'mute, less excited person, too calm a person', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chí\'tôglə', english: 'fungi, eaten as food', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chɔ́gə', english: 'chalk', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chɔ́sə mbəláló\'ə́', english: 'islam; mosque', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chuchuə', english: 'gossip', category: 'things'),
  AwingWord(awing: 'chúu', english: 'intensifies the smelling nature of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwántə́ nkiə', english: 'brook, stream', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwî\'', english: 'sound (word) that intensifies the bitterness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'chwíŋ', english: 'sound (word) that intensifies the sourness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwí\'túə', english: 'cooperate; share ideas', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ě', english: 'utterance that indicates that one has been making a mistake', category: 'things', tonePattern: 'rising', difficulty: 3),
  AwingWord(awing: 'élə', english: 'aids', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ə́', english: 'they, it, thing in question or talked about', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ə̂\'ə', english: 'no', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfag ndúmə', english: 'fork (in path)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ', english: 'in this compound, this place, here (nominal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfeŋ məlá\'ə', english: 'roofer of thatched houses', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋə', english: 'roofer of thatched houses', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfê', english: 'giver', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndê', english: 'the secret meaning behind something', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndê atseebə', english: 'speech with lots of terminology', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndzɔ\'ə', english: 'divorcee', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfelə', english: 'appearance', category: 'things'),
  AwingWord(awing: 'əfəblə', english: 'lungs, especially of animals', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfəənə́', english: 'shin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəmá', english: 'mold', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəŋə́', english: 'a hole on the body caused by accident or illness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfi məjîə', english: 'restaurant dealer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfi ndasê', english: 'real estate agent; somebody who sells land', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfi ngɔŋə', english: 'traitor', category: 'things', difficulty: 2),
  AwingWord(awing: 'Əfo Akófo', english: 'the ninth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Alôndzá I', english: 'fourth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Alôndzá II', english: 'the eighth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ayáfo', english: 'the eleventh fon of Awing (disappeared 1950)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Əfoozó I', english: 'the tenth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Əfoozó II', english: 'the thirteenth fon of Awing (enthroned 4th may 1998)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Məfumánəngoomá', english: 'the second fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfo najîa', english: 'glutton, heavy eater', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' I', english: 'third fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' II', english: 'the sixth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' III', english: 'the twelfth fon of Awing (1950 to 1998)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Nká\'ŋngwé', english: 'the fifth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Nká\'fo', english: 'the seventh fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfó\'ə', english: 'gutter, deep place or thing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfóŋə', english: 'reader or somebody who reads', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfoonpalê', english: 'somebody with a sleep addiction', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfoontó\'ə', english: 'name of the fon, used only by the young and unmarried', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfoopəfo', english: 'sovereign; almighty', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfúkéelə', english: 'anus', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfwoŋə', english: 'ox', category: 'things', difficulty: 2),
  AwingWord(awing: 'əghâ akə', english: 'when?, what time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ atsəmə', english: 'always', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ aghâ', english: 'irregularly; from time to time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ ghená', english: 'now', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ nda\'ə', english: 'another time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ njia', english: 'time of famine', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ pipó ní nó', english: 'often, most of the time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ wá\'ó', english: 'time of famine', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yi wá', english: 'then, that moment', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yîə', english: 'later, in the near future (limited to a day)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yitsə̌', english: 'sometimes', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əghəənə', english: 'friendship', category: 'things', difficulty: 2),
  AwingWord(awing: 'əghəmə', english: 'fig (tree)', category: 'things', difficulty: 2),
  AwingWord(awing: 'əgho', english: 'possessive pronoun yours (used for nouns of class 3)', category: 'things', difficulty: 2),
  AwingWord(awing: 'əghoobá', english: 'possessive pronoun \'theirs\' used for class 1 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əghə̂', english: 'reflexive pronoun ours (exclusive). Used specifically for class 3 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əjîə', english: 'possessive pronoun his/hers (used for nouns of class 9)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əkeelə', english: 'frugality, stinginess, a desire not to share', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkeenə', english: 'oath; covenant', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkəəbə', english: 'cain; indian bamboo ropes', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkəkə́\'lápúmə', english: 'trash; scrap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkəmə́', english: 'nobleship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkiə', english: 'gizzard, considered to belong to elders or the head of the family whenever a fowl is killed for a meal', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkogə́', english: 'widowhood', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkwubə', english: 'frugality', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkwuná', english: 'bed', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ə́lá ndê', english: 'wall of a house', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ólé', english: 'how? (interrogative)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əleló', english: 'beard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlénə', english: 'name; reputation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əléna ajúmə', english: 'noun', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá jum nó', english: 'drought, famine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá nwa\' nó', english: 'daylight', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlimə́ afa\'ə', english: 'working relationship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ələŋə', english: 'laziness', category: 'things', difficulty: 2),
  AwingWord(awing: 'əma\' pó\'ə', english: 'story teller', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ənáŋnə majîə', english: 'cook', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ənoonə', english: 'crowd', category: 'things', difficulty: 2),
  AwingWord(awing: 'ənɔ̌ fúto', english: 'photographer', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ənu kətaŋə', english: 'meaningless thing; useless idea', category: 'things', difficulty: 2),
  AwingWord(awing: 'əŋǎ\'pilô', english: 'giant; boaster', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əŋwa\'lə əŋwa\'lə', english: 'secretary, typist', category: 'things', difficulty: 2),
  AwingWord(awing: 'əŋwa\'lə nkeebə', english: 'treasurer; accountant', category: 'things', difficulty: 2),
  AwingWord(awing: 'əpəgpúmə', english: 'scrap; metal waste', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpénə', english: 'possessive adjective ours (inclusive). Used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpééná', english: 'possessive plural adjective \'yours\', used for nouns of class 8', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpiə', english: 'possessive adjective his/hers, used for nouns of class 8', category: 'things', difficulty: 2),
  AwingWord(awing: 'əpô', english: 'possessive singular pronoun yours, used for nouns of class 8', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpóobá', english: 'possessive adjective theirs, used for nouns of class 8', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpoŋə', english: 'goodness', category: 'things', difficulty: 2),
  AwingWord(awing: 'əpûmbîə', english: 'wealth, worldly things', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpúmáfa\'ə', english: 'scaffolding', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpúmógə', english: 'looking glasses', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'əpûngɔŋə', english: 'common property; public property', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpûntéelə', english: 'Lord\'s Supper article', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpûtsəmə', english: 'everything', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əsa\'ə', english: 'shoot', category: 'things', difficulty: 2),
  AwingWord(awing: 'əsá\'mánumə', english: 'east; sunrise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsəpó\'á', english: 'something that is cheap or free of charge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsê', english: 'god; fetish (spirit)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əsê nəpóolə', english: 'God (the one who has created everything on earth); supreme being', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əséenə', english: 'crevice', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsenə́', english: 'venom (of snake), stinger', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsəənə', english: 'shame', category: 'things', difficulty: 2),
  AwingWord(awing: 'əsóomə', english: 'destruction that springs from jealousy, envy, or simply an evil heart, ill-will', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsoŋ nkadtə', english: 'spine, backbone', category: 'things', difficulty: 2),
  AwingWord(awing: 'əshîə', english: 'appearance', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'əshí\'nə', english: '1) goodness, kindness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əshúmə̌fágə', english: 'mudfish', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əshwáŋə', english: 'track (of animal)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ətéelə', english: 'a sort of mushroom', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwə', english: 'who?', category: 'things', difficulty: 2),
  AwingWord(awing: 'əwəənə́', english: 'possessive pronoun \'yours\', used to modify nouns of class 1', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwəgə́', english: 'possessive pronoun \'ours\' used for class 1 nouns; possessive adj \'our\' used for class 1 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwágó', english: 'possessive pronoun \'ours\' used for class 3 nouns; possessive adj \'our\' used for class 3 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əyîə', english: 'possessive pronoun \'hers\' used for class 1 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əzeemə', english: 'possessive pronoun \'mine\' used for class 9 nouns', category: 'things', difficulty: 2),
  AwingWord(awing: 'əzəəná', english: 'yours (pl)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzəgá', english: 'possessive pronoun \'ours\' used for nouns of class 9; possessive adj \'our\' used for nouns of class 9', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzələ', english: 'theft', category: 'things', difficulty: 2),
  AwingWord(awing: 'əzo', english: 'possessive singular pronoun \'yours\' used for class 9 nouns', category: 'things', difficulty: 2),
  AwingWord(awing: 'əzoobá', english: 'possessive pronoun \'theirs\' used for class 9 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzooná', english: 'yesterday', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'fê atsámə', english: 'punish. A person is only punished when he does something wrong', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fê mbwódnə', english: 'bless. If God is pleased with somebody, he gives him peace', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fê ndǎ', english: 'congratulate. People should learn to say \'thank you\'', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'féenkǐə', english: 'baptise', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'felə', english: 'breastbone', category: 'things', difficulty: 2),
  AwingWord(awing: 'felə ali\'ó', english: 'move away, migrate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fágəndi\'ə', english: 'antidote, anti-poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Fəlénchə', english: 'French. People who live in Douala speak French', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəŋ', english: 'sound (word) reinforcing an act of acceptance that is done without any thought or interest', category: 'things', difficulty: 3),
  AwingWord(awing: 'fig mbəəmə', english: 'pretend. A person decieves himself thinking that he has decieved somebody else', category: 'things', difficulty: 2),
  AwingWord(awing: 'fógə təpəŋə', english: 'exorcise. Evil cannot be used to ward off evil', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fôo', english: 'sound (word) that describes a deep breath', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'fóolá', english: 'rat', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fu\' mbélə', english: 'dung beetle. Dung beetles are usually found in cow dung', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fwə\'ə', english: 'chisel', category: 'things', difficulty: 2),
  AwingWord(awing: 'fyaabə', english: 'a piece of stick or iron used for controling embers, also a piece of stick used for disposing of th harmful or unwanted', category: 'things', difficulty: 2),
  AwingWord(awing: 'fya\'ə̂ anuə', english: 'pour libation. People pour libation on the fourth day of the Awing week', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gélə', english: 'gate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gôlə', english: 'gold', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghâ', english: 'word used at the end of an expression to mark exclamation', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghen ná mbia', english: 'continue, go ahead', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghenə̂', english: 'demonstrative adjective \'this\' for nouns of classes one and three', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghenkə̂ ndəlá', english: 'waste time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghídntəŋə̂', english: 'hiccough', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghôo', english: 'sound (word) that describes something spilling on the ground', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'Íslələ', english: 'Israel (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jéntailə', english: 'gentile (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká ajúmə', english: 'nothing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká ŋwunə', english: 'nobody', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kánáda', english: 'women dance group (originally based in Tata Alota\'s compound, no longer active)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kě', english: 'marker of negation', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ká\' nəsoŋá', english: 'laugh in a wild manner', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəənə', english: 'whether, if', category: 'things', difficulty: 3),
  AwingWord(awing: 'kaghoghə', english: 'integrity, importance', category: 'things'),
  AwingWord(awing: 'kákáŋə́', english: 'poorly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəlo\'', english: 'sound that describes or intensifies the manner in which something falls', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəlo\'ko\'', english: 'sound that describes or intensifies the manner in which something falls', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəlɔ\'kɔ\'', english: 'sound that describes or intensifies the manner in which something is falling', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəmú\'ntəŋə', english: '(entry continues to next page)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kánáŋə́', english: 'chameleon', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ká\'tátíə', english: 'kingfisher (bird that makes a cutting sound on a tree)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káyé məŋgo\'ə', english: 'gravel', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ki', english: 'or, either', category: 'things', difficulty: 3),
  AwingWord(awing: 'kí mbi', english: 'again, once more', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kí\'ə', english: 'obstruction; obstruction', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíghálágháalə', english: 'butterfly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíghidghaabə', english: 'cartilage', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíkəm ŋwunə', english: 'dwarf', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíkəmə ajîə', english: 'shortsightedness (a shortsighted person is not different from a fool)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kílelónkaŋə̂', english: 'spider', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kíláglakəmósaŋə', english: 'gecko', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kimbó\'nkonə', english: 'zebra', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Klísto', english: 'Christ (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'klóbə', english: 'women dance group based in Tata Ngonyo\'s compound (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóŋ', english: 'ditch', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'kə\'', english: 'word that intensifies the hardness of something', category: 'things', difficulty: 3),
  AwingWord(awing: 'kó əpúmə', english: 'work wood (Afese\'s job is wood work)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'ó', english: 'ladder', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'kəŋ', english: 'intensifies the strongness of something (something is usually strong \'kong\')', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəŋ məŋkwâ\'lə', english: 'desert (nothing grows in a desert)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəŋ nəyeŋə', english: 'grassland (feeding ground for cattle)', category: 'things', difficulty: 2),
  AwingWord(awing: 'kəŋ yi njùbtə', english: 'desert', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'kótinə', english: 'cotton (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwá mbiə', english: 'lead; be first', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwákwá', english: 'a dance group in Tame Fonka\'s compound', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwâŋ', english: 'intensifies the cleanliness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'kwaŋ kákáŋə̂', english: 'hesitate (when an evil doer hesitates in his plans, it demonstrates the voice of God)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwêd', english: 'sound (word) that describes the immediacy with which a stop is made', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'kwə\'ə̂', english: 'namesake', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'kwíŋə mə́ ŋwíŋə', english: 'sharpen a knife', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwud nká\'ə', english: 'build a fence', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúlə akálé', english: 'dress smartly, dress in nice fitting attires', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'láalé', english: 'jigger', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'laŋkô ndelô', english: 'entertain, amuse', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'légə á ndu mbumá', english: 'incubate, set on eggs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lə', english: 'but', category: 'things', difficulty: 3),
  AwingWord(awing: 'ləba', english: 'rubber', category: 'things'),
  AwingWord(awing: 'ləəmó koŋ yi njùbtə', english: 'camel', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləg əkeenə', english: 'take an oath', category: 'things', difficulty: 2),
  AwingWord(awing: 'lóg nələgə', english: 'wink (of eye)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'láglələglə', english: 'word that describes how a snake moves or how something else moves like a snake', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ləzámə', english: 'exam', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'lá əsê', english: 'rise up (intr)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ló nkéebə', english: 'beg for money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lókə', english: 'lock', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'lókiə', english: 'luck', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ma\' nkó\'ə', english: 'decorate, make something flowerish or beautiful', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mǎ pəmá', english: 'grandmother (maternal)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mǎ pətǎ', english: 'grandmother (paternal)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mǎ pətǎ yi ndzá\'kə', english: 'grandmother of someone', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ma\'ô atsə\'ə', english: 'wear clothes, dress up', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mângasá', english: 'Women dance group based in Sam Sunyewe\'s compound', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'maŋ cha\'tô', english: 'greetings', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'maŋə', english: 'he/him pronoun', category: 'things'),
  AwingWord(awing: 'mbagə aləmə', english: 'A dance group in Tame Efoomba\'s compound', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbaŋ mbenə', english: 'testicle', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbě ndumó', english: 'mole', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbenə', english: 'penis', category: 'things'),
  AwingWord(awing: 'mbáʔə', english: 'lump (of clay or mud)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbǎəmə', english: 'body; self', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbôláʔə', english: 'proverb, wise saying, idiomatic expression', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi ndê', english: 'floor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi yi ntsɛɛmbia', english: 'olden times', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbimâ', english: 'believe', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mbi yi ńdzáŋnə', english: 'pain', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mbifúə', english: 'cowrie shell', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'Mbîwiŋə', english: 'Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbo\'â', english: 'circumcision (male)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mbô\'máwúmó', english: 'eagle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbô\'móonə', english: 'the manner of circumcising, the way in which circumcision is done', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbô\'nəntsoolə', english: 'soldier, army officer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbəba akoolə', english: 'footprint (of man or animal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbo\'ə', english: 'if', category: 'things', difficulty: 3),
  AwingWord(awing: 'mbyáabə', english: 'guard', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mé fia apô', english: '(continues on next page)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé ghagə́', english: '(continuation) thumb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'méd mánumə', english: 'west; sunset', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'méná', english: 'a word that is used before numbers that modify class six nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mə', english: 'my', category: 'things', difficulty: 2),
  AwingWord(awing: 'mó', english: 'the infinitive \'to\'', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'məchína təzá\'ə', english: 'celibacy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'máəló', english: 'demonstrative pronoun \'it\' used for nouns of class six', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məəná', english: 'demontrative adj \'this\', used for nouns of class six', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məfênə', english: 'giving; offering', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məfu\'ə', english: 'foam', category: 'things'),
  AwingWord(awing: 'mág mó əfo', english: 'somebody who investigates issues and report to the fon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məgtə azonə̂', english: 'settle dispute', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mâghaba', english: 'adultry', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê nə nəkwa', english: 'twenty-four (24)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê nə tá\'ə', english: 'twenty-one (21)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghó\'kənə', english: 'worship; worshipping', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məkálé', english: 'English language', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məkeemə̂', english: 'gun powder', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'məko\'nə̂', english: 'north', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'məkwú má akokíə', english: 'cowpies', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mókwúbla', english: 'shelter', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məkwúblənə', english: 'repentance; repenting', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məkwumə́', english: 'masquerader, dance group uniquely made up of men and totally veiled', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məleemə', english: 'deception, deceit', category: 'things'),
  AwingWord(awing: 'məláŋə', english: 'sorrow, pity', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məlo\' má tyantə̂ nə̂', english: 'alcohol (general)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məlóŋ má atîa', english: 'sap', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məlwîə', english: 'nasal mucus, snot, catarrh', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məm nəpóola', english: 'heaven', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məméema', english: 'possessive pronoun \'mine\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mámé yi ndzá\'ka', english: 'grandmother (maternal)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məméənə', english: 'possessive pronoun plural \'yours\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məmía', english: 'possessive pronoun \'his\' used for class 6 nouns; possessive pronoun hers, used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məmô', english: 'possessive pronoun singular \'yours\' used for class 6 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məmóoba', english: 'possessive pronoun \'theirs\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manganə', english: 'charm (fetish)', category: 'things'),
  AwingWord(awing: 'mángâsé', english: 'scorpion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mangyè', english: '1) female (sex), woman, wife', category: 'things', tonePattern: 'low', difficulty: 3),
  AwingWord(awing: 'manoŋ má mbéŋa', english: 'wool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manoŋ má ndě má neemə', english: 'mane', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'manoŋ má neemə', english: 'fur', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məntalása', english: 'matress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mankálə', english: 'pap; mushy food', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manwâ\'na', english: 'cleanliness; holiness', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'máp ə́ŋə̂', english: 'an unformed animal in the womb; a young unformed plant in the bud', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mápə́ŋə́ fláwa', english: 'bud', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mápə́ŋə́ móona', english: 'foetus', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məse', english: 'witchcraft', category: 'things'),
  AwingWord(awing: 'məso\'ə', english: 'robe of honour and respect for men', category: 'things', difficulty: 2),
  AwingWord(awing: 'məteenə̂', english: 'market', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mətəənə', english: 'strength', category: 'things'),
  AwingWord(awing: 'mətágna mangyè', english: 'being engaged, being betrothed', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məti má nkîa', english: 'current, of water; wave of water', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mətoŋə̂', english: 'down, south', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mətoŋŋə̂', english: 'down, South', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mótwe\'á', english: 'caterpillar', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mətwâŋnə', english: 'burial, burying', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mətsenə', english: 'urine', category: 'things'),
  AwingWord(awing: 'mətsá', english: 'attribute \'certain\', modifying nouns of class 6; attribute \'some\', modifying nouns of class 6', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mîa', english: 'demonstrative adj \'those\', modifies nouns of class six', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó apeemə', english: 'pocket; witchcraft (used colloquially)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó kwúneemə', english: 'piglet', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mangyè', english: 'bride; girl, little girl', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó natûə', english: 'firstborn', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó ngába', english: 'chick', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó ntîə', english: 'orphan', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó ŋwíŋə', english: 'knife', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mo\'ə̂', english: '(not given)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'na mbǎəmə', english: 'human flesh, \'meat of body\'', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'na məyeŋə', english: 'wild animal', category: 'things'),
  AwingWord(awing: 'na nəyeŋə̂', english: 'wild animal', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'náŋ mbiə', english: 'hope, be optimistic', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nátíbə', english: 'native', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ncha\'tə əsê', english: 'spiritual healer, somebody who heals through prayers', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nchîə', english: 'soot', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nchílə', english: 'Women dance group in Njom, no longer active, but still have their drums and other things', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nchîmbîə', english: 'life, living', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nchwadkə̂', english: 'salvation', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nchwá\'ə', english: 'subscription, tontine', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nchwiga', english: 'spy', category: 'things'),
  AwingWord(awing: 'ndadkándadka', english: 'continously, non-stop', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nda\'ə', english: 'only, lone', category: 'things', difficulty: 2),
  AwingWord(awing: 'nda\'nə', english: 'promise', category: 'things'),
  AwingWord(awing: 'ndě yi mbwódta nə̂', english: 'nausea', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndé\'ə', english: 'necklace', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndé\'nə', english: 'spare, something that has not got a partner', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndě melo\'ə', english: 'bar, drinking spot', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndě móga', english: 'kitchen', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndě móona', english: 'birth ceremony, naming ceremony', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndedta', english: 'frontier (of ethnic area); boundary', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndeela', english: 'A sort of feast celebrated by Bororos', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndelə̂', english: 'time', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ndámə', english: 'wire', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndaŋə', english: 'bamboo', category: 'things'),
  AwingWord(awing: 'ndəŋndəŋə', english: 'truth. Speak the truth', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndəpa\'ə', english: 'tobacco; cigarette', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndəsê təpəŋə', english: 'barren land', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Ndawálé', english: 'Douala. People from Douala speak French', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndəzəəmə', english: 'moth', category: 'things'),
  AwingWord(awing: 'ndí\'ə', english: 'poison', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndoonə', english: 'curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'ndotíə', english: 'dirt, rubbish', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndú atsəmə', english: 'everywhere', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndua', english: 'hammer', category: 'things'),
  AwingWord(awing: 'ndzaŋə', english: 'color, kind, pattern', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzaŋə á laŋ ná', english: 'account (report)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzeemó', english: 'axe', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndzelá', english: 'satisfaction (of sth especially food), satedness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzəəmə', english: 'dream; vision (supernatural)', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzogə', english: 'itch (n)', category: 'things'),
  AwingWord(awing: 'ndzɔ́\'ə', english: 'modern wedding ceremony; sexual intercourse', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ndzɔ́\'ə alá\'ə', english: 'in public', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ndzɔ́\'ə tá\' məngyè', english: 'polygamy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzəmnə', english: 'insult', category: 'things', difficulty: 3),
  AwingWord(awing: 'nèe ndzɔ́\'ə', english: 'rape or have sex with somebody by dint of force', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'neemə akoobá', english: 'wild animal', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'néŋ əfɔ́gə', english: 'blow up, inflate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'néŋ mbwódnə', english: 'bless', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'néŋ nəfaŋə́', english: 'wound (sth or sb)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwáakə', english: 'style of beginning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwaakinə́', english: 'the beginning, the start', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwéd nə́ atoonə akáŋəsê', english: 'alter', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəchwi\'ə́', english: 'turf, of grass', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfágə', english: 'twin', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəfèŋə', english: 'inhygenic behaviour that is exagerated eg cooking and eating with excrement lying in', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nəfed nó ngo\'ə́', english: 'titled feather. Titled feathers are given to people who do great things', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfelə', english: 'feather', category: 'things'),
  AwingWord(awing: 'nəfemə̂', english: 'a secret place, especially in the fon\'s palace', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəfaŋ nó móənə', english: 'ulcer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfo nə́ Əsê', english: 'kingdom of', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəfyânə', english: 'spanking', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəgheebə', english: 'the manner of sharing or distributing', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəghéenə', english: 'visit', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəgha\' nó mógə', english: 'embers; charcoal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəgholə', english: 'a challenging task', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəjíə', english: 'possessive pronoun "his" used for class 5 nouns; possessive pronoun "her" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəká\'ə', english: 'bundle (especially of firewood)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkaŋə', english: 'magic', category: 'things'),
  AwingWord(awing: 'nəkéelə', english: 'headpad', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkəələ', english: 'penis (colloquial usage)', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəkəŋ nó atsa\'ə́', english: 'cooking pot (earthenware)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkəŋ nó ndəpa\'ə́', english: 'tobacco pipe', category: 'things', tonePattern: 'high', difficulty: 2),
  // Session 52: was 'nəkəŋ nó nkíə' — nkíə (high tone) does not exist. Per dict, water = nkǐə (rising).
  AwingWord(awing: 'nəkəŋ nó nkǐə', english: 'pot (for water)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nəkəŋ nó séləbə', english: 'metal pot', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkəŋə́', english: 'tobacco pipe', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkəŋ', english: 'pot', category: 'things'),
  AwingWord(awing: 'nəkó\'ə', english: 'growth (of plants)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkoŋ nó nkyílə', english: 'arrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkoŋə́', english: 'lance, spear', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkwedná əpúmə', english: 'garbage dump', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkwinə', english: 'beam; rafter', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəkwíŋə', english: 'manner of prospering, manner of growing (of plants), manner of climbing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkwu nó ndê', english: 'doorway', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəkwu\'ə́', english: 'mortar', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkwuunə́', english: 'entrance', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyéŋə', english: 'mourning, crying', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyéŋə mbi Əsê', english: 'confession', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəkye nó nûə', english: 'beewax; bee-bread', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəkyéelə', english: 'debt', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyelá', english: 'hearth', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyelá nó mógə́', english: 'fireplace, hearth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəla\'ə', english: 'string', category: 'things'),
  AwingWord(awing: 'nələŋ nó kɔ́\'ə aŋkándə', english: 'strap for climbing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nələŋə́', english: 'knuckle, joint', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəló\' nó aghələ məjíə', english: 'ladle', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəló\'ə', english: 'spoon', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəloŋə', english: 'harp', category: 'things'),
  AwingWord(awing: 'nəlwelá', english: 'bump, knot (in wood)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəlwí nə́ əshúə', english: 'gill', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənchwínə', english: 'waxbill', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəntəələ', english: 'maggot (found in rotten meat)', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəntoolá', english: 'hernia (a disease)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənyinə', english: 'journey; movement, travel', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəpá nó ngɔŋə', english: 'public alter. Used by any person for his family or personal sacrifices', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpab nó əshúə', english: 'fin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpaŋə', english: 'redness', category: 'things'),
  AwingWord(awing: 'nəpeebə', english: 'wing', category: 'things'),
  AwingWord(awing: 'nəped nó nûə', english: 'beehive', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpélə', english: 'excrement', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpenə́', english: 'edge, side, beside', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpəgə', english: 'foolishness', category: 'things'),
  AwingWord(awing: 'nəpəm nó atîə', english: 'trunk, of tree', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpəm nó lúm nə́', english: 'stomachache, upset stomach', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpíə', english: 'cola nut', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpíəmbéŋə', english: 'quiny; The fruit of a quiny tree is used as medicine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpí nó neemə', english: 'udder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpó\' nó əpúmə', english: 'threshing-floor', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpo\'ə́', english: 'bundle', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpo\' nó kéenə', english: 'melon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpɔ́\'ə', english: 'pumpkin', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpɔŋə', english: 'beauty', category: 'things'),
  AwingWord(awing: 'nəságə', english: 'vagina', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəsáŋə', english: 'broom', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəse', english: 'grave', category: 'things'),
  AwingWord(awing: 'nəsednə', english: 'bend, curve, corner', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəsô', english: 'the manner of weeding', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəsóŋə', english: 'the manner of saying', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsɔ\'ə', english: 'the manner of clearing (of a field)', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəsoŋ nó kwúneemə afoonə', english: 'tusk (of warthog)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsoŋ nə́ záŋ ná', english: 'toothache', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəshugnə', english: 'camp, encampment', category: 'things'),
  AwingWord(awing: 'nətáŋə', english: 'hardship, stress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nətú\' ənumnə', english: 'eclipse (sun)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətu nó ndúmə', english: 'crossroads, intersection', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətu nó nəkoŋə́', english: 'shaft of arrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətûə', english: 'summit, highest point, tip, chief, headman', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətwéŋ nó pəkwûə', english: 'cemetery', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətsa\'ə́', english: 'marsh', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nətsê nó neemə', english: 'heifer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətsə́', english: 'attribute "certain", modifying nouns of class 5; attribute "some", modifying nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəwaŋə́', english: 'sales point, place for business transaction', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəwû nó nkǐ mógə', english: 'funeral', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nəwuə', english: 'the manner of falling', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəyeŋə yi səbtə nó', english: 'weeds', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzéemə', english: 'possessive pronoun "mine" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzágə́', english: 'possessive pronoun "ours" used for class 5 nouns; possessive adj "our" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzô', english: 'possessive singular pronoun "yours" used for class 5 nouns. Where is your potatoe', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəzóobá', english: 'possessive pronoun "theirs" used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá', english: 'no', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá mə\'ə́', english: 'once, one time', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá yitsə̂', english: 'again, once more', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngagə', english: 'fist', category: 'things'),
  AwingWord(awing: 'ngaŋəfa\'ə', english: 'servant. Am not your servant', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋəfúə', english: 'medicine man, traditional healer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkwaalətáksə', english: 'tax collector. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋtsáŋə', english: 'prisoner; captive', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkəpeenə', english: 'enemy. Peter is my enemy', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋmáŋéemə', english: 'diviner, fortune-teller. A fortune-teller lies', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋnchindê', english: 'host, owner of the compound', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngaŋnəkaŋə', english: 'sorcerer; magic practitioner', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋnənyinə', english: 'traveller, very mobile person', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋtê', english: 'sorcerer (male)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngaŋtsoolə', english: 'army officer, soldier', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngéelə', english: 'gun', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngedtəpəŋə', english: 'sinner, evil doer', category: 'things', difficulty: 2),
  AwingWord(awing: 'ńgə́', english: 'verb complement, occurs only after verbs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá\'ə', english: 'hardship, distress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngəəbə', english: 'goblet', category: 'things'),
  AwingWord(awing: 'ngi yi mbyâŋnə', english: 'boyfriend', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngi yi məngyè', english: 'girlfriend', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ngo\'kə́', english: 'splendor; glory', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngóobə', english: 'cunning; deceit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngoolə', english: 'swear, a statement that is considered as the truth, oath', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngólə', english: 'hole', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngonə', english: 'dance group in Njom, no longer active', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwâ', english: 'sheath', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ngwâ nəkoŋ nó nkyílə', english: 'quiver', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngwaalə', english: 'somebody who slaughters', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwaamə', english: 'accuser', category: 'things'),
  AwingWord(awing: 'ngwágə', english: 'someone who despises', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwě əsê', english: 'fetish priestess', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwe\'ə́', english: 'tomorrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwəpá\'ə', english: 'biggest dance group in Awing based in Njom', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwub neemə', english: 'hide of cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwubə', english: 'shoe; hide of any animal', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwubə akoolə', english: 'shoe', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwüdlóŋə́', english: 'heron. Some people believe that when a heron cries it is an evil omen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwumnə́ akwunə́', english: 'bedbug', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngyéŋə', english: 'side (of body)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngyeenakə\'ə', english: 'shepherd, cow boy', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngyêtûə', english: 'earache', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ni\'ə́', english: 'a sort of pointed weed, usually pierces into the feet of farmers when they are weeding', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'njakásə', english: 'jackal. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nji\' nəságə', english: 'clitoris', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nji\' nətôglə', english: 'earwax', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'njiə', english: 'hunger', category: 'things'),
  AwingWord(awing: 'nji\'ə́', english: 'egussi', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'njîməneemə', english: 'pastureland', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'njubkə', english: 'sth peeling off', category: 'things', difficulty: 2),
  AwingWord(awing: 'nju\'ə', english: 'silk', category: 'things'),
  AwingWord(awing: 'nka kwíŋə́', english: 'shell (of turtle)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nká\' məneemə', english: 'cattle pen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nká\' nəpumə́', english: 'eggshell', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nka sáŋə́', english: 'nest', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nka\'ə', english: 'leprosy', category: 'things'),
  AwingWord(awing: 'nkámázɔ́\'ə́', english: 'monkey', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkaŋə', english: 'age-group', category: 'things'),
  AwingWord(awing: 'nkeemə́', english: 'basket', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nkeenə́ akyamə', english: 'gall bladder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkeenə́ atətsələ', english: 'cocoon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nked nətəŋə́', english: 'umbilical cord', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nked nkyílə', english: 'bowstring', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá akóolə əshúə', english: 'fishing net', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá apɔ́əmə', english: 'hunting net', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəənə', english: 'news, message', category: 'things'),
  AwingWord(awing: 'nkəm əsê', english: 'fetish priestess', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkəmə́', english: 'title of sub-chief; sub-chief', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkǐ nəko\'nó', english: 'national anthem', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkǐ yi əshî\'nə', english: 'gospel, good news', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkog məngyè', english: 'widow', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkog ngábə', english: 'hen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkog ŋwu mbyâŋnə', english: 'widower', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkoolə', english: 'bruise', category: 'things'),
  AwingWord(awing: 'nkóomə atûə', english: 'barber', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nkɔ\'ə', english: 'bucket', category: 'things'),
  AwingWord(awing: 'nkənə', english: 'hunchback', category: 'things'),
  AwingWord(awing: 'nkəŋ ndəpa\'ə', english: 'pipe stem', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkəŋə aŋwa\'lə', english: 'pen', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkwa', english: 'mask', category: 'things'),
  AwingWord(awing: 'nkwáalə', english: 'midwife', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nkwâtáksə', english: 'tax collector', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nkwe', english: 'masqueraders based in Tame Mbah Ako\'s compound. No longer active', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkwáŋə', english: 'firewood', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nkwiŋ məngyè', english: 'spinster', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkwiŋ ŋwu mbyâŋnə', english: 'bachelor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkwúblə mbimá', english: 'convert, somebody who changes his or her believes', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkwu\'ə', english: 'chaffs of grain', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkye', english: 'granary', category: 'things'),
  AwingWord(awing: 'nkye məngyè', english: 'barren woman', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkyeetə', english: 'meeting, assembly', category: 'things'),
  AwingWord(awing: 'nkyílə', english: 'hunting bow; sword', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nó mətû mətûə', english: 'spitting cobra', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nó ngámə', english: 'python', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'noŋkə', english: 'law, practice', category: 'things'),
  AwingWord(awing: 'nóŋ ntsoolə', english: 'kiss, of lovers only', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntagə akoolə', english: 'footstep', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntaŋə', english: 'horn (musical instrument)', category: 'things', difficulty: 2),
  AwingWord(awing: 'ńte akə̌', english: 'why?', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ńte ngə́', english: 'because', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ntəələ', english: 'capital for starting a business', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntəənə acha\'tésê', english: 'fasting', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntəmə', english: 'a skirt-like dress worn by men', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntó\'ə', english: 'calabash', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntóoma', english: 'pillar, wedge, esp. for a house', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntú əsê', english: 'prophet', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntûə', english: 'payment', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntúmkə', english: 'entrance hut', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntyâ əpúmə', english: 'somebody who finds it difficult to make a choice', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntsa\'ə', english: 'hoof', category: 'things'),
  AwingWord(awing: 'ntseŋ ndê Əsê', english: 'angel', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntseŋnə', english: 'somebody who looks after something eg cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntseŋnə məneemə', english: 'shepherd', category: 'things'),
  AwingWord(awing: 'ntsentə', english: 'meeting, grouping', category: 'things'),
  AwingWord(awing: 'ntsəələ', english: 'lie (falsehood)', category: 'things'),
  AwingWord(awing: 'ntsəmá', english: 'confidential or private conversation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntsóŋə', english: 'bottle', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntsəŋkə', english: 'condemnation; destruction, destroyer', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntso ndê', english: 'door', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntso sáŋə́', english: 'beak, bill', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntsɔ́\'ə afa\'ə', english: 'reward, remuneration', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntsə\'lə', english: 'comb (of rooster), crest', category: 'things', difficulty: 2),
  AwingWord(awing: 'nyâ\'', english: 'opening sound that is gradual and secretive eg of a door', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nyânyâ', english: 'sound that describes a crying baby', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nya\'nya\'ə', english: 'drizzle', category: 'things'),
  AwingWord(awing: 'nyâ\'nya\'nya\'', english: 'intensifies the continuous and muddy nature of a drizzle', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nyá\'tənyá\'tə', english: 'sound (word) that describes how secretive somebody moves', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyênənyenə', english: 'sound (word) that describes the slowness of someting or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'ŋwáglə', english: 'bell', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ŋwu mbyâŋnə', english: 'man; male (sex)', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'ŋwu ntsəmə', english: 'everybody', category: 'things', difficulty: 2),
  AwingWord(awing: 'ŋwunə', english: 'inhabitant, resident', category: 'things'),
  AwingWord(awing: 'ŋwunə alə\'á', english: 'cripple', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'óflenə', english: 'offering given in church', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pábánduuŋgɔ́\'ə', english: 'lizard; agama lizard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pá\'mághéemə́', english: 'flea', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pâmtə', english: 'sound that describes a start or sudden wake', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'pánkó', english: 'something that accompanies a bigger one eg a stool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pánkó akɔ\'ə', english: 'stool, a sort of seat', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'paŋ sɔŋə́', english: 'weaverbird', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'páta', english: 'even though', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'pe\'ə', english: 'marker, of simple past tense. Used for events that take place the same day', category: 'things', difficulty: 3),
  AwingWord(awing: 'péŋkə ajwiə', english: 'faint. Some people who lose their breath on hearing any bad news', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pénkə aghoonə́', english: 'throb with pain', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pô', english: 'demonstrative adj \'those\', used to modify nouns of classes one and three', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pəənə́', english: 'demonstrative pronoun \'you\' (pl.). Occurs after nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'páanə', english: 'class two and eight interrogative \'which\'', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəgə', english: 'we exclusive, that is, excluding others', category: 'things'),
  AwingWord(awing: 'págtə', english: 'quench, extinguish', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəlô', english: 'ancestors; les ancetre', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pôm', english: 'sound that describes a start or sudden wake', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'pəpíə', english: 'possessive pronoun \'his\' used for class 2 nouns; possessive pronoun \'hers\' used for class 2 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəpóobá', english: 'possessive pronoun \'theirs\' used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pi ndəŋ', english: 'boil over', category: 'things', difficulty: 2),
  AwingWord(awing: 'píi', english: 'intensifies the blackness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'pímə məmə', english: 'accept reluctantly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\' mbô', english: 'clap (hands), beg', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pó\' nó nduə', english: 'hit with a hammer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\' ngoŋə', english: 'cry out; scream', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'əpa\'ə', english: 'abstain, avoid, stay away from', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'mâmbéŋə', english: 'hyena', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pôŋ', english: 'intensifies the redness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'po\'á', english: 'mushroom', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'púu', english: 'intensifies the whiteness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'pyáb nó nəkaŋə', english: 'protect by charm', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pyádnə', english: 'really, truly; very well', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sá ndedtə', english: 'mark out, peg out (of boundary)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sádusísə', english: 'Sadducee', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'sáŋ pábá', english: 'harmattan', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'séenásê', english: 'puff adder', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'sedkə ndzəmə', english: 'turn over (tr)', category: 'things', difficulty: 2),
  AwingWord(awing: 'sélóbə', english: 'silver', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'səmtwá\'', english: 'sound (word) that describes how two things bump on each other or two people meet unexpectedly', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'sáŋ məkálə', english: 'pigeon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ neemə', english: 'cattle egret', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ ngábə', english: 'partridge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ ngábə akoobá', english: 'guinea fowl', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sílenə', english: 'ceiling', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'sínágoga', english: 'sinagogue', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'sog əpúmə', english: 'wash utensils', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sog ətsə\'á', english: 'launder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sogə akwubə', english: 'bathe (wash body) (intr)', category: 'things', difficulty: 2),
  AwingWord(awing: 'soŋ nkəlá', english: 'pull; resist', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soŋə múto', english: 'steer, drive a car', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soŋə ndəsê', english: 'drag on the grown', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sóoŋ', english: 'sound (word) produced to describe the intensity with which somebody is listening, hearing or looking', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'sə\'â ali\'á', english: 'clear (land or a grown place for planting)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwa\'ə', english: 'razor blade. If you give a razor blade to a child he will wound himself with', category: 'things', difficulty: 2),
  AwingWord(awing: 'shwěmôndóŋə', english: 'shrew, name of animal', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tä afa\'ə', english: 'master', category: 'things', difficulty: 2),
  AwingWord(awing: 'tá\' əpúmə', english: 'bead', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tá\' ngǎ', english: 'once, one time', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tä pətä', english: 'grandfather (paternal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'táksə', english: 'tax. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tâlətaalə', english: 'sound (word) that describes how a drunk person moves', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'téemə atəənə́', english: 'set a trap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'témpəələ', english: 'temple. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tə', english: '"us", excluding other people; "we" excluding other people', category: 'things', difficulty: 2),
  AwingWord(awing: 'tâb', english: 'intensifies the softness of something. Mattress is so soft', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'təə', english: 'non-stop', category: 'things', difficulty: 2),
  AwingWord(awing: 'táfu\'əmántséntsé', english: 'dragonfly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təjî ndzɔ\'á', english: 'virgin', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'təká', english: 'never', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'táko\' sáŋə́', english: 'turkey', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tám nó afûə', english: 'bewitch', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'támásê', english: 'destruction, wastage', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'táŋká\'andíkwumá', english: 'millipede', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təpí əsê', english: 'unbeliever, somebody who does not believe in God or the popular religion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'təpíma', english: 'unbeliever, polite expression for pagan or somebody who does not identify himself with one\'s religion or the popular religion', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tasa\'ə', english: 'spark', category: 'things', difficulty: 2),
  AwingWord(awing: 'tatəənə', english: 'between; middle', category: 'things', difficulty: 2),
  AwingWord(awing: 'təti nəpu nə́ ngəbə', english: 'yolk (of egg)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí\'ə', english: 'let; allow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tó\'', english: 'sound (word) that adds meaning to the quietness of somebody or something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'tó\' nkǐə', english: 'draw water', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tôd', english: 'sound (word) that intensifies the messy state of a thing or situation', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'tóŋ njwîŋə', english: 'whistle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tósə', english: 'touch lamp. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túg ntáəmə', english: 'be courageous; be brave', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twáamə aléemə', english: 'hurt oneself', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twám nó mbô', english: 'carry in arms', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyáŋə mənaŋə', english: 'gossip', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsópó', english: 'plague; epidemic', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsô', english: 'sound (word) that describes the fastness in which one or many things disappear into the unknown', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'tsonkô ndena', english: 'haggle; negotiate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\' ətsə\'á', english: 'undress', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóg', english: 'sound (word) that intensifies the coldness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'vâd', english: 'sound (word) that describes the fastness of something or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'vâinə', english: 'vain. From: English', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'vîp', english: 'sound (word) that describes the fastness of sometning or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'wâg', english: 'sound (word) that describes the sound of something being opened or torn with brute force', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'wág Əsê', english: 'blaspheme; belittle God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'welə', english: 'weight. It is not good to carry a lot of weight. From: English', category: 'things', difficulty: 2),
  AwingWord(awing: 'wô', english: 'demonstrtive adj \'that\' used to modify nouns of classes one and three. That pig is whose own', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wáənə', english: 'which?', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wískiə', english: 'whisky', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'wûu', english: 'sound (word) that describes the rumbling of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'Yéso', english: 'Jesus. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Yéso Klisto', english: 'Jesus Christ. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yêe', english: 'sound (word) that describes how a group (herd, swarm, people etc) run into different directions, usually in such of safty', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'yó', english: 'his; her', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'yǐpəchíə', english: 'concubinage; cohabitation', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'yitsə̌', english: 'attribute "certain", modifying nouns of classes 1, 3, 7 and 9', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'yôyo', english: 'Women dance group based in Tame Tangwing\'s compound. No longer active', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zǎa', english: 'winnow, of grain', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'zá\'ə', english: 'before (contrasted with afterwards). You were suppose to tell me before he comes', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'zagə atîə', english: 'soar', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zén', english: 'a word that is used before numbers that modify class five nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zə̂', english: 'demonstrative adjective \'that\' (talked about); demonstrative adjective "that", pointing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zoŋ əshwáŋə', english: 'track, of an animal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zoomə', english: 'confession', category: 'things', difficulty: 2),
  AwingWord(awing: 'zó\' nkǐə', english: 'swim', category: 'things', tonePattern: 'rising', difficulty: 2),

  // numbers (12 — duplicates of the curated numbers list have been removed.
  // The curated `numbers` list above is authoritative for the kid-facing
  // Numbers screen; these are extended/alternate forms only.)
  AwingWord(awing: 'azoŋkə', english: 'second, second place', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'kwa', english: 'four (see nəkwa)', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê', english: 'twenty (20)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén nəfeemə̂', english: 'eighty (80)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén nəkwa', english: 'forty (40)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'məghám mén nəpu\'ə̂', english: 'ninety (90)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén ntogə̂', english: 'sixty (60)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén teelə̂', english: 'thirty (30)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén tênə', english: 'fifty (50)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám méná asaambê', english: 'seventy (70)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'nəghámə', english: 'ten (alternate form)', category: 'numbers', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá', english: 'hundred (100)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsoobə asaambê', english: 'seventeen (17)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'ntsəb mə\'á', english: 'eleven (11)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsəb napu\'á', english: 'nineteen (19)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsəb pê', english: 'twelve (12)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'pě', english: 'two (alternate form)', category: 'numbers', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'teelə', english: 'three (alternate form)', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'tênə', english: 'five (alternate form)', category: 'numbers', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tóosə', english: 'thousand (1000). From: English', category: 'numbers', tonePattern: 'high', difficulty: 2),

  // === Auto-extracted from Bible NT corpus (auto_extract_app_content.py) ===
  AwingWord(awing: 'ə́sóŋ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.45, freq=525
  AwingWord(awing: 'əshîʼnə', english: 'good', category: 'general', difficulty: 2),
    // bible:MAT.3.10, conf=0.50, freq=501
  AwingWord(awing: 'ə́sóŋə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.3.1, conf=0.40, freq=446
  AwingWord(awing: 'táʼ', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.5.36, conf=0.61, freq=382
  AwingWord(awing: 'ngaŋə́zoŋə́ndzəm', english: 'disciples', category: 'general', difficulty: 2),
    // bible:MAT.5.1, conf=0.65, freq=338
  AwingWord(awing: 'ḿbímə', english: 'faith', category: 'general', difficulty: 2),
    // bible:MAT.3.15, conf=0.70, freq=323
  AwingWord(awing: 'fiʼtə̂', english: 'tell', category: 'general', difficulty: 2),
    // bible:MAT.2.8, conf=0.45, freq=317
  AwingWord(awing: 'nɨ́', english: 'many', category: 'general', difficulty: 2),
    // bible:MAT.7.22, conf=0.61, freq=301
  AwingWord(awing: 'ndɛ̂', english: 'house', category: 'general', difficulty: 2),
    // bible:MAT.2.11, conf=0.47, freq=291
  AwingWord(awing: 'Mmaʼmbî', english: 'lord', category: 'general', difficulty: 2),
    // bible:MAT.4.7, conf=0.95, freq=277
  AwingWord(awing: 'pɛ̌', english: 'two', category: 'general', difficulty: 2),
    // bible:MAT.2.16, conf=0.46, freq=264
  AwingWord(awing: 'nkɨ', english: 'good', category: 'general', difficulty: 2),
    // bible:MAT.9.35, conf=0.42, freq=260
  AwingWord(awing: 'məngyě', english: 'woman', category: 'general', difficulty: 2),
    // bible:MAT.1.23, conf=0.43, freq=253
  AwingWord(awing: 'Mmaʼmbîə', english: 'lord', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.91, freq=220
  AwingWord(awing: 'táʼə', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.5.29, conf=0.57, freq=214
  AwingWord(awing: 'mäŋ', english: 'tell', category: 'general', difficulty: 2),
    // bible:MAT.3.9, conf=0.41, freq=210
  AwingWord(awing: 'fóŋ', english: 'called', category: 'general', difficulty: 2),
    // bible:MAT.1.16, conf=0.46, freq=205
  AwingWord(awing: 'nchîmbî', english: 'life', category: 'general', difficulty: 2),
    // bible:MAT.6.25, conf=0.53, freq=205
  AwingWord(awing: 'əlɛ́n', english: 'name', category: 'general', difficulty: 2),
    // bible:MAT.1.21, conf=0.55, freq=194
  AwingWord(awing: 'ḿbítə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.2.2, conf=0.41, freq=189
  AwingWord(awing: 'fɛ́lə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=0.44, freq=188
  AwingWord(awing: 'ŋwaʼlə̂', english: 'written', category: 'general', difficulty: 2),
    // bible:MAT.4.4, conf=0.41, freq=188
  AwingWord(awing: 'nəpó', english: 'heaven', category: 'general', difficulty: 2),
    // bible:MAT.3.16, conf=0.52, freq=178
  AwingWord(awing: 'ńdzóʼ', english: 'heard', category: 'general', difficulty: 2),
    // bible:MAT.2.3, conf=0.70, freq=168
  AwingWord(awing: 'ńkwúnə', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.2.11, conf=0.46, freq=163
  AwingWord(awing: 'Pəjus', english: 'jews', category: 'general', difficulty: 2),
    // bible:MAT.27.1, conf=0.60, freq=161
  AwingWord(awing: '“Maŋ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.2.15, conf=0.50, freq=155
  AwingWord(awing: 'Ajwǐəsê', english: 'spirit', category: 'general', difficulty: 2),
    // bible:MAT.1.18, conf=0.92, freq=148
  AwingWord(awing: 'ndɛn', english: 'things', category: 'general', difficulty: 2),
    // bible:MAT.6.32, conf=0.44, freq=147
  AwingWord(awing: 'tú', english: 'sent', category: 'general', difficulty: 2),
    // bible:MAT.2.8, conf=0.51, freq=142
  AwingWord(awing: 'ngaŋəfaʼ', english: 'servant', category: 'general', difficulty: 2),
    // bible:MAT.8.13, conf=0.42, freq=141
  AwingWord(awing: 'pənoŋkə', english: 'scribes', category: 'general', difficulty: 2),
    // bible:MAT.2.4, conf=0.42, freq=140
  AwingWord(awing: 'əwɛn', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MRK.9.38, conf=0.55, freq=139
  AwingWord(awing: 'Pəjusə', english: 'jews', category: 'general', difficulty: 2),
    // bible:MAT.2.2, conf=0.47, freq=136
  AwingWord(awing: 'ńjɨ́', english: 'saw', category: 'general', difficulty: 2),
    // bible:MAT.2.9, conf=0.41, freq=136
  AwingWord(awing: 'pətǎ', english: 'fathers', category: 'general', difficulty: 2),
    // bible:MAT.1.1, conf=0.61, freq=129
  AwingWord(awing: 'akɔŋnə', english: 'love', category: 'general', difficulty: 2),
    // bible:MAT.24.12, conf=0.78, freq=129
  AwingWord(awing: 'Jɛlusalɛm', english: 'jerusalem', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=0.89, freq=123
  AwingWord(awing: 'Tə́kɔʼndɛ̂sê', english: 'temple', category: 'general', difficulty: 2),
    // bible:MAT.4.5, conf=0.77, freq=122
  AwingWord(awing: 'pətəjǐsê', english: 'gentiles', category: 'general', difficulty: 2),
    // bible:MAT.6.7, conf=0.57, freq=122
  AwingWord(awing: 'mbwɔ́dnə', english: 'peace', category: 'general', difficulty: 2),
    // bible:MAT.5.9, conf=0.64, freq=121
  AwingWord(awing: 'ngoʼ', english: 'years', category: 'general', difficulty: 2),
    // bible:MAT.2.16, conf=0.44, freq=116
  AwingWord(awing: '“Lə́', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.3.14, conf=0.44, freq=115
  AwingWord(awing: 'tɔŋ', english: 'city', category: 'general', difficulty: 2),
    // bible:MAT.5.38, conf=0.60, freq=114
  AwingWord(awing: 'aŋkənúʼə́', english: 'boat', category: 'general', difficulty: 2),
    // bible:MAT.4.21, conf=0.45, freq=113
  AwingWord(awing: 'Mosisə', english: 'moses', category: 'general', difficulty: 2),
    // bible:MAT.5.17, conf=0.69, freq=113
  AwingWord(awing: 'pəlim', english: 'brothers', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=0.71, freq=112
  AwingWord(awing: 'pətə́kɔʼ', english: 'chief', category: 'general', difficulty: 2),
    // bible:MAT.2.4, conf=0.56, freq=111
  AwingWord(awing: 'ńdzɨ́', english: 'saw', category: 'general', difficulty: 2),
    // bible:MAT.3.7, conf=0.41, freq=110
  AwingWord(awing: 'Pɔl', english: 'paul', category: 'general', difficulty: 2),
    // bible:ACT.11.30, conf=0.53, freq=106
  AwingWord(awing: 'Lə́ələ́', english: 'therefore', category: 'general', difficulty: 2),
    // bible:MAT.1.17, conf=0.50, freq=105
  AwingWord(awing: 'nəgháʼ', english: 'glory', category: 'general', difficulty: 2),
    // bible:MAT.4.8, conf=0.82, freq=104
  AwingWord(awing: 'mɛdnə̂', english: 'eternal', category: 'general', difficulty: 2),
    // bible:MAT.18.8, conf=0.49, freq=104
  AwingWord(awing: 'ngwě', english: 'wife', category: 'general', difficulty: 2),
    // bible:MAT.1.6, conf=0.51, freq=103
  AwingWord(awing: 'pəngyě', english: 'women', category: 'general', difficulty: 2),
    // bible:MAT.13.56, conf=0.40, freq=102
  AwingWord(awing: 'asaambɛ̂', english: 'seven', category: 'general', difficulty: 2),
    // bible:MAT.12.45, conf=0.91, freq=101
  AwingWord(awing: 'əmə́g', english: 'eyes', category: 'general', difficulty: 2),
    // bible:MAT.9.29, conf=0.53, freq=99
  AwingWord(awing: 'nəkwa', english: 'four', category: 'general', difficulty: 2),
    // bible:MAT.1.17, conf=0.56, freq=97
  AwingWord(awing: 'pətəpɔŋ', english: 'sins', category: 'general', difficulty: 2),
    // bible:MAT.3.6, conf=0.60, freq=95
  AwingWord(awing: 'ńtsɛɛlə̂', english: 'than', category: 'general', difficulty: 2),
    // bible:MAT.6.26, conf=0.44, freq=95
  AwingWord(awing: 'məntú', english: 'apostles', category: 'general', difficulty: 2),
    // bible:MAT.1.22, conf=0.56, freq=94
  AwingWord(awing: 'pəlimə́', english: 'brothers', category: 'general', difficulty: 2),
    // bible:LUK.8.21, conf=0.87, freq=93
  AwingWord(awing: '“Gho', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.2.6, conf=0.59, freq=92
  AwingWord(awing: 'Jɔn', english: 'john', category: 'general', difficulty: 2),
    // bible:MAT.3.1, conf=0.70, freq=92
  AwingWord(awing: 'mɔʼə́', english: 'eternal', category: 'general', difficulty: 2),
    // bible:MAT.18.8, conf=0.53, freq=92
  AwingWord(awing: 'ntsɔb', english: 'twelve', category: 'general', difficulty: 2),
    // bible:MAT.1.17, conf=0.77, freq=91
  AwingWord(awing: 'məko', english: 'feet', category: 'general', difficulty: 2),
    // bible:MAT.4.9, conf=0.67, freq=88
  AwingWord(awing: 'ntseŋndɛ̂sê', english: 'angel', category: 'general', difficulty: 2),
    // bible:LUK.1.13, conf=0.73, freq=88
  AwingWord(awing: 'apɔŋə́ntə́əmə', english: 'grace', category: 'general', difficulty: 2),
    // bible:JHN.1.14, conf=0.88, freq=88
  AwingWord(awing: 'Ajwi', english: 'spirit', category: 'general', difficulty: 2),
    // bible:MAT.22.43, conf=0.66, freq=85
  AwingWord(awing: 'mbêsê', english: 'priest', category: 'general', difficulty: 2),
    // bible:MAT.8.4, conf=0.87, freq=84
  AwingWord(awing: 'mə́ənə́', english: 'things', category: 'general', difficulty: 2),
    // bible:MAT.3.11, conf=0.41, freq=83
  AwingWord(awing: 'Nkyaʼ', english: 'light', category: 'general', difficulty: 2),
    // bible:MAT.4.16, conf=0.68, freq=81
  AwingWord(awing: 'Pəfalasi', english: 'pharisees', category: 'general', difficulty: 2),
    // bible:MAT.3.7, conf=0.96, freq=80
  AwingWord(awing: 'məloʼ', english: 'wine', category: 'general', difficulty: 2),
    // bible:MAT.9.17, conf=0.57, freq=76
  AwingWord(awing: 'ntsɛɛmbi', english: 'first', category: 'general', difficulty: 2),
    // bible:MAT.10.2, conf=0.57, freq=76
  AwingWord(awing: 'pɛ̌sê', english: 'demons', category: 'general', difficulty: 2),
    // bible:MAT.4.24, conf=0.64, freq=75
  AwingWord(awing: 'júmnə', english: 'dead', category: 'general', difficulty: 2),
    // bible:MAT.12.42, conf=0.53, freq=75
  AwingWord(awing: 'móonə', english: 'son', category: 'general', difficulty: 2),
    // bible:MAT.1.18, conf=0.50, freq=74
  AwingWord(awing: 'ngaŋə́pêsê', english: 'priests', category: 'general', difficulty: 2),
    // bible:MAT.2.4, conf=0.92, freq=72
  AwingWord(awing: 'akwaŋ', english: 'hope', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.66, freq=71
  AwingWord(awing: 'məntúmə́sê', english: 'prophets', category: 'general', difficulty: 2),
    // bible:MAT.2.23, conf=0.85, freq=71
  AwingWord(awing: 'ńnáanə', english: 'sat', category: 'general', difficulty: 2),
    // bible:MAT.5.1, conf=0.59, freq=71
  AwingWord(awing: 'ndɛ̂sê', english: 'synagogue', category: 'general', difficulty: 2),
    // bible:MAT.12.4, conf=0.55, freq=71
  AwingWord(awing: 'ntûsê', english: 'prophet', category: 'general', difficulty: 2),
    // bible:MAT.2.5, conf=0.82, freq=68
  AwingWord(awing: 'ńkɔŋtə̂', english: 'rejoice', category: 'general', difficulty: 2),
    // bible:MAT.2.10, conf=0.43, freq=68
  AwingWord(awing: 'ndim', english: 'brother', category: 'general', difficulty: 2),
    // bible:MAT.4.18, conf=0.76, freq=68
  AwingWord(awing: 'Islɛl', english: 'israel', category: 'general', difficulty: 2),
    // bible:MAT.8.10, conf=0.54, freq=67
  AwingWord(awing: '“Nə́', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.8.26, conf=0.69, freq=67
  AwingWord(awing: 'ngaŋə́zéʼkə', english: 'scribes', category: 'general', difficulty: 2),
    // bible:MAT.2.4, conf=0.86, freq=66
  AwingWord(awing: 'apá', english: 'bread', category: 'general', difficulty: 2),
    // bible:MAT.4.4, conf=0.52, freq=66
  AwingWord(awing: 'ńtsɛ', english: 'than', category: 'general', difficulty: 2),
    // bible:MAT.5.20, conf=0.62, freq=65
  AwingWord(awing: 'Mɛɛlə', english: 'mary', category: 'general', difficulty: 2),
    // bible:MAT.1.16, conf=0.87, freq=63
  AwingWord(awing: '“Mbɔʼ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.4.3, conf=0.59, freq=63
  AwingWord(awing: 'Saamun', english: 'simon', category: 'general', difficulty: 2),
    // bible:MAT.4.18, conf=0.89, freq=63
  AwingWord(awing: 'mɔ́mɛ́', english: 'brother', category: 'general', difficulty: 2),
    // bible:MAT.7.3, conf=0.62, freq=63
  AwingWord(awing: 'móg', english: 'fire', category: 'general', difficulty: 2),
    // bible:MAT.3.12, conf=0.73, freq=62
  AwingWord(awing: '“Á', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.2.5, conf=0.52, freq=60
  AwingWord(awing: 'pətseŋpə́ndɛ́pə́sê', english: 'angels', category: 'general', difficulty: 2),
    // bible:MAT.4.11, conf=0.92, freq=59
  AwingWord(awing: 'fóg', english: 'day', category: 'general', difficulty: 2),
    // bible:MAT.5.32, conf=0.61, freq=59
  AwingWord(awing: 'mbóŋ', english: 'multitude', category: 'general', difficulty: 2),
    // bible:MAT.6.2, conf=0.44, freq=59
  AwingWord(awing: 'apeŋ', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.9.25, conf=0.54, freq=59
  AwingWord(awing: '“Lɛ̌', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.3.17, conf=0.52, freq=58
  AwingWord(awing: 'záʼ', english: 'before', category: 'general', difficulty: 2),
    // bible:MAT.5.24, conf=0.45, freq=58
  AwingWord(awing: 'ndzɛd', english: 'lamb', category: 'general', difficulty: 2),
    // bible:MAT.9.36, conf=0.40, freq=57
  AwingWord(awing: '“Kɔ', english: 'don', category: 'general', difficulty: 2),
    // bible:MAT.5.21, conf=0.61, freq=56
  AwingWord(awing: 'mbéŋ', english: 'lamb', category: 'general', difficulty: 2),
    // bible:MAT.12.11, conf=0.59, freq=56
  AwingWord(awing: 'mənta', english: 'fruit', category: 'general', difficulty: 2),
    // bible:MAT.3.10, conf=0.59, freq=54
  AwingWord(awing: 'Judya', english: 'judea', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=0.85, freq=53
  AwingWord(awing: 'Ablaamə', english: 'abraham', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=0.83, freq=52
  AwingWord(awing: 'əlěmbî', english: 'days', category: 'general', difficulty: 2),
    // bible:MAT.4.2, conf=0.79, freq=52
  AwingWord(awing: 'tɔsə', english: 'thousand', category: 'general', difficulty: 2),
    // bible:MAT.14.21, conf=0.92, freq=52
  AwingWord(awing: 'Apoŋə', english: 'multitude', category: 'general', difficulty: 2),
    // bible:MAT.4.25, conf=0.45, freq=51
  AwingWord(awing: '“Mmaʼmbî', english: 'lord', category: 'general', difficulty: 2),
    // bible:MAT.7.21, conf=0.96, freq=51
  AwingWord(awing: 'ngweŋ', english: 'priest', category: 'general', difficulty: 2),
    // bible:MAT.11.21, conf=0.69, freq=51
  AwingWord(awing: 'tǎpə', english: 'father', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=0.94, freq=50
  AwingWord(awing: 'məkálə́', english: 'bread', category: 'general', difficulty: 2),
    // bible:MAT.4.3, conf=0.66, freq=50
  AwingWord(awing: 'nə́ənə', english: 'sea', category: 'general', difficulty: 2),
    // bible:MAT.4.15, conf=0.46, freq=50
  AwingWord(awing: 'tsɔ́ʼtə', english: 'judge', category: 'general', difficulty: 2),
    // bible:MAT.7.1, conf=0.42, freq=50
  AwingWord(awing: 'Payilɛlə', english: 'pilate', category: 'general', difficulty: 2),
    // bible:MAT.27.11, conf=0.78, freq=50
  AwingWord(awing: 'pɔ́pə́mɛ́', english: 'brothers', category: 'general', difficulty: 2),
    // bible:MAT.12.46, conf=0.69, freq=49
  AwingWord(awing: 'nəgháʼə', english: 'glory', category: 'general', difficulty: 2),
    // bible:MAT.19.28, conf=0.71, freq=49
  AwingWord(awing: 'ngɔʼ', english: 'stone', category: 'general', difficulty: 2),
    // bible:MAT.7.9, conf=0.70, freq=47
  AwingWord(awing: '“Təmbɔʼ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.9.16, conf=0.43, freq=47
  AwingWord(awing: 'pəfo', english: 'kings', category: 'general', difficulty: 2),
    // bible:MAT.2.6, conf=0.57, freq=46
  AwingWord(awing: 'ḿmaʼə̂', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.5.29, conf=0.48, freq=46
  AwingWord(awing: 'nəlyaŋnə́', english: 'mystery', category: 'general', difficulty: 2),
    // bible:MAT.6.4, conf=0.41, freq=46
  AwingWord(awing: 'ngaŋə́ghɛlə', english: 'sinners', category: 'general', difficulty: 2),
    // bible:MAT.7.11, conf=0.59, freq=46
  AwingWord(awing: 'ńjúmnə', english: 'dead', category: 'general', difficulty: 2),
    // bible:MAT.9.18, conf=0.46, freq=46
  AwingWord(awing: 'ngwǔəə', english: 'fell', category: 'general', difficulty: 2),
    // bible:MAT.4.6, conf=0.44, freq=45
  AwingWord(awing: 'ngaŋkəpa', english: 'enemies', category: 'general', difficulty: 2),
    // bible:MAT.5.43, conf=0.42, freq=45
  AwingWord(awing: 'nkáʼə', english: 'prison', category: 'general', difficulty: 2),
    // bible:MAT.11.2, conf=0.53, freq=45
  AwingWord(awing: 'alěláʼə́sê', english: 'sabbath', category: 'general', difficulty: 2),
    // bible:MAT.12.5, conf=0.96, freq=45
  AwingWord(awing: 'Galili', english: 'galilee', category: 'general', difficulty: 2),
    // bible:MAT.2.22, conf=0.84, freq=44
  AwingWord(awing: 'mógə́', english: 'fire', category: 'general', difficulty: 2),
    // bible:MAT.3.10, conf=0.66, freq=44
  AwingWord(awing: 'məmbéŋ', english: 'sheep', category: 'general', difficulty: 2),
    // bible:MAT.7.15, conf=0.84, freq=44
  AwingWord(awing: 'ḿbóʼmbô', english: 'begged', category: 'general', difficulty: 2),
    // bible:MAT.8.34, conf=0.51, freq=43
  AwingWord(awing: 'Jɛmsə', english: 'james', category: 'general', difficulty: 2),
    // bible:MAT.4.21, conf=0.98, freq=42
  AwingWord(awing: 'chaʼtə́sê', english: 'pray', category: 'general', difficulty: 2),
    // bible:MAT.6.5, conf=0.45, freq=42
  AwingWord(awing: 'ńdwɛ́nkə', english: 'full', category: 'general', difficulty: 2),
    // bible:MAT.6.23, conf=0.43, freq=42
  AwingWord(awing: '“Ndzéʼkə', english: 'teacher', category: 'general', difficulty: 2),
    // bible:MAT.8.19, conf=0.71, freq=42
  AwingWord(awing: 'pəkwû', english: 'dead', category: 'general', difficulty: 2),
    // bible:MAT.8.22, conf=0.78, freq=41
  AwingWord(awing: 'ńgweŋə̂', english: 'high', category: 'general', difficulty: 2),
    // bible:MAT.9.24, conf=0.59, freq=41
  AwingWord(awing: 'pɔ́gə', english: 'don', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.57, freq=40
  AwingWord(awing: 'əjwi', english: 'spirits', category: 'general', difficulty: 2),
    // bible:MAT.8.16, conf=0.70, freq=40
  AwingWord(awing: 'nchîntɨ', english: 'life', category: 'general', difficulty: 2),
    // bible:MAT.18.8, conf=0.93, freq=40
  AwingWord(awing: 'məfaʼ', english: 'works', category: 'general', difficulty: 2),
    // bible:MAT.5.16, conf=0.85, freq=39
  AwingWord(awing: 'ə́sɛ́n', english: 'today', category: 'general', difficulty: 2),
    // bible:MAT.5.36, conf=0.44, freq=39
  AwingWord(awing: 'nətúʼ', english: 'night', category: 'general', difficulty: 2),
    // bible:MAT.24.43, conf=0.87, freq=39
  AwingWord(awing: 'Zə́m', english: 'fruit', category: 'general', difficulty: 2),
    // bible:MAT.3.8, conf=0.82, freq=38
  AwingWord(awing: 'ńnô', english: 'drink', category: 'general', difficulty: 2),
    // bible:MAT.11.18, conf=0.42, freq=38
  AwingWord(awing: 'Ndzáʼkə', english: 'passover', category: 'general', difficulty: 2),
    // bible:MAT.26.2, conf=0.76, freq=38
  AwingWord(awing: 'Mənkyeetə', english: 'assemblies', category: 'general', difficulty: 2),
    // bible:ACT.9.31, conf=0.84, freq=38
  AwingWord(awing: 'ə́fóŋ', english: 'called', category: 'general', difficulty: 2),
    // bible:MAT.2.4, conf=0.41, freq=37
  AwingWord(awing: 'achaʼtə́sê', english: 'prayer', category: 'general', difficulty: 2),
    // bible:MAT.6.7, conf=0.46, freq=37
  AwingWord(awing: 'əka', english: 'covenant', category: 'general', difficulty: 2),
    // bible:MAT.14.7, conf=0.78, freq=37
  AwingWord(awing: 'əshû', english: 'fish', category: 'general', difficulty: 2),
    // bible:MAT.7.10, conf=0.67, freq=36
  AwingWord(awing: 'apagləpaglə', english: 'cross', category: 'general', difficulty: 2),
    // bible:MAT.10.38, conf=0.58, freq=36
  AwingWord(awing: 'nkɛd', english: 'hundred', category: 'general', difficulty: 2),
    // bible:MAT.13.47, conf=0.69, freq=36
  AwingWord(awing: 'apɔ́gə', english: 'fear', category: 'general', difficulty: 2),
    // bible:MAT.14.26, conf=0.42, freq=36
  AwingWord(awing: 'Jɛlusalɛmə', english: 'jerusalem', category: 'general', difficulty: 2),
    // bible:MAT.4.5, conf=0.89, freq=35
  AwingWord(awing: 'təənə', english: 'right', category: 'general', difficulty: 2),
    // bible:MAT.6.3, conf=0.89, freq=35
  AwingWord(awing: 'nəfɔ', english: 'kingdom', category: 'general', difficulty: 2),
    // bible:MAT.8.12, conf=0.43, freq=35
  AwingWord(awing: 'əfə́g', english: 'blind', category: 'general', difficulty: 2),
    // bible:MAT.8.15, conf=0.51, freq=35
  AwingWord(awing: 'yɛ́d', english: 'signs', category: 'general', difficulty: 2),
    // bible:MAT.21.15, conf=0.77, freq=35
  AwingWord(awing: 'Ńtsəʼ', english: 'christ', category: 'general', difficulty: 2),
    // bible:MAT.27.17, conf=0.89, freq=35
  AwingWord(awing: 'məfɛ̂nə', english: 'gift', category: 'general', difficulty: 2),
    // bible:JHN.4.10, conf=0.57, freq=35
  AwingWord(awing: 'aləŋənə́fɔ', english: 'throne', category: 'general', difficulty: 2),
    // bible:JHN.12.31, conf=0.91, freq=35
  AwingWord(awing: 'Galiliə', english: 'galilee', category: 'general', difficulty: 2),
    // bible:MAT.4.12, conf=0.82, freq=34
  AwingWord(awing: 'ngaŋə́sáʼə́məsáʼ', english: 'council', category: 'general', difficulty: 2),
    // bible:MAT.5.25, conf=0.44, freq=34
  AwingWord(awing: 'ntsǒndɛ̂', english: 'door', category: 'general', difficulty: 2),
    // bible:MAT.6.6, conf=0.53, freq=34
  AwingWord(awing: 'əshî', english: 'face', category: 'general', difficulty: 2),
    // bible:MAT.6.16, conf=0.44, freq=34
  AwingWord(awing: 'Debilə', english: 'david', category: 'general', difficulty: 2),
    // bible:MAT.1.1, conf=0.85, freq=33
  AwingWord(awing: 'Debid', english: 'david', category: 'general', difficulty: 2),
    // bible:MAT.1.17, conf=0.88, freq=33
  AwingWord(awing: 'Ɛlɔdə', english: 'herod', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=0.85, freq=33
  AwingWord(awing: 'azáŋə́ndé', english: 'wrath', category: 'general', difficulty: 2),
    // bible:MAT.3.7, conf=0.76, freq=33
  AwingWord(awing: 'ndzoŋdzəm', english: 'disciple', category: 'general', difficulty: 2),
    // bible:MAT.8.21, conf=0.61, freq=33
  AwingWord(awing: 'atséebə́nə́múʼ', english: 'parable', category: 'general', difficulty: 2),
    // bible:MAT.13.3, conf=0.85, freq=33
  AwingWord(awing: 'tə́kɔʼə', english: 'great', category: 'general', difficulty: 2),
    // bible:MAT.13.32, conf=0.48, freq=33
  AwingWord(awing: 'ntsɛɛmbiə', english: 'first', category: 'general', difficulty: 2),
    // bible:MAT.21.36, conf=0.64, freq=33
  AwingWord(awing: 'laʼnə̂', english: 'promise', category: 'general', difficulty: 2),
    // bible:LUK.1.54, conf=0.45, freq=33
  AwingWord(awing: 'mə̂ghabə', english: 'adultery', category: 'general', difficulty: 2),
    // bible:MAT.5.27, conf=0.68, freq=31
  AwingWord(awing: 'zɛ́n', english: 'two', category: 'general', difficulty: 2),
    // bible:MAT.8.28, conf=0.45, freq=31
  AwingWord(awing: 'akóolə́mə́lə́ŋə', english: 'mercy', category: 'general', difficulty: 2),
    // bible:MAT.9.13, conf=0.74, freq=31
  AwingWord(awing: 'ńdíblə', english: 'around', category: 'general', difficulty: 2),
    // bible:MAT.13.2, conf=0.52, freq=31
  AwingWord(awing: 'Islɛlə', english: 'israel', category: 'general', difficulty: 2),
    // bible:MAT.2.6, conf=0.70, freq=30
  AwingWord(awing: 'məngɔʼ', english: 'stones', category: 'general', difficulty: 2),
    // bible:MAT.3.9, conf=0.40, freq=30
  AwingWord(awing: 'ŋ́ŋáŋkə', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.5.16, conf=0.53, freq=30
  AwingWord(awing: 'ntaŋ', english: 'tabernacle', category: 'general', difficulty: 2),
    // bible:MAT.6.2, conf=0.43, freq=30
  AwingWord(awing: '“Mäŋ', english: 'tell', category: 'general', difficulty: 2),
    // bible:MAT.8.10, conf=0.80, freq=30
  AwingWord(awing: '“Tǎ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.11.25, conf=0.57, freq=30
  AwingWord(awing: 'mə́numə', english: 'sun', category: 'general', difficulty: 2),
    // bible:MAT.13.6, conf=0.60, freq=30
  AwingWord(awing: 'Ntseŋndɛ̂', english: 'angel', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.93, freq=29
  AwingWord(awing: 'ńkwěe', english: 'answered', category: 'general', difficulty: 2),
    // bible:MAT.9.12, conf=0.45, freq=29
  AwingWord(awing: 'ndɔ́ŋ', english: 'cup', category: 'general', difficulty: 2),
    // bible:MAT.10.42, conf=0.90, freq=29
  AwingWord(awing: 'júmkə', english: 'raised', category: 'general', difficulty: 2),
    // bible:MAT.11.5, conf=0.55, freq=29
  AwingWord(awing: 'Elayija', english: 'elijah', category: 'general', difficulty: 2),
    // bible:MAT.11.14, conf=0.97, freq=29
  AwingWord(awing: 'apoʼ', english: 'free', category: 'general', difficulty: 2),
    // bible:MAT.18.32, conf=0.69, freq=29
  AwingWord(awing: 'Jɔsɛfə', english: 'joseph', category: 'general', difficulty: 2),
    // bible:MAT.1.18, conf=0.75, freq=28
  AwingWord(awing: 'məŋkwâʼlə̌', english: 'wilderness', category: 'general', difficulty: 2),
    // bible:MAT.3.1, conf=0.82, freq=28
  AwingWord(awing: 'Satan', english: 'satan', category: 'general', difficulty: 2),
    // bible:MAT.4.10, conf=0.57, freq=28
  AwingWord(awing: 'ndzɛnə́', english: 'side', category: 'general', difficulty: 2),
    // bible:MAT.4.15, conf=0.43, freq=28
  AwingWord(awing: 'nəghə́m', english: 'ten', category: 'general', difficulty: 2),
    // bible:MAT.4.25, conf=0.50, freq=28
  AwingWord(awing: 'Banabasə', english: 'barnabas', category: 'general', difficulty: 2),
    // bible:ACT.9.27, conf=0.71, freq=28
  AwingWord(awing: 'əpa', english: 'another', category: 'general', difficulty: 2),
    // bible:MAT.2.11, conf=0.48, freq=27
  AwingWord(awing: 'nkyaʼə', english: 'light', category: 'general', difficulty: 2),
    // bible:MAT.5.15, conf=0.70, freq=27
  AwingWord(awing: 'nələ́g', english: 'eye', category: 'general', difficulty: 2),
    // bible:MAT.5.29, conf=0.85, freq=27
  AwingWord(awing: 'məghɔ́d', english: 'ointment', category: 'general', difficulty: 2),
    // bible:MAT.6.17, conf=0.59, freq=27
  AwingWord(awing: 'məsânə', english: 'morning', category: 'general', difficulty: 2),
    // bible:MAT.16.3, conf=0.44, freq=27
  AwingWord(awing: 'əlɛ́nə', english: 'name', category: 'general', difficulty: 2),
    // bible:MAT.18.20, conf=0.81, freq=27
  AwingWord(awing: 'Kasa', english: 'caesar', category: 'general', difficulty: 2),
    // bible:MAT.22.17, conf=0.74, freq=27
  AwingWord(awing: 'nəchwaakənə́', english: 'beginning', category: 'general', difficulty: 2),
    // bible:MAT.24.21, conf=0.63, freq=27
  AwingWord(awing: 'Əfooghɨ', english: 'sea', category: 'general', difficulty: 2),
    // bible:MAT.4.13, conf=0.58, freq=26
  AwingWord(awing: 'ngaŋəfaʼə', english: 'servant', category: 'general', difficulty: 2),
    // bible:MAT.8.6, conf=0.46, freq=26
  AwingWord(awing: 'ńkyéŋ', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.8.29, conf=0.58, freq=26
  AwingWord(awing: 'ńnoŋkə̂', english: 'laid', category: 'general', difficulty: 2),
    // bible:MAT.9.18, conf=0.50, freq=26
  AwingWord(awing: 'ntáʼ', english: 'loaves', category: 'general', difficulty: 2),
    // bible:MAT.14.17, conf=0.73, freq=26
  AwingWord(awing: 'ḿmɛdnə̂', english: 'forever', category: 'general', difficulty: 2),
    // bible:JHN.3.15, conf=0.65, freq=26
  AwingWord(awing: 'Ɛlɔd', english: 'herod', category: 'general', difficulty: 2),
    // bible:MAT.2.22, conf=0.80, freq=25
  AwingWord(awing: 'ŋáʼ', english: 'opened', category: 'general', difficulty: 2),
    // bible:MAT.7.7, conf=0.40, freq=25
  AwingWord(awing: 'ndzɛlə', english: 'sheep', category: 'general', difficulty: 2),
    // bible:MAT.7.15, conf=0.40, freq=25
  AwingWord(awing: 'əkɨʼnəmə́nu', english: 'signs', category: 'general', difficulty: 2),
    // bible:MAT.7.22, conf=0.40, freq=25
  AwingWord(awing: 'kɔ́d', english: 'eat', category: 'general', difficulty: 2),
    // bible:MAT.8.12, conf=0.44, freq=25
  AwingWord(awing: 'ńtsóʼ', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.8.16, conf=0.40, freq=25
  AwingWord(awing: 'afyaʼə́nu', english: 'sacrifice', category: 'general', difficulty: 2),
    // bible:MAT.9.13, conf=0.44, freq=25
  AwingWord(awing: 'pɔ̂nkə̂', english: 'children', category: 'general', difficulty: 2),
    // bible:MAT.11.25, conf=0.64, freq=25
  AwingWord(awing: 'əkyeʼmə́nu', english: 'signs', category: 'general', difficulty: 2),
    // bible:MAT.16.3, conf=0.92, freq=25
  AwingWord(awing: 'póʼə', english: 'circumcision', category: 'general', difficulty: 2),
    // bible:MRK.12.4, conf=0.60, freq=25
  AwingWord(awing: 'Masedonya', english: 'macedonia', category: 'general', difficulty: 2),
    // bible:ACT.16.12, conf=0.92, freq=25
  AwingWord(awing: 'apɔŋə́ntɨ́', english: 'grace', category: 'general', difficulty: 2),
    // bible:ROM.6.15, conf=0.80, freq=25
  AwingWord(awing: '“Mɔ̂', english: 'son', category: 'general', difficulty: 2),
    // bible:MAT.1.23, conf=0.50, freq=24
  AwingWord(awing: 'maʼə̂', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.3.10, conf=0.50, freq=24
  AwingWord(awing: 'Dɛbəələ', english: 'devil', category: 'general', difficulty: 2),
    // bible:MAT.4.1, conf=0.88, freq=24
  AwingWord(awing: 'mələ́ŋ', english: 'mercy', category: 'general', difficulty: 2),
    // bible:MAT.5.7, conf=0.54, freq=24
  AwingWord(awing: 'nchubə', english: 'tax', category: 'general', difficulty: 2),
    // bible:MAT.5.46, conf=0.71, freq=24
  AwingWord(awing: 'mənkǐ', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.7.25, conf=0.42, freq=24
  AwingWord(awing: 'nkwanə́', english: 'evening', category: 'general', difficulty: 2),
    // bible:MAT.8.16, conf=0.79, freq=24
  AwingWord(awing: 'ńjúmkə', english: 'raised', category: 'general', difficulty: 2),
    // bible:MAT.10.8, conf=0.75, freq=24
  AwingWord(awing: 'ŋwíŋ', english: 'sword', category: 'general', difficulty: 2),
    // bible:MAT.10.21, conf=0.88, freq=24
  AwingWord(awing: 'mətôglə', english: 'hear', category: 'general', difficulty: 2),
    // bible:MAT.11.15, conf=0.71, freq=24
  AwingWord(awing: 'ŋáʼnə', english: 'opened', category: 'general', difficulty: 2),
    // bible:MAT.3.16, conf=0.57, freq=23
  AwingWord(awing: 'jwaʼ', english: 'anxious', category: 'general', difficulty: 2),
    // bible:MAT.6.25, conf=0.43, freq=23
  AwingWord(awing: 'akwaʼlə', english: 'temptation', category: 'general', difficulty: 2),
    // bible:MAT.6.13, conf=0.45, freq=22
  AwingWord(awing: 'Filibə', english: 'philip', category: 'general', difficulty: 2),
    // bible:MAT.14.3, conf=0.91, freq=22
  AwingWord(awing: 'pwɔ́d', english: 'weak', category: 'general', difficulty: 2),
    // bible:MAT.24.32, conf=0.41, freq=22
  AwingWord(awing: 'məsáʼ', english: 'one', category: 'general', difficulty: 2),
    // bible:MRK.10.42, conf=0.45, freq=22
  AwingWord(awing: 'pəpépə́sê', english: 'priest', category: 'general', difficulty: 2),
    // bible:LUK.6.4, conf=0.45, freq=22
  AwingWord(awing: 'əlam', english: 'body', category: 'general', difficulty: 2),
    // bible:ROM.12.4, conf=0.73, freq=22
  AwingWord(awing: 'pətseŋpə́ndɛ̂', english: 'angels', category: 'general', difficulty: 2),
    // bible:MAT.4.6, conf=0.95, freq=21
  AwingWord(awing: 'kɛ́d', english: 'fire', category: 'general', difficulty: 2),
    // bible:MAT.4.16, conf=0.48, freq=21
  AwingWord(awing: 'nəpá', english: 'altar', category: 'general', difficulty: 2),
    // bible:MAT.5.24, conf=0.86, freq=21
  AwingWord(awing: 'ńtsɔ́ʼtə', english: 'judgment', category: 'general', difficulty: 2),
    // bible:MAT.7.1, conf=0.48, freq=21
  AwingWord(awing: 'ńgoonə̂', english: 'sick', category: 'general', difficulty: 2),
    // bible:MAT.8.14, conf=0.76, freq=21
  AwingWord(awing: '“ghɛn', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.11.4, conf=0.62, freq=21
  AwingWord(awing: 'akóolə́mə́lə́ŋ', english: 'mercy', category: 'general', difficulty: 2),
    // bible:MAT.12.7, conf=0.57, freq=21
  AwingWord(awing: 'mbipú', english: 'seed', category: 'general', difficulty: 2),
    // bible:MAT.13.18, conf=0.43, freq=21
  AwingWord(awing: 'Tsəʼ', english: 'christ', category: 'general', difficulty: 2),
    // bible:MAT.16.16, conf=0.95, freq=21
  AwingWord(awing: 'Antiok', english: 'antioch', category: 'general', difficulty: 2),
    // bible:ACT.6.5, conf=0.71, freq=21
  AwingWord(awing: 'əsɨ́', english: 'ashamed', category: 'general', difficulty: 2),
    // bible:ROM.1.26, conf=0.43, freq=21
  AwingWord(awing: 'mǎpə', english: 'mother', category: 'general', difficulty: 2),
    // bible:MAT.1.16, conf=0.90, freq=20
  AwingWord(awing: 'ńtsóokə', english: 'down', category: 'general', difficulty: 2),
    // bible:MAT.2.16, conf=0.45, freq=20
  AwingWord(awing: 'Izaya', english: 'isaiah', category: 'general', difficulty: 2),
    // bible:MAT.3.3, conf=0.90, freq=20
  AwingWord(awing: 'tɔ́g', english: 'immediately', category: 'general', difficulty: 2),
    // bible:MAT.4.20, conf=0.90, freq=20
  AwingWord(awing: 'ńtsóʼə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.4.23, conf=0.45, freq=20
  AwingWord(awing: 'ləəmə̂', english: 'sat', category: 'general', difficulty: 2),
    // bible:MAT.5.13, conf=0.40, freq=20
  AwingWord(awing: '“Lɔg', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.6.1, conf=0.60, freq=20
  AwingWord(awing: 'ə́sɛ̂nə̌', english: 'today', category: 'general', difficulty: 2),
    // bible:MAT.6.11, conf=0.50, freq=20
  AwingWord(awing: 'ngaŋə́pyáabə', english: 'officers', category: 'general', difficulty: 2),
    // bible:MAT.18.34, conf=0.40, freq=20
  AwingWord(awing: 'nkog', english: 'widow', category: 'general', difficulty: 2),
    // bible:MAT.22.24, conf=0.60, freq=20
  AwingWord(awing: 'achaʼtə', english: 'greet', category: 'general', difficulty: 2),
    // bible:LUK.1.29, conf=0.45, freq=20
  AwingWord(awing: 'əzɛnə̂', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.1.75, conf=0.50, freq=20
  AwingWord(awing: 'tɨd', english: 'boast', category: 'general', difficulty: 2),
    // bible:ROM.11.18, conf=0.70, freq=20
  AwingWord(awing: 'Ijibə', english: 'egypt', category: 'general', difficulty: 2),
    // bible:MAT.2.13, conf=0.68, freq=19
  AwingWord(awing: 'lyáŋ', english: 'hidden', category: 'general', difficulty: 2),
    // bible:MAT.5.14, conf=0.58, freq=19
  AwingWord(awing: 'pəpóŋə', english: 'poor', category: 'general', difficulty: 2),
    // bible:MAT.11.5, conf=0.68, freq=19
  AwingWord(awing: 'akyeʼə́nuə', english: 'sign', category: 'general', difficulty: 2),
    // bible:MAT.12.38, conf=0.89, freq=19
  AwingWord(awing: 'léenə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.13.51, conf=0.42, freq=19
  AwingWord(awing: 'akyeʼə́nu', english: 'sign', category: 'general', difficulty: 2),
    // bible:MAT.16.4, conf=0.74, freq=19
  AwingWord(awing: 'chwád', english: 'saved', category: 'general', difficulty: 2),
    // bible:MAT.24.22, conf=0.68, freq=19
  AwingWord(awing: 'Amɛn', english: 'amen', category: 'general', difficulty: 2),
    // bible:MRK.16.20, conf=0.95, freq=19
  AwingWord(awing: 'awaamə́ntə́əmə', english: 'perseverance', category: 'general', difficulty: 2),
    // bible:ROM.5.3, conf=0.53, freq=19
  AwingWord(awing: 'ngyaʼə́', english: 'house', category: 'general', difficulty: 2),
    // bible:MAT.1.20, conf=0.44, freq=18
  AwingWord(awing: 'məkoolə', english: 'feet', category: 'general', difficulty: 2),
    // bible:MAT.5.13, conf=0.72, freq=18
  AwingWord(awing: 'pəsə́ŋ', english: 'birds', category: 'general', difficulty: 2),
    // bible:MAT.6.26, conf=0.78, freq=18
  AwingWord(awing: 'akəkógə́', english: 'foolish', category: 'general', difficulty: 2),
    // bible:MAT.7.26, conf=0.44, freq=18
  AwingWord(awing: 'tǎdndzɔʼə́', english: 'bridegroom', category: 'general', difficulty: 2),
    // bible:MAT.9.15, conf=1.00, freq=18
  AwingWord(awing: 'pəfəg', english: 'blind', category: 'general', difficulty: 2),
    // bible:MAT.9.27, conf=1.00, freq=18
  AwingWord(awing: 'məlɛ́n', english: 'names', category: 'general', difficulty: 2),
    // bible:MAT.10.2, conf=0.44, freq=18
  AwingWord(awing: 'ngəsáŋ', english: 'wheat', category: 'general', difficulty: 2),
    // bible:MAT.12.1, conf=0.50, freq=18
  AwingWord(awing: '“Pɛn', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.15.33, conf=0.61, freq=18
  AwingWord(awing: 'póonə', english: 'children', category: 'general', difficulty: 2),
    // bible:MAT.16.18, conf=0.72, freq=18
  AwingWord(awing: 'Esya', english: 'asia', category: 'general', difficulty: 2),
    // bible:ACT.2.9, conf=0.89, freq=18
  AwingWord(awing: 'Jɔsɛf', english: 'joseph', category: 'general', difficulty: 2),
    // bible:MAT.1.19, conf=0.53, freq=17
  AwingWord(awing: 'ńkwə́ʼtə', english: 'down', category: 'general', difficulty: 2),
    // bible:MAT.2.11, conf=0.53, freq=17
  AwingWord(awing: 'shaʼtə̂', english: 'down', category: 'general', difficulty: 2),
    // bible:MAT.5.17, conf=0.41, freq=17
  AwingWord(awing: 'kəm', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.8.16, conf=0.76, freq=17
  AwingWord(awing: 'pəmə́nu', english: 'hour', category: 'general', difficulty: 2),
    // bible:MAT.14.25, conf=0.71, freq=17
  AwingWord(awing: 'Falasi', english: 'pharisee', category: 'general', difficulty: 2),
    // bible:MAT.15.12, conf=0.65, freq=17
  AwingWord(awing: 'Sisalya', english: 'caesarea', category: 'general', difficulty: 2),
    // bible:MAT.16.13, conf=0.71, freq=17
  AwingWord(awing: 'nəfɛdnə́', english: 'beginning', category: 'general', difficulty: 2),
    // bible:MAT.19.4, conf=0.47, freq=17
  AwingWord(awing: '“Əghâ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.24.32, conf=0.47, freq=17
  AwingWord(awing: 'Judas', english: 'judas', category: 'general', difficulty: 2),
    // bible:MAT.26.47, conf=0.71, freq=17
  AwingWord(awing: 'láʼkə', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.17.9, conf=0.82, freq=17
  AwingWord(awing: 'Ijib', english: 'egypt', category: 'general', difficulty: 2),
    // bible:ACT.7.10, conf=0.71, freq=17
  AwingWord(awing: 'Sɔl', english: 'saul', category: 'general', difficulty: 2),
    // bible:ACT.7.58, conf=0.82, freq=17
  AwingWord(awing: 'Timoti', english: 'timothy', category: 'general', difficulty: 2),
    // bible:ACT.16.2, conf=0.76, freq=17
  AwingWord(awing: '“Lǒo', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.2.20, conf=0.62, freq=16
  AwingWord(awing: 'ngɔʼə', english: 'stone', category: 'general', difficulty: 2),
    // bible:MAT.4.6, conf=0.62, freq=16
  AwingWord(awing: 'Nazalɛd', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.4.13, conf=0.88, freq=16
  AwingWord(awing: 'ńtɔ́g', english: 'immediately', category: 'general', difficulty: 2),
    // bible:MAT.4.22, conf=0.75, freq=16
  AwingWord(awing: 'məndɛ̂', english: 'synagogues', category: 'general', difficulty: 2),
    // bible:MAT.4.23, conf=0.50, freq=16
  AwingWord(awing: 'məghɔ', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.4.23, conf=0.44, freq=16
  AwingWord(awing: 'alamə́', english: 'members', category: 'general', difficulty: 2),
    // bible:MAT.5.29, conf=0.56, freq=16
  AwingWord(awing: 'ntsǒnkáʼ', english: 'gate', category: 'general', difficulty: 2),
    // bible:MAT.7.13, conf=0.44, freq=16
  AwingWord(awing: 'kəfɨd', english: 'wind', category: 'general', difficulty: 2),
    // bible:MAT.8.26, conf=0.81, freq=16
  AwingWord(awing: 'pəkwúna', english: 'pigs', category: 'general', difficulty: 2),
    // bible:MAT.8.30, conf=0.81, freq=16
  AwingWord(awing: 'ńkwum', english: 'touched', category: 'general', difficulty: 2),
    // bible:MAT.9.20, conf=0.50, freq=16
  AwingWord(awing: 'məfag', english: 'branches', category: 'general', difficulty: 2),
    // bible:MAT.13.32, conf=0.62, freq=16
  AwingWord(awing: 'ayáŋ', english: 'wisdom', category: 'general', difficulty: 2),
    // bible:MAT.13.54, conf=0.81, freq=16
  AwingWord(awing: 'kwɛlə̂', english: 'poured', category: 'general', difficulty: 2),
    // bible:MAT.24.2, conf=0.50, freq=16
  AwingWord(awing: '‘Maŋ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.24.5, conf=0.62, freq=16
  AwingWord(awing: 'Payilɛd', english: 'pilate', category: 'general', difficulty: 2),
    // bible:MAT.27.2, conf=0.81, freq=16
  AwingWord(awing: 'Saamunə', english: 'simon', category: 'general', difficulty: 2),
    // bible:MAT.27.32, conf=0.88, freq=16
  AwingWord(awing: 'kwíŋ', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.2.52, conf=0.50, freq=16
  AwingWord(awing: 'pəlú', english: 'husbands', category: 'general', difficulty: 2),
    // bible:JHN.4.18, conf=0.75, freq=16
  AwingWord(awing: 'Jekɔbə', english: 'jacob', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=1.00, freq=15
  AwingWord(awing: 'ŋ́ŋáʼ', english: 'opened', category: 'general', difficulty: 2),
    // bible:MAT.2.11, conf=0.53, freq=15
  AwingWord(awing: '“Mɛdtə̂', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.3.2, conf=0.53, freq=15
  AwingWord(awing: 'mənoŋ', english: 'hair', category: 'general', difficulty: 2),
    // bible:MAT.3.4, conf=0.80, freq=15
  AwingWord(awing: 'kwaʼlə̂', english: 'tempted', category: 'general', difficulty: 2),
    // bible:MAT.4.1, conf=0.47, freq=15
  AwingWord(awing: 'ńtwə́ŋə', english: 'buried', category: 'general', difficulty: 2),
    // bible:MAT.8.21, conf=0.40, freq=15
  AwingWord(awing: 'Filib', english: 'philip', category: 'general', difficulty: 2),
    // bible:MAT.10.3, conf=0.93, freq=15
  AwingWord(awing: 'yáŋ', english: 'wise', category: 'general', difficulty: 2),
    // bible:MAT.11.25, conf=0.60, freq=15
  AwingWord(awing: 'Alěláʼsê', english: 'sabbath', category: 'general', difficulty: 2),
    // bible:MAT.12.1, conf=1.00, freq=15
  AwingWord(awing: 'ńkɔ́lə', english: 'eat', category: 'general', difficulty: 2),
    // bible:MAT.12.1, conf=0.47, freq=15
  AwingWord(awing: 'pɛ̌npə', english: 'christ', category: 'general', difficulty: 2),
    // bible:MAT.13.56, conf=0.67, freq=15
  AwingWord(awing: 'wad', english: 'covenant', category: 'general', difficulty: 2),
    // bible:MAT.14.7, conf=0.47, freq=15
  AwingWord(awing: 'jú', english: 'buy', category: 'general', difficulty: 2),
    // bible:MAT.14.15, conf=0.40, freq=15
  AwingWord(awing: 'alə́m', english: 'cloud', category: 'general', difficulty: 2),
    // bible:MAT.16.3, conf=0.60, freq=15
  AwingWord(awing: 'kyaʼ', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.16.17, conf=0.40, freq=15
  AwingWord(awing: 'pəkog', english: 'widows', category: 'general', difficulty: 2),
    // bible:MAT.23.13, conf=0.93, freq=15
  AwingWord(awing: 'Əkəkóg', english: 'foolish', category: 'general', difficulty: 2),
    // bible:MAT.23.17, conf=0.47, freq=15
  AwingWord(awing: 'Olif', english: 'olive', category: 'general', difficulty: 2),
    // bible:MAT.24.3, conf=0.53, freq=15
  AwingWord(awing: 'ńtsɛntə̂', english: 'together', category: 'general', difficulty: 2),
    // bible:MAT.26.3, conf=0.60, freq=15
  AwingWord(awing: 'nkaŋŋwu', english: 'young', category: 'general', difficulty: 2),
    // bible:MRK.14.51, conf=0.60, freq=15
  AwingWord(awing: 'ndíʼ', english: 'smoke', category: 'general', difficulty: 2),
    // bible:MRK.16.18, conf=0.73, freq=15
  AwingWord(awing: 'ńchaʼtə̂', english: 'greet', category: 'general', difficulty: 2),
    // bible:LUK.1.40, conf=0.60, freq=15
  AwingWord(awing: 'Lazalɔsə', english: 'lazarus', category: 'general', difficulty: 2),
    // bible:LUK.16.20, conf=0.73, freq=15
  AwingWord(awing: 'pəshunə́', english: 'beloved', category: 'general', difficulty: 2),
    // bible:LUK.23.12, conf=0.67, freq=15
  AwingWord(awing: 'əpoʼə', english: 'righteousness', category: 'general', difficulty: 2),
    // bible:JHN.8.33, conf=0.47, freq=15
  AwingWord(awing: 'Joppa', english: 'joppa', category: 'general', difficulty: 2),
    // bible:ACT.9.36, conf=0.73, freq=15
  AwingWord(awing: 'Ɛfesus', english: 'ephesus', category: 'general', difficulty: 2),
    // bible:ACT.18.19, conf=0.67, freq=15
  AwingWord(awing: 'Fɛstusə', english: 'festus', category: 'general', difficulty: 2),
    // bible:ACT.24.27, conf=0.80, freq=15
  AwingWord(awing: 'kɔntə̂', english: 'without', category: 'general', difficulty: 2),
    // bible:ROM.9.32, conf=0.40, freq=15
  AwingWord(awing: 'Azigə', english: 'isaac', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=0.93, freq=14
  AwingWord(awing: '“Əsê', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.1.23, conf=0.79, freq=14
  AwingWord(awing: 'Kapanawum', english: 'capernaum', category: 'general', difficulty: 2),
    // bible:MAT.4.13, conf=0.93, freq=14
  AwingWord(awing: 'ngaŋə́kwáalə́', english: 'tax', category: 'general', difficulty: 2),
    // bible:MAT.5.46, conf=1.00, freq=14
  AwingWord(awing: 'pəzə̌', english: 'robbers', category: 'general', difficulty: 2),
    // bible:MAT.6.19, conf=0.57, freq=14
  AwingWord(awing: 'nchîndɛ̂', english: 'house', category: 'general', difficulty: 2),
    // bible:MAT.9.6, conf=0.71, freq=14
  AwingWord(awing: 'koʼlə̂', english: 'faith', category: 'general', difficulty: 2),
    // bible:MAT.11.6, conf=0.43, freq=14
  AwingWord(awing: 'lá', english: 'understand', category: 'general', difficulty: 2),
    // bible:MAT.13.19, conf=0.57, freq=14
  AwingWord(awing: '“Jwə́ʼtə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.15.10, conf=0.64, freq=14
  AwingWord(awing: 'Akwaŋə́nuə', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.16.23, conf=0.43, freq=14
  AwingWord(awing: 'nəpuʼə́', english: 'nine', category: 'general', difficulty: 2),
    // bible:MAT.18.12, conf=0.64, freq=14
  AwingWord(awing: 'Bɛtani', english: 'bethany', category: 'general', difficulty: 2),
    // bible:MAT.21.17, conf=0.86, freq=14
  AwingWord(awing: 'ndzə̌lə', english: 'thief', category: 'general', difficulty: 2),
    // bible:MAT.24.43, conf=0.71, freq=14
  AwingWord(awing: 'məndú', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.1.75, conf=0.43, freq=14
  AwingWord(awing: 'Sɔlə', english: 'saul', category: 'general', difficulty: 2),
    // bible:ACT.8.3, conf=0.57, freq=14
  AwingWord(awing: 'pələəmə́', english: 'horses', category: 'general', difficulty: 2),
    // bible:ACT.8.28, conf=0.57, freq=14
  AwingWord(awing: 'lɔ́btə', english: 'god', category: 'general', difficulty: 2),
    // bible:ACT.9.24, conf=0.57, freq=14
  AwingWord(awing: 'afyaʼə́', english: 'strife', category: 'general', difficulty: 2),
    // bible:ACT.23.7, conf=0.50, freq=14
  AwingWord(awing: 'ə́fyagə̂', english: 'perfect', category: 'general', difficulty: 2),
    // bible:ROM.12.2, conf=0.50, freq=14
  AwingWord(awing: 'Əfɛ̂nkǐə', english: 'john', category: 'general', difficulty: 2),
    // bible:MAT.3.1, conf=1.00, freq=13
  AwingWord(awing: 'kə́ʼ', english: 'measure', category: 'general', difficulty: 2),
    // bible:MAT.3.10, conf=0.54, freq=13
  AwingWord(awing: 'əpí', english: 'clothing', category: 'general', difficulty: 2),
    // bible:MAT.3.12, conf=0.46, freq=13
  AwingWord(awing: 'Andəlu', english: 'andrew', category: 'general', difficulty: 2),
    // bible:MAT.4.18, conf=1.00, freq=13
  AwingWord(awing: '“Yeso', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.4.19, conf=0.62, freq=13
  AwingWord(awing: 'kwɛd', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.5.13, conf=0.54, freq=13
  AwingWord(awing: 'zô', english: 'eye', category: 'general', difficulty: 2),
    // bible:MAT.5.29, conf=0.54, freq=13
  AwingWord(awing: 'əsêndú', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.7.2, conf=0.46, freq=13
  AwingWord(awing: 'Mbəŋ', english: 'rain', category: 'general', difficulty: 2),
    // bible:MAT.7.25, conf=0.69, freq=13
  AwingWord(awing: 'mənka', english: 'baskets', category: 'general', difficulty: 2),
    // bible:MAT.8.20, conf=0.62, freq=13
  AwingWord(awing: 'ḿbyáanə', english: 'take', category: 'general', difficulty: 2),
    // bible:MAT.9.6, conf=0.46, freq=13
  AwingWord(awing: 'əfoʼ', english: 'rich', category: 'general', difficulty: 2),
    // bible:MAT.9.38, conf=0.62, freq=13
  AwingWord(awing: 'zɔ', english: 'blasphemy', category: 'general', difficulty: 2),
    // bible:MAT.12.31, conf=0.46, freq=13
  AwingWord(awing: '“yǐ', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.14.18, conf=0.54, freq=13
  AwingWord(awing: 'pəghɔ', english: 'sick', category: 'general', difficulty: 2),
    // bible:MAT.14.35, conf=0.85, freq=13
  AwingWord(awing: 'mbóomə', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.15.3, conf=0.46, freq=13
  AwingWord(awing: 'sháŋ', english: 'man', category: 'general', difficulty: 2),
    // bible:MAT.15.38, conf=0.46, freq=13
  AwingWord(awing: 'nəghə́mə', english: 'ten', category: 'general', difficulty: 2),
    // bible:MAT.18.28, conf=0.77, freq=13
  AwingWord(awing: 'sɔb', english: 'against', category: 'general', difficulty: 2),
    // bible:MAT.24.7, conf=0.85, freq=13
  AwingWord(awing: 'alěmbî', english: 'day', category: 'general', difficulty: 2),
    // bible:MAT.24.36, conf=0.85, freq=13
  AwingWord(awing: 'fúfú', english: 'white', category: 'general', difficulty: 2),
    // bible:MAT.27.59, conf=0.46, freq=13
  AwingWord(awing: 'əshɨ́', english: 'ashamed', category: 'general', difficulty: 2),
    // bible:MRK.8.38, conf=0.54, freq=13
  AwingWord(awing: 'Aglɛpa', english: 'agrippa', category: 'general', difficulty: 2),
    // bible:ACT.25.13, conf=0.85, freq=13
  AwingWord(awing: 'achǐ', english: 'blood', category: 'general', difficulty: 2),
    // bible:1CO.15.50, conf=0.92, freq=13
  AwingWord(awing: 'Jekɔb', english: 'jacob', category: 'general', difficulty: 2),
    // bible:MAT.1.2, conf=0.92, freq=12
  AwingWord(awing: 'nɔd', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.6.24, conf=0.42, freq=12
  AwingWord(awing: 'Tɔməsə', english: 'thomas', category: 'general', difficulty: 2),
    // bible:MAT.10.3, conf=0.92, freq=12
  AwingWord(awing: 'mbaŋ', english: 'mustard', category: 'general', difficulty: 2),
    // bible:MAT.10.10, conf=0.42, freq=12
  AwingWord(awing: '“Mbwɔ́dnə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.10.12, conf=0.67, freq=12
  AwingWord(awing: 'Tayile', english: 'tyre', category: 'general', difficulty: 2),
    // bible:MAT.11.21, conf=1.00, freq=12
  AwingWord(awing: 'ńkwɛlə̂', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.13.48, conf=0.50, freq=12
  AwingWord(awing: 'akáŋ', english: 'poured', category: 'general', difficulty: 2),
    // bible:MAT.14.11, conf=0.42, freq=12
  AwingWord(awing: 'ḿbagtə̂', english: 'broke', category: 'general', difficulty: 2),
    // bible:MAT.14.19, conf=0.83, freq=12
  AwingWord(awing: 'fig', english: 'tree', category: 'general', difficulty: 2),
    // bible:MAT.21.19, conf=0.92, freq=12
  AwingWord(awing: 'məngɔʼə', english: 'stones', category: 'general', difficulty: 2),
    // bible:MAT.21.35, conf=0.42, freq=12
  AwingWord(awing: 'lə́ʼ', english: 'escape', category: 'general', difficulty: 2),
    // bible:MAT.23.33, conf=0.50, freq=12
  AwingWord(awing: 'Balabasə', english: 'barabbas', category: 'general', difficulty: 2),
    // bible:MAT.27.16, conf=0.92, freq=12
  AwingWord(awing: 'lɛn', english: 'old', category: 'general', difficulty: 2),
    // bible:MRK.2.21, conf=1.00, freq=12
  AwingWord(awing: 'Samalya', english: 'samaria', category: 'general', difficulty: 2),
    // bible:LUK.17.11, conf=0.83, freq=12
  AwingWord(awing: 'zɔ́b', english: 'officer', category: 'general', difficulty: 2),
    // bible:LUK.20.20, conf=0.42, freq=12
  AwingWord(awing: 'Jusə', english: 'jew', category: 'general', difficulty: 2),
    // bible:JHN.3.25, conf=0.50, freq=12
  AwingWord(awing: 'Banabas', english: 'barnabas', category: 'general', difficulty: 2),
    // bible:ACT.4.36, conf=0.75, freq=12
  AwingWord(awing: 'nəkaʼ', english: 'remains', category: 'general', difficulty: 2),
    // bible:ROM.6.3, conf=0.50, freq=12
  AwingWord(awing: 'ə́fyag', english: 'perfect', category: 'general', difficulty: 2),
    // bible:1CO.13.9, conf=0.50, freq=12
  AwingWord(awing: 'nətúʼə', english: 'night', category: 'general', difficulty: 2),
    // bible:MAT.2.14, conf=1.00, freq=11
  AwingWord(awing: 'kə́yé', english: 'children', category: 'general', difficulty: 2),
    // bible:MAT.2.16, conf=0.64, freq=11
  AwingWord(awing: 'Nazalɛlə', english: 'nazareth', category: 'general', difficulty: 2),
    // bible:MAT.2.23, conf=0.91, freq=11
  AwingWord(awing: 'mənteemə́', english: 'fruit', category: 'general', difficulty: 2),
    // bible:MAT.3.8, conf=0.82, freq=11
  AwingWord(awing: 'ngwɛʼə́', english: 'tomorrow', category: 'general', difficulty: 2),
    // bible:MAT.6.30, conf=1.00, freq=11
  AwingWord(awing: 'ńtoonə̂', english: 'burned', category: 'general', difficulty: 2),
    // bible:MAT.7.19, conf=0.45, freq=11
  AwingWord(awing: 'Iskaliɔt', english: 'judas', category: 'general', difficulty: 2),
    // bible:MAT.10.4, conf=1.00, freq=11
  AwingWord(awing: 'ngɔ́n', english: 'darnel', category: 'general', difficulty: 2),
    // bible:MAT.13.26, conf=0.55, freq=11
  AwingWord(awing: 'atǐəpagləpaglə', english: 'cross', category: 'general', difficulty: 2),
    // bible:MAT.16.24, conf=0.73, freq=11
  AwingWord(awing: 'Zakalya', english: 'zacharias', category: 'general', difficulty: 2),
    // bible:MAT.23.35, conf=0.73, freq=11
  AwingWord(awing: 'məŋnkwəənə', english: 'mountains', category: 'general', difficulty: 2),
    // bible:MAT.24.16, conf=0.82, freq=11
  AwingWord(awing: 'nəfaŋ', english: 'thunders', category: 'general', difficulty: 2),
    // bible:MAT.24.27, conf=0.45, freq=11
  AwingWord(awing: 'ntə̌blə', english: 'naked', category: 'general', difficulty: 2),
    // bible:MAT.25.38, conf=0.82, freq=11
  AwingWord(awing: 'məloʼə', english: 'wine', category: 'general', difficulty: 2),
    // bible:MRK.15.23, conf=0.45, freq=11
  AwingWord(awing: '“Mmaʼmbîə', english: 'lord', category: 'general', difficulty: 2),
    // bible:LUK.1.25, conf=1.00, freq=11
  AwingWord(awing: 'achîəndɛ̂', english: 'foundation', category: 'general', difficulty: 2),
    // bible:LUK.6.48, conf=0.73, freq=11
  AwingWord(awing: 'ńdzoŋkə̂', english: 'second', category: 'general', difficulty: 2),
    // bible:ACT.7.13, conf=0.82, freq=11
  AwingWord(awing: 'mətûə', english: 'elders', category: 'general', difficulty: 2),
    // bible:ACT.14.23, conf=0.45, freq=11
  AwingWord(awing: 'Mɛkisidɛgə', english: 'melchizedek', category: 'general', difficulty: 2),
    // bible:HEB.5.6, conf=0.82, freq=11
  AwingWord(awing: 'Pəsadusi', english: 'sadducees', category: 'general', difficulty: 2),
    // bible:MAT.3.7, conf=1.00, freq=10
  AwingWord(awing: 'Zebedi', english: 'zebedee', category: 'general', difficulty: 2),
    // bible:MAT.4.21, conf=1.00, freq=10
  AwingWord(awing: 'ntsɔ́ʼəfaʼə', english: 'reward', category: 'general', difficulty: 2),
    // bible:MAT.5.12, conf=0.70, freq=10
  AwingWord(awing: 'ngaŋmə́fɨg', english: 'hypocrites', category: 'general', difficulty: 2),
    // bible:MAT.6.2, conf=0.70, freq=10
  AwingWord(awing: 'ngaŋmə́fɨgə', english: 'hypocrites', category: 'general', difficulty: 2),
    // bible:MAT.6.5, conf=1.00, freq=10
  AwingWord(awing: 'məshî', english: 'faces', category: 'general', difficulty: 2),
    // bible:MAT.6.16, conf=0.70, freq=10
  AwingWord(awing: 'ajɨ́', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.6.17, conf=0.40, freq=10
  AwingWord(awing: 'ńtɛ̂', english: 'sun', category: 'general', difficulty: 2),
    // bible:MAT.6.28, conf=0.50, freq=10
  AwingWord(awing: 'məmí', english: 'own', category: 'general', difficulty: 2),
    // bible:MAT.6.34, conf=0.40, freq=10
  AwingWord(awing: 'ńtə́m', english: 'lots', category: 'general', difficulty: 2),
    // bible:MAT.7.25, conf=0.40, freq=10
  AwingWord(awing: 'ńkwéʼnə', english: 'even', category: 'general', difficulty: 2),
    // bible:MAT.8.26, conf=0.40, freq=10
  AwingWord(awing: 'nəlwî', english: 'touched', category: 'general', difficulty: 2),
    // bible:MAT.9.20, conf=0.40, freq=10
  AwingWord(awing: '“Anuə', english: 'kingdom', category: 'general', difficulty: 2),
    // bible:MAT.10.7, conf=0.90, freq=10
  AwingWord(awing: 'pəmǎ', english: 'parents', category: 'general', difficulty: 2),
    // bible:MAT.10.21, conf=0.60, freq=10
  AwingWord(awing: 'mə́lə́glə', english: 'shadow', category: 'general', difficulty: 2),
    // bible:MAT.10.28, conf=0.60, freq=10
  AwingWord(awing: 'Jona', english: 'jonah', category: 'general', difficulty: 2),
    // bible:MAT.12.39, conf=1.00, freq=10
  AwingWord(awing: 'məŋaŋ', english: 'root', category: 'general', difficulty: 2),
    // bible:MAT.13.6, conf=0.70, freq=10
  AwingWord(awing: 'ətsábnə́múʼ', english: 'parables', category: 'general', difficulty: 2),
    // bible:MAT.13.53, conf=0.70, freq=10
  AwingWord(awing: '“Pó', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.14.16, conf=0.50, freq=10
  AwingWord(awing: 'əpuʼ', english: 'baskets', category: 'general', difficulty: 2),
    // bible:MAT.14.20, conf=0.70, freq=10
  AwingWord(awing: 'mələ́ŋə', english: 'mercy', category: 'general', difficulty: 2),
    // bible:MAT.15.22, conf=0.70, freq=10
  AwingWord(awing: 'ŋwuntə̂', english: 'murmured', category: 'general', difficulty: 2),
    // bible:MAT.20.11, conf=0.40, freq=10
  AwingWord(awing: 'ə́sog', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.23.26, conf=0.40, freq=10
  AwingWord(awing: 'pəlê', english: 'sleep', category: 'general', difficulty: 2),
    // bible:MAT.25.5, conf=0.50, freq=10
  AwingWord(awing: 'ńjúnə', english: 'bought', category: 'general', difficulty: 2),
    // bible:MAT.27.7, conf=0.50, freq=10
  AwingWord(awing: 'ńgɔ', english: 'sick', category: 'general', difficulty: 2),
    // bible:MRK.5.25, conf=0.60, freq=10
  AwingWord(awing: 'məndɔ́ŋ', english: 'horns', category: 'general', difficulty: 2),
    // bible:MRK.7.4, conf=0.80, freq=10
  AwingWord(awing: 'Elisabɛlə', english: 'elizabeth', category: 'general', difficulty: 2),
    // bible:LUK.1.5, conf=0.80, freq=10
  AwingWord(awing: 'ngɛdtəpɔŋə', english: 'sinner', category: 'general', difficulty: 2),
    // bible:LUK.5.8, conf=0.60, freq=10
  AwingWord(awing: 'Ghə́glə', english: 'quickly', category: 'general', difficulty: 2),
    // bible:LUK.14.21, conf=0.40, freq=10
  AwingWord(awing: 'tə́mtə', english: 'stone', category: 'general', difficulty: 2),
    // bible:LUK.20.6, conf=0.60, freq=10
  AwingWord(awing: 'ńdjɨ́', english: 'said', category: 'general', difficulty: 2),
    // bible:JHN.7.48, conf=0.40, freq=10
  AwingWord(awing: 'ngaŋntsəələ', english: 'liar', category: 'general', difficulty: 2),
    // bible:JHN.8.44, conf=0.60, freq=10
  AwingWord(awing: 'Stifən', english: 'stephen', category: 'general', difficulty: 2),
    // bible:ACT.6.5, conf=0.50, freq=10
  AwingWord(awing: 'Paŋ', english: 'red', category: 'general', difficulty: 2),
    // bible:ACT.7.36, conf=0.60, freq=10
  AwingWord(awing: 'Akaya', english: 'achaia', category: 'general', difficulty: 2),
    // bible:ACT.18.12, conf=1.00, freq=10
  AwingWord(awing: 'kətɨd', english: 'boasting', category: 'general', difficulty: 2),
    // bible:ROM.15.17, conf=0.60, freq=10
  AwingWord(awing: 'asəgə́ndzɔʼə', english: 'lord', category: 'general', difficulty: 2),
    // bible:COL.3.12, conf=0.50, freq=10
  AwingWord(awing: 'Aky', english: 'god', category: 'general', difficulty: 2),
    // bible:REV.1.8, conf=0.50, freq=10
  AwingWord(awing: 'Jodanə', english: 'jordan', category: 'general', difficulty: 2),
    // bible:MAT.3.6, conf=1.00, freq=9
  AwingWord(awing: 'mənó', english: 'serpents', category: 'general', difficulty: 2),
    // bible:MAT.3.7, conf=0.56, freq=9
  AwingWord(awing: 'sɛlə̂', english: 'become', category: 'general', difficulty: 2),
    // bible:MAT.4.3, conf=0.56, freq=9
  AwingWord(awing: 'pəghoonə́', english: 'sick', category: 'general', difficulty: 2),
    // bible:MAT.4.24, conf=0.67, freq=9
  AwingWord(awing: 'tɛ̂', english: 'sun', category: 'general', difficulty: 2),
    // bible:MAT.5.45, conf=0.44, freq=9
  AwingWord(awing: 'fyag', english: 'perfect', category: 'general', difficulty: 2),
    // bible:MAT.5.48, conf=0.67, freq=9
  AwingWord(awing: 'kwaabə', english: 'right', category: 'general', difficulty: 2),
    // bible:MAT.6.3, conf=0.89, freq=9
  AwingWord(awing: 'achaʼtə́sênji', english: 'fast', category: 'general', difficulty: 2),
    // bible:MAT.6.16, conf=0.67, freq=9
  AwingWord(awing: 'póʼtə', english: 'opened', category: 'general', difficulty: 2),
    // bible:MAT.7.7, conf=0.56, freq=9
  AwingWord(awing: 'Ngaŋnkaʼ', english: 'lepers', category: 'general', difficulty: 2),
    // bible:MAT.8.2, conf=0.44, freq=9
  AwingWord(awing: 'nkweglə', english: 'paralytic', category: 'general', difficulty: 2),
    // bible:MAT.9.2, conf=0.78, freq=9
  AwingWord(awing: 'pəkwûə', english: 'dead', category: 'general', difficulty: 2),
    // bible:MAT.10.8, conf=0.78, freq=9
  AwingWord(awing: 'asáʼə́məsáʼ', english: 'judgment', category: 'general', difficulty: 2),
    // bible:MAT.10.15, conf=0.67, freq=9
  AwingWord(awing: 'ńdzɔb', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.11.17, conf=0.44, freq=9
  AwingWord(awing: 'mənaŋ', english: 'jews', category: 'general', difficulty: 2),
    // bible:MAT.12.14, conf=0.44, freq=9
  AwingWord(awing: 'ńjú', english: 'bought', category: 'general', difficulty: 2),
    // bible:MAT.13.44, conf=0.44, freq=9
  AwingWord(awing: '“Fɛ̂', english: 'give', category: 'general', difficulty: 2),
    // bible:MAT.14.8, conf=0.56, freq=9
  AwingWord(awing: 'ńtsəŋ', english: 'ointment', category: 'general', difficulty: 2),
    // bible:MAT.15.19, conf=0.67, freq=9
  AwingWord(awing: 'təpɛlə', english: 'table', category: 'general', difficulty: 2),
    // bible:MAT.15.27, conf=0.78, freq=9
  AwingWord(awing: 'chúʼ', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.18.24, conf=0.56, freq=9
  AwingWord(awing: 'Iblu', english: 'hebrew', category: 'general', difficulty: 2),
    // bible:MAT.21.9, conf=0.67, freq=9
  AwingWord(awing: 'Ə́sɛdkə̂', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.21.12, conf=0.44, freq=9
  AwingWord(awing: 'ətəənə́', english: 'anchors', category: 'general', difficulty: 2),
    // bible:MAT.22.15, conf=0.44, freq=9
  AwingWord(awing: '“Ndɔ', english: 'woe', category: 'general', difficulty: 2),
    // bible:MAT.23.15, conf=0.67, freq=9
  AwingWord(awing: 'lə́g', english: 'unless', category: 'general', difficulty: 2),
    // bible:MAT.24.22, conf=0.44, freq=9
  AwingWord(awing: 'məfǔ', english: 'tree', category: 'general', difficulty: 2),
    // bible:MAT.24.32, conf=0.56, freq=9
  AwingWord(awing: 'məŋwíŋ', english: 'swords', category: 'general', difficulty: 2),
    // bible:MAT.26.47, conf=0.67, freq=9
  AwingWord(awing: 'Lebi', english: 'levi', category: 'general', difficulty: 2),
    // bible:MRK.2.14, conf=0.67, freq=9
  AwingWord(awing: 'ənumnə', english: 'day', category: 'general', difficulty: 2),
    // bible:MRK.4.27, conf=0.67, freq=9
  AwingWord(awing: 'əŋkənúʼə́', english: 'boats', category: 'general', difficulty: 2),
    // bible:MRK.4.36, conf=0.67, freq=9
  AwingWord(awing: 'gleb', english: 'vineyard', category: 'general', difficulty: 2),
    // bible:MRK.12.2, conf=0.56, freq=9
  AwingWord(awing: 'ḿbɛ́nkə', english: 'trembling', category: 'general', difficulty: 2),
    // bible:MRK.16.8, conf=0.78, freq=9
  AwingWord(awing: 'əmə́gə', english: 'eyes', category: 'general', difficulty: 2),
    // bible:LUK.2.30, conf=0.44, freq=9
  AwingWord(awing: 'nənumnə', english: 'day', category: 'general', difficulty: 2),
    // bible:LUK.2.37, conf=1.00, freq=9
  AwingWord(awing: 'gɔbnɔ', english: 'proconsul', category: 'general', difficulty: 2),
    // bible:LUK.3.1, conf=0.56, freq=9
  AwingWord(awing: 'ə́fɨgə̂', english: 'deceived', category: 'general', difficulty: 2),
    // bible:LUK.19.8, conf=0.44, freq=9
  AwingWord(awing: 'atəəmə́tɨ́', english: 'vision', category: 'general', difficulty: 2),
    // bible:LUK.24.23, conf=0.78, freq=9
  AwingWord(awing: 'pəfúfú', english: 'white', category: 'general', difficulty: 2),
    // bible:JHN.20.12, conf=0.89, freq=9
  AwingWord(awing: 'Ananyasə', english: 'ananias', category: 'general', difficulty: 2),
    // bible:ACT.5.1, conf=0.89, freq=9
  AwingWord(awing: 'Damaskɔs', english: 'damascus', category: 'general', difficulty: 2),
    // bible:ACT.9.2, conf=0.89, freq=9
  AwingWord(awing: 'Timotiə', english: 'timothy', category: 'general', difficulty: 2),
    // bible:ACT.16.1, conf=0.78, freq=9
  AwingWord(awing: 'Apolosə', english: 'apollos', category: 'general', difficulty: 2),
    // bible:ACT.18.26, conf=0.56, freq=9
  AwingWord(awing: 'Fɛlɛsə', english: 'felix', category: 'general', difficulty: 2),
    // bible:ACT.23.24, conf=0.78, freq=9
  AwingWord(awing: 'ndɔtí', english: 'god', category: 'general', difficulty: 2),
    // bible:ROM.1.24, conf=0.44, freq=9
  AwingWord(awing: 'pəzéʼkə', english: 'teachers', category: 'general', difficulty: 2),
    // bible:1CO.12.28, conf=0.67, freq=9
  AwingWord(awing: 'Taatusə', english: 'titus', category: 'general', difficulty: 2),
    // bible:2CO.2.13, conf=1.00, freq=9
  AwingWord(awing: 'əpúmə́tsəŋkə', english: 'plagues', category: 'general', difficulty: 2),
    // bible:REV.9.18, conf=0.89, freq=9
  AwingWord(awing: 'Lam', english: 'lamp', category: 'general', difficulty: 2),
    // bible:MAT.1.3, conf=0.75, freq=8
  AwingWord(awing: 'aləŋənə́foonə', english: 'throne', category: 'general', difficulty: 2),
    // bible:MAT.5.34, conf=1.00, freq=8
  AwingWord(awing: 'mbǒʼḿbóʼ', english: 'immorality', category: 'general', difficulty: 2),
    // bible:MAT.6.7, conf=0.50, freq=8
  AwingWord(awing: 'ńkə́g', english: 'faith', category: 'general', difficulty: 2),
    // bible:MAT.6.30, conf=0.62, freq=8
  AwingWord(awing: 'záʼə', english: 'first', category: 'general', difficulty: 2),
    // bible:MAT.8.21, conf=0.75, freq=8
  AwingWord(awing: 'sə́mə', english: 'wind', category: 'general', difficulty: 2),
    // bible:MAT.8.24, conf=0.50, freq=8
  AwingWord(awing: 'akəpóglə́', english: 'dust', category: 'general', difficulty: 2),
    // bible:MAT.10.14, conf=0.88, freq=8
  AwingWord(awing: 'Ndzoŋdzəmə', english: 'disciple', category: 'general', difficulty: 2),
    // bible:MAT.10.24, conf=0.62, freq=8
  AwingWord(awing: '“Fiʼtə̂', english: 'tell', category: 'general', difficulty: 2),
    // bible:MAT.13.36, conf=0.62, freq=8
  AwingWord(awing: 'ḿbɛ́nə', english: 'came', category: 'general', difficulty: 2),
    // bible:MAT.14.6, conf=0.62, freq=8
  AwingWord(awing: '“Ndɛd', english: 'come', category: 'general', difficulty: 2),
    // bible:MAT.14.15, conf=0.50, freq=8
  AwingWord(awing: 'Izlɛlə', english: 'israel', category: 'general', difficulty: 2),
    // bible:MAT.15.31, conf=0.62, freq=8
  AwingWord(awing: 'nəkyɛ́', english: 'lord', category: 'general', difficulty: 2),
    // bible:MAT.18.25, conf=0.62, freq=8
  AwingWord(awing: 'ngaŋnəpad', english: 'neighbor', category: 'general', difficulty: 2),
    // bible:MAT.19.19, conf=0.88, freq=8
  AwingWord(awing: '“Anu', english: 'answered', category: 'general', difficulty: 2),
    // bible:MAT.19.26, conf=0.50, freq=8
  AwingWord(awing: 'aləŋə', english: 'throne', category: 'general', difficulty: 2),
    // bible:MAT.19.28, conf=0.75, freq=8
  AwingWord(awing: 'Olifə', english: 'olives', category: 'general', difficulty: 2),
    // bible:MAT.21.1, conf=1.00, freq=8
  AwingWord(awing: 'ńchiʼnə̂', english: 'earthquake', category: 'general', difficulty: 2),
    // bible:MAT.21.10, conf=0.88, freq=8
  AwingWord(awing: 'yɛ́ɛlə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.26.5, conf=0.50, freq=8
  AwingWord(awing: 'aŋkəʼə́', english: 'rooster', category: 'general', difficulty: 2),
    // bible:MAT.26.34, conf=1.00, freq=8
  AwingWord(awing: 'ńchwegə̂', english: 'kiss', category: 'general', difficulty: 2),
    // bible:MAT.26.48, conf=0.50, freq=8
  AwingWord(awing: 'ńgyɛ́ɛlə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.27.24, conf=0.62, freq=8
  AwingWord(awing: 'paŋpaŋə', english: 'purple', category: 'general', difficulty: 2),
    // bible:MAT.27.28, conf=0.62, freq=8
  AwingWord(awing: 'ńtóŋ', english: 'tomb', category: 'general', difficulty: 2),
    // bible:MAT.27.48, conf=0.50, freq=8
  AwingWord(awing: 'Magdalɛn', english: 'magdalene', category: 'general', difficulty: 2),
    // bible:MAT.27.56, conf=1.00, freq=8
  AwingWord(awing: 'nkǎŋkǐ', english: 'sea', category: 'general', difficulty: 2),
    // bible:MRK.1.16, conf=0.50, freq=8
  AwingWord(awing: 'Loman', english: 'roman', category: 'general', difficulty: 2),
    // bible:MRK.3.18, conf=0.50, freq=8
  AwingWord(awing: 'atɔ́gə', english: 'room', category: 'general', difficulty: 2),
    // bible:MRK.14.14, conf=0.88, freq=8
  AwingWord(awing: 'atéemə́təndwegtə', english: 'abyss', category: 'general', difficulty: 2),
    // bible:LUK.8.31, conf=1.00, freq=8
  AwingWord(awing: 'mənchwa', english: 'divided', category: 'general', difficulty: 2),
    // bible:LUK.11.17, conf=0.50, freq=8
  AwingWord(awing: 'məngoʼ', english: 'years', category: 'general', difficulty: 2),
    // bible:LUK.12.19, conf=0.75, freq=8
  AwingWord(awing: 'límkə', english: 'harm', category: 'general', difficulty: 2),
    // bible:LUK.12.46, conf=0.62, freq=8
  AwingWord(awing: 'pəfoʼ', english: 'rich', category: 'general', difficulty: 2),
    // bible:LUK.21.1, conf=0.75, freq=8
  AwingWord(awing: 'kɛ́lə', english: 'light', category: 'general', difficulty: 2),
    // bible:JHN.1.5, conf=0.50, freq=8
  AwingWord(awing: 'ŋáʼkə', english: 'open', category: 'general', difficulty: 2),
    // bible:JHN.9.17, conf=0.50, freq=8
  AwingWord(awing: 'fwɔn', english: 'one', category: 'general', difficulty: 2),
    // bible:JHN.20.19, conf=0.50, freq=8
  AwingWord(awing: 'Damaskɔsə', english: 'damascus', category: 'general', difficulty: 2),
    // bible:ACT.9.19, conf=1.00, freq=8
  AwingWord(awing: 'kwéŋə', english: 'things', category: 'general', difficulty: 2),
    // bible:ACT.9.31, conf=0.50, freq=8
  AwingWord(awing: 'Mag', english: 'mark', category: 'general', difficulty: 2),
    // bible:ACT.12.12, conf=0.62, freq=8
  AwingWord(awing: 'mbǒʼḿbóʼə́', english: 'sexual', category: 'general', difficulty: 2),
    // bible:ACT.15.20, conf=0.75, freq=8
  AwingWord(awing: 'Ɛfesusə', english: 'ephesus', category: 'general', difficulty: 2),
    // bible:ACT.18.21, conf=0.75, freq=8
  AwingWord(awing: 'Sɛləba', english: 'silver', category: 'general', difficulty: 2),
    // bible:ACT.19.19, conf=1.00, freq=8
  AwingWord(awing: 'Adam', english: 'adam', category: 'general', difficulty: 2),
    // bible:ROM.5.14, conf=0.75, freq=8
  AwingWord(awing: 'məshú', english: 'god', category: 'general', difficulty: 2),
    // bible:1CO.15.39, conf=0.50, freq=8
  AwingWord(awing: 'asəgə́ndzɔʼ', english: 'perseverance', category: 'general', difficulty: 2),
    // bible:COL.1.11, conf=0.50, freq=8
  AwingWord(awing: 'fɨdnû', english: 'opened', category: 'general', difficulty: 2),
    // bible:REV.5.1, conf=0.62, freq=8
  AwingWord(awing: 'Solomunə', english: 'solomon', category: 'general', difficulty: 2),
    // bible:MAT.1.6, conf=1.00, freq=7
  AwingWord(awing: 'Babilɔn', english: 'babylon', category: 'general', difficulty: 2),
    // bible:MAT.1.17, conf=0.71, freq=7
  AwingWord(awing: 'əsáʼmə́nu', english: 'east', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=0.71, freq=7
  AwingWord(awing: 'məŋkɛlə́', english: 'boat', category: 'general', difficulty: 2),
    // bible:MAT.4.21, conf=0.43, freq=7
  AwingWord(awing: 'pəkɔ́ŋə́sê', english: 'lame', category: 'general', difficulty: 2),
    // bible:MAT.4.24, conf=0.86, freq=7
  AwingWord(awing: 'nkwə́ŋ', english: 'own', category: 'general', difficulty: 2),
    // bible:MAT.7.3, conf=0.43, freq=7
  AwingWord(awing: 'ńkə́gə', english: 'few', category: 'general', difficulty: 2),
    // bible:MAT.7.14, conf=0.43, freq=7
  AwingWord(awing: '“Tsɔʼə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.8.13, conf=0.43, freq=7
  AwingWord(awing: 'mɛ́nə', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.8.17, conf=0.57, freq=7
  AwingWord(awing: '“Zoŋə̂', english: 'follow', category: 'general', difficulty: 2),
    // bible:MAT.8.22, conf=1.00, freq=7
  AwingWord(awing: 'ńtsə́g', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.8.28, conf=0.71, freq=7
  AwingWord(awing: 'fɨ́dkə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.8.31, conf=0.43, freq=7
  AwingWord(awing: '“Wam', english: 'cheer', category: 'general', difficulty: 2),
    // bible:MAT.9.2, conf=0.86, freq=7
  AwingWord(awing: 'nkwânchubə', english: 'tax', category: 'general', difficulty: 2),
    // bible:MAT.9.9, conf=1.00, freq=7
  AwingWord(awing: 'ńnɨ́', english: 'sat', category: 'general', difficulty: 2),
    // bible:MAT.9.10, conf=0.43, freq=7
  AwingWord(awing: 'ngɔ́d', english: 'through', category: 'general', difficulty: 2),
    // bible:MAT.9.16, conf=0.86, freq=7
  AwingWord(awing: 'ńkəm', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.9.33, conf=0.86, freq=7
  AwingWord(awing: 'pətɔ̂ŋ', english: 'city', category: 'general', difficulty: 2),
    // bible:MAT.11.1, conf=0.57, freq=7
  AwingWord(awing: 'chiʼ', english: 'shaken', category: 'general', difficulty: 2),
    // bible:MAT.11.7, conf=0.57, freq=7
  AwingWord(awing: 'Bɛdsada', english: 'bethsaida', category: 'general', difficulty: 2),
    // bible:MAT.11.21, conf=1.00, freq=7
  AwingWord(awing: 'Sidɔnə', english: 'sidon', category: 'general', difficulty: 2),
    // bible:MAT.11.22, conf=1.00, freq=7
  AwingWord(awing: '“Noŋkə', english: 'lawful', category: 'general', difficulty: 2),
    // bible:MAT.12.10, conf=1.00, freq=7
  AwingWord(awing: 'ńtég', english: 'came', category: 'general', difficulty: 2),
    // bible:MAT.12.44, conf=0.71, freq=7
  AwingWord(awing: '“Mǎ', english: 'mother', category: 'general', difficulty: 2),
    // bible:MAT.12.47, conf=1.00, freq=7
  AwingWord(awing: 'məsɔbsɔb', english: 'thorns', category: 'general', difficulty: 2),
    // bible:MAT.13.7, conf=1.00, freq=7
  AwingWord(awing: 'mbəm', english: 'fruit', category: 'general', difficulty: 2),
    // bible:MAT.13.8, conf=1.00, freq=7
  AwingWord(awing: 'nətáŋ', english: 'riches', category: 'general', difficulty: 2),
    // bible:MAT.13.22, conf=0.43, freq=7
  AwingWord(awing: 'əkáŋ', english: 'angels', category: 'general', difficulty: 2),
    // bible:MAT.13.33, conf=0.57, freq=7
  AwingWord(awing: 'asəgə́', english: 'land', category: 'general', difficulty: 2),
    // bible:MAT.13.48, conf=0.71, freq=7
  AwingWord(awing: 'ngaŋə́láʼ', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.14.35, conf=0.43, freq=7
  AwingWord(awing: 'ə́shíʼə́', english: 'loaves', category: 'general', difficulty: 2),
    // bible:MAT.15.34, conf=0.57, freq=7
  AwingWord(awing: 'jáʼ', english: 'appeared', category: 'general', difficulty: 2),
    // bible:MAT.17.3, conf=0.43, freq=7
  AwingWord(awing: 'leŋ', english: 'didn', category: 'general', difficulty: 2),
    // bible:MAT.17.12, conf=0.57, freq=7
  AwingWord(awing: 'kə́g', english: 'nothing', category: 'general', difficulty: 2),
    // bible:MAT.17.20, conf=0.43, freq=7
  AwingWord(awing: '“Saamun', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.17.25, conf=1.00, freq=7
  AwingWord(awing: 'nyegnə̂', english: 'mocked', category: 'general', difficulty: 2),
    // bible:MAT.20.19, conf=0.71, freq=7
  AwingWord(awing: 'fóŋnə', english: 'son', category: 'general', difficulty: 2),
    // bible:MAT.20.30, conf=0.43, freq=7
  AwingWord(awing: 'kɔ́ŋə́sê', english: 'man', category: 'general', difficulty: 2),
    // bible:MAT.21.14, conf=0.71, freq=7
  AwingWord(awing: 'ngaŋə́fanə', english: 'other', category: 'general', difficulty: 2),
    // bible:MAT.21.41, conf=0.43, freq=7
  AwingWord(awing: 'ntaʼlə', english: 'few', category: 'general', difficulty: 2),
    // bible:MAT.22.14, conf=0.57, freq=7
  AwingWord(awing: 'Azig', english: 'isaac', category: 'general', difficulty: 2),
    // bible:MAT.22.32, conf=1.00, freq=7
  AwingWord(awing: 'mbab', english: 'wings', category: 'general', difficulty: 2),
    // bible:MAT.23.37, conf=0.71, freq=7
  AwingWord(awing: 'ntsǒnkáʼə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.24.33, conf=0.71, freq=7
  AwingWord(awing: 'pəlám', english: 'lamps', category: 'general', difficulty: 2),
    // bible:MAT.25.1, conf=0.71, freq=7
  AwingWord(awing: 'ntɨ̌túʼ', english: 'midnight', category: 'general', difficulty: 2),
    // bible:MAT.25.6, conf=0.86, freq=7
  AwingWord(awing: 'foʼə̂', english: 'reap', category: 'general', difficulty: 2),
    // bible:MAT.25.26, conf=0.57, freq=7
  AwingWord(awing: 'ngab', english: 'day', category: 'general', difficulty: 2),
    // bible:MAT.25.32, conf=0.71, freq=7
  AwingWord(awing: 'pəpóŋ', english: 'poor', category: 'general', difficulty: 2),
    // bible:MAT.26.11, conf=0.57, freq=7
  AwingWord(awing: 'atətá', english: 'peter', category: 'general', difficulty: 2),
    // bible:MAT.26.58, conf=0.86, freq=7
  AwingWord(awing: 'ə́fyáalə', english: 'cyrene', category: 'general', difficulty: 2),
    // bible:MAT.27.32, conf=0.43, freq=7
  AwingWord(awing: 'ŋ́ŋáʼə', english: 'come', category: 'general', difficulty: 2),
    // bible:MRK.4.22, conf=0.43, freq=7
  AwingWord(awing: 'ńdə́gə', english: 'opened', category: 'general', difficulty: 2),
    // bible:MRK.6.27, conf=0.57, freq=7
  AwingWord(awing: 'ə́sogə̂', english: 'washed', category: 'general', difficulty: 2),
    // bible:MRK.7.5, conf=0.43, freq=7
  AwingWord(awing: 'Jus', english: 'jew', category: 'general', difficulty: 2),
    // bible:MRK.7.26, conf=0.86, freq=7
  AwingWord(awing: 'weŋ', english: 'son', category: 'general', difficulty: 2),
    // bible:MRK.13.26, conf=0.43, freq=7
  AwingWord(awing: 'Alǒ', english: 'father', category: 'general', difficulty: 2),
    // bible:MRK.13.32, conf=0.43, freq=7
  AwingWord(awing: 'twə́ŋə', english: 'buried', category: 'general', difficulty: 2),
    // bible:MRK.14.8, conf=0.43, freq=7
  AwingWord(awing: 'ńnáakə', english: 'into', category: 'general', difficulty: 2),
    // bible:MRK.16.19, conf=0.43, freq=7
  AwingWord(awing: 'Pətseŋnə', english: 'shepherds', category: 'general', difficulty: 2),
    // bible:LUK.2.8, conf=0.86, freq=7
  AwingWord(awing: 'ngɛdtəpɔŋ', english: 'one', category: 'general', difficulty: 2),
    // bible:LUK.6.22, conf=0.86, freq=7
  AwingWord(awing: 'ngwan', english: 'stripes', category: 'general', difficulty: 2),
    // bible:LUK.12.47, conf=0.57, freq=7
  AwingWord(awing: 'akwáalə́nkǐ', english: 'baptism', category: 'general', difficulty: 2),
    // bible:LUK.12.50, conf=0.71, freq=7
  AwingWord(awing: 'ə́lɔgə̂', english: 'words', category: 'general', difficulty: 2),
    // bible:LUK.21.24, conf=0.57, freq=7
  AwingWord(awing: 'ńjwáglə', english: 'cried', category: 'general', difficulty: 2),
    // bible:LUK.23.21, conf=0.57, freq=7
  AwingWord(awing: 'Glikə', english: 'greek', category: 'general', difficulty: 2),
    // bible:JHN.1.41, conf=0.43, freq=7
  AwingWord(awing: 'pətəkaŋ', english: 'elders', category: 'general', difficulty: 2),
    // bible:JHN.8.9, conf=0.43, freq=7
  AwingWord(awing: 'ŋ́ŋáʼnə', english: 'opened', category: 'general', difficulty: 2),
    // bible:JHN.9.10, conf=0.43, freq=7
  AwingWord(awing: 'təghə́', english: 'without', category: 'general', difficulty: 2),
    // bible:JHN.14.6, conf=0.43, freq=7
  AwingWord(awing: '“Pəlimə́', english: 'brothers', category: 'general', difficulty: 2),
    // bible:ACT.1.16, conf=0.86, freq=7
  AwingWord(awing: 'jwaʼlə̂', english: 'another', category: 'general', difficulty: 2),
    // bible:ACT.2.12, conf=0.43, freq=7
  AwingWord(awing: 'Sayiplus', english: 'cyprus', category: 'general', difficulty: 2),
    // bible:ACT.4.36, conf=1.00, freq=7
  AwingWord(awing: 'pəghəənə', english: 'strangers', category: 'general', difficulty: 2),
    // bible:ACT.7.6, conf=0.43, freq=7
  AwingWord(awing: 'Kɔneliɔsə', english: 'cornelius', category: 'general', difficulty: 2),
    // bible:ACT.10.1, conf=0.86, freq=7
  AwingWord(awing: 'kyádkənkǐ', english: 'island', category: 'general', difficulty: 2),
    // bible:ACT.13.6, conf=0.86, freq=7
  AwingWord(awing: '“Yǐəə', english: 'saying', category: 'general', difficulty: 2),
    // bible:ACT.16.9, conf=1.00, freq=7
  AwingWord(awing: 'Tɛsalonika', english: 'thessalonica', category: 'general', difficulty: 2),
    // bible:ACT.17.1, conf=0.86, freq=7
  AwingWord(awing: 'Akwila', english: 'aquila', category: 'general', difficulty: 2),
    // bible:ACT.18.2, conf=0.86, freq=7
  AwingWord(awing: 'Plisila', english: 'aquila', category: 'general', difficulty: 2),
    // bible:ACT.18.2, conf=0.86, freq=7
  AwingWord(awing: 'wáakə́', english: 'sea', category: 'general', difficulty: 2),
    // bible:ACT.27.17, conf=0.57, freq=7
  AwingWord(awing: 'pə́pə̌', english: 'god', category: 'general', difficulty: 2),
    // bible:2CO.1.17, conf=0.57, freq=7
  AwingWord(awing: 'nəpaŋ', english: 'voice', category: 'general', difficulty: 2),
    // bible:1TH.4.16, conf=0.57, freq=7
  AwingWord(awing: 'nəjí', english: 'sounded', category: 'general', difficulty: 2),
    // bible:REV.8.7, conf=1.00, freq=7
  AwingWord(awing: 'Bɛtəlɛɛmə', english: 'bethlehem', category: 'general', difficulty: 2),
    // bible:MAT.2.1, conf=1.00, freq=6
  AwingWord(awing: 'Jodan', english: 'jordan', category: 'general', difficulty: 2),
    // bible:MAT.3.5, conf=1.00, freq=6
  AwingWord(awing: 'nəloŋ', english: 'down', category: 'general', difficulty: 2),
    // bible:MAT.4.5, conf=0.67, freq=6
  AwingWord(awing: '“Aŋwaʼlə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.4.7, conf=0.67, freq=6
  AwingWord(awing: 'Dɛbəəl', english: 'devil', category: 'general', difficulty: 2),
    // bible:MAT.4.8, conf=0.83, freq=6
  AwingWord(awing: 'təjiʼə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.4.10, conf=0.50, freq=6
  AwingWord(awing: 'azɔŋ', english: 'against', category: 'general', difficulty: 2),
    // bible:MAT.5.23, conf=0.50, freq=6
  AwingWord(awing: 'aliʼə́sáʼə́məsáʼ', english: 'judge', category: 'general', difficulty: 2),
    // bible:MAT.5.25, conf=0.50, freq=6
  AwingWord(awing: 'ndɔ́la', english: 'two', category: 'general', difficulty: 2),
    // bible:MAT.5.26, conf=0.67, freq=6
  AwingWord(awing: 'achaʼtə́sênjiə', english: 'fast', category: 'general', difficulty: 2),
    // bible:MAT.6.16, conf=0.83, freq=6
  AwingWord(awing: 'ńdzə', english: 'swords', category: 'general', difficulty: 2),
    // bible:MAT.6.20, conf=0.50, freq=6
  AwingWord(awing: 'tsɛɛkə̂', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.8.3, conf=0.67, freq=6
  AwingWord(awing: 'twə́ŋ', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MAT.8.22, conf=0.67, freq=6
  AwingWord(awing: 'Matyo', english: 'matthew', category: 'general', difficulty: 2),
    // bible:MAT.9.9, conf=0.83, freq=6
  AwingWord(awing: '“Móonə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.9.18, conf=0.67, freq=6
  AwingWord(awing: 'fɛ́dkə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.9.25, conf=0.50, freq=6
  AwingWord(awing: 'Sodom', english: 'sodom', category: 'general', difficulty: 2),
    // bible:MAT.10.15, conf=1.00, freq=6
  AwingWord(awing: 'Sidɔn', english: 'tyre', category: 'general', difficulty: 2),
    // bible:MAT.11.21, conf=0.83, freq=6
  AwingWord(awing: 'ḿbə́g', english: 'than', category: 'general', difficulty: 2),
    // bible:MAT.12.45, conf=0.50, freq=6
  AwingWord(awing: 'ńdagtə̂', english: 'baskets', category: 'general', difficulty: 2),
    // bible:MAT.13.4, conf=0.83, freq=6
  AwingWord(awing: 'ńtáŋnə', english: 'night', category: 'general', difficulty: 2),
    // bible:MAT.13.17, conf=0.50, freq=6
  AwingWord(awing: '“Kó', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.15.22, conf=0.67, freq=6
  AwingWord(awing: 'məngwû', english: 'dogs', category: 'general', difficulty: 2),
    // bible:MAT.15.26, conf=1.00, freq=6
  AwingWord(awing: 'ntáʼə', english: 'loaves', category: 'general', difficulty: 2),
    // bible:MAT.15.36, conf=1.00, freq=6
  AwingWord(awing: 'Filipi', english: 'philippi', category: 'general', difficulty: 2),
    // bible:MAT.16.13, conf=0.83, freq=6
  AwingWord(awing: 'kyag', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.16.19, conf=0.50, freq=6
  AwingWord(awing: 'sə́', english: 'themselves', category: 'general', difficulty: 2),
    // bible:MAT.19.12, conf=0.67, freq=6
  AwingWord(awing: 'ńkɨ́ʼə', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.19.14, conf=0.50, freq=6
  AwingWord(awing: 'ngaŋnkéebə', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.19.23, conf=1.00, freq=6
  AwingWord(awing: '“Zə́ənə', english: 'behold', category: 'general', difficulty: 2),
    // bible:MAT.19.27, conf=0.83, freq=6
  AwingWord(awing: 'ələŋəmə́fɔ', english: 'thrones', category: 'general', difficulty: 2),
    // bible:MAT.19.28, conf=1.00, freq=6
  AwingWord(awing: 'ntɨ̌numnə', english: 'about', category: 'general', difficulty: 2),
    // bible:MAT.20.5, conf=0.67, freq=6
  AwingWord(awing: '‘lə́', english: 'god', category: 'general', difficulty: 2),
    // bible:MAT.20.7, conf=0.67, freq=6
  AwingWord(awing: 'Jɛliko', english: 'jericho', category: 'general', difficulty: 2),
    // bible:MAT.20.29, conf=1.00, freq=6
  AwingWord(awing: 'ńnaʼə̂', english: 'rebuked', category: 'general', difficulty: 2),
    // bible:MAT.20.31, conf=0.50, freq=6
  AwingWord(awing: 'ńtɔ́ŋnə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.20.31, conf=0.50, freq=6
  AwingWord(awing: 'təŋnə̂', english: 'tied', category: 'general', difficulty: 2),
    // bible:MAT.21.2, conf=0.67, freq=6
  AwingWord(awing: 'əkɔʼ', english: 'seats', category: 'general', difficulty: 2),
    // bible:MAT.21.12, conf=1.00, freq=6
  AwingWord(awing: 'ńtóŋə', english: 'went', category: 'general', difficulty: 2),
    // bible:MAT.21.33, conf=0.83, freq=6
  AwingWord(awing: 'ńgwúnə', english: 'invited', category: 'general', difficulty: 2),
    // bible:MAT.22.9, conf=0.67, freq=6
  AwingWord(awing: 'tɔ́mtə', english: 'came', category: 'general', difficulty: 2),
    // bible:MAT.22.16, conf=0.50, freq=6
  AwingWord(awing: 'fîəpô', english: 'finger', category: 'general', difficulty: 2),
    // bible:MAT.23.4, conf=0.83, freq=6
  AwingWord(awing: 'məntsoolə', english: 'end', category: 'general', difficulty: 2),
    // bible:MAT.24.6, conf=0.50, freq=6
  AwingWord(awing: 'sɛ́nə', english: 'light', category: 'general', difficulty: 2),
    // bible:MAT.24.29, conf=0.50, freq=6
  AwingWord(awing: 'Kaifasə', english: 'caiaphas', category: 'general', difficulty: 2),
    // bible:MAT.26.3, conf=1.00, freq=6
  AwingWord(awing: 'ḿbóolə', english: 'weak', category: 'general', difficulty: 2),
    // bible:MAT.26.41, conf=0.67, freq=6
  AwingWord(awing: 'ńtwǐ', english: 'spat', category: 'general', difficulty: 2),
    // bible:MAT.26.67, conf=0.50, freq=6
  AwingWord(awing: 'məngwúb', english: 'rocks', category: 'general', difficulty: 2),
    // bible:MAT.27.51, conf=0.50, freq=6
  AwingWord(awing: 'ŋ́ŋáʼkə', english: 'opened', category: 'general', difficulty: 2),
    // bible:MAT.27.52, conf=0.67, freq=6
  AwingWord(awing: 'ngaŋntsɨd', english: 'liar', category: 'general', difficulty: 2),
    // bible:MAT.27.63, conf=0.50, freq=6
  AwingWord(awing: 'ńkwɛdnə̂', english: 'one', category: 'general', difficulty: 2),
    // bible:MRK.2.22, conf=0.50, freq=6
  AwingWord(awing: 'pəfî', english: 'languages', category: 'general', difficulty: 2),
    // bible:MRK.7.33, conf=0.67, freq=6
  AwingWord(awing: 'ńgwad', english: 'covenant', category: 'general', difficulty: 2),
    // bible:MRK.14.12, conf=0.67, freq=6
  AwingWord(awing: 'ambáŋə́', english: 'water', category: 'general', difficulty: 2),
    // bible:MRK.14.13, conf=0.50, freq=6
  AwingWord(awing: 'ńdzɔ́gə', english: 'peter', category: 'general', difficulty: 2),
    // bible:MRK.14.54, conf=1.00, freq=6
  AwingWord(awing: 'toonə̂', english: 'into', category: 'general', difficulty: 2),
    // bible:LUK.1.9, conf=0.50, freq=6
  AwingWord(awing: 'təmbɔʼə', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.1.22, conf=0.50, freq=6
  AwingWord(awing: 'Sala', english: 'sarah', category: 'general', difficulty: 2),
    // bible:LUK.3.32, conf=0.67, freq=6
  AwingWord(awing: 'ŋáʼə', english: 'veil', category: 'general', difficulty: 2),
    // bible:LUK.4.17, conf=0.50, freq=6
  AwingWord(awing: 'aghɔ', english: 'healed', category: 'general', difficulty: 2),
    // bible:LUK.4.40, conf=0.50, freq=6
  AwingWord(awing: 'nəpɔŋ', english: 'glory', category: 'general', difficulty: 2),
    // bible:LUK.9.26, conf=0.67, freq=6
  AwingWord(awing: 'ə́sagə̂', english: 'its', category: 'general', difficulty: 2),
    // bible:LUK.12.15, conf=0.50, freq=6
  AwingWord(awing: 'məmbéŋə', english: 'good', category: 'general', difficulty: 2),
    // bible:LUK.12.32, conf=0.50, freq=6
  AwingWord(awing: 'pəfə́m', english: 'poor', category: 'general', difficulty: 2),
    // bible:LUK.14.13, conf=0.83, freq=6
  AwingWord(awing: 'jwə́ʼə', english: 'fire', category: 'general', difficulty: 2),
    // bible:LUK.14.24, conf=0.50, freq=6
  AwingWord(awing: 'tətəənə', english: 'middle', category: 'general', difficulty: 2),
    // bible:LUK.22.55, conf=0.83, freq=6
  AwingWord(awing: 'Lɛbi', english: 'through', category: 'general', difficulty: 2),
    // bible:JHN.1.19, conf=0.50, freq=6
  AwingWord(awing: 'shwəgtə̂', english: 'away', category: 'general', difficulty: 2),
    // bible:JHN.2.10, conf=0.83, freq=6
  AwingWord(awing: 'ńgabnə̂', english: 'division', category: 'general', difficulty: 2),
    // bible:JHN.7.43, conf=0.50, freq=6
  AwingWord(awing: 'sɛ́n', english: 'night', category: 'general', difficulty: 2),
    // bible:JHN.9.4, conf=0.83, freq=6
  AwingWord(awing: 'Lazalɔs', english: 'lazarus', category: 'general', difficulty: 2),
    // bible:JHN.11.2, conf=0.67, freq=6
  AwingWord(awing: 'tǎpətǎ', english: 'father', category: 'general', difficulty: 2),
    // bible:ACT.4.25, conf=0.50, freq=6
  AwingWord(awing: 'Stifənə', english: 'stephen', category: 'general', difficulty: 2),
    // bible:ACT.6.9, conf=0.50, freq=6
  AwingWord(awing: 'Silisya', english: 'cilicia', category: 'general', difficulty: 2),
    // bible:ACT.6.9, conf=1.00, freq=6
  AwingWord(awing: 'atəəmə́tə́əmə', english: 'into', category: 'general', difficulty: 2),
    // bible:ACT.10.10, conf=0.50, freq=6
  AwingWord(awing: 'ə́fyaʼ', english: 'idols', category: 'general', difficulty: 2),
    // bible:ACT.15.29, conf=0.83, freq=6
  AwingWord(awing: 'Təlowasə', english: 'troas', category: 'general', difficulty: 2),
    // bible:ACT.16.8, conf=0.83, freq=6
  AwingWord(awing: 'əsáʼməsáʼə', english: 'another', category: 'general', difficulty: 2),
    // bible:ACT.17.34, conf=0.50, freq=6
  AwingWord(awing: 'nəweŋ', english: 'officer', category: 'general', difficulty: 2),
    // bible:ACT.22.26, conf=0.67, freq=6
  AwingWord(awing: 'əshunə́', english: 'greet', category: 'general', difficulty: 2),
    // bible:ROM.2.3, conf=0.67, freq=6
  AwingWord(awing: 'zéʼə', english: 'know', category: 'general', difficulty: 2),
    // bible:1CO.14.31, conf=0.50, freq=6
  AwingWord(awing: 'nənta', english: 'god', category: 'general', difficulty: 2),
    // bible:EPH.5.9, conf=0.67, freq=6
  AwingWord(awing: 'Lawodesya', english: 'laodicea', category: 'general', difficulty: 2),
    // bible:COL.2.1, conf=1.00, freq=6
  AwingWord(awing: 'ńdzoolə̂', english: 'thunders', category: 'general', difficulty: 2),
    // bible:REV.4.5, conf=0.83, freq=6
  AwingWord(awing: 'akɔ́', english: 'beast', category: 'general', difficulty: 2),
    // bible:REV.14.9, conf=0.83, freq=6
  AwingWord(awing: 'afoʼəmə́jî', english: 'sickle', category: 'general', difficulty: 2),
    // bible:REV.14.15, conf=1.00, freq=6
  AwingWord(awing: 'Jese', english: 'jesse', category: 'general', difficulty: 2),
    // bible:MAT.1.5, conf=1.00, freq=5
  AwingWord(awing: 'Babilɔnə', english: 'babylon', category: 'general', difficulty: 2),
    // bible:MAT.1.11, conf=1.00, freq=5
  AwingWord(awing: 'məpad', english: 'neighbors', category: 'general', difficulty: 2),
    // bible:MAT.2.16, conf=0.60, freq=5
  AwingWord(awing: 'alúʼə', english: 'dove', category: 'general', difficulty: 2),
    // bible:MAT.3.16, conf=0.80, freq=5
  AwingWord(awing: 'əláʼə', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.4.8, conf=0.60, freq=5
  AwingWord(awing: 'kwə́ʼtə', english: 'down', category: 'general', difficulty: 2),
    // bible:MAT.4.9, conf=0.80, freq=5
  AwingWord(awing: 'Silya', english: 'syria', category: 'general', difficulty: 2),
    // bible:MAT.4.24, conf=0.60, freq=5
  AwingWord(awing: 'ghɔ', english: 'sick', category: 'general', difficulty: 2),
    // bible:MAT.4.24, conf=0.80, freq=5
  AwingWord(awing: 'ntɛ́n', english: 'stand', category: 'general', difficulty: 2),
    // bible:MAT.5.15, conf=0.60, freq=5
  AwingWord(awing: 'akəkóg', english: 'foolish', category: 'general', difficulty: 2),
    // bible:MAT.5.22, conf=0.60, freq=5
  AwingWord(awing: 'ə́shamkə̂', english: 'away', category: 'general', difficulty: 2),
    // bible:MAT.5.31, conf=0.40, freq=5
  AwingWord(awing: 'kwab', english: 'left', category: 'general', difficulty: 2),
    // bible:MAT.5.39, conf=0.80, freq=5
  AwingWord(awing: 'tsɔ́ʼkə', english: 'lend', category: 'general', difficulty: 2),
    // bible:MAT.5.42, conf=0.60, freq=5
  AwingWord(awing: 'təjǐsê', english: 'tax', category: 'general', difficulty: 2),
    // bible:MAT.5.47, conf=0.40, freq=5
  AwingWord(awing: 'yï', english: 'amen', category: 'general', difficulty: 2),
    // bible:MAT.6.6, conf=0.40, freq=5
  AwingWord(awing: 'tə́mə́sɛ́', english: 'don', category: 'general', difficulty: 2),
    // bible:MAT.6.19, conf=0.80, freq=5
  AwingWord(awing: 'ńdzə́gə', english: 'sow', category: 'general', difficulty: 2),
    // bible:MAT.6.26, conf=0.40, freq=5
  AwingWord(awing: 'Solomun', english: 'solomon', category: 'general', difficulty: 2),
    // bible:MAT.6.29, conf=1.00, freq=5
  AwingWord(awing: 'nəyeŋ', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.6.30, conf=0.60, freq=5
  AwingWord(awing: 'lǎa', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.7.4, conf=0.40, freq=5
  AwingWord(awing: 'kə́gə', english: 'few', category: 'general', difficulty: 2),
    // bible:MAT.7.14, conf=0.40, freq=5
  AwingWord(awing: 'zə́mə', english: 'fruit', category: 'general', difficulty: 2),
    // bible:MAT.7.17, conf=0.80, freq=5
  AwingWord(awing: 'ənu', english: 'wise', category: 'general', difficulty: 2),
    // bible:MAT.7.24, conf=0.40, freq=5
  AwingWord(awing: 'əléemə', english: 'one', category: 'general', difficulty: 2),
    // bible:MAT.8.6, conf=0.60, freq=5
  AwingWord(awing: 'ńchiʼ', english: 'heads', category: 'general', difficulty: 2),
    // bible:MAT.8.24, conf=0.40, freq=5
  AwingWord(awing: 'mə́sɔ́', english: 'blood', category: 'general', difficulty: 2),
    // bible:MAT.9.20, conf=1.00, freq=5
  AwingWord(awing: 'jwáglə', english: 'shouted', category: 'general', difficulty: 2),
    // bible:MAT.9.23, conf=0.60, freq=5
  AwingWord(awing: 'Alfɔsə', english: 'son', category: 'general', difficulty: 2),
    // bible:MAT.10.3, conf=1.00, freq=5
  AwingWord(awing: 'Pəsamalitan', english: 'samaritans', category: 'general', difficulty: 2),
    // bible:MAT.10.5, conf=0.80, freq=5
  AwingWord(awing: 'kɔdtə̂', english: 'city', category: 'general', difficulty: 2),
    // bible:MAT.10.14, conf=0.80, freq=5
  AwingWord(awing: 'ngaŋə́sáʼə́məsáʼə', english: 'deliver', category: 'general', difficulty: 2),
    // bible:MAT.10.17, conf=0.40, freq=5
  AwingWord(awing: 'kɔnə̂', english: 'day', category: 'general', difficulty: 2),
    // bible:MAT.10.35, conf=0.60, freq=5
  AwingWord(awing: 'Akəkaʼ', english: 'reed', category: 'general', difficulty: 2),
    // bible:MAT.11.7, conf=0.60, freq=5
  AwingWord(awing: 'fiʼkə̂', english: 'compare', category: 'general', difficulty: 2),
    // bible:MAT.11.16, conf=0.40, freq=5
  AwingWord(awing: 'lwaʼə', english: 'immorality', category: 'general', difficulty: 2),
    // bible:MAT.11.19, conf=0.40, freq=5
  AwingWord(awing: 'ənuə', english: 'wise', category: 'general', difficulty: 2),
    // bible:MAT.11.25, conf=0.80, freq=5
  AwingWord(awing: 'əfɔ', english: 'into', category: 'general', difficulty: 2),
    // bible:MAT.12.1, conf=0.80, freq=5
  AwingWord(awing: 'ńtwám', english: 'cup', category: 'general', difficulty: 2),
    // bible:MAT.12.29, conf=0.60, freq=5
  AwingWord(awing: 'ndimə́', english: 'brother', category: 'general', difficulty: 2),
    // bible:MAT.12.50, conf=1.00, freq=5
  AwingWord(awing: 'əfooghəəmə́', english: 'sea', category: 'general', difficulty: 2),
    // bible:MAT.13.1, conf=0.60, freq=5
  AwingWord(awing: 'atséebə́nə́múʼə́', english: 'parable', category: 'general', difficulty: 2),
    // bible:MAT.13.10, conf=0.80, freq=5
  AwingWord(awing: 'fɔ́lə́sə', english: 'mustard', category: 'general', difficulty: 2),
    // bible:MAT.13.31, conf=1.00, freq=5
  AwingWord(awing: 'təjiʼ', english: 'own', category: 'general', difficulty: 2),
    // bible:MAT.14.13, conf=0.60, freq=5
  AwingWord(awing: 'pəfəgə́', english: 'blind', category: 'general', difficulty: 2),
    // bible:MAT.15.14, conf=1.00, freq=5
  AwingWord(awing: 'pəkî', english: 'key', category: 'general', difficulty: 2),
    // bible:MAT.16.19, conf=0.80, freq=5
  AwingWord(awing: 'kɨ́ʼə́', english: 'stumbling', category: 'general', difficulty: 2),
    // bible:MAT.16.23, conf=0.40, freq=5
  AwingWord(awing: 'ḿbéŋkə', english: 'man', category: 'general', difficulty: 2),
    // bible:MAT.16.26, conf=0.40, freq=5
  AwingWord(awing: 'məntaŋ', english: 'elijah', category: 'general', difficulty: 2),
    // bible:MAT.17.4, conf=0.60, freq=5
  AwingWord(awing: 'nchub', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.17.24, conf=0.60, freq=5
  AwingWord(awing: 'məghə́mə', english: 'seventy', category: 'general', difficulty: 2),
    // bible:MAT.18.22, conf=1.00, freq=5
  AwingWord(awing: 'ńnyáʼ', english: 'saw', category: 'general', difficulty: 2),
    // bible:MAT.20.3, conf=0.40, freq=5
  AwingWord(awing: 'ḿmegnə̂', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.20.31, conf=0.60, freq=5
  AwingWord(awing: 'jáʼə', english: 'revealed', category: 'general', difficulty: 2),
    // bible:MAT.23.15, conf=0.60, freq=5
  AwingWord(awing: 'pánə', english: 'out', category: 'general', difficulty: 2),
    // bible:MAT.24.26, conf=0.40, freq=5
  AwingWord(awing: 'shúm', english: 'prophesy', category: 'general', difficulty: 2),
    // bible:MAT.24.49, conf=0.40, freq=5
  AwingWord(awing: 'kɛləshín', english: 'lamps', category: 'general', difficulty: 2),
    // bible:MAT.25.3, conf=0.60, freq=5
  AwingWord(awing: '‘gho', english: 'said', category: 'general', difficulty: 2),
    // bible:MAT.25.23, conf=1.00, freq=5
  AwingWord(awing: 'akwub', english: 'alabaster', category: 'general', difficulty: 2),
    // bible:MAT.26.7, conf=0.40, freq=5
  AwingWord(awing: '“Aliʼə́', english: 'called', category: 'general', difficulty: 2),
    // bible:MAT.27.8, conf=0.80, freq=5
  AwingWord(awing: 'ńjwə́ʼ', english: 'tasted', category: 'general', difficulty: 2),
    // bible:MAT.27.34, conf=0.60, freq=5
  AwingWord(awing: 'ńdə́mə', english: 'wrapped', category: 'general', difficulty: 2),
    // bible:MAT.27.59, conf=0.80, freq=5
  AwingWord(awing: 'ńkwaʼlə̂', english: 'tempted', category: 'general', difficulty: 2),
    // bible:MRK.1.13, conf=0.60, freq=5
  AwingWord(awing: 'chiʼə̂', english: 'lord', category: 'general', difficulty: 2),
    // bible:MRK.1.26, conf=0.60, freq=5
  AwingWord(awing: '‘Pə́', english: 'sins', category: 'general', difficulty: 2),
    // bible:MRK.2.9, conf=0.40, freq=5
  AwingWord(awing: 'ngǎŋndzəm', english: 'against', category: 'general', difficulty: 2),
    // bible:MRK.3.6, conf=0.60, freq=5
  AwingWord(awing: 'aghoonə́', english: 'many', category: 'general', difficulty: 2),
    // bible:MRK.3.10, conf=0.40, freq=5
  AwingWord(awing: 'ńchiʼə̂', english: 'said', category: 'general', difficulty: 2),
    // bible:MRK.4.39, conf=0.40, freq=5
  AwingWord(awing: 'ńdə́gtə', english: 'often', category: 'general', difficulty: 2),
    // bible:MRK.5.4, conf=0.40, freq=5
  AwingWord(awing: 'akwantə', english: 'things', category: 'general', difficulty: 2),
    // bible:MRK.6.11, conf=0.60, freq=5
  AwingWord(awing: 'túʼə', english: 'day', category: 'general', difficulty: 2),
    // bible:MRK.6.35, conf=0.60, freq=5
  AwingWord(awing: 'ḿbookə̂', english: 'leave', category: 'general', difficulty: 2),
    // bible:MRK.6.46, conf=0.60, freq=5
  AwingWord(awing: 'məkəŋ', english: 'clay', category: 'general', difficulty: 2),
    // bible:MRK.7.4, conf=0.80, freq=5
  AwingWord(awing: 'akɔ́ʼkə', english: 'evil', category: 'general', difficulty: 2),
    // bible:MRK.7.22, conf=0.40, freq=5
  AwingWord(awing: 'ńdzɔŋnə̂', english: 'disciples', category: 'general', difficulty: 2),
    // bible:MRK.9.14, conf=0.40, freq=5
  AwingWord(awing: 'nkɨʼnənu', english: 'jesus', category: 'general', difficulty: 2),
    // bible:MRK.9.39, conf=0.40, freq=5
  AwingWord(awing: '“Jɨ́', english: 'said', category: 'general', difficulty: 2),
    // bible:MRK.10.33, conf=0.80, freq=5
  AwingWord(awing: '“Ghɛd', english: 'said', category: 'general', difficulty: 2),
    // bible:MRK.10.37, conf=0.80, freq=5
  AwingWord(awing: 'tɔ́ŋnə', english: 'voice', category: 'general', difficulty: 2),
    // bible:MRK.10.47, conf=0.60, freq=5
  AwingWord(awing: 'glebə', english: 'another', category: 'general', difficulty: 2),
    // bible:MRK.12.1, conf=0.60, freq=5
  AwingWord(awing: 'ngaŋə́shíʼnə', english: 'farmers', category: 'general', difficulty: 2),
    // bible:MRK.12.9, conf=0.80, freq=5
  AwingWord(awing: '‘Mmaʼmbî', english: 'lord', category: 'general', difficulty: 2),
    // bible:MRK.12.37, conf=1.00, freq=5
  AwingWord(awing: 'ńtóotə', english: 'stirred', category: 'general', difficulty: 2),
    // bible:MRK.15.11, conf=0.60, freq=5
  AwingWord(awing: 'ńdzéʼ', english: 'learn', category: 'general', difficulty: 2),
    // bible:LUK.1.3, conf=0.60, freq=5
  AwingWord(awing: 'ə́sɛd', english: 'god', category: 'general', difficulty: 2),
    // bible:LUK.3.8, conf=0.80, freq=5
  AwingWord(awing: 'Joshwa', english: 'levi', category: 'general', difficulty: 2),
    // bible:LUK.3.29, conf=0.40, freq=5
  AwingWord(awing: 'Sylya', english: 'syria', category: 'general', difficulty: 2),
    // bible:LUK.4.27, conf=0.80, freq=5
  AwingWord(awing: 'ə́fɛ́dkə', english: 'out', category: 'general', difficulty: 2),
    // bible:LUK.4.41, conf=0.80, freq=5
  AwingWord(awing: 'nkǐmə́g', english: 'weeping', category: 'general', difficulty: 2),
    // bible:LUK.7.38, conf=0.40, freq=5
  AwingWord(awing: 'ńjwaʼlə̂', english: 'because', category: 'general', difficulty: 2),
    // bible:LUK.9.7, conf=0.60, freq=5
  AwingWord(awing: 'Samalitan', english: 'samaritan', category: 'general', difficulty: 2),
    // bible:LUK.10.33, conf=0.60, freq=5
  AwingWord(awing: 'mə́ŋgâsê', english: 'power', category: 'general', difficulty: 2),
    // bible:LUK.11.12, conf=0.80, freq=5
  AwingWord(awing: '‘Tǎ', english: 'lord', category: 'general', difficulty: 2),
    // bible:LUK.12.45, conf=0.60, freq=5
  AwingWord(awing: 'Kɛ́', english: 'never', category: 'general', difficulty: 2),
    // bible:LUK.15.29, conf=0.60, freq=5
  AwingWord(awing: 'ndɛdtə', english: 'don', category: 'general', difficulty: 2),
    // bible:LUK.17.11, conf=0.40, freq=5
  AwingWord(awing: '“Ndɛn', english: 'answered', category: 'general', difficulty: 2),
    // bible:LUK.17.37, conf=0.40, freq=5
  AwingWord(awing: 'ngaŋə́táŋə́mə́tá', english: 'merchants', category: 'general', difficulty: 2),
    // bible:LUK.19.45, conf=0.60, freq=5
  AwingWord(awing: 'məmá', english: 'said', category: 'general', difficulty: 2),
    // bible:LUK.20.8, conf=0.60, freq=5
  AwingWord(awing: 'ətyǎntə', english: 'great', category: 'general', difficulty: 2),
    // bible:LUK.21.11, conf=0.40, freq=5
  AwingWord(awing: 'asáʼə́məsáʼə', english: 'day', category: 'general', difficulty: 2),
    // bible:LUK.22.66, conf=1.00, freq=5
  AwingWord(awing: 'əfankəmə́nu', english: 'sins', category: 'general', difficulty: 2),
    // bible:LUK.24.47, conf=0.80, freq=5
  AwingWord(awing: '“Ŋáŋkə', english: 'god', category: 'general', difficulty: 2),
    // bible:JHN.9.24, conf=0.80, freq=5
  AwingWord(awing: 'sáʼkə', english: 'thunders', category: 'general', difficulty: 2),
    // bible:JHN.12.29, conf=0.80, freq=5
  AwingWord(awing: 'paŋpaŋ', english: 'purple', category: 'general', difficulty: 2),
    // bible:JHN.19.5, conf=0.80, freq=5
  AwingWord(awing: 'ngyéŋ', english: 'side', category: 'general', difficulty: 2),
    // bible:JHN.19.34, conf=0.80, freq=5
  AwingWord(awing: 'mətsɨ́', english: 'things', category: 'general', difficulty: 2),
    // bible:JHN.21.25, conf=0.40, freq=5
  AwingWord(awing: 'Pamfilya', english: 'pamphylia', category: 'general', difficulty: 2),
    // bible:ACT.2.10, conf=1.00, freq=5
  AwingWord(awing: 'ńchwád', english: 'saved', category: 'general', difficulty: 2),
    // bible:ACT.4.12, conf=0.60, freq=5
  AwingWord(awing: 'Sinayi', english: 'mount', category: 'general', difficulty: 2),
    // bible:ACT.7.30, conf=0.80, freq=5
  AwingWord(awing: 'nəkyéŋ', english: 'tears', category: 'general', difficulty: 2),
    // bible:ACT.7.34, conf=0.60, freq=5
  AwingWord(awing: 'pəkɔ́', english: 'made', category: 'general', difficulty: 2),
    // bible:ACT.7.41, conf=0.40, freq=5
  AwingWord(awing: 'ńtyáatə', english: 'jesus', category: 'general', difficulty: 2),
    // bible:ACT.8.31, conf=0.40, freq=5
  AwingWord(awing: 'Magə', english: 'mark', category: 'general', difficulty: 2),
    // bible:ACT.13.5, conf=0.60, freq=5
  AwingWord(awing: 'Deu', english: 'god', category: 'general', difficulty: 2),
    // bible:ACT.13.18, conf=0.40, freq=5
  AwingWord(awing: 'Listəla', english: 'lystra', category: 'general', difficulty: 2),
    // bible:ACT.14.6, conf=1.00, freq=5
  AwingWord(awing: 'Ikonum', english: 'iconium', category: 'general', difficulty: 2),
    // bible:ACT.14.19, conf=1.00, freq=5
  AwingWord(awing: 'kəʼlə̂', english: 'reasoned', category: 'general', difficulty: 2),
    // bible:ACT.15.7,