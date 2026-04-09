import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  String _selectedCategory = 'all';
  int _currentCard = 0;
  bool _showEnglish = false;

  static const _categories = {
    'all': 'All Words',
    'body': 'Body Parts',
    'animals': 'Animals',
    'nature': 'Nature',
    'food': 'Food & Drink',
    'actions': 'Actions',
    'things': 'Things',
    'family': 'Family & Places',
    'descriptive': 'Descriptive',
    'numbers': 'Numbers',
  };

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_vocabulary');
    });
  }

  List<AwingWord> get _words {
    if (_selectedCategory == 'all') return allVocabulary;
    return allVocabulary
        .where((w) => w.category == _selectedCategory)
        .toList();
  }

  void _nextCard() {
    setState(() {
      _showEnglish = false;
      _currentCard = (_currentCard + 1) % _words.length;
    });
  }

  void _prevCard() {
    setState(() {
      _showEnglish = false;
      _currentCard =
          _currentCard > 0 ? _currentCard - 1 : _words.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    if (_currentCard >= words.length) _currentCard = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: Colors.green.shade200,
                    onSelected: (_) => setState(() {
                      _selectedCategory = entry.key;
                      _currentCard = 0;
                      _showEnglish = false;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${_currentCard + 1} / ${words.length}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          // Flashcard
          Expanded(
            child: words.isEmpty
                ? const Center(child: Text('No words in this category'))
                : GestureDetector(
                    onTap: () => setState(() => _showEnglish = !_showEnglish),
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < 0) {
                          _nextCard();
                        } else if (details.primaryVelocity! > 0) {
                          _prevCard();
                        }
                      }
                    },
                    child: _FlashCard(
                      word: words[_currentCard],
                      showEnglish: _showEnglish,
                      pronunciation: _pronunciation,
                    ),
                  ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _prevCard,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showEnglish = !_showEnglish),
                  icon: Icon(_showEnglish
                      ? Icons.visibility_off
                      : Icons.visibility),
                  label: Text(_showEnglish ? 'Hide' : 'Show'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final AwingWord word;
  final bool showEnglish;
  final PronunciationService pronunciation;

  const _FlashCard({
    required this.word,
    required this.showEnglish,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = ImageService.assetPath(word.awing);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Main content: image fills left, word centered on right
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image fills the entire left half
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.green.shade200,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Word + pronunciation + hear it centered on right half
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              word.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Awing word
                          Text(
                            word.awing,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // Pronunciation guide
                          Text(
                            PronunciationService.getPronunciationGuide(
                                word.awing),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          // Hear it button
                          ElevatedButton.icon(
                            onPressed: () =>
                                pronunciation.speakAwing(word.awing),
                            icon: const Icon(Icons.volume_up, size: 24),
                            label: const Text('Hear it',
                                style: TextStyle(fontSize: 17)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDAA520),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          // English translation (shown/hidden)
                          AnimatedOpacity(
                            opacity: showEnglish ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          word.english,
                                          style: TextStyle(
                                            fontSize: 26,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (showEnglish)
                                        IconButton(
                                          onPressed: () => pronunciation
                                              .speakEnglish(word.english),
                                          icon: Icon(
                                            Icons.volume_up,
                                            color: Colors.green.shade600,
                                          ),
                                          tooltip: 'Hear English',
                                          iconSize: 24,
                                        ),
                                    ],
                                  ),
                                  if (word.pluralForm != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Plural: ${word.pluralForm}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (!showEnglish) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Tap to reveal!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
    );
  }
}
