import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Data class for a single story
class AwingStory {
  final String titleEnglish;
  final String titleAwing;
  final String illustration; // emoji/icon placeholder
  final List<StorySentence> sentences;
  final List<StoryVocabulary> vocabulary;
  final List<ComprehensionQuestion> questions;
  bool isCompleted;

  AwingStory({
    required this.titleEnglish,
    required this.titleAwing,
    required this.illustration,
    required this.sentences,
    required this.vocabulary,
    required this.questions,
    this.isCompleted = false,
  });
}

/// A sentence in a story
class StorySentence {
  final String awing;
  final String english;

  const StorySentence({
    required this.awing,
    required this.english,
  });
}

/// Vocabulary item with Awing and English
class StoryVocabulary {
  final String awing;
  final String english;

  const StoryVocabulary({
    required this.awing,
    required this.english,
  });
}

/// Multiple choice comprehension question
class ComprehensionQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options; // includes correct answer, already shuffled

  const ComprehensionQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

/// ============================================================================
/// STORY DATA — 4 short Awing stories for kids
/// ============================================================================

/// AUDIT 2026-04-29 (audit_screen_glosses.py):
/// All 7 previously-hardcoded stories used Awing words with WRONG
/// English glosses. The 2007 Awing English Dictionary says:
///
///   koŋə    = 'crawl, slither'   (NOT 'owl')
///   alá'ə   = 'much, a lot'      (NOT 'village')
///   pímə    = 'believe; accept'  (NOT 'see')
///   mbəŋə   = 'drum'             (NOT 'rain')
///   ashî'nə = 'trade'            (NOT 'good')
///   wâakɔ́   = (not in dict)      (was glossed 'water'; closest is wáako = 'sand')
///
/// The Awing sentences themselves were fabricated and the English
/// translations did not match what the Awing actually says. Per the
/// project rule "all Awing content must be PDF-verified or confirmed
/// by Dr. Sama" (Session 30), these stories are removed pending
/// proper authoring with native-speaker review.
///
/// The original 7 stories are preserved in git history at commit
/// 33183df if any are salvageable for re-authoring. Run
/// `python scripts/audit_screen_glosses.py` after adding new content
/// to catch any future drift.
final List<AwingStory> awingStories = [];


/// ============================================================================
/// SCREENS
/// ============================================================================

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Awing Stories'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Stories', icon: Icon(Icons.library_books)),
              Tab(text: 'Vocabulary', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StoryListView(),
            StoryVocabularyView(),
          ],
        ),
      ),
    );
  }
}

class StoryListView extends StatefulWidget {
  const StoryListView({Key? key}) : super(key: key);

  @override
  State<StoryListView> createState() => _StoryListViewState();
}

class _StoryListViewState extends State<StoryListView> {
  late List<AwingStory> _stories = List.from(awingStories);

  void _markStoryComplete(int index) {
    setState(() {
      _stories[index].isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return StoryCard(
          story: story,
          onTap: () async {
            final completed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => StoryViewerScreen(story: story),
              ),
            );
            if (completed == true) {
              _markStoryComplete(index);
            }
          },
        );
      },
    );
  }
}

class StoryCard extends StatelessWidget {
  final AwingStory story;
  final VoidCallback onTap;

  const StoryCard({
    Key? key,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade100,
                Colors.cyan.shade100,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                story.illustration,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.titleEnglish,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.titleAwing,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story.sentences.length} sentences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (story.isCompleted)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.teal,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryViewerScreen extends StatefulWidget {
  final AwingStory story;

  const StoryViewerScreen({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentSentenceIndex = 0;
  bool _showEnglish = false;
  bool _storyCompleted = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
  }

  void _nextSentence() {
    if (_currentSentenceIndex < widget.story.sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _showEnglish = false;
      });
    } else {
      setState(() {
        _storyCompleted = true;
      });
    }
  }

  void _prevSentence() {
    if (_currentSentenceIndex > 0) {
      setState(() {
        _currentSentenceIndex--;
        _showEnglish = false;
      });
    }
  }

  void _speakSentence() {
    final sentence = widget.story.sentences[_currentSentenceIndex];
    _pronunciation.speakAwing(sentence.awing);
  }

  @override
  Widget build(BuildContext context) {
    if (_storyCompleted) {
      return StoryQuizScreen(
        story: widget.story,
        onComplete: () {
          Navigator.pop(context, true);
        },
      );
    }

    final sentence = widget.story.sentences[_currentSentenceIndex];
    final progress = (_currentSentenceIndex + 1) / widget.story.sentences.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.titleEnglish),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Large illustration area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.story.illustration,
                  style: const TextStyle(fontSize: 96),
                  textAlign: TextAlign.center,
                ),
              ),
              // Sentence card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.cyan.shade50],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Awing sentence (always visible)
                            Text(
                              sentence.awing,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // English translation (tap to reveal)
                            if (_showEnglish)
                              Text(
                                sentence.english,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.teal,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              Text(
                                'Tap to reveal English',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 32),
                            // Speaker button
                            FloatingActionButton(
                              onPressed: _speakSentence,
                              backgroundColor: Colors.teal,
                              child: const Icon(Icons.volume_up),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Progress dots
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.story.sentences.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _currentSentenceIndex
                            ? Colors.teal
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentSentenceIndex > 0 ? _prevSentence : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showEnglish = !_showEnglish);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                      ),
                      child: Text(
                        _showEnglish ? 'Hide English' : 'Show English',
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _nextSentence,
                      label: const Text('Next'),
                      icon: const Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pronunciation.dispose();
    super.dispose();
  }
}

class StoryQuizScreen extends StatefulWidget {
  final AwingStory story;
  final VoidCallback onComplete;

  const StoryQuizScreen({
    Key? key,
    required this.story,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  bool _quizCompleted = false;

  void _selectAnswer(String answer) {
    if (_answered) return;

    final isCorrect = answer == widget.story.questions[_currentQuestion].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.story.questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Complete!'),
          backgroundColor: Colors.teal,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade50,
                Colors.cyan.shade50,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 24),
                Text(
                  'Great Job!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You scored $_score/${widget.story.questions.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = widget.story.questions[_currentQuestion];
    final isCorrect = _selectedAnswer == question.correctAnswer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Quiz'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentQuestion + 1}/${widget.story.questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 32),
                ...question.options.map((option) {
                  final isSelected = _selectedAnswer == option;
                  final showCorrect = _answered && option == question.correctAnswer;
                  final showIncorrect = _answered && isSelected && !isCorrect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: _answered ? null : () => _selectAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answered
                            ? showCorrect
                                ? Colors.green
                                : showIncorrect
                                    ? Colors.red
                                    : Colors.grey.shade300
                            : Colors.white,
                        foregroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.black54,
                        side: BorderSide(
                          color: isSelected ? Colors.teal : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                if (_answered)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCorrect ? 'Correct!' : 'Not quite right.',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _nextQuestion,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            _currentQuestion < widget.story.questions.length - 1
                                ? 'Next Question'
                                : 'Finish',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StoryVocabularyView extends StatelessWidget {
  const StoryVocabularyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Collect all vocabulary from all stories
    final allVocab = <String, String>{};
    for (final story in awingStories) {
      for (final vocab in story.vocabulary) {
        allVocab[vocab.awing] = vocab.english;
      }
    }

    final vocabList = allVocab.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vocabList.length,
      itemBuilder: (context, index) {
        final entry = vocabList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.cyan.shade50, Colors.teal.shade50],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    PronunciationService().speakAwing(entry.key);
                  },
                  icon: const Icon(Icons.volume_up),
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
