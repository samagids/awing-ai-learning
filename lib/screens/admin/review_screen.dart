import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';

/// Developer review screen — shows all user contributions
/// with approve/reject workflow. Fully local, no backend.
///
/// Flow:
/// 1. Developer taps "Import" to load a JSON file received from users
/// 2. Reviews each contribution (listen to audio, read corrections)
/// 3. Approves or rejects
/// 4. Taps "Export Approved" → shares JSON via platform share
/// 5. Places the JSON in the project's contributions/ folder
/// 6. Runs build_and_run.bat to apply changes and rebuild the APK
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _importContributions() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      int totalImported = 0;
      final service = context.read<ContributionService>();

      for (final file in result.files) {
        if (file.path == null) continue;
        final count = await service.importFromFile(file.path!);
        totalImported += count;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $totalImported new contributions'),
            backgroundColor: totalImported > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }

      final count = await context
          .read<ContributionService>()
          .importFromJson(data.text!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Imported $count contributions from clipboard'
                : 'No new contributions found in clipboard'),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportApproved() async {
    final service = context.read<ContributionService>();
    if (service.approvedContributions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved contributions to export')),
      );
      return;
    }

    await service.shareApproved();
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_open, color: const Color(0xFF006432)),
              title: const Text('Import from JSON file'),
              subtitle: const Text('Pick a .json contribution file'),
              onTap: () {
                Navigator.pop(ctx);
                _importContributions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste, color: const Color(0xFF006432)),
              title: const Text('Import from clipboard'),
              subtitle: const Text('Paste JSON text from clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                _importFromClipboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Contributions'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003d1f),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showImportMenu,
            tooltip: 'Import contributions',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _exportApproved,
            tooltip: 'Export approved',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Consumer<ContributionService>(
        builder: (context, service, _) {
          final pending = service.contributions
              .where((c) => c.status == ContributionStatus.pending)
              .toList();
          final approved = service.contributions
              .where((c) => c.status == ContributionStatus.approved)
              .toList();
          final rejected = service.contributions
              .where((c) => c.status == ContributionStatus.rejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, showActions: true),
              _buildApprovedList(approved),
              _buildList(rejected),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Contribution> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No contributions here',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            if (showActions) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showImportMenu,
                icon: const Icon(Icons.file_download),
                label: const Text('Import Contributions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ContributionCard(
          contribution: items[index],
          showActions: showActions,
          player: _player,
          onApprove: () => _approveDialog(items[index]),
          onReject: () => _rejectDialog(items[index]),
        );
      },
    );
  }

  Future<void> _syncToCloud() async {
    final service = context.read<ContributionService>();
    if (!service.hasWebhook) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No webhook configured. Deploy with deploy_apps_script.bat first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing to Google Sheet...')),
    );

    final count = await service.syncApprovedToWebhook();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Synced $count contributions to Google Sheet'
              : 'All contributions already synced'),
          backgroundColor: count > 0 ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  Widget _buildApprovedList(List<Contribution> items) {
    final service = context.read<ContributionService>();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No approved contributions',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Cloud sync banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    service.hasWebhook ? Icons.cloud_done : Icons.cloud_off,
                    color: service.hasWebhook
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service.hasWebhook
                          ? '${items.length} approved. Approvals auto-sync to Google Sheet. '
                            'Run build_and_run.bat to download and apply.'
                          : '${items.length} approved. Export manually or deploy '
                            'the webhook for auto-sync.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (service.hasWebhook) ...[
                    ElevatedButton.icon(
                      onPressed: _syncToCloud,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _exportApproved,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Export JSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _ContributionCard(
                contribution: items[index],
                player: _player,
              );
            },
          ),
        ),
      ],
    );
  }

  void _approveDialog(Contribution c) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Contribution?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: 'This will approve ',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextSpan(
                    text: '"${c.targetWord}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: c.type == ContributionType.spellingCorrection
                        ? ' → "${c.correction}". Export and run '
                          'build_and_run.bat to apply the change.'
                        : '. Export and run build_and_run.bat to apply.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Review notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ContributionService>().approve(
                    c.id,
                    reviewNotes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Approved: "${c.targetWord}" → "${c.correction}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _rejectDialog(Contribution c) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Contribution?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${c.targetWord}" correction from ${c.profileName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g. Spelling is already correct',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ContributionService>().reject(
                    c.id,
                    reason: reasonController.text.isNotEmpty
                        ? reasonController.text
                        : 'Not applicable',
                  );
            },
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Contribution contribution;
  final bool showActions;
  final AudioPlayer player;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ContributionCard({
    required this.contribution,
    this.showActions = false,
    required this.player,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final c = contribution;
    final typeLabel = switch (c.type) {
      ContributionType.spellingCorrection => 'Spelling Fix',
      ContributionType.pronunciationFix => 'Pronunciation',
      ContributionType.newWord => 'New Word',
      ContributionType.newSentence => 'New Sentence',
      ContributionType.newPhrase => 'New Phrase',
      ContributionType.generalFeedback => 'Feedback',
    };
    final typeColor = switch (c.type) {
      ContributionType.spellingCorrection => Colors.orange,
      ContributionType.pronunciationFix => Colors.blue,
      ContributionType.newWord => Colors.green,
      ContributionType.newSentence => Colors.teal,
      ContributionType.newPhrase => Colors.purple,
      ContributionType.generalFeedback => Colors.grey,
    };
    final typeIcon = switch (c.type) {
      ContributionType.spellingCorrection => Icons.spellcheck,
      ContributionType.pronunciationFix => Icons.record_voice_over,
      ContributionType.newWord => Icons.add_circle,
      ContributionType.newSentence => Icons.short_text,
      ContributionType.newPhrase => Icons.chat_bubble,
      ContributionType.generalFeedback => Icons.feedback,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type badge + contributor name + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  c.profileName,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(c.submittedAt),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target word
            Row(
              children: [
                const Text('Word: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(
                    c.targetWord,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Correction (if applicable)
            if (c.correction.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16,
                      color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.correction,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // English meaning
            if (c.englishMeaning != null && c.englishMeaning!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'English: ${c.englishMeaning}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Pronunciation guide
            if (c.pronunciationGuide != null &&
                c.pronunciationGuide!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.record_voice_over,
                      size: 14, color: Colors.purple.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sounds like: ${c.pronunciationGuide}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Category
            if (c.category != null) ...[
              const SizedBox(height: 4),
              Text(
                'Category: ${c.category}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],

            // Audio recording
            if (c.audioPath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text('Audio recording attached'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.blue, size: 32),
                      onPressed: () {
                        player.play(DeviceFileSource(c.audioPath!));
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Notes
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.notes!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],

            // Review notes (for approved/rejected)
            if (c.reviewNotes != null && c.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.status == ContributionStatus.approved
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Review: ${c.reviewNotes}',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.status == ContributionStatus.approved
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],

            // Action buttons (only for pending in developer mode)
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
