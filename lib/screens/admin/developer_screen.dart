import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/data/awing_alphabet.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/data/awing_tones.dart' hide awingVowels;
import 'package:awing_ai_learning/screens/admin/review_screen.dart';
import 'package:awing_ai_learning/screens/about_screen.dart';
import 'package:awing_ai_learning/components/parental_gate.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

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
    context.read<AuthService>().resetDevModeActivity();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

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
      length: 6,
      child: Builder(builder: (ctx) {
        DefaultTabController.of(ctx).addListener(() {
          auth.resetDevModeActivity();
        });
        // Reset inactivity timer on ANY touch/interaction within developer mode
        return Listener(
          onPointerDown: (_) => auth.resetDevModeActivity(),
          child: Scaffold(
          appBar: AppBar(
            title: const Text('Developer Mode'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.greenAccent,
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final ok = await ParentalGate.verify(
                    context,
                    title: 'Exit Developer Mode',
                    message: 'Only the developer should exit developer mode.',
                  );
                  if (!ok || !context.mounted) return;
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
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
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
                icon: const Icon(Icons.logout,
                    color: Colors.redAccent, size: 18),
                label: const Text('Exit Dev',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.greenAccent,
              isScrollable: true,
              tabs: [
                Tab(text: 'Review', icon: Icon(Icons.rate_review)),
                Tab(text: 'Record', icon: Icon(Icons.mic)),
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
              _RecordTab(),
              _UsersTab(),
              _AnalyticsTab(),
              _ContentTab(),
              _SettingsTab(),
            ],
          ),
        ),
        );
      }),
    );
  }
}

// =====================================================================
//  REVIEW TAB — live server sync
// =====================================================================

class _ReviewTab extends StatefulWidget {
  const _ReviewTab();

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  Timer? _refreshTimer;
  bool _isFetching = false;
  DateTime? _lastSyncedAt;
  String? _lastError;
  FetchAllResult? _lastResult;

