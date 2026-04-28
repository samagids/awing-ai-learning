import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:network_info_plus/network_info_plus.dart';

/// Represents an exam question created by the teacher.
class ExamQuestion {
  final String id;
  final String questionText;
  final String type;
  final List<String> choices;
  final int correctIndex;
  final String? audioClipKey;

  /// Awing word used to look up the illustration. Paired with `imageEnglish`
  /// so homonyms resolve to their own image.
  final String? imageKey;

  /// English gloss paired with `imageKey` so the student-side PackImage
  /// can compute the correct compound filename. Older client/teacher
  /// versions may not send this field — treat absence as empty string
  /// so the lookup degrades gracefully (fallback icon).
  final String? imageEnglish;

  const ExamQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.choices,
    required this.correctIndex,
    this.audioClipKey,
    this.imageKey,
    this.imageEnglish,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionText': questionText,
        'type': type,
        'choices': choices,
        'correctIndex': correctIndex,
        'audioClipKey': audioClipKey,
        'imageKey': imageKey,
        'imageEnglish': imageEnglish,
      };

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] ?? '',
        questionText: json['questionText'] ?? '',
        type: json['type'] ?? 'translate_to_english',
        choices: List<String>.from(json['choices'] ?? []),
        correctIndex: json['correctIndex'] ?? 0,
        audioClipKey: json['audioClipKey'],
        imageKey: json['imageKey'],
        imageEnglish: json['imageEnglish'],
      );
}

/// A participant in the exam (student connected to teacher).
class ExamParticipant {
  final String profileId;
  final String displayName;
  final String avatarEmoji;
  String level;
  Socket? socket; // teacher-side: socket back to student
  bool isReady;
  Map<String, int> answers;
  int score;
  bool submitted;

  ExamParticipant({
    required this.profileId,
    required this.displayName,
    this.avatarEmoji = '🧒',
    this.level = 'beginner',
    this.socket,
    this.isReady = false,
    Map<String, int>? answers,
    this.score = 0,
    this.submitted = false,
  }) : answers = answers ?? {};
}

class PendingJoinRequest {
  final String profileId;
  final String displayName;
  final String avatarEmoji;
  final String level;
  final Socket socket;

  const PendingJoinRequest({
    required this.profileId,
    required this.displayName,
    required this.avatarEmoji,
    required this.level,
    required this.socket,
  });
}

/// Kept for source compatibility with older screen code; unused.
class DiscoveredTeacher {
  final String endpointId;
  final String endpointName;
  final DateTime discoveredAt;
  const DiscoveredTeacher({
    required this.endpointId,
    required this.endpointName,
    required this.discoveredAt,
  });
}

enum ExamState {
  idle,
  setup,
  waiting,
  inProgress,
  finished,
}

/// Exam session service — Kahoot-style PIN over the local network.
///
/// The teacher generates a 6-digit PIN, opens a TCP server, and registers
/// an mDNS service whose **name is the PIN itself**. The student types the
/// same PIN, runs a quick mDNS scan looking for a service with that name,
/// gets back the teacher's host:port, and opens a TCP socket.
///
/// Works offline — both devices just need to share a Wi-Fi network or
/// one device's hotspot. No internet required.
class ExamService extends ChangeNotifier {
  static const String _serviceType = '_awing-exam._tcp';
  static const int _basePort = 9876;
  static const Duration _pinSearchTimeout = Duration(seconds: 12);

  // ---------- role / state ----------
  bool _isTeacher = false;
  bool get isTeacher => _isTeacher;

  ExamState _state = ExamState.idle;
  ExamState get state => _state;

  String _examLevel = 'beginner';
  String get examLevel => _examLevel;

  int _timeLimitMinutes = 15;
  int get timeLimitMinutes => _timeLimitMinutes;

  List<ExamQuestion> _questions = [];
  List<ExamQuestion> get questions => List.unmodifiable(_questions);

