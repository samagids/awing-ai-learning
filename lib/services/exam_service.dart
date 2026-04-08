import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Represents an exam question created by the teacher.
class ExamQuestion {
  final String id;
  final String questionText; // Awing text or English depending on type
  final String type; // 'translate_to_english', 'translate_to_awing', 'listen_and_choose', 'fill_blank'
  final List<String> choices; // 4 choices
  final int correctIndex; // 0-3
  final String? audioClipKey; // for listen questions

  const ExamQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.choices,
    required this.correctIndex,
    this.audioClipKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionText': questionText,
    'type': type,
    'choices': choices,
    'correctIndex': correctIndex,
    'audioClipKey': audioClipKey,
  };

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
    id: json['id'] ?? '',
    questionText: json['questionText'] ?? '',
    type: json['type'] ?? 'translate_to_english',
    choices: List<String>.from(json['choices'] ?? []),
    correctIndex: json['correctIndex'] ?? 0,
    audioClipKey: json['audioClipKey'],
  );
}

/// A participant in the exam (student connected to teacher).
class ExamParticipant {
  final String profileId;
  final String displayName;
  final String avatarEmoji;
  String level;
  bool isReady;
  Map<String, int> answers; // questionId → chosen index
  int score;
  bool submitted;

  ExamParticipant({
    required this.profileId,
    required this.displayName,
    this.avatarEmoji = '🧒',
    this.level = 'beginner',
    this.isReady = false,
    Map<String, int>? answers,
    this.score = 0,
    this.submitted = false,
  }) : answers = answers ?? {};

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'displayName': displayName,
    'avatarEmoji': avatarEmoji,
    'level': level,
    'isReady': isReady,
    'answers': answers,
    'score': score,
    'submitted': submitted,
  };

  factory ExamParticipant.fromJson(Map<String, dynamic> json) => ExamParticipant(
    profileId: json['profileId'] ?? '',
    displayName: json['displayName'] ?? '',
    avatarEmoji: json['avatarEmoji'] ?? '🧒',
    level: json['level'] ?? 'beginner',
    isReady: json['isReady'] ?? false,
    answers: Map<String, int>.from(json['answers'] ?? {}),
    score: json['score'] ?? 0,
    submitted: json['submitted'] ?? false,
  );
}

/// State of the exam session.
enum ExamState {
  idle,       // no exam
  setup,      // teacher is setting up
  waiting,    // waiting for students to join
  inProgress, // exam running
  finished,   // exam ended, showing results
}

/// Exam session service — handles teacher/student roles and networking.
///
/// Uses TCP sockets over Wi-Fi for communication. Bluetooth discovery
/// is used to find nearby devices, then falls back to Wi-Fi for data transfer.
///
/// PROTOCOL:
///   Teacher starts a TCP server on port 9876.
///   Students connect via the teacher's IP address.
///   Messages are JSON lines (\n delimited).
///
/// Message types:
///   teacher → students: EXAM_CONFIG, EXAM_START, EXAM_END
///   students → teacher: JOIN, ANSWER, SUBMIT
class ExamService extends ChangeNotifier {
  static const int _port = 9876;

  // Role
  bool _isTeacher = false;
  bool get isTeacher => _isTeacher;

  // Exam state
  ExamState _state = ExamState.idle;
  ExamState get state => _state;

  // Exam config (set by teacher)
  String _examLevel = 'beginner'; // beginner, medium, expert
  String get examLevel => _examLevel;
  int _timeLimitMinutes = 15;
  int get timeLimitMinutes => _timeLimitMinutes;
  List<ExamQuestion> _questions = [];
  List<ExamQuestion> get questions => List.unmodifiable(_questions);

  // Participants
  final List<ExamParticipant> _participants = [];
  List<ExamParticipant> get participants => List.unmodifiable(_participants);

  // Student-side state
  ExamParticipant? _myParticipant;
  ExamParticipant? get myParticipant => _myParticipant;
  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  // Timer
  Timer? _examTimer;
  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  // Network
  ServerSocket? _server;
  Socket? _clientSocket; // student's connection to teacher
  final List<Socket> _clientSockets = []; // teacher's connections to students
  String? _teacherIp;
  String? get teacherIp => _teacherIp;

  // ==================== TEACHER METHODS ====================

  /// Start as teacher — create exam session.
  Future<void> startAsTeacher() async {
    _isTeacher = true;
    _state = ExamState.setup;
    _participants.clear();
    _questions.clear();
    notifyListeners();
  }

  /// Set exam level (beginner, medium, expert).
  void setExamLevel(String level) {
    _examLevel = level.toLowerCase();
    notifyListeners();
  }

