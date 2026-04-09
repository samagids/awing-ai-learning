import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';

/// Cloud backup & sync settings screen.
/// Allows users to connect their Google account, back up, restore,
/// and toggle auto-sync.
class BackupScreen extends StatelessWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CloudBackupService>(
      builder: (context, backup, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Backup'),
            centerTitle: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Google Drive connection card
                _ConnectionCard(backup: backup),
                const SizedBox(height: 20),

                // Backup actions (only if signed in)
                if (backup.isSignedIn) ...[
                  _BackupActionsCard(backup: backup),
                  const SizedBox(height: 20),
                  _SyncSettingsCard(backup: backup),
                  const SizedBox(height: 20),
                  _BackupInfoCard(backup: backup),
                ],

                // Error display
                if (backup.syncError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Something went wrong with the backup. Please try again later.',
                            style: TextStyle(
                              color: Colors.red.shade700,
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
        );
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final CloudBackupService backup;
  const _ConnectionCard({required this.backup});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              backup.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
              size: 48,
              color: backup.isSignedIn ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              backup.isSignedIn ? 'Connected to Google Drive' : 'Not Connected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: backup.isSignedIn
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
            ),
            if (backup.connectedEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                backup.connectedEmail!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 16),
            if (backup.isSignedIn)
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Disconnect?'),
                      content: const Text(
                        'Auto-sync will stop. Your data on Google Drive will not be deleted.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await backup.signOut();
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => backup.signIn(),
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                label: const Text('Connect Google Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackupActionsCard extends StatelessWidget {
  final CloudBackupService backup;
  const _BackupActionsCard({required this.backup});

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
            Text(
              'Backup & Restore',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your data is stored securely in your Google Drive app folder.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: backup.isSyncing
                        ? null
                        : () async {
                            final success = await backup.backupAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Backup complete!'
                                        : 'Backup failed',
                                  ),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                    icon: backup.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(backup.isSyncing ? 'Syncing...' : 'Backup Now'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: backup.isSyncing
                        ? null
                        : () => _confirmRestore(context, backup),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context, CloudBackupService backup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Cloud?'),
        content: const Text(
          'This will replace all local data with your cloud backup. '
          'Any local changes not yet backed up will be lost.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Safety: backup current data first so nothing is lost
              await backup.backupAll();
              final success = await backup.restoreAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Restore complete! Restart the app to see changes.'
                          : 'Restore failed. Your current data was backed up first.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _SyncSettingsCard extends StatelessWidget {
  final CloudBackupService backup;
  const _SyncSettingsCard({required this.backup});

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
            Text(
              'Sync Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-sync'),
              subtitle: const Text(
                'Automatically back up after quizzes and lesson completion',
              ),
              value: backup.autoSync,
              onChanged: (v) => backup.setAutoSync(v),
              activeColor: Colors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupInfoCard extends StatelessWidget {
  final CloudBackupService backup;
  const _BackupInfoCard({required this.backup});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What gets backed up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.people,
              label: 'User accounts & profiles',
            ),
            _InfoRow(
              icon: Icons.trending_up,
              label: 'Lesson progress & quiz scores',
            ),
            _InfoRow(
              icon: Icons.star,
              label: 'XP, streaks, badges & spaced repetition',
            ),
            _InfoRow(
              icon: Icons.quiz,
              label: 'Exam history & results',
            ),
            _InfoRow(
              icon: Icons.settings,
              label: 'App settings & preferences',
            ),
            const SizedBox(height: 12),
            if (backup.lastBackupTime != null) ...[
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    'Last backup: ${_formatTime(backup.lastBackupTime!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo.shade300),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
