import 'package:flutter/material.dart';
import 'package:awing_ai_learning/screens/medium/clusters_screen.dart';
import 'package:awing_ai_learning/screens/medium/vowels_screen.dart';
import 'package:awing_ai_learning/screens/medium/noun_classes_screen.dart';
import 'package:awing_ai_learning/screens/medium/sentences_screen.dart';
import 'package:awing_ai_learning/screens/medium/writing_quiz_screen.dart';
import 'package:awing_ai_learning/screens/medium/numbers_medium_screen.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_screen.dart';
import 'package:awing_ai_learning/screens/games/medium_sentence_build.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

class MediumHome extends StatefulWidget {
  const MediumHome({Key? key}) : super(key: key);

  @override
  State<MediumHome> createState() => _MediumHomeState();
}

class _MediumHomeState extends State<MediumHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('medium', alternate: _isFemaleVoice);
  }

  void _toggleVoice(bool female) {
    setState(() {
      _isFemaleVoice = female;
    });
    _pronunciation.setVoiceForLevel('medium', alternate: female);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medium'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text(
                      'Voice:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _VoiceOption(
                      label: 'Young Man',
                      icon: Icons.face,
                      selected: !_isFemaleVoice,
                      color: Colors.orange,
                      onTap: () => _toggleVoice(false),
                    ),
                    const SizedBox(width: 8),
                    _VoiceOption(
                      label: 'Young Woman',
                      icon: Icons.face_3,
                      selected: _isFemaleVoice,
                      color: Colors.orange,
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
              title: 'Short Sentences',
              subtitle: 'Learn everyday Awing sentences',
              icon: Icons.short_text,
              color: Colors.orange.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SentencesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Consonant Clusters',
              subtitle: 'Prenasalized, palatalized & labialized sounds',
              icon: Icons.record_voice_over,
              color: const Color(0xFFFF9800),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClustersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Vowels & Syllables',
              subtitle: '9 vowels, long vowels & syllable types',
              icon: Icons.circle_outlined,
              color: Colors.orange.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VowelsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Noun Classes',
              subtitle: 'Singular & plural patterns',
              icon: Icons.category,
              color: Colors.orange.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NounClassesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Sentence Building',
              subtitle: 'Build your own Awing sentences',
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFEF6C00),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SentencesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Difficult Words',
              subtitle: 'Learn more challenging vocabulary',
              icon: Icons.menu_book,
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Numbers 11-100',
              subtitle: 'Teens, tens & big numbers',
              icon: Icons.pin,
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumbersMediumScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Writing Quiz',
              subtitle: 'Fill in the blank sentences',
              icon: Icons.edit_note,
              color: Colors.orange.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WritingQuizScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Games',
              subtitle: 'Sentence Build - arrange words in order',
              icon: Icons.extension,
              color: Colors.orange.shade800,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediumSentenceBuild()),
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
