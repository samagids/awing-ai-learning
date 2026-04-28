import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Medium-level screen for learning Awing numbers 11-100.
/// Teaches teens (11-19), tens (20-90), and hundred/thousand.
class NumbersMediumScreen extends StatefulWidget {
  const NumbersMediumScreen({Key? key}) : super(key: key);

  @override
  State<NumbersMediumScreen> createState() => _NumbersMediumScreenState();
}

class _NumbersMediumScreenState extends State<NumbersMediumScreen>
    with SingleTickerProviderStateMixin {
  final PronunciationService _pronunciation = PronunciationService();
  late TabController _tabController;
  int? _selectedIndex;

  // Split numbers by group
  List<AwingWord> get _teens => numbers
      .where((w) =>
          w.difficulty == 2 &&
          ['eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
           'sixteen', 'seventeen', 'eighteen', 'nineteen']
              .contains(w.english))
      .toList();

  List<AwingWord> get _tens => numbers
      .where((w) =>
          w.difficulty == 2 &&
          ['twenty', 'thirty', 'forty', 'fifty', 'sixty',
           'seventy', 'eighty', 'ninety']
              .contains(w.english))
      .toList();

  List<AwingWord> get _big => numbers
      .where((w) =>
          ['hundred', 'thousand'].contains(w.english))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_numbers');
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
        title: const Text('Numbers 11-100'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Teens'),
            Tab(text: 'Tens'),
            Tab(text: 'Big Numbers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeensTab(),
          _buildTensTab(),
          _buildBigNumbersTab(),
        ],
      ),
    );
  }

  Widget _buildTeensTab() {
    final teenNumbers = _teens;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern explanation
          Card(
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teens Pattern (11-19)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'In Awing, teens are formed by adding the base number after a prefix word. Tap each number to hear it!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Teen number list
          ...List.generate(teenNumbers.length, (index) {
            final word = teenNumbers[index];
            final digitValue = index + 11;
            final isSelected = _selectedIndex == index && _tabController.index == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NumberCard(
                digit: digitValue,
                word: word,
                isSelected: isSelected,
                color: Colors.orange,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _pronunciation.speakAwing(word.awing);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          // Count teens button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _countRange(teenNumbers, 0),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Count 11 to 19!', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTensTab() {
    final tenNumbers = _tens;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern explanation
          Card(
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tens Pattern (20-90)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tens in Awing use "məghə́m mén" (groups of) followed by the base number. Twenty and thirty have short forms!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tens list
          ...List.generate(tenNumbers.length, (index) {
            final word = tenNumbers[index];
            final digitValue = (index + 2) * 10; // 20, 30, 40, 50, ...
            final isSelected = _selectedIndex == index && _tabController.index == 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NumberCard(
                digit: digitValue,
                word: word,
                isSelected: isSelected,
                color: Colors.deepOrange,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  _pronunciation.speakAwing(word.awing);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          // Count tens button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _countRange(tenNumbers, 1),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Count by 10s!', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigNumbersTab() {
    final bigNumbers = _big;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big numbers intro
          Card(
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hundred & Thousand',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Learn the words for really big numbers in Awing!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Big number cards
          ...bigNumbers.map((word) {
            final digit = word.english == 'hundred' ? 100 : 1000;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _pronunciation.speakAwing(word.awing),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$digit',
                          style: const TextStyle(
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
                                word.awing,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                word.english,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
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
            );
          }),
          const SizedBox(height: 24),
          // Number system summary
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
                        'Number Patterns',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PatternRow(pattern: '11-19', rule: 'ntsəb + base number'),
                  const SizedBox(height: 8),
                  _PatternRow(pattern: '20, 30, 40', rule: 'mbá (short forms)'),
                  const SizedBox(height: 8),
                  _PatternRow(pattern: '50-90', rule: 'məghə́m mén + base'),
                  const SizedBox(height: 8),
                  _PatternRow(pattern: '100', rule: 'ŋgwú'),
                  const SizedBox(height: 8),
                  _PatternRow(pattern: '1000', rule: 'ntɛ̂'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _countRange(List<AwingWord> wordList, int tabIndex) async {
    _tabController.animateTo(tabIndex);
    for (int i = 0; i < wordList.length; i++) {
      if (!mounted) return;
      setState(() => _selectedIndex = i);
      await _pronunciation.speakAwing(wordList[i].awing);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }
}

class _NumberCard extends StatelessWidget {
  final int digit;
  final AwingWord word;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NumberCard({
    required this.digit,
    required this.word,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isSelected
                ? [color.withOpacity(0.8), color]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Number circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                '$digit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Word info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.awing,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
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
              color: isSelected ? Colors.white : color.withOpacity(0.6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  final String pattern;
  final String rule;

  const _PatternRow({required this.pattern, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            pattern,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            rule,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