  // The PIN — both sides see the same value.
  String? _pin;
  String? get pin => _pin;
  String get advertisedName => _pin ?? '';

  String? _localIp;
  String? get localIp => _localIp;

  // ---------- teacher-side ----------
  final List<ExamParticipant> _participants = [];
  List<ExamParticipant> get participants => List.unmodifiable(_participants);

  final List<PendingJoinRequest> _pendingJoins = [];
  List<PendingJoinRequest> get pendingJoins => List.unmodifiable(_pendingJoins);

  // ---------- student-side ----------
  ExamParticipant? _myParticipant;
  ExamParticipant? get myParticipant => _myParticipant;
  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;
  Socket? _teacherSocket;
  String? _rejectReason;
  String? get rejectReason => _rejectReason;
  bool _isApproved = false;
  bool get isApproved => _isApproved;

  // ---------- timer ----------
  Timer? _examTimer;
  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  // ---------- network internals ----------
  ServerSocket? _serverSocket;
  nsd.Registration? _mdnsRegistration;
  Timer? _mdnsKeepalive;

  // ---------- legacy hooks for source compat ----------
  bool get permissionsPermanentlyDenied => false;
  List<DiscoveredTeacher> get discoveredTeachers => const [];
  Future<bool> requestPermissions() async => true;
  Future<String?> requestPermissionsWithReason() async => null;
  Future<void> openPermissionSettings() async {}
  Future<List<String>> diagnose() async {
    final problems = <String>[];
    final ip = await _getLocalIp();
    if (ip == null) {
      problems.add(
          'No Wi-Fi network detected. Connect to Wi-Fi (or join the teacher\'s hotspot) and try again.');
    }
    return problems;
  }

  Future<String?> startDiscovering({required String studentName}) async => null;
  Future<void> stopDiscovering() async {}
  Future<String?> requestJoinTeacher({
    required String endpointId,
    required String profileId,
    required String displayName,
    required String avatarEmoji,
    required String level,
  }) =>
      joinByPin(
        pin: endpointId,
        profileId: profileId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        level: level,
      );

  // ==================== HELPERS ====================

