import 'package:flutter/material.dart';
import 'package:awing_ai_learning/screens/beginner/alphabet_screen.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_screen.dart';
import 'package:awing_ai_learning/screens/beginner/quiz_screen.dart';
import 'package:awing_ai_learning/screens/beginner/tone_screen.dart';
import 'package:awing_ai_learning/screens/beginner/pronunciation_screen.dart';
import 'package:awing_ai_learning/screens/beginner/phrases_screen.dart';
import 'package:awing_ai_learning/screens/beginner/numbers_screen.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

class BeginnerHome extends StatefulWidget {
  const BeginnerHome({Key? key}) : super(key: key);

  @override
  State<BeginnerHome> createState() => _BeginnerHomeState();
}

class _BeginnerHomeState extends State<BeginnerHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('beginner', alternate: _isFemaleVoice);
  }

  void _toggleVoice(bool female) {
    setState(() {
      _isFemaleVoice = female;
    });
    _pronunciation.setVoiceForLevel('beginner', alternate: female);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beginner'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text(
                      'Voice:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _VoiceOption(
                      label: 'Boy',
                      icon: Icons.face,
                      selected: !_isFemaleVoice,
                      color: Colors.green,
                      onTap: () => _toggleVoice(false),
                    ),
                    const SizedBox(width: 8),
                    _VoiceOption(
                      label: 'Girl',
                      icon: Icons.face_3,
                      selected: _isFemaleVoice,
                      color: Colors.green,
                      onTap: () => _toggleVoice(true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a lesson:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _LessonTile(
              title: 'Alphabet',
              subtitle: 'Learn the 22 consonants and 9 vowels',
              icon: Icons.abc,
              color: Colors.green.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlphabetScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Vocabulary',
              subtitle: 'Learn common Awing words',
              icon: Icons.menu_book,
              color: Colors.green.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Tones',
              subtitle: 'Hear how tone changes meaning',
              icon: Icons.music_note,
              color: Colors.green.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ToneScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Numbers',
              subtitle: 'Learn to count 1-10 in Awing',
              icon: Icons.looks_one,
              color: const Color(0xFF66BB6A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumbersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Phrases & Greetings',
              subtitle: 'Say hello, ask questions & more',
              icon: Icons.chat,
              color: const Color(0xFF43A047),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhrasesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Pronunciation',
              subtitle: 'Practice speaking Awing words',
              icon: Icons.mic,
              color: const Color(0xFF388E3C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PronunciationScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Quiz',
              subtitle: 'Test what you have learned!',
              icon: Icons.quiz,
              color: Colors.green.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VoiceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LessonTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 28,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
