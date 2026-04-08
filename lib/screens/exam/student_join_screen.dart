import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/exam_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/screens/exam/student_exam_screen.dart';

class StudentJoinScreen extends StatefulWidget {
  const StudentJoinScreen({Key? key}) : super(key: key);

  @override
  State<StudentJoinScreen> createState() => _StudentJoinScreenState();
}

class _StudentJoinScreenState extends State<StudentJoinScreen> {
  final _ipController = TextEditingController();
  final ExamService _examService = ExamService();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    _examService.close();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _error = 'Enter the teacher\'s IP address');
      return;
    }

    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;
    if (profile == null) {
      setState(() => _error = 'No profile selected');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    final error = await _examService.joinExam(
      ip,
      profileId: profile.id,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      level: profile.currentLevel,
    );

    if (error != null) {
      setState(() {
        _connecting = false;
        _error = error;
      });
      return;
    }

    // Wait for exam to start by listening to state changes
    _examService.addListener(_onExamStateChange);
    setState(() => _connecting = false);
  }

  void _onExamStateChange() {
    if (_examService.state == ExamState.inProgress) {
      _examService.removeListener(_onExamStateChange);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentExamScreen(examService: _examService),
          ),
        );
      }
    } else if (_examService.state == ExamState.idle) {
      // Got rejected or disconnected
      _examService.removeListener(_onExamStateChange);
      if (mounted) {
        setState(() {
          _error = 'Disconnected from teacher. Check your level matches the exam.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;
    final isWaiting = _examService.state == ExamState.waiting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Exam'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile info
            if (profile != null)
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(profile.avatarEmoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Level: ${profile.currentLevel}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 16),
            ],

            // Waiting message
            if (isWaiting) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Connected! Waiting for teacher to start the exam...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level: ${_examService.examLevel.toUpperCase()} | '
                        '${_examService.timeLimitMinutes} minutes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // IP entry (when not connected)
            if (!isWaiting) ...[
              const Text(
                'Enter Teacher\'s IP Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask your teacher for the IP address shown on their screen.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.100',
                  prefixIcon: const Icon(Icons.wifi),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _connecting ? null : _connect,
                icon: _connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_connecting ? 'Connecting...' : 'Join Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
          ],
        ),
      ),
    );
  }
}
