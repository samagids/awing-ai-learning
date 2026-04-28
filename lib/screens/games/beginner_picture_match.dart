import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Beginner game: drag each Awing word chip onto the matching picture.
/// 8 rounds, 4 image/word pairs per round (32 matches total).
/// Fresh randomization per attempt — no deterministic seeding (prevents
/// pattern-memorization exploit).
class BeginnerPictureMatch extends StatefulWidget {
  const BeginnerPictureMatch({Key? key}) : super(key: key);

  @override
  State<BeginnerPictureMatch> createState() => _BeginnerPictureMatchState();
}

class _BeginnerPictureMatchState extends State<BeginnerPictureMatch> {
  static const int totalRounds = 8;
  static const int pairsPerRound = 4;

  final PronunciationService _pronunciation = PronunciationService();
  late ConfettiController _confettiController;
  late Random _random;

  List<List<AwingWord>> _rounds = [];
  List<String> _shuffledChipOrder = [];
  // Map from image awing key → the awing word currently dropped on it (null = empty)
  Map<String, String?> _placed = {};
  Set<String> _placedChips = {}; // chips already successfully placed
  int _roundIndex = 0;
  int _mistakesThisRound = 0;
  int _totalCorrect = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pronunciation.init();
    _pronunciation.setVoiceForLevel('beginner');
    _generateGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateGame() {
    _random = Random();
    final beginnerWords = allVocabulary
        .where((w) => w.difficulty == 1 && w.awing.isNotEmpty)
        .toList();
    beginnerWords.shuffle(_random);

    _rounds = [];
    // Need 8 rounds * 4 words = 32 unique words minimum
    final count = (totalRounds * pairsPerRound).clamp(0, beginnerWords.length);
    for (int i = 0; i < count; i += pairsPerRound) {
      if (i + pairsPerRound > count) break;
      _rounds.add(beginnerWords.sublist(i, i + pairsPerRound));
    }
    _roundIndex = 0;
    _totalCorrect = 0;
    _totalAttempts = 0;
    _setupRound();
  }

  void _setupRound() {
    _mistakesThisRound = 0;
    _placed = {for (final w in _rounds[_roundIndex]) w.awing: null};
    _placedChips = {};
    // Shuffle chip order independently of image order so kids can't rely on position
    _shuffledChipOrder = _rounds[_roundIndex].map((w) => w.awing).toList()
      ..shuffle(_random);
  }

  void _onMatch(String imageAwing, String chipAwing) {
    setState(() {
      _totalAttempts++;
      if (imageAwing == chipAwing) {
        _placed[imageAwing] = chipAwing;
        _placedChips.add(chipAwing);
        _totalCorrect++;
        _pronunciation.speakAwing(chipAwing);
      } else {
        _mistakesThisRound++;
      }
    });

    // Check round complete
    if (_placedChips.length == pairsPerRound) {
      Future.delayed(const Duration(milliseconds: 900), _advanceRound);
    }
  }

  void _advanceRound() {
    if (_roundIndex + 1 >= _rounds.length) {
      _finishGame();
    } else {
      setState(() {
        _roundIndex++;
        _setupRound();
      });
    }
  }

  void _finishGame() {
    final percentage = _totalAttempts > 0
        ? (_totalCorrect * 100 / _totalAttempts).round()
        : 0;
    if (percentage >= 80) _confettiController.play();

    // XP reward
    context.read<ProgressService>().addXP(50);

    // Analytics
    AnalyticsService.instance.logQuiz(
      quizType: 'beginner_game_picture_match',
      level: 'beginner',
      scorePercent: percentage,
      correct: _totalCorrect,
      total: _totalAttempts,
    );

    // Parent notification
    final auth = context.read<AuthService>();
    final childName = auth.currentProfile?.displayName ?? 'Your child';
    context.read<ParentNotificationService>().notifyQuizCompleted(
          childName: childName,
          quizName: 'Beginner Game: Picture Match',
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
            Text('$percentage%', style: const TextStyle(fontSize: 40, color: Colors.green)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        appBar: AppBar(title: const Text('Picture Match')),
        body: const Center(child: Text('Not enough vocabulary. Try again later.')),
      );
    }
    final round = _rounds[_roundIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Picture Match - Round ${_roundIndex + 1}/${totalRounds.clamp(0, _rounds.length)}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_roundIndex + _placedChips.length / pairsPerRound) /
                      _rounds.length,
                  backgroundColor: Colors.green.shade50,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drag each word onto the right picture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: round.map((w) => _buildImageTarget(w)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _shuffledChipOrder
                        .where((chip) => !_placedChips.contains(chip))
                        .map((chip) => _buildWordChip(chip))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        backgroundColor: Colors.green.shade50,
                        label: Text('Score: $_totalCorrect / $_totalAttempts'),
                      ),
                      if (_mistakesThisRound > 0)
                        Chip(
                          backgroundColor: Colors.red.shade50,
                          label: Text('Mistakes: $_mistakesThisRound'),
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

  Widget _buildImageTarget(AwingWord word) {
    final isPlaced = _placed[word.awing] != null;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isPlaced,
      onAcceptWithDetails: (details) => _onMatch(word.awing, details.data),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _pronunciation.speakAwing(word.awing),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPlaced
                    ? Colors.green
                    : candidateData.isNotEmpty
                        ? Colors.orange
                        : Colors.green.shade200,
                width: isPlaced ? 3 : 2,
              ),
              color: isPlaced ? Colors.green.shade50 : Colors.white,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: PackImage(
                      awingWord: word.awing,
                      english: word.english,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.green.shade50,
                        child: Icon(Icons.image, color: Colors.green.shade300, size: 48),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isPlaced ? Colors.green : Colors.green.shade50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: Text(
                    isPlaced ? word.awing : word.english,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isPlaced ? Colors.white : Colors.green.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordChip(String awing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Draggable<String>(
        data: awing,
        onDragStarted: () => _pronunciation.speakAwing(awing),
        feedback: Material(
          color: Colors.transparent,
          child: _chipBox(awing, elevated: true),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _chipBox(awing)),
        child: _chipBox(awing),
      ),
    );
  }

  Widget _chipBox(String text, {bool elevated = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(28),
        boxShadow: elevated
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
