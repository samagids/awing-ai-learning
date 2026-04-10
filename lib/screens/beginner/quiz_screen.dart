import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _random = Random();
  final PronunciationService _pronunciation = PronunciationService();
  late List<AwingWord> _quizWords;
  late List<List<String>> _allChoices; // pre-generated choices per question
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
    _quizWords = List.from(allVocabulary)..shuffle(_random);
    if (_quizWords.length > 20) _quizWords = _quizWords.sublist(0, 20);
    _allChoices = _quizWords.map((w) => _generateChoices(w)).toList();
  }

  List<String> _generateChoices(AwingWord correct) {
    final others = allVocabulary
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
    String emoji;
    if (percentage >= 80) {
      message = 'Amazing! You are a fast learner!';
      emoji = '🌟';
      _confettiController.play();
    } else if (percentage >= 60) {
      message = 'Good job! Keep practicing!';
      emoji = '👍';
    } else {
      message = 'Keep going! Practice makes perfect!';
      emoji = '💪';
    }

    Provider.of<ProgressService>(context, listen: false)
        .saveQuizScore('beginner', percentage);

    context.read<AuthService>().completeLesson('beginner_quiz');
    context.read<AuthService>().saveQuizScore('beginner_quiz', percentage);

    AnalyticsService.instance.logQuiz(
      quizType: 'beginner_quiz',
      level: 'beginner',
      scorePercent: percentage,
      correct: _score,
      total: _totalAnswered,
    );

    // Notify parent via WhatsApp
    final parentService = context.read<ParentNotificationService>();
    final childName = context.read<AuthService>().currentProfile?.displayName ?? 'Your child';
    parentService.notifyQuizCompleted(
      childName: childName,
      quizName: 'Beginner Quiz',
      score: percentage,
      totalQuestions: _totalAnswered,
      correctAnswers: _score,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$emoji Quiz Complete!', textAlign: TextAlign.center),
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
              Navigator.pop(context);
              _restart();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
        title: Text('Quiz — $_score / $_totalAnswered'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                  valueColor: AlwaysStoppedAnimation(Colors.green),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Question ${_currentQuestion + 1} of ${_quizWords.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                // Question
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
                        // Image thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.asset(
                              ImageService.assetPath(word.awing),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.green.shade50,
                                child: Icon(Icons.translate, color: Colors.green.shade300, size: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Word + hear it
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
                // Next button
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
              blastDirection: -3.14159 / 2, // Upward
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.amber,
                const Color(0xFF006432),
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
