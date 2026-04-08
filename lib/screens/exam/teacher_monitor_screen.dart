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
  @override
  void initState() {
    super.initState();
    widget.examService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.examService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
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
              // Connection info (when waiting)
              if (isWaiting && exam.teacherIp != null) ...[
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi, size: 32, color: Colors.indigo),
                        const SizedBox(height: 8),
                        const Text(
                          'Students can connect using:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          exam.teacherIp!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level: ${exam.examLevel.toUpperCase()} | '
                          '${exam.questions.length} questions | '
                          '${exam.timeLimitMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    ? 'Results (${exam.participants.length} students)'
                    : 'Students (${exam.participants.length} connected)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Participants list
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
                    : ListView.builder(
                        itemCount: exam.participants.length,
                        itemBuilder: (context, i) {
                          final p = exam.participants[i];
                          return Card(
                            child: ListTile(
                              leading: Text(
                                p.avatarEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              title: Text(
                                p.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: isFinished
                                  ? Text('Score: ${p.score}%')
                                  : isRunning
                                      ? Text(
                                          p.submitted
                                              ? 'Submitted'
                                              : '${p.answers.length}/${exam.questions.length} answered',
                                        )
                                      : const Text('Connected'),
                              trailing: isFinished
                                  ? CircleAvatar(
                                      backgroundColor: p.score >= 90
                                          ? Colors.green
                                          : p.score >= 70
                                              ? Colors.orange
                                              : Colors.red,
                                      child: Text(
                                        '${p.score}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : isRunning && p.submitted
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : null,
                            ),
                          );
                        },
                      ),
              ),

              // Action buttons
              const SizedBox(height: 16),
              if (isWaiting)
                ElevatedButton.icon(
                  onPressed: exam.participants.isEmpty
                      ? null
                      : () => exam.startExam(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Exam'),
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
}
