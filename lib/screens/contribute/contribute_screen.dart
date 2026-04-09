import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// User-facing screen for submitting word corrections, pronunciation
/// recordings, new words, and general suggestions.
class ContributeScreen extends StatefulWidget {
  /// Optional pre-filled word (when user taps "Report" on a specific word)
  final String? prefillWord;
  final String? prefillCategory;

  const ContributeScreen({Key? key, this.prefillWord, this.prefillCategory})
      : super(key: key);

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _wordController = TextEditingController();
  final _correctionController = TextEditingController();
  final _englishController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _notesController = TextEditingController();

  ContributionType _type = ContributionType.spellingCorrection;
  String _category = 'body';
  bool _submitted = false;
  bool _emailSent = false;
  bool _emailFailed = false;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  static const _categories = [
    'body', 'animals', 'nature', 'actions', 'things', 'family', 'numbers',
    'greeting', 'question', 'classroom', 'farewell', 'grammar', 'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillWord != null) {
      _wordController.text = widget.prefillWord!;
    }
    if (widget.prefillCategory != null) {
      _category = widget.prefillCategory!;
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _correctionController.dispose();
    _englishController.dispose();
    _pronunciationController.dispose();
    _notesController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ==================== Audio Recording ====================

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
    await _player.play(DeviceFileSource(_recordingPath!));
  }

  Future<void> _deleteRecording() async {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  // ==================== Submit ====================

  Contribution? _lastSubmitted;

  Future<void> _submit() async {
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Awing word')),
      );
      return;
    }
    if (_type != ContributionType.generalFeedback &&
        _correctionController.text.trim().isEmpty &&
        !_hasRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a correction or record the pronunciation'),
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final contribService = context.read<ContributionService>();
    final analytics = AnalyticsService.instance;

    final id = await contribService.submit(
      deviceId: analytics.isOptedOut ? 'anonymous' : 'contributor',
      profileName: auth.currentProfile?.displayName ?? 'Anonymous',
      type: _type,
      targetWord: _wordController.text.trim(),
      correction: _correctionController.text.trim(),
      englishMeaning: _englishController.text.trim().isNotEmpty
          ? _englishController.text.trim()
          : null,
      category: _category,
      pronunciationGuide: _pronunciationController.text.trim().isNotEmpty
          ? _pronunciationController.text.trim()
          : null,
      audioPath: _hasRecording ? _recordingPath : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    // Keep a reference to the submitted contribution for sharing
    if (id != null) {
      _lastSubmitted = contribService.contributions
          .firstWhere((c) => c.id == id);
    }

    analytics.logFeedback(
      type: 'contribution_${_type.name}',
      message: '${_wordController.text} → ${_correctionController.text}',
      screen: 'contribute_screen',
    );

    // Auto-email to developer
    bool emailSuccess = false;
    if (_lastSubmitted != null) {
      emailSuccess = await contribService.emailContribution(
        _lastSubmitted!,
        senderName: auth.currentProfile?.displayName ?? 'Anonymous',
        senderEmail: auth.currentEmail ?? 'no-reply@awing-app.local',
      );
    }

    if (!mounted) return;
    setState(() {
      _submitted = true;
      _emailSent = emailSuccess;
      _emailFailed = !emailSuccess;
    });
  }

  Future<void> _shareSubmission() async {
    if (_lastSubmitted == null) return;
    await context.read<ContributionService>().shareContribution(_lastSubmitted!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute'),
        centerTitle: true,
        backgroundColor: const Color(0xFF006432),
        foregroundColor: Colors.white,
      ),
      body: _submitted ? _buildThankYou() : _buildForm(),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _emailSent ? Icons.mark_email_read : Icons.check_circle,
              size: 64,
              color: _emailSent ? Colors.green : const Color(0xFF006432),
            ),
            const SizedBox(height: 16),
            Text(
              _emailSent
                  ? 'Sent to Developer!'
                  : 'Submission Saved!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _emailSent
                    ? Colors.green.shade700
                    : const Color(0xFF006432),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailSent
                  ? 'Your contribution has been emailed to the developer '
                    'for review. Thank you for helping grow the Awing language app!'
                  : _emailFailed
                      ? 'Your contribution was saved locally. '
                        'We could not open your email app automatically. '
                        'You can share it manually below.'
                      : 'Your contribution was saved successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // Show manual share button only if auto-email failed
            if (_emailFailed) ...[
              ElevatedButton.icon(
                onPressed: _shareSubmission,
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Manually',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _submitted = false;
                      _emailSent = false;
                      _emailFailed = false;
                      _lastSubmitted = null;
                      _wordController.clear();
                      _correctionController.clear();
                      _englishController.clear();
                      _pronunciationController.clear();
                      _notesController.clear();
                      _hasRecording = false;
                      _recordingPath = null;
                    });
                  },
                  child: const Text('Submit Another'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type selector
          Text(
            'What would you like to contribute?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _typeChip('Fix Spelling', Icons.spellcheck,
                  ContributionType.spellingCorrection),
              _typeChip('Fix Pronunciation', Icons.record_voice_over,
                  ContributionType.pronunciationFix),
              _typeChip('Add New Word', Icons.add_circle_outline,
                  ContributionType.newWord),
              _typeChip('Add Sentence', Icons.short_text,
                  ContributionType.newSentence),
            ],
          ),
          const SizedBox(height: 24),

