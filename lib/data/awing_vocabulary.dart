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
  AwingWord(awing: "mbe'tə", english: 'shoulder', category: 'body'),
  AwingWord(awing: 'achîə', english: 'blood', category: 'body'),
  AwingWord(awing: 'akoolə', english: 'leg', category: 'body'),
  AwingWord(awing: 'alɔ́əmə', english: 'tongue', category: 'body'),
  AwingWord(awing: 'ŋgɔ́ɔmə', english: 'body', category: 'body'),
  AwingWord(awing: 'ŋgɔ̀ɔnə', english: 'eye', category: 'body'),
  AwingWord(awing: 'ntɔ̀ə', english: 'ear', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'nəpe', english: 'liver', category: 'body', difficulty: 2),
  AwingWord(awing: 'nətô', english: 'intestine', category: 'body', difficulty: 2),
  AwingWord(awing: 'fɛlə', english: 'breastbone', category: 'body', difficulty: 2),
  AwingWord(awing: 'aghâŋə', english: 'chest', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəlɔ́gə', english: 'eye', category: 'body', pluralForm: 'mələ́g'),
  AwingWord(awing: 'ntɔ̂glə', english: 'ear', category: 'body'),
  AwingWord(awing: 'ntsoolə', english: 'mouth (body)', category: 'body', pluralForm: 'məntsoolə'),
  AwingWord(awing: 'nəsoŋɔ́', english: 'tooth', category: 'body', pluralForm: 'məsoŋ'),
  AwingWord(awing: 'nənɔŋə', english: 'hair', category: 'body', pluralForm: 'mənɔŋə'),
  AwingWord(awing: 'akwəŋɔ́', english: 'bone', category: 'body'),
  AwingWord(awing: 'nəpəmə', english: 'stomach', category: 'body', pluralForm: 'məpəmə'),
  AwingWord(awing: "alu'ɔ̀", english: 'hip', category: 'body'),
  AwingWord(awing: 'atéelə', english: 'foot', category: 'body'),
  AwingWord(awing: 'nəpéenə', english: 'crown of head', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'ələlə', english: 'beard', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəpɔ̌ɔnə', english: 'breast', category: 'body', difficulty: 2),
  AwingWord(awing: 'atúəkeenə', english: 'shoulder blade', category: 'body', difficulty: 2),
  AwingWord(awing: "kwɔ'tə", english: 'knee', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəbâŋə', english: 'wing (of bird)', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəlwɛ̂ɨ', english: 'hump', category: 'body', difficulty: 3),
  AwingWord(awing: 'nətɔŋɔ́', english: 'navel', category: 'body', difficulty: 2),
  AwingWord(awing: "nətɔ'ə", english: 'thigh', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntîə', english: 'height', category: 'body', difficulty: 2),
  AwingWord(awing: 'ajwíə', english: 'soul/spirit', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntɔ̂əmə', english: 'heart', category: 'body', difficulty: 2),
];

/// Animals and nature — fun for kids
const List<AwingWord> animalsNature = [
  // Beginner animals
  AwingWord(awing: 'əshûə', english: 'fish', category: 'animals'),
  AwingWord(awing: 'koŋə', english: 'owl', category: 'animals'),
  AwingWord(awing: 'nóolə', english: 'snake', category: 'animals'),
  AwingWord(awing: 'ankoomə', english: 'ram', category: 'animals'),
  AwingWord(awing: 'ndzô', english: 'goat', category: 'animals'),
  AwingWord(awing: 'mbyâə', english: 'guard dog', category: 'animals'),
  AwingWord(awing: 'əndəŋə', english: 'duck', category: 'animals'),
  AwingWord(awing: 'kshǐa', english: 'cricket', category: 'animals'),
  AwingWord(awing: 'mbeŋó', english: 'cockroach', category: 'animals'),
  AwingWord(awing: 'kónáŋó', english: 'chameleon', category: 'animals'),
  AwingWord(awing: 'apóbə', english: 'he-goat', category: 'animals'),
  AwingWord(awing: 'ngwûə', english: 'dog', category: 'animals', pluralForm: 'məngwûə'),
  AwingWord(awing: 'ngɔ́bə', english: 'chicken', category: 'animals', pluralForm: 'məngɔ́bə'),
  AwingWord(awing: 'pûshíə', english: 'cat', category: 'animals'),
  AwingWord(awing: 'sáŋɔ́', english: 'bird', category: 'animals', pluralForm: 'pəsáŋɔ́'),
  AwingWord(awing: "tâŋka'ə", english: 'elephant', category: 'animals'),
  AwingWord(awing: 'sáambaŋə', english: 'lion', category: 'animals'),
  AwingWord(awing: 'ambónə', english: 'hippopotamus', category: 'animals'),
  AwingWord(awing: 'chwíə', english: 'antelope', category: 'animals'),
  AwingWord(awing: 'lúmtɔ́', english: 'mosquito', category: 'animals'),
  AwingWord(awing: 'kwíŋə', english: 'tortoise', category: 'animals'),
  AwingWord(awing: 'kwúneemə', english: 'pig', category: 'animals'),
  AwingWord(awing: 'tatseemə', english: 'frog', category: 'animals'),
  AwingWord(awing: 'lóolə', english: 'toad', category: 'animals'),
  AwingWord(awing: 'anjwa', english: 'giraffe', category: 'animals'),
  AwingWord(awing: 'ŋjakásə', english: 'donkey', category: 'animals'),
  AwingWord(awing: "nka'ə", english: 'leopard', category: 'animals'),
  AwingWord(awing: 'kígháləgháló', english: 'butterfly', category: 'animals'),
  AwingWord(awing: 'fóolɔ́', english: 'rat', category: 'animals'),
  AwingWord(awing: 'anɔ́mɔ́', english: 'louse', category: 'animals'),
  AwingWord(awing: 'njá', english: 'shrimp', category: 'animals'),
  AwingWord(awing: 'ngwúmnɔ́', english: 'locust', category: 'animals'),
  AwingWord(awing: "tɔ'lɔ́", english: 'squirrel', category: 'animals'),
  AwingWord(awing: "əŋka'ɔ́", english: 'rooster', category: 'animals'),
  // Beginner nature
  AwingWord(awing: 'atîə', english: 'tree', category: 'nature'),
  AwingWord(awing: 'akoobɔ́', english: 'forest', category: 'nature'),
  AwingWord(awing: "ngə'ə", english: 'stone', category: 'nature'),
  AwingWord(awing: 'wâakɔ́', english: 'sand', category: 'nature'),
  AwingWord(awing: 'afûə', english: 'leaf', category: 'nature'),
  AwingWord(awing: 'sánə', english: 'moon', category: 'nature'),
  AwingWord(awing: 'ndě', english: 'water (drink)', category: 'nature'),
  AwingWord(awing: 'íŋə', english: 'fire', category: 'nature'),
  AwingWord(awing: 'àlě', english: 'day', category: 'nature'),
  AwingWord(awing: 'aləmə', english: 'cloud', category: 'nature'),
  AwingWord(awing: 'aləmó', english: 'pool', category: 'nature'),
  AwingWord(awing: 'nkîə', english: 'river/stream', category: 'nature'),
  AwingWord(awing: 'nəpóolə', english: 'sky', category: 'nature'),
  AwingWord(awing: 'mɔ́numə', english: 'sun', category: 'nature'),
  AwingWord(awing: 'mbəŋə', english: 'rain', category: 'nature'),
  AwingWord(awing: 'sɔ́mə', english: 'wind', category: 'nature'),
  AwingWord(awing: 'nəyeŋɔ́', english: 'grass', category: 'nature'),
  AwingWord(awing: 'nəfáŋɔ́', english: 'thunder', category: 'nature'),
  AwingWord(awing: "nətú'ə", english: 'night', category: 'nature'),
  AwingWord(awing: 'alě', english: 'morning', category: 'nature'),
  AwingWord(awing: 'nkwanɔ́', english: 'evening', category: 'nature'),
  AwingWord(awing: 'alanə', english: 'road/path', category: 'nature'),
  AwingWord(awing: 'nəfógə', english: 'waterfall', category: 'nature'),
  AwingWord(awing: 'ndəsê', english: 'ground/earth', category: 'nature'),
  AwingWord(awing: 'mɔ́lɔ̂glə', english: 'shadow', category: 'nature'),
  AwingWord(awing: 'ndo', english: 'valley', category: 'nature'),
  AwingWord(awing: 'nkwəənə', english: 'mountain', category: 'nature'),
  AwingWord(awing: "nkya' sáŋə", english: 'moonlight', category: 'nature'),
  // Medium/Expert
  AwingWord(awing: "anyeŋə", english: 'claw', category: 'animals', difficulty: 2),
  AwingWord(awing: "nənjwínnə", english: 'fly', category: 'animals', difficulty: 2),
  AwingWord(awing: "ngə'ɔ́", english: 'termite', category: 'animals', difficulty: 2),
  AwingWord(awing: "njɔ́ə", english: 'groundnuts', category: 'nature', difficulty: 2),
  AwingWord(awing: "nkəŋə", english: 'peace plant', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ɔ̀fɨ̂ə', english: 'medicine', category: 'nature', difficulty: 2),
  AwingWord(awing: 'əfóonə', english: 'hunting', category: 'nature', difficulty: 2),
  AwingWord(awing: 'əkəghanə', english: 'okra', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəwûə', english: 'death', category: 'nature', difficulty: 3),
];

/// Food and drink — things kids eat and drink
const List<AwingWord> foodDrink = [
  // Beginner — common foods
  AwingWord(awing: 'majîə', english: 'food/meal', category: 'food'),
  AwingWord(awing: "amú'ɔ́", english: 'banana', category: 'food'),
  AwingWord(awing: "azó'ə", english: 'yam', category: 'food'),
  AwingWord(awing: "akwú'ɔ́", english: 'cocoyam', category: 'food'),
  AwingWord(awing: 'ngəsáŋɔ́', english: 'corn/maize', category: 'food'),
  AwingWord(awing: 'nûə', english: 'honey', category: 'food'),
  AwingWord(awing: 'ndzě', english: 'vegetable', category: 'food'),
  AwingWord(awing: 'mâfe', english: 'sweet potato', category: 'food'),
  AwingWord(awing: 'apopó', english: 'pawpaw', category: 'food'),
  AwingWord(awing: 'nəpumɔ́', english: 'egg', category: 'food', pluralForm: 'mbumɔ́'),
  AwingWord(awing: 'neemə', english: 'meat', category: 'food'),
  AwingWord(awing: 'nəkwúnə', english: 'rice', category: 'food'),
  AwingWord(awing: 'mɔ́lígə', english: 'milk', category: 'food'),
  AwingWord(awing: 'lámɔ́sə', english: 'orange', category: 'food'),
  AwingWord(awing: 'tâmto', english: 'tomato', category: 'food'),
  AwingWord(awing: "ná'ə", english: 'soup/sauce', category: 'food'),
  AwingWord(awing: 'ngwápa', english: 'guava', category: 'food'),
  AwingWord(awing: 'panɔ́paələ', english: 'pineapple', category: 'food'),
  AwingWord(awing: 'akəfé', english: 'coffee', category: 'food'),
  AwingWord(awing: 'pyâ', english: 'avocado', category: 'food'),
  AwingWord(awing: 'ngéemə', english: 'bunch of banana', category: 'food'),
  AwingWord(awing: "achú'ə", english: 'pounded cocoyam', category: 'food'),
  AwingWord(awing: "nəlɔ'ɔ́", english: 'sweet yam', category: 'food'),
  AwingWord(awing: 'nkwûə', english: 'sort of okra', category: 'food'),
  AwingWord(awing: "ɔ́nyúsə", english: 'onion', category: 'food'),
  // Medium
  AwingWord(awing: 'aŋkəsálə', english: 'cassava', category: 'food', difficulty: 2),
  AwingWord(awing: 'nəgɔ̌əbə', english: 'goblet', category: 'food', difficulty: 2),
  AwingWord(awing: 'apéenə', english: 'fufu corn', category: 'food', difficulty: 2),
  AwingWord(awing: 'galéba', english: 'grape', category: 'food', difficulty: 2),
  AwingWord(awing: "shí sɔ̂ntê", english: 'green pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "paŋ sɔ̂ntê", english: 'red pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "nkɔ̂ŋ ɔ̂'lə", english: 'sugar cane', category: 'food', difficulty: 2),
];

/// Simple actions (verbs) — everyday actions kids can act out
const List<AwingWord> actions = [
  // Beginner — simple everyday actions
  AwingWord(awing: 'nô', english: 'drink', category: 'actions'),
  AwingWord(awing: 'ko', english: 'take', category: 'actions'),
  AwingWord(awing: 'yîə', english: 'come', category: 'actions'),
  AwingWord(awing: 'fê', english: 'give', category: 'actions'),
  AwingWord(awing: 'mîə', english: 'swallow', category: 'actions'),
  AwingWord(awing: 'lúmə', english: 'bite', category: 'actions'),
  AwingWord(awing: "zó'ə", english: 'hear', category: 'actions'),
  AwingWord(awing: 'pímə', english: 'see', category: 'actions'),
  AwingWord(awing: 'pɛ́nə', english: 'dance', category: 'actions'),
  AwingWord(awing: "cha'tɔ́", english: 'greet', category: 'actions'),
  AwingWord(awing: 'túmə', english: 'send', category: 'actions'),
  AwingWord(awing: 'léŋə', english: 'lick', category: 'actions'),
  AwingWord(awing: "lyáŋə", english: 'hide', category: 'actions'),
  AwingWord(awing: 'fínə', english: 'sell', category: 'actions', shortForm: 'fi'),
  AwingWord(awing: 'ghɛnɔ́', english: 'go', category: 'actions'),
  AwingWord(awing: 'pìə', english: 'give birth', category: 'actions'),
  AwingWord(awing: 'kâ', english: 'smell', category: 'actions'),
  AwingWord(awing: 'tɨ̂ə', english: 'stand', category: 'actions', shortForm: 'tî'),
  AwingWord(awing: 'kwúnə', english: 'enter', category: 'actions'),
  AwingWord(awing: 'kə́ərə', english: 'run', category: 'actions'),
  AwingWord(awing: 'kíə', english: 'pay (money)', category: 'actions'),
  AwingWord(awing: 'fɔ̂nə', english: 'read', category: 'actions'),
  AwingWord(awing: 'jwîə', english: 'breathe', category: 'actions'),
  AwingWord(awing: 'pyáabə', english: 'watch/wait', category: 'actions'),
  AwingWord(awing: 'kyagó', english: 'untie', category: 'actions'),
  AwingWord(awing: "ńnáŋ", english: 'look at', category: 'actions'),
  AwingWord(awing: 'jíə', english: 'eat', category: 'actions'),
  AwingWord(awing: 'lê', english: 'sleep', category: 'actions'),
  AwingWord(awing: 'jwítə', english: 'rest', category: 'actions'),
  AwingWord(awing: "júnə", english: 'buy', category: 'actions'),
  AwingWord(awing: 'kóolə', english: 'catch/harvest', category: 'actions'),
  AwingWord(awing: 'ghɛdtɔ́', english: 'do a little', category: 'actions'),
  AwingWord(awing: 'nyinɔ́', english: 'walk/travel', category: 'actions'),
  AwingWord(awing: 'nyintɔ́', english: 'take a walk', category: 'actions'),
  AwingWord(awing: 'tómə', english: 'kick/shoot', category: 'actions'),
  AwingWord(awing: 'sóŋə', english: 'say/speak', category: 'actions'),
  AwingWord(awing: 'wiŋɔ́', english: 'laugh', category: 'actions'),
  AwingWord(awing: 'weŋɔ́', english: 'smile', category: 'actions'),
  AwingWord(awing: 'kyéŋə', english: 'cry/weep', category: 'actions'),
  AwingWord(awing: 'zoobɔ́', english: 'sing', category: 'actions'),
  AwingWord(awing: "ŋwa'lɔ́", english: 'write', category: 'actions'),
  AwingWord(awing: "zé'kə", english: 'teach', category: 'actions'),
  AwingWord(awing: "zé'ə", english: 'learn', category: 'actions'),
  AwingWord(awing: 'pookɔ́', english: 'say goodbye', category: 'actions'),
  AwingWord(awing: 'sogɔ́', english: 'wash', category: 'actions'),
  AwingWord(awing: 'léelə', english: 'prepare', category: 'actions'),
  AwingWord(awing: 'kamtɔ́', english: 'eat hastily', category: 'actions'),
  AwingWord(awing: 'loonɔ́', english: 'desire/want', category: 'actions'),
  AwingWord(awing: "wɔ́'tə", english: 'remember', category: 'actions'),
  AwingWord(awing: 'piímə', english: 'believe/accept', category: 'actions'),
  AwingWord(awing: 'logŋə', english: 'forget', category: 'actions'),
  // Medium
  AwingWord(awing: "tsó'ə", english: 'heal', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwágə', english: 'cough', category: 'actions', difficulty: 2),
  AwingWord(awing: 'twâŋə', english: 'bury', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fyáalə', english: 'chase', category: 'actions', difficulty: 2),
  AwingWord(awing: "ŋá'ə", english: 'open', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jágə', english: 'yawn', category: 'actions', difficulty: 2),
  AwingWord(awing: 'sɛ́nə', english: 'cut open', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsɛ́bə', english: 'talk', category: 'actions', difficulty: 2, shortForm: 'tsáb'),
  AwingWord(awing: 'zɔ̀ɔmə', english: 'insult', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zə́ənə', english: 'find', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fìə', english: 'sell', category: 'actions', difficulty: 2, shortForm: 'fî'),
  AwingWord(awing: 'mwé', english: 'salty', category: 'actions', difficulty: 2),
  AwingWord(awing: "myá'á", english: 'throw away', category: 'actions', difficulty: 2),
];

/// Things, objects, and food — words kids encounter daily
const List<AwingWord> thingsObjects = [
  // Beginner — everyday objects and food
  AwingWord(awing: 'ajúmə', english: 'thing', category: 'things'),
  AwingWord(awing: 'nəgoomɔ́', english: 'plantain', category: 'things'),
  AwingWord(awing: 'ngwáŋə', english: 'salt', category: 'things'),
  AwingWord(awing: 'ndzǒ', english: 'beans', category: 'things'),
  AwingWord(awing: 'mândzǒ', english: 'groundnuts', category: 'things'),
  AwingWord(awing: "nəpɔ'ɔ́", english: 'pumpkin', category: 'things'),
  AwingWord(awing: 'nduə', english: 'hammer', category: 'things'),
  AwingWord(awing: 'əkwunɔ́', english: 'bed', category: 'things'),
  AwingWord(awing: 'nəkəŋɔ́', english: 'pot', category: 'things', pluralForm: 'məkəŋɔ́'),
  AwingWord(awing: 'apeemə', english: 'bag', category: 'things', shortForm: 'apa'),
  AwingWord(awing: 'əpúmə', english: 'basket (large)', category: 'things'),
  AwingWord(awing: 'ajwikə', english: 'window', category: 'things'),
  AwingWord(awing: 'mbê', english: 'knife', category: 'things'),
  AwingWord(awing: 'kəíə', english: 'chair', category: 'things'),
  AwingWord(awing: 'lɛ̀ərə', english: 'hat', category: 'things'),
  AwingWord(awing: "shwa'a", english: 'razor', category: 'things'),
  AwingWord(awing: 'əlɔ́ŋə', english: 'dance group', category: 'things'),
  AwingWord(awing: 'ŋgɛ̀ərə', english: 'gun', category: 'things'),
  AwingWord(awing: 'mətwé', english: 'saliva', category: 'things'),
  AwingWord(awing: 'akwâalə', english: 'support', category: 'things'),
  AwingWord(awing: 'əpéenə', english: 'bread', category: 'things'),
  AwingWord(awing: "nətó'ə", english: 'potato', category: 'things'),
  AwingWord(awing: 'apúə', english: 'ashes', category: 'things'),
  AwingWord(awing: 'kóŋó', english: 'ditch', category: 'things'),
  AwingWord(awing: "əsá'ə", english: 'needle', category: 'things'),
  AwingWord(awing: 'ndê', english: 'house', category: 'things'),
  AwingWord(awing: 'ntɔ̂ŋɔ̂', english: 'hut', category: 'things'),
  AwingWord(awing: 'atɔ́gə', english: 'room', category: 'things'),
  AwingWord(awing: 'asogə', english: 'soap', category: 'things'),
  AwingWord(awing: "atsa'ɔ́", english: 'clothes', category: 'things'),
  AwingWord(awing: 'múto', english: 'car', category: 'things'),
  AwingWord(awing: "aŋwa'lə", english: 'book/school', category: 'things'),
  AwingWord(awing: 'kíə', english: 'key (lock)', category: 'things'),
  AwingWord(awing: 'mógɔ́', english: 'fire/burn', category: 'things'),
  AwingWord(awing: 'chénə', english: 'chain', category: 'things'),
  AwingWord(awing: 'nkelɔ́', english: 'rope', category: 'things', pluralForm: 'mənkelɔ́'),
  AwingWord(awing: 'nkwumə', english: 'box', category: 'things'),
  AwingWord(awing: 'bɔ̂lə', english: 'ball', category: 'things'),
  AwingWord(awing: "ntso ndê", english: 'door', category: 'things'),
  AwingWord(awing: 'nkéemɔ́', english: 'basket', category: 'things'),
  AwingWord(awing: "kwa'ɔ́", english: 'plate', category: 'things'),
  AwingWord(awing: 'nto', english: 'trousers', category: 'things'),
  AwingWord(awing: "ntó'ə", english: 'calabash', category: 'things'),
  AwingWord(awing: "nkéebə", english: 'money', category: 'things', pluralForm: 'mənkéebə'),
  AwingWord(awing: 'atso', english: 'musical instrument', category: 'things'),
  AwingWord(awing: 'ntâŋɔ̂', english: 'horn', category: 'things'),
  AwingWord(awing: 'máta', english: 'mat', category: 'things'),
  AwingWord(awing: 'nkîə', english: 'song', category: 'things'),
  AwingWord(awing: "nda'ə", english: 'string', category: 'things'),
  AwingWord(awing: 'bɔ́bə', english: 'bulb/ball', category: 'things'),
  AwingWord(awing: 'ŋwíŋɔ́', english: 'machete/cutlass', category: 'things'),
  AwingWord(awing: 'ndaŋɔ́', english: 'bamboo', category: 'things'),
  AwingWord(awing: 'táksa', english: 'tax', category: 'things'),
  // Medium/Expert — less common objects
  AwingWord(awing: 'mbéenə', english: 'nail', category: 'things', difficulty: 2),
  AwingWord(awing: "fwɔ'ə", english: 'chisel', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzoəmə', english: 'dream', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndwîgtə', english: 'end', category: 'things', difficulty: 2),
  AwingWord(awing: 'ɔ̂twé', english: 'saliva', category: 'things', difficulty: 2),
  AwingWord(awing: "əghâa", english: 'season', category: 'things', difficulty: 3),
  AwingWord(awing: 'nəse', english: 'grave', category: 'things', difficulty: 3),
];

/// Family, people, and places — essential for conversations
const List<AwingWord> familyPeople = [
  // Beginner — family and common places
  AwingWord(awing: 'mǎ', english: 'mother', category: 'family', pluralForm: 'pəmǎ'),
  AwingWord(awing: 'tátə', english: 'grandfather', category: 'family'),
  AwingWord(awing: 'mábna', english: 'baby', category: 'family'),
  AwingWord(awing: 'yə', english: 'he/she', category: 'family'),
  AwingWord(awing: "alá'ə", english: 'village', category: 'family', pluralForm: "əlá'ə"),
  AwingWord(awing: 'adě', english: 'house', category: 'family'),
  AwingWord(awing: 'ngye', english: 'voice', category: 'family'),
  AwingWord(awing: 'mətéenɔ́', english: 'market', category: 'family'),
  AwingWord(awing: 'əfɔ́nə', english: 'reader', category: 'family', pluralForm: 'pəfɔ́nə'),
  AwingWord(awing: 'ndáəshə', english: 'thief', category: 'family'),
  AwingWord(awing: 'əndìmə', english: 'nephew', category: 'family'),
  AwingWord(awing: 'ŋgàmə', english: 'mother-in-law', category: 'family'),
  AwingWord(awing: 'əgùərə', english: 'descendant', category: 'family'),
  AwingWord(awing: 'tǎ', english: 'father/parent', category: 'family', pluralForm: 'pətǎ'),
  AwingWord(awing: 'ngəənə', english: 'friend', category: 'family', pluralForm: 'pəghəənə'),
  AwingWord(awing: 'ndúmə', english: 'husband', category: 'family'),
  AwingWord(awing: 'maŋgyè', english: 'wife', category: 'family'),
  AwingWord(awing: 'ndè', english: 'elder', category: 'family'),
  AwingWord(awing: 'əfo', english: 'chief/ruler', category: 'family'),
  AwingWord(awing: "ŋwunə", english: 'person', category: 'family', pluralForm: 'paənə'),
  AwingWord(awing: "mɔ́ mbyâŋnə", english: 'boy/son', category: 'family'),
  AwingWord(awing: "mɔ́ maŋgyè", english: 'girl/daughter', category: 'family'),
  AwingWord(awing: 'mɔ́ŋkə', english: 'child', category: 'family'),
  AwingWord(awing: 'ngaŋə', english: 'owner', category: 'family'),
  AwingWord(awing: "ngaŋəfa'ə", english: 'servant', category: 'family'),
  AwingWord(awing: "nkɔ́'ə", english: 'butcher', category: 'family'),
  AwingWord(awing: 'atúmə', english: 'country/land', category: 'family'),
  AwingWord(awing: 'afoonə', english: 'farm', category: 'family'),
  AwingWord(awing: 'nchîndê', english: 'compound', category: 'family'),
  AwingWord(awing: "ali'ə", english: 'place', category: 'family'),
  AwingWord(awing: 'awátə', english: 'hospital', category: 'family'),
  AwingWord(awing: 'chɔ́sə', english: 'church', category: 'family'),
  // Medium/Expert
  AwingWord(awing: 'ayáŋə', english: 'wisdom', category: 'family', difficulty: 2),
  AwingWord(awing: 'nkɨ́ə', english: 'stream', category: 'family', difficulty: 2),
  AwingWord(awing: 'apɛ̌ɛlə', english: 'mad person', category: 'family', difficulty: 2),
  AwingWord(awing: "əfəgɔ́", english: 'blind person', category: 'family', difficulty: 2),
  AwingWord(awing: 'əlɔ́ɔnə', english: 'beggar', category: 'family', difficulty: 3),
];

/// Numbers and counting
const List<AwingWord> numbers = [
  AwingWord(awing: 'əmɔ́', english: 'one', category: 'numbers'),
  AwingWord(awing: 'əpá', english: 'two', category: 'numbers'),
  AwingWord(awing: 'əlɛ́', english: 'three', category: 'numbers'),
  AwingWord(awing: 'əkwá', english: 'four', category: 'numbers'),
  AwingWord(awing: 'ətáanə', english: 'five', category: 'numbers'),
  AwingWord(awing: 'ntúu', english: 'six', category: 'numbers'),
  AwingWord(awing: 'tsɔ̂mbí', english: 'seven', category: 'numbers'),
  AwingWord(awing: 'nɛ̂ŋ', english: 'eight', category: 'numbers'),
  AwingWord(awing: 'əbwá', english: 'nine', category: 'numbers'),
  AwingWord(awing: 'əghám', english: 'ten', category: 'numbers'),
];

// ============================================================
// MEDIUM/EXPERT VOCABULARY (difficulty: 2-3) — more complex words
// ============================================================

/// More actions/verbs from the orthography & phonology PDFs
const List<AwingWord> moreActions = [
  // Medium
  AwingWord(awing: 'shîə', english: 'stretch', category: 'actions', difficulty: 2),
  AwingWord(awing: 'yîkə', english: 'harden', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tɔ́gə', english: 'blow', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kaŋtɔ́', english: 'stumble', category: 'actions', difficulty: 2),
  AwingWord(awing: 'sɛdnɔ́', english: 'turn round', category: 'actions', difficulty: 2),
  AwingWord(awing: 'nyaglɔ́', english: 'tickle', category: 'actions', difficulty: 2),
  AwingWord(awing: 'nɔ́ŋə', english: 'suck', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lɛdnɔ́', english: 'sweat', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pìkə', english: 'twist', category: 'actions', difficulty: 2),
  AwingWord(awing: 'sɔ̀ɔbə', english: 'stab', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwúbtə', english: 'close', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwùɔbə', english: 'exchange', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lɛ̀ŋkə', english: 'fill', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ídkə', english: 'frighten', category: 'actions', difficulty: 2),
  AwingWord(awing: 'nwâŋə', english: 'disappear', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ɔ̂ŋwâə', english: 'be clean', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tɔ̂ənə', english: 'be mature', category: 'actions', difficulty: 2, shortForm: 'tə̂nə'),
  AwingWord(awing: 'fìnə', english: 'resemble each other', category: 'actions', difficulty: 2),
  AwingWord(awing: "tyá'lə", english: 'straddle', category: 'actions', difficulty: 2),
  AwingWord(awing: 'puónə', english: 'dip in water', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chwigó', english: 'spy', category: 'actions', difficulty: 2),
  // Expert
  AwingWord(awing: 'tɔ́əmə', english: 'choke', category: 'actions', difficulty: 3),
  AwingWord(awing: "ne'ɔ́", english: 'limp', category: 'actions', difficulty: 3),
  AwingWord(awing: "pwɔ́nə", english: 'appease', category: 'actions', difficulty: 3),
  AwingWord(awing: "wâarə", english: 'slaughter', category: 'actions', difficulty: 3),
  AwingWord(awing: "ɔ̀pwə̂nənə", english: 'be kind', category: 'actions', difficulty: 3),
  AwingWord(awing: 'ntɨ́mmaə', english: 'stagger', category: 'actions', difficulty: 3),
];

/// More things/objects — medium and expert level
const List<AwingWord> moreThings = [
  AwingWord(awing: 'nəchwélə', english: 'hearth', category: 'things', difficulty: 2),
  AwingWord(awing: "ntúmkə", english: 'entrance hut', category: 'things', difficulty: 2),
  AwingWord(awing: 'əlɛɛlə', english: 'bridge', category: 'things', difficulty: 2),
  AwingWord(awing: 'ŋgwɔ́ɔlə', english: 'snail', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəghǒ', english: 'grinding stone', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwé', english: 'response', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoolá', english: 'latrine', category: 'things', difficulty: 2),
  AwingWord(awing: "ashwí'ə", english: 'swelling', category: 'things', difficulty: 2),
  AwingWord(awing: 'njwîŋə', english: 'whistle', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbwódnə', english: 'blessing', category: 'things', difficulty: 2),
  AwingWord(awing: "ngó'ə", english: 'hardship', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwúə', english: 'corpse', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsáŋə', english: 'punishment', category: 'things', difficulty: 3),
  AwingWord(awing: 'ntsoolə', english: 'war/fight', category: 'things', difficulty: 3, pluralForm: 'məntsoolə'),
  AwingWord(awing: "ŋwáglɔ́", english: 'bell', category: 'things', difficulty: 3),
  AwingWord(awing: 'azagɔ́', english: 'odour', category: 'things', difficulty: 3),
];

/// Descriptive words (adjectives/adverbs) — colors, sizes, qualities
const List<AwingWord> descriptiveWords = [
  // Colors and appearance
  AwingWord(awing: 'shíshíə', english: 'black', category: 'descriptive'),
  AwingWord(awing: 'fúfûə', english: 'white', category: 'descriptive'),
  AwingWord(awing: 'paŋpaŋə', english: 'red', category: 'descriptive'),
  AwingWord(awing: 'sénə', english: 'blue/green/dark', category: 'descriptive'),
  // Size and shape
  AwingWord(awing: 'wíŋɔ́', english: 'big', category: 'descriptive'),
  AwingWord(awing: 'mɔ́', english: 'small', category: 'descriptive'),
  AwingWord(awing: 'sagɔ́', english: 'long/far', category: 'descriptive'),
  AwingWord(awing: 'kamkɔ̂', english: 'short', category: 'descriptive'),
  AwingWord(awing: 'fáŋə', english: 'fat/thick', category: 'descriptive'),
  AwingWord(awing: 'ashwánə', english: 'thin', category: 'descriptive'),
  // Qualities
  AwingWord(awing: "ashî'nə", english: 'good/kind', category: 'descriptive'),
  AwingWord(awing: 'pɔ̀ŋɔ́', english: 'beautiful', category: 'descriptive'),
  AwingWord(awing: 'tɔnɔ́', english: 'hot', category: 'descriptive'),
  AwingWord(awing: 'nwâ', english: 'cold', category: 'descriptive'),
  AwingWord(awing: 'tyantɔ̌', english: 'hard/strong', category: 'descriptive'),
  AwingWord(awing: "fía", english: 'new/fresh', category: 'descriptive'),
  AwingWord(awing: 'ndenə', english: 'old', category: 'descriptive'),
  AwingWord(awing: 'mboŋɔ́', english: 'many/much', category: 'descriptive'),
  AwingWord(awing: "nta'lə", english: 'few/little', category: 'descriptive'),
  AwingWord(awing: 'senɔ́', english: 'today', category: 'descriptive'),
  AwingWord(awing: "ngwe'ɔ́", english: 'tomorrow', category: 'descriptive'),
  AwingWord(awing: 'əzoonɔ́', english: 'yesterday', category: 'descriptive'),
  AwingWord(awing: 'zá', english: 'often/usually', category: 'descriptive'),
  // Medium difficulty
  AwingWord(awing: 'dɔtɔ́', english: 'ugly', category: 'descriptive', difficulty: 2),
  AwingWord(awing: "tɔ̀jí'ə", english: 'alone', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'pátə', english: 'even though', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'chígɔ́', english: 'truly/really', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ghâsə', english: 'clever/smart', category: 'descriptive', difficulty: 2),
  AwingWord(awing: "zaŋkɔ̂", english: 'light (not heavy)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'kóŋɔ́', english: 'empty', category: 'descriptive', difficulty: 2),
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

/// Simple, kid-friendly phrases organized from easiest to hardest.
/// Each phrase uses only common Awing words.
const List<AwingPhrase> awingPhrases = [
  // === GREETINGS (the first thing every learner needs) ===
  AwingPhrase(
    awing: "Apellah!",
    english: "How are you?",
    context: "The simplest, most common Awing greeting",
    category: 'greeting',
    clipKey: 'greeting_apellah',
  ),
  AwingPhrase(
    awing: "Cha'tɔ́!",
    english: "Greetings!",
    context: "General greeting when meeting someone",
    category: 'greeting',
    clipKey: 'greeting_chatoo',
  ),
  AwingPhrase(
    awing: "Yə kwa'ə.",
    english: "I am fine.",
    context: "Reply to 'How are you?'",
    category: 'greeting',
    clipKey: 'greeting_kwae',
  ),
  AwingPhrase(
    awing: "Ee!",
    english: "Yes!",
    context: "Simple yes — used very often",
    category: 'greeting',
    clipKey: 'greeting_ee',
  ),
  AwingPhrase(
    awing: "Wo'!",
    english: "Sure! / Of course!",
    context: "Agreeing with someone enthusiastically",
    category: 'greeting',
    clipKey: 'greeting_wo',
  ),

  // === DAILY LIFE (simple, practical phrases) ===
  AwingPhrase(
    awing: "Lɛ̌ ndo?",
    english: "What is this?",
    context: "Pointing at something and asking what it is",
    category: 'daily',
    clipKey: 'daily_what_is_this',
  ),
  AwingPhrase(
    awing: "Ko pə nəgoomɔ́.",
    english: "Give me plantain.",
    context: "Asking for food — simple request",
    category: 'daily',
    clipKey: 'daily_give_plantain',
  ),
  AwingPhrase(
    awing: "Yîə fɛ́ə!",
    english: "Come here!",
    context: "Calling someone to come to you",
    category: 'daily',
    clipKey: 'daily_come_here',
  ),
  AwingPhrase(
    awing: "Ko pə asé.",
    english: "Come and sit down.",
    context: "Inviting someone to sit — welcoming a visitor",
    category: 'daily',
    clipKey: 'daily_sit_down',
  ),
  AwingPhrase(
    awing: "A kə ghɛnɔ́ mətéenɔ́.",
    english: "He went to the market.",
    context: "Talking about where someone went",
    category: 'daily',
    clipKey: 'daily_market',
  ),

  // === QUESTIONS (simple questions kids ask) ===
  AwingPhrase(
    awing: "Ache kə?",
    english: "What do you want?",
    context: "Asking someone what they need",
    category: 'question',
    clipKey: 'question_what_want',
  ),
  AwingPhrase(
    awing: "Ghô ghɛnɔ́ lə afô?",
    english: "Where are you going?",
    context: "Asking someone where they are headed",
    category: 'question',
    clipKey: 'question_where_going',
  ),
  AwingPhrase(
    awing: "Ee wə nə kó?",
    english: "Is it good?",
    context: "Asking if something is good or okay",
    category: 'question',
    clipKey: 'question_is_good',
  ),

  // === CLASSROOM (phrases for learners) ===
  AwingPhrase(
    awing: "Nô ndèe.",
    english: "Drink water.",
    context: "Simple command — useful in class",
    category: 'classroom',
    clipKey: 'classroom_drink_water',
  ),
  AwingPhrase(
    awing: "Pímə fɛ́ə!",
    english: "Look here!",
    context: "Getting someone's attention",
    category: 'classroom',
    clipKey: 'classroom_look_here',
  ),
  AwingPhrase(
    awing: "Lô!",
    english: "Get out!",
    context: "Telling someone to leave — exclamation",
    category: 'classroom',
    clipKey: 'classroom_get_out',
  ),

  // === FAREWELLS ===
  AwingPhrase(
    awing: "Wə yîə ndèe.",
    english: "Come back again.",
    context: "Inviting someone to return",
    category: 'farewell',
    clipKey: 'farewell_come_back',
  ),
  AwingPhrase(
    awing: "Cha'tɔ́ ndèe!",
    english: "Goodbye!",
    context: "Final farewell greeting",
    category: 'farewell',
    clipKey: 'farewell_goodbye',
  ),
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
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/// All vocabulary combined for easy access
List<AwingWord> get allVocabulary => [
  ...bodyParts,
  ...animalsNature,
  ...foodDrink,
  ...actions,
  ...thingsObjects,
  ...familyPeople,
  ...numbers,
  ...moreActions,
  ...moreThings,
  ...descriptiveWords,
];

/// Get vocabulary by category
List<AwingWord> getVocabularyByCategory(String category) {
  return allVocabulary.where((w) => w.category == category).toList();
}

/// Get vocabulary by difficulty level
List<AwingWord> getVocabularyByDifficulty(int level) {
  return allVocabulary.where((w) => w.difficulty <= level).toList();
}
