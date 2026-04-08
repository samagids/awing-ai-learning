import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Collects anonymized user activity data locally, with optional cloud sync.
///
/// By default, all data stays on-device. If a webhook URL is configured in
/// `config/webhooks.json`, events are also sent to a Google Apps Script
/// endpoint that logs them in a Google Sheet.
///
/// Deploy the webhook: `scripts\deploy_apps_script.bat`
/// Events are always persisted locally in SharedPreferences.
class AnalyticsService {

  static const String _appVersion = '1.2.0';
  static const int _batchSize = 20;
  static const Duration _flushInterval = Duration(minutes: 5);
  static const String _keyDeviceId = 'analytics_device_id';
  static const String _keyPendingEvents = 'analytics_pending';
  static const String _keyOptOut = 'analytics_opt_out';

  static AnalyticsService? _instance;
  late SharedPreferences _prefs;
  String _deviceId = '';
  bool _initialized = false;
  bool _optedOut = false;
  Timer? _flushTimer;
  DateTime? _sessionStart;
  String? _webhookUrl; // Loaded from config/webhooks.json (optional)

  // Pending events queued for batch send
  final Map<String, List<List<dynamic>>> _pending = {
    'Activity': [],
    'Quizzes': [],
    'Feedback': [],
    'Errors': [],
    'Sessions': [],
  };

  AnalyticsService._();

  /// Singleton instance.
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  bool get isOptedOut => _optedOut;

  /// Initialize — generate anonymous device ID, restore pending events.
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _optedOut = _prefs.getBool(_keyOptOut) ?? false;