          // Target word
          TextField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: _type == ContributionType.newWord ||
                      _type == ContributionType.newSentence
                  ? 'Awing word or sentence'
                  : 'Which word needs fixing?',
              hintText: _type == ContributionType.newSentence
                  ? 'e.g. Ko akwe pə nəgoomɔ́'
                  : 'e.g. apô',
              prefixIcon: const Icon(Icons.translate),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Correction
          if (_type != ContributionType.pronunciationFix) ...[
            TextField(
              controller: _correctionController,
              decoration: InputDecoration(
                labelText: _type == ContributionType.spellingCorrection
                    ? 'Correct spelling'
                    : _type == ContributionType.newSentence
                        ? 'English translation'
                        : 'The Awing word',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // English meaning (for new words)
          if (_type == ContributionType.newWord) ...[
            TextField(
              controller: _englishController,
              decoration: InputDecoration(
                labelText: 'English meaning',
                hintText: 'e.g. hand',
                prefixIcon: const Icon(Icons.language),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pronunciation guide (for new words and sentences)
          if (_type == ContributionType.newWord ||
              _type == ContributionType.newSentence ||
              _type == ContributionType.pronunciationFix) ...[
            TextField(
              controller: _pronunciationController,
              decoration: InputDecoration(
                labelText: 'How to pronounce it',
                hintText: _type == ContributionType.newSentence
                    ? 'e.g. koh ah-kweh puh nuh-goh-maw'
                    : 'e.g. ah-POH (describe the sounds)',
                helperText: 'Write how it sounds using simple English letters. '
                    'Use CAPS for the stressed/high-tone syllable.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.record_voice_over),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category selector
          if (_type == ContributionType.newWord) ...[
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c[0].toUpperCase() + c.substring(1)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(height: 16),
          ],

          // Audio recording section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.shade50
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording
                    ? Colors.red.shade200
                    : const Color(0xFFA5D6A7),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Record the correct pronunciation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF006432),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap and hold to record how this word should sound',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Record button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : const Color(0xFF006432),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? Colors.red
                                      : const Color(0xFF006432))
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    if (_hasRecording) ...[
                      const SizedBox(width: 16),
                      // Play button
                      IconButton(
                        onPressed: _playRecording,
                        icon: const Icon(Icons.play_circle_fill),
                        iconSize: 48,
                        color: const Color(0xFF006432),
                      ),
                      // Delete button
                      IconButton(
                        onPressed: _deleteRecording,
                        icon: const Icon(Icons.delete),
                        iconSize: 32,
                        color: Colors.red.shade400,
                      ),
                    ],
                  ],
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
                if (_hasRecording && !_isRecording) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Recording saved (${_formatDuration(_recordingDuration)})',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Additional notes (optional)',
              hintText: 'Any context or explanation...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text(
              'Submit Contribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006432),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your name will be shown as the contributor. '
            'The developer will review and approve your submission.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, IconData icon, ContributionType type) {
    final selected = _type == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16,
              color: selected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _type = type),
      selectedColor: const Color(0xFF006432),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade700,
      ),
      checkmarkColor: Colors.white,
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
