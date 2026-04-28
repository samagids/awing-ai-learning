import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/exam_service.dart';

class StudentExamScreen extends StatefulWidget {
  final ExamService examService;

  const StudentExamScreen({Key? key, required this.examService})
      : super(key: key);

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen> {
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

  /// Kid-friendly, self-contained question prompt that EMBEDS the word so
  /// the student can read it as one complete sentence. Uses an emoji to
  /// make it feel like a game rather than a test.
  String _getPromptForType(String type, String questionText) {
    final q = questionText.trim();
    switch (type) {
      case 'translate_to_english':
        return '🤔 What does "$q" mean?';
      case 'translate_to_awing':
        return '🗣️ How do you say "$q" in Awing?';
      case 'category_match':
        // questionText is the category label, e.g. "Food & drink".
        final lower = q.toLowerCase();
        // Strip leading article-ish bits to make it read naturally.
        final trimmed = lower.startsWith('the ') ? lower.substring(4) : lower;
        return '🔍 Which one is a ${_singular(trimmed)}?';
      case 'identify_tone':
        return '🎵 What tone does "$q" use?';
      case 'spelling':
        return '✍️ How do you spell "$q" in Awing?';
      case 'letter_to_sound':
        return '🔤 What sound does the letter "$q" make?';
      case 'sound_to_letter':
        return '🔊 Which letter makes the sound $q?';
      case 'letter_example':
        return '🚀 Which word starts with the letter "$q"?';
      case 'tone_minimal_pair':
        return '🤔 What does "$q" mean?';
      default:
        return 'Answer this question';
    }
  }

  /// Turn a category label into a naturally-readable singular noun.
  /// "Food & drink" → "food", "Animals" → "animal",
  /// "Body parts" → "body part", "Actions / verbs" → "action".
  String _singular(String label) {
    // Collapse "X & Y" / "X / Y" down to the first chunk so the question
    // stays short: "food & drink" → "food".
    var s = label;
    for (final sep in const [' & ', ' / ', '/', ',']) {
      final i = s.indexOf(sep);
      if (i > 0) {
        s = s.substring(0, i);
        break;
      }
    }
    s = s.trim();
    // Simple English plural → singular.
    if (s.endsWith('ies') && s.length > 3) {
      s = '${s.substring(0, s.length - 3)}y';
    } else if (s.endsWith('es') && s.length > 2) {
      s = s.substring(0, s.length - 2);
    } else if (s.endsWith('s') && s.length > 1 && !s.endsWith('ss')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.examService;

    if (exam.state == ExamState.finished) {
      return _buildResultsView(exam);
    }

    if (exam.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam'), backgroundColor: Colors.indigo),
        body: const Center(child: Text('No questions loaded.')),
      );
    }

    final question = exam.questions[exam.currentQuestionIndex];
    final selectedAnswer =
        exam.myParticipant?.answers[question.id];

    return WillPopScope(
      onWillPop: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Exam?'),
            content: const Text('Your answers will be submitted automatically.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave & Submit'),
              ),
            ],
          ),
        );
        if (leave == true) {
          exam.submitExam();
        }
        return leave ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Question ${exam.currentQuestionIndex + 1} of ${exam.questions.length}',
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            // Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatTime(exam.secondsRemaining),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: exam.secondsRemaining < 60
                        ? Colors.red.shade200
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (exam.currentQuestionIndex + 1) / exam.questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
              const SizedBox(height: 16),

              // Question
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Kid-friendly prompt that embeds the word as a
                      // complete sentence — e.g. "🤔 What does tátə mean?"
                      Text(
                        _getPromptForType(
                            question.type, question.questionText),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Show the companion image whenever imageKey is set.
                      // (Category-match questions set imageKey=null so the
                      // picture doesn't leak the correct answer.)
                      // PackImage has its own built-in fallback icon for
                      // words that don't have a generated image file.
                      if (question.imageKey != null &&
                          question.imageKey!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final imageSize =
                                (MediaQuery.of(context).size.width * 0.45)
                                    .clamp(90.0, 120.0);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: imageSize,
                                height: imageSize,
                                child: PackImage(
                                  awingWord: question.imageKey!,
                                  english: question.imageEnglish ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Choices
              ...List.generate(question.choices.length, (i) {
                final isSelected = selectedAnswer == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      exam.answerQuestion(question.id, i);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      backgroundColor: isSelected
                          ? Colors.indigo.shade50
                          : null,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.indigo
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.indigo
                                : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i), // A, B, C, D
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.choices[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Navigation
              Row(
                children: [
                  if (exam.currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => exam.previousQuestion(),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (exam.currentQuestionIndex > 0)
                    const SizedBox(width: 12),
                  Expanded(
                    child: exam.currentQuestionIndex ==
                            exam.questions.length - 1
                        ? ElevatedButton(
                            onPressed: () => _confirmSubmit(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit Exam',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => exam.nextQuestion(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Next'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubmit() {
    final exam = widget.examService;
    final answered = exam.myParticipant?.answers.length ?? 0;
    final total = exam.questions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          answered < total
              ? 'You answered $answered of $total questions. '
                'Unanswered questions will be marked wrong.'
              : 'You answered all $total questions. Submit now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              exam.submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(ExamService exam) {
    final score = exam.myParticipant?.score ?? 0;
    final passed = score >= 90;
    final totalQ = exam.questions.length;
    final correctQ = (score * totalQ / 100).round();

    AnalyticsService.instance.logQuiz(
      quizType: 'exam',
      level: exam.examLevel,
      scorePercent: score,
      correct: correctQ,
      total: totalQ,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                passed ? '🎉' : '📝',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                '${score}%',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed ? 'Excellent! You passed!' : 'Keep practicing!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: passed
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need 90% to pass',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await exam.close();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
