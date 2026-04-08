import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/screens/admin/review_screen.dart';

/// Developer Mode — full admin panel.
/// Only accessible when logged in as samagids@gmail.com.
/// Resets the 5-minute inactivity timer on every tab switch.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  @override
  void initState() {
    super.initState();
    // Reset timer on entry
    context.read<AuthService>().resetDevModeActivity();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // If dev mode was auto-disabled, pop back to home
    if (!auth.isDeveloper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Developer mode deactivated due to inactivity'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }

    return DefaultTabController(
      length: 5,
      child: Builder(builder: (ctx) {
        // Reset inactivity timer on every tab switch
        DefaultTabController.of(ctx).addListener(() {
          auth.resetDevModeActivity();
        });
        return Scaffold(
          appBar: AppBar(
            title: const Text('Developer Mode'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.greenAccent,
            actions: [
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Deactivate Developer Mode?'),
                      content: const Text(
                        'You will need to re-enter the access code and verify via email to reactivate.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            auth.disableDevMode();
                            Navigator.pop(ctx);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Developer mode deactivated'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: const Text('Deactivate'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text('Exit Dev', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.greenAccent,
              isScrollable: true,
              tabs: [
                Tab(text: 'Review', icon: Icon(Icons.rate_review)),
                Tab(text: 'Users', icon: Icon(Icons.people)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(text: 'Content', icon: Icon(Icons.edit_note)),
                Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ReviewTab(),
              _UsersTab(),
              _AnalyticsTab(),
              _ContentTab(),
              _SettingsTab(),
            ],
          ),
        );
      }),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionService>(
      builder: (context, service, _) {
        final pending = service.pendingContributions;
        final approved = service.approvedContributions;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              color: const Color(0xFF003d1f),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribution Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent.shade100,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(
                          label: 'Pending',
                          value: '${pending.length}',
                          color: Colors.orange,
                        ),
                        _StatBox(
                          label: 'Approved',
                          value: '${approved.length}',
                          color: Colors.green,
                        ),
                        _StatBox(
                          label: 'Total',
                          value: '${service.contributions.length}',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Open full review screen button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: Text(
                pending.isEmpty
                    ? 'Review Contributions'
                    : 'Review ${pending.length} Pending',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pending.isEmpty
                    ? Colors.grey.shade700
                    : const Color(0xFF006432),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent pending items preview
            if (pending.isNotEmpty) ...[
              Text(
                'Recent Pending',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 8),
              ...pending.take(5).map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        c.type == ContributionType.pronunciationFix
                            ? Icons.record_voice_over
                            : c.type == ContributionType.newWord
                                ? Icons.add_circle
                                : Icons.spellcheck,
                        color: Colors.orange,
                      ),
                      title: Text(c.targetWord),
                      subtitle: Text(
                        '${c.type.name} by ${c.profileName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: c.audioPath != null
                          ? const Icon(Icons.audiotrack, color: Colors.blue)
                          : null,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade200,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _UserStatBox(
                          label: 'Accounts',
                          value: '${accounts.length}',
                        ),
                        _UserStatBox(
                          label: 'Profiles',
                          value: '${auth.totalProfileCount}',
                        ),
                        _UserStatBox(
                          label: 'Beginner',
                          value: '${_countAtLevel(accounts, 'beginner')}',
                        ),
                        _UserStatBox(
                          label: 'Medium',
                          value: '${_countAtLevel(accounts, 'medium')}',
                        ),
                        _UserStatBox(
                          label: 'Expert',
                          value: '${_countAtLevel(accounts, 'expert')}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Account list
            ...accounts.map((account) => _AccountCard(account: account)),
          ],
        );
      },
    );
  }

  static int _countAtLevel(List<UserAccount> accounts, String level) {
    int count = 0;
    for (final a in accounts) {
      for (final p in a.profiles) {
        if (p.currentLevel == level) count++;
      }
    }
    return count;
  }
}

class _UserStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _UserStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final UserAccount account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          account.authMethod == 'google' ? Icons.g_mobiledata : Icons.email,
          color: account.isDeveloper ? Colors.greenAccent : null,
        ),
        title: Text(
          account.email,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: account.isDeveloper ? Colors.greenAccent : null,
          ),
        ),
        subtitle: Text(
          '${account.profiles.length} profiles | ${account.authMethod}',
        ),
        children: account.profiles.map((profile) {
          return ListTile(
            leading: Text(profile.avatarEmoji,
                style: const TextStyle(fontSize: 28)),
            title: Text(profile.displayName),
            subtitle: Text(
              'Level: ${profile.currentLevel} | '
              'XP: ${profile.totalXP} | '
              'Lessons: ${profile.lessonsCompleted.length} | '
              'Medium: ${profile.mediumUnlocked ? "✓" : "✗"} | '
              'Expert: ${profile.expertUnlocked ? "✓" : "✗"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                final auth = context.read<AuthService>();
                if (action == 'unlock_medium') {
                  auth.devUnlockLevel(profile.id, 'medium');
                } else if (action == 'unlock_expert') {
                  auth.devUnlockLevel(profile.id, 'expert');
                }
              },
              itemBuilder: (_) => [
                if (!profile.mediumUnlocked)
                  const PopupMenuItem(
                    value: 'unlock_medium',
                    child: Text('Unlock Medium'),
                  ),
                if (!profile.expertUnlocked)
                  const PopupMenuItem(
                    value: 'unlock_expert',
                    child: Text('Unlock Expert'),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();
        final allProfiles = accounts.expand((a) => a.profiles).toList();

        // Compute quiz stats
        final quizScores = <String, List<int>>{};
        for (final p in allProfiles) {
          for (final entry in p.quizBestScores.entries) {
            quizScores.putIfAbsent(entry.key, () => []);
            quizScores[entry.key]!.add(entry.value);
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AnalyticRow(
                      label: 'Total accounts',
                      value: '${accounts.length}',
                    ),
                    _AnalyticRow(
                      label: 'Total profiles',
                      value: '${allProfiles.length}',
                    ),
                    _AnalyticRow(
                      label: 'Total XP earned',
                      value: '${allProfiles.fold(0, (sum, p) => sum + p.totalXP)}',
                    ),
                    _AnalyticRow(
                      label: 'Total lessons completed',
                      value: '${allProfiles.fold(0, (sum, p) => sum + p.lessonsCompleted.length)}',
                    ),
                    _AnalyticRow(
                      label: 'Medium unlocked',
                      value: '${allProfiles.where((p) => p.mediumUnlocked).length}',
                    ),
                    _AnalyticRow(
                      label: 'Expert unlocked',
                      value: '${allProfiles.where((p) => p.expertUnlocked).length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Local Analytics card
            Card(
              color: Colors.indigo.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlueAccent.shade100,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Events logged: ${AnalyticsService.instance.totalEventCount}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All analytics data is stored locally on each device.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (quizScores.isNotEmpty) ...[
              const Text(
                'Quiz Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...quizScores.entries.map((entry) {
                final avg =
                    entry.value.reduce((a, b) => a + b) / entry.value.length;
                final max = entry.value.reduce((a, b) => a > b ? a : b);
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: Text(
                      'Avg: ${avg.toStringAsFixed(1)}% | '
                      'Best: $max% | '
                      'Taken: ${entry.value.length}x',
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

class _AnalyticRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Content Editor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Edit vocabulary, phrases, and lesson content.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _ContentCard(
          title: 'Vocabulary',
          subtitle: 'Edit words across all categories',
          icon: Icons.menu_book,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Content editor coming soon')),
            );
          },
        ),
        _ContentCard(
          title: 'Phrases',
          subtitle: 'Edit greetings and common phrases',
          icon: Icons.chat_bubble,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Content editor coming soon')),
            );
          },
        ),
        _ContentCard(
          title: 'Stories',
          subtitle: 'Edit story content and translations',
          icon: Icons.auto_stories,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Content editor coming soon')),
            );
          },
        ),
        _ContentCard(
          title: 'Audio Clips',
          subtitle: 'Manage pronunciation audio files',
          icon: Icons.audiotrack,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio manager coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ContentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF006432)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'App Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('Debug Info'),
            subtitle: const Text('Version 1.2.0 | Build 4'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: const Text(
                    'Awing AI Learning v1.2.0+4\n'
                    'Flutter SDK: 3.22+\n'
                    'Dart SDK: 3.4+\n'
                    'Auth: Local SharedPreferences\n'
                    'Exam: TCP sockets (port 9876)\n'
                    'TTS: Edge TTS (Swahili voices)',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.monitor, color: Colors.blue),
            title: const Text('Exam Monitor'),
            subtitle: const Text('View active exam sessions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exam monitor coming soon')),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Export Data'),
            subtitle: const Text('Export all user data as JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export coming soon')),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Security',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Deactivate Developer Mode'),
            subtitle: const Text('Auto-disables after 5 min of inactivity'),
            trailing: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () {
              final auth = context.read<AuthService>();
              auth.disableDevMode();
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Developer mode deactivated'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
