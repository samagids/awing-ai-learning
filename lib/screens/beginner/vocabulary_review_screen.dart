import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

class VocabularyReviewScreen extends StatefulWidget {
  const VocabularyReviewScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyReviewScreen> createState() => _VocabularyReviewScreenState();
}

class _VocabularyReviewScreenState extends State<VocabularyReviewScreen> {
  late List<SpacedRepetitionWord> reviewQueue;
  int currentIndex = 0;
  bool answerRevealed = false;
  int correctCount = 0;
  int incorrectCount = 0;
  bool sessionComplete = false;

  @override
  void initState() {
    super.initState();
    reviewQueue = Provider.of<ProgressService>(context, listen: false).getWordsToReview();
  }

  String? _getEnglishTranslation(String awingWord) {
    try {
      final word = allVocabulary.firstWhere(
        (w) => w.awing == awingWord,
        orElse: () => AwingWord(
          awing: awingWord,
          english: 'Unknown',
          category: 'unknown',
        ),
      );
      return word.english;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _handleAnswer(bool correct) async {
    final progressService = Provider.of<ProgressService>(context, listen: false);
    final currentWord = reviewQueue[currentIndex].word;

    // Record the answer
    await progressService.recordSpacedRepetitionAnswer(currentWord, correct);

    // Update counters
    if (correct) {
      correctCount++;
    } else {
      incorrectCount++;
    }

    // Move to next word or show summary
    if (currentIndex < reviewQueue.length - 1) {
      setState(() {
        currentIndex++;
        answerRevealed = false;
      });
    } else {
      setState(() {
        sessionComplete = true;
      });
    }
  }

  void _revealAnswer() {
    setState(() {
      answerRevealed = true;
    });
  }

  void _resetSession() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Show celebration screen if no words to review
    if (reviewQueue.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vocabulary Review'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'All Caught Up!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You have no words to review right now.\nGreat job keeping up with your studying!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _resetSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show summary screen if session is complete
    if (sessionComplete) {
      final totalReviewed = correctCount + incorrectCount;
      final percentage = totalReviewed > 0 ? ((correctCount / totalReviewed) * 100).toInt() : 0;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Complete'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Session Complete!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Correct:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$correctCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Still Learning:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$incorrectCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.green.withAlpha(100)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Accuracy:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _resetSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show review card
    final currentWord = reviewQueue[currentIndex];
    final english = _getEnglishTranslation(currentWord.word);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Review'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Word ${currentIndex + 1} of ${reviewQueue.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Box ${currentWord.box + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / reviewQueue.length,
                    minHeight: 8,
                    backgroundColor: Colors.green.withAlpha(100),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ),
          ),
          // Box level indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= currentWord.box ? Colors.green : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Review card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Image fills left, word + hear it centered on right
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image fills left half
                          Expanded(
                            flex: 1,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                              ),
                              child: PackImage(
                                awingWord: currentWord.word,
                                english: english ?? '',
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.green.shade50,
                                  child: Icon(Icons.image_outlined, size: 48, color: Colors.green.shade200),
                                ),
                              ),
                            ),
                          ),
                          // Word + hear it centered on right half
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Auto-shrink Awing word to fit narrow phones
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currentWord.word,
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final pronService = Provider.of<PronunciationService>(
                                      context,
                                      listen: false,
                                    );
                                    await pronService.speakAwing(currentWord.word);
                                  },
                                  icon: const Icon(Icons.volume_up),
                                  label: const Text('Hear it'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Answer section below
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                      // Answer section
                      if (!answerRevealed)
                        Column(
                          children: [
                            Text(
                              'Do you remember the translation?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _revealAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              ),
                              child: const Text(
                                'Show Answer',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                english ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How did you do?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handleAnswer(true),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('I knew it!'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _handleAnswer(false),
                                  icon: const Icon(Icons.info),
                                  label: const Text('Still learning'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
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
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