    // Generate or restore anonymous device ID (random, not tied to user)
    _deviceId = _prefs.getString(_keyDeviceId) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await _prefs.setString(_keyDeviceId, _deviceId);
    }

    // Load webhook URL from config (optional — if not present, stays local-only)
    await _loadWebhookUrl();

    // Restore any unsent events from last session
    _restorePending();

    // Start periodic flush timer
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());

    // Record session start
    _sessionStart = DateTime.now();
    _initialized = true;
  }

  /// Let users opt out of analytics.
  Future<void> setOptOut(bool value) async {
    _optedOut = value;
    await _prefs.setBool(_keyOptOut, value);
    if (value) {
      // Clear all pending data
      for (final list in _pending.values) {
        list.clear();
      }
      _savePending();
    }
  }

  // ==================== Event Logging ====================

  /// Log a lesson/screen activity.
  void logActivity({
    required String event,
    String level = '',
    String lesson = '',
    String detail = '',
    int durationSec = 0,
  }) {
    if (_optedOut) return;
    _pending['Activity']!.add([
      DateTime.now().toIso8601String(),
      _deviceId,
      event,
      level,
      lesson,
      detail,
      durationSec,
      _appVersion,
    ]);
    _checkFlush();
  }

  /// Log a quiz attempt with score breakdown.
  void logQuiz({
    required String quizType,
    required String level,
    required int scorePercent,
    required int correct,
    required int total,
    List<String> wrongAnswers = const [],
    int timeSec = 0,
  }) {
    if (_optedOut) return;
    _pending['Quizzes']!.add([
      DateTime.now().toIso8601String(),
      _deviceId,
      quizType,
      level,
      scorePercent,
      correct,
      total,
      wrongAnswers.join('; '),
      timeSec,
    ]);
    _checkFlush();
  }

  /// Log user feedback or recommendation.
  void logFeedback({
    required String type, // 'recommendation', 'bug_report', 'rating', 'suggestion'
    int rating = 0,
    String message = '',
    String screen = '',
  }) {
    if (_optedOut) return;
    _pending['Feedback']!.add([
      DateTime.now().toIso8601String(),
      _deviceId,
      type,
      rating,
      message,
      screen,
    ]);
    _checkFlush();
  }

  /// Log an error or crash.
  void logError({
    required String screen,
    required String error,
    String stackTrace = '',
  }) {
    if (_optedOut) return;
    _pending['Errors']!.add([
      DateTime.now().toIso8601String(),
      _deviceId,
      screen,
      error,
      stackTrace.length > 500
          ? stackTrace.substring(0, 500)
          : stackTrace,
      _appVersion,
    ]);
    _checkFlush();
  }

  /// Log a session summary (call on app close or background).
  void logSessionEnd({int lessonsDone = 0, int quizzesDone = 0}) {
    if (_optedOut) return;
    final durationMin = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inMinutes
        : 0;
    _pending['Sessions']!.add([
      DateTime.now().toIso8601String(),
      _deviceId,
      'session_end',
      durationMin,
      lessonsDone,
      quizzesDone,
      _appVersion,
    ]);
    flush(); // Immediately flush on session end
  }

  // ==================== Persistence ====================

  /// Save pending events locally and optionally send to cloud webhook.
  Future<void> flush() async {
    if (_optedOut) return;
    _savePending();

    // If webhook URL is configured, send events to Google Sheet
    if (_webhookUrl != null && _webhookUrl!.isNotEmpty) {
      await _sendToCloud();
    }
  }

  /// Get all logged events for a specific category (for Developer Mode stats).
  List<List<dynamic>> getEvents(String category) {
    return List.unmodifiable(_pending[category] ?? []);
  }

  /// Get total event count across all categories.
  int get totalEventCount =>
      _pending.values.fold<int>(0, (sum, list) => sum + list.length);

  /// Dispose — flush remaining events and cancel timer.
  void dispose() {
    _flushTimer?.cancel();
    flush();
  }

  // ==================== Helpers ====================

  void _checkFlush() {
    final totalPending = _pending.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    if (totalPending >= _batchSize) {
      flush();
    } else {
      _savePending(); // Save locally in case app closes
    }
  }

  void _savePending() {
    final data = <String, dynamic>{};
    for (final entry in _pending.entries) {
      data[entry.key] = entry.value;
    }
    _prefs.setString(_keyPendingEvents, jsonEncode(data));
  }

  void _restorePending() {
    final json = _prefs.getString(_keyPendingEvents);
    if (json == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      for (final key in data.keys) {
        if (_pending.containsKey(key)) {
          final list = data[key] as List<dynamic>;
          _pending[key] = list
              .map((row) => (row as List<dynamic>).toList())
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Analytics: Error restoring pending: $e');
    }
  }

  /// Load the webhook URL from config/webhooks.json (bundled asset).
  /// If the file doesn't exist or has no URL, analytics stays local-only.
  Future<void> _loadWebhookUrl() async {
    try {
      final configJson = await rootBundle.loadString('config/webhooks.json');
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      final url = config['analytics_url'] as String?;
      if (url != null && url.startsWith('https://')) {
        _webhookUrl = url;
        if (kDebugMode) print('Analytics: Cloud sync enabled → $url');
      }
    } catch (_) {
      // No config file or invalid — local-only mode (this is fine)
      if (kDebugMode) print('Analytics: No webhooks.json — local-only mode');
    }
  }

  /// Send pending events to the Google Apps Script webhook.
  /// Events are cleared from local storage after successful send.
  Future<void> _sendToCloud() async {
    if (_webhookUrl == null) return;

    for (final category in _pending.keys) {
      final events = _pending[category]!;
      if (events.isEmpty) continue;

      try {
        // Use dart:io HttpClient to avoid adding http package dependency
        final uri = Uri.parse(_webhookUrl!);
        final client = HttpClient();
        final request = await client.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode({
          'sheet': category,
          'data': events,
        }));
        final response = await request.close();

        if (response.statusCode == 200) {
          // Clear sent events
          events.clear();
          _savePending();
          if (kDebugMode) print('Analytics: Sent $category events to cloud');
        }
        client.close();
      } catch (e) {
        // Network error — events stay in local queue for next flush
        if (kDebugMode) print('Analytics: Cloud send failed for $category: $e');
      }
    }
  }

  /// Generate a random anonymous device ID (not tied to any user info).
  String _generateDeviceId() {
    final r = Random.secure();
    final bytes = List<int>.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
