import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Pronunciation practice — kid-friendly flow:
///
///   1. See the word + picture + English meaning.
///   2. Tap "Hear it" to listen to the correct Awing pronunciation.
///   3. Tap the big mic to record yourself saying it.
///   4. Tap again to stop — playback buttons appear.
///   5. Tap "Play mine" to hear your own recording.
///   6. Tap "Hear it" again to compare with the reference.
///   7. Decide for yourself whether to move on or try again.
///
/// The previous version used speech-to-text to generate a fake "% match"
/// score, but Android's speech recognizer is English-trained — it was
/// guessing English words that *sounded* like what the kid said, then
/// scoring against that guess. This is honest, educational, and actually
/// helps kids hear their own pronunciation vs the reference.
class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({Key? key}) : super(key: key);

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with TickerProviderStateMixin {
  final PronunciationService _pronunciation = PronunciationService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  late AnimationController _pulseController;
  late AwingWord _currentWord;
  late List<AwingWord> _vocabulary;

  static const int _maxRecordSeconds = 10;
  bool _isRecording = false;
  bool _isPlayingMine = false;
  String? _myRecordingPath;
  int _wordsPracticed = 0;
  Timer? _recordingTimer;
  int _recordingSecondsLeft = _maxRecordSeconds;

  @override
  void initState() {
    super.initState();
    _vocabulary = allVocabulary;
    _currentWord = _getRandomWord();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pronunciation.init();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingMine = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_pronunciation');
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  AwingWord _getRandomWord() {
    // Only practice with difficulty-1 words (beginner friendly).
    final pool = _vocabulary.where((w) => w.difficulty <= 1).toList();
    if (pool.isEmpty) return _vocabulary.first;
    return pool[math.Random().nextInt(pool.length)];
  }

  Future<void> _startRecording() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone permission is needed to record yourself.'),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/awing_practice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
        ),
        path: path,
      );

      _pulseController.repeat();
      _recordingSecondsLeft = _maxRecordSeconds;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordingSecondsLeft--;
        });
        if (_recordingSecondsLeft <= 0) {
          timer.cancel();
          _stopRecording();
        }
      });
      setState(() {
        _isRecording = true;
        _myRecordingPath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final path = await _recorder.stop();
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _isRecording = false;
        _myRecordingPath = path;
        if (path != null) _wordsPracticed++;
      });
    } catch (e) {
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _playMyRecording() async {
    final path = _myRecordingPath;
    if (path == null) return;
    try {
      setState(() => _isPlayingMine = true);
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) setState(() => _isPlayingMine = false);
    }
  }

  Future<void> _hearReference() async {
    await _pronunciation.speakAwing(_currentWord.awing);
  }

  void _nextWord() {
    setState(() {
      _currentWord = _getRandomWord();
      _myRecordingPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Practice'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Session stat — just a positive count, no fake score.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Words practiced: $_wordsPracticed',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Picture of the current word — responsive to device width.
              Builder(
                builder: (context) {
                  final imageSize = (MediaQuery.of(context).size.width * 0.5)
                      .clamp(120.0, 200.0);
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: PackImage(
                          awingWord: _currentWord.awing,
                          english: _currentWord.english,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Awing word (big) — auto-shrink to fit narrow phones.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currentWord.awing,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currentWord.english,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Step 1: Hear the reference.
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _hearReference,
                icon: const Icon(Icons.volume_up),
                label: const Text('Hear it'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Big mic — tap to start/stop recording.
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording
                          ? 1.0 + (_pulseController.value * 0.12)
                          : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isRecording)
                              BoxShadow(
                                color: Colors.red.withOpacity(
                                    0.3 + (_pulseController.value * 0.3)),
                                blurRadius:
                                    20 + (_pulseController.value * 10),
                                spreadRadius:
                                    8 + (_pulseController.value * 5),
                              ),
                          ],
                        ),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: FloatingActionButton(
                            heroTag: 'mic',
                            backgroundColor: _isRecording
                                ? Colors.red.shade600
                                : Colors.blue.shade600,
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRecording
                    ? 'Recording… $_recordingSecondsLeft s left'
                    : _myRecordingPath == null
                        ? 'Tap the mic and say the word'
                        : 'Recorded! Listen to yourself below.',
                style: TextStyle(color: _isRecording && _recordingSecondsLeft <= 3 ? Colors.red.shade700 : Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Step 3: Playback controls — appear once there's a recording.
              if (_myRecordingPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Compare the two:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _hearReference,
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Hear it'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isPlayingMine ? null : _playMyRecording,
                            icon: Icon(_isPlayingMine
                                ? Icons.graphic_eq
                                : Icons.play_circle),
                            label: Text(_isPlayingMine ? 'Playing…' : 'Play mine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Listen to both. Do they sound the same? You decide!',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade900),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.replay),
                      label: const Text('Try again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _nextWord,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
