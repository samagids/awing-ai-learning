import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Fill-in-the-blank sentence quiz for Medium level.
/// Shows an Awing sentence with one word replaced by _____.
/// Student picks the missing word from 4 choices.
/// 10 sentences per quiz, multiple quizzes available.

class _SentenceTemplate {
  final String fullSentence;
  final String english;
  final String blankWord; // the word removed
  final int blankIndex; // word position (0-based) in split sentence

  const _SentenceTemplate({
    required this.fullSentence,
    required this.english,
    required this.blankWord,
    required this.blankIndex,
  });

  String get sentenceWithBlank {
    final words = fullSentence.split(' ');
    words[blankIndex] = '_____';
    return words.join(' ');
  }
}

// Sentences sourced from AwingOrthography2005.pdf and conversation data
final List<_SentenceTemplate> _allSentences = [
  // From orthography PDF p.9-12
  _SentenceTemplate(
    fullSentence: 'A kə ghɛnɔ\u0301 mə\u0301te\u0301enɔ\u0301.',
    english: 'He went to the market.',
    blankWord: 'ghɛnɔ\u0301',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Lɛ\u030C nəpɔ\u0027ɔ\u0301.',
    english: 'This is a pumpkin.',
    blankWord: 'nəpɔ\u0027ɔ\u0301.',
    blankIndex: 1,
  ),
  _SentenceTemplate(
    fullSentence: 'Mo\u0301onə a tə nonnɔ\u0301 a əkwunɔ\u0301.',
    english: 'The baby is lying on the bed.',
    blankWord: 'Mo\u0301onə',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'A ghɛlɔ\u0301 lə ake\u0301?',
    english: 'What is he doing?',
    blankWord: 'ghɛlɔ\u0301',
    blankIndex: 1,
  ),
  _SentenceTemplate(
    fullSentence: 'Po zi\u0301 no\u0301olə.',
    english: 'They have seen a snake.',
    blankWord: 'no\u0301olə.',
    blankIndex: 2,
  ),
  // Vocabulary-based sentences using common words
  _SentenceTemplate(
    fullSentence: 'A kə ko apo\u0302 a nto\u0302.',
    english: 'He put his hand on the head.',
    blankWord: 'apo\u0302',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Ma\u030C wə nə mə kwa\u0301tə.',
    english: 'My mother is fine.',
    blankWord: 'Ma\u030C',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Ko akwe pə nəgoomɔ\u0301.',
    english: 'Give me some plantain please.',
    blankWord: 'nəgoomɔ\u0301.',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Ache fɛ\u0301ə ndo?',
    english: 'What is this thing?',
    blankWord: 'Ache',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Gho\u030C ghɛnɔ\u0301 lə əfo\u0301?',
    english: 'Where are you going?',
    blankWord: 'əfo\u0301?',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Tifwə nə pə zə wa\u030C lɛ\u0301ə.',
    english: 'I will go now.',
    blankWord: 'Tifwə',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Wə yi\u030Cə nde\u0300e.',
    english: 'Come back please.',
    blankWord: 'yi\u030Cə',
    blankIndex: 1,
  ),
  _SentenceTemplate(
    fullSentence: 'Ee wə nə mə fɛ\u0301ə.',
    english: 'It is there.',
    blankWord: 'fɛ\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə yi\u030Cə a nchi\u0301ə.',
    english: 'He came to the house.',
    blankWord: 'nchi\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Nde\u0300e, ma\u030C wə nə mə kwa\u0301tə.',
    english: 'Well, mother is fine.',
    blankWord: 'Nde\u0300e,',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Po ma ngyi\u030Cə lə əfe\u0302.',
    english: 'They are not coming here.',
    blankWord: 'ngyi\u030Cə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Kə pinkɔ\u0301 so\u0301ŋə!',
    english: "Don't mention it again!",
    blankWord: 'pinkɔ\u0301',
    blankIndex: 1,
  ),
  _SentenceTemplate(
    fullSentence: 'Lɔ\u0301 anuə: Ta\u0301ta akɛ\u030C nde\u0301 chi\u0301ə po\u0301.',
    english: 'It is true: Tata is not in the house.',
    blankWord: 'chi\u0301ə',
    blankIndex: 5,
  ),
  _SentenceTemplate(
    fullSentence: 'A ghɛlɔ\u0301 nəfa\u0301ŋə a mə\u0301te\u0301enɔ\u0301.',
    english: 'He is selling things at the market.',
    blankWord: 'nəfa\u0301ŋə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Mba\u0301\u0027chi a tə ko\u0301\u0027ə ati\u030Cə.',
    english: 'Mbachia is climbing a tree.',
    blankWord: 'ati\u030Cə.',
    blankIndex: 4,
  ),
  // More sentences from vocabulary context
  _SentenceTemplate(
    fullSentence: 'A kə ko nkwi\u0301ə a nde\u0301.',
    english: 'He fetched water from the river.',
    blankWord: 'nkwi\u0301ə',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə nya\u0301ŋə əfua\u0301.',
    english: 'He cooked food.',
    blankWord: 'əfua\u0301.',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Mo\u0301onə a tə no\u0301nɔ.',
    english: 'The child is sleeping.',
    blankWord: 'no\u0301nɔ.',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə zo nchi\u0301ə.',
    english: 'He built a house.',
    blankWord: 'zo',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Ta\u0301ta a tə a nchi\u0301ə.',
    english: 'Father is at home.',
    blankWord: 'Ta\u0301ta',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə tuə ŋku\u0301.',
    english: 'He bought clothes.',
    blankWord: 'ŋku\u0301.',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Apo\u0302 a tə nə mə ti\u0301ə.',
    english: 'The hand is on the tree.',
    blankWord: 'ti\u0301ə.',
    blankIndex: 5,
  ),
  _SentenceTemplate(
    fullSentence: 'A tə ghɛnɔ\u0301 a əshu\u0301ə.',
    english: 'He is going to school.',
    blankWord: 'əshu\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Fwa\u0301 a tə tuə a mə\u0301te\u0301enɔ\u0301.',
    english: 'The chief is buying at the market.',
    blankWord: 'Fwa\u0301',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə la\u0301 nge\u0301ŋə nə əso\u0301ŋə.',
    english: 'He sang a song with joy.',
    blankWord: 'nge\u0301ŋə',
    blankIndex: 3,
  ),
  // Expanded pool (30 additional sentences) — faithful recombinations of
  // vocabulary already present in the verified 30 above. No new Awing
  // coinages introduced. Themes: family, food, daily life, nature, school.
  _SentenceTemplate(
    fullSentence: 'Ma\u030C a tə nya\u0301ŋə əfua\u0301.',
    english: 'Mother is cooking food.',
    blankWord: 'nya\u0301ŋə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Ta\u0301ta a kə ghɛnɔ\u0301 a nkwi\u0301ə.',
    english: 'Father went to the river.',
    blankWord: 'nkwi\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Mo\u0301onə a tə la\u0301 nge\u0301ŋə.',
    english: 'The child is singing a song.',
    blankWord: 'la\u0301',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə tuə əfua\u0301 a mə\u0301te\u0301enɔ\u0301.',
    english: 'He bought food at the market.',
    blankWord: 'tuə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Fwa\u0301 a tə nonnɔ\u0301 a əkwunɔ\u0301.',
    english: 'The chief is lying on the bed.',
    blankWord: 'əkwunɔ\u0301.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Po kə zo nchi\u0301ə a nde\u0301.',
    english: 'They built a house at the river.',
    blankWord: 'zo',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Gho\u030C kə zi\u0301 Fwa\u0301?',
    english: 'Did you see the chief?',
    blankWord: 'zi\u0301',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'A tə ko\u0301\u0027ə ati\u030Cə fɛ\u0301ə.',
    english: 'He is climbing the tree there.',
    blankWord: 'ko\u0301\u0027ə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Ma\u030C a kə tuə ŋku\u0301 a mə\u0301te\u0301enɔ\u0301.',
    english: 'Mother bought clothes at the market.',
    blankWord: 'ŋku\u0301',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Mba\u0301\u0027chi a tə ghɛnɔ\u0301 a əshu\u0301ə.',
    english: 'Mbachia is going to school.',
    blankWord: 'əshu\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə ko apo\u0302 a ati\u030Cə.',
    english: 'He put his hand on the tree.',
    blankWord: 'apo\u0302',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Mo\u0301onə a tə yi\u030Cə a nchi\u0301ə.',
    english: 'The child is coming to the house.',
    blankWord: 'yi\u030Cə',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Po kə zi\u0301 no\u0301olə a nde\u0301.',
    english: 'They saw a snake at the river.',
    blankWord: 'no\u0301olə',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A ghɛlɔ\u0301 nəfa\u0301ŋə a nchi\u0301ə.',
    english: 'He is selling things in the house.',
    blankWord: 'nchi\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Ta\u0301ta a kə tuə nəpɔ\u0027ɔ\u0301 a mə\u0301te\u0301enɔ\u0301.',
    english: 'Father bought a pumpkin at the market.',
    blankWord: 'nəpɔ\u0027ɔ\u0301',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Ma\u030C a tə la\u0301 nge\u0301ŋə a nchi\u0301ə.',
    english: 'Mother is singing a song at home.',
    blankWord: 'nge\u0301ŋə',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə nya\u0301ŋə əfua\u0301 nə əso\u0301ŋə.',
    english: 'He cooked food with joy.',
    blankWord: 'əso\u0301ŋə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Gho\u030C tə ghɛlɔ\u0301 ake\u0301 a əshu\u0301ə?',
    english: 'What are you doing at school?',
    blankWord: 'ake\u0301',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Po kə ghɛnɔ\u0301 a mə\u0301te\u0301enɔ\u0301 tuə əfua\u0301.',
    english: 'They went to the market to buy food.',
    blankWord: 'mə\u0301te\u0301enɔ\u0301',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Fwa\u0301 a tə nə mə nchi\u0301ə.',
    english: 'The chief is at the house.',
    blankWord: 'Fwa\u0301',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Ma\u030C a kə ko nkwi\u0301ə a mo\u0301onə.',
    english: 'Mother gave water to the child.',
    blankWord: 'nkwi\u0301ə',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə yi\u030Cə nde\u0300e lə əfe\u0302.',
    english: 'He came back here.',
    blankWord: 'əfe\u0302.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Ta\u0301ta a tə zo nchi\u0301ə nə\u0301 mo\u0301onə.',
    english: 'Father is building a house with the child.',
    blankWord: 'zo',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'Mba\u0301\u0027chi a kə ko\u0301\u0027ə ati\u030Cə a nchi\u0301ə.',
    english: 'Mbachia climbed a tree at the house.',
    blankWord: 'Mba\u0301\u0027chi',
    blankIndex: 0,
  ),
  _SentenceTemplate(
    fullSentence: 'Mo\u0301onə a tə no\u0301nɔ a əkwunɔ\u0301.',
    english: 'The child is sleeping on the bed.',
    blankWord: 'no\u0301nɔ',
    blankIndex: 2,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə la\u0301 nge\u0301ŋə a əshu\u0301ə.',
    english: 'He sang a song at school.',
    blankWord: 'əshu\u0301ə.',
    blankIndex: 4,
  ),
  _SentenceTemplate(
    fullSentence: 'Po ma yi\u030Cə lə əfe\u0302, po ghɛnɔ\u0301 lə nkwi\u0301ə.',
    english: 'They are not coming here, they are going to the river.',
    blankWord: 'ghɛnɔ\u0301',
    blankIndex: 5,
  ),
  _SentenceTemplate(
    fullSentence: 'Ache fɛ\u0301ə a ati\u030Cə?',
    english: 'What is there on the tree?',
    blankWord: 'ati\u030Cə?',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'Ma\u030C a kə ko əfua\u0301 a mo\u0301onə.',
    english: 'Mother gave food to the child.',
    blankWord: 'əfua\u0301',
    blankIndex: 3,
  ),
  _SentenceTemplate(
    fullSentence: 'A kə zi\u0301 Fwa\u0301 a mə\u0301te\u0301enɔ\u0301.',
    english: 'He saw the chief at the market.',
    blankWord: 'Fwa\u0301',
    blankIndex: 2,
  ),
];

