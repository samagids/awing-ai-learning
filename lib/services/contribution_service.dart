import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Type of contribution a user can submit.
enum ContributionType {
  spellingCorrection,   // "This word is spelled wrong"
  pronunciationFix,     // "This pronunciation is wrong" + audio recording
  newWord,              // "Add this word to the dictionary"
  newSentence,          // "Add this sentence/phrase"
  newPhrase,            // "Add this greeting/phrase"
  generalFeedback,      // "General suggestion"
}

/// Status of a contribution in the review pipeline.
enum ContributionStatus {
  pending,    // Submitted, waiting for review
  approved,   // Developer approved — queued for next build
  rejected,   // Developer rejected with reason
}

/// Result of a fetchAllFromWebhook() call. Reports what changed locally
/// AND the full server-side counts, so the Developer Mode dashboard can
/// display accurate live numbers even when nothing changed locally.
class FetchAllResult {
  final bool success;
  final String? error;
  final int added;          // new contributions pulled from server
  final int updated;        // existing contributions whose status changed
  final int serverPending;  // total pending on the server
  final int serverApproved; // total approved on the server
  final int serverRejected; // total rejected on the server
  final int serverTotal;    // total rows on the server

  const FetchAllResult({
    required this.success,
    this.error,
    this.added = 0,
    this.updated = 0,
    this.serverPending = 0,
    this.serverApproved = 0,
    this.serverRejected = 0,
    this.serverTotal = 0,
  });
}

/// A single user contribution (correction, new word, or recording).
class Contribution {
  final String id;
  final String deviceId;        // Anonymous device ID
  final String profileName;     // Display name (not email)
  final ContributionType type;
  final String targetWord;      // The word/sentence being corrected or added
  final String correction;      // The suggested correction text
  final String? englishMeaning; // English translation (for new words)
  final String? category;       // vocabulary category
  final String? pronunciationGuide; // How to pronounce it (phonetic spelling)
  final String? audioPath;      // Local path to recorded audio
  final String? notes;          // User's explanation
  final DateTime submittedAt;
  ContributionStatus status;
  String? reviewNotes;          // Developer's review notes
  DateTime? reviewedAt;

  Contribution({
    required this.id,
    required this.deviceId,
    required this.profileName,
    required this.type,
    required this.targetWord,
    required this.correction,
    this.englishMeaning,
    this.category,
    this.pronunciationGuide,
    this.audioPath,
    this.notes,
    DateTime? submittedAt,
    this.status = ContributionStatus.pending,
    this.reviewNotes,
    this.reviewedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'profileName': profileName,
    'type': type.name,
    'targetWord': targetWord,
    'correction': correction,
    'englishMeaning': englishMeaning,
    'category': category,
    'pronunciationGuide': pronunciationGuide,
    'audioPath': audioPath,
    'notes': notes,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
    'reviewNotes': reviewNotes,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
    id: json['id'] ?? '',
    deviceId: json['deviceId'] ?? '',
    profileName: json['profileName'] ?? 'Anonymous',
    type: ContributionType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ContributionType.generalFeedback,
    ),
    targetWord: json['targetWord'] ?? '',
    correction: json['correction'] ?? '',
    englishMeaning: json['englishMeaning'],
    category: json['category'],
    pronunciationGuide: json['pronunciationGuide'],
    audioPath: json['audioPath'],
    notes: json['notes'],
    submittedAt: json['submittedAt'] != null
        ? DateTime.parse(json['submittedAt'])
        : DateTime.now(),
    status: ContributionStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ContributionStatus.pending,
    ),
    reviewNotes: json['reviewNotes'],
    reviewedAt: json['reviewedAt'] != null
        ? DateTime.parse(json['reviewedAt'])
        : null,
  );
}

/// Manages user contributions — local-first with optional cloud sync.
///
/// Flow:
/// 1. User submits a contribution → saved locally on device.
/// 2. If webhook is configured, data is queued for upload and sent when
///    internet becomes available (offline-first).
/// 3. Developer imports or receives contributions in Developer Mode.
/// 4. Developer reviews, approves, or rejects.
/// 5. Approved contributions are exported as `approved_contributions.json`
///    into the project's `contributions/` folder.
/// 6. Developer runs `build_and_run.bat` which calls `apply_contributions.py`
///    to update the Dart data files + regenerate audio for all 6 voices.
/// 7. Developer verifies the build, then pushes to app stores.
class ContributionService extends ChangeNotifier {
  static const String _keyContributions = 'contributions_local';
  static const String _keyPendingQueue = 'contributions_pending_queue';

