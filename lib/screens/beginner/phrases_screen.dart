import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

/// Beginner-level screen for learning common Awing phrases & greetings.
class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({Key? key}) : super(key: key);

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  String _selectedCategory = 'all';

  static const _categories = {
    'all': 'All Phrases',
    'greeting': 'Greetings',
    'daily': 'Daily Life',
    'question': 'Questions',
    'classroom': 'Classroom',
    'farewell': 'Farewells',
  };

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_phrases');
    });
  }

  List<AwingPhrase> get _phrases {
    if (_selectedCategory == 'all') return awingPhrases;
    return awingPhrases
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _phrases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrases & Greetings'),
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
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          // Intro card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap a phrase to hear it spoken. Practice saying each phrase out loud!',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Phrase list
          Expanded(
            child: phrases.isEmpty
                ? const Center(child: Text('No phrases in this category'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: phrases.length,
                    itemBuilder: (context, index) {
                      return _PhraseCard(
                        phrase: phrases[index],
                        pronunciation: _pronunciation,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatefulWidget {
  final AwingPhrase phrase;
  final PronunciationService pronunciation;
  final int index;

  const _PhraseCard({
    required this.phrase,
    required this.pronunciation,
    required this.index,
  });

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _showTranslation = false;

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'greeting':
        return Icons.waving_hand;
      case 'daily':
        return Icons.wb_sunny;
      case 'question':
        return Icons.help_outline;
      case 'classroom':
        return Icons.school;
      case 'farewell':
        return Icons.directions_walk;
      default:
        return Icons.chat_bubble;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'greeting':
        return Colors.amber.shade600;
      case 'daily':
        return Colors.orange.shade400;
      case 'question':
        return Colors.teal.shade400;
      case 'classroom':
        return Colors.blue.shade400;
      case 'farewell':
        return Colors.purple.shade300;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrase;
    final color = _categoryColor(phrase.category);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _showTranslation = !_showTranslation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PackImage.path(
                      packPath: ImageService.phrasePackPath(phrase.awing),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: 56,
                        height: 56,
                        color: color.withOpacity(0.15),
                      ),
                      errorWidget: Container(
                        width: 56,
                        height: 56,
                        color: color.withOpacity(0.2),
                        alignment: Alignment.center,
                        child: Icon(_categoryIcon(phrase.category),
                            color: color, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phrase.awing,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Play button
                  IconButton(
                    onPressed: () => widget.pronunciation.speakSentence(
                      phrase.awing,
                      clipKey: phrase.clipKey,
                    ),
                    icon: Icon(Icons.volume_up, color: color),
                    tooltip: 'Hear this phrase',
                  ),
                ],
              ),
              // Context hint
              if (phrase.context != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 68),
                  child: Text(
                    phrase.context!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              // Translation (tap to reveal)
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.only(left: 68, top: 8),
                  child: Text(
                    'Tap to see translation',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 68, top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.translate, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phrase.english,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.pronunciation.speakEnglish(phrase.english),
                        icon: Icon(Icons.volume_up, size: 20, color: Colors.green.shade600),
                        tooltip: 'Hear English',
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                crossFadeState: _showTranslation
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
