import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/screens/beginner/beginner_home.dart';
import 'package:awing_ai_learning/screens/medium/medium_home.dart';
import 'package:awing_ai_learning/screens/expert/expert_home.dart';
import 'package:awing_ai_learning/screens/profile_screen.dart';
import 'package:awing_ai_learning/screens/stories_screen.dart';
import 'package:awing_ai_learning/screens/exam/teacher_setup_screen.dart';
import 'package:awing_ai_learning/screens/exam/student_join_screen.dart';
import 'package:awing_ai_learning/screens/admin/developer_screen.dart';
import 'package:awing_ai_learning/screens/settings/feedback_screen.dart';
import 'package:awing_ai_learning/screens/settings/parent_settings_screen.dart';
import 'package:awing_ai_learning/screens/settings/backup_screen.dart';
import 'package:awing_ai_learning/screens/contribute/contribute_screen.dart';
import 'package:awing_ai_learning/components/parental_gate.dart';
import 'package:awing_ai_learning/screens/about_screen.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SizedBox(height: 16),
            // Title row with icon buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 44,
                              height: 44,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Awing',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006432),
                            ),
                          ),
                        ],
                      ),
                      if (profile != null)
                        Text(
                          'Hi, ${profile.displayName}! ${profile.avatarEmoji}',
                          style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFFDAA520),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Learn a Language!',
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color(0xFFDAA520),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person),
                      tooltip: 'Profile',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Switch Profile',
                      onPressed: () => auth.switchProfile(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.family_restroom),
                      tooltip: 'Parent Settings',
                      onPressed: () async {
                        final ok = await ParentalGate.verify(
                          context,
                          title: 'Parent Settings',
                          message: 'Only a parent or guardian should change settings.',
                        );
                        if (ok && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentSettingsScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    // Dark mode toggle hidden in v1.2.1 — re-enable after
                    // completing full dark-mode color audit across all screens.
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Spoken by 19,000 people in Cameroon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            // Progress summary
            Consumer<ProgressService>(
              builder: (context, progress, _) {
                final hasStreak = progress.dailyStreak > 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level ${progress.level} • ${progress.xp} XP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006432),
                          ),
                        ),
                        if (hasStreak) ...[
                          const SizedBox(width: 12),
                          Text(
                            '🔥 ${progress.dailyStreak}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.xpToNextLevel > 0
                            ? progress.xpInCurrentLevel / progress.xpToNextLevel
                            : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFDAA520),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Mode selection cards
            Column(
              children: [
                      // Beginner — always unlocked
                      _ModeCard(
                        title: 'Beginner',
                        subtitle: 'Alphabet, basic words & tones',
                        icon: Icons.child_care,
                        color: Colors.green,
                        locked: false,
                        onTap: () {
                          context.read<ProgressService>().markDifficultyLevelTried('Beginner');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'beginner',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BeginnerHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Medium — locked until beginner complete
                      _ModeCard(
                        title: 'Medium',
                        subtitle: 'Grammar, sentences & clusters',
                        icon: Icons.school,
                        color: Colors.orange,
                        locked: !auth.isLevelUnlocked('medium'),
                        progressWidget: (!auth.isLevelUnlocked('medium') && profile != null)
                            ? _UnlockProgress(
                                lessonsCompleted: profile.beginnerLessonsCompleted(),
                                totalLessons: UserProfile.beginnerLessonIds.length,
                                quizzesPassed: profile.beginnerQuizzesPassed(),
                                totalQuizzes: UserProfile.beginnerQuizIds.length,
                              )
                            : null,
                        onTap: () {
                          if (!auth.isLevelUnlocked('medium')) {
                            _showLockedDialog(context, 'Medium',
                                'Complete all Beginner lessons and score 90% on all 10 quizzes to unlock Medium.');
                            return;
                          }
                          context.read<ProgressService>().markDifficultyLevelTried('Medium');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'medium',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MediumHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Expert — locked until medium complete
                      _ModeCard(
                        title: 'Expert',
                        subtitle: 'Tone mastery, elision & conversations',
                        icon: Icons.emoji_events,
                        color: Colors.red,
                        locked: !auth.isLevelUnlocked('expert'),
                        progressWidget: (!auth.isLevelUnlocked('expert') && auth.isLevelUnlocked('medium') && profile != null)
                            ? _UnlockProgress(
                                lessonsCompleted: profile.mediumLessonsCompleted(),
                                totalLessons: UserProfile.mediumLessonIds.length,
                                quizzesPassed: profile.mediumQuizzesPassed(),
                                totalQuizzes: UserProfile.mediumQuizIds.length,
                              )
                            : null,
                        onTap: () {
                          if (!auth.isLevelUnlocked('expert')) {
                            _showLockedDialog(context, 'Expert',
                                'Complete all Medium lessons and score 90% on the writing quiz to unlock Expert.');
                            return;
                          }
                          context.read<ProgressService>().markDifficultyLevelTried('Expert');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'expert',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpertHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Stories — always available
                      _ModeCard(
                        title: 'Stories',
                        subtitle: 'Read & listen to Awing stories',
                        icon: Icons.auto_stories,
                        color: Colors.teal,
                        locked: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoriesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Contribute — anyone can submit corrections
                      _ModeCard(
                        title: 'Contribute',
                        subtitle: 'Fix a word, record pronunciation',
                        icon: Icons.volunteer_activism,
                        color: const Color(0xFF006432),
                        locked: false,
                        onTap: () {
                          AnalyticsService.instance.logActivity(
                            event: 'open_contribute',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContributeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Exam Mode
                      _ModeCard(
                        title: 'Exam',
                        subtitle: 'Take or create an exam',
                        icon: Icons.quiz,
                        color: Colors.indigo,
                        locked: false,
                        onTap: () => _showExamRoleDialog(context),
                      ),
                      // Developer Mode — hidden unless developer account
                      if (auth.isDeveloper) ...[
                        const SizedBox(height: 12),
                        _ModeCard(
                          title: 'Developer',
                          subtitle: 'Admin panel & app settings',
                          icon: Icons.code,
                          color: Colors.grey.shade800,
                          locked: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeveloperScreen(),
                              ),
                            );
                          },
                        ),
                      ],
              const SizedBox(height: 8),
            ],
            ),
            const SizedBox(height: 12),
            // About button
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
                icon: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                label: Text(
                  'About',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Developer credit
            Center(
              child: Text(
                'By Dr. Guidion Sama, DIT',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Version ${AboutScreen.appVersion}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String level, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            Text('$level Locked'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExamRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Mode'),
        content: const Text('Are you a teacher creating an exam, or a student joining one?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentJoinScreen()),
              );
            },
            child: const Text('Student'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Only parents/teachers should set up exams
              final ok = await ParentalGate.verify(
                context,
                title: 'Teacher Mode',
                message: 'Only a parent or teacher should set up exams.',
              );
              if (ok && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherSetupScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Teacher'),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;
  final Widget? progressWidget;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
    this.progressWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: locked ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: locked
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 48, color: Colors.white.withOpacity(locked ? 0.6 : 1)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(locked ? 0.7 : 1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(locked ? 0.5 : 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock : Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(locked ? 0.6 : 1),
                  ),
                ],
              ),
              if (progressWidget != null) ...[
                const SizedBox(height: 12),
                progressWidget!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows lesson and quiz progress toward unlocking the next level.
class _UnlockProgress extends StatelessWidget {
  final int lessonsCompleted;
  final int totalLessons;
  final int quizzesPassed;
  final int totalQuizzes;

  const _UnlockProgress({
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.quizzesPassed,
    required this.totalQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    final lessonsDone = lessonsCompleted >= totalLessons;
    final quizzesDone = quizzesPassed >= totalQuizzes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            lessonsDone ? Icons.check_circle : Icons.menu_book,
            size: 16,
            color: lessonsDone ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            'Lessons $lessonsCompleted/$totalLessons',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: lessonsDone ? Colors.greenAccent : Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            quizzesDone ? Icons.check_circle : Icons.quiz,
            size: 16,
            color: quizzesDone ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            'Quizzes $quizzesPassed/$totalQuizzes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: quizzesDone ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
