import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({Key? key}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentConversationIndex = 0;
  int _currentLineIndex = 0;
  bool _showEnglish = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('expert_conversation');
    });
  }

  void _nextLine() {
    if (_currentLineIndex + 1 < _conversations[_currentConversationIndex]['lines'].length) {
      setState(() {
        _currentLineIndex++;
        _showEnglish = false;
      });
    } else if (_currentConversationIndex + 1 < _conversations.length) {
      setState(() {
        _currentConversationIndex++;
        _currentLineIndex = 0;
        _showEnglish = false;
      });
    }
  }

  void _previousLine() {
    if (_currentLineIndex > 0) {
      setState(() {
        _currentLineIndex--;
        _showEnglish = false;
      });
    } else if (_currentConversationIndex > 0) {
      setState(() {
        _currentConversationIndex--;
        _currentLineIndex = _conversations[_currentConversationIndex]['lines'].length - 1;
        _showEnglish = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _currentConversationIndex = 0;
      _currentLineIndex = 0;
      _showEnglish = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversations[_currentConversationIndex];
    final lines = conversation['lines'] as List<Map<String, String>>;
    final currentLine = lines[_currentLineIndex];
    final title = conversation['title'] as String;
    final context_text = conversation['context'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Practice'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conversation header
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context_text,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress
              Text(
                'Dialogue ${_currentConversationIndex + 1} of ${_conversations.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Line ${_currentLineIndex + 1} of ${lines.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Current line display
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: currentLine['speaker'] == 'Person A'
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLine['speaker']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: currentLine['speaker'] == 'Person A'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentLine['awing']!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pronunciation.speakAwing(currentLine['awing']!),
                              icon: const Icon(Icons.volume_up),
                              label: const Text('Hear it'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentLine['speaker'] == 'Person A'
                                    ? Colors.blue
                                    : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _showEnglish = !_showEnglish);
                              },
                              icon: Icon(
                                _showEnglish ? Icons.visibility_off : Icons.visibility,
                              ),
                              label: Text(_showEnglish ? 'Hide' : 'Show'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showEnglish) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'English:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentLine['english']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tips for the conversation
              if (currentLine['tip'] != null) ...[
                Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb, color: Colors.purple.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentLine['tip']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _currentConversationIndex == 0 && _currentLineIndex == 0
                          ? null
                          : _previousLine,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _currentConversationIndex == _conversations.length - 1 &&
                              _currentLineIndex == lines.length - 1
                          ? null
                          : _nextLine,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _currentConversationIndex == _conversations.length - 1 &&
                                _currentLineIndex == lines.length - 1
                            ? 'Done'
                            : 'Next',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Over'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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

const List<Map<String, dynamic>> _conversations = [
  {
    'title': 'Greeting',
    'context': 'Two friends meet on the path',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': "Cha'tɔ́!",
        'english': 'Greetings!',
        'tip': 'Cha\'tɔ́ is the standard greeting. The tone is important!',
      },
      {
        'speaker': 'Person B',
        'awing': "Cha'tɔ́! Yə yǐə?",
        'english': 'Greetings! How are you? (Is he/she coming?)',
        'tip': 'Yə yǐə? is a polite way to ask someone\'s status.',
      },
      {
        'speaker': 'Person A',
        'awing': 'Ndèe, mǎ wə nə mə kwátə.',
        'english': 'Well, my mother is fine.',
        'tip': 'Mǎ (mother) can be used to show respect or closeness.',
      },
    ],
  },
  {
    'title': 'Asking for Something',
    'context': 'A child asks a parent for food',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': 'Mǎ, ndèe?',
        'english': 'Mother, please? (Can I have something?)',
        'tip': 'Ndèe shows respect and politeness when asking.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Ache kə?',
        'english': 'What do you want?',
        'tip': 'Ache means "what". It\'s a natural question word.',
      },
      {
        'speaker': 'Person A',
        'awing': 'Ko akwe pə nəgoomɔ́.',
        'english': 'Give me some plantain, please.',
        'tip': 'Ko means "take/give". Pə shows politeness with the request.',
      },
      {
        'speaker': 'Person B',
        'awing': "Wo'! Ee wə nə fɛ́ə.",
        'english': 'Sure! It is there.',
        'tip': 'Wo\' means "okay". Ee marks agreement and emphasis.',
      },
    ],
  },
  {
    'title': 'Visiting a Friend',
    'context': 'Arriving at a friend\'s house',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': "Cha'tɔ́! Yə yǐə?",
        'english': 'Hello! How are you?',
        'tip': 'This is the standard greeting when arriving.',
      },
      {
        'speaker': 'Person B',
        'awing': "Cha'tɔ́! Yə kwa'ə.",
        'english': 'Hello! I am well.',
        'tip': 'Kwa\'ə shows the person is doing well and happy.',
      },
      {
        'speaker': 'Person A',
        'awing': 'Apô wə nə mə ntô.',
        'english': 'I came to visit (my hand/heart is here).',
        'tip': 'Apô (hand) can represent coming with good intentions.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Ee wə nə mə fɛ́ə. Ko pə asé.',
        'english': 'Good! Come and sit down.',
        'tip': 'Asé means "place" or "sit". Ko is the invitation.',
      },
    ],
  },
  {
    'title': 'Learning Together',
    'context': 'A teacher and student learning Awing',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': 'Ache fɛ́ə ndo?',
        'english': 'What is this thing?',
        'tip': 'Ndo means "thing". This is how you ask what something is.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Ee wə nə apô. A apô.',
        'english': 'It is a hand. A hand.',
        'tip': 'Repeating the word emphasizes it for learning.',
      },
      {
        'speaker': 'Person A',
        'awing': 'Apô. A-po. Akwe?',
        'english': 'Hand. A-po. What does it mean?',
        'tip': 'Breaking it down helps with learning pronunciation.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Apô wə nə ajúmə wə nə mə pə ko.',
        'english': 'A hand is the thing we use to take things.',
        'tip': 'This explanation helps understand the word through context.',
      },
    ],
  },
  {
    'title': 'Simple Exchange',
    'context': 'Quick daily conversation',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': 'Ee wə nə kó?',
        'english': 'Is it good?',
        'tip': 'Kó can mean "good" or "fine". This asks for confirmation.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Ee! Kó ndo! Ndèe?',
        'english': 'Yes! Good thing! Please?',
        'tip': 'Ndèe at the end makes a statement turn into a polite question.',
      },
      {
        'speaker': 'Person A',
        'awing': 'Wo\'! Ee ndèe mə kwa\'ə.',
        'english': 'Sure! That\'s very good.',
        'tip': 'Wo\' is agreement. Ndèe adds emphasis and politeness.',
      },
    ],
  },
  {
    'title': 'Farewell',
    'context': 'Saying goodbye to a friend',
    'lines': [
      {
        'speaker': 'Person A',
        'awing': 'Tifwə nə pə zə wǎ lɛ́ə.',
        'english': 'I will go now.',
        'tip': 'Tifwə shows gentle intention to leave.',
      },
      {
        'speaker': 'Person B',
        'awing': 'Akwe! Wə yǐə ndèe.',
        'english': 'Okay! Come back please.',
        'tip': 'Ndèe at the end makes this a hopeful request.',
      },
      {
        'speaker': 'Person A',
        'awing': "Ee! Cha'tɔ́ ndèe!",
        'english': 'Yes! Goodbye! (Greetings please!)',
        'tip': 'Cha\'tɔ́ means both "hello" and "goodbye" depending on context.',
      },
    ],
  },
];
