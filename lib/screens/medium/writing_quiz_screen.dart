import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Writing rule quiz questions
class WritingQuestion {
  final String question;
  final String? context; // optional explanation
  final List<String> choices;
  final String correctAnswer;

  const WritingQuestion({
    required this.question,
    required this.choices,
    required this.correctAnswer,
    this.context,
  });
}

const List<WritingQuestion> writingQuestions = [
  WritingQuestion(
    question: 'How do you write the "r" sound in Awing?',
    context: 'Remember: Awing has no "r" in its orthography!',
    choices: ['Write "r"', 'Write "l"', 'Write "rh"', 'Write "d"'],
    correctAnswer: 'Write "l"',
  ),
  WritingQuestion(
    question: 'What letter can appear at the END of an Awing word?',
    context: 'Think about the very last letter of words...',
    choices: [
      'Any consonant',
      'Always a vowel (except nda\')',
      'Only "ng"',
      'Only "n"',
    ],
    correctAnswer: 'Always a vowel (except nda\')',
  ),
  WritingQuestion(
    question: 'Can you write "b" at the BEGINNING of a word?',
    choices: [
      'Yes, always write "b"',
      'No, write "p" or "mb" instead',
      'No, write "d" instead',
      'Yes, but only in compounds',
    ],
    correctAnswer: 'No, write "p" or "mb" instead',
  ),
  WritingQuestion(
    question: 'When can you write "d" at the beginning of a word?',
    context: 'Check the orthography rules for initial consonants...',
    choices: [
      'Always',
      'Only after vowels',
      'Never',
      'Only in borrowed words',
    ],
    correctAnswer: 'Never',
  ),
  WritingQuestion(
    question: 'After "m", what do you write instead of "p"?',
    choices: ['Write "b"', 'Write "p"', 'Write "f"', 'Write "mp"'],
    correctAnswer: 'Write "b"',
  ),
  WritingQuestion(
    question: 'When a nasal precedes a consonant, what do you write?',
    context: '"Nasal" means m, n, or ng sounds',
    choices: [
      'Write "n" before everything',
      '"m" before "b", "n" before other consonants',
      '"n" before everything',
      '"m" before everything',
    ],
    correctAnswer: '"m" before "b", "n" before other consonants',
  ),
  WritingQuestion(
    question: 'How do you always write "g" at the BEGINNING?',
    choices: ['Just "g"', '"gh"', '"ng"', '"ŋ"'],
    correctAnswer: '"gh"',
  ),
  WritingQuestion(
    question: 'Can you write the sequence "yə" after a consonant?',
    choices: [
      'Yes, always',
      'No, write "iə" instead',
      'Only sometimes',
      'Only in fast speech',
    ],
    correctAnswer: 'No, write "iə" instead',
  ),
  WritingQuestion(
    question: 'Can you write "wə" after a consonant?',
    choices: [
      'Yes, always',
      'No, write "uə" instead',
      'Only in formal speech',
      'Only after labial consonants',
    ],
    correctAnswer: 'No, write "uə" instead',
  ),
  WritingQuestion(
    question: 'Can you write "e" at the BEGINNING of a word?',
    choices: [
      'Yes, in all words starting with the vowel',
      'No, write "ə" instead',
      'Only in borrowed words',
      'Only in verbs',
    ],
    correctAnswer: 'No, write "ə" instead',
  ),
  WritingQuestion(
    question: 'How do you write the prenasalized cluster with "b"?',
    choices: ['Write "nb"', 'Write "mb"', 'Write "bn"', 'Write "mn"'],
    correctAnswer: 'Write "mb"',
  ),
  WritingQuestion(
    question: 'How do you write the prenasalized cluster with "t"?',
    choices: ['Write "nt"', 'Write "tn"', 'Write "ndt"', 'Write "tnd"'],
    correctAnswer: 'Write "nt"',
  ),
  WritingQuestion(
    question: 'The palatalized cluster with "t" + "y" is written:',
    choices: ['Write "ty"', 'Write "tj"', 'Write "ky"', 'Write "ci"'],
    correctAnswer: 'Write "ty"',
  ),
  WritingQuestion(
    question: 'The labialized cluster with "k" + "w" is written:',
    choices: ['Write "kw"', 'Write "kv"', 'Write "qu"', 'Write "ku"'],
    correctAnswer: 'Write "kw"',
  ),
  WritingQuestion(
    question: 'When do you write "ng" (not "ngh")?',
    context: '"ng" clusters follow nasal sounds',
    choices: [
      'Always write "ngh"',
      'When "g" follows a nasal',
      'Only at word endings',
      'Only at word beginnings',
    ],
    correctAnswer: 'When "g" follows a nasal',
  ),
  WritingQuestion(
    question: 'The special exception word "nda\'" means:',
    choices: [
      'A small animal',
      'Only',
      'A conjunction',
      'A verb meaning to go',
    ],
    correctAnswer: 'Only',
  ),
  WritingQuestion(
    question: 'How many vowels does Awing have?',
    choices: ['5', '7', '9', '11'],
    correctAnswer: '9',
  ),
  WritingQuestion(
    question: 'Which of these is NOT a valid Awing vowel?',
    choices: ['ɛ (epsilon)', 'ə (schwa)', 'ɨ (barred i)', 'y'],
    correctAnswer: 'y',
  ),
  WritingQuestion(
    question: 'Tone marks go on which vowel when two vowels are together?',
    choices: [
      'The second vowel',
      'Both vowels',
      'The first vowel',
      'Neither vowel',
    ],
    correctAnswer: 'The first vowel',
  ),
  WritingQuestion(
    question: 'Which glottal stop symbol is used in Awing writing?',
    choices: ['Use "h"', 'Use apostrophe "\'', 'Use "ʔ"', 'Omit it entirely'],
    correctAnswer: 'Use apostrophe "\'"',
  ),
];

