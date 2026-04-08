import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class VowelsScreen extends StatefulWidget {
  const VowelsScreen({Key? key}) : super(key: key);

  @override
  State<VowelsScreen> createState() => _VowelsScreenState();
}

class _VowelsScreenState extends State<VowelsScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _selectedTab = 0; // 0=chart, 1=long vowels, 2=syllables

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_vowels');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vowels & Syllables'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.orange.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tab('9 Vowels', 0),
                _tab('Long Vowels', 1),
                _tab('Syllables', 2),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildVowelChart()
                : _selectedTab == 1
                    ? _buildLongVowels()
                    : _buildSyllables(),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.orange : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.orange : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVowelChart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Awing Vowel System', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 8),
                  Text(
                    'Awing has 9 vowels arranged in a 3×3 grid by tongue height and position. This is more than most Bantu languages, which typically have 7.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Visual vowel chart
          _buildVowelGrid(),
          const SizedBox(height: 20),
          // Individual vowel cards
          ...awingVowels.map((v) => _buildVowelCard(v)),
        ],
      ),
    );
  }

  Widget _buildVowelGrid() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(width: 60),
                ...['Front', 'Central', 'Back'].map((h) => Expanded(
                  child: Text(h, textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                )),
              ],
            ),
            const Divider(),
            // Vowel rows
            ...['high', 'mid', 'low'].map((height) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      height[0].toUpperCase() + height.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  ...['front', 'central', 'back'].map((pos) {
                    final vowel = awingVowels.where(
                      (v) => v.height == height && v.position == pos,
                    ).firstOrNull;
                    if (vowel == null) return const Expanded(child: SizedBox.shrink());
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _pronunciation.speakAwing(vowel.exampleWord),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(vowel.vowel, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              if (vowel.hasLongForm)
                                Text('(${vowel.vowel}ː)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildVowelCard(AwingVowel v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade300,
          child: Text(v.vowel, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(v.description, style: const TextStyle(fontSize: 14)),
        subtitle: Text('${v.exampleWord} = ${v.exampleEnglish}', style: const TextStyle(fontSize: 13)),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up, color: Colors.orange),
          onPressed: () => _pronunciation.speakAwing(v.exampleWord),
        ),
      ),
    );
  }

  Widget _buildLongVowels() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Long Vowels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 8),
                  Text(
                    'Awing has 7 long vowels. Vowel length is contrastive — it can change meaning! Long vowels only appear in the first syllable of a word root.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...longVowelExamples.map((lv) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepOrange.shade300,
                        child: Text(lv['vowel']!, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lv['word']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(lv['english']!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.orange),
                        onPressed: () => _pronunciation.speakAwing(lv['word']!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Compare: ${lv['contrast']!}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          // Vowel sequences section
          const Text('Vowel Sequences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Awing has 3 vowel sequences — a high vowel followed by schwa (ə). The high vowel is the stem ending and ə is a suffix.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          ...vowelSequences.map((vs) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade300,
                child: Text(vs['sequence']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(vs['example']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${vs['english']} — ${vs['note']}', style: const TextStyle(fontSize: 13)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSyllables() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Syllable Structure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 8),
                  Text(
                    'Awing has 6 basic syllable types. "C" = consonant, "V" = vowel, "S" = semivowel (w or j), "N" = syllabic nasal.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...syllableTypes.map((st) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(st.pattern, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.description, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(st.example, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(' = ${st.english}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.orange),
                        onPressed: () => _pronunciation.speakAwing(st.example),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: st.whereUsed.map((w) => Chip(
                      label: Text(w, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.orange.shade100,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    )).toList(),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          // Verb suffixes section
          const Text('Verb Suffixes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Every Awing verb must end with a suffix vowel. The suffix changes the meaning:',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          ...verbSuffixes.map((vs) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade400,
                child: Text(vs.suffix, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              title: Text(vs.meaning, style: const TextStyle(fontSize: 14)),
              subtitle: Text('${vs.example} = ${vs.exampleEnglish}', style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.orange),
                onPressed: () => _pronunciation.speakAwing(vs.example),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
