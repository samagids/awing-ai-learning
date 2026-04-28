import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/screens/settings/feedback_screen.dart';

/// Kid-friendly player profile screen with gamification stats, badges, and progress tracking
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Badge? _selectedBadge;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progressService, _) {
        final unlockedBadges = progressService.getUnlockedBadges();
        final allBadges = progressService.getAllBadges();
        final wordsToReview = progressService.getWordsToReview();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF006432),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.feedback_outlined),
                tooltip: 'Send Feedback',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section - Level & XP
                _buildHeaderSection(progressService),

                const SizedBox(height: 24),

                // Stats Row - Words, Quizzes, Lessons
                _buildStatsRow(progressService),

                const SizedBox(height: 24),

                // Review Reminder
                if (wordsToReview.isNotEmpty) _buildReviewReminder(wordsToReview),

                const SizedBox(height: 24),

                // Badges Grid
                _buildBadgesSection(allBadges),

                const SizedBox(height: 24),

                // Recent Quiz Scores
                _buildRecentScoresSection(progressService),

                const SizedBox(height: 24),

                // My PIN section
                _buildMyPinSection(),

                const SizedBox(height: 24),

                // Analytics opt-out
                _buildAnalyticsToggle(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the header section with level, XP progress, and daily streak
  Widget _buildHeaderSection(ProgressService progressService) {
    final currentLevel = progressService.currentLevel;
    final totalXP = progressService.getTotalXP();
    final levelProgress = progressService.levelProgressPercent / 100.0;
    final dailyStreak = progressService.getDailyStreak();
    final currentLevelXP = progressService.currentLevelXP;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF006432), const Color(0xFFDAA520)],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Large Circular Progress Indicator with Level
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle with gradient
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade300, Colors.orange.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006432).withAlpha(100),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Progress ring
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: levelProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withAlpha(100),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEVEL',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '$currentLevel',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // XP Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$currentLevelXP / 200 XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006432),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total XP: $totalXP',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF004d29),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Daily Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Streak',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '$dailyStreak ${dailyStreak == 1 ? 'day' : 'days'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stats row with Words Learned, Quizzes Taken, Lessons Done
  Widget _buildStatsRow(ProgressService progressService) {
    final wordsLearned = progressService.getCompletedLessons().length > 0
        ? 'Multiple'
        : '0'; // Simplified - you might track this differently
    final quizzesTaken = progressService.getAllQuizScores().length;
    final lessonsDone = progressService.getCompletedLessons().length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              emoji: '📚',
              title: 'Words',
              value: '${progressService.getWordsToReview().length}+',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              emoji: '🎯',
              title: 'Quizzes',
              value: '$quizzesTaken',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              emoji: '✅',
              title: 'Lessons',
              value: '$lessonsDone',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required String emoji,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(100), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build review reminder card
  Widget _buildReviewReminder(List<SpacedRepetitionWord> wordsToReview) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade100, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300, width: 2),
        ),
        child: Row(
          children: [
            const Text(
              '📝',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Words to Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    "You have ${wordsToReview.length} word${wordsToReview.length == 1 ? '' : 's'} due for review!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to vocabulary review screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vocabulary review coming soon!')),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build badges section with 3x3 grid
  Widget _buildBadgesSection(List<Badge> allBadges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${allBadges.where((b) => b.unlocked).length}/${allBadges.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              return _buildBadgeWidget(badge);
            },
          ),
        ],
      ),
    );
  }

  /// Build individual badge widget
  Widget _buildBadgeWidget(Badge badge) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBadge = badge;
        });
        _showBadgeDialog(badge);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: badge.unlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFB8E6B8), const Color(0xFF004d29)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade300, Colors.grey.shade500],
                ),
          boxShadow: badge.unlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF006432).withAlpha(100),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (badge.unlocked)
              Text(
                badge.emoji,
                style: const TextStyle(fontSize: 40),
              )
            else
              const Text(
                '🔒',
                style: TextStyle(fontSize: 40),
              ),
            // Unlocked indicator
            if (badge.unlocked)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show badge details dialog
  void _showBadgeDialog(Badge badge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(
                badge.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(badge.title),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14),
              ),
              if (badge.unlocked && badge.unlockedDate != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Unlocked on ${_formatDate(badge.unlockedDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Keep playing to unlock this badge!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Build "My PIN" section — lets each profile set or change their own PIN
  Widget _buildMyPinSection() {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;
    if (profile == null) return const SizedBox.shrink();

    final hasPin = profile.hasPin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasPin ? Icons.lock : Icons.lock_open,
                    color: hasPin ? const Color(0xFF006432) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'My PIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (hasPin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PIN set',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasPin
                    ? 'Your profile is protected. Others need your PIN to switch to your profile.'
                    : 'Set a PIN (at least 6 digits) to protect your profile from others.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSetProfilePinDialog(profile.id, hasPin),
                      icon: Icon(hasPin ? Icons.edit : Icons.add),
                      label: Text(hasPin ? 'Change PIN' : 'Set PIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006432),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (hasPin) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showRemoveProfilePinDialog(profile.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to set or change a profile PIN
  void _showSetProfilePinDialog(String profileId, bool hasExisting) async {
    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;

    // If changing, verify current PIN first
    if (hasExisting && profile != null && profile.hasPin) {
      final currentPinController = TextEditingController();
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify Current PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current PIN to change it.'),
              const SizedBox(height: 16),
              TextField(
                controller: currentPinController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                obscureText: true,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (profile.verifyPin(currentPinController.text)) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      if (verified != true || !mounted) return;
    }

    // Now show the new PIN dialog
    final newPinController = TextEditingController();
    if (!mounted) return;
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasExisting ? 'Set New PIN' : 'Set Your PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a PIN (at least 6 digits) to protect your profile.'),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = newPinController.text;
              if (pin.length >= 6) {
                Navigator.pop(ctx, pin);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 6 digits'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006432),
              foregroundColor: Colors.white,
            ),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    if (newPin != null && newPin.length >= 6 && mounted) {
      auth.setProfilePin(profileId, newPin);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN set! Others will need it to access your profile.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show dialog to remove a profile PIN (requires current PIN)
  void _showRemoveProfilePinDialog(String profileId) async {
    final auth = context.read<AuthService>();
    final profile = auth.currentProfile;
    if (profile == null || !profile.hasPin) return;

    final controller = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current PIN to remove it.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (profile.verifyPin(controller.text)) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (verified == true && mounted) {
      auth.removeProfilePin(profileId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN removed. Anyone can switch to your profile now.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Build recent quiz scores section
  Widget _buildAnalyticsToggle() {
    final analytics = AnalyticsService.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SwitchListTile(
          title: const Text('Help Improve the App'),
          subtitle: const Text(
            'Share anonymous usage data (no personal info)',
          ),
          value: !analytics.isOptedOut,
          onChanged: (v) {
            analytics.setOptOut(!v);
            setState(() {});
          },
          secondary: const Icon(Icons.analytics_outlined),
          activeColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScoresSection(ProgressService progressService) {
    final allScores = progressService.getAllQuizScores();

    if (allScores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text(
                '📊',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No Quiz Scores Yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete quizzes to see your scores here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Quiz Scores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...allScores.entries.map((entry) {
            final quizType = entry.key;
            final score = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatQuizType(quizType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Get color based on quiz score
  Color _getScoreColor(int score) {
    if (score == 100) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Format quiz type to human-readable string
  String _formatQuizType(String quizType) {
    return quizType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Format date to human-readable string
  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