class WritingQuizScreen extends StatefulWidget {
  const WritingQuizScreen({Key? key}) : super(key: key);

  @override
  State<WritingQuizScreen> createState() => _WritingQuizScreenState();
}

class _WritingQuizScreenState extends State<WritingQuizScreen> {
  final _random = Random();
  late List<WritingQuestion> _quizQuestions;
  late List<List<String>> _allChoices;
  int _currentQuestion = 0;
  int _score = 0;
  int _totalAnswered = 0;
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  void _generateQuiz() {
    _quizQuestions = List.from(writingQuestions)..shuffle(_random);
    if (_quizQuestions.length > 20) _quizQuestions = _quizQuestions.sublist(0, 20);
    _allChoices = _quizQuestions
        .map((q) => List<String>.from(q.choices)..shuffle(_random))
        .toList();
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _totalAnswered++;
      if (answer == _quizQuestions[_currentQuestion].correctAnswer) {
        _score++;
      }
    });
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
      message = 'Amazing! You know Awing writing rules!';
      celebration = '🌟';
    } else if (percentage >= 60) {
      message = 'Good effort! Keep studying the rules!';
      celebration = '👍';
    } else {
      message = 'Keep practicing! Review the orthography guide!';
      celebration = '💪';
    }

    AnalyticsService.instance.logQuiz(
      quizType: 'writing_quiz',
      level: 'medium',
      scorePercent: percentage,
      correct: _score,
      total: _totalAnswered,
    );

    context.read<AuthService>().completeLesson('medium_writing_quiz');
    context.read<AuthService>().saveQuizScore('medium_writing_quiz', percentage);

    // Notify parent via WhatsApp
    final parentService = context.read<ParentNotificationService>();
    final childName = context.read<AuthService>().currentProfile?.displayName ?? 'Your child';
    parentService.notifyQuizCompleted(
      childName: childName,
      quizName: 'Writing Rules Quiz',
      score: percentage,
      totalQuestions: _totalAnswered,
      correctAnswers: _score,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(celebration),
        content: Text('$message\n\nScore: $_score/$_totalAnswered ($percentage%)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restart();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _quizQuestions[_currentQuestion];
    final choices = _allChoices[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Quiz'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestion + 1}/${_quizQuestions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
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
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / _quizQuestions.length,
                minHeight: 8,
                backgroundColor: Colors.orange.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            // Question
            Text(
              current.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Context (if available)
            if (current.context != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  current.context!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Answer choices
            ...choices.map((choice) {
              final isCorrect = choice == current.correctAnswer;
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _answered ? null : () => _selectAnswer(choice),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          if (_answered && !isSelected && isCorrect)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            // Next button
            if (_answered)
              Center(
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Next Question',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  'Select an answer to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
