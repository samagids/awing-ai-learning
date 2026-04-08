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
import 'dart:convert';
import 'dart:io';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/main.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _versionTapCount = 0;

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
                      icon: const Icon(Icons.cloud_outlined),
                      tooltip: 'Cloud Backup',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BackupScreen(),
                        ),
                      ),
                    ),
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
                      onPressed: () async {
                        final ok = await ParentalGate.verify(
                          context,
                          title: 'Switch Profile',
                          message: 'Only a parent or guardian should switch profiles.',
                        );
                        if (ok && context.mounted) {
                          auth.switchProfile();
                        }
                      },
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
                    IconButton(
                      icon: const Icon(Icons.brightness_6),
                      tooltip: 'Dark Mode',
                      onPressed: () {
                        context.read<ThemeNotifier>().toggle();
                      },
                    ),
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
                        onTap: () {
                          if (!auth.isLevelUnlocked('medium')) {
                            _showLockedDialog(context, 'Medium',
                                'Complete all Beginner lessons and score 90% on the quiz to unlock Medium.');
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
              child: GestureDetector(
                onTap: () {
                  _versionTapCount++;
                  if (_versionTapCount >= 5 && !auth.isDeveloper) {
                    _versionTapCount = 0;
                    _showDevModeDialog(context, auth);
                  } else if (_versionTapCount >= 5 && auth.isDeveloper) {
                    _versionTapCount = 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Developer mode is already active')),
                    );
                  } else if (_versionTapCount >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${5 - _versionTapCount} more taps...'),
                        duration: const Duration(milliseconds: 500),
                      ),
                    );
                  }
                },
              child: Text(
                'Version 1.2.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            ),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  /// Load the analytics webhook URL from bundled config.
  Future<String?> _getAnalyticsWebhookUrl() async {
    try {
      final jsonStr = await rootBundle.loadString('config/webhooks.json');
      final config = jsonDecode(jsonStr) as Map<String, dynamic>;
      return config['analytics_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Send a 6-digit verification code to the developer's Gmail via webhook.
  /// Google Apps Script returns 302 redirects — Dart's HttpClient converts
  /// POST→GET on redirect, losing the body. We must follow redirects manually.
  Future<bool> _sendDevVerificationEmail(String code) async {
    final webhookUrl = await _getAnalyticsWebhookUrl();
    if (webhookUrl == null) return false;

    final payload = jsonEncode({
      'action': 'send_dev_code',
      'code': code,
      'email': 'samagids@gmail.com',
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Step 1: POST the payload — Apps Script processes it and returns 302
      final postRequest = await client.postUrl(Uri.parse(webhookUrl));
      postRequest.followRedirects = false;
      postRequest.headers.contentType = ContentType.json;
      postRequest.write(payload);
      final postResponse = await postRequest.close();

      debugPrint('Webhook POST: ${postResponse.statusCode}');

      // Step 2: Follow 302 redirect with GET to read the response
      if (postResponse.statusCode == 302 || postResponse.statusCode == 301) {
        await postResponse.drain<void>();
        final location = postResponse.headers.value('location');
        if (location == null) {
          client.close();
          debugPrint('Webhook error: redirect with no location header');
          return false;
        }
        debugPrint('Webhook redirect to: ${location.substring(0, 80)}...');

        // Follow redirect chain with GET (googleusercontent serves the response)
        var getUri = Uri.parse(location);
        for (int i = 0; i < 5; i++) {
          final getRequest = await client.getUrl(getUri);
          getRequest.followRedirects = false;
          final getResponse = await getRequest.close();

          if (getResponse.statusCode == 302 || getResponse.statusCode == 301) {
            await getResponse.drain<void>();
            final nextLocation = getResponse.headers.value('location');
            if (nextLocation == null) break;
            getUri = Uri.parse(nextLocation);
            continue;
          }

          final body = await getResponse.transform(utf8.decoder).join();
          client.close();
          debugPrint('Webhook response: ${getResponse.statusCode} $body');
          final result = jsonDecode(body);
          return result['status'] == 'ok';
        }
      } else {
        // No redirect — read directly
        final body = await postResponse.transform(utf8.decoder).join();
        client.close();
        debugPrint('Webhook response (no redirect): ${postResponse.statusCode} $body');
        final result = jsonDecode(body);
        return result['status'] == 'ok';
      }

      client.close();
      debugPrint('Webhook error: could not get response after redirects');
      return false;
    } catch (e) {
      debugPrint('Webhook error: $e');
      return false;
    }
  }

  void _showDevModeDialog(BuildContext context, AuthService auth) {
    // Step 1: Must be signed in with the developer Gmail
    if (!auth.isDeveloperEmail) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.red),
              SizedBox(width: 8),
              Text('Access Denied'),
            ],
          ),
          content: const Text(
            'Developer Mode is only available for the designated developer account. '
            'Sign in with the developer Google account to access this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Step 2: Enter access code
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: Colors.grey),
            SizedBox(width: 8),
            Text('Developer Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 1 of 2: Enter the developer access code.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text == 'awing2026') {
                Navigator.pop(ctx);
                _startDevMode2FA(context, auth);
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid access code'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  /// Step 3: Send verification code to developer Gmail and show input dialog.
  void _startDevMode2FA(BuildContext context, AuthService auth) async {
    // Generate and store code
    final code = auth.generateDevVerificationCode();

    // Show loading dialog while sending email
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Sending verification code to your Gmail...')),
          ],
        ),
      ),
    );

    // Send code via webhook — must succeed for security
    final sent = await _sendDevVerificationEmail(code);

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send verification email. Check internet connection and webhook deployment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show code entry dialog
    final verifyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Email Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 2 of 2: A 6-digit code was sent to your Gmail. '
              'Enter it below to activate Developer Mode.',
            ),
            const SizedBox(height: 8),
            Text(
              'Code expires in 10 minutes.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verifyController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final error = auth.verifyDevCode(verifyController.text);
              Navigator.pop(ctx);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer mode activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherSetupScreen()),
              );
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

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
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
          child: Row(
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
        ),
      ),
    );
  }
}