  /// Set time limit.
  void setTimeLimit(int minutes) {
    _timeLimitMinutes = minutes;
    notifyListeners();
  }

  /// Add a question to the exam.
  void addQuestion(ExamQuestion question) {
    _questions.add(question);
    notifyListeners();
  }

  /// Remove a question by index.
  void removeQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _questions.removeAt(index);
      notifyListeners();
    }
  }

  /// Open the exam room — start TCP server, accept connections.
  Future<String?> openExamRoom() async {
    try {
      // Get device IP
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      String? ip;
      for (final interface_ in interfaces) {
        for (final addr in interface_.addresses) {
          if (!addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
        if (ip != null) break;
      }
      if (ip == null) return 'Could not determine device IP address';

      _teacherIp = ip;

      // Start TCP server
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _state = ExamState.waiting;
      notifyListeners();

      // Listen for student connections
      _server!.listen(
        _handleStudentConnection,
        onError: (e) {
          if (kDebugMode) print('Server error: $e');
        },
      );

      return null; // success
    } catch (e) {
      return 'Failed to start exam server: $e';
    }
  }

  void _handleStudentConnection(Socket socket) {
    _clientSockets.add(socket);

    socket.listen(
      (data) {
        final messages = utf8.decode(data).split('\n');
        for (final msg in messages) {
          if (msg.trim().isEmpty) continue;
          try {
            final json = jsonDecode(msg.trim());
            _handleStudentMessage(socket, json);
          } catch (e) {
            if (kDebugMode) print('Invalid message: $msg');
          }
        }
      },
      onDone: () {
        _clientSockets.remove(socket);
        // Remove participant for this socket
        _participants.removeWhere(
          (p) => p.profileId == socket.remoteAddress.address,
        );
        notifyListeners();
      },
      onError: (e) {
        _clientSockets.remove(socket);
        notifyListeners();
      },
    );
  }

  void _handleStudentMessage(Socket socket, Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'JOIN':
        final participant = ExamParticipant(
          profileId: json['profileId'] ?? socket.remoteAddress.address,
          displayName: json['displayName'] ?? 'Student',
          avatarEmoji: json['avatarEmoji'] ?? '🧒',
          level: json['level'] ?? 'beginner',
        );
        // Only accept if same level
        if (participant.level == _examLevel) {
          _participants.add(participant);
          // Send exam config to student
          _sendToSocket(socket, {
            'type': 'EXAM_CONFIG',
            'level': _examLevel,
            'timeLimit': _timeLimitMinutes,
            'questionCount': _questions.length,
          });
          notifyListeners();
        } else {
          _sendToSocket(socket, {
            'type': 'REJECT',
            'reason': 'This exam is for ${_examLevel} level only. '
                'Your level is ${participant.level}.',
          });
          socket.close();
        }
        break;

      case 'ANSWER':
        final profileId = json['profileId'] ?? '';
        final questionId = json['questionId'] ?? '';
        final answerIndex = json['answerIndex'] ?? 0;
        for (final p in _participants) {
          if (p.profileId == profileId) {
            p.answers[questionId] = answerIndex;
            notifyListeners();
            break;
          }
        }
        break;

      case 'SUBMIT':
        final profileId = json['profileId'] ?? '';
        for (final p in _participants) {
          if (p.profileId == profileId) {
            p.submitted = true;
            _calculateScore(p);
            notifyListeners();
            break;
          }
        }
        // Check if all submitted
        if (_participants.every((p) => p.submitted)) {
          endExam();
        }
        break;
    }
  }

  void _calculateScore(ExamParticipant p) {
    int correct = 0;
    for (final q in _questions) {
      final answer = p.answers[q.id];
      if (answer != null && answer == q.correctIndex) {
        correct++;
      }
    }
    p.score = _questions.isNotEmpty
        ? ((correct / _questions.length) * 100).round()
        : 0;
  }

  /// Start the exam — send questions to all students, start timer.
  void startExam() {
    if (_questions.isEmpty) return;

    _state = ExamState.inProgress;
    _secondsRemaining = _timeLimitMinutes * 60;

    // Send questions to all students
    final msg = {
      'type': 'EXAM_START',
      'questions': _questions.map((q) => q.toJson()).toList(),
      'timeLimitSeconds': _secondsRemaining,
    };
    for (final socket in _clientSockets) {
      _sendToSocket(socket, msg);
    }

    // Start countdown
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      notifyListeners();
      if (_secondsRemaining <= 0) {
        endExam();
      }
    });

    notifyListeners();
  }

  /// End the exam.
  void endExam() {
    _examTimer?.cancel();
    _state = ExamState.finished;

    // Calculate scores for all participants
    for (final p in _participants) {
      _calculateScore(p);
    }

    // Notify students
    final results = _participants.map((p) => {
      'displayName': p.displayName,
      'score': p.score,
    }).toList();

    for (final socket in _clientSockets) {
      _sendToSocket(socket, {
        'type': 'EXAM_END',
        'results': results,
      });
    }

    notifyListeners();
  }

  // ==================== STUDENT METHODS ====================

  /// Connect to teacher's exam as a student.
  Future<String?> joinExam(String teacherIp, {
    required String profileId,
    required String displayName,
    required String avatarEmoji,
    required String level,
  }) async {
    try {
      _isTeacher = false;
      _clientSocket = await Socket.connect(teacherIp, _port,
          timeout: const Duration(seconds: 5));

      _myParticipant = ExamParticipant(
        profileId: profileId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        level: level,
      );

      // Send join message
      _sendToSocket(_clientSocket!, {
        'type': 'JOIN',
        'profileId': profileId,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'level': level,
      });

      _state = ExamState.waiting;
      notifyListeners();

      // Listen for teacher messages
      _clientSocket!.listen(
        (data) {
          final messages = utf8.decode(data).split('\n');
          for (final msg in messages) {
            if (msg.trim().isEmpty) continue;
            try {
              final json = jsonDecode(msg.trim());
              _handleTeacherMessage(json);
            } catch (e) {
              if (kDebugMode) print('Invalid message from teacher: $msg');
            }
          }
        },
        onDone: () {
          _state = ExamState.idle;
          notifyListeners();
        },
        onError: (e) {
          _state = ExamState.idle;
          notifyListeners();
        },
      );

      return null;
    } catch (e) {
      return 'Could not connect to teacher: $e';
    }
  }

  void _handleTeacherMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'REJECT':
        _state = ExamState.idle;
        // Store rejection reason for UI to display
        notifyListeners();
        break;

      case 'EXAM_CONFIG':
        _examLevel = json['level'] ?? 'beginner';
        _timeLimitMinutes = json['timeLimit'] ?? 15;
        _state = ExamState.waiting;
        notifyListeners();
        break;

      case 'EXAM_START':
        _questions = (json['questions'] as List<dynamic>)
            .map((q) => ExamQuestion.fromJson(q))
            .toList();
        _secondsRemaining = json['timeLimitSeconds'] ?? 900;
        _currentQuestionIndex = 0;
        _state = ExamState.inProgress;

        // Start local timer
        _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _secondsRemaining--;
          notifyListeners();
          if (_secondsRemaining <= 0) {
            submitExam();
          }
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

  /// Submit answer for current question (student).
  void answerQuestion(String questionId, int answerIndex) {
    if (_myParticipant == null || _clientSocket == null) return;
    _myParticipant!.answers[questionId] = answerIndex;

    _sendToSocket(_clientSocket!, {
      'type': 'ANSWER',
      'profileId': _myParticipant!.profileId,
      'questionId': questionId,
      'answerIndex': answerIndex,
    });

    notifyListeners();
  }

  /// Move to next question (student).
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Move to previous question (student).
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Submit the exam (student).
  void submitExam() {
    if (_myParticipant == null || _clientSocket == null) return;
    _myParticipant!.submitted = true;
    _examTimer?.cancel();

    _sendToSocket(_clientSocket!, {
      'type': 'SUBMIT',
      'profileId': _myParticipant!.profileId,
    });

    // Calculate own score
    _calculateScore(_myParticipant!);
    _state = ExamState.finished;
    notifyListeners();
  }

  // ==================== CLEANUP ====================

  /// Close all connections and reset.
  Future<void> close() async {
    _examTimer?.cancel();
    for (final socket in _clientSockets) {
      socket.destroy();
    }
    _clientSockets.clear();
    _clientSocket?.destroy();
    _clientSocket = null;
    await _server?.close();
    _server = null;
    _state = ExamState.idle;
    _participants.clear();
    _questions.clear();
    _myParticipant = null;
    _currentQuestionIndex = 0;
    notifyListeners();
  }

  // ==================== HELPERS ====================

  void _sendToSocket(Socket socket, Map<String, dynamic> data) {
    try {
      socket.write('${jsonEncode(data)}\n');
    } catch (e) {
      if (kDebugMode) print('Send error: $e');
    }
  }

  /// Get the device's Wi-Fi IP address for display.
  Future<String?> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface_ in interfaces) {
        for (final addr in interface_.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }
}
