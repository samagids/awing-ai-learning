import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Simple Awing sentences for the Medium module
class AwingSentence {
  final String awing;
  final String english;
  final List<AwingWord> words; // word-by-word breakdown

  const AwingSentence({
    required this.awing,
    required this.english,
    required this.words,
  });
}

class AwingWord {
  final String word;
  final String english;

  const AwingWord(this.word, this.english);
}

/// Sentences sourced from AwingOrthography2005.pdf examples (pages 9, 11, 12).
/// Ordered from simplest (2 words) to more complex.
// Sentences verified from AwingOrthography2005.pdf.
// Individual words verified from orthography page 8 tone chart and page 9 noun classes.
const List<AwingSentence> awingSentences = [
  // Simple 2-word sentences — words verified from orthography tone chart (p.8)
  // yə = he (p.8), ko = take (p.8), mǎ = mother (p.9)
  AwingSentence(
    awing: 'Yə nô',
    english: 'He/she drinks',
    words: [
      AwingWord('Yə', 'He/she'),
      AwingWord('nô', 'drinks'),
    ],
  ),
  AwingSentence(
    awing: 'Mǎ ko',
    english: 'Mother takes',
    words: [
      AwingWord('Mǎ', 'Mother'),
      AwingWord('ko', 'takes'),
    ],
  ),
  // 3-word sentence — ndě = water (dictionary)
  AwingSentence(
    awing: 'Mǎ nô ndě',
    english: 'Mother drinks water',
    words: [
      AwingWord('Mǎ', 'Mother'),
      AwingWord('nô', 'drinks'),
      AwingWord('ndě', 'water'),
    ],
  ),
  // yǐə = come (p.8, RISING tone ǐ, not falling î)
  AwingSentence(
    awing: 'Yə yǐə',
    english: 'He/she comes',
    words: [
      AwingWord('Yə', 'He/she'),
      AwingWord('yǐə', 'comes'),
    ],
  ),
  // Longer sentences — VERIFIED from orthography PDF
  // Page 11: "Móonə a tə nonnɔ́ a əkwunɔ́."
  AwingSentence(
    awing: "Móonə a tə nonnɔ́ a əkwunɔ́.",
    english: 'The baby is lying on the bed.',
    words: [
      AwingWord('Móonə', 'Baby'),
      AwingWord('a', '(subject)'),
      AwingWord('tə', '(progressive)'),
      AwingWord('nonnɔ́', 'lying'),
      AwingWord('a', 'on'),
      AwingWord('əkwunɔ́', 'bed'),
    ],
  ),
  // Page 9: "A kə ghɛnɔ́ məteenɔ́."
  AwingSentence(
    awing: "A kə ghɛnɔ́ məteenɔ́.",
    english: 'He went to the market.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('kə', '(past tense)'),
      AwingWord('ghɛnɔ́', 'go'),
      AwingWord('məteenɔ́', 'market'),
    ],
  ),
  // Page 12: "Po zí nóolə."
  AwingSentence(
    awing: "Po zí nóolə.",
    english: 'They have seen a snake.',
    words: [
      AwingWord('Po', 'They'),
      AwingWord('zí', 'have seen'),
      AwingWord('nóolə', 'snake'),
    ],
  ),
  // Page 12: "Ghǒ ghɛnɔ́ lə əfó?" (from quotation marks section)
  AwingSentence(
    awing: "Ghǒ ghɛnɔ́ lə əfó?",
    english: 'Where are you going?',
    words: [
      AwingWord('Ghǒ', 'You'),
      AwingWord('ghɛnɔ́', 'going'),
      AwingWord('lə', 'to'),
      AwingWord('əfó', 'where'),
    ],
  ),
  // Page 11: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə."
  AwingSentence(
    awing: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə.",
    english: 'They are not coming here, they are going to the stream.',
    words: [
      AwingWord('Po', 'They'),
      AwingWord('ma', 'not'),
      AwingWord('ngyǐə', 'come'),
      AwingWord('lə', 'to'),
      AwingWord('əfê', 'here'),
      AwingWord('po', 'they'),
      AwingWord('ghɛnɔ́', 'go'),
      AwingWord('lə', 'to'),
      AwingWord('nkǐə', 'stream'),
    ],
  ),
  // Page 10: "Lɛ̌ nəpɔ'ɔ́."
  AwingSentence(
    awing: "Lɛ̌ nəpɔ'ɔ́.",
    english: 'This is a pumpkin.',
    words: [
      AwingWord('Lɛ̌', 'This is'),
      AwingWord("nəpɔ'ɔ́", 'pumpkin'),
    ],
  ),
];

class SentencesScreen extends StatefulWidget {
  const SentencesScreen({Key? key}) : super(key: key);

  @override
  State<SentencesScreen> createState() => _SentencesScreenState();
}

