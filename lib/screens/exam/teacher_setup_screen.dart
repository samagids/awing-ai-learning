import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/exam_service.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/data/awing_alphabet.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/screens/exam/teacher_monitor_screen.dart';

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({Key? key}) : super(key: key);

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  final ExamService _examService = ExamService();
  String _selectedLevel = 'beginner';
  int _timeLimit = 15;
  String? _error;
  late Set<String> _selectedQuestionTypes;

  @override
  void initState() {
    super.initState();
    _examService.startAsTeacher();
    // Initialize with all available types for beginner
    _selectedQuestionTypes = _getAvailableQuestionTypes('beginner');
  }

  @override
  void dispose() {
    _examService.close();
    super.dispose();
  }

  /// Get available question types based on level
  Set<String> _getAvailableQuestionTypes(String level) {
    return {
      'translate_to_english',
      'translate_to_awing',
      'category_match',
      if (level != 'beginner') 'identify_tone',
      if (level == 'expert') 'spelling',
    };
  }

  /// Get prompt text for a question type
  String _getPromptForType(String type) {
    switch (type) {
      case 'translate_to_english':
        return 'What does this mean in English?';
      case 'translate_to_awing':
        return 'How do you say this in Awing?';
      case 'category_match':
        return 'Which word belongs to this category?';
      case 'identify_tone':
        return 'What tone does this word have?';
      case 'spelling':
        return 'Which is the correct Awing spelling?';
      default:
        return 'Answer this question';
    }
  }

  /// Auto-generate a question of a specific type
  ExamQuestion? _generateQuestionOfType(String type) {
    final random = Random();
    final allWords = allVocabulary;

    if (allWords.isEmpty) return null;

    switch (type) {
      case 'translate_to_english':
        return _generateTranslateToEnglish(random, allWords);
      case 'translate_to_awing':
        return _generateTranslateToAwing(random, allWords);
      case 'category_match':
        return _generateCategoryMatch(random, allWords);
      case 'identify_tone':
        return _generateIdentifyTone(random, allWords);
      case 'spelling':
        return _generateSpelling(random, allWords);
      default:
        return null;
    }
  }

  ExamQuestion _generateTranslateToEnglish(Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final sameCategory = allWords
        .where((w) => w.category == word.category && w.english != word.english)
        .toList();
    sameCategory.shuffle();

    final wrongWords = sameCategory.isNotEmpty
        ? sameCategory.take(3).map((w) => w.english).toList()
        : allWords
            .where((w) => w.english != word.english)
            .take(3)
            .map((w) => w.english)
            .toList();

    final choices = [...wrongWords, word.english]..shuffle();
    final correctIndex = choices.indexOf(word.english);

    return ExamQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      questionText: word.awing,
      type: 'translate_to_english',
      choices: choices,
      correctIndex: correctIndex,
    );
  }

  ExamQuestion _generateTranslateToAwing(Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final sameCategory = allWords
        .where((w) => w.category == word.category && w.english != word.english)
        .toList();
    sameCategory.shuffle();

    final wrongWords = sameCategory.isNotEmpty
        ? sameCategory.take(3).map((w) => w.awing).toList()
        : allWords
            .where((w) => w.english != word.english)
            .take(3)
            .map((w) => w.awing)
            .toList();

    final choices = [...wrongWords, word.awing]..shuffle();
    final correctIndex = choices.indexOf(word.awing);

    return ExamQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      questionText: word.english,
      type: 'translate_to_awing',
      choices: choices,
      correctIndex: correctIndex,
    );
  }

  ExamQuestion _generateCategoryMatch(Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final categoryName = _getCategoryLabel(word.category);

    final otherCategories = allWords
        .where((w) => w.category != word.category)
        .toList();
    otherCategories.shuffle();

    final wrongWords = otherCategories.take(3).map((w) => w.awing).toList();
    final choices = [...wrongWords, word.awing]..shuffle();
    final correctIndex = choices.indexOf(word.awing);

    return ExamQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      questionText: categoryName,
      type: 'category_match',
      choices: choices,
      correctIndex: correctIndex,
    );
  }

  ExamQuestion _generateIdentifyTone(Random random, List<AwingWord> allWords) {
    final wordsWithTone = allWords.where((w) => w.tonePattern != null && w.tonePattern!.isNotEmpty).toList();
    if (wordsWithTone.isEmpty) {
      return _generateTranslateToEnglish(random, allWords);
    }

    final word = wordsWithTone[random.nextInt(wordsWithTone.length)];
    final tonePattern = word.tonePattern ?? '';

    // For beginner, simplify to High/Mid/Low
    final toneMap = {
      'High': 'High',
      'Mid': 'Mid',
      'Low': 'Low',
      'Rising': 'Rising',
      'Falling': 'Falling',
    };

    final correctTone = toneMap[tonePattern] ?? 'Mid';
    final allTones = ['High', 'Mid', 'Low'];
    allTones.removeWhere((t) => t == correctTone);
    allTones.shuffle();
    final wrongTones = allTones.take(3).toList();

    final choices = [...wrongTones, correctTone]..shuffle();
    final correctIndex = choices.indexOf(correctTone);

    return ExamQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      questionText: word.awing,
      type: 'identify_tone',
      choices: choices,
      correctIndex: correctIndex,
    );
  }

  ExamQuestion _generateSpelling(Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];

    // Create misspellings by swapping or removing characters
    final wrongSpellings = <String>[];
    final awing = word.awing;

    // Try to create 3 plausible misspellings
    while (wrongSpellings.length < 3 && wrongSpellings.length < allWords.length) {
      final candidate = allWords[random.nextInt(allWords.length)];
      if (candidate.awing != awing && !wrongSpellings.contains(candidate.awing)) {
        wrongSpellings.add(candidate.awing);
      }
    }

    // Pad if needed
    while (wrongSpellings.length < 3) {
      wrongSpellings.add('${awing}ə');
    }

    final choices = [...wrongSpellings, awing]..shuffle();
    final correctIndex = choices.indexOf(awing);

    return ExamQuestion(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      questionText: word.english,
      type: 'spelling',
      choices: choices,
      correctIndex: correctIndex,
    );
  }

  String _getCategoryLabel(String category) {
    final labels = {
      'bodyParts': 'Body Parts',
      'animals': 'Animals',
      'actions': 'Actions',
      'thingsObjects': 'Things & Objects',
      'familyPeople': 'Family & People',
      'foodDrink': 'Food & Drink',
      'descriptiveWords': 'Descriptive Words',
      'numbers': 'Numbers',
    };
    return labels[category] ?? category;
  }

  String _getQuestionTypeLabel(String type) {
    final labels = {
      'translate_to_english': 'English Translation',
      'translate_to_awing': 'Awing Translation',
      'category_match': 'Category Match',
      'identify_tone': 'Identify Tone',
      'spelling': 'Spelling',
    };
    return labels[type] ?? type;
  }

  /// Auto-generate questions from the app's vocabulary/alphabet data.
  void _addAutoQuestion() {
    if (_selectedQuestionTypes.isEmpty) {
      setState(() => _error = 'Select at least one question type.');
      return;
    }

    final random = Random();
    final selectedType = _selectedQuestionTypes.toList()[random.nextInt(_selectedQuestionTypes.length)];

    final question = _generateQuestionOfType(selectedType);
    if (question == null) {
      setState(() => _error = 'Could not generate question. Try again.');
      return;
    }

    _examService.addQuestion(question);
    setState(() => _error = null);
  }

  /// Add a custom question via dialog.
  void _addCustomQuestion() {
    final questionController = TextEditingController();
    final choiceControllers = List.generate(4, (_) => TextEditingController());
    int correctChoice = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDialogState) {
          return AlertDialog(
            title: const Text('Add Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question (Awing text)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: correctChoice,
                            onChanged: (v) {
                              setDialogState(() => correctChoice = v!);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: choiceControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Choice ${i + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Text(
                    'Select the correct answer with the radio button',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final choices =
                      choiceControllers.map((c) => c.text.trim()).toList();
                  if (questionController.text.trim().isEmpty ||
                      choices.any((c) => c.isEmpty)) {
                    return;
                  }
                  _examService.addQuestion(ExamQuestion(
                    id: 'q_${DateTime.now().millisecondsSinceEpoch}',
                    questionText: questionController.text.trim(),
                    type: 'translate_to_english',
                    choices: choices,
                    correctIndex: correctChoice,
                  ));
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Add multiple auto-generated questions at once.
  void _addBulkQuestions(int count) {
    for (int i = 0; i < count; i++) {
      _addAutoQuestion();
    }
  }

  /// Open the exam room and navigate to monitor screen.
  Future<void> _openRoom() async {
    if (_examService.questions.isEmpty) {
      setState(() => _error = 'Add at least one question before opening the room.');
      return;
    }

    _examService.setExamLevel(_selectedLevel);
    _examService.setTimeLimit(_timeLimit);

    final error = await _examService.openExamRoom();
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherMonitorScreen(examService: _examService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Exam'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 16),
            ],

            // Level selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exam Level',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All participants must be at this level to join.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'beginner', label: Text('Beginner')),
                        ButtonSegment(value: 'medium', label: Text('Medium')),
                        ButtonSegment(value: 'expert', label: Text('Expert')),
                      ],
                      selected: {_selectedLevel},
                      onSelectionChanged: (s) {
                        setState(() {
                          _selectedLevel = s.first;
                          // Update available question types for new level
                          _selectedQuestionTypes = _getAvailableQuestionTypes(_selectedLevel);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Question Types selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Question Types',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedQuestionTypes = _getAvailableQuestionTypes(_selectedLevel);
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select which question types to include',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAvailableQuestionTypes(_selectedLevel).map((type) {
                        final isSelected = _selectedQuestionTypes.contains(type);
                        final label = _getQuestionTypeLabel(type);
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedQuestionTypes.add(type);
                              } else {
                                if (_selectedQuestionTypes.length > 1) {
                                  _selectedQuestionTypes.remove(type);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time limit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Limit',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _timeLimit.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            label: '$_timeLimit min',
                            onChanged: (v) {
                              setState(() => _timeLimit = v.round());
                            },
                          ),
                        ),
                        Text(
                          '$_timeLimit min',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Questions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions (${_examService.questions.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle, color: Colors.indigo),
                          onSelected: (v) {
                            switch (v) {
                              case 'auto_1':
                                _addAutoQuestion();
                                break;
                              case 'auto_5':
                                _addBulkQuestions(5);
                                break;
                              case 'auto_10':
                                _addBulkQuestions(10);
                                break;
                              case 'auto_20':
                                _addBulkQuestions(20);
                                break;
                              case 'custom':
                                _addCustomQuestion();
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'auto_1', child: Text('Add 1 random question')),
                            PopupMenuItem(value: 'auto_5', child: Text('Add 5 random questions')),
                            PopupMenuItem(value: 'auto_10', child: Text('Add 10 random questions')),
                            PopupMenuItem(value: 'auto_20', child: Text('Add 20 random questions')),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'custom', child: Text('Add custom question')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_examService.questions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No questions yet.\nTap + to add questions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_examService.questions.length, (i) {
                        final q = _examService.questions[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(
                            q.questionText,
                            style: const TextStyle(fontSize: 15),
                          ),
                          subtitle: Text(
                            'Answer: ${q.choices[q.correctIndex]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _examService.removeQuestion(i);
                              setState(() {});
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Open room button
            ElevatedButton.icon(
              onPressed: _openRoom,
              icon: const Icon(Icons.wifi),
              label: const Text('Open Exam Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
