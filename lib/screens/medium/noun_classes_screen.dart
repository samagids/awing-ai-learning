import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class NounClassesScreen extends StatefulWidget {
  const NounClassesScreen({Key? key}) : super(key: key);

  @override
  State<NounClassesScreen> createState() => _NounClassesScreenState();
}

class _NounClassesScreenState extends State<NounClassesScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  late PageController _pageController;
  int _currentClassIndex = 0;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_noun_classes');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noun Classes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Page indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                nounClasses.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: _currentClassIndex == index
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                ),
              ),
            ),
          ),
          // Noun class cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentClassIndex = index),
              itemCount: nounClasses.length,
              itemBuilder: (context, index) => _NounClassCard(
                nounClass: nounClasses[index],
                pronunciation: _pronunciation,
              ),
            ),
          ),
          // Exercise section
          Expanded(
            child: _PluralGuessingExercise(
              pronunciation: _pronunciation,
            ),
          ),
        ],
      ),
    );
  }
}

class _NounClassCard extends StatelessWidget {
  final NounClass nounClass;
  final PronunciationService pronunciation;

  const _NounClassCard({
    required this.nounClass,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Class number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Class ${nounClass.classNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Singular example
          _ExampleBox(
            label: 'SINGULAR',
            word: nounClass.singularExample,
            english: nounClass.english.split('/')[0],
            color: Colors.blue.shade50,
            onSpeak: () => pronunciation.speakAwing(nounClass.singularExample),
          ),
          const SizedBox(height: 16),
          // Arrow icon
          const Icon(Icons.arrow_downward, color: Colors.orange, size: 28),
          const SizedBox(height: 16),
          // Plural example
          _ExampleBox(
            label: 'PLURAL',
            word: nounClass.pluralExample,
            english: nounClass.english.split('/').length > 1
                ? nounClass.english.split('/')[1]
                : nounClass.english,
            color: Colors.green.shade50,
            onSpeak: nounClass.pluralExample != '--'
                ? () => pronunciation.speakAwing(nounClass.pluralExample)
                : null,
          ),
          const SizedBox(height: 20),
          // Pattern explanation
          if (nounClass.prefix != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pattern:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plural prefix: "${nounClass.prefix}"',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExampleBox extends StatelessWidget {
  final String label;
  final String word;
  final String english;
  final Color color;
  final VoidCallback? onSpeak;

  const _ExampleBox({
    required this.label,
    required this.word,
    required this.english,
    required this.color,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            english,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (onSpeak != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton.small(
                backgroundColor: Colors.orange,
                onPressed: onSpeak,
                child: const Icon(Icons.volume_up, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PluralGuessingExercise extends StatefulWidget {
  final PronunciationService pronunciation;

  const _PluralGuessingExercise({
    required this.pronunciation,
  });

  @override
  State<_PluralGuessingExercise> createState() => _PluralGuessingExerciseState();
}

class _PluralGuessingExerciseState extends State<_PluralGuessingExercise> {
  final _random = Random();
  late List<NounClass> _exerciseQuestions;
  int _currentQuestion = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _generateExercise();
  }

  void _generateExercise() {
    // Filter noun classes that have actual plurals
    _exerciseQuestions = nounClasses.where((nc) => nc.pluralExample != '--').toList()
      ..shuffle(_random);
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == _exerciseQuestions[_currentQuestion].pluralExample) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 >= _exerciseQuestions.length) {
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
    final total = _exerciseQuestions.length;
    final percentage = (_score / total * 100).round();
    String message;
    if (percentage >= 80) {
      message = 'Excellent! You understand noun classes!';
    } else if (percentage >= 60) {
      message = 'Good effort! Keep practicing!';
    } else {
      message = 'Keep learning! Review the patterns above!';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Work!'),
        content: Text('$message\n\nScore: $_score/$total'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generateExercise();
                _currentQuestion = 0;
                _score = 0;
                _selectedAnswer = null;
                _answered = false;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exerciseQuestions.isEmpty) {
      return const Center(
        child: Text('No more questions!'),
      );
    }

    final current = _exerciseQuestions[_currentQuestion];
    final options = [current.pluralExample];

    // Add wrong answers
    options.addAll(
      nounClasses
          .where((nc) => nc.pluralExample != current.pluralExample && nc.pluralExample != '--')
          .take(2)
          .map((nc) => nc.pluralExample),
    );
    options.shuffle(_random);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(thickness: 2, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Guess the Plural!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          // Question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'The plural of:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  current.singularExample,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Options
          ...options.map((option) {
            final isCorrect = option == current.pluralExample;
            final isSelected = _selectedAnswer == option;
            final isWrong = isSelected && !isCorrect;

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade300;
            if (isSelected && isCorrect) {
              bgColor = Colors.green.shade50;
              borderColor = Colors.green;
            } else if (isWrong) {
              bgColor = Colors.red.shade50;
              borderColor = Colors.red;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: _answered ? null : () => _selectAnswer(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (isSelected)
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          // Next button
          if (_answered)
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentQuestion + 1}/${_exerciseQuestions.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
