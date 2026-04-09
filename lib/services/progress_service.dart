import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spaced repetition box level (0-4)
/// Box 0: review every session
/// Box 1: review in 1 day
/// Box 2: review in 3 days
/// Box 3: review in 7 days
/// Box 4: review in 14 days (mastered)
class SpacedRepetitionWord {
  final String word;
  int box; // 0-4
  DateTime nextReviewDate;
  int timesCorrect;
  int timesIncorrect;
  DateTime dateAdded;

  SpacedRepetitionWord({
    required this.word,
    this.box = 0,
    DateTime? nextReviewDate,
    this.timesCorrect = 0,
    this.timesIncorrect = 0,
    DateTime? dateAdded,
  })  : nextReviewDate = nextReviewDate ?? DateTime.now(),
        dateAdded = dateAdded ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'box': box,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'timesCorrect': timesCorrect,
      'timesIncorrect': timesIncorrect,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Create from JSON
  factory SpacedRepetitionWord.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionWord(
      word: json['word'] ?? '',
      box: json['box'] ?? 0,
      nextReviewDate: DateTime.parse(json['nextReviewDate'] ?? DateTime.now().toIso8601String()),
      timesCorrect: json['timesCorrect'] ?? 0,
      timesIncorrect: json['timesIncorrect'] ?? 0,
      dateAdded: DateTime.parse(json['dateAdded'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Badge achievement data
class Badge {
  final String id; // e.g., "first_steps"
  final String title; // e.g., "First Steps"
  final String description; // e.g., "Complete first lesson"
  final String emoji; // e.g., "🎯"
  bool unlocked;
  DateTime? unlockedDate;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlocked = false,
    this.unlockedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '',
      unlocked: json['unlocked'] ?? false,
      unlockedDate: json['unlockedDate'] != null ? DateTime.parse(json['unlockedDate']) : null,
    );
  }
}

/// Main progress tracking and gamification service
class ProgressService extends ChangeNotifier {
  static const String _keyCompletedLessons = 'completed_lessons';
  static const String _keyQuizScores = 'quiz_scores';
  static const String _keyDailyStreak = 'daily_streak';
  static const String _keyLastOpenDate = 'last_open_date';
  static const String _keyWordsLearned = 'words_learned';
  static const String _keySpacedRepetition = 'spaced_repetition';
  static const String _keyTotalXP = 'total_xp';
  static const String _keyBadges = 'badges';
  static const String _keyViewedLetters = 'viewed_letters';
  static const String _keyViewedWords = 'viewed_words';
  static const String _keyTriedDifficultyLevels = 'tried_difficulty_levels';

  late SharedPreferences _prefs;
  bool _initialized = false;

  // In-memory cache — safe defaults so getters work before initialize()
  Set<String> _completedLessons = {};
  Map<String, int> _quizScores = {};
  int _dailyStreak = 0;
  int _totalXP = 0;
  Map<String, SpacedRepetitionWord> _spacedRepetitionData = {};
  Map<String, Badge> _badges = {};
  Set<String> _viewedLetters = {};
  Set<String> _viewedWords = {};
  Set<String> _triedDifficultyLevels = {};

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load all data
    _completedLessons = _loadStringSet(_keyCompletedLessons);
    _quizScores = _loadIntMap(_keyQuizScores);
    _spacedRepetitionData = _loadSpacedRepetition(_keySpacedRepetition);
    _totalXP = _prefs.getInt(_keyTotalXP) ?? 0;
    _badges = _initializeBadges();
    _viewedLetters = _loadStringSet(_keyViewedLetters);
    _viewedWords = _loadStringSet(_keyViewedWords);
    _triedDifficultyLevels = _loadStringSet(_keyTriedDifficultyLevels);

    // Handle daily streak
    _updateDailyStreak();

    _initialized = true;
    notifyListeners();
  }

  /// Reload all progress data from SharedPreferences.
  /// Call after cloud restore writes new data to prefs.
  void refreshFromPrefs() {
    if (!_initialized) return;
    _completedLessons = _loadStringSet(_keyCompletedLessons);
    _quizScores = _loadIntMap(_keyQuizScores);
    _spacedRepetitionData = _loadSpacedRepetition(_keySpacedRepetition);
    _totalXP = _prefs.getInt(_keyTotalXP) ?? 0;
    _badges = _initializeBadges();
    _viewedLetters = _loadStringSet(_keyViewedLetters);
    _viewedWords = _loadStringSet(_keyViewedWords);
    _triedDifficultyLevels = _loadStringSet(_keyTriedDifficultyLevels);
    notifyListeners();
  }

  /// Get current level based on XP
  int get currentLevel => (_totalXP ~/ 200) + 1;

  /// Alias for currentLevel
  int get level => currentLevel;

  /// Get total XP (property alias)
  int get xp => _totalXP;

  /// Get total XP (getter alias)
  int get totalXP => _totalXP;

  /// Get daily streak (property alias)
  int get dailyStreak => _dailyStreak;

  /// Get XP needed for next level (total per level = 200)
  int get xpForNextLevel {
    int xpAtCurrentLevel = (currentLevel - 1) * 200;
    return 200 - (_totalXP - xpAtCurrentLevel);
  }

  /// XP budget per level
  int get xpToNextLevel => 200;

  /// Get current XP progress within current level (0-200)
  int get currentLevelXP => _totalXP % 200;

  /// Alias for currentLevelXP
  int get xpInCurrentLevel => currentLevelXP;

  /// Get current progress percentage (0-100)
  int get levelProgressPercent {
    return ((currentLevelXP / 200) * 100).toInt();
  }

  /// Mark a lesson as completed
  Future<void> completeLesson(String lessonId) async {
    if (!_completedLessons.contains(lessonId)) {
      _completedLessons.add(lessonId);
      await _saveStringSet(_keyCompletedLessons, _completedLessons);

      // Award XP
      await addXP(50);

      // Check badges
      await _checkBadgesOnLessonComplete(lessonId);

      notifyListeners();
    }
  }

  /// Check if a lesson is completed
  bool isLessonCompleted(String lessonId) {
    return _completedLessons.contains(lessonId);
  }

  /// Get all completed lessons
  List<String> getCompletedLessons() {
    return _completedLessons.toList();
  }

  /// Save a quiz score
  Future<void> saveQuizScore(String quizType, int score) async {
    int currentBest = _quizScores[quizType] ?? 0;
    if (score > currentBest) {
      _quizScores[quizType] = score;
      await _saveIntMap(_keyQuizScores, _quizScores);

      // Award XP for high scores
      await addXP(10);

      // Check for Quiz Whiz badge
      if (score == 100) {
        await _unlockBadge('quiz_whiz');
      }

      notifyListeners();
    }
  }

  /// Get best score for a quiz type
  int getBestQuizScore(String quizType) {
    return _quizScores[quizType] ?? 0;
  }

  /// Get all quiz scores
  Map<String, int> getAllQuizScores() {
    return Map.from(_quizScores);
  }

  /// Get current daily streak
  int getDailyStreak() {
    return _dailyStreak;
  }

  /// Add XP and notify listeners
  Future<void> addXP(int xp) async {
    _totalXP += xp;
    await _prefs.setInt(_keyTotalXP, _totalXP);
    notifyListeners();
  }

  /// Get total XP
  int getTotalXP() {
    return _totalXP;
  }

  /// Mark a word as viewed (adds to spaced repetition system)
  Future<void> markWordViewed(String word) async {
    if (!_viewedWords.contains(word)) {
      _viewedWords.add(word);
      await _saveStringSet(_keyViewedWords, _viewedWords);

      // Add to spaced repetition if not already there
      if (!_spacedRepetitionData.containsKey(word)) {
        _spacedRepetitionData[word] = SpacedRepetitionWord(word: word);
        await _saveSpacedRepetition(_keySpacedRepetition, _spacedRepetitionData);
      }

      // Check Word Collector badge
      if (_viewedWords.length == 10) {
        await _unlockBadge('word_collector');
      }

      // Check Vocabulary Champion badge
      if (_viewedWords.length == 67) {
        await _unlockBadge('vocabulary_champion');
      }

      notifyListeners();
    }
  }

  /// Mark a letter as viewed
  Future<void> markLetterViewed(String letter) async {
    if (!_viewedLetters.contains(letter)) {
      _viewedLetters.add(letter);
      await _saveStringSet(_keyViewedLetters, _viewedLetters);

      // Check Alphabet Pro badge
      if (_viewedLetters.length == 31) {
        await _unlockBadge('alphabet_pro');
      }

      notifyListeners();
    }
  }

  /// Mark difficulty level as tried
  Future<void> markDifficultyLevelTried(String level) async {
    if (!_triedDifficultyLevels.contains(level)) {
      _triedDifficultyLevels.add(level);
      await _saveStringSet(_keyTriedDifficultyLevels, _triedDifficultyLevels);

      // Check Language Explorer badge
      if (_triedDifficultyLevels.length == 3) {
        await _unlockBadge('language_explorer');
      }

      notifyListeners();
    }
  }

  /// Get words that need review today
  List<SpacedRepetitionWord> getWordsToReview() {
    List<SpacedRepetitionWord> toReview = [];
    DateTime now = DateTime.now();

    for (var word in _spacedRepetitionData.values) {
      if (word.nextReviewDate.isBefore(now) || word.nextReviewDate.isAtSameMomentAs(now)) {
        toReview.add(word);
      }
    }

    // Sort by next review date (oldest first)
    toReview.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return toReview;
  }

  /// Record an answer in spaced repetition
  Future<void> recordSpacedRepetitionAnswer(String word, bool correct) async {
    if (!_spacedRepetitionData.containsKey(word)) {
      _spacedRepetitionData[word] = SpacedRepetitionWord(word: word);
    }

    var srWord = _spacedRepetitionData[word]!;

    if (correct) {
      srWord.timesCorrect++;

      // Move to next box (max 4)
      if (srWord.box < 4) {
        srWord.box++;
      }

      // Calculate next review date based on box
      int daysUntilReview = _getDaysForBox(srWord.box);
      srWord.nextReviewDate = DateTime.now().add(Duration(days: daysUntilReview));

      // Award XP
      await addXP(5);
    } else {
      srWord.timesIncorrect++;

      // Reset to box 0
      srWord.box = 0;
      srWord.nextReviewDate = DateTime.now();
    }

    await _saveSpacedRepetition(_keySpacedRepetition, _spacedRepetitionData);
    notifyListeners();
  }

  /// Get all badges
  List<Badge> getAllBadges() {
    return _badges.values.toList();
  }

  /// Check if a badge is unlocked
  bool isBadgeUnlocked(String badgeId) {
    return _badges[badgeId]?.unlocked ?? false;
  }

  /// Get unlocked badges
  List<Badge> getUnlockedBadges() {
    return _badges.values.where((b) => b.unlocked).toList();
  }

  /// Get locked badges
  List<Badge> getLockedBadges() {
    return _badges.values.where((b) => !b.unlocked).toList();
  }

  // ==================== Private Methods ====================

  /// Update daily streak
  Future<void> _updateDailyStreak() async {
    String? lastOpenDateStr = _prefs.getString(_keyLastOpenDate);
    _dailyStreak = _prefs.getInt(_keyDailyStreak) ?? 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastOpenDateStr == null) {
      // First time opening
      _dailyStreak = 1;
    } else {
      DateTime? lastOpenDate;
      try {
        lastOpenDate = DateTime.parse(lastOpenDateStr);
      } catch (_) {
        // Corrupted date string — treat as first time
        _dailyStreak = 1;
        await _prefs.setString(_keyLastOpenDate, today.toIso8601String());
        await _prefs.setInt(_keyDailyStreak, _dailyStreak);
        return;
      }
      DateTime lastOpenDay = DateTime(lastOpenDate.year, lastOpenDate.month, lastOpenDate.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));

      if (lastOpenDay.isAtSameMomentAs(today)) {
        // Opened today already, streak unchanged
      } else if (lastOpenDay.isAtSameMomentAs(yesterday)) {
        // Opened yesterday, streak continues
        _dailyStreak++;

        // Check streak badges
        if (_dailyStreak == 3) {
          await _unlockBadge('streak_star');
        }
        if (_dailyStreak == 7) {
          await _unlockBadge('dedicated_learner');
        }
      } else {
        // Streak broken, start over
        _dailyStreak = 1;
      }
    }

