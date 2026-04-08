import 'package:flutter/material.dart';
import 'package:awing_ai_learning/screens/expert/tone_mastery_screen.dart';
import 'package:awing_ai_learning/screens/expert/allophones_screen.dart';
import 'package:awing_ai_learning/screens/expert/elision_screen.dart';
import 'package:awing_ai_learning/screens/expert/conversation_screen.dart';
import 'package:awing_ai_learning/screens/expert/expert_quiz_screen.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

class ExpertHome extends StatefulWidget {
  const ExpertHome({Key? key}) : super(key: key);

  @override
  State<ExpertHome> createState() => _ExpertHomeState();
}

class _ExpertHomeState extends State<ExpertHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('expert', alternate: _isFemaleVoice);
  }

  void _toggleVoice(bool female) {
    setState(() {
      _isFemaleVoice = female;
    });
    _pronunciation.setVoiceForLevel('expert', alternate: female);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.red),
                    const SizedBox(width: 12),
                    const Text(
                      'Voice:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _VoiceOption(
                      label: 'Man',
                      icon: Icons.face,
                      selected: !_isFemaleVoice,
                      color: Colors.red,
                      onTap: () => _toggleVoice(false),
                    ),
                    const SizedBox(width: 8),
                    _VoiceOption(
                      label: 'Woman',
                      icon: Icons.face_3,
                      selected: _isFemaleVoice,
                      color: Colors.red,
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
              title: 'Tone Mastery',
              subtitle: 'Advanced tone patterns in sentences',
              icon: Icons.graphic_eq,
              color: Colors.red.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ToneMasteryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Sound Changes',
              subtitle: 'How consonants change in different positions',
              icon: Icons.swap_horiz,
              color: const Color(0xFFE53935),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllophonesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Elision Rules',
              subtitle: 'Long/short forms & vowel dropping',
              icon: Icons.edit,
              color: Colors.red.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ElisionScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Conversation',
              subtitle: 'Real Awing dialogues',
              icon: Icons.chat_bubble,
              color: Colors.red.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Expert Quiz',
              subtitle: 'The ultimate Awing challenge!',
              icon: Icons.emoji_events,
              color: Colors.red.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertQuizScreen()),
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
