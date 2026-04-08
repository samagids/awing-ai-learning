import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';

/// Sends activity reports to parents via WhatsApp.
///
/// Two notification types:
/// 1. **Quiz completed** — instant message after each quiz with score and feedback
/// 2. **Weekly summary** — digest of lessons, quizzes, streak, XP earned this week
///
/// Messages are sent via WhatsApp `wa.me` deep link (opens WhatsApp with
/// pre-filled message). No API key or backend needed.
///
/// If the device is offline or WhatsApp isn't installed, messages are queued
/// locally and can be sent later from the Parent Settings screen.
class ParentNotificationService {
  static const String _keyPendingMessages = 'parent_pending_messages';
  static const String _keyLastWeeklySent = 'parent_last_weekly_sent';
  static const String _keyWeeklyStats = 'parent_weekly_stats';

  final AuthService _auth;
  final ProgressService _progress;
  late SharedPreferences _prefs;
  bool _initialized = false;

  List<Map<String, dynamic>> _pendingMessages = [];

  ParentNotificationService({
    required AuthService auth,
    required ProgressService progress,
  })  : _auth = auth,
        _progress = progress;

  int get pendingMessageCount => _pendingMessages.length;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadPendingMessages();
    _initialized = true;
  }

  // ==================== Quiz Notification ====================

  /// Send a WhatsApp message to the parent after a quiz is completed.
  /// Called from quiz screens after the score is shown.
  Future<bool> notifyQuizCompleted({
    required String childName,
    required String quizName,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    final account = _auth.currentAccount;
    if (account == null || !account.hasWhatsApp || !account.sendQuizNotifications) {
      return false;
    }

    // Track for weekly summary
    _recordWeeklyStat('quiz', {
      'name': quizName,
      'score': score,
      'date': DateTime.now().toIso8601String(),
    });

    final percentage = score;
    final emoji = percentage >= 90
        ? '🌟'
        : percentage >= 70
            ? '👏'
            : percentage >= 50
                ? '💪'
                : '📚';

    final message = '$emoji Awing Learning — Quiz Report\n\n'
        'Child: $childName\n'
        'Quiz: $quizName\n'
        'Score: $correctAnswers/$totalQuestions ($percentage%)\n'
        '${_scoreMessage(percentage)}\n\n'
        '— Sent from Awing AI Learning';

    return _sendWhatsApp(account.whatsappNumber!, message);
  }

  String _scoreMessage(int percentage) {
    if (percentage >= 90) return 'Excellent work! Your child is doing amazing!';
    if (percentage >= 70) return 'Good progress! Keep encouraging them!';
    if (percentage >= 50) return 'Getting there! Practice makes perfect.';
    return 'Needs more practice. Try reviewing the lessons together.';
  }

  // ==================== Lesson Notification ====================

  /// Record that a lesson was completed (for weekly summary).
  void recordLessonCompleted(String childName, String lessonName) {
    _recordWeeklyStat('lesson', {
      'name': lessonName,
      'child': childName,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // ==================== Weekly Summary ====================

  /// Send a weekly summary if 7 days have passed since the last one.
  /// Called on app launch or from settings.
  Future<bool> sendWeeklySummaryIfDue() async {
    final account = _auth.currentAccount;
    if (account == null || !account.hasWhatsApp || !account.sendWeeklySummary) {
      return false;
    }

    final lastSent = _prefs.getString(_keyLastWeeklySent);
    if (lastSent != null) {
      final lastDate = DateTime.tryParse(lastSent);
      if (lastDate != null && DateTime.now().difference(lastDate).inDays < 7) {
        return false; // Not due yet
      }
    }

    return sendWeeklySummary();
  }

  /// Force-send the weekly summary now.
  Future<bool> sendWeeklySummary() async {
    final account = _auth.currentAccount;
    if (account == null || !account.hasWhatsApp) return false;

    final stats = _getWeeklyStats();
    final profiles = account.profiles;
    final childNames = profiles.map((p) => p.displayName).join(', ');

    final lessonsCount = (stats['lessons'] as List?)?.length ?? 0;
    final quizzes = (stats['quizzes'] as List?) ?? [];
    final avgScore = quizzes.isNotEmpty
        ? (quizzes.fold<int>(0, (sum, q) => sum + (q['score'] as int? ?? 0)) /
                quizzes.length)
            .round()
        : 0;

    final streak = _progress.dailyStreak;
    final xp = _progress.xp;
    final level = _progress.level;

    final streakEmoji = streak >= 7 ? '🔥🔥🔥' : streak >= 3 ? '🔥🔥' : streak > 0 ? '🔥' : '❄️';

    final message = '📊 Awing Learning — Weekly Report\n\n'
        'Children: $childNames\n'
        'Period: Last 7 days\n\n'
        '📖 Lessons completed: $lessonsCount\n'
        '📝 Quizzes taken: ${quizzes.length}'
        '${quizzes.isNotEmpty ? " (avg score: $avgScore%)" : ""}\n'
        '$streakEmoji Daily streak: $streak days\n'
        '⭐ Level $level • $xp XP\n\n'
        '${_weeklyAdvice(lessonsCount, quizzes.length, streak)}\n\n'
        '— Sent from Awing AI Learning';

    final sent = await _sendWhatsApp(account.whatsappNumber!, message);
    if (sent) {
      _prefs.setString(_keyLastWeeklySent, DateTime.now().toIso8601String());
      _clearWeeklyStats();
    }
    return sent;
  }

  String _weeklyAdvice(int lessons, int quizzes, int streak) {
    if (lessons == 0 && quizzes == 0) {
      return 'Your child hasn\'t practiced this week. Try setting a daily reminder!';
    }
    if (streak >= 7) return 'Amazing consistency! A full week streak — keep it going!';
    if (streak >= 3) return 'Good habit forming! Encourage daily practice.';
    if (quizzes >= 3) return 'Great quiz activity! Try exploring new lessons too.';
    return 'Good start! Try to practice a little each day.';
  }

  // ==================== WhatsApp Sending ====================

  /// Open WhatsApp with a pre-filled message to the parent's number.
  /// If WhatsApp can't be opened, queues the message for later.
  Future<bool> _sendWhatsApp(String phoneNumber, String message) async {
    // Clean the phone number: remove +, spaces, dashes
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    final waUrl = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        waUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _queueMessage(phoneNumber, message);
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('ParentNotification: WhatsApp launch error: $e');
      _queueMessage(phoneNumber, message);
      return false;
    }
  }

  /// Send all queued messages that couldn't be sent earlier.
  Future<int> flushPendingMessages() async {
    if (_pendingMessages.isEmpty) return 0;

    int sent = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final msg in _pendingMessages) {
      final phone = msg['phone'] as String? ?? '';
      final text = msg['message'] as String? ?? '';
      if (phone.isEmpty || text.isEmpty) continue;

      final cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
      final waUrl = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(text)}',
      );

      try {
        final launched = await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        if (launched) {
          sent++;
          // Small delay between messages so user can confirm each
          await Future.delayed(const Duration(seconds: 2));
        } else {
          remaining.add(msg);
        }
      } catch (_) {
        remaining.add(msg);
      }
    }

    _pendingMessages = remaining;
    _savePendingMessages();
    return sent;
  }

  // ==================== Message Queue ====================

  void _queueMessage(String phone, String message) {
    _pendingMessages.add({
      'phone': phone,
      'message': message,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    _savePendingMessages();
  }

  void _loadPendingMessages() {
    final json = _prefs.getString(_keyPendingMessages);
    if (json == null) return;
    try {
      final List<dynamic> list = jsonDecode(json);
      _pendingMessages = list.map((j) => Map<String, dynamic>.from(j)).toList();
    } catch (_) {}
  }

  void _savePendingMessages() {
    _prefs.setString(_keyPendingMessages, jsonEncode(_pendingMessages));
  }

  void clearPendingMessages() {
    _pendingMessages.clear();
    _savePendingMessages();
  }

  // ==================== Weekly Stats Tracking ====================

  void _recordWeeklyStat(String type, Map<String, dynamic> data) {
    final stats = _getWeeklyStats();
    final key = type == 'quiz' ? 'quizzes' : 'lessons';
    final list = (stats[key] as List?) ?? [];
    list.add(data);
    stats[key] = list;
    _prefs.setString(_keyWeeklyStats, jsonEncode(stats));
  }

  Map<String, dynamic> _getWeeklyStats() {
    final json = _prefs.getString(_keyWeeklyStats);
    if (json == null) return {'quizzes': [], 'lessons': []};
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return {'quizzes': [], 'lessons': []};
    }
  }

  void _clearWeeklyStats() {
    _prefs.setString(_keyWeeklyStats, jsonEncode({'quizzes': [], 'lessons': []}));
  }
}
