import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/screens/settings/backup_screen.dart';

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
    // Validate WhatsApp number if provided
    final phone = _whatsappController.text.trim();
    if (phone.isNotEmpty) {
      // Strip spaces and dashes for validation
      final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      // Must start with + and country code, then digits (7-15 digits total)
      if (!RegExp(r'^\+\d{7,15}$').hasMatch(cleaned)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid phone number with country code (e.g. +237 6XX XXX XXX)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthService>();
    auth.updateParentName(_nameController.text);
    auth.updateWhatsAppNumber(phone);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== Parent Controls ====================

  /// Show a dialog to set or change the parent PIN.
  /// PIN must be at least 6 digits.
  Future<void> _showPinSetupDialog(AuthService auth, bool isChange) async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isChange ? 'Change Parent PIN' : 'Set Parent PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isChange
                          ? 'Enter your current PIN, then choose a new 6+ digit PIN.'
                          : 'Choose a 6+ digit PIN. You\'ll need it to reset your child\'s progress.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isChange) ...[
                      TextField(
                        controller: currentPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Current PIN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'New PIN (6+ digits)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Confirm new PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006432),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();

                    if (isChange) {
                      final currentPin = currentPinController.text.trim();
                      if (!auth.verifyAccountPin(currentPin)) {
                        setDialogState(() {
                          errorText = 'Current PIN is incorrect.';
                        });
                        return;
                      }
                    }
                    if (newPin.length < 6) {
                      setDialogState(() {
                        errorText = 'PIN must be at least 6 digits.';
                      });
                      return;
                    }
                    if (newPin != confirmPin) {
                      setDialogState(() {
                        errorText = 'PINs do not match.';
                      });
                      return;
                    }
                    auth.setAccountPin(newPin);
                    Navigator.pop(ctx, true);
                  },
                  child: Text(isChange ? 'Change PIN' : 'Set PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isChange ? 'Parent PIN updated' : 'Parent PIN set'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Verify the parent PIN and, on success, confirm + reset child progress.
  Future<void> _showResetFlow(AuthService auth) async {
    final profile = auth.currentProfile;
    if (profile == null) return;

    // If no PIN is set, require the parent to set one first.
    if (!auth.hasAccountPin) {
      final setNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Parent PIN First'),
          content: const Text(
            'You need a parent PIN before resetting a child\'s progress. '
            'Would you like to set one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006432),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set PIN'),
            ),
          ],
        ),
      );
      if (setNow != true || !mounted) return;
      await _showPinSetupDialog(auth, false);
      if (!auth.hasAccountPin) return;
    }

    // Verify the PIN.
    final pinController = TextEditingController();
    String? pinError;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Parent PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your parent PIN to reset ${profile.displayName}\'s progress.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Parent PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (pinError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      pinError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (auth.verifyAccountPin(pinController.text.trim())) {
                      Navigator.pop(ctx, true);
                    } else {
                      setDialogState(() {
                        pinError = 'Incorrect PIN.';
                      });
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
    pinController.dispose();
    if (verified != true || !mounted) return;

    // Destructive confirmation — require typing RESET.
    final confirmController = TextEditingController();
    String? confirmError;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Reset Progress?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will wipe ${profile.displayName}\'s XP, completed '
                    'lessons, quiz scores, streaks, badges, and level unlocks. '
                    'This cannot be undone.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type RESET to confirm:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'RESET',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (confirmError != null) {
                        setDialogState(() {
                          confirmError = null;
                        });
                      }
                    },
                  ),
                  if (confirmError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      confirmError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (confirmController.text.trim().toUpperCase() ==
                        'RESET') {
                      Navigator.pop(ctx, true);
                    } else {
                      setDialogState(() {
                        confirmError = 'Please type RESET exactly.';
                      });
                    }
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();
    if (confirmed != true || !mounted) return;

    // Perform the reset.
    auth.resetProfileProgress(profile.id);
    await context.read<ProgressService>().resetChildProgress();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.displayName}\'s progress has been reset.'),
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

                // Parent Controls — PIN + reset child progress
                _SectionCard(
                  title: 'Parent Controls',
                  icon: Icons.shield_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protect settings with a parent PIN and reset your child\'s learning progress when needed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Icon(
                          account.hasAccountPin
                              ? Icons.lock
                              : Icons.lock_open_outlined,
                          color: account.hasAccountPin
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                        title: Text(
                          account.hasAccountPin
                              ? 'Change Parent PIN'
                              : 'Set Parent PIN',
                        ),
                        subtitle: Text(
                          account.hasAccountPin
                              ? 'PIN is set — required to reset progress.'
                              : 'No PIN set — tap to create one.',
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _showPinSetupDialog(auth, account.hasAccountPin),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.restart_alt,
                          color: Colors.red.shade700,
                        ),
                        title: const Text(
                          'Reset Child Progress',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          auth.currentProfile == null
                              ? 'No profile selected.'
                              : 'Wipe ${auth.currentProfile!.displayName}\'s XP, lessons, quizzes, and level unlocks.',
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: auth.currentProfile == null
                            ? null
                            : () => _showResetFlow(auth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cloud Backup
                _SectionCard(
                  title: 'Cloud Backup',
                  icon: Icons.cloud_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Back up profiles and progress to Google Drive so data is safe if the app is reinstalled.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BackupScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.cloud_outlined),
                          label: const Text('Manage Cloud Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
