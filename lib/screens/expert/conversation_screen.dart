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
    // Empty-state guard (Session 60: removed fabricated conversations).
    if (_conversations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conversation Practice'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Conversations coming soon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'We are preparing verified Awing conversations '
                  'with native speakers. Check back in the next '
                  'update!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

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

// Session 60: Removed all 6 conversations — Session 30 audit flagged
// Cha'tɔ́, Wo'!, and Yə kwa'ə as fabricated phrases that survived
// earlier cleanup. Conversations screen will show empty until verified
// content is sourced from AwingOrthography2005.pdf or confirmed by
// Dr. Sama. The original entries are preserved in git history (last
// commit before this change: 4e8835e).
const List<Map<String, dynamic>> _conversations = [];
