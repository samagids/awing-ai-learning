import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/exam_service.dart';

class TeacherMonitorScreen extends StatefulWidget {
  final ExamService examService;

  const TeacherMonitorScreen({Key? key, required this.examService})
      : super(key: key);

  @override
  State<TeacherMonitorScreen> createState() => _TeacherMonitorScreenState();
}

class _TeacherMonitorScreenState extends State<TeacherMonitorScreen> {
  List<String> _diagnostics = const [];

  @override
  void initState() {
    super.initState();
    widget.examService.addListener(_onUpdate);
    // Run a diagnostic 6s after the room opens so the teacher knows
    // whether their device is actually broadcasting.
    Future.delayed(const Duration(seconds: 6), () async {
      if (!mounted) return;
      if (widget.examService.state == ExamState.waiting &&
          widget.examService.participants.isEmpty &&
          widget.examService.pendingJoins.isEmpty) {
        final d = await widget.examService.diagnose();
        if (mounted) setState(() => _diagnostics = d);
      }
    });
  }

  @override
  void dispose() {
    widget.examService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _runDiagnose() async {
    final d = await widget.examService.diagnose();
    if (mounted) setState(() => _diagnostics = d);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.examService;
    final isWaiting = exam.state == ExamState.waiting;
    final isRunning = exam.state == ExamState.inProgress;
    final isFinished = exam.state == ExamState.finished;

    return WillPopScope(
      onWillPop: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Exam?'),
            content: const Text('This will close the exam for all students.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (leave == true) {
          await exam.close();
        }
        return leave ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isWaiting
              ? 'Waiting for Students'
              : isRunning
                  ? 'Exam in Progress'
                  : isFinished
                      ? 'Exam Results'
                      : 'Exam'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            if (isRunning)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    _formatTime(exam.secondsRemaining),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Big PIN card (Kahoot-style) — shown while waiting.
              // Wrapped in a RepaintBoundary + extracted widget so it
              // doesn't visually rebuild every time a student joins or
              // answers a question.
              if (isWaiting) ...[
                RepaintBoundary(
                  child: _PinCard(
                    pin: exam.pin ?? '------',
                    levelLabel: exam.examLevel.toUpperCase(),
                    questionCount: exam.questions.length,
                    timeLimitMinutes: exam.timeLimitMinutes,
                    localIp: exam.localIp,
                  ),
                ),
                const SizedBox(height: 12),

                // Pending join requests
                if (exam.pendingJoins.isNotEmpty) ...[
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_add,
                                  color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                'Approval needed (${exam.pendingJoins.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...exam.pendingJoins.map((req) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.amber,
                                  child: Icon(Icons.person,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  req.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                    'wants to join this exam'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Reject',
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () =>
                                          exam.rejectPending(req.profileId),
                                    ),
                                    IconButton(
                                      tooltip: 'Approve',
                                      icon: const Icon(Icons.check,
                                          color: Colors.green),
                                      onPressed: () =>
                                          exam.approvePending(req.profileId),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Diagnostics card — shown when no students appear after a few
                // seconds, to help the teacher fix Bluetooth/Location issues.
                if (_diagnostics.isNotEmpty) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Students cannot find this device:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._diagnostics.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(p)),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    exam.openPermissionSettings(),
                                icon: const Icon(Icons.settings),
                                label: const Text('Open Settings'),
                              ),
                              TextButton.icon(
                                onPressed: _runDiagnose,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Re-check'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // Timer bar (when running)
              if (isRunning) ...[
                Card(
                  color: exam.secondsRemaining < 60
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          color: exam.secondsRemaining < 60
                              ? Colors.red
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(exam.secondsRemaining),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: exam.secondsRemaining < 60
                                ? Colors.red
                                : Colors.blue,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Participants header
              Text(
                isFinished
                    ? 'Results (${exam.participants.length} students, ranked)'
                    : isRunning
                        ? 'Live progress (${exam.participants.length} students, ranked)'
                        : 'Students (${exam.participants.length} connected)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Participants list — sorted by correct-count descending during
              // running/finished so the leader is on top. Each entry expands
              // to show the per-question breakdown.
              Expanded(
                child: exam.participants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Waiting for students to join...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final ranked = _rankedParticipants(exam);
                          return ListView.builder(
                            itemCount: ranked.length,
                            itemBuilder: (context, i) {
                              final p = ranked[i];
                              final correct = _correctCount(exam, p);
                              final answered = p.answers.length;
                              final total = exam.questions.length;
                              final pct = total > 0
                                  ? (correct / total * 100).round()
                                  : 0;
                              return _ParticipantCard(
                                participant: p,
                                rank: (isRunning || isFinished) ? i + 1 : null,
                                isFinished: isFinished,
                                isRunning: isRunning,
                                correct: correct,
                                answered: answered,
                                total: total,
                                percent: pct,
                                questions: exam.questions,
                              );
                            },
                          );
                        },
                      ),
              ),

              // Action buttons
              const SizedBox(height: 16),
              if (isWaiting) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.podcasts, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Discovery is OPEN — students can still find and join. '
                          'Tapping Start will close discovery, then everyone gets the '
                          'questions at the same time.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: (exam.participants.isEmpty || exam.questions.isEmpty)
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Start the exam?'),
                              content: Text(
                                  'All ${exam.participants.length} approved student(s) '
                                  'will receive the questions now. No new students will '
                                  'be able to join after this.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Start'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) exam.startExam();
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                      'Start Exam (${exam.participants.length} student${exam.participants.length == 1 ? '' : 's'})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              if (isRunning)
                ElevatedButton.icon(
                  onPressed: () => exam.endExam(),
                  icon: const Icon(Icons.stop),
                  label: const Text('End Exam Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (isFinished)
                ElevatedButton.icon(
                  onPressed: () async {
                    await exam.close();
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Close Exam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sort by correct count desc, then by answered count desc, then by name.
  /// Stable when no answers exist (waiting state) — preserves arrival order.
  List<ExamParticipant> _rankedParticipants(ExamService exam) {
    final list = List<ExamParticipant>.from(exam.participants);
    final shouldRank = exam.state == ExamState.inProgress ||
        exam.state == ExamState.finished;
    if (shouldRank) {
      list.sort((a, b) {
        final ac = _correctCount(exam, a);
        final bc = _correctCount(exam, b);
        if (ac != bc) return bc.compareTo(ac);
        if (a.answers.length != b.answers.length) {
          return b.answers.length.compareTo(a.answers.length);
        }
        return a.displayName.compareTo(b.displayName);
      });
    }
    return list;
  }

  int _correctCount(ExamService exam, ExamParticipant p) {
    int c = 0;
    for (final q in exam.questions) {
      final ans = p.answers[q.id];
      if (ans != null && ans == q.correctIndex) c++;
    }
    return c;
  }
}

/// One row in the live-progress / results list. Tap to expand and see
/// each question with the student's chosen answer + the correct answer.
class _ParticipantCard extends StatelessWidget {
  final ExamParticipant participant;
  final int? rank;
  final bool isFinished;
  final bool isRunning;
  final int correct;
  final int answered;
  final int total;
  final int percent;
  final List<ExamQuestion> questions;

  const _ParticipantCard({
    required this.participant,
    required this.rank,
    required this.isFinished,
    required this.isRunning,
    required this.correct,
    required this.answered,
    required this.total,
    required this.percent,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final p = participant;
    Color scoreColor;
    if (percent >= 90) {
      scoreColor = Colors.green;
    } else if (percent >= 70) {
      scoreColor = Colors.orange;
    } else if (percent >= 40) {
      scoreColor = Colors.amber;
    } else {
      scoreColor = Colors.red;
    }

    final showLive = isRunning || isFinished;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        // Hide the divider line drawn by ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: rank != null
              ? _RankBadge(rank: rank!)
              : Text(p.avatarEmoji, style: const TextStyle(fontSize: 28)),
          title: Row(
            children: [
              if (rank != null) ...[
                Text(p.avatarEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  p.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (isRunning && p.submitted)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                ),
            ],
          ),
          subtitle: showLive
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _Pill(
                        icon: Icons.check,
                        label: '$correct correct',
                        color: Colors.green,
                      ),
                      _Pill(
                        icon: Icons.help_outline,
                        label: '$answered / $total answered',
                        color: Colors.blue,
                      ),
                      if (!p.submitted && answered > 0 && isRunning)
                        const _Pill(
                          icon: Icons.timer,
                          label: 'in progress',
                          color: Colors.indigo,
                        ),
                      if (p.submitted)
                        const _Pill(
                          icon: Icons.done_all,
                          label: 'submitted',
                          color: Colors.teal,
                        ),
                    ],
                  ),
                )
              : const Text('Connected — waiting for exam to start'),
          trailing: showLive
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
          children: showLive ? _buildAnswerList() : const [],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerList() {
    if (questions.isEmpty) {
      return const [Text('No questions to display.')];
    }
    return [
      const Divider(height: 1),
      const SizedBox(height: 8),
      ...List.generate(questions.length, (qi) {
        final q = questions[qi];
        final picked = participant.answers[q.id];
        final answered = picked != null;
        final isCorrect = answered && picked == q.correctIndex;
        final pickedText = answered && picked! >= 0 && picked < q.choices.length
            ? q.choices[picked]
            : '—';
        final correctText = q.correctIndex >= 0 &&
                q.correctIndex < q.choices.length
            ? q.choices[q.correctIndex]
            : '—';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${qi + 1}.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          !answered
                              ? Icons.radio_button_unchecked
                              : isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel,
                          color: !answered
                              ? Colors.grey
                              : isCorrect
                                  ? Colors.green
                                  : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            !answered
                                ? 'Not answered yet'
                                : isCorrect
                                    ? 'Picked: $pickedText'
                                    : 'Picked: $pickedText  •  Correct: $correctText',
                            style: TextStyle(
                              fontSize: 12,
                              color: !answered
                                  ? Colors.grey.shade600
                                  : isCorrect
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;
    if (rank == 1) {
      color = const Color(0xFFFFD700); // gold
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0); // silver
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32); // bronze
      icon = Icons.emoji_events;
    } else {
      color = Colors.indigo.shade300;
      icon = null;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: icon != null
          ? const Icon(Icons.emoji_events, color: Colors.white, size: 18)
          : Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
    );
  }
}

/// The big indigo PIN card on the teacher's monitor screen.
/// Extracted as its own widget so frequent listener-driven rebuilds
/// (students joining, answers arriving) don't redraw it every time.
class _PinCard extends StatelessWidget {
  final String pin;
  final String levelLabel;
  final int questionCount;
  final int timeLimitMinutes;
  final String? localIp;

  const _PinCard({
    required this.pin,
    required this.levelLabel,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.localIp,
  });

  String get _formattedPin {
    if (pin.length != 6) return pin;
    return '${pin.substring(0, 3)} ${pin.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Game PIN',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedPin,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Students enter this PIN on their device',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Level: $levelLabel  •  $questionCount questions  •  $timeLimitMinutes min',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (localIp != null) ...[
              const SizedBox(height: 4),
              Text(
                'On Wi-Fi as $localIp',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
