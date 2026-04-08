import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/data/awing_alphabet.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

class ExpertQuizScreen extends StatefulWidget {
  const ExpertQuizScreen({Key? key}) : super(key: key);

  @override
  State<ExpertQuizScreen> createState() => _ExpertQuizScreenState();
}

class _ExpertQuizScreenState extends State<ExpertQuizScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  final _random = Random();
  late List<Map<String, dynamic>> _quizQuestions;
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
    try {
      _quizQuestions = [
        ..._generateVocabularyQuestions(5),
        ..._generateToneQuestions(4),
        ..._generateSpellingQuestions(4),
        ..._generateGrammarQuestions(4),
        ..._generateSentenceQuestions(3),
      ];
    } catch (e) {
      // Fallback: at least have sentence questions which are hardcoded
      _quizQuestions = _generateSentenceQuestions(3);
    }
    if (_quizQuestions.isEmpty) {
      _quizQuestions = _generateSentenceQuestions(3);
    }
    _quizQuestions.shuffle(_random);
    _allChoices = _quizQuestions
        .map((q) {
          final correct = q['correctAnswer'] as String;
          final all = (q['allAnswers'] as List).cast<String>();
          return _generateChoices(correct, all);
        })
        .toList();
  }

  List<Map<String, dynamic>> _generateVocabularyQuestions(int count) {
    final vocab = List.from(allVocabulary)..shuffle(_random);
    return vocab.take(count).map((word) {
      final wrongAnswers = allVocabulary
          .where((w) => w.english != word.english)
          .toList()
        ..shuffle(_random);
      return {
        'type': 'vocabulary',
        'question': 'What does "${word.awing}" mean?',
        'word': word.awing,
        'correctAnswer': word.english,
        'allAnswers': [word.english, ...wrongAnswers.take(3).map((w) => w.english)],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _generateToneQuestions(int count) {
    final pairs = List.from(toneMinimalPairs)..shuffle(_random);
    final questions = <Map<String, dynamic>>[];

    for (final pair in pairs.take(count)) {
      final words = [
        {'word': pair.word1, 'tone': pair.tone1},
        {'word': pair.word2, 'tone': pair.tone2},
      ];
      if (pair.word3 != null) {
        words.add({'word': pair.word3, 'tone': pair.tone3 ?? 'Mid'});
      }

      for (final item in words) {
        // Capitalize tone name to match answer choices
        final toneName = (item['tone'] as String);
        final capitalizedTone = toneName[0].toUpperCase() + toneName.substring(1).toLowerCase();
        questions.add({
          'type': 'tone',
          'question': 'What tone is on "${item['word']}"?',
          'word': item['word'],
          'correctAnswer': capitalizedTone,
          'allAnswers': ['High', 'Mid', 'Low', 'Rising', 'Falling'],
        });
        if (questions.length >= count) break;
      }
      if (questions.length >= count) break;
    }

    return questions;
  }

  List<Map<String, dynamic>> _generateSpellingQuestions(int count) {
    // Only pick words that contain special Awing characters (ɔ, ə, ɛ, ɨ)
    // so the wrong answers are actually different from the correct one
    final specialCharWords = allVocabulary.where((w) =>
        w.awing.contains('ɔ') || w.awing.contains('ə') ||
        w.awing.contains('ɛ') || w.awing.contains('ɨ')).toList();
    specialCharWords.shuffle(_random);

    // Fallback: if not enough special-char words, use all vocabulary
    final source = specialCharWords.length >= count ? specialCharWords : (List.from(allVocabulary)..shuffle(_random));

    return source.take(count).map((word) {
      final wrongSet = <String>{};
      if (word.awing.contains('ɔ')) wrongSet.add(word.awing.replaceAll('ɔ', 'o'));
      if (word.awing.contains('ə')) wrongSet.add(word.awing.replaceAll('ə', 'e'));
      if (word.awing.contains('ɛ')) wrongSet.add(word.awing.replaceAll('ɛ', 'e'));
      if (word.awing.contains('ɨ')) wrongSet.add(word.awing.replaceAll('ɨ', 'i'));
      wrongSet.remove(word.awing); // remove if replacement didn't change anything

      // If still not enough wrong answers, pick other words from same category
      if (wrongSet.length < 3) {
        final otherWords = allVocabulary
            .where((w) => w.english != word.english)
            .toList()..shuffle(_random);
        for (final other in otherWords) {
          wrongSet.add(other.awing);
          if (wrongSet.length >= 3) break;
        }
      }

      return {
        'type': 'spelling',
        'question': 'Which spelling is correct for "${word.english}"?',
        'correctAnswer': word.awing,
        'allAnswers': [word.awing, ...wrongSet.take(3)],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _generateGrammarQuestions(int count) {
    final questions = <Map<String, dynamic>>[];

    // Only use noun classes with real plural forms (skip '--')
    for (final nc in nounClasses.where((nc) => nc.pluralExample != '--')) {
      questions.add({
        'type': 'grammar',
        'question':
            'What is the plural of "${nc.singularExample}" (${nc.english.split('/')[0]})?',
        'correctAnswer': nc.pluralExample,
        'allAnswers': [
          nc.pluralExample,
          'p${nc.singularExample}',
          'm${nc.singularExample}',
          'ə${nc.singularExample}',
        ],
      });
    }

    // Add more grammar-based questions
    questions.add({
      'type': 'grammar',
      'question': 'Which word means both "hello" and "goodbye"?',
      'correctAnswer': "Cha'tɔ́",
      'allAnswers': ["Cha'tɔ́", 'Ndèe', 'Ee', 'Wo\''],
    });

    questions.add({
      'type': 'grammar',
      'question': 'What is the short form of "apeemə"?',
      'correctAnswer': 'apa',
      'allAnswers': ['apa', 'apem', 'ape', 'apeem'],
    });

    questions.add({
      'type': 'grammar',
      'question': 'What is the short form of "apéenə"?',
      'correctAnswer': 'apá',
      'allAnswers': ['apá', 'apeen', 'apen', 'ape'],
    });

    questions.add({
      'type': 'grammar',
      'question': 'Which is a prenasalized consonant cluster?',
      'correctAnswer': 'Mb',
      'allAnswers': ['Mb', 'Ty', 'Kw', 'Gh'],
    });

    questions.shuffle(_random);
    return questions.take(count).toList();
  }

  List<Map<String, dynamic>> _generateSentenceQuestions(int count) {
    return [
      {
        'type': 'sentence',
        'question': 'How would you say "Come back, please" in Awing?',
        'correctAnswer': 'Wə yîə ndèe',
        'allAnswers': ['Wə yîə ndèe', 'Yə yîə ndèe', 'Ko yîə ndèe', 'Pə yîə ndèe'],
      },
      {
        'type': 'sentence',
        'question': 'What does "Tifwə nə pə zə wǎ lɛ́ə" mean?',
        'correctAnswer': 'I will go now',
        'allAnswers': ['I will go now', 'Come back please', 'Are you coming?', 'I am well'],
      },
      {
        'type': 'sentence',
        'question': 'Which response is appropriate for "Cha\'tɔ́!"?',
        'correctAnswer': "Cha'tɔ́! Yə yîə?",
        'allAnswers': ["Cha'tɔ́! Yə yîə?", "Ko pə asé", "Ache fɛ́ə ndo?", "Akwe?"],
      },
    ].take(count).toList();
  }

  List<String> _generateChoices(String correct, List<String> allAnswers) {
    final answers = [...allAnswers].toSet().toList();
    if (!answers.contains(correct)) {
      answers.add(correct);
    }
    answers.shuffle(_random);
    return answers;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _totalAnswered++;

      if (answer == _quizQuestions[_currentQuestion]['correctAnswer']) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 >= _quizQuestions.length) {
      _showResults();
      return;
    }

    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  void _showResults() {
    final percentage = (_score / _totalAnswered * 100).round();

    AnalyticsService.instance.logQuiz(
      quizType: 'expert_quiz',
      level: 'expert',
      scorePercent: percentage,
      correct: _score,
      total: _totalAnswered,
    );

    context.read<AuthService>().completeLesson('expert_quiz');
    context.read<AuthService>().saveQuizScore('expert_quiz', percentage);

    // Notify parent via WhatsApp
    final parentService = context.read<ParentNotificationService>();
    final childName = context.read<AuthService>().currentProfile?.displayName ?? 'Your child';
    parentService.notifyQuizCompleted(
      childName: childName,
      quizName: 'Expert Challenge Quiz',
      score: percentage,
      totalQuestions: _totalAnswered,
      correctAnswers: _score,
    );

    String message;
    String emoji = '🌟';

    if (percentage >= 90) {
      message = 'You are an Awing master! Incredible achievement!';
      emoji = '👑';
    } else if (percentage >= 80) {
      message = 'Excellent work! You know Awing very well!';
      emoji = '🌟';
    } else if (percentage >= 70) {
      message = 'Great job! You are becoming an expert!';
      emoji = '👍';
    } else if (percentage >= 60) {
      message = 'Good effort! Keep studying and practicing!';
      emoji = '💪';
    } else {
      message = 'Keep practicing! You will get better!';
      emoji = '🚀';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score / $_totalAnswered',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(fontSize: 32, color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generateQuiz();
                _currentQuestion = 0;
                _score = 0;
                _totalAnswered = 0;
                _selectedAnswer = null;
                _answered = false;
              });
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _quizQuestions[_currentQuestion];
    final choices = _allChoices[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Quiz'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress
              Text(
                'Question ${_currentQuestion + 1} of ${_quizQuestions.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentQuestion + 1) / _quizQuestions.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(Colors.red.shade500),
                ),
              ),
              const SizedBox(height: 16),

              // Question type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question['type'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question
              Card(
                color: Colors.red.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['question'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                      ),
                      if (question['word'] != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _answered ? null : () => _pronunciation.speakAwing(question['word']),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Hear it'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Answer choices
              ...choices.map((choice) {
                final isSelected = _selectedAnswer == choice;
                final isCorrect = choice == question['correctAnswer'];
                final isWrong = isSelected && !isCorrect;

                Color bgColor = Colors.grey.shade100;
                Color textColor = Colors.black;
                Color borderColor = Colors.transparent;
                double borderWidth = 0;

                if (isWrong) {
                  bgColor = Colors.red.shade200;
                  textColor = Colors.red.shade900;
                  borderColor = Colors.red;
                  borderWidth = 2;
                } else if (_answered && isCorrect) {
                  bgColor = Colors.green.shade300;
                  textColor = Colors.green.shade900;
                  borderColor = Colors.green;
                  borderWidth = 2;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectAnswer(choice),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: borderWidth),
                        ),
                        child: Row(
                          children: [
                            if (_answered && isCorrect)
                              Icon(Icons.check_circle, color: Colors.green.shade900)
                            else if (isWrong)
                              Icon(Icons.cancel, color: Colors.red.shade900)
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                choice,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Score display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Score',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_score / $_totalAnswered',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _totalAnswered > 0
                          ? '${(_score / _totalAnswered * 100).round()}%'
                          : '0%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
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
}
