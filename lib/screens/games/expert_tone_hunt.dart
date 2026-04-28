import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Expert game: listen to an Awing word, pick the tone (High/Low/Rising/Falling).
/// 10 rounds, fresh randomization per attempt — no deterministic seeding
/// (prevents pattern-memorization exploit).
///
/// Only 4 tone options are offered (not 5) because Mid-tone words in the
/// vocabulary are unmarked and carry no `tonePattern` tag — making them
/// unreliable game stimuli. The 4 marked tones are the teachable set.
class ExpertToneHunt extends StatefulWidget {
  const ExpertToneHunt({Key? key}) : super(key: key);

  @override
  State<ExpertToneHunt> createState() => _ExpertToneHuntState();
}

class _ExpertToneHuntState extends State<ExpertToneHunt> {
  static const int totalRounds = 10;

  /// Only the 4 tones that are explicitly marked in vocabulary data.
  /// Mid tone is unmarked in the orthography so game stimuli can't be
  /// reliably sourced for it.
  static const List<String> _tonesOffered = ['high', 'low', 'rising', 'falling'];

  static const Map<String, String> _toneLabels = {
    'high': 'High',
    'low': 'Low',
    'rising': 'Rising',
    'falling': 'Falling',
  };

  static const Map<String, String> _toneSymbols = {
    'high': 'á',
    'low': 'à',
    'rising': 'ǎ',
    'falling': 'â',
  };

  final PronunciationService _pronunciation = PronunciationService();
  late ConfettiController _confettiController;
  late Random _random;

  List<AwingWord> _rounds = [];
  int _roundIndex = 0;
  String? _selectedTone;
  bool _revealed = false;
  int _totalCorrect = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pronunciation.init();
    _pronunciation.setVoiceForLevel('expert');
    _generateGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateGame() {
    _random = Random();

    // Seed pool with the canonical tone-example words from awing_tones.dart
    // so every game includes clear teachable exemplars.
    final pool = <AwingWord>[];
    for (final tone in awingTones) {
      final key = tone.name.toLowerCase();
      if (_tonesOffered.contains(key)) {
        pool.add(AwingWord(
          awing: tone.exampleWord,
          english: tone.exampleEnglish,
          category: 'tones',
          tonePattern: key,
        ));
      }
    }

    // Add vocabulary words whose tonePattern is one of the 4 marked tones.
    final vocabPool = allVocabulary
        .where((w) =>
            w.awing.isNotEmpty &&
            w.tonePattern != null &&
            _tonesOffered.contains(w.tonePattern))
        .toList();
    vocabPool.shuffle(_random);

    // Balance: try to include some of each tone so the game isn't lopsided.
    // Group by tone, take up to ceil(totalRounds / 4) from each.
    final Map<String, List<AwingWord>> grouped = {
      for (final t in _tonesOffered) t: [],
    };
    for (final w in vocabPool) {
      grouped[w.tonePattern!]!.add(w);
    }

    final perTone = (totalRounds / _tonesOffered.length).ceil();
    final balanced = <AwingWord>[];
    for (final t in _tonesOffered) {
      balanced.addAll(grouped[t]!.take(perTone));
    }
    pool.addAll(balanced);

    // Shuffle full pool, take 10
    pool.shuffle(_random);
    _rounds = pool.take(totalRounds).toList();

    _roundIndex = 0;
    _totalCorrect = 0;
    _selectedTone = null;
    _revealed = false;

    // Auto-play the first word after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrent());
  }

  void _playCurrent() {
    if (_roundIndex >= _rounds.length) return;
    _pronunciation.speakAwing(_rounds[_roundIndex].awing);
  }

  void _selectTone(String tone) {
    if (_revealed) return;
    setState(() {
      _selectedTone = tone;
      _revealed = true;
      if (tone == _rounds[_roundIndex].tonePattern) {
        _totalCorrect++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), _advanceRound);
  }

  void _advanceRound() {
    if (!mounted) return;
    if (_roundIndex + 1 >= _rounds.length) {
      _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _selectedTone = null;
        _revealed = false;
      });
      _playCurrent();
    }
  }

  void _finishGame() {
    final percentage = (_totalCorrect * 100 / totalRounds).round();
    if (percentage >= 80) _confettiController.play();

    context.read<ProgressService>().addXP(50);

    AnalyticsService.instance.logQuiz(
      quizType: 'expert_game_tone_hunt',
      level: 'expert',
      scorePercent: percentage,
      correct: _totalCorrect,
      total: totalRounds,
    );

    final auth = context.read<AuthService>();
    final childName = auth.currentProfile?.displayName ?? 'Your child';
    context.read<ParentNotificationService>().notifyQuizCompleted(
          childName: childName,
          quizName: 'Expert Game: Tone Hunt',
          score: percentage,
          totalQuestions: totalRounds,
          correctAnswers: _totalCorrect,
        );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Text(percentage >= 80 ? 'Great job!' : 'Good try!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_totalCorrect out of $totalRounds correct',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('$percentage%', style: const TextStyle(fontSize: 40, color: Colors.red)),
            const SizedBox(height: 8),
            const Text('+50 XP earned!', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(_generateGame);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Play again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tone Hunt')),
        body: const Center(child: Text('Not enough tone data. Try again later.')),
      );
    }
    final word = _rounds[_roundIndex];
    final correctTone = word.tonePattern;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tone Hunt - Round ${_roundIndex + 1}/$totalRounds'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_roundIndex + (_revealed ? 1 : 0)) / totalRounds,
                  backgroundColor: Colors.red.shade50,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Listen carefully and pick the tone',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Word card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  word.awing,
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                word.english,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _playCurrent,
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Hear it again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Tone options grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.6,
                            children: _tonesOffered.map((t) {
                              final isSelected = _selectedTone == t;
                              final isCorrect = t == correctTone;
                              Color bgColor = Colors.white;
                              Color borderColor = Colors.red.shade200;
                              Color textColor = Colors.red.shade800;

                              if (_revealed) {
                                if (isCorrect) {
                                  bgColor = Colors.green.shade100;
                                  borderColor = Colors.green;
                                  textColor = Colors.green.shade900;
                                } else if (isSelected) {
                                  bgColor = Colors.red.shade100;
                                  borderColor = Colors.red;
                                  textColor = Colors.red.shade900;
                                }
                              }

                              return GestureDetector(
                                onTap: () => _selectTone(t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor, width: 3),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _toneSymbols[t]!,
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _toneLabels[t]!,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      if (_revealed && isCorrect)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Icon(Icons.check_circle,
                                              color: Colors.green, size: 20),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Chip(
                    backgroundColor: Colors.red.shade50,
                    label: Text('Score: $_totalCorrect / ${_roundIndex + (_revealed ? 1 : 0)}'),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              maxBlastForce: 15,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
