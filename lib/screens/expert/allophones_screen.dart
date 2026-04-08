import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Expert-level screen teaching consonant allophonic rules.
/// Based on "A Phonological Sketch of Awing" (van den Berg, 2009).
class AllophonesScreen extends StatefulWidget {
  const AllophonesScreen({Key? key}) : super(key: key);

  @override
  State<AllophonesScreen> createState() => _AllophonesScreenState();
}

class _AllophonesScreenState extends State<AllophonesScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentRuleIndex = 0;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('expert_allophones');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Changes'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consonant Allophones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'In Awing, the same underlying consonant can sound different depending on where it appears in a word. These sound variations are called allophones.',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Awing has only 14 underlying consonants, but they produce 54 different surface sounds!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Underlying consonants summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('14 Underlying Consonants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildConsonantTable(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rule navigation
            Text(
              'Rule ${_currentRuleIndex + 1} of ${allophonicRules.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Current rule card
            if (allophonicRules.isNotEmpty)
              _buildRuleCard(allophonicRules[_currentRuleIndex]),

            const SizedBox(height: 24),

            // Navigation buttons
            Row(
              children: [
                if (_currentRuleIndex > 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _currentRuleIndex--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
                if (_currentRuleIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentRuleIndex + 1 < allophonicRules.length
                        ? () => setState(() => _currentRuleIndex++)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      _currentRuleIndex + 1 >= allophonicRules.length ? 'Done' : 'Next Rule',
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
    );
  }

  Widget _buildConsonantTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
      },
      children: [
        _tableRow(['', 'Labial', 'Coronal', 'Velar'], header: true),
        _tableRow(['Voiceless stops', '', 't', 'k']),
        _tableRow(['Voiced stops', 'b', 'd', 'g']),
        _tableRow(['Affricates', '', 'ts', '']),
        _tableRow(['Fricatives (vl)', 'f', 's', '']),
        _tableRow(['Fricatives (vd)', '', 'z', '']),
        _tableRow(['Nasals', 'm', 'n', 'ŋ']),
        _tableRow(['Semivowels', 'w', 'j', '']),
      ],
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: header ? BoxDecoration(color: Colors.red.shade100) : null,
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          cell,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: header ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRuleCard(AllophonicRule rule) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phoneme header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.red.shade400,
                  child: Text(
                    rule.phoneme,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    rule.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Examples
            ...rule.examples.map((ex) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ex['surface']!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex['environment']!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(
                          '${ex['word']} = ${ex['english']}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.red),
                    onPressed: () => _pronunciation.speakAwing(ex['word']!),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
