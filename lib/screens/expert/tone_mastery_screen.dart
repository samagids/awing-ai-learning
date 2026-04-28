import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class ToneMasteryScreen extends StatefulWidget {
  const ToneMasteryScreen({Key? key}) : super(key: key);

  @override
  State<ToneMasteryScreen> createState() => _ToneMasteryScreenState();
}

class _ToneMasteryScreenState extends State<ToneMasteryScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  final _random = Random();
  int _exerciseScore = 0;
  int _exerciseAnswered = 0;
  int _currentExerciseIndex = 0;
  String? _selectedTone;
  bool _answered = false;
  late List<Map<String, dynamic>> _exercises;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _generateExercises();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('expert_tone_mastery');
    });
  }

  /// Normalize tone names like 'high-final' to just 'high'
  String _normalizeTone(String tone) {
    final base = tone.toLowerCase().split('-').first;
    const validTones = ['high', 'mid', 'low', 'rising', 'falling'];
    return validTones.contains(base) ? base : 'mid';
  }

  void _generateExercises() {
    // Mix minimal pairs with tone examples
    _exercises = [];

    // Add tone minimal pairs
    for (final pair in toneMinimalPairs) {
      _exercises.add({
        'word': pair.word1,
        'correctTone': _normalizeTone(pair.tone1),
        'englishMeaning': pair.english1,
      });
      _exercises.add({
        'word': pair.word2,
        'correctTone': _normalizeTone(pair.tone2),
        'englishMeaning': pair.english2,
      });
      if (pair.word3 != null) {
        _exercises.add({
          'word': pair.word3,
          'correctTone': _normalizeTone(pair.tone3 ?? 'mid'),
          'englishMeaning': pair.english3,
        });
      }
    }

    // Add tone examples
    for (final tone in awingTones) {
      _exercises.add({
        'word': tone.exampleWord,
        'correctTone': tone.name.toLowerCase(),
        'englishMeaning': tone.exampleEnglish,
      });
    }

    _exercises.shuffle(_random);
    if (_exercises.length > 15) {
      _exercises = _exercises.sublist(0, 15);
    }

    // Safety: ensure at least 1 exercise
    if (_exercises.isEmpty) {
      _exercises.add({
        'word': 'mǎ',
        'correctTone': 'rising',
        'englishMeaning': 'mother',
      });
    }
  }

  void _selectTone(String tone) {
    if (_answered) return;

    setState(() {
      _selectedTone = tone;
      _answered = true;
      _exerciseAnswered++;

      final correct = _exercises[_currentExerciseIndex]['correctTone'];
      if (tone.toLowerCase() == correct) {
        _exerciseScore++;
      }
    });

    // Auto-advance after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), _nextExercise);
  }

  void _nextExercise() {
    if (_currentExerciseIndex + 1 >= _exercises.length) {
      _showResults();
      return;
    }

    setState(() {
      _currentExerciseIndex++;
      _selectedTone = null;
      _answered = false;
    });
  }

  void _showResults() {
    final percentage = (_exerciseScore / _exerciseAnswered * 100).round();
    String message;
    if (percentage >= 85) {
      message = 'Excellent! You are a tone master!';
    } else if (percentage >= 70) {
      message = 'Great job! Your tone awareness is improving!';
    } else {
      message = 'Good effort! Keep practicing those tones!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Text('Exercise Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $_exerciseScore / $_exerciseAnswered',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$percentage%', style: TextStyle(fontSize: 32, color: Colors.red.shade700)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generateExercises();
                _currentExerciseIndex = 0;
                _exerciseScore = 0;
                _exerciseAnswered = 0;
                _selectedTone = null;
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

  void _restart() {
    setState(() {
      _generateExercises();
      _currentExerciseIndex = 0;
      _exerciseScore = 0;
      _exerciseAnswered = 0;
      _selectedTone = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Mastery'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tone patterns explanation
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tone Patterns',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Awing has 5 tones. When words combine in sentences, tones interact and can change!',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildTonePatternInfo(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise section
              const Text(
                'Tone Identification Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Listen to the word. Which tone do you hear? (${_currentExerciseIndex + 1} / ${_exercises.length})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Current exercise
              Card(
                color: Colors.red.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _exercises[_currentExerciseIndex]['word'],
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(${_exercises[_currentExerciseIndex]['englishMeaning']})',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _answered
                            ? null
                            : () => _pronunciation.speakAwing(_exercises[_currentExerciseIndex]['word']),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Hear the word'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tone buttons
              const Text(
                'Which tone?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['high', 'mid', 'low', 'rising', 'falling']
                    .map((tone) {
                      final isSelected = _selectedTone == tone;
                      final isCorrect = tone.toLowerCase() ==
                          _exercises[_currentExerciseIndex]['correctTone'];
                      final isWrong = isSelected && !isCorrect;

                      Color bgColor = Colors.grey.shade200;
                      if (isWrong) {
                        bgColor = Colors.red.shade200;
                      } else if (_answered && isCorrect) {
                        bgColor = Colors.green.shade300;
                      }

                      return ElevatedButton(
                        onPressed: () => _selectTone(tone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bgColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isSelected
                                ? BorderSide(
                                    color: isWrong ? Colors.red : Colors.green,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          tone.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),

              if (_answered)
                Column(
                  children: [
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedTone?.toUpperCase() == _exercises[_currentExerciseIndex]['correctTone'].toUpperCase()
                                    ? 'Correct!'
                                    : 'The correct tone was: ${_exercises[_currentExerciseIndex]['correctTone'].toUpperCase()}',
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _exerciseAnswered / _exercises.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(Colors.red.shade500),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress: $_exerciseAnswered / ${_exercises.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTonePatternInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TonePatternRule(
          title: 'High Tone (á)',
          description: 'Voice goes UP. Keep it high throughout the word.',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _TonePatternRule(
          title: 'Mid Tone (a)',
          description: 'Voice stays in the MIDDLE. Steady and even.',
          icon: Icons.remove,
        ),
        const SizedBox(height: 12),
        _TonePatternRule(
          title: 'Low Tone (a)',
          description: 'Voice goes DOWN. Make it low and deep.',
          icon: Icons.trending_down,
        ),
        const SizedBox(height: 12),
        _TonePatternRule(
          title: 'Rising (ǎ)',
          description: 'Start LOW, then go UP. Like a question!',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _TonePatternRule(
          title: 'Falling (â)',
          description: 'Start HIGH, then go DOWN. Like you\'re deciding.',
          icon: Icons.trending_down,
        ),
      ],
    );
  }
}

class _TonePatternRule extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _TonePatternRule({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
