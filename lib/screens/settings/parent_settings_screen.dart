import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Settings screen for parents to manage WhatsApp notifications,
/// update their contact info, and send test/weekly summary messages.
class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _whatsappController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<AuthService>().currentAccount;
    _nameController = TextEditingController(text: account?.parentName ?? '');
    _whatsappController = TextEditingController(text: account?.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _save() {
    final auth = context.read<AuthService>();
    auth.updateParentName(_nameController.text);
    auth.updateWhatsAppNumber(_whatsappController.text);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final account = auth.currentAccount;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Parent Settings')),
            body: const Center(child: Text('Not logged in')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Parent Settings'),
            centerTitle: true,
            backgroundColor: const Color(0xFF006432),
            foregroundColor: Colors.white,
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contact info card
                _SectionCard(
                  title: 'Your Contact Info',
                  icon: Icons.person,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() => _hasChanges = true),
                        decoration: InputDecoration(
                          labelText: 'Parent Name',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() => _hasChanges = true),
                        decoration: InputDecoration(
                          labelText: 'WhatsApp Number',
                          hintText: '+237 6XX XXX XXX',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          helperText:
                              'Include country code (e.g. +237 for Cameroon)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notification preferences
                _SectionCard(
                  title: 'Notification Preferences',
                  icon: Icons.notifications,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Quiz Notifications'),
                        subtitle: const Text(
                          'Receive a WhatsApp message each time your child finishes a quiz',
                        ),
                        value: account.sendQuizNotifications,
                        onChanged: account.hasWhatsApp
                            ? (v) => auth.setQuizNotifications(v)
                            : null,
                        activeColor: const Color(0xFF006432),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Weekly Summary'),
                        subtitle: const Text(
                          'Get a weekly report of lessons, quizzes, and streaks',
                        ),
                        value: account.sendWeeklySummary,
                        onChanged: account.hasWhatsApp
                            ? (v) => auth.setWeeklySummary(v)
                            : null,
                        activeColor: const Color(0xFF006432),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (!account.hasWhatsApp) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add your WhatsApp number above to enable notifications',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                if (account.hasWhatsApp) ...[
                  _SectionCard(
                    title: 'Actions',
                    icon: Icons.send,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.send, color: Colors.green.shade700),
                          title: const Text('Send Test Message'),
                          subtitle: const Text(
                            'Send a test message to verify your WhatsApp number',
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            final notifier =
                                context.read<ParentNotificationService>();
                            final childName =
                                auth.currentProfile?.displayName ?? 'Test Child';
                            final sent = await notifier.notifyQuizCompleted(
                              childName: childName,
                              quizName: 'Test Quiz',
                              score: 85,
                              totalQuestions: 20,
                              correctAnswers: 17,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(sent
                                      ? 'Opening WhatsApp...'
                                      : 'Could not open WhatsApp. Message queued.'),
                                  backgroundColor:
                                      sent ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading:
                              Icon(Icons.summarize, color: Colors.blue.shade700),
                          title: const Text('Send Weekly Summary Now'),
                          subtitle: const Text(
                            'Send this week\'s activity report right now',
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            final notifier =
                                context.read<ParentNotificationService>();
                            final sent = await notifier.sendWeeklySummary();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(sent
                                      ? 'Opening WhatsApp with weekly summary...'
                                      : 'Could not send summary. Try again later.'),
                                  backgroundColor:
                                      sent ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Pending messages
                Builder(
                  builder: (context) {
                    final notifier = context.read<ParentNotificationService>();
                    if (notifier.pendingMessageCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return _SectionCard(
                      title: 'Pending Messages',
                      icon: Icons.schedule_send,
                      child: Column(
                        children: [
                          Text(
                            '${notifier.pendingMessageCount} message(s) waiting to be sent.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final sent =
                                        await notifier.flushPendingMessages();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Sent $sent message(s)'),
                                        ),
                                      );
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  notifier.clearPendingMessages();
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Queue cleared')),
                                  );
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Info footer
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Messages are sent via WhatsApp on this device. '
                    'No data is stored on any server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF006432)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
