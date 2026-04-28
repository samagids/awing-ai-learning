import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Quiz selector — 20 quizzes, each with 20 multiple-choice questions.
/// Word selection and answer choices are freshly randomized on every
/// attempt so kids can't memorize a pattern — they have to actually learn.
class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedQuiz; // null = show selector, 0-9 = taking quiz

  @override
  Widget build(BuildContext context) {
    if (_selectedQuiz != null) {
      return _QuizPlay(
        quizNumber: _selectedQuiz!,
        onBack: () => setState(() => _selectedQuiz = null),
      );
    }
    return _QuizSelector(
      onSelect: (n) => setState(() => _selectedQuiz = n),
    );
  }
}

// ─── Quiz selector grid ──────────────────────────────────────

class _QuizSelector extends StatelessWidget {
  final ValueChanged<int> onSelect;
  const _QuizSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final scores = auth.currentProfile?.quizBestScores ?? {};
    final passedCount = List.generate(20, (i) => scores['beginner_quiz_${i + 1}'] ?? 0)
        .where((s) => s >= 90)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beginner Quiz'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a quiz:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Each quiz has 20 questions. Score 90%+ to pass!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (passedCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$passedCount of 20 quizzes passed',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                final colors = [
                  Colors.green.shade300,
                  Colors.green.shade400,
                  Colors.teal.shade300,
                  Colors.teal.shade400,
                  Colors.green.shade500,
                  Colors.green.shade600,
                  Colors.teal.shade500,
                  Colors.teal.shade600,
                  Colors.green.shade700,
                  Colors.green.shade800,
                  Colors.lightGreen.shade400,
                  Colors.lightGreen.shade500,
                  Colors.cyan.shade400,
                  Colors.cyan.shade500,
                  Colors.lightGreen.shade600,
                  Colors.lightGreen.shade700,
                  Colors.cyan.shade600,
                  Colors.cyan.shade700,
                  Colors.teal.shade700,
                  Colors.teal.shade800,
                ];
                final bestScore = scores['beginner_quiz_${index + 1}'] ?? 0;
                return _QuizCard(
                  number: index + 1,
                  color: colors[index],
                  bestScore: bestScore,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final int number;
  final Color color;
  final int bestScore;
  final VoidCallback onTap;

  const _QuizCard({
    required this.number,
    required this.color,
    required this.onTap,
    this.bestScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    final passed = bestScore >= 90;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withAlpha(200), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Checkmark badge for passed quizzes
              if (passed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Quiz $number',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '20 questions',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    if (bestScore > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: passed
                              ? Colors.white.withAlpha(200)
                              : Colors.white.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Best: $bestScore%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: passed
                                ? Colors.green.shade800
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
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

// ─── Quiz play screen ────────────────────────────────────────

class _QuizPlay extends StatefulWidget {
  final int quizNumber;
  final VoidCallback onBack;
  const _QuizPlay({required this.quizNumber, required this.onBack});

  @override
  State<_QuizPlay> createState() => _QuizPlayState();
}

class _QuizPlayState extends State<_QuizPlay> {
  late final Random _random;
  final PronunciationService _pronunciation = PronunciationService();
  late List<AwingWord> _quizWords;
  late List<List<String>> _allChoices;
  int _currentQuestion = 0;
  int _score = 0;
  int _totalAnswered = 0;
  String? _selectedAnswer;
  bool _answered = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _generateQuiz();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateQuiz() {
    // Fresh randomness every attempt — no pattern for kids to memorize.
    // Each time the child opens quiz N, they see a different random set of
    // 20 words drawn from the beginner pool, with fresh answer choices.
    _random = Random();

    // Only use beginner-level vocabulary (difficulty == 1)
    final beginnerWords = allVocabulary.where((w) => w.difficulty == 1).toList();
    beginnerWords.shuffle(_random);

    // Fresh random slice of 20 words — different set every attempt.
    _quizWords = beginnerWords.take(20).toList();
    _allChoices = _quizWords.map((w) => _generateChoices(w)).toList();
  }

  List<String> _generateChoices(AwingWord correct) {
    final beginnerWords = allVocabulary.where((w) => w.difficulty == 1).toList();
    final others = beginnerWords
        .where((w) => w.english != correct.english)
        .toList()
      ..shuffle(_random);
    final choices = [
      correct.english,
      ...others.take(3).map((w) => w.english),
    ]..shuffle(_random);
    return choices;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _totalAnswered++;
      final word = _quizWords[_currentQuestion];
      final isCorrect = answer == word.english;
      if (isCorrect) {
        _score++;
        Provider.of<ProgressService>(context, listen: false)
            .recordSpacedRepetitionAnswer(word.awing, true);
      } else {
        Provider.of<ProgressService>(context, listen: false)
            .recordSpacedRepetitionAnswer(word.awing, false);
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 >= _quizWords.length) {
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
    String message;
    String emoji;
    if (percentage >= 80) {
      message = 'Amazing! You are a fast learner!';
      emoji = '\u{1F31F}';
      _confettiController.play();
    } else if (percentage >= 60) {
      message = 'Good job! Keep practicing!';
      emoji = '\u{1F44D}';
    } else {
      message = 'Keep going! Practice makes perfect!';
      emoji = '\u{1F4AA}';
    }

    context.read<AuthService>().saveQuizScore('beginner_quiz_${widget.quizNumber + 1}', percentage);

    AnalyticsService.instance.logQuiz(
      quizType: 'beginner_quiz_${widget.quizNumber + 1}',
      level: 'beginner',
      scorePercent: percentage,
      correct: _score,
      total: _totalAnswered,
    );

    final parentService = context.read<ParentNotificationService>();
    final childName = context.read<AuthService>().currentProfile?.displayName ?? 'Your child';
    parentService.notifyQuizCompleted(
      childName: childName,
      quizName: 'Beginner Quiz ${widget.quizNumber + 1}',
      score: percentage,
      totalQuestions: _totalAnswered,
      correctAnswers: _score,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$emoji Quiz ${widget.quizNumber + 1} Complete!', textAlign: TextAlign.center),
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
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _generateQuiz();
                _currentQuestion = 0;
                _score = 0;
                _totalAnswered = 0;
                _selectedAnswer = null;
                _answered = false;
              });
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quizWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No quiz words available.')),
      );
    }

    final word = _quizWords[_currentQuestion];
    final choices = _allChoices[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${widget.quizNumber + 1} \u2014 $_score / $_totalAnswered'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: (_currentQuestion + 1) / _quizWords.length,
                  backgroundColor: Colors.green.shade100,
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Question ${_currentQuestion + 1} of ${_quizWords.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'What does this word mean?',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Word card with image and hear-it button
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: PackImage(
                              awingWord: word.awing,
                              english: word.english,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                              errorWidget: Container(
                                color: Colors.green.shade50,
                                child: Icon(Icons.translate, color: Colors.green.shade300, size: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word.awing,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _pronunciation.speakAwing(word.awing),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volume_up, color: const Color(0xFFDAA520), size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Hear it',
                                      style: TextStyle(color: const Color(0xFFDAA520), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Answer choices
                ...choices.map((choice) {
                  final isCorrect = choice == word.english;
                  final isSelected = _selectedAnswer == choice;
                  Color? bgColor;
                  if (_answered) {
                    if (isCorrect) {
                      bgColor = Colors.green.shade100;
                    } else if (isSelected) {
                      bgColor = Colors.red.shade100;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _selectAnswer(choice),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: bgColor,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          side: BorderSide(
                            color: _answered && isCorrect
                                ? Colors.green
                                : _answered && isSelected
                                    ? Colors.red
                                    : Colors.grey.shade300,
                            width: _answered && (isCorrect || isSelected) ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          choice,
                          style: TextStyle(
                            fontSize: 16,
                            color: _answered && isCorrect
                                ? Colors.green.shade800
                                : _answered && isSelected && !isCorrect
                                    ? Colors.red.shade800
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                if (_answered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentQuestion + 1 >= _quizWords.length
                            ? 'See Results'
                            : 'Next Question',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3.14159 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.amber,
                Color(0xFF006432),
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
