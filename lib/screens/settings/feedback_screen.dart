import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';

/// Screen where users can rate the app and send feedback/recommendations
/// to the developer. All feedback is anonymized.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  String _feedbackType = 'suggestion';
  int _rating = 0;
  bool _submitted = false;

  final _analytics = AnalyticsService.instance;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_messageController.text.trim().isEmpty && _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a rating or message')),
      );
      return;
    }

    _analytics.logFeedback(
      type: _feedbackType,
      rating: _rating,
      message: _messageController.text.trim(),
      screen: 'feedback_screen',
    );

    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _submitted ? _buildThankYou() : _buildForm(),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Thank you!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us make Awing better for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to App'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Privacy notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your feedback is anonymous. No personal information is collected.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feedback type
          Text(
            'What kind of feedback?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _TypeChip(
                label: 'Suggestion',
                icon: Icons.lightbulb_outline,
                selected: _feedbackType == 'suggestion',
                onTap: () => setState(() => _feedbackType = 'suggestion'),
              ),
              _TypeChip(
                label: 'Bug Report',
                icon: Icons.bug_report_outlined,
                selected: _feedbackType == 'bug_report',
                onTap: () => setState(() => _feedbackType = 'bug_report'),
              ),
              _TypeChip(
                label: 'New Content',
                icon: Icons.add_circle_outline,
                selected: _feedbackType == 'content_request',
                onTap: () => setState(() => _feedbackType = 'content_request'),
              ),
              _TypeChip(
                label: 'Pronunciation',
                icon: Icons.record_voice_over,
                selected: _feedbackType == 'pronunciation',
                onTap: () => setState(() => _feedbackType = 'pronunciation'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Star rating
          Text(
            'How would you rate the app?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: i < _rating ? Colors.amber : Colors.grey.shade400,
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          if (_rating > 0)
            Center(
              child: Text(
                ['', 'Needs work', 'Okay', 'Good', 'Great', 'Amazing!'][_rating],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Message
          Text(
            'Your message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: _feedbackType == 'suggestion'
                  ? 'What would make the app better?'
                  : _feedbackType == 'bug_report'
                      ? 'What went wrong? What were you doing?'
                      : _feedbackType == 'content_request'
                          ? 'What words, phrases, or lessons should we add?'
                          : 'Which pronunciation sounds wrong?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text(
              'Send Feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.teal,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade700,
      ),
      checkmarkColor: Colors.white,
    );
  }
}