class _SentencesScreenState extends State<SentencesScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _selectedMode = 0; // 0 = Reading, 1 = Building

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_sentences');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Building'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mode tabs
          Container(
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'Reading',
                    isSelected: _selectedMode == 0,
                    onTap: () => setState(() => _selectedMode = 0),
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    label: 'Building',
                    isSelected: _selectedMode == 1,
                    onTap: () => setState(() => _selectedMode = 1),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedMode == 0
                ? _ReadingMode(pronunciation: _pronunciation)
                : _BuildingMode(pronunciation: _pronunciation),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _ReadingMode extends StatefulWidget {
  final PronunciationService pronunciation;

  const _ReadingMode({required this.pronunciation});

  @override
  State<_ReadingMode> createState() => _ReadingModeState();
}

class _ReadingModeState extends State<_ReadingMode> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicator
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              awingSentences.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: _currentIndex == index
                      ? Colors.orange
                      : Colors.orange.shade200,
                ),
              ),
            ),
          ),
        ),
        // Sentences
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: awingSentences.length,
            itemBuilder: (context, index) => _SentenceCard(
              sentence: awingSentences[index],
              pronunciation: widget.pronunciation,
            ),
          ),
        ),
      ],
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final AwingSentence sentence;
  final PronunciationService pronunciation;

  const _SentenceCard({
    required this.sentence,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  sentence.awing,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  sentence.english,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.orange,
                    onPressed: () => pronunciation.speakAwing(sentence.awing),
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text(
                      'Hear It',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Word-by-word breakdown
          const Text(
            'Word by Word:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sentence.words.asMap().entries.map((entry) {
            final idx = entry.key;
            final word = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${idx + 1}. ${word.word}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            word.english,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FloatingActionButton.small(
                      backgroundColor: Colors.blue,
                      onPressed: () => pronunciation.speakAwing(word.word),
                      child: const Icon(Icons.volume_up, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BuildingMode extends StatefulWidget {
  final PronunciationService pronunciation;

  const _BuildingMode({required this.pronunciation});

  @override
  State<_BuildingMode> createState() => _BuildingModeState();
}

class _BuildingModeState extends State<_BuildingMode> {
  final _random = Random();
  late List<AwingSentence> _buildingExercises;
  int _currentIndex = 0;
  late List<AwingWord> _shuffledWords;
  late List<AwingWord> _selectedOrder;

  @override
  void initState() {
    super.initState();
    _buildingExercises = List.from(awingSentences)..shuffle(_random);
    _initializeSentence();
  }

  void _initializeSentence() {
    final current = _buildingExercises[_currentIndex];
    _shuffledWords = List.from(current.words)..shuffle(_random);
    _selectedOrder = [];
  }

  void _selectWord(AwingWord word) {
    setState(() {
      _shuffledWords.remove(word);
      _selectedOrder.add(word);
    });
  }

  void _deselectWord(int index) {
    setState(() {
      final word = _selectedOrder[index];
      _selectedOrder.removeAt(index);
      _shuffledWords.add(word);
      _shuffledWords.sort(
        (a, b) => _buildingExercises[_currentIndex]
            .words
            .indexOf(a)
            .compareTo(_buildingExercises[_currentIndex].words.indexOf(b)),
      );
    });
  }

  void _checkAnswer() {
    final current = _buildingExercises[_currentIndex];
    final isCorrect =
        _selectedOrder.map((w) => w.word).join(' ') == current.awing;

    String message;
    Color bgColor;
    if (isCorrect) {
      message = 'Perfect! You got it right!';
      bgColor = Colors.green;
    } else {
      message = 'Not quite. Try again!';
      bgColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );

    if (isCorrect) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentIndex + 1 < _buildingExercises.length) {
          setState(() {
            _currentIndex++;
            _initializeSentence();
          });
        } else {
          _showResults();
        }
      });
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Work!'),
        content: const Text('You completed all sentence building exercises!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _buildingExercises = List.from(awingSentences)..shuffle(_random);
                _currentIndex = 0;
                _initializeSentence();
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
    final current = _buildingExercises[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          const Text(
            'Arrange the words to form the sentence:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // Target sentence (for reference)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              current.english,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Selected order
          const Text(
            'Your sentence:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: _selectedOrder.isEmpty
                ? const Text(
                    'Tap words below to build your sentence...',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedOrder.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final word = entry.value;
                      return InkWell(
                        onTap: () => _deselectWord(idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word.word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          // Available words
          const Text(
            'Available words:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _shuffledWords.map((word) {
              return InkWell(
                onTap: () => _selectWord(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        word.english,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Check button
          Center(
            child: ElevatedButton(
              onPressed: _selectedOrder.length == current.words.length
                  ? _checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Check Answer',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Question ${_currentIndex + 1}/${_buildingExercises.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
