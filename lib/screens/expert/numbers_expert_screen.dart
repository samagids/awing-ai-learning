import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Expert-level screen for advanced Awing numbers:
/// compound numbers (21-25), hundreds (200-500), thousand.
/// Also teaches the number-building patterns so learners can
/// construct ANY number in Awing.
class NumbersExpertScreen extends StatefulWidget {
  const NumbersExpertScreen({Key? key}) : super(key: key);

  @override
  State<NumbersExpertScreen> createState() => _NumbersExpertScreenState();
}

class _NumbersExpertScreenState extends State<NumbersExpertScreen>
    with SingleTickerProviderStateMixin {
  final PronunciationService _pronunciation = PronunciationService();
  late TabController _tabController;
  int? _selectedIndex;

  // Compound twenties (21-25)
  List<AwingWord> get _compounds => numbers
      .where((w) =>
          w.difficulty == 3 &&
          w.english.startsWith('twenty-'))
      .toList();

  // Hundreds (200-500)
  List<AwingWord> get _hundreds => numbers
      .where((w) =>
          w.difficulty == 3 &&
          w.english.contains('hundred'))
      .toList();

  // Thousand
  List<AwingWord> get _thousand => numbers
      .where((w) =>
          w.difficulty == 3 &&
          w.english == 'thousand')
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('expert_numbers');
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
        title: const Text('Advanced Numbers'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Compounds'),
            Tab(text: 'Hundreds'),
            Tab(text: 'Patterns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompoundsTab(),
          _buildHundredsTab(),
          _buildPatternsTab(),
        ],
      ),
    );
  }

  Widget _buildCompoundsTab() {
    final items = _compounds;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compound Numbers (21-25)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'To say numbers like 21, 22, etc., combine the tens word with "nə́" (and) plus the units. '
                    'These examples show how twenties are built — the same pattern works for all tens!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final word = items[index];
            final digitValue = 21 + index;
            final isSelected = _selectedIndex == index && _tabController.index == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpertNumberCard(
                digit: digitValue,
                word: word,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _pronunciation.speakAwing(word.awing);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          // Breakdown card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'How it works',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    number: '21',
                    parts: ['məghə́m mém mbê', 'nə́', "tá'ə"],
                    meanings: ['twenty', 'and', 'one'],
                  ),
                  const Divider(height: 20),
                  _BreakdownRow(
                    number: '23',
                    parts: ['məghə́m mém mbê', 'nə́ pén', 'teelə́'],
                    meanings: ['twenty', 'and', 'three'],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHundredsTab() {
    final hundredItems = _hundreds;
    final thousandItems = _thousand;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hundreds & Thousand',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hundreds use "nked" followed by the base number. '
                    'Tap each to hear how big numbers sound in Awing!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Hundreds
          ...List.generate(hundredItems.length, (index) {
            final word = hundredItems[index];
            final digitValue = (index + 2) * 100; // 200, 300, 400, 500
            final isSelected = _selectedIndex == index && _tabController.index == 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpertNumberCard(
                digit: digitValue,
                word: word,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _pronunciation.speakAwing(word.awing);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          // Thousand - big feature card
          if (thousandItems.isNotEmpty) ...[
            const Text(
              'Thousand',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pronunciation.speakAwing(thousandItems.first.awing),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '1000',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thousandItems.first.awing,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'one thousand',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white, size: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number-Building Rules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'With these patterns, you can build ANY number in Awing! '
                    'Study the rules below and try building numbers yourself.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _PatternCard(
            title: '1-10: Base Numbers',
            color: Colors.green,
            icon: Icons.looks_one,
            examples: [
              'əmɔ́ (1), əpá (2), əlɛ́ (3), əkwá (4), ətáanə (5)',
              'ntogə́ (6), asaambê (7), nəfeemə́ (8), nəpu\'ə́ (9), nəghámə (10)',
            ],
          ),
          const SizedBox(height: 12),
          _PatternCard(
            title: '11-19: ntsəb + base',
            color: Colors.orange,
            icon: Icons.add,
            examples: [
              'ntsəb teelə́ = 13 (ten-plus three)',
              'ntsəb nəfeemə́ = 18 (ten-plus eight)',
            ],
          ),
          const SizedBox(height: 12),
          _PatternCard(
            title: '20-90: məghə́m mén + base',
            color: Colors.orange.shade700,
            icon: Icons.close,
            examples: [
              'mbá = 20 (short form)',
              'məghə́m mén tênə = 50 (groups-of five)',
              'məghə́m mén nəfeemə́ = 80 (groups-of eight)',
            ],
          ),
          const SizedBox(height: 12),
          _PatternCard(
            title: 'Tens + Units: tens nə́ units',
            color: Colors.red.shade400,
            icon: Icons.link,
            examples: [
              "məghə́m mém mbê nə́ tá'ə = 21",
              'məghə́m mém mbê nə́ pén teelə́ = 23',
              'məghə́m mém mbê nə́ nəkwa = 24',
            ],
          ),
          const SizedBox(height: 12),
          _PatternCard(
            title: '100s: nked + base',
            color: Colors.red.shade700,
            icon: Icons.looks_3,
            examples: [
              'nked pê = 200 (hundred two)',
              'nked teelə́ = 300 (hundred three)',
              'nked tênə = 500 (hundred five)',
            ],
          ),
          const SizedBox(height: 12),
          _PatternCard(
            title: '1000: tə́sə',
            color: Colors.red.shade900,
            icon: Icons.star,
            examples: [
              'tə́sə = 1,000',
            ],
          ),
          const SizedBox(height: 24),
          // Challenge card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.amber.shade100, Colors.amber.shade200],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧠 Challenge: Build these numbers!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text('• How would you say 35 in Awing?', style: TextStyle(fontSize: 14, height: 1.8)),
                  Text('• How would you say 72 in Awing?', style: TextStyle(fontSize: 14, height: 1.8)),
                  Text('• How would you say 400 in Awing?', style: TextStyle(fontSize: 14, height: 1.8)),
                  SizedBox(height: 12),
                  Text(
                    'Hint: Use the tens pattern + nə́ + units pattern!',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.brown),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertNumberCard extends StatelessWidget {
  final int digit;
  final AwingWord word;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExpertNumberCard({
    required this.digit,
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isSelected
                ? [Colors.red.shade400, Colors.red.shade700]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.red.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.red.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                '$digit',
                style: TextStyle(
                  fontSize: digit >= 1000 ? 16 : (digit >= 100 ? 18 : 22),
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.awing,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.english,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.volume_up,
              color: isSelected ? Colors.white : Colors.red.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String number;
  final List<String> parts;
  final List<String> meanings;

  const _BreakdownRow({
    required this.number,
    required this.parts,
    required this.meanings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number $number:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(parts.length, (i) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    parts[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meanings[i],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<String> examples;

  const _PatternCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  backgroundColor: color,
                  radius: 16,
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...examples.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                ex,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
