import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Medium game: Sentence Build.
/// 6 rounds — tap the scrambled Awing word chips in the correct order
/// to rebuild each sentence. Every sentence is drawn from the verified
/// 60-template pool used by the Medium writing quiz (sources:
/// AwingOrthography2005.pdf pages 9-12 + conversation_screen.dart).
///
/// Randomization is fresh per attempt (no deterministic seeding) so kids
/// can't memorize a pattern and have to parse the sentence each time.
class MediumSentenceBuild extends StatefulWidget {
  const MediumSentenceBuild({Key? key}) : super(key: key);

  @override
  State<MediumSentenceBuild> createState() => _MediumSentenceBuildState();
}

class _GameSentence {
  final String awing;
  final String english;
  const _GameSentence(this.awing, this.english);
}

/// Short sentences (3–6 tokens) drawn from the verified _allSentences
/// pool in writing_quiz_screen.dart. Kept short so tapping stays
/// manageable on phone-sized screens and the game is a puzzle rather
/// than a parsing marathon.
const List<_GameSentence> _sentencePool = [
  _GameSentence('A ghɛlɔ́ lə aké?', 'What is he doing?'),
  _GameSentence('Po zí nóolə.', 'They have seen a snake.'),
  _GameSentence('Ghǒ ghɛnɔ́ lə əfó?', 'Where are you going?'),
  _GameSentence('A kə zo nchíə.', 'He built a house.'),
  _GameSentence('A kə nyáŋə əfuá.', 'He cooked food.'),
  _GameSentence('Móonə a tə nónɔ.', 'The child is sleeping.'),
  _GameSentence('Tátə a tə a nchíə.', 'Father is at home.'),
  _GameSentence('A kə yǐə a nchíə.', 'He came to the house.'),
  _GameSentence('Lǒ!', 'Get out!'),
  _GameSentence('Lɛ̌ nəpɔ\'ɔ́.', 'This is a pumpkin.'),
  _GameSentence('A kə ghɛnɔ́ məteenɔ́.', 'He went to the market.'),
  _GameSentence('Kə pinkɔ́ sóŋə!', 'Don\'t mention it again!'),
];

class _MediumSentenceBuildState extends State<MediumSentenceBuild> {
  static const int totalRounds = 6;

  final PronunciationService _pronunciation = PronunciationService();
  late ConfettiController _confettiController;
  late Random _random;

  List<_GameSentence> _rounds = [];
  int _roundIndex = 0;

  // Original tokens for the current sentence (what the child must reconstruct)
  List<String> _correctTokens = [];
  // Scrambled chip order shown at the bottom; each chip has a stable index
  List<_Chip> _chipPool = [];
  // Chips the child has placed, in slot order
  List<_Chip> _placedChips = [];
  bool _revealed = false; // true after the child taps "Check"

  int _totalCorrect = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pronunciation.init();
    _pronunciation.setVoiceForLevel('medium');
    _generateGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateGame() {
    _random = Random();
    final pool = List<_GameSentence>.from(_sentencePool)..shuffle(_random);
    _rounds = pool.take(totalRounds).toList();
    _roundIndex = 0;
    _totalCorrect = 0;
    _totalAttempts = 0;
    _setupRound();
  }

  void _setupRound() {
    _revealed = false;
    _placedChips = [];
    // Tokenize on whitespace; preserves punctuation attached to words
    _correctTokens = _rounds[_roundIndex].awing.split(RegExp(r'\s+'));
    _chipPool = [
      for (int i = 0; i < _correctTokens.length; i++)
        _Chip(index: i, text: _correctTokens[i])
    ]..shuffle(_random);
    // If by bad luck the shuffle produced the exact correct order, shuffle again
    if (_chipPool.length > 1 &&
        _chipPool.asMap().entries.every((e) => e.value.index == e.key)) {
      _chipPool.shuffle(_random);
    }
  }

  void _placeChip(_Chip chip) {
    if (_revealed) return;
    setState(() {
      _chipPool.remove(chip);
      _placedChips.add(chip);
    });
  }

  void _removePlacedChip(_Chip chip) {
    if (_revealed) return;
    setState(() {
      _placedChips.remove(chip);
      _chipPool.add(chip);
    });
  }