    await _prefs.setInt(_keyDailyStreak, _dailyStreak);
    await _prefs.setString(_keyLastOpenDate, now.toIso8601String());
  }

  /// Initialize badges with all available achievements
  Map<String, Badge> _initializeBadges() {
    final badgesList = [
      Badge(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Complete first lesson',
        emoji: '🎯',
      ),
      Badge(
        id: 'word_collector',
        title: 'Word Collector',
        description: 'Learn 10 words',
        emoji: '📚',
      ),
      Badge(
        id: 'quiz_whiz',
        title: 'Quiz Whiz',
        description: 'Score 100% on any quiz',
        emoji: '🧠',
      ),
      Badge(
        id: 'tone_master',
        title: 'Tone Master',
        description: 'Complete tones lesson',
        emoji: '🎵',
      ),
      Badge(
        id: 'streak_star',
        title: 'Streak Star',
        description: '3-day streak',
        emoji: '⭐',
      ),
      Badge(
        id: 'dedicated_learner',
        title: 'Dedicated Learner',
        description: '7-day streak',
        emoji: '🔥',
      ),
      Badge(
        id: 'alphabet_pro',
        title: 'Alphabet Pro',
        description: 'View all 31 letters',
        emoji: '🔤',
      ),
      Badge(
        id: 'vocabulary_champion',
        title: 'Vocabulary Champion',
        description: 'Learn all 67 words',
        emoji: '👑',
      ),
      Badge(
        id: 'language_explorer',
        title: 'Language Explorer',
        description: 'Try all 3 difficulty levels',
        emoji: '🌍',
      ),
    ];

    Map<String, Badge> badgesMap = {};

    // Load from persistence
    String? badgesJson = _prefs.getString(_keyBadges);
    if (badgesJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(badgesJson);
        for (var badgeJson in decoded) {
          Badge badge = Badge.fromJson(badgeJson);
          badgesMap[badge.id] = badge;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding badges: $e');
        }
      }
    }

    // Fill in any missing badges from template
    for (var badge in badgesList) {
      badgesMap.putIfAbsent(badge.id, () => badge);
    }

    return badgesMap;
  }

  /// Unlock a badge
  Future<void> _unlockBadge(String badgeId) async {
    if (_badges.containsKey(badgeId) && !_badges[badgeId]!.unlocked) {
      _badges[badgeId]!.unlocked = true;
      _badges[badgeId]!.unlockedDate = DateTime.now();

      // Award XP for badge unlock
      await addXP(100);

      await _saveBadges(_keyBadges, _badges);
      notifyListeners();
    }
  }

  /// Check and unlock badges on lesson completion
  Future<void> _checkBadgesOnLessonComplete(String lessonId) async {
    // First Steps badge
    if (_completedLessons.length == 1) {
      await _unlockBadge('first_steps');
    }

    // Tone Master badge
    if (lessonId == 'beginner_tones') {
      await _unlockBadge('tone_master');
    }
  }

  /// Get days until next review for a given box
  int _getDaysForBox(int box) {
    switch (box) {
      case 0:
        return 0; // Same day
      case 1:
        return 1; // 1 day
      case 2:
        return 3; // 3 days
      case 3:
        return 7; // 7 days
      case 4:
        return 14; // 14 days
      default:
        return 0;
    }
  }

  // ==================== Persistence Methods ====================

  /// Load a set of strings from SharedPreferences
  Set<String> _loadStringSet(String key) {
    String? json = _prefs.getString(key);
    if (json == null) return {};

    try {
      List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => e.toString()).toSet();
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding string set $key: $e');
      }
      return {};
    }
  }

  /// Save a set of strings to SharedPreferences
  Future<void> _saveStringSet(String key, Set<String> data) async {
    String json = jsonEncode(data.toList());
    await _prefs.setString(key, json);
  }

  /// Load a map of string->int from SharedPreferences
  Map<String, int> _loadIntMap(String key) {
    String? json = _prefs.getString(key);
    if (json == null) return {};

    try {
      Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((k, v) => MapEntry(k, (v is int) ? v : int.tryParse(v.toString()) ?? 0));
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding int map $key: $e');
      }
      return {};
    }
  }

  /// Save a map of string->int to SharedPreferences
  Future<void> _saveIntMap(String key, Map<String, int> data) async {
    String json = jsonEncode(data);
    await _prefs.setString(key, json);
  }

  /// Load spaced repetition data from SharedPreferences
  Map<String, SpacedRepetitionWord> _loadSpacedRepetition(String key) {
    String? json = _prefs.getString(key);
    if (json == null) return {};

    try {
      Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((k, v) => MapEntry(k, SpacedRepetitionWord.fromJson(v)));
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding spaced repetition data $key: $e');
      }
      return {};
    }
  }

  /// Save spaced repetition data to SharedPreferences
  Future<void> _saveSpacedRepetition(
    String key,
    Map<String, SpacedRepetitionWord> data,
  ) async {
    Map<String, dynamic> toSave = {};
    for (var entry in data.entries) {
      toSave[entry.key] = entry.value.toJson();
    }
    String json = jsonEncode(toSave);
    await _prefs.setString(key, json);
  }

  /// Save badges to SharedPreferences
  Future<void> _saveBadges(String key, Map<String, Badge> badges) async {
    List<Map<String, dynamic>> badgesList = badges.values.map((b) => b.toJson()).toList();
    String json = jsonEncode(badgesList);
    await _prefs.setString(key, json);
  }

  /// Clear all progress data (for testing/debugging)
  Future<void> clearAllProgress() async {
    await _prefs.clear();
    _completedLessons.clear();
    _quizScores.clear();
    _spacedRepetitionData.clear();
    _totalXP = 0;
    _viewedLetters.clear();
    _viewedWords.clear();
    _triedDifficultyLevels.clear();
    _badges = _initializeBadges();
    _dailyStreak = 0;
    notifyListeners();
  }
}