  @override
  void initState() {
    super.initState();
    // Kick off first fetch after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromServer(showSnack: false);
    });
    // Auto-refresh every 30 seconds while Dev Mode is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isFetching) _syncFromServer(showSnack: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncFromServer({required bool showSnack}) async {
    if (_isFetching) return;
    if (!mounted) return;

    setState(() {
      _isFetching = true;
      _lastError = null;
    });

    final service = context.read<ContributionService>();
    final result = await service.fetchAllFromWebhook();

    if (!mounted) return;

    setState(() {
      _isFetching = false;
      _lastResult = result;
      if (result.success) {
        _lastSyncedAt = DateTime.now();
        _lastError = null;
      } else {
        _lastError = result.error;
      }
    });

    if (showSnack) {
      final msg = result.success
          ? (result.added > 0 || result.updated > 0
              ? 'Synced — +${result.added} new, ${result.updated} updated'
              : 'Up to date (${result.serverTotal} on server)')
          : 'Sync failed: ${result.error ?? "unknown error"}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          backgroundColor: result.success ? Colors.green : Colors.red.shade800,
        ),
      );
    }
  }

  String _syncedAgo() {
    if (_lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().difference(_lastSyncedAt!);
    if (diff.inSeconds < 10) return 'Synced just now';
    if (diff.inSeconds < 60) return 'Synced ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
    return 'Synced ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionService>(
      builder: (context, service, _) {
        // Prefer server counts when available, fall back to local counts.
        // This avoids showing "0 pending" right after boot before the first
        // fetch completes — we'd rather show the locally known numbers.
        final localPending = service.pendingContributions.length;
        final localApproved = service.approvedContributions.length;
        final localTotal = service.contributions.length;

        final serverAvailable = _lastResult?.success ?? false;
        final pendingCount =
            serverAvailable ? _lastResult!.serverPending : localPending;
        final approvedCount =
            serverAvailable ? _lastResult!.serverApproved : localApproved;
        final totalCount =
            serverAvailable ? _lastResult!.serverTotal : localTotal;

        final pendingForList = service.pendingContributions;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFF003d1f),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Contribution Queue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent.shade100,
                          ),
                        ),
                        const Spacer(),
                        // Manual refresh with spinner while fetching
                        if (_isFetching)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white70),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.white70),
                            tooltip: 'Refresh from server',
                            onPressed: () => _syncFromServer(showSnack: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(
                            label: 'Pending',
                            value: '$pendingCount',
                            color: Colors.orange),
                        _StatBox(
                            label: 'Approved',
                            value: '$approvedCount',
                            color: Colors.green),
                        _StatBox(
                            label: 'Total',
                            value: '$totalCount',
                            color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _lastError != null
                              ? Icons.cloud_off
                              : (serverAvailable
                                  ? Icons.cloud_done
                                  : Icons.cloud_queue),
                          size: 14,
                          color: _lastError != null
                              ? Colors.red.shade300
                              : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _lastError != null
                              ? 'Sync error — tap refresh'
                              : _syncedAgo(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _lastError != null
                                ? Colors.red.shade300
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReviewScreen()));
              },
              icon: const Icon(Icons.rate_review),
              label: Text(
                pendingCount == 0
                    ? 'Review Contributions'
                    : 'Review $pendingCount Pending',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pendingCount == 0
                    ? Colors.grey.shade700
                    : const Color(0xFF006432),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (pendingForList.isNotEmpty) ...[
              Text('Recent Pending',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300)),
              const SizedBox(height: 8),
              ...pendingForList.take(5).map((c) => Card(
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

// =====================================================================
//  RECORD TAB — re-record audio for any word, phrase, or letter
// =====================================================================

/// Represents a single content item that can be recorded.
class _RecordableItem {
  final String awing;
  final String english;
  final String source; // 'word', 'phrase', 'letter'
  final String? category;

  const _RecordableItem({
    required this.awing,
    required this.english,
    required this.source,
    this.category,
  });

  String get displayLabel => '$awing — $english';
  String get sourceLabel {
    if (source == 'word') return 'Word (${category ?? "?"})';
    if (source == 'phrase') return 'Phrase';
    return 'Letter';
  }
}

class _RecordTab extends StatefulWidget {
  const _RecordTab();

  @override
  State<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<_RecordTab> {
  // All recordable items
  late List<_RecordableItem> _allItems;
  List<_RecordableItem> _filtered = [];

  // Selection
  _RecordableItem? _selected;
  String _filterSource = 'All';
  final _searchController = TextEditingController();

  // Recording
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _isPlaying = false;
  bool _submitting = false;

  static const int _maxRecordSeconds = 10;

  @override
  void initState() {
    super.initState();
    _buildItemList();
    _applyFilter();
    _searchController.addListener(_applyFilter);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  void _buildItemList() {
    _allItems = [];

    // Letters (alphabet)
    for (final letter in awingAlphabet) {
      _allItems.add(_RecordableItem(
        awing: letter.letter,
        english: '${letter.phoneme} (${letter.type})',
        source: 'letter',
      ));
    }

    // Vocabulary words
    for (final word in allVocabulary) {
      _allItems.add(_RecordableItem(
        awing: word.awing,
        english: word.english,
        source: 'word',
        category: word.category,
      ));
    }

    // Phrases
    for (final phrase in awingPhrases) {
      _allItems.add(_RecordableItem(
        awing: phrase.awing,
        english: phrase.english,
        source: 'phrase',
        category: phrase.category,
      ));
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _allItems.where((item) {
        // Source filter
        if (_filterSource != 'All') {
          if (_filterSource == 'Words' && item.source != 'word') return false;
          if (_filterSource == 'Phrases' && item.source != 'phrase') return false;
          if (_filterSource == 'Letters' && item.source != 'letter') return false;
        }
        // Text search
        if (query.isNotEmpty) {
          return item.awing.toLowerCase().contains(query) ||
              item.english.toLowerCase().contains(query) ||
              (item.category?.toLowerCase().contains(query) ?? false);
        }
        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ==================== Recording ====================

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final contribService = context.read<ContributionService>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _recordingPath = await contribService.getRecordingPath(tempId);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );

    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingDuration.inSeconds >= _maxRecordSeconds) {
        _stopRecording();
        return;
      }
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });

    setState(() {
      _isRecording = true;
      _hasRecording = false;
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _hasRecording = path != null;
      if (path != null) _recordingPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_recordingPath!));
  }

  Future<void> _playReference() async {
    if (_selected == null) return;
    final pron = PronunciationService();
    await pron.speakAwing(_selected!.awing);
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  // ==================== Submit as Contribution ====================

  Future<void> _submitRecording() async {
    if (_selected == null || !_hasRecording) return;

    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final contribService = context.read<ContributionService>();
    final analytics = AnalyticsService.instance;

    await contribService.submit(
      deviceId: analytics.isOptedOut ? 'anonymous' : 'developer',
      profileName: auth.currentProfile?.displayName ?? 'Developer',
      type: ContributionType.pronunciationFix,
      targetWord: _selected!.awing,
      correction: _selected!.awing, // same word, new recording
      englishMeaning: _selected!.english,
      category: _selected!.category ?? _selected!.source,
      pronunciationGuide: null,
      audioPath: _recordingPath,
      notes:
          'Developer re-recording (${_selected!.sourceLabel})',
    );

    analytics.logActivity(
      event: 'dev_record',
      level: 'developer',
      lesson: 'record_${_selected!.source}',
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        _hasRecording = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Recording submitted for "${_selected!.awing}" — check Review tab'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.deepPurple.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.purpleAccent),
                    const SizedBox(width: 8),
                    Text('Re-record Audio',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent.shade100)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a word, phrase, or letter and record the correct '
                  'pronunciation. The recording is submitted as a contribution '
                  'and follows the standard review workflow.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Source filter chips
        Wrap(
          spacing: 8,
          children: ['All', 'Words', 'Phrases', 'Letters']
              .map((src) => ChoiceChip(
                    label: Text(src, style: const TextStyle(fontSize: 12)),
                    selected: _filterSource == src,
                    selectedColor: Colors.purpleAccent,
                    onSelected: (_) {
                      _filterSource = src;
                      _applyFilter();
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Count
        Text(
          '${_filtered.length} items | '
          '${_allItems.where((i) => i.source == "word").length} words, '
          '${_allItems.where((i) => i.source == "phrase").length} phrases, '
          '${_allItems.where((i) => i.source == "letter").length} letters',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // Search + Dropdown
        Autocomplete<_RecordableItem>(
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase().trim();
            if (query.isEmpty) {
              return _filtered.take(50);
            }
            return _filtered
                .where((item) =>
                    item.awing.toLowerCase().contains(query) ||
                    item.english.toLowerCase().contains(query))
                .take(50);
          },
          displayStringForOption: (item) => item.displayLabel,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            // Sync external search controller
            controller.addListener(() {
              _searchController.text = controller.text;
            });
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Search and select content',
                hintText: 'Type Awing or English...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setState(() => _selected = null);
                        },
                      )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (ctx, i) {
                      final item = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          item.source == 'word'
                              ? Icons.abc
                              : item.source == 'phrase'
                                  ? Icons.chat_bubble_outline
                                  : Icons.text_fields,
                          size: 18,
                          color: item.source == 'word'
                              ? Colors.blue
                              : item.source == 'phrase'
                                  ? Colors.teal
                                  : Colors.orange,
                        ),
                        title: Text(item.awing,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${item.english}  •  ${item.sourceLabel}',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () => onSelected(item),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (item) {
            setState(() {
              _selected = item;
              _hasRecording = false;
              _recordingPath = null;
              _recordingDuration = Duration.zero;
            });
          },
        ),
        const SizedBox(height: 16),

        // Selected item card
        if (_selected != null) ...[
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.awing,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(_selected!.english,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white70)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selected!.source == 'word'
                                    ? Colors.blue.withOpacity(0.2)
                                    : _selected!.source == 'phrase'
                                        ? Colors.teal.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_selected!.sourceLabel,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54)),
                            ),
                          ],
                        ),
                      ),
                      // Hear reference pronunciation
                      Column(
                        children: [
                          IconButton(
                            onPressed: _playReference,
                            icon: const Icon(Icons.volume_up,
                                color: Colors.greenAccent, size: 32),
                            tooltip: 'Hear current pronunciation',
                          ),
                          const Text('Hear it',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recording controls
          Card(
            color: _isRecording
                ? Colors.red.shade900.withOpacity(0.5)
                : Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Timer
                  Text(
                    '${_recordingDuration.inSeconds}s / ${_maxRecordSeconds}s',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.redAccent : Colors.white54,
                    ),
                  ),
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: _recordingDuration.inSeconds / _maxRecordSeconds,
                        backgroundColor: Colors.grey.shade800,
                        color: Colors.redAccent,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Big mic button
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : Colors.purpleAccent,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 4)
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording
                        ? 'Tap to stop'
                        : _hasRecording
                            ? 'Tap to re-record'
                            : 'Tap to record',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Playback controls (when recording exists)
                  if (_hasRecording) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Play recording
                        ElevatedButton.icon(
                          onPressed: _isPlaying ? null : _playRecording,
                          icon: Icon(_isPlaying
                              ? Icons.hourglass_bottom
                              : Icons.play_arrow),
                          label: Text(_isPlaying ? 'Playing...' : 'Play mine'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Delete recording
                        OutlinedButton.icon(
                          onPressed: _deleteRecording,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submitRecording,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(_submitting
                            ? 'Submitting...'
                            : 'Submit to Review Queue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Empty state
        if (_selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.mic_none,
                      size: 64, color: Colors.grey.shade700),
                  const SizedBox(height: 12),
                  Text('Select a word, phrase, or letter above\nto start recording',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// =====================================================================
//  USERS TAB — local accounts + Firebase cloud users
// =====================================================================

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>>? _cloudUsers;
  bool _loadingCloud = false;
  String? _cloudError;

  @override
  void initState() {
    super.initState();
    _fetchCloudUsers();
  }

  Future<void> _fetchCloudUsers() async {
    setState(() {
      _loadingCloud = true;
      _cloudError = null;
    });
    try {
      // Use collectionGroup('data') to find ALL user subcollection docs,
      // since many parent /users/{id} documents don't exist (phantom parents).
      final dataSnapshot =
          await FirebaseFirestore.instance.collectionGroup('data').get();

      // Extract unique user IDs from document paths: users/{userId}/data/{docType}
      final userDataMap = <String, Map<String, Map<String, dynamic>?>>{};
      for (final doc in dataSnapshot.docs) {
        final pathParts = doc.reference.path.split('/');
        // Expect: users / {userId} / data / {docType}
        if (pathParts.length >= 4 && pathParts[0] == 'users') {
          final userId = pathParts[1];
          final docType = pathParts[3]; // accounts, progress, or settings
          userDataMap.putIfAbsent(userId, () => {});
          userDataMap[userId]![docType] = doc.data();
        }
      }

      // Also try reading parent documents for those that exist
      final users = <Map<String, dynamic>>[];
      for (final entry in userDataMap.entries) {
        final userId = entry.key;
        final docs = entry.value;

        // Try to read parent doc (may not exist for older users)
        Map<String, dynamic>? parentData;
        try {
          final parentDoc = await FirebaseFirestore.instance
              .doc('users/$userId')
              .get();
          if (parentDoc.exists) {
            parentData = parentDoc.data();
          }
        } catch (_) {}

        users.add({
          'docId': userId,
          'email': parentData?['email'] ?? userId.replaceAll('_dot_', '.'),
          'appVersion': parentData?['app_version'],
          'profileCount': parentData?['profile_count'],
          'accounts': docs['accounts'],
          'progress': docs['progress'],
          'settings': docs['settings'],
          'updatedAt': parentData?['updated_at'] ??
              docs['accounts']?['updated_at'] ??
              docs['progress']?['updated_at'],
        });
      }

      if (mounted) {
        setState(() {
          _cloudUsers = users;
          _loadingCloud = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloudError = e.toString();
          _loadingCloud = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Local summary
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Local Users',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent.shade200)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _UserStatBox(
                            label: 'Accounts',
                            value: '${accounts.length}'),
                        _UserStatBox(
                            label: 'Profiles',
                            value: '${auth.totalProfileCount}'),
                        _UserStatBox(
                            label: 'Beginner',
                            value:
                                '${_countAtLevel(accounts, 'beginner')}'),
                        _UserStatBox(
                            label: 'Medium',
                            value:
                                '${_countAtLevel(accounts, 'medium')}'),
                        _UserStatBox(
                            label: 'Expert',
                            value:
                                '${_countAtLevel(accounts, 'expert')}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Local account list
            ...accounts
                .map((account) => _AccountCard(account: account)),

            const SizedBox(height: 24),

            // Firebase Cloud Users section
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('Firebase Cloud Users',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_loadingCloud)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchCloudUsers,
                    tooltip: 'Refresh cloud users',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cloudError != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error: $_cloudError',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12)),
                ),
              ),

            if (_cloudUsers != null && _cloudUsers!.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No cloud users found.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),

            if (_cloudUsers != null)
              ...(_cloudUsers!.map((user) => _CloudUserCard(user: user))),
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

class _CloudUserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _CloudUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user['email'] ?? 'Unknown';
    final updatedAt = user['updatedAt'] as String?;
    final appVersion = user['appVersion'] as String?;
    final accountsData = user['accounts']?['data'];
    final progressData = user['progress']?['data'];
    final settingsData = user['settings']?['data'];

    int profileCount = 0;
    int totalXP = 0;
    List<Map<String, dynamic>> profileDetails = [];

    if (accountsData is Map) {
      for (final entry in accountsData.values) {
        if (entry is Map && entry['profiles'] is List) {
          for (final p in entry['profiles']) {
            profileCount++;
            final xp = (p['totalXP'] as int?) ?? 0;
            totalXP += xp;
            profileDetails.add({
              'name': p['displayName'] ?? 'Unknown',
              'level': p['currentLevel'] ?? '?',
              'xp': xp,
              'mediumUnlocked': p['mediumUnlocked'] == true,
              'expertUnlocked': p['expertUnlocked'] == true,
              'lessonsCompleted': p['lessonsCompleted'] is Map
                  ? (p['lessonsCompleted'] as Map).length
                  : 0,
            });
          }
        }
      }
    }

    if (progressData is Map) {
      final xp = progressData['total_xp'];
      if (xp is int && totalXP == 0) totalXP = xp;
    }

    String lastSync = 'Never';
    if (updatedAt != null) {
      try {
        final dt = DateTime.parse(updatedAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          lastSync = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          lastSync = '${diff.inHours}h ago';
        } else {
          lastSync = '${diff.inDays}d ago';
        }
      } catch (_) {
        lastSync = updatedAt;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading:
            const Icon(Icons.cloud_circle, color: Colors.blue),
        title: Text(email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '$profileCount profiles | XP: $totalXP | Synced: $lastSync',
            style: const TextStyle(fontSize: 12)),
        children: [
          // App version & sync info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                if (appVersion != null)
                  Chip(
                    label: Text('v$appVersion',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue.shade50,
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 8),
                Text('Last sync: $lastSync',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Profile details
          if (profileDetails.isNotEmpty)
            ...profileDetails.map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, size: 18),
                  title: Text(p['name'] as String),
                  subtitle: Text(
                    'Level: ${p['level']} | XP: ${p['xp']} | '
                    'Lessons: ${p['lessonsCompleted']}'
                    '${p['mediumUnlocked'] == true ? ' | Medium ✓' : ''}'
                    '${p['expertUnlocked'] == true ? ' | Expert ✓' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                )),

          // Cloud progress data
          if (progressData is Map) ...[
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cloud Progress',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (progressData['daily_streak'] != null)
                    Text(
                        'Daily streak: ${progressData['daily_streak']}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['total_xp'] != null)
                    Text('Total XP: ${progressData['total_xp']}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['words_learned'] != null)
                    Text(
                        'Words learned: ${_summarizeJson(progressData['words_learned'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['completed_lessons'] != null)
                    Text(
                        'Lessons: ${_summarizeJson(progressData['completed_lessons'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['quiz_scores'] != null)
                    Text(
                        'Quizzes: ${_summarizeJson(progressData['quiz_scores'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['badges'] != null)
                    Text(
                        'Badges: ${_summarizeJson(progressData['badges'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['spaced_repetition'] != null)
                    Text(
                        'Spaced rep: ${_summarizeJson(progressData['spaced_repetition'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['viewed_letters'] != null)
                    Text(
                        'Viewed letters: ${_summarizeJson(progressData['viewed_letters'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['viewed_words'] != null)
                    Text(
                        'Viewed words: ${_summarizeJson(progressData['viewed_words'])}',
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],

          // Settings data
          if (settingsData is Map) ...[
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                      'Dark mode: ${settingsData['isDarkMode'] == true ? 'ON' : 'OFF'}',
                      style: const TextStyle(fontSize: 12)),
                  Text(
                      'Auto-sync: ${settingsData['cloud_auto_sync'] == true ? 'ON' : 'OFF'}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _summarizeJson(dynamic data) {
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return '${decoded.length} items';
        if (decoded is Map) return '${decoded.length} entries';
      } catch (_) {}
      return data.length > 40 ? '${data.substring(0, 40)}...' : data;
    }
    if (data is List) return '${data.length} items';
    if (data is Map) return '${data.length} entries';
    return data.toString();
  }
}

// =====================================================================
//  ANALYTICS TAB — all activity from local + Firebase
// =====================================================================

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  String _selectedCategory = 'All';
  bool _showEventDetail = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();
        final allProfiles =
            accounts.expand((a) => a.profiles).toList();

        // Compute quiz stats from all profiles
        final quizScores = <String, List<int>>{};
        for (final p in allProfiles) {
          for (final entry in p.quizBestScores.entries) {
            quizScores.putIfAbsent(entry.key, () => []);
            quizScores[entry.key]!.add(entry.value);
          }
        }

        // Compute lesson stats
        final lessonCounts = <String, int>{};
        for (final p in allProfiles) {
          for (final lessonId in p.lessonsCompleted.keys) {
            if (p.lessonsCompleted[lessonId] == true) {
              lessonCounts[lessonId] =
                  (lessonCounts[lessonId] ?? 0) + 1;
            }
          }
        }

        // Local analytics events
        final analytics = AnalyticsService.instance;
        final activityEvents = analytics.getEvents('Activity');
        final quizEvents = analytics.getEvents('Quizzes');
        final feedbackEvents = analytics.getEvents('Feedback');
        final errorEvents = analytics.getEvents('Errors');
        final sessionEvents = analytics.getEvents('Sessions');

        // Progress service data
        final progress = context.watch<ProgressService>();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview card
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent.shade200)),
                    const SizedBox(height: 12),
                    _AnalyticRow(
                        label: 'Total accounts',
                        value: '${accounts.length}'),
                    _AnalyticRow(
                        label: 'Total profiles',
                        value: '${allProfiles.length}'),
                    _AnalyticRow(
                        label: 'Total XP earned',
                        value:
                            '${allProfiles.fold(0, (sum, p) => sum + p.totalXP)}'),
                    _AnalyticRow(
                        label: 'Total lessons completed',
                        value:
                            '${allProfiles.fold(0, (sum, p) => sum + p.lessonsCompleted.length)}'),
                    _AnalyticRow(
                        label: 'Medium unlocked',
                        value:
                            '${allProfiles.where((p) => p.mediumUnlocked).length}'),
                    _AnalyticRow(
                        label: 'Expert unlocked',
                        value:
                            '${allProfiles.where((p) => p.expertUnlocked).length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Progress service stats
            Card(
              color: Colors.teal.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Device Progress',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent.shade100)),
                    const SizedBox(height: 12),
                    _AnalyticRow(
                        label: 'Level',
                        value: '${progress.currentLevel}'),
                    _AnalyticRow(
                        label: 'Total XP', value: '${progress.totalXP}'),
                    _AnalyticRow(
                        label: 'Daily streak',
                        value: '${progress.dailyStreak} days'),
                    _AnalyticRow(
                        label: 'Badges unlocked',
                        value:
                            '${progress.getUnlockedBadges().length} / ${progress.getAllBadges().length}'),
                    _AnalyticRow(
                        label: 'Words in review',
                        value:
                            '${progress.getWordsToReview().length} due'),
                    _AnalyticRow(
                        label: 'Lessons completed',
                        value:
                            '${progress.getCompletedLessons().length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Event log summary
            Card(
              color: Colors.indigo.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Event Log',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors.lightBlueAccent.shade100)),
                        const Spacer(),
                        Text(
                            '${analytics.totalEventCount} total',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EventCountRow(
                        label: 'Activities',
                        count: activityEvents.length,
                        icon: Icons.touch_app,
                        color: Colors.blue),
                    _EventCountRow(
                        label: 'Quizzes',
                        count: quizEvents.length,
                        icon: Icons.quiz,
                        color: Colors.green),
                    _EventCountRow(
                        label: 'Feedback',
                        count: feedbackEvents.length,
                        icon: Icons.feedback,
                        color: Colors.amber),
                    _EventCountRow(
                        label: 'Errors',
                        count: errorEvents.length,
                        icon: Icons.error,
                        color: Colors.red),
                    _EventCountRow(
                        label: 'Sessions',
                        count: sessionEvents.length,
                        icon: Icons.timer,
                        color: Colors.purple),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showEventDetail = !_showEventDetail;
                          });
                        },
                        icon: Icon(_showEventDetail
                            ? Icons.expand_less
                            : Icons.expand_more),
                        label: Text(_showEventDetail
                            ? 'Hide Event Details'
                            : 'Show Event Details'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Detailed event list (expandable)
            if (_showEventDetail) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Activity', 'Quizzes', 'Feedback', 'Errors', 'Sessions']
                    .map((cat) => ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: Colors.greenAccent,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ..._buildEventList(analytics),
            ],

            const SizedBox(height: 16),

            // Quiz performance
            if (quizScores.isNotEmpty) ...[
              const Text('Quiz Performance',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...quizScores.entries.map((entry) {
                final avg = entry.value.reduce((a, b) => a + b) /
                    entry.value.length;
                final best =
                    entry.value.reduce((a, b) => a > b ? a : b);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      best == 100
                          ? Icons.star
                          : best >= 80
                              ? Icons.star_half
                              : Icons.star_border,
                      color: best == 100
                          ? Colors.amber
                          : best >= 80
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    title: Text(entry.key),
                    subtitle: Text(
                      'Avg: ${avg.toStringAsFixed(1)}% | Best: $best% | Taken: ${entry.value.length}x',
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // Lesson completion breakdown
            if (lessonCounts.isNotEmpty) ...[
              const Text('Lesson Completion',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...lessonCounts.entries.map((entry) => Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      title: Text(entry.key),
                      trailing: Text(
                          '${entry.value} user${entry.value > 1 ? "s" : ""}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildEventList(AnalyticsService analytics) {
    final categories = _selectedCategory == 'All'
        ? ['Activity', 'Quizzes', 'Feedback', 'Errors', 'Sessions']
        : [_selectedCategory];

    final allEvents = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final events = analytics.getEvents(cat);
      for (final event in events) {
        allEvents.add({'category': cat, 'data': event});
      }
    }

    // Sort by timestamp descending (first element is timestamp)
    allEvents.sort((a, b) {
      final aTime = (a['data'] as List).isNotEmpty
          ? (a['data'] as List)[0].toString()
          : '';
      final bTime = (b['data'] as List).isNotEmpty
          ? (b['data'] as List)[0].toString()
          : '';
      return bTime.compareTo(aTime);
    });

    if (allEvents.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No events in this category.',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ),
      ];
    }

    return allEvents.take(50).map((item) {
      final cat = item['category'] as String;
      final data = item['data'] as List;
      final timestamp =
          data.isNotEmpty ? data[0].toString() : 'Unknown';

      String title = cat;
      String subtitle = '';

      // Format based on category
      if (cat == 'Activity' && data.length >= 5) {
        title = data[2]?.toString() ?? 'Activity';
        subtitle =
            'Level: ${data[3]} | Lesson: ${data[4]}';
      } else if (cat == 'Quizzes' && data.length >= 7) {
        title = '${data[2]} (${data[3]})';
        subtitle =
            'Score: ${data[4]}% | ${data[5]}/${data[6]} correct';
      } else if (cat == 'Feedback' && data.length >= 5) {
        title = 'Feedback: ${data[2]}';
        subtitle = data[4]?.toString() ?? '';
      } else if (cat == 'Errors' && data.length >= 4) {
        title = 'Error: ${data[2]}';
        subtitle = data[3]?.toString() ?? '';
      } else if (cat == 'Sessions' && data.length >= 6) {
        title = 'Session ${data[2]}';
        subtitle =
            '${data[3]} min | ${data[4]} lessons | ${data[5]} quizzes';
      }

      // Format timestamp
      String timeStr = timestamp;
      try {
        final dt = DateTime.parse(timestamp);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeStr = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeStr = '${diff.inHours}h ago';
        } else {
          timeStr = '${diff.inDays}d ago';
        }
      } catch (_) {}

      IconData icon;
      Color iconColor;
      switch (cat) {
        case 'Activity':
          icon = Icons.touch_app;
          iconColor = Colors.blue;
          break;
        case 'Quizzes':
          icon = Icons.quiz;
          iconColor = Colors.green;
          break;
        case 'Feedback':
          icon = Icons.feedback;
          iconColor = Colors.amber;
          break;
        case 'Errors':
          icon = Icons.error;
          iconColor = Colors.red;
          break;
        case 'Sessions':
          icon = Icons.timer;
          iconColor = Colors.purple;
          break;
        default:
          icon = Icons.circle;
          iconColor = Colors.grey;
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(title,
              style: const TextStyle(fontSize: 13)),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle,
                  style: const TextStyle(fontSize: 11))
              : null,
          trailing: Text(timeStr,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
        ),
      );
    }).toList();
  }
}

class _EventCountRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _EventCountRow({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// =====================================================================
//  CONTENT TAB — vocabulary, phrases, stories, alphabet stats
// =====================================================================

class _ContentTab extends StatelessWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context) {
    // Compute stats from data files
    final vocabWords = allVocabulary;
    final phrases = awingPhrases;
    final letters = awingAlphabet;
    final toneTypes = awingTones;
    final clusters = [
      ...prenasalizedClusters,
      ...palatalizedClusters,
      ...labializedClusters,
    ];

    // Category breakdown
    final categoryCount = <String, int>{};
    for (final w in vocabWords) {
      categoryCount[w.category] =
          (categoryCount[w.category] ?? 0) + 1;
    }
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Difficulty breakdown
    int beginner = 0, medium = 0, expert = 0;
    for (final w in vocabWords) {
      final d = w.difficulty;
      if (d == 1) {
        beginner++;
      } else if (d == 2) {
        medium++;
      } else {
        expert++;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Content summary card
        Card(
          color: Colors.grey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content Summary',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade200)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                        label: 'Words',
                        value: '${vocabWords.length}',
                        color: Colors.blue),
                    _StatBox(
                        label: 'Phrases',
                        value: '${phrases.length}',
                        color: Colors.purple),
                    _StatBox(
                        label: 'Letters',
                        value: '${letters.length}',
                        color: Colors.orange),
                    _StatBox(
                        label: 'Tones',
                        value: '${toneTypes.length}',
                        color: Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Difficulty breakdown
        Card(
          color: Colors.blueGrey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vocabulary by Difficulty',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                _DifficultyBar(
                    label: 'Beginner (1)',
                    count: beginner,
                    total: vocabWords.length,
                    color: Colors.green),
                const SizedBox(height: 6),
                _DifficultyBar(
                    label: 'Medium (2)',
                    count: medium,
                    total: vocabWords.length,
                    color: Colors.orange),
                const SizedBox(height: 6),
                _DifficultyBar(
                    label: 'Expert (3)',
                    count: expert,
                    total: vocabWords.length,
                    color: Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Words by Category',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...sortedCategories.map((entry) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 100,
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      fontSize: 13))),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: entry.value /
                                  (sortedCategories.first.value),
                              backgroundColor:
                                  Colors.grey.shade200,
                              color: _categoryColor(entry.key),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 35,
                              child: Text('${entry.value}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Language features
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Language Features',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _AnalyticRow(
                    label: 'Tone types', value: '${toneTypes.length}'),
                _AnalyticRow(
                    label: 'Consonant clusters',
                    value: '${clusters.length}'),
                _AnalyticRow(
                    label: 'Vowels',
                    value:
                        '${letters.where((l) => l.type == "vowel").length}'),
                _AnalyticRow(
                    label: 'Consonants',
                    value:
                        '${letters.where((l) => l.type == "consonant").length}'),
                _AnalyticRow(
                    label: 'Syllable types',
                    value: '${syllableTypes.length}'),
                _AnalyticRow(
                    label: 'Verb suffixes',
                    value: '${verbSuffixes.length}'),
                _AnalyticRow(
                    label: 'Allophonic rules',
                    value: '${allophonicRules.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Color _categoryColor(String cat) {
    switch (cat) {
      case 'things':
        return Colors.blue;
      case 'actions':
        return Colors.orange;
      case 'descriptive':
        return Colors.purple;
      case 'family':
        return Colors.pink;
      case 'body':
        return Colors.red;
      case 'animals':
        return Colors.brown;
      case 'nature':
        return Colors.green;
      case 'food':
        return Colors.amber;
      case 'numbers':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _DifficultyBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.grey.shade700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }
}

// =====================================================================
//  SETTINGS TAB — debug info, export, Firebase status, security
// =====================================================================

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudBackupService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('App Info',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('Debug Info'),
            subtitle: Text(
                'Version ${AboutScreen.appVersion} | Build ${AboutScreen.buildNumber}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDebugInfo(context),
          ),
        ),
        const SizedBox(height: 16),

        // Firebase status
        const Text('Cloud & Firebase',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: cloud.isSignedIn
              ? Colors.green.shade50
              : Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      cloud.isSignedIn
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: cloud.isSignedIn
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cloud.isSignedIn
                          ? 'Firebase Connected'
                          : 'Firebase Not Connected',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cloud.connectedEmail != null)
                  Text('Email: ${cloud.connectedEmail}',
                      style: const TextStyle(fontSize: 13)),
                if (cloud.lastBackupTime != null)
                  Text('Last backup: ${_formatTime(cloud.lastBackupTime!)}',
                      style: const TextStyle(fontSize: 13)),
                Text(
                    'Auto-sync: ${cloud.autoSync ? "ON" : "OFF"}',
                    style: const TextStyle(fontSize: 13)),
                if (cloud.syncError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Error: ${cloud.syncError}',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: cloud.isSyncing
                          ? null
                          : () async {
                              await cloud.backupAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(cloud.syncError ??
                                      'Backup complete'),
                                ));
                              }
                            },
                      icon: cloud.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.backup, size: 18),
                      label: const Text('Backup Now'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: cloud.isSyncing
                          ? null
                          : () async {
                              await cloud.restoreAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(cloud.syncError ??
                                      'Restore complete'),
                                ));
                              }
                            },
                      icon:
                          const Icon(Icons.cloud_download, size: 18),
                      label: const Text('Restore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data export
        const Text('Data Management',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.download, color: Colors.green),
            title: const Text('Export All Data'),
            subtitle: const Text(
                'Export accounts, progress, analytics as JSON'),
            trailing: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _exporting ? null : () => _exportData(context),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined,
                color: Colors.blue),
            title: const Text('Export Analytics Events'),
            subtitle: const Text('Export local event log as JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportAnalytics(context),
          ),
        ),
        const SizedBox(height: 24),

        // Security
        const Text('Security',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Deactivate Developer Mode'),
            subtitle:
                const Text('Auto-disables after 5 min of inactivity'),
            trailing:
                const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () async {
              final ok = await ParentalGate.verify(
                context,
                title: 'Deactivate Developer Mode',
                message:
                    'Only the developer should deactivate developer mode.',
              );
              if (!ok || !context.mounted) return;
              final auth = context.read<AuthService>();
              auth.disableDevMode();
              Navigator.of(context)
                  .popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Developer mode deactivated'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever,
                color: Colors.red),
            title: const Text('Clear Local Progress'),
            subtitle: const Text(
                'Reset all progress data on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmClearProgress(context),
          ),
        ),
      ],
    );
  }

  void _showDebugInfo(BuildContext context) {
    final cloud = context.read<CloudBackupService>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug Info'),
        content: Text(
          'Awing AI Learning v1.6.1+28\n'
          'Flutter SDK: 3.22+\n'
          'Dart SDK: 3.4+\n'
          'Auth: Google Sign-In + SharedPreferences\n'
          'Cloud: Firebase Firestore (Spark plan)\n'
          'Exam: TCP sockets + mDNS (LAN)\n'
          'TTS: Edge TTS (6 Swahili voices)\n'
          'Firebase signed in: ${cloud.isSignedIn}\n'
          'Cloud email: ${cloud.connectedEmail ?? "none"}\n'
          'Auto-sync: ${cloud.autoSync}\n'
          'Analytics events: ${AnalyticsService.instance.totalEventCount}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = context.read<AuthService>();
      final accounts = auth.getAllAccounts();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '${AboutScreen.appVersion}+${AboutScreen.buildNumber}',
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'progress': {
          'completed_lessons':
              prefs.getString('completed_lessons'),
          'quiz_scores': prefs.getString('quiz_scores'),
          'daily_streak': prefs.getInt('daily_streak'),
          'total_xp': prefs.getInt('total_xp'),
          'badges': prefs.getString('badges'),
          'viewed_letters': prefs.getString('viewed_letters'),
          'viewed_words': prefs.getString('viewed_words'),
          'spaced_repetition':
              prefs.getString('spaced_repetition'),
        },
        'analytics': {
          'activity':
              AnalyticsService.instance.getEvents('Activity'),
          'quizzes':
              AnalyticsService.instance.getEvents('Quizzes'),
          'feedback':
              AnalyticsService.instance.getEvents('Feedback'),
          'errors':
              AnalyticsService.instance.getEvents('Errors'),
          'sessions':
              AnalyticsService.instance.getEvents('Sessions'),
        },
      };

      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(exportData);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/awing_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportAnalytics(BuildContext context) async {
    try {
      final analytics = AnalyticsService.instance;
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalEvents': analytics.totalEventCount,
        'activity': analytics.getEvents('Activity'),
        'quizzes': analytics.getEvents('Quizzes'),
        'feedback': analytics.getEvents('Feedback'),
        'errors': analytics.getEvents('Errors'),
        'sessions': analytics.getEvents('Sessions'),
      };

      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(exportData);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/awing_analytics_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _confirmClearProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Progress?'),
        content: const Text(
          'This will reset all progress data on this device: '
          'lessons, quiz scores, XP, badges, streaks, and spaced repetition. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final progress = context.read<ProgressService>();
              await progress.clearAllProgress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return isoString;
    }
  }
}

// =====================================================================
//  SHARED WIDGETS
// =====================================================================

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
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
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Colors.white54)),
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
          account.authMethod == 'google'
              ? Icons.g_mobiledata
              : Icons.email,
          color: account.isDeveloper ? Colors.greenAccent : null,
        ),
        title: Text(account.email,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: account.isDeveloper
                    ? Colors.greenAccent
                    : null)),
        subtitle: Text(
            '${account.profiles.length} profiles | ${account.authMethod}'),
        children: account.profiles.map((profile) {
          return ListTile(
            leading: Text(profile.avatarEmoji,
                style: const TextStyle(fontSize: 28)),
            title: Text(profile.displayName),
            subtitle: Text(
              'Level: ${profile.currentLevel} | '
              'XP: ${profile.totalXP} | '
              'Lessons: ${profile.lessonsCompleted.length} | '
              'Medium: ${profile.mediumUnlocked ? "Y" : "N"} | '
              'Expert: ${profile.expertUnlocked ? "Y" : "N"}\n'
              'Created: ${_formatDate(profile.createdAt)} | '
              'Active: ${_formatDate(profile.lastActiveAt)}',
              style: const TextStyle(fontSize: 11),
            ),
            isThreeLine: true,
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
                      child: Text('Unlock Medium')),
                if (!profile.expertUnlocked)
                  const PopupMenuItem(
                      value: 'unlock_expert',
                      child: Text('Unlock Expert')),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
          Text(label,
              style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent)),
        ],
      ),
    );
  }
}
