import 'package:flutter/material.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Beginner-level screen for learning Awing numbers 1-10.
class NumbersScreen extends StatefulWidget {
  const NumbersScreen({Key? key}) : super(key: key);

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Numbers'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Awing Numbers 1-10',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn to count in Awing! Tap each number to hear it spoken. Try counting along out loud!',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Number grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: numbers.length,
              itemBuilder: (context, index) {
                final word = numbers[index];
                final isSelected = _selectedIndex == index;
                final digitValue = index + 1;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _pronunciation.speakAwing(word.awing);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.green.shade50, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? Colors.green.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: isSelected ? 12 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Big digit
                        Text(
                          '$digitValue',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Awing word
                        Text(
                          word.awing,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // English
                        Text(
                          word.english,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // "Count along" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _countAloud,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Count 1 to 10!', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Fun facts
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
                          'Did you know?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Awing numbers use noun class prefixes (ə-). Most number words start with the ə- prefix, just like many other Awing nouns!',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _countAloud() async {
    for (int i = 0; i < numbers.length; i++) {
      if (!mounted) return;
      setState(() => _selectedIndex = i);
      await _pronunciation.speakAwing(numbers[i].awing);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }
}