  late SharedPreferences _prefs;
  bool _initialized = false;
  String? _webhookUrl; // Loaded from config/webhooks.json
  Timer? _retryTimer;

  List<Contribution> _contributions = [];
  List<Map<String, dynamic>> _pendingQueue = []; // Offline queue

  // Getters
  List<Contribution> get contributions => List.unmodifiable(_contributions);
  List<Contribution> get pendingContributions =>
      _contributions.where((c) => c.status == ContributionStatus.pending).toList();
  List<Contribution> get approvedContributions =>
      _contributions.where((c) => c.status == ContributionStatus.approved).toList();
  List<Contribution> get rejectedContributions =>
      _contributions.where((c) => c.status == ContributionStatus.rejected).toList();
  bool get hasWebhook => _webhookUrl != null && _webhookUrl!.isNotEmpty;

  int get pendingQueueCount => _pendingQueue.length;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadContributions();
    _loadPendingQueue();
    await _loadWebhookUrl();
    _initialized = true;
    notifyListeners();
    // Start retry timer — tries to flush queued items every 2 minutes
    _retryTimer = Timer.periodic(const Duration(minutes: 2), (_) => flushQueue());
    // Also try flushing immediately on startup
    flushQueue();
  }

  /// Dispose resources.
  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Load the webhook URL from config/webhooks.json.
  Future<void> _loadWebhookUrl() async {
    try {
      final configJson = await rootBundle.loadString('config/webhooks.json');
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      final url = config['contributions_url'] as String?;
      if (url != null && url.startsWith('https://')) {
        _webhookUrl = url;
        if (kDebugMode) print('ContributionService: Webhook enabled → $url');
      }
    } catch (_) {
      // No config or invalid — works offline (local-only mode)
    }
  }

  /// POST JSON to the contributions webhook. Returns true on success.
  /// On failure, queues the payload for retry when internet is available.
  ///
  /// Google Apps Script webhooks return a 302 redirect on POST. The redirect
  /// URL serves the JSON response via GET only. We must:
  ///   1. POST with followRedirects=false
  ///   2. Read the Location header from the 302
  ///   3. GET the redirect URL to read the actual JSON response
  /// Set of webhook actions that require developer authentication.
  /// Submit and check_version are intentionally open. Everything else
  /// must come from a signed-in developer; the server (Apps Script)
  /// verifies the attached `idToken` against DEVELOPER_EMAIL.
  static const Set<String> _privilegedActions = {
    'approve',
    'reject',
    'fetch_pending',
    'fetch_all',
    'fetch_audio',
  };

  /// If the requested webhook action is privileged AND a Firebase user
  /// is signed in, attach a fresh ID token to the payload. The server
  /// rejects privileged calls without a valid developer-email token.
  ///
  /// We never throw on token-fetch failure — a privileged call without
  /// a token will simply be rejected by the server, which is the
  /// correct outcome.
  Future<void> _attachAuthIfPrivileged(Map<String, dynamic> payload) async {
    final action = payload['action']?.toString() ?? '';
    if (!_privilegedActions.contains(action)) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      // Force-refresh to keep tokens fresh; expired tokens server-side
      // would otherwise look like an unauthorized call. The result is
      // a short string we add to the payload — never logged.
      final token = await user.getIdToken(true);
      if (token != null && token.isNotEmpty) {
        payload['idToken'] = token;
      }
    } catch (e) {
      // Token fetch can fail for many benign reasons (offline, network,
      // user signed out mid-call). Don't blow up — server rejects
      // privileged calls without a token, which is the safe default.
      if (kDebugMode) {
        print('ContributionService: getIdToken failed (will retry): $e');
      }
    }
  }

  Future<bool> _postToWebhook(Map<String, dynamic> payload, {bool queue = true}) async {
    if (_webhookUrl == null) return false;
    // Stamp privileged calls with a Firebase ID token before sending.
    await _attachAuthIfPrivileged(payload);
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Phase 1: POST the payload (Apps Script processes it, returns 302)
      final request = await client.postUrl(Uri.parse(_webhookUrl!));
      // IMPORTANT: must send UTF-8 bytes. Dart's HttpClientRequest.write()
      // defaults to Latin-1, which corrupts any non-ASCII character (ô, ɛ,
      // ɔ, ə, tone diacritics, …) into U+FFFD on the server side.
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.followRedirects = false;
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      await response.drain<void>();

      if (response.statusCode == 302 || response.statusCode == 301) {
        // Phase 2: Follow the redirect with GET to read the response
        final redirectUrl = response.headers.value('location');
        if (redirectUrl != null) {
          var getUri = Uri.parse(redirectUrl);
          // Follow up to 5 chained redirects
          for (int i = 0; i < 5; i++) {
            final getReq = await client.getUrl(getUri);
            getReq.followRedirects = false;
            final getResp = await getReq.close();
            if (getResp.statusCode == 302 || getResp.statusCode == 301) {
              final nextUrl = getResp.headers.value('location');
              await getResp.drain<void>();
              if (nextUrl != null) {
                getUri = Uri.parse(nextUrl);
                continue;
              }
            }
            // Final response
            final body = await getResp.transform(const Utf8Decoder()).join();
            client.close();
            if (getResp.statusCode == 200) {
              try {
                final result = jsonDecode(body);
                return result['status'] == 'ok';
              } catch (_) {
                // JSON parse error but 200 = probably ok (Apps Script processed it)
                return true;
              }
            }
            // Non-200 final response — but the POST was already processed by Apps Script
            // The 302 itself means the server accepted the request.
            if (kDebugMode) print('ContributionService: Redirect final status ${getResp.statusCode}');
            return true;
          }
        }
        // Got a 302 = Apps Script processed the POST successfully
        client.close();
        return true;
      }

      // Direct 200 (unlikely for Apps Script, but handle it)
      if (response.statusCode == 200) {
        client.close();
        return true;
      }

      client.close();
      // Actual server error (5xx) — queue for retry
      if (queue) _enqueue(payload);
      return false;
    } catch (e) {
      if (kDebugMode) print('ContributionService: Webhook error (queued): $e');
      // Network error — queue for retry when internet returns
      if (queue) _enqueue(payload);
      return false;
    }
  }

  /// Add a payload to the offline queue for later retry.
  void _enqueue(Map<String, dynamic> payload) {
    _pendingQueue.add(payload);
    _savePendingQueue();
    if (kDebugMode) print('ContributionService: Queued payload (${_pendingQueue.length} in queue)');
  }

  /// Flush the offline queue — send all queued payloads to the webhook.
  /// Called periodically and on app startup.
  Future<int> flushQueue() async {
    if (_webhookUrl == null || _pendingQueue.isEmpty) return 0;

    // Check internet connectivity by trying to resolve the webhook host
    try {
      final uri = Uri.parse(_webhookUrl!);
      final result = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty) return 0;
    } catch (_) {
      // No internet — keep items in queue
      return 0;
    }

    int sent = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final payload in _pendingQueue) {
      final ok = await _postToWebhook(payload, queue: false);
      if (ok) {
        sent++;
      } else {
        remaining.add(payload);
      }
    }

    _pendingQueue = remaining;
    _savePendingQueue();

    if (sent > 0) {
      if (kDebugMode) print('ContributionService: Flushed $sent queued items (${remaining.length} remaining)');
      notifyListeners();
    }
    return sent;
  }

  void _loadPendingQueue() {
    final json = _prefs.getString(_keyPendingQueue);
    if (json == null) return;
    try {
      final List<dynamic> list = jsonDecode(json);
      _pendingQueue = list.map((j) => Map<String, dynamic>.from(j)).toList();
    } catch (e) {
      if (kDebugMode) print('ContributionService: Queue load error: $e');
    }
  }

  void _savePendingQueue() {
    _prefs.setString(_keyPendingQueue, jsonEncode(_pendingQueue));
  }

  // ==================== User Submission ====================

  /// Submit a new contribution. Saves locally.
  Future<String?> submit({
    required String deviceId,
    required String profileName,
    required ContributionType type,
    required String targetWord,
    required String correction,
    String? englishMeaning,
    String? category,
    String? pronunciationGuide,
    String? audioPath,
    String? notes,
  }) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${deviceId.substring(0, 6)}';

    final contribution = Contribution(
      id: id,
      deviceId: deviceId,
      profileName: profileName,
      type: type,
      targetWord: targetWord,
      correction: correction,
      englishMeaning: englishMeaning,
      category: category,
      pronunciationGuide: pronunciationGuide,
      audioPath: audioPath,
      notes: notes,
    );

    _contributions.insert(0, contribution);
    _saveContributions();
    notifyListeners();

    // Also push to webhook (non-blocking, best-effort)
    _postToWebhook({
      'action': 'submit',
      'id': id,
      'profileName': profileName,
      'type': type.name,
      'targetWord': targetWord,
      'correction': correction,
      'englishMeaning': englishMeaning ?? '',
      'category': category ?? '',
      'pronunciationGuide': pronunciationGuide ?? '',
      'notes': notes ?? '',
    });

    return id;
  }

  /// Share a contribution via the platform share sheet (email, WhatsApp, etc.)
  /// so it reaches the developer.
  Future<void> shareContribution(Contribution c) async {
    final json = const JsonEncoder.withIndent('  ').convert(c.toJson());

    // Write to a temp file for sharing
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/awing_contribution_${c.id}.json');
    await file.writeAsString(json);

    final files = <XFile>[];
    files.add(XFile(file.path, mimeType: 'application/json'));

    // If there's an audio recording, include it
    if (c.audioPath != null) {
      final audioFile = File(c.audioPath!);
      if (await audioFile.exists()) {
        files.add(XFile(c.audioPath!, mimeType: 'audio/mp4'));
      }
    }

    await Share.shareXFiles(
      files,
      subject: 'Awing Contribution: ${c.targetWord}',
      text: 'Awing language contribution from ${c.profileName}:\n'
          'Type: ${c.type.name}\n'
          'Word: ${c.targetWord}\n'
          'Correction: ${c.correction}\n'
          '${c.englishMeaning != null ? "English: ${c.englishMeaning}\n" : ""}'
          '${c.notes != null ? "Notes: ${c.notes}\n" : ""}',
    );
  }

  /// Auto-email a contribution to the developer.
  /// Uses mailto: URI to compose an email with full details.
  /// Returns true if the email client was launched successfully.
  Future<bool> emailContribution(
    Contribution c, {
    required String senderName,
    required String senderEmail,
  }) async {
    const developerEmail = 'samagids@gmail.com';

    final typeLabel = {
      ContributionType.spellingCorrection: 'Spelling Correction',
      ContributionType.pronunciationFix: 'Pronunciation Fix',
      ContributionType.newWord: 'New Word',
      ContributionType.newSentence: 'New Sentence',
      ContributionType.newPhrase: 'New Phrase',
      ContributionType.generalFeedback: 'General Feedback',
    }[c.type] ?? c.type.name;

    final subject = 'Awing Contribution: $typeLabel — ${c.targetWord}';

    final bodyLines = <String>[
      'Awing AI Learning — User Contribution',
      '======================================',
      '',
      'From: $senderName ($senderEmail)',
      'Date: ${c.submittedAt.toIso8601String()}',
      'Type: $typeLabel',
      '',
      '--- Details ---',
      'Awing word/sentence: ${c.targetWord}',
    ];

    if (c.correction.isNotEmpty) {
      final corrLabel = c.type == ContributionType.newSentence
          ? 'English translation'
          : c.type == ContributionType.spellingCorrection
              ? 'Correct spelling'
              : 'Suggested text';
      bodyLines.add('$corrLabel: ${c.correction}');
    }
    if (c.englishMeaning != null && c.englishMeaning!.isNotEmpty) {
      bodyLines.add('English meaning: ${c.englishMeaning}');
    }
    if (c.category != null && c.category!.isNotEmpty) {
      bodyLines.add('Category: ${c.category}');
    }
    if (c.pronunciationGuide != null && c.pronunciationGuide!.isNotEmpty) {
      bodyLines.add('Pronunciation guide: ${c.pronunciationGuide}');
    }
    if (c.notes != null && c.notes!.isNotEmpty) {
      bodyLines.add('Notes: ${c.notes}');
    }
    if (c.audioPath != null) {
      bodyLines.add('');
      bodyLines.add('** Audio recording attached on device — '
          'please request it via reply if needed **');
    }

    bodyLines.addAll([
      '',
      '--- JSON (for import) ---',
      const JsonEncoder.withIndent('  ').convert(c.toJson()),
      '',
      '---',
      'Sent from Awing AI Learning app',
    ]);

    final body = bodyLines.join('\n');

    final uri = Uri(
      scheme: 'mailto',
      path: developerEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(uri);
      return launched;
    } catch (e) {
      if (kDebugMode) print('ContributionService: Email launch error: $e');
      return false;
    }
  }

  /// Share ALL pending contributions at once.
  Future<void> shareAllPending() async {
    final pending = pendingContributions;
    if (pending.isEmpty) return;

    final jsonList = pending.map((c) => c.toJson()).toList();
    final json = const JsonEncoder.withIndent('  ').convert(jsonList);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/awing_contributions_all.json');
    await file.writeAsString(json);

    final files = <XFile>[
      XFile(file.path, mimeType: 'application/json'),
    ];

    // Include all audio recordings
    for (final c in pending) {
      if (c.audioPath != null) {
        final audioFile = File(c.audioPath!);
        if (await audioFile.exists()) {
          files.add(XFile(c.audioPath!, mimeType: 'audio/mp4'));
        }
      }
    }

    await Share.shareXFiles(
      files,
      subject: 'Awing Contributions (${pending.length} items)',
      text: '${pending.length} Awing language contributions ready for review.',
    );
  }

  // ==================== Cloud Fetch ====================

  /// Fetch pending contributions from the Google Sheet webhook.
  /// Returns the number of new contributions imported.
  /// This allows contributions submitted from ANY device to appear
  /// in Developer Mode without manual JSON import.
  ///
  /// Google Apps Script returns 302 redirects — we must follow them
  /// manually with GET to read the actual JSON response.
  Future<int> fetchFromWebhook() async {
    if (_webhookUrl == null) return 0;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Phase 1: POST the fetch_pending request
      final request = await client.postUrl(Uri.parse(_webhookUrl!));
      // IMPORTANT: must send UTF-8 bytes. Dart's HttpClientRequest.write()
      // defaults to Latin-1, which corrupts any non-ASCII character into
      // U+FFFD on the server side. This request has no non-ASCII content
      // but we keep the pattern consistent with _postToWebhook().
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.followRedirects = false;
      // fetch_pending is a privileged action — attach the developer's
      // Firebase ID token so the server (Apps Script) can verify
      // request comes from samagids@gmail.com.
      final fetchPayload = <String, dynamic>{'action': 'fetch_pending'};
      await _attachAuthIfPrivileged(fetchPayload);
      request.add(utf8.encode(jsonEncode(fetchPayload)));
      final response = await request.close();

      String body;

      // Phase 2: Follow 302 redirect with GET to read the response
      if (response.statusCode == 302 || response.statusCode == 301) {
        await response.drain<void>();
        final location = response.headers.value('location');
        if (location == null) {
          client.close();
          return 0;
        }

        var getUri = Uri.parse(location);
        body = '';
        for (int i = 0; i < 5; i++) {
          final getReq = await client.getUrl(getUri);
          getReq.followRedirects = false;
          final getResp = await getReq.close();
          if (getResp.statusCode == 302 || getResp.statusCode == 301) {
            await getResp.drain<void>();
            final nextUrl = getResp.headers.value('location');
            if (nextUrl != null) {
              getUri = Uri.parse(nextUrl);
              continue;
            }
          }
          body = await getResp.transform(const Utf8Decoder()).join();
          break;
        }
      } else {
        body = await response.transform(const Utf8Decoder()).join();
      }
      client.close();

      if (body.isEmpty) {
        if (kDebugMode) print('ContributionService: Fetch returned empty body');
        return 0;
      }

      if (kDebugMode) print('ContributionService: Fetch response: ${body.substring(0, body.length.clamp(0, 200))}');

      final result = jsonDecode(body);
      if (result['status'] != 'ok') return 0;

      final List<dynamic> items = result['contributions'] ?? [];
      if (items.isEmpty) return 0;

      int imported = 0;
      for (final item in items) {
        final map = Map<String, dynamic>.from(item);
        // Webhook returns slightly different field names — normalize
        final c = Contribution(
          id: map['id']?.toString() ?? '',
          deviceId: map['deviceId']?.toString() ?? 'cloud',
          profileName: map['profileName']?.toString() ?? 'Anonymous',
          type: ContributionType.values.firstWhere(
            (t) => t.name == map['type'],
            orElse: () => ContributionType.generalFeedback,
          ),
          targetWord: map['targetWord']?.toString() ?? '',
          correction: map['correction']?.toString() ?? '',
          englishMeaning: map['englishMeaning']?.toString(),
          category: map['category']?.toString(),
          notes: map['notes']?.toString(),
          submittedAt: map['submittedAt'] != null
              ? DateTime.tryParse(map['submittedAt'].toString())
              : null,
          status: ContributionStatus.pending,
        );

        // Skip duplicates (by ID)
        if (c.id.isNotEmpty && !_contributions.any((existing) => existing.id == c.id)) {
          _contributions.insert(0, c);
          imported++;
        }
      }

      if (imported > 0) {
        _saveContributions();
        notifyListeners();
        if (kDebugMode) print('ContributionService: Fetched $imported new contributions from webhook');
      }
      return imported;
    } catch (e) {
      if (kDebugMode) print('ContributionService: Fetch error: $e');
      return 0;
    }
  }

  /// Fetch ALL contributions (pending + approved + rejected) from webhook
  /// and merge them into local state by id. Used by Developer Mode to keep
  /// the dashboard counters in sync with server state across all devices.
  ///
  /// Server is the source of truth for status: if a contribution exists
  /// locally and on server, the server's status/reviewNotes/reviewedAt win.
  /// Local-only entries (unsent offline-queue submissions) are preserved.
  ///
  /// Returns a FetchAllResult with counts: {added, updated, pending, approved, rejected}.
  Future<FetchAllResult> fetchAllFromWebhook() async {
    if (_webhookUrl == null) {
      return const FetchAllResult(success: false, error: 'No webhook configured');
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Phase 1: POST the fetch_all request (UTF-8 encoded)
      final request = await client.postUrl(Uri.parse(_webhookUrl!));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.followRedirects = false;
      // fetch_all is privileged — attach developer Firebase ID token.
      final fetchAllPayload = <String, dynamic>{'action': 'fetch_all'};
      await _attachAuthIfPrivileged(fetchAllPayload);
      request.add(utf8.encode(jsonEncode(fetchAllPayload)));
      final response = await request.close();

      String body;

      // Phase 2: Follow 302 redirect with GET (Apps Script web app pattern)
      if (response.statusCode == 302 || response.statusCode == 301) {
        await response.drain<void>();
        final location = response.headers.value('location');
        if (location == null) {
          client.close();
          return const FetchAllResult(success: false, error: 'No redirect location');
        }

        var getUri = Uri.parse(location);
        body = '';
        for (int i = 0; i < 5; i++) {
          final getReq = await client.getUrl(getUri);
          getReq.followRedirects = false;
          final getResp = await getReq.close();
          if (getResp.statusCode == 302 || getResp.statusCode == 301) {
            await getResp.drain<void>();
            final nextUrl = getResp.headers.value('location');
            if (nextUrl != null) {
              getUri = Uri.parse(nextUrl);
              continue;
            }
          }
          body = await getResp.transform(const Utf8Decoder()).join();
          break;
        }
      } else {
        body = await response.transform(const Utf8Decoder()).join();
      }
      client.close();

      if (body.isEmpty) {
        return const FetchAllResult(success: false, error: 'Empty response');
      }

      final result = jsonDecode(body);
      if (result['status'] != 'ok') {
        return FetchAllResult(
          success: false,
          error: result['message']?.toString() ?? 'Server error',
        );
      }

      final List<dynamic> items = result['contributions'] ?? [];

      int added = 0;
      int updated = 0;
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (final item in items) {
        final map = Map<String, dynamic>.from(item);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final serverStatus = ContributionStatus.values.firstWhere(
          (s) => s.name == (map['status']?.toString() ?? 'pending'),
          orElse: () => ContributionStatus.pending,
        );

        // Tally counts by status
        if (serverStatus == ContributionStatus.pending) {
          pending++;
        } else if (serverStatus == ContributionStatus.approved) {
          approved++;
        } else {
          rejected++;
        }

        final existingIndex = _contributions.indexWhere((c) => c.id == id);
        if (existingIndex >= 0) {
          // Update existing: server wins for status/review fields
          final existing = _contributions[existingIndex];
          final reviewedAtStr = map['reviewedAt']?.toString();
          final serverReviewedAt = (reviewedAtStr != null && reviewedAtStr.isNotEmpty)
              ? DateTime.tryParse(reviewedAtStr)
              : null;
          final serverReviewNotes = map['reviewNotes']?.toString();
          final merged = Contribution(
            id: existing.id,
            deviceId: existing.deviceId,
            profileName: existing.profileName,
            type: existing.type,
            targetWord: existing.targetWord,
            correction: existing.correction,
            englishMeaning: existing.englishMeaning,
            category: existing.category,
            pronunciationGuide: existing.pronunciationGuide,
            audioPath: existing.audioPath,
            notes: existing.notes,
            submittedAt: existing.submittedAt,
            status: serverStatus,
            reviewNotes: (serverReviewNotes != null && serverReviewNotes.isNotEmpty)
                ? serverReviewNotes
                : existing.reviewNotes,
            reviewedAt: serverReviewedAt ?? existing.reviewedAt,
          );
          // Only count as "updated" if something actually changed.
          if (existing.status != merged.status ||
              existing.reviewNotes != merged.reviewNotes ||
              existing.reviewedAt != merged.reviewedAt) {
            updated++;
          }
          _contributions[existingIndex] = merged;
        } else {
          // New entry from another device
          final submittedAtStr = map['submittedAt']?.toString();
          final submittedAt = (submittedAtStr != null && submittedAtStr.isNotEmpty)
              ? DateTime.tryParse(submittedAtStr)
              : null;
          final reviewedAtStr = map['reviewedAt']?.toString();
          final reviewedAt = (reviewedAtStr != null && reviewedAtStr.isNotEmpty)
              ? DateTime.tryParse(reviewedAtStr)
              : null;
          final c = Contribution(
            id: id,
            deviceId: map['deviceId']?.toString() ?? 'cloud',
            profileName: map['profileName']?.toString() ?? 'Anonymous',
            type: ContributionType.values.firstWhere(
              (t) => t.name == map['type'],
              orElse: () => ContributionType.generalFeedback,
            ),
            targetWord: map['targetWord']?.toString() ?? '',
            correction: map['correction']?.toString() ?? '',
            englishMeaning: map['englishMeaning']?.toString(),
            category: map['category']?.toString(),
            notes: map['notes']?.toString(),
            submittedAt: submittedAt,
            status: serverStatus,
            reviewNotes: map['reviewNotes']?.toString(),
            reviewedAt: reviewedAt,
          );
          _contributions.insert(0, c);
          added++;
        }
      }

      if (added > 0 || updated > 0) {
        _saveContributions();
        notifyListeners();
      }

      if (kDebugMode) {
        print('ContributionService: fetchAll → +$added new, ~$updated updated '
            '(server: $pending pending, $approved approved, $rejected rejected)');
      }

      return FetchAllResult(
        success: true,
        added: added,
        updated: updated,
        serverPending: pending,
        serverApproved: approved,
        serverRejected: rejected,
        serverTotal: items.length,
      );
    } catch (e) {
      if (kDebugMode) print('ContributionService: fetchAll error: $e');
      return FetchAllResult(success: false, error: e.toString());
    }
  }

  // ==================== Developer Import ====================

  /// Import contributions from a JSON file (developer receives via email etc.)
  Future<int> importFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = [decoded];
      } else {
        return 0;
      }

      int imported = 0;
      for (final item in list) {
        final c = Contribution.fromJson(Map<String, dynamic>.from(item));
        // Don't import duplicates
        if (!_contributions.any((existing) => existing.id == c.id)) {
          _contributions.insert(0, c);
          imported++;
        }
      }

      if (imported > 0) {
        _saveContributions();
        notifyListeners();
      }
      return imported;
    } catch (e) {
      if (kDebugMode) print('ContributionService: Import error: $e');
      return 0;
    }
  }

  /// Import from a file path (developer picks a JSON file).
  Future<int> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      return importFromJson(content);
    } catch (e) {
      if (kDebugMode) print('ContributionService: File import error: $e');
      return 0;
    }
  }

  // ==================== Developer Review ====================

  /// Approve a contribution (developer only).
  /// Marks as approved locally AND pushes to the Google Sheet webhook
  /// so build_and_run.bat can download it automatically.
  Future<bool> approve(String contributionId, {String? reviewNotes}) async {
    final idx = _contributions.indexWhere((c) => c.id == contributionId);
    if (idx < 0) return false;

    final c = _contributions[idx];
    c.status = ContributionStatus.approved;
    c.reviewNotes = reviewNotes;
    c.reviewedAt = DateTime.now();
    _saveContributions();
    notifyListeners();

    // Push approval to webhook so build script can download it
    _postToWebhook({
      'action': 'approve',
      'id': c.id,
      'type': c.type.name,
      'targetWord': c.targetWord,
      'correction': c.correction,
      'englishMeaning': c.englishMeaning ?? '',
      'category': c.category ?? '',
      'pronunciationGuide': c.pronunciationGuide ?? '',
      'reviewNotes': reviewNotes ?? '',
    });

    return true;
  }

  /// Reject a contribution (developer only).
  Future<bool> reject(String contributionId, {String? reason}) async {
    final idx = _contributions.indexWhere((c) => c.id == contributionId);
    if (idx < 0) return false;

    final c = _contributions[idx];
    c.status = ContributionStatus.rejected;
    c.reviewNotes = reason ?? 'Not applicable';
    c.reviewedAt = DateTime.now();
    _saveContributions();
    notifyListeners();

    // Push rejection to webhook
    _postToWebhook({
      'action': 'reject',
      'id': c.id,
      'reason': reason ?? 'Not applicable',
    });

    return true;
  }

  /// Sync all approved contributions to the webhook.
  /// Use this if some approvals were made offline and need pushing.
  Future<int> syncApprovedToWebhook() async {
    if (!hasWebhook) return 0;
    int synced = 0;
    for (final c in approvedContributions) {
      final ok = await _postToWebhook({
        'action': 'approve',
        'id': c.id,
        'type': c.type.name,
        'targetWord': c.targetWord,
        'correction': c.correction,
        'englishMeaning': c.englishMeaning ?? '',
        'category': c.category ?? '',
        'pronunciationGuide': c.pronunciationGuide ?? '',
        'reviewNotes': c.reviewNotes ?? '',
      });
      if (ok) synced++;
    }
    return synced;
  }

  // ==================== Export Approved ====================

  /// Export all approved contributions as a JSON file.
  /// Developer places this in the project's contributions/ folder,
  /// then runs build_and_run.bat to apply changes.
  Future<String?> exportApproved() async {
    final approved = approvedContributions;
    if (approved.isEmpty) return null;

    final jsonList = approved.map((c) => c.toJson()).toList();
    final json = const JsonEncoder.withIndent('  ').convert(jsonList);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/approved_contributions.json');
    await file.writeAsString(json);

    return file.path;
  }

  /// Share the approved contributions JSON via platform share
  /// so developer can put it in the project folder on their computer.
  Future<void> shareApproved() async {
    final path = await exportApproved();
    if (path == null) return;

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      subject: 'Awing Approved Contributions',
      text: '${approvedContributions.length} approved contributions ready '
          'to apply. Place this file in the project\'s contributions/ folder '
          'and run build_and_run.bat.',
    );
  }

  /// Clear all contributions that have been approved and exported.
  void clearApproved() {
    _contributions.removeWhere((c) => c.status == ContributionStatus.approved);
    _saveContributions();
    notifyListeners();
  }

  // ==================== Audio Recording Helpers ====================

  /// Get the path for saving a recorded audio contribution.
  Future<String> getRecordingPath(String contributionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final recordDir = Directory('${dir.path}/contributions');
    if (!await recordDir.exists()) {
      await recordDir.create(recursive: true);
    }
    return '${recordDir.path}/$contributionId.m4a';
  }

  // ==================== Persistence ====================

  void _loadContributions() {
    final json = _prefs.getString(_keyContributions);
    if (json == null) return;
    try {
      final List<dynamic> list = jsonDecode(json);
      _contributions = list.map((j) => Contribution.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('ContributionService: Load error: $e');
    }
  }

  void _saveContributions() {
    final json = jsonEncode(_contributions.map((c) => c.toJson()).toList());
    _prefs.setString(_keyContributions, json);
  }
}
