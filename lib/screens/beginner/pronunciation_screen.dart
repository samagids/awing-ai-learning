import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/speech_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({Key? key}) : super(key: key);

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with TickerProviderStateMixin {
  final PronunciationService _pronunciation = PronunciationService();
  final SpeechService _speechService = SpeechService();

  late AnimationController _pulseController;
  late AwingWord _currentWord;
  String? _spokenText;
  double? _similarityScore;
  bool _isRecording = false;
  int _wordsLearned = 0;
  double _totalScore = 0.0;

  late List<AwingWord> _vocabulary;

  @override
  void initState() {
    super.initState();
    _vocabulary = allVocabulary;
    _currentWord = _getRandomWord();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pronunciation.init();
    _speechService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_pronunciation');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  AwingWord _getRandomWord() {
    return _vocabulary[math.Random().nextInt(_vocabulary.length)];
  }

  /// Normalize text for comparison (lowercase, remove diacritics, trim)
  String _normalize(String text) {
    // Remove common diacritics
    final replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ǎ': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ě': 'e',
      'ĩ': 'i',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ǐ': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ǒ': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ǔ': 'u',
      'ũ': 'u',
      'ɛ': 'e',
      'ə': 'a',
      'ɨ': 'i',
      'ɔ': 'o',
      'ŋ': 'n',
      "'": '',
    };

    var result = text.toLowerCase();
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result.trim();
  }

  /// Calculate similarity between two strings (0.0 to 1.0)
  /// Uses character matching approach similar to Levenshtein distance
  double _calculateSimilarity(String str1, String str2) {
    final normalized1 = _normalize(str1);
    final normalized2 = _normalize(str2);

    if (normalized1.isEmpty && normalized2.isEmpty) return 1.0;
    if (normalized1.isEmpty || normalized2.isEmpty) return 0.0;

    // Count matching characters at same positions
    int matches = 0;
    final minLen = math.min(normalized1.length, normalized2.length);
    final maxLen = math.max(normalized1.length, normalized2.length);

    for (int i = 0; i < minLen; i++) {
      if (normalized1[i] == normalized2[i]) matches++;
    }

    // Similarity is: matches / max_length
    // This rewards correct characters in order but penalizes length mismatches
    return matches / maxLen;
  }

  /// Get feedback based on similarity score
  String _getFeedbackText(double score) {
    if (score >= 0.7) {
      return 'Great job!';
    } else if (score >= 0.4) {
      return 'Good try!';
    } else {
      return 'Try again!';
    }
  }

  /// Get feedback color based on similarity score
  Color _getFeedbackColor(double score) {
    if (score >= 0.7) {
      return Colors.green.shade600;
    } else if (score >= 0.4) {
      return Colors.amber.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  /// Convert score (0.0-1.0) to star rating (1-5)
  int _getStarRating(double score) {
    if (score >= 0.9) return 5;
    if (score >= 0.7) return 4;
    if (score >= 0.5) return 3;
    if (score >= 0.3) return 2;
    return 1;
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _spokenText = null;
      _similarityScore = null;
    });

    _pulseController.repeat();

    await _speechService.startListening((result) {
      setState(() {
        _spokenText = result;
      });
    });

    // Auto-stop after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    await _stopRecording();
  }

  Future<void> _stopRecording() async {
    _pulseController.stop();
    _speechService.stopListening();

    if (_spokenText != null && _spokenText!.isNotEmpty) {
      final score = _calculateSimilarity(_spokenText!, _currentWord.awing);
      setState(() {
        _isRecording = false;
        _similarityScore = score;
        _wordsLearned++;
        _totalScore += score;
      });
    } else {
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _nextWord() {
    setState(() {
      _currentWord = _getRandomWord();
      _spokenText = null;
      _similarityScore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = _similarityScore != null ? _getStarRating(_similarityScore!) : 0;
    final avgScore =
        _wordsLearned > 0 ? (_totalScore / _wordsLearned * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Practice'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Session stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Words Practiced',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          _wordsLearned.toString(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Average Score',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          '$avgScore%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Current word display
              Text(
                _currentWord.awing,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _currentWord.english,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Microphone button with pulsing animation
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording
                          ? 1.0 + (_pulseController.value * 0.1)
                          : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isRecording)
                              BoxShadow(
                                color: Colors.green.withOpacity(
                                    0.3 + (_pulseController.value * 0.3)),
                                blurRadius: 20 + (_pulseController.value * 10),
                                spreadRadius:
                                    10 + (_pulseController.value * 5),
                              ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: 'mic',
                          backgroundColor: _isRecording
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isRecording ? 'Listening...' : 'Tap to speak',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Spoken text feedback
              if (_spokenText != null && _spokenText!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'You said:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _spokenText!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Similarity score feedback
              if (_similarityScore != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getFeedbackColor(_similarityScore!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getFeedbackColor(_similarityScore!),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getFeedbackText(_similarityScore!),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _getFeedbackColor(_similarityScore!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Star rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < stars ? Icons.star : Icons.star_outline,
                              color: Colors.amber.shade600,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      // Percentage score
                      Text(
                        '${(_similarityScore! * 100).round()}% Match',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _getFeedbackColor(_similarityScore!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _pronunciation.speakAwing(_currentWord.awing),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Hear it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_similarityScore != null)
                    ElevatedButton.icon(
                      onPressed: _nextWord,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
