import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ExamService _examService = ExamService();
  final TextEditingController _pinController = TextEditingController();
  bool _joining = false;
  String? _error;
  // Once we hand the ExamService off to the StudentExamScreen, that
  // screen owns its lifecycle. We must NOT close it here on dispose,
  // or the questions / socket would be torn down before the exam
  // screen can use them.
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _examService.addListener(_onExamUpdate);
  }

  @override
  void dispose() {
    _examService.removeListener(_onExamUpdate);
    if (!_handedOff) {
      _examService.close();
    }
    _pinController.dispose();
    super.dispose();
  }

  void _onExamUpdate() {
    if (!mounted) return;
    if (_examService.state == ExamState.inProgress) {
      // Hand off ownership BEFORE pushReplacement so dispose doesn't
      // tear down the live socket and clear the questions.
      _handedOff = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentExamScreen(examService: _examService),
        ),
      );
      return;
    }
    if (_examService.rejectReason != null) {
      setState(() => _error = _examService.rejectReason);
    } else {
      setState(() {});
    }
  }

  Future<void> _join() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'PIN must be 6 digits.');
      return;
    }
    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;
    if (profile == null) {
      setState(() => _error = 'No profile selected. Please pick a profile first.');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    final err = await _examService.joinByPin(
      pin: pin,
      profileId: profile.id,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      level: profile.currentLevel,
    );
    if (!mounted) return;
    setState(() {
      _joining = false;
      if (err != null) _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;
    final exam = _examService;
    final isWaiting = exam.state == ExamState.waiting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Exam'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (profile != null)
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Text(profile.avatarEmoji,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.displayName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            Text('Level: ${profile.currentLevel}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isWaiting) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        exam.isApproved
                            ? 'You\'re in! Waiting for the teacher to start the exam...'
                            : 'Joined! Waiting for the teacher to approve you...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exam.isApproved
                            ? 'The questions will appear automatically when the teacher taps Start.'
                            : 'Your teacher will see your name and approve you to join.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'Enter the 6-digit PIN your teacher is showing',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                    fontSize: 36,
                  ),
                  filled: true,
                  fillColor: Colors.indigo.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.indigo.shade200, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onSubmitted: (_) => _join(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _joining ? null : _join,
                icon: _joining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_joining ? 'Joining...' : 'Join Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
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