  void _checkAnswer() {
    if (_placedChips.length != _correctTokens.length) return;
    final isCorrect = List.generate(_correctTokens.length, (i) => i)
        .every((i) => _placedChips[i].index == i);

    setState(() {
      _totalAttempts++;
      _revealed = true;
      if (isCorrect) {
        _totalCorrect++;
        _pronunciation.speakAwing(_rounds[_roundIndex].awing);
      }
    });
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _rounds.length) {
      _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _setupRound();
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _revealed = false;
      _chipPool = [..._chipPool, ..._placedChips]..shuffle(_random);
      _placedChips = [];
    });
  }

  void _finishGame() {
    final percentage = _totalAttempts > 0
        ? (_totalCorrect * 100 / _totalAttempts).round()
        : 0;
    if (percentage >= 80) _confettiController.play();

    context.read<ProgressService>().addXP(50);

    AnalyticsService.instance.logQuiz(
      quizType: 'medium_game_sentence_build',
      level: 'medium',
      scorePercent: percentage,
      correct: _totalCorrect,
      total: _totalAttempts,
    );

    final auth = context.read<AuthService>();
    final childName = auth.currentProfile?.displayName ?? 'Your child';
    context.read<ParentNotificationService>().notifyQuizCompleted(
          childName: childName,
          quizName: 'Medium Game: Sentence Build',
          score: percentage,
          totalQuestions: _totalAttempts,
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
              '$_totalCorrect out of $_totalAttempts correct',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('$percentage%',
                style: const TextStyle(fontSize: 40, color: Colors.orange)),
            const SizedBox(height: 8),
            const Text('+50 XP earned!',
                style: TextStyle(color: Colors.deepOrange)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Play again',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sentence Build')),
        body: const Center(child: Text('No sentences available.')),
      );
    }

    final sentence = _rounds[_roundIndex];
    final isComplete = _placedChips.length == _correctTokens.length;
    final isCorrect = _revealed &&
        _placedChips.length == _correctTokens.length &&
        List.generate(_correctTokens.length, (i) => i)
            .every((i) => _placedChips[i].index == i);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sentence Build - Round ${_roundIndex + 1}/$totalRounds'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_roundIndex + (isComplete ? 1 : 0)) / _rounds.length,
                  backgroundColor: Colors.orange.shade50,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 16),
                // English hint card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Build this sentence in Awing:',
                            style: TextStyle(
                                fontSize: 14, color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '"${sentence.english}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          if (_revealed) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  color: isCorrect
                                      ? Colors.green
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isCorrect
                                        ? 'Correct!'
                                        : 'Correct: ${sentence.awing}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? Colors.green
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _pronunciation.speakAwing(sentence.awing),
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Hear the sentence'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.deepOrange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sentence slot area (where placed chips go)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _revealed
                            ? (isCorrect ? Colors.green : Colors.orange.shade300)
                            : Colors.orange.shade200,
                        width: 2,
                      ),
                    ),
                    child: _placedChips.isEmpty
                        ? Center(
                            child: Text(
                              'Tap words below to build the sentence',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _placedChips
                                .map((chip) => _buildPlacedChip(chip))
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Word bank',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange),
                ),
                const SizedBox(height: 8),
                // Word chip bank
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _chipPool
                          .map((chip) => _buildWordChip(chip))
                          .toList(),
                    ),
                  ),
                ),
                // Action button row
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _revealed
                              ? null
                              : (_placedChips.isEmpty ? null : _tryAgain),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: const Text('Reset',
                              style: TextStyle(color: Colors.orange)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _revealed
                            ? ElevatedButton(
                                onPressed: isCorrect ? _nextRound : _tryAgain,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: Text(
                                  isCorrect
                                      ? (_roundIndex + 1 >= _rounds.length
                                          ? 'Finish'
                                          : 'Next')
                                      : 'Try again',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: isComplete ? _checkAnswer : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text('Check',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              ),
                      ),
                    ],
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

  Widget _buildWordChip(_Chip chip) {
    return GestureDetector(
      onTap: _revealed ? null : () => _placeChip(chip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          chip.text,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPlacedChip(_Chip chip) {
    final slotIndex = _placedChips.indexOf(chip);
    final isCorrectSlot = chip.index == slotIndex;
    final Color bg;
    if (_revealed) {
      bg = isCorrectSlot ? Colors.green : Colors.red.shade400;
    } else {
      bg = Colors.orange.shade400;
    }
    return GestureDetector(
      onTap: _revealed ? null : () => _removePlacedChip(chip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          chip.text,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Chip {
  final int index; // original position in the correct sentence
  final String text;
  const _Chip({required this.index, required this.text});
}
