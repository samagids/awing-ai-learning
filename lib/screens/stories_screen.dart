import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Data class for a single story
class AwingStory {
  final String titleEnglish;
  final String titleAwing;
  final String illustration; // emoji/icon placeholder
  final List<StorySentence> sentences;
  final List<StoryVocabulary> vocabulary;
  final List<ComprehensionQuestion> questions;
  bool isCompleted;

  AwingStory({
    required this.titleEnglish,
    required this.titleAwing,
    required this.illustration,
    required this.sentences,
    required this.vocabulary,
    required this.questions,
    this.isCompleted = false,
  });
}

/// A sentence in a story
class StorySentence {
  final String awing;
  final String english;

  const StorySentence({
    required this.awing,
    required this.english,
  });
}

/// Vocabulary item with Awing and English
class StoryVocabulary {
  final String awing;
  final String english;

  const StoryVocabulary({
    required this.awing,
    required this.english,
  });
}

/// Multiple choice comprehension question
class ComprehensionQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options; // includes correct answer, already shuffled

  const ComprehensionQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

/// ============================================================================
/// STORY DATA — 4 short Awing stories for kids
/// ============================================================================

final List<AwingStory> awingStories = [
  AwingStory(
    titleEnglish: 'The Owl and the Fish',
    titleAwing: 'Koŋə ne əshûə',
    illustration: '🦉',
    sentences: [
      StorySentence(
        awing: 'Koŋə yǐə alá\'ə.',
        english: 'The owl came to the village.',
      ),
      StorySentence(
        awing: 'Yə zó\'ə wâakɔ́ ne ndě.',
        english: 'She heard sounds at the water.',
      ),
      StorySentence(
        awing: 'Əshûə nyɛ́ə wâakɔ́.',
        english: 'The fish was in the water.',
      ),
      StorySentence(
        awing: 'Koŋə pímə əshûə.',
        english: 'The owl saw the fish.',
      ),
      StorySentence(
        awing: 'Yə cha\'tɔ́ əshûə ne mîə nô.',
        english: 'She greeted the fish, who swallowed water.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'koŋə', english: 'owl'),
      StoryVocabulary(awing: 'əshûə', english: 'fish'),
      StoryVocabulary(awing: 'alá\'ə', english: 'village'),
      StoryVocabulary(awing: 'yǐə', english: 'come'),
      StoryVocabulary(awing: 'zó\'ə', english: 'hear'),
      StoryVocabulary(awing: 'wâakɔ́', english: 'water'),
      StoryVocabulary(awing: 'pímə', english: 'see/believe'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
      StoryVocabulary(awing: 'mîə', english: 'swallow'),
      StoryVocabulary(awing: 'nô', english: 'drink'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did the owl go?',
        correctAnswer: 'to the village',
        options: ['to the village', 'to the forest', 'to the tree'],
      ),
      ComprehensionQuestion(
        question: 'What animal did the owl see in the water?',
        correctAnswer: 'a fish',
        options: ['a fish', 'a snake', 'a bird'],
      ),
      ComprehensionQuestion(
        question: 'What did the owl do with the fish?',
        correctAnswer: 'She greeted it',
        options: ['She greeted it', 'She caught it', 'She danced with it'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'Mother\'s Hands',
    titleAwing: 'Mǎ ne apô',
    illustration: '👩',
    sentences: [
      StorySentence(
        awing: 'Mǎ nkadtə nə nəgoomɔ́.',
        english: 'Mother prepared plantain.',
      ),
      StorySentence(
        awing: 'Apô yə kwágə pɛ́nə.',
        english: 'Her hands worked and danced.',
      ),
      StorySentence(
        awing: 'Yə ko afûə ne ngwáŋə.',
        english: 'She took leaves and salt.',
      ),
      StorySentence(
        awing: 'Məkəŋɔ́ yə nyɛ́ə atîə.',
        english: 'The pots sat on the fire.',
      ),
      StorySentence(
        awing: 'Pəmǎ cha\'tɔ́ məndě ne yə pímə.',
        english: 'The mothers greeted each other when they saw her food.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'mǎ', english: 'mother'),
      StoryVocabulary(awing: 'apô', english: 'hand'),
      StoryVocabulary(awing: 'nəgoomɔ́', english: 'plantain'),
      StoryVocabulary(awing: 'afûə', english: 'leaf/medicine'),
      StoryVocabulary(awing: 'ngwáŋə', english: 'salt'),
      StoryVocabulary(awing: 'nəkəŋɔ́', english: 'pot'),
      StoryVocabulary(awing: 'atîə', english: 'tree/fire'),
      StoryVocabulary(awing: 'ko', english: 'take'),
      StoryVocabulary(awing: 'pɛ́nə', english: 'dance'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What did Mother prepare?',
        correctAnswer: 'plantain',
        options: ['plantain', 'fish', 'beans'],
      ),
      ComprehensionQuestion(
        question: 'What ingredients did Mother use?',
        correctAnswer: 'leaves and salt',
        options: ['leaves and salt', 'sand and water', 'stones and wood'],
      ),
      ComprehensionQuestion(
        question: 'Why did the mothers greet each other?',
        correctAnswer: 'They saw her good food',
        options: ['They saw her good food', 'They heard music', 'They danced together'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Village',
    titleAwing: 'Alá\'ə ne pɛ́nə',
    illustration: '🏘️',
    sentences: [
      StorySentence(
        awing: 'Alá\'ə nyɛ́ə pəlɛ́ə ne asɨ́ə.',
        english: 'The village had many people and houses.',
      ),
      StorySentence(
        awing: 'Mbe\'tə pɛ́nə pimə akoobɔ́.',
        english: 'The young people danced and looked at the forest.',
      ),
      StorySentence(
        awing: 'Cha\'tɔ́ nyɛ́ə ngye pəmǎ ne pəyə.',
        english: 'Greetings were the voices of mothers and fathers.',
      ),
      StorySentence(
        awing: 'Pəndě nəkəŋɔ́ nyɛ́ə meŋ ne mândzǒ.',
        english: 'The pots held soup and groundnuts.',
      ),
      StorySentence(
        awing: 'Ayáŋə pə ndě alá\'ə.',
        english: 'The wisdom lived in the village.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'alá\'ə', english: 'village'),
      StoryVocabulary(awing: 'pəlɛ́ə', english: 'people'),
      StoryVocabulary(awing: 'asɨ́ə', english: 'houses'),
      StoryVocabulary(awing: 'mbe\'tə', english: 'shoulder/young person'),
      StoryVocabulary(awing: 'pɛ́nə', english: 'dance'),
      StoryVocabulary(awing: 'akoobɔ́', english: 'forest'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
      StoryVocabulary(awing: 'ngye', english: 'voice'),
      StoryVocabulary(awing: 'nəkəŋɔ́', english: 'pot'),
      StoryVocabulary(awing: 'ayáŋə', english: 'wisdom'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What was in the village?',
        correctAnswer: 'people and houses',
        options: ['people and houses', 'only trees', 'only water'],
      ),
      ComprehensionQuestion(
        question: 'What did the young people do?',
        correctAnswer: 'danced and looked at the forest',
        options: ['danced and looked at the forest', 'worked in the pots', 'ran to the water'],
      ),
      ComprehensionQuestion(
        question: 'What was in the pots?',
        correctAnswer: 'soup and groundnuts',
        options: ['soup and groundnuts', 'water and sand', 'leaves and stones'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'Learning to Heal',
    titleAwing: 'Tsó\'ə ne afûə',
    illustration: '🌿',
    sentences: [
      StorySentence(
        awing: 'Apɛ̌ɛlə ko mǎ yǐə akoobɔ́.',
        english: 'A young person came with mother to the forest.',
      ),
      StorySentence(
        awing: 'Mǎ zó\'ə atîə ne afûə.',
        english: 'Mother heard the trees and the leaves.',
      ),
      StorySentence(
        awing: 'Yə nô ndě pə atîə nyɛ́ə tsó\'ə.',
        english: 'She drank water—the tree is healing.',
      ),
      StorySentence(
        awing: 'Apɛ̌ɛlə pímə afûə nəlwîə ne ndě.',
        english: 'The young person saw the medicine leaf for the nose and water.',
      ),
      StorySentence(
        awing: 'Tsó\'ə pə alá\'ə ne ayáŋə pə mǎ.',
        english: 'Healing came to the village—wisdom from mother.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'tsó\'ə', english: 'heal'),
      StoryVocabulary(awing: 'afûə', english: 'leaf/medicine'),
      StoryVocabulary(awing: 'akoobɔ́', english: 'forest'),
      StoryVocabulary(awing: 'mǎ', english: 'mother'),
      StoryVocabulary(awing: 'atîə', english: 'tree'),
      StoryVocabulary(awing: 'zó\'ə', english: 'hear'),
      StoryVocabulary(awing: 'nô', english: 'drink'),
      StoryVocabulary(awing: 'pímə', english: 'see'),
      StoryVocabulary(awing: 'nəlwîə', english: 'nose'),
      StoryVocabulary(awing: 'ayáŋə', english: 'wisdom'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did they go to learn?',
        correctAnswer: 'to the forest',
        options: ['to the forest', 'to the village', 'to the water'],
      ),
      ComprehensionQuestion(
        question: 'What does the tree provide?',
        correctAnswer: 'healing',
        options: ['healing', 'food', 'homes'],
      ),
      ComprehensionQuestion(
        question: 'Who teaches the young person about healing?',
        correctAnswer: 'Mother',
        options: ['Mother', 'the forest', 'the owl'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Dog and the Chicken',
    titleAwing: 'Ngwûə ne ngɔ́bə',
    illustration: '🐕',
    sentences: [
      StorySentence(
        awing: 'Ngwûə a kə lê ndê.',
        english: 'The dog was sleeping at the house.',
      ),
      StorySentence(
        awing: 'Ngɔ́bə yǐə nchîndê.',
        english: 'The chicken came to the compound.',
      ),
      StorySentence(
        awing: 'Ngɔ́bə a kə jíə ngəsáŋɔ́.',
        english: 'The chicken was eating corn.',
      ),
      StorySentence(
        awing: 'Ngwûə zó\'ə ngɔ́bə.',
        english: 'The dog heard the chicken.',
      ),
      StorySentence(
        awing: 'Yə kə́ərə kə ngɔ́bə.',
        english: 'It ran to the chicken.',
      ),
      StorySentence(
        awing: 'Ngɔ́bə shɔ́ŋə atîə wíŋɔ́!',
        english: 'The chicken climbed a big tree!',
      ),
      StorySentence(
        awing: 'Ngwûə pímə ngɔ́bə atîə.',
        english: 'The dog looked at the chicken in the tree.',
      ),
      StorySentence(
        awing: 'Ngwûə ŋwàŋə ndê, a lê ndèe.',
        english: 'The dog returned home and slept again.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'ngwûə', english: 'dog'),
      StoryVocabulary(awing: 'ngɔ́bə', english: 'chicken'),
      StoryVocabulary(awing: 'lê', english: 'sleep'),
      StoryVocabulary(awing: 'ngəsáŋɔ́', english: 'corn'),
      StoryVocabulary(awing: 'kə́ərə', english: 'run'),
      StoryVocabulary(awing: 'shɔ́ŋə', english: 'climb'),
      StoryVocabulary(awing: 'atîə', english: 'tree'),
      StoryVocabulary(awing: 'ŋwàŋə', english: 'return'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What was the chicken eating?',
        correctAnswer: 'corn',
        options: ['corn', 'beans', 'bananas'],
      ),
      ComprehensionQuestion(
        question: 'Where did the chicken go to escape?',
        correctAnswer: 'A big tree',
        options: ['A big tree', 'The river', 'The farm'],
      ),
      ComprehensionQuestion(
        question: 'What did the dog do at the end?',
        correctAnswer: 'Went home and slept',
        options: ['Went home and slept', 'Caught the chicken', 'Climbed the tree'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Farmer and the Rain',
    titleAwing: 'Tǎ afoonə ne mbəŋə',
    illustration: '🌧️',
    sentences: [
      StorySentence(
        awing: 'Tǎ ghɛnɔ́ afoonə kə̂ŋə.',
        english: 'Father went to the farm early.',
      ),
      StorySentence(
        awing: 'Yə tɔ̀ə ngəsáŋɔ́ ne azó\'ə.',
        english: 'He planted corn and yam.',
      ),
      StorySentence(
        awing: 'Mɔ́numə a kə tɔnɔ́ sagɔ́.',
        english: 'The sun was very hot.',
      ),
      StorySentence(
        awing: 'Yə nô ndě, yə jwítə.',
        english: 'He drank water and rested.',
      ),
      StorySentence(
        awing: 'Aləmə yǐə nəpóolə.',
        english: 'Clouds came in the sky.',
      ),
      StorySentence(
        awing: 'Mbəŋə a kə pə̀ə wíŋɔ́!',
        english: 'The rain fell heavily!',
      ),
      StorySentence(
        awing: 'Tǎ wiŋɔ́, yə sóŋə: "Ashî\'nə sagɔ́!"',
        english: 'Father was happy, he said: "Very good!"',
      ),
      StorySentence(
        awing: 'Mbəŋə ko pə ndě kə afoonə.',
        english: 'The rain brought water to the farm.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'afoonə', english: 'farm'),
      StoryVocabulary(awing: 'tɔ̀ə', english: 'plant'),
      StoryVocabulary(awing: 'mɔ́numə', english: 'sun'),
      StoryVocabulary(awing: 'tɔnɔ́', english: 'hot'),
      StoryVocabulary(awing: 'aləmə', english: 'cloud'),
      StoryVocabulary(awing: 'mbəŋə', english: 'rain'),
      StoryVocabulary(awing: 'wiŋɔ́', english: 'happy/big'),
      StoryVocabulary(awing: 'ashî\'nə', english: 'good'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What did Father plant?',
        correctAnswer: 'Corn and yam',
        options: ['Corn and yam', 'Bananas', 'Cocoyam and beans'],
      ),
      ComprehensionQuestion(
        question: 'What happened when clouds came?',
        correctAnswer: 'It rained heavily',
        options: ['It rained heavily', 'The sun got hotter', 'Father went home'],
      ),
      ComprehensionQuestion(
        question: 'Why was Father happy?',
        correctAnswer: 'Rain watered the farm',
        options: ['Rain watered the farm', 'He found treasure', 'He finished planting'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Child at the Market',
    titleAwing: 'Mɔ́ŋkə kə mətéenɔ́',
    illustration: '🛍️',
    sentences: [
      StorySentence(
        awing: 'Mǎ sóŋə: "Yîə, ghɛnɔ́ mətéenɔ́."',
        english: 'Mother said: "Come, let\'s go to the market."',
      ),
      StorySentence(
        awing: 'Mɔ́ŋkə wiŋɔ́ sagɔ́!',
        english: 'The child was very happy!',
      ),
      StorySentence(
        awing: 'Yə pímə amú\'ɔ́ ne lámɔ́sə.',
        english: 'He saw bananas and oranges.',
      ),
      StorySentence(
        awing: 'Mǎ júnə ngəsáŋɔ́ ne ndzě.',
        english: 'Mother bought corn and vegetables.',
      ),
      StorySentence(
        awing: 'Mɔ́ŋkə kwɨ̌nə: "Mǎ, ko pə amú\'ɔ́!"',
        english: 'The child asked: "Mother, give me a banana!"',
      ),
      StorySentence(
        awing: 'Mǎ fê pə amú\'ɔ́ əmɔ́.',
        english: 'Mother gave him one banana.',
      ),
      StorySentence(
        awing: 'Mɔ́ŋkə jíə, yə sóŋə: "Mbɔ́ɔnɔ́, Mǎ!"',
        english: 'The child ate and said: "Thank you, Mother!"',
      ),
      StorySentence(
        awing: 'Yə ŋwàŋə ndê ne mǎ.',
        english: 'They returned home with Mother.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'mətéenɔ́', english: 'market'),
      StoryVocabulary(awing: 'amú\'ɔ́', english: 'banana'),
      StoryVocabulary(awing: 'lámɔ́sə', english: 'orange'),
      StoryVocabulary(awing: 'júnə', english: 'buy'),
      StoryVocabulary(awing: 'ndzě', english: 'vegetable'),
      StoryVocabulary(awing: 'kwɨ̌nə', english: 'ask'),
      StoryVocabulary(awing: 'Mbɔ́ɔnɔ́', english: 'thank you'),
      StoryVocabulary(awing: 'ŋwàŋə', english: 'return'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did Mother and the child go?',
        correctAnswer: 'The market',
        options: ['The market', 'The farm', 'The school'],
      ),
      ComprehensionQuestion(
        question: 'What did the child ask for?',
        correctAnswer: 'A banana',
        options: ['A banana', 'An orange', 'Corn'],
      ),
      ComprehensionQuestion(
        question: 'What did the child say after eating?',
        correctAnswer: 'Thank you',
        options: ['Thank you', 'More please', 'Goodbye'],
      ),
    ],
  ),
];

/// ============================================================================
/// SCREENS
/// ============================================================================

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Awing Stories'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Stories', icon: Icon(Icons.library_books)),
              Tab(text: 'Vocabulary', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StoryListView(),
            StoryVocabularyView(),
          ],
        ),
      ),
    );
  }
}

class StoryListView extends StatefulWidget {
  const StoryListView({Key? key}) : super(key: key);

  @override
  State<StoryListView> createState() => _StoryListViewState();
}

class _StoryListViewState extends State<StoryListView> {
  late List<AwingStory> _stories = List.from(awingStories);

  void _markStoryComplete(int index) {
    setState(() {
      _stories[index].isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return StoryCard(
          story: story,
          onTap: () async {
            final completed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => StoryViewerScreen(story: story),
              ),
            );
            if (completed == true) {
              _markStoryComplete(index);
            }
          },
        );
      },
    );
  }
}

class StoryCard extends StatelessWidget {
  final AwingStory story;
  final VoidCallback onTap;

  const StoryCard({
    Key? key,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade100,
                Colors.cyan.shade100,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                story.illustration,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.titleEnglish,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.titleAwing,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story.sentences.length} sentences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (story.isCompleted)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.teal,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryViewerScreen extends StatefulWidget {
  final AwingStory story;

  const StoryViewerScreen({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentSentenceIndex = 0;
  bool _showEnglish = false;
  bool _storyCompleted = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
  }

  void _nextSentence() {
    if (_currentSentenceIndex < widget.story.sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _showEnglish = false;
      });
    } else {
      setState(() {
        _storyCompleted = true;
      });
    }
  }

  void _prevSentence() {
    if (_currentSentenceIndex > 0) {
      setState(() {
        _currentSentenceIndex--;
        _showEnglish = false;
      });
    }
  }

  void _speakSentence() {
    final sentence = widget.story.sentences[_currentSentenceIndex];
    _pronunciation.speakAwing(sentence.awing);
  }

  @override
  Widget build(BuildContext context) {
    if (_storyCompleted) {
      return StoryQuizScreen(
        story: widget.story,
        onComplete: () {
          Navigator.pop(context, true);
        },
      );
    }

    final sentence = widget.story.sentences[_currentSentenceIndex];
    final progress = (_currentSentenceIndex + 1) / widget.story.sentences.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.titleEnglish),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Large illustration area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.story.illustration,
                  style: const TextStyle(fontSize: 96),
                  textAlign: TextAlign.center,
                ),
              ),
              // Sentence card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.cyan.shade50],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Awing sentence (always visible)
                            Text(
                              sentence.awing,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // English translation (tap to reveal)
                            if (_showEnglish)
                              Text(
                                sentence.english,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.teal,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              Text(
                                'Tap to reveal English',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 32),
                            // Speaker button
                            FloatingActionButton(
                              onPressed: _speakSentence,
                              backgroundColor: Colors.teal,
                              child: const Icon(Icons.volume_up),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Progress dots
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.story.sentences.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _currentSentenceIndex
                            ? Colors.teal
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentSentenceIndex > 0 ? _prevSentence : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showEnglish = !_showEnglish);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                      ),
                      child: Text(
                        _showEnglish ? 'Hide English' : 'Show English',
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _nextSentence,
                      label: const Text('Next'),
                      icon: const Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pronunciation.dispose();
    super.dispose();
  }
}

class StoryQuizScreen extends StatefulWidget {
  final AwingStory story;
  final VoidCallback onComplete;

  const StoryQuizScreen({
    Key? key,
    required this.story,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  bool _quizCompleted = false;

  void _selectAnswer(String answer) {
    if (_answered) return;

    final isCorrect = answer == widget.story.questions[_currentQuestion].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.story.questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Complete!'),
          backgroundColor: Colors.teal,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade50,
                Colors.cyan.shade50,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 24),
                Text(
                  'Great Job!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You scored $_score/${widget.story.questions.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = widget.story.questions[_currentQuestion];
    final isCorrect = _selectedAnswer == question.correctAnswer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Quiz'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentQuestion + 1}/${widget.story.questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 32),
                ...question.options.map((option) {
                  final isSelected = _selectedAnswer == option;
                  final showCorrect = _answered && option == question.correctAnswer;
                  final showIncorrect = _answered && isSelected && !isCorrect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: _answered ? null : () => _selectAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answered
                            ? showCorrect
                                ? Colors.green
                                : showIncorrect
                                    ? Colors.red
                                    : Colors.grey.shade300
                            : Colors.white,
                        foregroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.black54,
                        side: BorderSide(
                          color: isSelected ? Colors.teal : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                if (_answered)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCorrect ? 'Correct!' : 'Not quite right.',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _nextQuestion,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            _currentQuestion < widget.story.questions.length - 1
                                ? 'Next Question'
                                : 'Finish',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StoryVocabularyView extends StatelessWidget {
  const StoryVocabularyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Collect all vocabulary from all stories
    final allVocab = <String, String>{};
    for (final story in awingStories) {
      for (final vocab in story.vocabulary) {
        allVocab[vocab.awing] = vocab.english;
      }
    }

    final vocabList = allVocab.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vocabList.length,
      itemBuilder: (context, index) {
        final entry = vocabList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.cyan.shade50, Colors.teal.shade50],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    PronunciationService().speakAwing(entry.key);
                  },
                  icon: const Icon(Icons.volume_up),
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
