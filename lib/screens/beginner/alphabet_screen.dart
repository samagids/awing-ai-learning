import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_alphabet.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({Key? key}) : super(key: key);

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PronunciationService _pronunciation = PronunciationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_alphabet');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awing Alphabet'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vowels (9)'),
            Tab(text: 'Consonants (22)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LetterGrid(letters: awingVowels, pronunciation: _pronunciation),
          _LetterGrid(letters: awingConsonants, pronunciation: _pronunciation),
        ],
      ),
    );
  }
}

class _LetterGrid extends StatelessWidget {
  final List<AwingLetter> letters;
  final PronunciationService pronunciation;

  const _LetterGrid({required this.letters, required this.pronunciation});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return _LetterCard(letter: letter, pronunciation: pronunciation);
      },
    );
  }
}

class _LetterCard extends StatefulWidget {
  final AwingLetter letter;
  final PronunciationService pronunciation;

  const _LetterCard({required this.letter, required this.pronunciation});

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    final isVowel = letter.type == 'vowel';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Big letter display
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isVowel
                          ? Colors.purple.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${letter.upperCase} ${letter.letter}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isVowel
                              ? Colors.purple.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter.phoneme,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (letter.description != null)
                          Text(
                            letter.description!,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  // Speak sound button
                  IconButton(
                    onPressed: () =>
                        widget.pronunciation.speakSound(letter.letter),
                    icon: Icon(
                      Icons.volume_up,
                      color: isVowel
                          ? Colors.purple.shade400
                          : Colors.blue.shade400,
                    ),
                    tooltip: 'Hear the sound',
                    iconSize: 28,
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
              // Expanded example
              if (_expanded) ...[
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Example:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  letter.exampleWord,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '= ${letter.exampleEnglish}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Speak example word button
                          IconButton(
                            onPressed: () => widget.pronunciation
                                .speakAwing(letter.exampleWord),
                            icon: Icon(
                              Icons.play_circle_fill,
                              color: Colors.green.shade600,
                            ),
                            tooltip: 'Hear the word',
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