  Future<String?> _getLocalIp() async {
    try {
      final wifi = NetworkInfo();
      final ip = await wifi.getWifiIP();
      if (ip != null && ip.isNotEmpty) return ip;
    } catch (_) {}
    try {
      final ifaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final i in ifaces) {
        for (final a in i.addresses) {
          if (!a.isLoopback) return a.address;
        }
      }
    } catch (_) {}
    return null;
  }

  String _generatePin() {
    final r = Random.secure();
    final n = 100000 + r.nextInt(900000);
    return n.toString();
  }

  void _sendToSocket(Socket s, Map<String, dynamic> data) {
    try {
      s.write('${jsonEncode(data)}\n');
    } catch (e) {
      if (kDebugMode) print('Send error: $e');
    }
  }

  // ==================== TEACHER METHODS ====================

  Future<void> startAsTeacher() async {
    _isTeacher = true;
    _state = ExamState.setup;
    _participants.clear();
    _pendingJoins.clear();
    _questions.clear();
    notifyListeners();
  }

  void setExamLevel(String level) {
    _examLevel = level.toLowerCase();
    notifyListeners();
  }

  void setTimeLimit(int minutes) {
    _timeLimitMinutes = minutes;
    notifyListeners();
  }

  void addQuestion(ExamQuestion question) {
    _questions.add(question);
    notifyListeners();
  }

  void removeQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _questions.removeAt(index);
      notifyListeners();
    }
  }

  /// Open the exam room — bind a TCP server and register an mDNS service
  /// whose **name is the PIN** so the student can look it up by PIN.
  Future<String?> openExamRoom(String teacherName) async {
    try {
      _localIp = await _getLocalIp();
      if (_localIp == null) {
        return 'No Wi-Fi network detected. Connect to Wi-Fi (or start a hotspot) and try again.';
      }

      _pin = _generatePin();

      // Bind a TCP server on a free port.
      ServerSocket? server;
      for (var attempt = 0; attempt < 20; attempt++) {
        try {
          server = await ServerSocket.bind(
              InternetAddress.anyIPv4, _basePort + attempt);
          break;
        } catch (_) {}
      }
      if (server == null) {
        return 'Could not open a network port on this device.';
      }
      _serverSocket = server;
      final port = server.port;
      if (kDebugMode) print('Awing exam server on ${_localIp!}:$port (PIN $_pin)');
      server.listen(_handleStudentConnection, onError: (e) {
        if (kDebugMode) print('ServerSocket error: $e');
      });

      await _registerMdns(port, teacherName: teacherName);

      // Re-announce every 25s in case the OS drops the registration.
      _mdnsKeepalive?.cancel();
      _mdnsKeepalive =
          Timer.periodic(const Duration(seconds: 25), (_) async {
        if (_serverSocket == null) return;
        try {
          if (_mdnsRegistration != null) {
            await nsd.unregister(_mdnsRegistration!);
          }
        } catch (_) {}
        _mdnsRegistration = null;
        await _registerMdns(port, teacherName: teacherName);
      });

      _state = ExamState.waiting;
      notifyListeners();
      return null;
    } catch (e) {
      await _stopServer();
      return 'Failed to open exam room: $e';
    }
  }

  Future<void> _registerMdns(int port, {required String teacherName}) async {
    try {
      _mdnsRegistration = await nsd.register(
        nsd.Service(
          // Service name == PIN. Students look up by exact name.
          name: _pin!,
          type: _serviceType,
          port: port,
          txt: {
            'teacher': utf8.encode(teacherName),
            'level': utf8.encode(_examLevel),
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) print('mDNS register failed: $e');
    }
  }

  Future<void> _stopServer() async {
    _mdnsKeepalive?.cancel();
    _mdnsKeepalive = null;
    if (_mdnsRegistration != null) {
      try {
        await nsd.unregister(_mdnsRegistration!);
      } catch (_) {}
    }
    _mdnsRegistration = null;
    try {
      await _serverSocket?.close();
    } catch (_) {}
    _serverSocket = null;
  }

  void _handleStudentConnection(Socket socket) {
    final buffer = StringBuffer();
    socket.listen(
      (data) {
        try {
          buffer.write(utf8.decode(data, allowMalformed: true));
        } catch (_) {
          return;
        }
        while (true) {
          final raw = buffer.toString();
          final nl = raw.indexOf('\n');
          if (nl < 0) break;
          final line = raw.substring(0, nl).trim();
          buffer.clear();
          buffer.write(raw.substring(nl + 1));
          if (line.isEmpty) continue;
          try {
            final msg = jsonDecode(line);
            if (msg is Map<String, dynamic>) {
              _handleStudentMessage(socket, msg);
            }
          } catch (e) {
            if (kDebugMode) print('Bad message: $line ($e)');
          }
        }
      },
      onDone: () => _onStudentDisconnected(socket),
      onError: (_) => _onStudentDisconnected(socket),
    );
  }

  void _onStudentDisconnected(Socket socket) {
    _pendingJoins.removeWhere((p) => identical(p.socket, socket));
    _participants.removeWhere((p) => identical(p.socket, socket));
    notifyListeners();
  }

  void _handleStudentMessage(Socket socket, Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'JOIN':
        if (_state == ExamState.inProgress || _state == ExamState.finished) {
          _sendToSocket(socket, {
            'type': 'REJECT',
            'reason': 'The exam has already started. Please join the next one.',
          });
          socket.destroy();
          return;
        }
        final profileId = (json['profileId'] as String?) ?? '';
        if (profileId.isEmpty) {
          _sendToSocket(socket, {
            'type': 'REJECT',
            'reason': 'Invalid profile. Please update the app.',
          });
          socket.destroy();
          return;
        }
        final level = (json['level'] as String?) ?? 'beginner';
        if (level != _examLevel) {
          _sendToSocket(socket, {
            'type': 'REJECT',
            'reason':
                'This exam is for $_examLevel level only. Your level is $level.',
          });
          socket.destroy();
          return;
        }
        _pendingJoins.removeWhere((p) => p.profileId == profileId);
        _pendingJoins.add(PendingJoinRequest(
          profileId: profileId,
          displayName: (json['displayName'] as String?) ?? 'Student',
          avatarEmoji: (json['avatarEmoji'] as String?) ?? '🧒',
          level: level,
          socket: socket,
        ));
        notifyListeners();
        break;

      case 'ANSWER':
        final profileId = (json['profileId'] as String?) ?? '';
        final questionId = (json['questionId'] as String?) ?? '';
        final answerIndex = (json['answerIndex'] as int?) ?? 0;
        for (final p in _participants) {
          if (p.profileId == profileId) {
            p.answers[questionId] = answerIndex;
            notifyListeners();
            break;
          }
        }
        break;

      case 'SUBMIT':
        final profileId = (json['profileId'] as String?) ?? '';
        for (final p in _participants) {
          if (p.profileId == profileId) {
            p.submitted = true;
            _calculateScore(p);
            notifyListeners();
            break;
          }
        }
        if (_participants.isNotEmpty &&
            _participants.every((p) => p.submitted)) {
          endExam();
        }
        break;
    }
  }

  Future<void> approvePending(String profileId) async {
    final idx = _pendingJoins.indexWhere((p) => p.profileId == profileId);
    if (idx < 0) return;
    final req = _pendingJoins.removeAt(idx);
    _participants.add(ExamParticipant(
      profileId: req.profileId,
      displayName: req.displayName,
      avatarEmoji: req.avatarEmoji,
      level: req.level,
      socket: req.socket,
    ));
    _sendToSocket(req.socket, {
      'type': 'APPROVED',
      'level': _examLevel,
      'timeLimit': _timeLimitMinutes,
      'questionCount': _questions.length,
    });
    notifyListeners();
  }

  Future<void> rejectPending(String profileId) async {
    final idx = _pendingJoins.indexWhere((p) => p.profileId == profileId);
    if (idx < 0) return;
    final req = _pendingJoins.removeAt(idx);
    _sendToSocket(req.socket, {
      'type': 'REJECT',
      'reason': 'Not approved by teacher.',
    });
    try {
      req.socket.destroy();
    } catch (_) {}
    notifyListeners();
  }

  void _calculateScore(ExamParticipant p) {
    int correct = 0;
    for (final q in _questions) {
      final a = p.answers[q.id];
      if (a != null && a == q.correctIndex) correct++;
    }
    p.score = _questions.isNotEmpty
        ? ((correct / _questions.length) * 100).round()
        : 0;
  }

  void startExam() {
    if (_questions.isEmpty) return;

    // Close discovery so no new students can find this device by PIN.
    _mdnsKeepalive?.cancel();
    _mdnsKeepalive = null;
    if (_mdnsRegistration != null) {
      // ignore: discarded_futures
      nsd.unregister(_mdnsRegistration!).catchError((_) {});
      _mdnsRegistration = null;
    }

    // Reject any unapproved pending joins.
    for (final pending in List<PendingJoinRequest>.from(_pendingJoins)) {
      _sendToSocket(pending.socket, {
        'type': 'REJECT',
        'reason': 'The exam has already started.',
      });
      try {
        pending.socket.destroy();
      } catch (_) {}
    }
    _pendingJoins.clear();

    _state = ExamState.inProgress;
    _secondsRemaining = _timeLimitMinutes * 60;
    final msg = {
      'type': 'EXAM_START',
      'questions': _questions.map((q) => q.toJson()).toList(),
      'timeLimitSeconds': _secondsRemaining,
    };
    for (final p in _participants) {
      if (p.socket != null) _sendToSocket(p.socket!, msg);
    }
    _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsRemaining--;
      notifyListeners();
      if (_secondsRemaining <= 0) endExam();
    });
    notifyListeners();
  }

  void endExam() {
    _examTimer?.cancel();
    _state = ExamState.finished;
    for (final p in _participants) {
      _calculateScore(p);
    }
    final results = _participants
        .map((p) => {'displayName': p.displayName, 'score': p.score})
        .toList();
    for (final p in _participants) {
      if (p.socket != null) {
        _sendToSocket(p.socket!, {'type': 'EXAM_END', 'results': results});
      }
    }
    notifyListeners();
  }

  // ==================== STUDENT METHODS ====================

  /// Look up the teacher by PIN (mDNS service name) and connect.
  /// Single call replaces "discover + pick from list + connect".
  Future<String?> joinByPin({
    required String pin,
    required String profileId,
    required String displayName,
    required String avatarEmoji,
    required String level,
  }) async {
    final cleaned = pin.trim();
    if (cleaned.length != 6 || int.tryParse(cleaned) == null) {
      return 'PIN must be a 6-digit number.';
    }

    _isTeacher = false;
    _pin = cleaned;
    _localIp = await _getLocalIp();
    if (_localIp == null) {
      return 'No Wi-Fi network detected. Connect to Wi-Fi (or join the teacher\'s hotspot) and try again.';
    }

    // Start an mDNS discovery, scan until we see a service whose name matches the PIN.
    nsd.Discovery? disc;
    final completer = Completer<_ResolvedService?>();
    Timer? timeoutTimer;

    void onUpdate() {
      final d = disc;
      if (d == null) return;
      for (final svc in d.services) {
        if (svc.name != cleaned) continue;
        // Resolve host.
        String? host;
        if (svc.addresses != null && svc.addresses!.isNotEmpty) {
          for (final a in svc.addresses!) {
            if (a.type == InternetAddressType.IPv4) {
              host = a.address;
              break;
            }
          }
          host ??= svc.addresses!.first.address;
        } else if (svc.host != null && svc.host!.isNotEmpty) {
          host = svc.host;
        }
        final port = svc.port;
        if (host != null && port != null) {
          if (!completer.isCompleted) {
            completer.complete(_ResolvedService(host: host, port: port));
          }
          return;
        }
      }
    }

    try {
      disc = await nsd.startDiscovery(
        _serviceType,
        autoResolve: true,
        ipLookupType: nsd.IpLookupType.v4,
      );
      disc.addListener(onUpdate);
      onUpdate();

      timeoutTimer = Timer(_pinSearchTimeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final resolved = await completer.future;
      timeoutTimer.cancel();
      try {
        disc.removeListener(onUpdate);
        await nsd.stopDiscovery(disc);
      } catch (_) {}

      if (resolved == null) {
        return 'No exam found with PIN $cleaned. Make sure both devices are on the same Wi-Fi (or the teacher\'s hotspot), and that the teacher\'s room is open.';
      }

      // Connect.
      _myParticipant = ExamParticipant(
        profileId: profileId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        level: level,
      );
      _isApproved = false;
      _rejectReason = null;

      try {
        final socket = await Socket.connect(resolved.host, resolved.port,
            timeout: const Duration(seconds: 8));
        _teacherSocket = socket;

        final buffer = StringBuffer();
        socket.listen(
          (data) {
            try {
              buffer.write(utf8.decode(data, allowMalformed: true));
            } catch (_) {
              return;
            }
            while (true) {
              final raw = buffer.toString();
              final nl = raw.indexOf('\n');
              if (nl < 0) break;
              final line = raw.substring(0, nl).trim();
              buffer.clear();
              buffer.write(raw.substring(nl + 1));
              if (line.isEmpty) continue;
              try {
                final msg = jsonDecode(line);
                if (msg is Map<String, dynamic>) _handleTeacherMessage(msg);
              } catch (_) {}
            }
          },
          onDone: () {
            _state = ExamState.idle;
            _teacherSocket = null;
            notifyListeners();
          },
          onError: (_) {
            _state = ExamState.idle;
            _teacherSocket = null;
            notifyListeners();
          },
        );

        _sendToSocket(socket, {
          'type': 'JOIN',
          'profileId': profileId,
          'displayName': displayName,
          'avatarEmoji': avatarEmoji,
          'level': level,
        });

        _state = ExamState.waiting;
        notifyListeners();
        return null;
      } catch (e) {
        _teacherSocket = null;
        return 'Found PIN $cleaned but couldn\'t connect to the teacher. They may have just closed the room — try again.';
      }
    } catch (e) {
      try {
        if (disc != null) await nsd.stopDiscovery(disc);
      } catch (_) {}
      timeoutTimer?.cancel();
      return 'Could not search for the exam: $e';
    }
  }

  void _handleTeacherMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'REJECT':
        _rejectReason = (json['reason'] as String?) ?? 'Not approved.';
        _state = ExamState.idle;
        notifyListeners();
        break;
      case 'APPROVED':
        _examLevel = (json['level'] as String?) ?? 'beginner';
        _timeLimitMinutes = (json['timeLimit'] as int?) ?? 15;
        _isApproved = true;
        _state = ExamState.waiting;
        notifyListeners();
        break;
      case 'EXAM_START':
        final raw = json['questions'];
        if (raw is List) {
          _questions = raw
              .whereType<Map<String, dynamic>>()
              .map((q) => ExamQuestion.fromJson(q))
              .toList();
        }
        _secondsRemaining = (json['timeLimitSeconds'] as int?) ?? 900;
        _currentQuestionIndex = 0;
        _state = ExamState.inProgress;
        _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _secondsRemaining--;
          notifyListeners();
          if (_secondsRemaining <= 0) submitExam();
        });
        notifyListeners();
        break;
      case 'EXAM_END':
        _examTimer?.cancel();
        _state = ExamState.finished;
        notifyListeners();
        break;
    }
  }

  void answerQuestion(String questionId, int answerIndex) {
    if (_myParticipant == null || _teacherSocket == null) return;
    _myParticipant!.answers[questionId] = answerIndex;
    _sendToSocket(_teacherSocket!, {
      'type': 'ANSWER',
      'profileId': _myParticipant!.profileId,
      'questionId': questionId,
      'answerIndex': answerIndex,
    });
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void submitExam() {
    if (_myParticipant == null || _teacherSocket == null) return;
    _myParticipant!.submitted = true;
    _examTimer?.cancel();
    _sendToSocket(_teacherSocket!, {
      'type': 'SUBMIT',
      'profileId': _myParticipant!.profileId,
    });
    _calculateScore(_myParticipant!);
    _state = ExamState.finished;
    notifyListeners();
  }

  // ==================== CLEANUP ====================

  Future<void> close() async {
    _examTimer?.cancel();
    await _stopServer();
    try {
      _teacherSocket?.destroy();
    } catch (_) {}
    _teacherSocket = null;
    for (final p in _participants) {
      try {
        p.socket?.destroy();
      } catch (_) {}
    }
    for (final p in _pendingJoins) {
      try {
        p.socket.destroy();
      } catch (_) {}
    }
    _state = ExamState.idle;
    _participants.clear();
    _pendingJoins.clear();
    _questions.clear();
    _myParticipant = null;
    _currentQuestionIndex = 0;
    _rejectReason = null;
    _isApproved = false;
    _pin = null;
    notifyListeners();
  }
}

class _ResolvedService {
  final String host;
  final int port;
  const _ResolvedService({required this.host, required this.port});
}
