import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class ToneScreen extends StatefulWidget {
  const ToneScreen({Key? key}) : super(key: key);

  @override
  State<ToneScreen> createState() => _ToneScreenState();
}

class _ToneScreenState extends State<ToneScreen> {
  final PronunciationService _pronunciation = PronunciationService();

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_tones');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tones'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Introduction card
          Card(
            color: Colors.amber.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'What are tones?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In Awing, the same word can mean completely different '
                    'things depending on whether your voice goes UP, DOWN, '
                    'or stays FLAT. This is called "tone"!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Tone types
          const Text(
            'The 5 Awing Tones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...awingTones
              .map((tone) => _ToneCard(tone: tone, pronunciation: _pronunciation)),
          const SizedBox(height: 24),
          // Minimal pairs
          const Text(
            'Hear the Difference!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'These words sound the same but have different tones '
            '— and different meanings! Tap the speaker to hear each one.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ...toneMinimalPairs
              .map((pair) => _MinimalPairCard(pair: pair, pronunciation: _pronunciation)),
          const SizedBox(height: 24),
          // Tips
          const Text(
            'Tips for Kids',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...toneRulesForKids.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rule, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ToneCard extends StatelessWidget {
  final ToneInfo tone;
  final PronunciationService pronunciation;

  const _ToneCard({required this.tone, required this.pronunciation});

  Color get _color {
    switch (tone.name) {
      case 'High':
        return Colors.red;
      case 'Mid':
        return Colors.orange;
      case 'Low':
        return Colors.blue;
      case 'Rising':
        return Colors.purple;
      case 'Falling':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get _arrow {
    switch (tone.name) {
      case 'High':
        return '↑';
      case 'Mid':
        return '→';
      case 'Low':
        return '↓';
      case 'Rising':
        return '↗';
      case 'Falling':
        return '↘';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Tone arrow indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _arrow,
                  style: TextStyle(fontSize: 28, color: _color),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${tone.name} Tone',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tone.symbol,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tone.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${tone.exampleWord} = ${tone.exampleEnglish}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () =>
                            pronunciation.speakAwing(tone.exampleWord),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.volume_up,
                            size: 20,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalPairCard extends StatelessWidget {
  final ToneMinimalPair pair;
  final PronunciationService pronunciation;

  const _MinimalPairCard({required this.pair, required this.pronunciation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFFFFF8E6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _pairRow(pair.word1, pair.english1, pair.tone1),
            const Divider(height: 16),
            _pairRow(pair.word2, pair.english2, pair.tone2),
            if (pair.word3 != null) ...[
              const Divider(height: 16),
              _pairRow(pair.word3!, pair.english3!, pair.tone3!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pairRow(String word, String english, String tone) {
    return Row(
      children: [
        // Speak button
        InkWell(
          onTap: () => pronunciation.speakAwing(word),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.volume_up,
              size: 18,
              color: const Color(0xFF006432),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            word,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            english,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tone,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF006432),
            ),
          ),
        ),
      ],
    );
  }
}
