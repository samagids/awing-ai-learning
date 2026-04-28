import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/exam_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
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
  // Where to draw question content from: 'vocabulary', 'alphabet',
  // 'tones', 'phrases', or 'all'.
  String _selectedSource = 'vocabulary';
  // Vocabulary categories the teacher wants to draw from. Empty set
  // means "all categories".
  final Set<String> _selectedCategories = {};
  // True once we've handed the ExamService off to the monitor screen.
  // After hand-off, the monitor screen owns its lifecycle — we must NOT
  // close it here on dispose, or the room would shut down (and the PIN
  // would vanish) the moment we navigate away.
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _examService.startAsTeacher();
    // Initialize with all available types for beginner
    _selectedQuestionTypes = _getAvailableQuestionTypesForSource(
        'beginner', 'vocabulary');
  }

  @override
  void dispose() {
    if (!_handedOff) {
      _examService.close();
    }
    super.dispose();
  }

  /// Get available question types based on level (legacy — kept as shim).
  Set<String> _getAvailableQuestionTypes(String level) =>
      _getAvailableQuestionTypesForSource(level, _selectedSource);

  /// Question types that make sense for the given (level, source) combo.
  Set<String> _getAvailableQuestionTypesForSource(
      String level, String source) {
    final out = <String>{};
    switch (source) {
      case 'vocabulary':
        out.addAll([
          'translate_to_english',
          'translate_to_awing',
          'category_match',
        ]);
        if (level != 'beginner') out.add('identify_tone');
        if (level == 'expert') out.add('spelling');
        break;
      case 'alphabet':
        out.addAll(['letter_to_sound', 'sound_to_letter', 'letter_example']);
        break;
      case 'tones':
        out.addAll(['identify_tone', 'tone_minimal_pair']);
        break;
      case 'phrases':
        out.addAll(['translate_to_english', 'translate_to_awing']);
        break;
      case 'all':
        out.addAll([
          'translate_to_english',
          'translate_to_awing',
          'category_match',
          'letter_to_sound',
          'sound_to_letter',
        ]);
        if (level != 'beginner') {
          out.addAll(['identify_tone', 'tone_minimal_pair']);
        }
        if (level == 'expert') out.add('spelling');
        break;
    }
    return out;
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'vocabulary':
        return 'Vocabulary';
      case 'alphabet':
        return 'Alphabet';
      case 'tones':
        return 'Tones';
      case 'phrases':
        return 'Phrases';
      case 'all':
        return 'Mixed (all)';
    }
    return source;
  }

  /// All vocabulary categories present in the data, sorted by label.
  List<String> _allCategories() {
    final set = <String>{};
    for (final w in allVocabulary) {
      set.add(w.category);
    }
    final list = set.toList()
      ..sort((a, b) => _getCategoryLabel(a).compareTo(_getCategoryLabel(b)));
    return list;
  }

  /// Filter the vocabulary list by the teacher's category selection.
  /// Empty selection = all categories.
  List<AwingWord> _filteredVocabulary() {
    if (_selectedCategories.isEmpty) return allVocabulary;
    return allVocabulary
        .where((w) => _selectedCategories.contains(w.category))
        .toList();
  }

  /// Build a multiple-choice list with **exactly 4 unique entries** that
  /// always includes [correct]. Distractors are drawn first from
  /// [preferred], then from [fallback], then synthesised as a last
  /// resort so the question is never short on options.
  ///
  /// Returns null if even after fallback we couldn't reach 4 distinct
  /// strings — the caller should retry with a different question.
  List<String>? _buildChoices({
    required String correct,
    required Iterable<String> preferred,
    Iterable<String> fallback = const <String>[],
    Random? random,
  }) {
    final r = random ?? Random();
    final norm = correct.trim();
    if (norm.isEmpty) return null;

    final picked = <String>{norm};

    void absorb(Iterable<String> source) {
      final list = source
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s != norm && !picked.contains(s))
          .toSet()
          .toList()
        ..shuffle(r);
      for (final s in list) {
        if (picked.length >= 4) break;
        picked.add(s);
      }
    }

    absorb(preferred);
    if (picked.length < 4) absorb(fallback);

    if (picked.length < 4) return null;

    final out = picked.toList()..shuffle(r);
    return out;
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
      case 'letter_to_sound':
        return 'What sound does this letter make?';
      case 'sound_to_letter':
        return 'Which letter makes this sound?';
      case 'letter_example':
        return 'Which Awing word starts with this letter?';
      case 'tone_minimal_pair':
        return 'What is the meaning of this word?';
      default:
        return 'Answer this question';
    }
  }

  /// Auto-generate a question of a specific type, honoring the teacher's
  /// source + category selection.
  ExamQuestion? _generateQuestionOfType(String type) {
    final random = Random();

    switch (type) {
      // Vocabulary sources
      case 'translate_to_english':
        final pool = _phrasePoolIfPhrasesSource() ?? _filteredVocabulary();
        if (pool.isEmpty) return null;
        if (pool is List<AwingPhrase>) {
          return _generatePhraseToEnglish(random, pool);
        }
        return _generateTranslateToEnglish(
            random, pool as List<AwingWord>);
      case 'translate_to_awing':
        final pool = _phrasePoolIfPhrasesSource() ?? _filteredVocabulary();
        if (pool.isEmpty) return null;
        if (pool is List<AwingPhrase>) {
          return _generatePhraseToAwing(random, pool);
        }
        return _generateTranslateToAwing(random, pool as List<AwingWord>);
      case 'category_match':
        final pool = _filteredVocabulary();
        if (pool.isEmpty) return null;
        return _generateCategoryMatch(random, pool);
      case 'identify_tone':
        final pool = _filteredVocabulary();
        if (pool.isEmpty) return null;
        return _generateIdentifyTone(random, pool);
      case 'spelling':
        final pool = _filteredVocabulary();
        if (pool.isEmpty) return null;
        return _generateSpelling(random, pool);

      // Alphabet
      case 'letter_to_sound':
        return _generateLetterToSound(random);
      case 'sound_to_letter':
        return _generateSoundToLetter(random);
      case 'letter_example':
        return _generateLetterExample(random);

      // Tones
      case 'tone_minimal_pair':
        return _generateToneMinimalPair(random);

      default:
        return null;
    }
  }

  /// If the source is 'phrases', return the phrase list; otherwise null
  /// so the caller falls back to vocabulary.
  List<dynamic>? _phrasePoolIfPhrasesSource() {
    if (_selectedSource != 'phrases') return null;
    if (awingPhrases.isEmpty) return null;
    return awingPhrases;
  }

  // ----- Alphabet generators -----

  ExamQuestion? _generateLetterToSound(Random random) {
    final letters = awingAlphabet;
    if (letters.isEmpty) return null;
    final letter = letters[random.nextInt(letters.length)];
    final correct = '/${letter.phoneme}/';
    final pool = letters
        .where((l) => l.phoneme != letter.phoneme)
        .map((l) => '/${l.phoneme}/');
    final choices = _buildChoices(
      correct: correct,
      preferred: pool,
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: letter.letter,
      type: 'letter_to_sound',
      choices: choices,
      correctIndex: choices.indexOf(correct),
    );
  }

  ExamQuestion? _generateSoundToLetter(Random random) {
    final letters = awingAlphabet;
    if (letters.isEmpty) return null;
    final letter = letters[random.nextInt(letters.length)];
    final pool = letters
        .where((l) => l.letter != letter.letter)
        .map((l) => l.letter);
    final choices = _buildChoices(
      correct: letter.letter,
      preferred: pool,
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: '/${letter.phoneme}/',
      type: 'sound_to_letter',
      choices: choices,
      correctIndex: choices.indexOf(letter.letter),
    );
  }

  ExamQuestion? _generateLetterExample(Random random) {
    final letters = awingAlphabet;
    if (letters.isEmpty) return null;
    final letter = letters[random.nextInt(letters.length)];
    final pool = letters
        .where((l) => l.exampleWord != letter.exampleWord)
        .map((l) => l.exampleWord);
    final choices = _buildChoices(
      correct: letter.exampleWord,
      preferred: pool,
      fallback: allVocabulary.map((w) => w.awing),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: letter.letter,
      type: 'letter_example',
      choices: choices,
      correctIndex: choices.indexOf(letter.exampleWord),
    );
  }

  // ----- Tone generators -----

  ExamQuestion? _generateToneMinimalPair(Random random) {
    if (toneMinimalPairs.isEmpty) return null;
    final pair = toneMinimalPairs[random.nextInt(toneMinimalPairs.length)];
    final pairOthers = <String>[
      pair.english2,
      if (pair.english3 != null) pair.english3!,
    ];
    final choices = _buildChoices(
      correct: pair.english1,
      preferred: pairOthers,
      fallback: allVocabulary.map((w) => w.english),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: pair.word1,
      type: 'tone_minimal_pair',
      choices: choices,
      correctIndex: choices.indexOf(pair.english1),
    );
  }

  // ----- Phrase generators -----

  ExamQuestion? _generatePhraseToEnglish(
      Random random, List<AwingPhrase> phrases) {
    final phrase = phrases[random.nextInt(phrases.length)];
    final pool =
        phrases.where((p) => p.english != phrase.english).map((p) => p.english);
    final choices = _buildChoices(
      correct: phrase.english,
      preferred: pool,
      fallback: allVocabulary.map((w) => w.english),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: phrase.awing,
      type: 'translate_to_english',
      choices: choices,
      correctIndex: choices.indexOf(phrase.english),
    );
  }

  ExamQuestion? _generatePhraseToAwing(
      Random random, List<AwingPhrase> phrases) {
    final phrase = phrases[random.nextInt(phrases.length)];
    final pool =
        phrases.where((p) => p.awing != phrase.awing).map((p) => p.awing);
    final choices = _buildChoices(
      correct: phrase.awing,
      preferred: pool,
      fallback: allVocabulary.map((w) => w.awing),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: phrase.english,
      type: 'translate_to_awing',
      choices: choices,
      correctIndex: choices.indexOf(phrase.awing),
    );
  }

  ExamQuestion? _generateTranslateToEnglish(
      Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    // Distractors come from DIFFERENT categories so the question is
    // "do you know what this word means?" rather than "guess between
    // similar foods/animals/etc." (per teacher feedback).
    final differentCategory = allVocabulary
        .where((w) => w.category != word.category && w.english != word.english)
        .map((w) => w.english);
    final choices = _buildChoices(
      correct: word.english,
      preferred: differentCategory,
      // Only fall back to broader vocab (which may include same category)
      // if there genuinely aren't 3 different-category distractors — extremely
      // unlikely with our 1500+ word dataset.
      fallback: allVocabulary
          .where((w) => w.english != word.english)
          .map((w) => w.english),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: word.awing,
      type: 'translate_to_english',
      choices: choices,
      correctIndex: choices.indexOf(word.english),
      imageKey: word.awing,
      imageEnglish: word.english,
    );
  }

  ExamQuestion? _generateTranslateToAwing(
      Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final differentCategory = allVocabulary
        .where((w) => w.category != word.category && w.awing != word.awing)
        .map((w) => w.awing);
    final choices = _buildChoices(
      correct: word.awing,
      preferred: differentCategory,
      fallback: allVocabulary
          .where((w) => w.awing != word.awing)
          .map((w) => w.awing),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: word.english,
      type: 'translate_to_awing',
      choices: choices,
      correctIndex: choices.indexOf(word.awing),
      imageKey: word.awing,
      imageEnglish: word.english,
    );
  }

  ExamQuestion? _generateCategoryMatch(
      Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final categoryName = _getCategoryLabel(word.category);
    final otherCategories =
        allVocabulary.where((w) => w.category != word.category).map((w) => w.awing);
    final choices = _buildChoices(
      correct: word.awing,
      preferred: otherCategories,
      fallback: allVocabulary.map((w) => w.awing),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: categoryName,
      type: 'category_match',
      choices: choices,
      correctIndex: choices.indexOf(word.awing),
      // NO imageKey — the image would reveal the correct answer.
    );
  }

  ExamQuestion? _generateIdentifyTone(
      Random random, List<AwingWord> allWords) {
    final wordsWithTone = allWords
        .where((w) => w.tonePattern != null && w.tonePattern!.isNotEmpty)
        .toList();
    if (wordsWithTone.isEmpty) return _generateTranslateToEnglish(random, allWords);

    final word = wordsWithTone[random.nextInt(wordsWithTone.length)];
    final tonePattern = (word.tonePattern ?? '').toLowerCase();
    String capitalize(String s) =>
        s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
    final correctTone = capitalize(tonePattern.split('-').first);

    // Always have 5 candidate tones so we can guarantee 4 unique choices.
    const allTones = ['High', 'Mid', 'Low', 'Rising', 'Falling'];
    final choices = _buildChoices(
      correct: correctTone,
      preferred: allTones.where((t) => t != correctTone),
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: word.awing,
      type: 'identify_tone',
      choices: choices,
      correctIndex: choices.indexOf(correctTone),
      imageKey: word.awing,
      imageEnglish: word.english,
    );
  }

  ExamQuestion? _generateSpelling(Random random, List<AwingWord> allWords) {
    final word = allWords[random.nextInt(allWords.length)];
    final awing = word.awing;
    // Distractor spellings from OTHER categories so the only confusion
    // is the spelling itself, not "is this a different food?".
    final fromOtherCats = allVocabulary
        .where((w) => w.category != word.category && w.awing != awing)
        .map((w) => w.awing);
    // Synthesised misspellings as a last-resort distractor source.
    final fakes = <String>[
      '${awing}ə',
      '${awing}a',
      'ə$awing',
      awing.length > 1
          ? awing.substring(0, awing.length - 1)
          : '${awing}ə',
    ];
    final choices = _buildChoices(
      correct: awing,
      preferred: fromOtherCats,
      fallback: fakes,
      random: random,
    );
    if (choices == null) return null;
    return ExamQuestion(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      questionText: word.english,
      type: 'spelling',
      choices: choices,
      correctIndex: choices.indexOf(awing),
      imageKey: word.awing,
      imageEnglish: word.english,
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'body': 'Body parts',
      'bodyParts': 'Body parts',
      'animals': 'Animals',
      'nature': 'Nature',
      'actions': 'Actions / verbs',
      'things': 'Things & objects',
      'thingsObjects': 'Things & objects',
      'family': 'Family & people',
      'familyPeople': 'Family & people',
      'food': 'Food & drink',
      'foodDrink': 'Food & drink',
      'descriptive': 'Describing words',
      'descriptiveWords': 'Describing words',
      'numbers': 'Numbers',
      'pronouns': 'Pronouns',
      'time': 'Time words',
      'classroom': 'Classroom',
      'daily': 'Daily life',
      'question': 'Question words',
    };
    return labels[category] ?? category;
  }

  String _getQuestionTypeLabel(String type) {
    const labels = {
      'translate_to_english': 'Awing → English',
      'translate_to_awing': 'English → Awing',
      'category_match': 'Category match',
      'identify_tone': 'Identify tone',
      'spelling': 'Correct spelling',
      'letter_to_sound': 'Letter → sound',
      'sound_to_letter': 'Sound → letter',
      'letter_example': 'Letter → example word',
      'tone_minimal_pair': 'Tone meaning',
    };
    return labels[type] ?? type;
  }

  /// Auto-generate a question. Retries up to ~30 times in case a small
  /// pool randomly fails to produce 4 unique choices, and randomises the
  /// chosen question type each attempt so a single bad type doesn't
  /// block the whole batch.
  void _addAutoQuestion() {
    if (_selectedQuestionTypes.isEmpty) {
      setState(() => _error = 'Select at least one question type.');
      return;
    }
    final selectable = _selectedQuestionTypes.toList();
    final random = Random();

    ExamQuestion? question;
    for (var attempt = 0; attempt < 30; attempt++) {
      final type = selectable[random.nextInt(selectable.length)];
      final candidate = _generateQuestionOfType(type);
      if (candidate == null) continue;
      // Final hard guard: must have 4 unique non-empty choices and a
      // valid correctIndex pointing at a real choice.
      final unique = <String>{};
      for (final c in candidate.choices) {
        final t = c.trim();
        if (t.isNotEmpty) unique.add(t);
      }
      if (unique.length != 4) continue;
      if (candidate.correctIndex < 0 ||
          candidate.correctIndex >= candidate.choices.length) {
        continue;
      }
      question = candidate;
      break;
    }

    if (question == null) {
      setState(() => _error =
          'Not enough material to build a 4-choice question with the current filters. Try adding more categories or switching the source.');
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

    final auth = context.read<AuthService>();
    final teacherName = auth.currentProfile?.displayName ?? 'Teacher';

    final error = await _examService.openExamRoom(teacherName);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (mounted) {
      // Mark hand-off BEFORE we navigate. pushReplacement disposes this
      // screen, which would otherwise call _examService.close() and shut
      // the room down before students can join.
      _handedOff = true;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error!,
                        style: TextStyle(color: Colors.red.shade700)),
                    if (_examService.permissionsPermanentlyDenied) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await _examService.openPermissionSettings();
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () async {
                              final err = await _examService
                                  .requestPermissionsWithReason();
                              setState(() => _error = err);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ] else if ((_error ?? '').toLowerCase().contains('permission') ||
                        (_error ?? '').toLowerCase().contains('bluetooth') ||
                        (_error ?? '').toLowerCase().contains('location')) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final err = await _examService
                                .requestPermissionsWithReason();
                            setState(() => _error = err);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Grant permissions'),
                        ),
                      ),
                    ],
                  ],
                ),
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
                          _selectedQuestionTypes =
                              _getAvailableQuestionTypesForSource(
                                  _selectedLevel, _selectedSource);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Source selector — what kind of content the questions draw from.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Source',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Where the questions come from',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final src in const [
                          'vocabulary',
                          'alphabet',
                          'tones',
                          'phrases',
                          'all',
                        ])
                          ChoiceChip(
                            label: Text(_getSourceLabel(src)),
                            selected: _selectedSource == src,
                            onSelected: (sel) {
                              if (!sel) return;
                              setState(() {
                                _selectedSource = src;
                                _selectedQuestionTypes =
                                    _getAvailableQuestionTypesForSource(
                                        _selectedLevel, src);
                                if (src != 'vocabulary' && src != 'all') {
                                  _selectedCategories.clear();
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Category multi-select — only shown when source uses vocabulary.
            if (_selectedSource == 'vocabulary' || _selectedSource == 'all') ...[
              const SizedBox(height: 12),
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
                            'Categories',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedCategories.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedCategories.clear());
                              },
                              child: const Text('All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategories.isEmpty
                            ? 'No filter — questions can be from any category'
                            : 'Only ${_selectedCategories.length} category(ies) selected',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in _allCategories())
                            FilterChip(
                              label: Text(_getCategoryLabel(cat)),
                              selected: _selectedCategories.contains(cat),
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _selectedCategories.add(cat);
                                  } else {
                                    _selectedCategories.remove(cat);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
