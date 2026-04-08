import 'dart:convert';

/// A single user profile within an email account.
/// One email can have multiple profiles (e.g. siblings sharing a tablet).
class UserProfile {
  final String id; // unique ID (timestamp-based)
  String displayName;
  String avatarEmoji; // kid-friendly emoji avatar
  String currentLevel; // 'beginner', 'medium', 'expert'
  bool beginnerUnlocked;
  bool mediumUnlocked;
  bool expertUnlocked;
  Map<String, bool> lessonsCompleted; // lessonId → completed
  Map<String, int> quizBestScores; // quizId → best score (0-100)
  int totalXP;
  String? pin; // optional 4-digit PIN to protect this profile
  DateTime createdAt;
  DateTime lastActiveAt;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarEmoji = '🧒',
    this.currentLevel = 'beginner',
    this.beginnerUnlocked = true,
    this.mediumUnlocked = false,
    this.expertUnlocked = false,
    Map<String, bool>? lessonsCompleted,
    Map<String, int>? quizBestScores,
    this.totalXP = 0,
    this.pin,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  })  : lessonsCompleted = lessonsCompleted ?? {},
        quizBestScores = quizBestScores ?? {},
        createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  /// Whether this profile has a PIN set.
  bool get hasPin => pin != null && pin!.length == 4;

  /// Verify a PIN attempt. Returns true if no PIN set or if PIN matches.
  bool verifyPin(String attempt) {
    if (!hasPin) return true;
    return attempt == pin;
  }

  /// Beginner lessons the user must complete to unlock Medium
  static const beginnerLessonIds = [
    'beginner_alphabet',
    'beginner_vocabulary',
    'beginner_tones',
    'beginner_numbers',
    'beginner_phrases',
    'beginner_pronunciation',
  ];

  /// Medium lessons the user must complete to unlock Expert
  static const mediumLessonIds = [
    'medium_clusters',
    'medium_vowels',
    'medium_noun_classes',
    'medium_sentences',
  ];

  /// Check if all beginner lessons are done AND quiz >= 90%
  bool get canUnlockMedium {
    final allLessons = beginnerLessonIds.every(
      (id) => lessonsCompleted[id] == true,
    );
    final quizScore = quizBestScores['beginner_quiz'] ?? 0;
    return allLessons && quizScore >= 90;
  }

  /// Check if all medium lessons are done AND quiz >= 90%
  bool get canUnlockExpert {
    final allLessons = mediumLessonIds.every(
      (id) => lessonsCompleted[id] == true,
    );
    final quizScore = quizBestScores['medium_writing_quiz'] ?? 0;
    return allLessons && quizScore >= 90;
  }

  /// Get completion count for a level
  int beginnerLessonsCompleted() =>
      beginnerLessonIds.where((id) => lessonsCompleted[id] == true).length;

  int mediumLessonsCompleted() =>
      mediumLessonIds.where((id) => lessonsCompleted[id] == true).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'currentLevel': currentLevel,
        'beginnerUnlocked': beginnerUnlocked,
        'mediumUnlocked': mediumUnlocked,
        'expertUnlocked': expertUnlocked,
        'lessonsCompleted': lessonsCompleted,
        'quizBestScores': quizBestScores,
        'totalXP': totalXP,
        'pin': pin,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: json['displayName'] ?? 'Learner',
        avatarEmoji: json['avatarEmoji'] ?? '🧒',
        currentLevel: json['currentLevel'] ?? 'beginner',
        beginnerUnlocked: json['beginnerUnlocked'] ?? true,
        mediumUnlocked: json['mediumUnlocked'] ?? false,
        expertUnlocked: json['expertUnlocked'] ?? false,
        lessonsCompleted: Map<String, bool>.from(json['lessonsCompleted'] ?? {}),
        quizBestScores: Map<String, int>.from(json['quizBestScores'] ?? {}),
        totalXP: json['totalXP'] ?? 0,
        pin: json['pin'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'])
            : DateTime.now(),
      );
}

/// Represents a logged-in email account that can hold multiple user profiles.
/// Typically a parent registers, then creates child profiles under the account.
class UserAccount {
  final String email;
  final String authMethod; // 'email' or 'google'
  String? passwordHash; // only for email auth (hashed)
  String? parentName; // Parent/guardian display name
  String? whatsappNumber; // Parent WhatsApp number for activity reports
  bool sendQuizNotifications; // Send WhatsApp message after each quiz
  bool sendWeeklySummary; // Send weekly activity summary via WhatsApp
  String? accountPin; // 4-digit PIN required to sign out or delete profiles
  List<UserProfile> profiles;
  DateTime createdAt;

  UserAccount({
    required this.email,
    this.authMethod = 'email',
    this.passwordHash,
    this.parentName,
    this.whatsappNumber,
    this.sendQuizNotifications = true,
    this.sendWeeklySummary = true,
    this.accountPin,
    List<UserProfile>? profiles,
    DateTime? createdAt,
  })  : profiles = profiles ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Whether this account has a parent PIN set.
  bool get hasAccountPin => accountPin != null && accountPin!.length == 4;

  /// Verify the account-level PIN. Returns true if no PIN set or if correct.
  bool verifyAccountPin(String attempt) {
    if (!hasAccountPin) return true;
    return attempt == accountPin;
  }

  bool get isDeveloper => email.toLowerCase() == 'samagids@gmail.com';
  bool get hasWhatsApp => whatsappNumber != null && whatsappNumber!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'email': email,
        'authMethod': authMethod,
        'passwordHash': passwordHash,
        'parentName': parentName,
        'whatsappNumber': whatsappNumber,
        'sendQuizNotifications': sendQuizNotifications,
        'sendWeeklySummary': sendWeeklySummary,
        'accountPin': accountPin,
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        email: json['email'] ?? '',
        authMethod: json['authMethod'] ?? 'email',
        passwordHash: json['passwordHash'],
        parentName: json['parentName'],
        whatsappNumber: json['whatsappNumber'],
        sendQuizNotifications: json['sendQuizNotifications'] ?? true,
        sendWeeklySummary: json['sendWeeklySummary'] ?? true,
        accountPin: json['accountPin'],
        profiles: (json['profiles'] as List<dynamic>?)
                ?.map((p) => UserProfile.fromJson(p))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
