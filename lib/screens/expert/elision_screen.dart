import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class ElisionScreen extends StatefulWidget {
  const ElisionScreen({Key? key}) : super(key: key);

  @override
  State<ElisionScreen> createState() => _ElisionScreenState();
}

class _ElisionScreenState extends State<ElisionScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentRuleIndex = 0;
  List<String> _answers = [];
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _answers = List.filled(_elisionRules.length, '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('expert_elision');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRule = _elisionRules[_currentRuleIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elision Rules'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What is Elision?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Elision means a sound is dropped or shortened. In Awing, when two vowels meet between words, one vowel is often dropped. Also, many words have LONG and SHORT forms!',
                        style: TextStyle(fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      _buildElisionExamples(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current rule
              Text(
                'Rule ${_currentRuleIndex + 1} of ${_elisionRules.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.amber.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentRule['title']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentRule['explanation']!,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Example:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentRule['longForm']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '↓',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade400, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentRule['shortForm']!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentRule['meaning']!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Practice question
              const Text(
                'Practice: Convert to short form',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Long form:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRule['practiceWord']!,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentRule['practiceMeaning']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pronunciation.speakAwing(currentRule['practiceWord']!),
                              icon: const Icon(Icons.volume_up),
                              label: const Text('Hear it'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_showAnswer)
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _showAnswer = true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Show short form'),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Short form:',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentRule['shortFormAnswer']!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation buttons
              Row(
                children: [
                  if (_currentRuleIndex > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentRuleIndex--;
                            _showAnswer = false;
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: SizedBox.shrink(),
                    ),
                  if (_currentRuleIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_currentRuleIndex + 1 < _elisionRules.length) {
                          setState(() {
                            _currentRuleIndex++;
                            _showAnswer = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _currentRuleIndex + 1 >= _elisionRules.length ? 'Done' : 'Next',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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

  Widget _buildElisionExamples() {
    // Get words with short forms from vocabulary
    final wordsWithShortForms = allVocabulary.where((w) => w.shortForm != null).toList();

    if (wordsWithShortForms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Real examples from Awing:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...wordsWithShortForms.take(3).map((word) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.awing,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '→ ${word.shortForm}',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  '(${word.english})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

const List<Map<String, String>> _elisionRules = [
  {
    'title': 'Vowel Elision Between Words',
    'explanation':
        'When a word ending in a vowel is followed by a word starting with a vowel, the final vowel of the first word is often dropped.',
    'longForm': 'a apô (the hand)',
    'shortForm': 'a\'pô',
    'meaning': 'The "a" (vowel ending) is dropped before "apô" (starts with vowel)',
    'practiceWord': 'apeemə',
    'practiceMeaning': 'bag (long form)',
    'shortFormAnswer': 'apa',
  },
  {
    'title': 'Long vs Short Forms',
    'explanation':
        'Many Awing words have both long and short forms. The short form removes or shortens vowels at the end. Use the short form in casual speech.',
    'longForm': 'apéenə',
    'shortForm': 'apá',
    'meaning': 'flour — the ending vowel is dropped',
    'practiceWord': 'apeemə',
    'practiceMeaning': 'bag (long form)',
    'shortFormAnswer': 'apa',
  },
  {
    'title': 'Schwa Deletion',
    'explanation':
        'The schwa vowel (ə) is sometimes dropped at the end of words, especially in connected speech. It\'s the weakest vowel.',
    'longForm': 'atîə',
    'shortForm': 'atî',
    'meaning': 'tree — the schwa is dropped in short form',
    'practiceWord': 'əshûə',
    'practiceMeaning': 'fish (long form)',
    'shortFormAnswer': 'əshû',
  },
  {
    'title': 'Vowel Contraction in Compounds',
    'explanation':
        'When the final vowel of one word meets the starting vowel of the next, the two often contract into a single sound.',
    'longForm': 'ndě ayáŋə',
    'shortForm': 'ndèyáŋə',
    'meaning': 'The final "ə" of ndě (house) and the "a" of ayáŋə (wisdom) contract together',
    'practiceWord': 'nəkəŋɔ́',
    'practiceMeaning': 'pot (long form)',
    'shortFormAnswer': 'kəŋɔ́',
  },
  {
    'title': 'Double Vowel Reduction',
    'explanation':
        'When two identical vowels meet, they are pronounced as one long vowel. In written form, the duplicate is often dropped.',
    'longForm': 'a + apɛ̌ɛlə',
    'shortForm': 'a apɛ̌lə',
    'meaning': 'The repeated vowel sound is reduced to one',
    'practiceWord': 'apéenə',
    'practiceMeaning': 'flour (long form)',
    'shortFormAnswer': 'apá',
  },
  {
    'title': 'Consonant-Vowel Adjustment',
    'explanation':
        'Sometimes when a consonant cluster meets a vowel, an epenthetic vowel is inserted, then later dropped in fast speech.',
    'longForm': 'nkadtə',
    'shortForm': 'nkad',
    'meaning': 'back — the final vowel can be dropped in connected speech',
    'practiceWord': 'nəkəŋɔ́',
    'practiceMeaning': 'pot (full form)',
    'shortFormAnswer': 'kəŋɔ́',
  },
];