class WritingQuizScreen extends StatefulWidget {
  const WritingQuizScreen({Key? key}) : super(key: key);

  @override
  State<WritingQuizScreen> createState() => _WritingQuizScreenState();
}

class _WritingQuizScreenState extends State<WritingQuizScreen> {
  final _random = Random();
  final PronunciationService _pronunciation = PronunciationService();
  late List<_SentenceTemplate> _quizSentences;
  late List<List<String>> _allChoices;
  int _currentQuestion = 0;
  int _score = 0;
  int _totalAnswered = 0;
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _generateQuiz();
  }

  void _generateQuiz() {
    final pool = List<_SentenceTemplate>.from(_allSentences)..shuffle(_random);
    _quizSentences = pool.take(10).toList();
    _allChoices = _quizSentences.map((s) => _generateChoices(s)).toList();
  }

  List<String> _generateChoices(_SentenceTemplate sentence) {
    // Get 3 wrong answers from other sentences' blank words
    final otherBlanks = _allSentences
        .where((s) => s.blankWord != sentence.blankWord)
        .map((s) => s.blankWord)
        .toSet()
        .toList()
      ..shuffle(_random);

    final choices = <String>{sentence.blankWord};
    for (final blank in otherBlanks) {
      if (choices.length >= 4) break;
      choices.add(blank);
    }
    // If still not enough, add random vocabulary words
    if (choices.length < 4) {
      final vocab = allVocabulary.toList()..shuffle(_random);
      for (final w in vocab) {
        if (choices.length >= 4) break;
        choices.add(w.awing);
      }
    }
    final result = choices.toList()..shuffle(_random);
    return result;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _totalAnswered++;
      if (answer == _quizSentences[_currentQuestion].blankWord) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 >= _quizSentences.length) {
      _showResults();
      return;
    }
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _generateQuiz();
      _currentQuestion = 0;
      _score = 0;
      _totalAnswered = 0;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  void _showResults() {
    final percentage = (_score / _totalAnswered * 100).round();
    String message;
    String celebration;
    if (percentage >= 80) {
      message = 'Amazing! You understand Awing sentences!';
      celebration = '\u{1F31F}';
    } else if (percentage >= 60) {
      message = 'Good effort! Keep studying!';
      celebration = '\u{1F44D}';
    } else {
      message = 'Keep practicing! Read the sentences again!';
      celebration = '\u{1F4AA}';
    }

    AnalyticsService.instance.logQuiz(
      quizType: 'writing_quiz',
      level: 'medium',
      scorePercent: percentage,
      correct: _score,
      total: _totalAnswered,
    );

    context.read<AuthService>().saveQuizScore('medium_writing_quiz', percentage);

    final parentService = context.read<ParentNotificationService>();
    final childName = context.read<AuthService>().currentProfile?.displayName ?? 'Your child';
    parentService.notifyQuizCompleted(
      childName: childName,
      quizName: 'Fill-in-the-Blank Quiz',
      score: percentage,
      totalQuestions: _totalAnswered,
      correctAnswers: _score,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$celebration Quiz Complete!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score / $_totalAnswered',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% correct',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restart();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _quizSentences[_currentQuestion];
    final choices = _allChoices[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text('Fill in the Blank \u2014 $_score / $_totalAnswered'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress + best score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sentence ${_currentQuestion + 1} of ${_quizSentences.length}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Row(
                  children: [
                    Builder(builder: (ctx) {
                      final best = ctx.watch<AuthService>().currentProfile?.quizBestScores['medium_writing_quiz'] ?? 0;
                      if (best == 0) return const SizedBox.shrink();
                      final passed = best >= 90;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: passed ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (passed)
                              const Icon(Icons.check_circle, color: Colors.green, size: 14),
                            if (passed) const SizedBox(width: 4),
                            Text(
                              'Best: $best%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: passed ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: $_score/$_totalAnswered',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / _quizSentences.length,
                minHeight: 8,
                backgroundColor: Colors.orange.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 24),

            // English translation hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.translate, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      current.english,
                      style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sentence with blank
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fill in the missing word:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      current.sentenceWithBlank,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pronunciation.speakAwing(current.fullSentence),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up, color: const Color(0xFFDAA520), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Hear full sentence',
                            style: TextStyle(color: const Color(0xFFDAA520), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If answered, show correct sentence
            if (_answered)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        current.fullSentence,
                        style: TextStyle(fontSize: 16, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Answer choices
            ...choices.map((choice) {
              final isCorrect = choice == current.blankWord;
              final isSelected = _selectedAnswer == choice;
              final isWrong = isSelected && !isCorrect;

              Color bgColor = Colors.white;
              Color borderColor = Colors.orange.shade300;
              Color textColor = Colors.black;

              if (isSelected && isCorrect) {
                bgColor = Colors.green.shade50;
                borderColor = Colors.green;
                textColor = Colors.green.shade900;
              } else if (isWrong) {
                bgColor = Colors.red.shade50;
                borderColor = Colors.red;
                textColor = Colors.red.shade900;
              } else if (_answered && isCorrect) {
                bgColor = Colors.green.shade50;
                borderColor = Colors.green;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _answered ? null : () => _selectAnswer(choice),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              choice,
                              style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          if (_answered && !isSelected && isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Next button
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentQuestion + 1 >= _quizSentences.length ? 'See Results' : 'Next Sentence',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
