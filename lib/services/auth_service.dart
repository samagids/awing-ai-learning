import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';

/// Authentication and user management service.
///
/// Enforces Google Sign-In only. Stores accounts locally via SharedPreferences.
/// Each Google email can hold multiple user profiles (e.g. siblings sharing
/// one device — parent signs in, creates child profiles).
class AuthService extends ChangeNotifier {
  static const String _keyAccounts = 'auth_accounts';
  static const String _keyCurrentEmail = 'auth_current_email';
  static const String _keyCurrentProfileId = 'auth_current_profile_id';
  static const String _developerEmail = 'samagids@gmail.com';
  static const String _keyDevMode = 'auth_dev_mode_enabled';
  static const String _keyDevCode = 'auth_dev_pending_code';
  static const String _keyDevCodeExpiry = 'auth_dev_code_expiry';

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _devModeManuallyEnabled = false;

  /// Auto-disable developer mode after 5 minutes of inactivity.
  static const Duration _devModeTimeout = Duration(minutes: 5);
  Timer? _devModeTimer;

  Map<String, UserAccount> _accounts = {}; // email → account
  UserAccount? _currentAccount;
  UserProfile? _currentProfile;

  /// Optional callback invoked whenever user data changes (lessons, quizzes, etc.).
  void Function()? onDataChanged;

  // ==================== Getters ====================

  bool get isLoggedIn => _currentAccount != null && _currentProfile != null;
  bool get hasAccount => _currentAccount != null;
  bool get hasProfile => _currentProfile != null;
  UserAccount? get currentAccount => _currentAccount;
  UserProfile? get currentProfile => _currentProfile;

  /// Developer mode requires:
  /// 1. Signed in with developer Gmail (samagids@gmail.com)
  /// 2. 2FA verified via email code
  bool get isDeveloper =>
      _devModeManuallyEnabled &&
      (_currentAccount?.email.toLowerCase() == _developerEmail);
  String get currentEmail => _currentAccount?.email ?? '';
  List<UserProfile> get profiles => _currentAccount?.profiles ?? [];

  /// Check if current account is the developer email (for 2FA eligibility).
  bool get isDeveloperEmail =>
      _currentAccount?.email.toLowerCase() == _developerEmail;

  /// Initialize the service — must be called before anything else.
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadAccounts();
    _restoreSession();
    _devModeManuallyEnabled = _prefs.getBool(_keyDevMode) ?? false;
    if (_devModeManuallyEnabled) {
      _resetDevModeTimer(); // start countdown even if persisted from last session
    }
    _initialized = true;
    notifyListeners();
  }

  // ==================== Google Sign-In ====================

  /// Login with Google account. Creates account if new.
  /// [displayName] and [photoUrl] are optional metadata from Google.
  /// Set [cloudBackup] to attempt restoring from Google Drive if
  /// the account has no local data (e.g. after reinstall).
  String? loginWithGoogle(
    String googleEmail, {
    String? displayName,
    String? photoUrl,
    CloudBackupService? cloudBackup,
  }) {
    final e = googleEmail.trim().toLowerCase();
    if (e.isEmpty) return 'Google sign-in failed';

    if (!_accounts.containsKey(e)) {
      // Create new account for this Google email
      _accounts[e] = UserAccount(
        email: e,
        authMethod: 'google',
        parentName: displayName,
      );
      _saveAccounts();

      // Try to restore from cloud backup (runs async, updates UI when done)
      if (cloudBackup != null) {
        _tryCloudRestore(e, cloudBackup);
      }
    } else if (displayName != null) {
      // Update display name if provided
      final account = _accounts[e]!;
      if (account.parentName == null || account.parentName!.isEmpty) {
        account.parentName = displayName;
        _saveAccounts();
      }
    }

    final account = _accounts[e]!;
    _currentAccount = account;
    _prefs.setString(_keyCurrentEmail, e);

    if (account.profiles.length == 1) {
      selectProfile(account.profiles.first.id);
    } else {
      _currentProfile = null;
      _prefs.remove(_keyCurrentProfileId);
    }

    notifyListeners();
    return null;
  }

  /// Attempt to restore data from Google Drive after a fresh install.
  Future<void> _tryCloudRestore(String email, CloudBackupService cloud) async {
    try {
      debugPrint('Attempting cloud restore for $email...');
      final ok = await cloud.restoreAll();
      if (ok) {
        // Reload accounts from SharedPreferences (restoreAll wrote them)
        _loadAccounts();
        if (_accounts.containsKey(email)) {
          _currentAccount = _accounts[email];
          final account = _currentAccount!;
          if (account.profiles.length == 1) {
            selectProfile(account.profiles.first.id);
          }
          debugPrint('Cloud restore succeeded: ${account.profiles.length} profiles');
        }
        notifyListeners();
      } else {
        debugPrint('No cloud backup found or restore failed');
      }
    } catch (e) {
      debugPrint('Cloud restore error: $e');
    }
  }

  // ==================== Profile Management ====================

  /// Create a new user profile under the current account.
  String? createProfile(String displayName, String avatarEmoji) {
    if (_currentAccount == null) return 'Not logged in';
    if (displayName.trim().isEmpty) return 'Name is required';

    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: displayName.trim(),
      avatarEmoji: avatarEmoji,
    );

    _currentAccount!.profiles.add(profile);
    _saveAccounts();

    // Auto-select the new profile
    selectProfile(profile.id);
    return null;
  }

  /// Select an existing profile by ID.
  void selectProfile(String profileId) {
    if (_currentAccount == null) return;
    try {
      _currentProfile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      _currentProfile!.lastActiveAt = DateTime.now();
      _prefs.setString(_keyCurrentProfileId, profileId);
      _saveAccounts();
      notifyListeners();
    } catch (_) {
      // Profile not found
    }
  }

  /// Delete a profile by ID.
  void deleteProfile(String profileId) {
    if (_currentAccount == null) return;
    _currentAccount!.profiles.removeWhere((p) => p.id == profileId);
    if (_currentProfile?.id == profileId) {
      _currentProfile = null;
      _prefs.remove(_keyCurrentProfileId);
    }
    _saveAccounts();
    notifyListeners();
  }

  // ==================== Level Progression ====================

  /// Mark a lesson as completed for the current profile.
  void completeLesson(String lessonId) {
    if (_currentProfile == null) return;
    _currentProfile!.lessonsCompleted[lessonId] = true;
    _checkLevelUnlocks();
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
  }

  /// Save a quiz score for the current profile.
  void saveQuizScore(String quizId, int score) {
    if (_currentProfile == null) return;
    final current = _currentProfile!.quizBestScores[quizId] ?? 0;
    if (score > current) {
      _currentProfile!.quizBestScores[quizId] = score;
      _checkLevelUnlocks();
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    }
  }

  /// Check and unlock levels based on completion.
  void _checkLevelUnlocks() {
    if (_currentProfile == null) return;
    final p = _currentProfile!;

    if (!p.mediumUnlocked && p.canUnlockMedium) {
      p.mediumUnlocked = true;
    }
    if (!p.expertUnlocked && p.canUnlockExpert) {
      p.expertUnlocked = true;
    }
  }

  /// Is a given level unlocked for the current profile?
  /// Developer has ALL levels unlocked.
  bool isLevelUnlocked(String level) {
    // Developer always has full access
    if (isDeveloper) return true;

    if (_currentProfile == null) return false;
    switch (level.toLowerCase()) {
      case 'beginner':
        return true; // always unlocked
      case 'medium':
        return _currentProfile!.mediumUnlocked;
      case 'expert':
        return _currentProfile!.expertUnlocked;
      default:
        return false;
    }
  }

  // ==================== PIN Management ====================

  /// Set or update the account-level PIN (protects sign out, delete profile).
  void setAccountPin(String pin) {
    if (_currentAccount == null) return;
    _currentAccount!.accountPin = pin.length == 4 ? pin : null;
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
  }

  /// Remove the account-level PIN.
  void removeAccountPin() {
    if (_currentAccount == null) return;
    _currentAccount!.accountPin = null;
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
  }

  /// Whether the current account has a PIN set.
  bool get hasAccountPin => _currentAccount?.hasAccountPin ?? false;

  /// Verify the account PIN. Returns true if correct or no PIN set.
  bool verifyAccountPin(String pin) {
    if (_currentAccount == null) return false;
    return _currentAccount!.verifyAccountPin(pin);
  }

  /// Set or update a profile-level PIN.
  void setProfilePin(String profileId, String pin) {
    if (_currentAccount == null) return;
    try {
      final profile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      profile.pin = pin.length == 4 ? pin : null;
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    } catch (_) {}
  }

  /// Remove a profile-level PIN.
  void removeProfilePin(String profileId) {
    if (_currentAccount == null) return;
    try {
      final profile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      profile.pin = null;
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    } catch (_) {}
  }

  // ==================== Session / Logout ====================

  /// Logout — clears current session. Caller must verify account PIN first.
  Future<void> logout() async {
    _currentAccount = null;
    _currentProfile = null;
    _prefs.remove(_keyCurrentEmail);
    _prefs.remove(_keyCurrentProfileId);
    // Sign out of Google so the login screen shows the account picker next time
    try {
      await CloudBackupService.loginGoogleSignIn.signOut();
    } catch (_) {}
    notifyListeners();
  }

  void switchProfile() {
    _currentProfile = null;
    _prefs.remove(_keyCurrentProfileId);
    notifyListeners();
  }

  // ==================== Parent Settings ====================

  /// Update the parent WhatsApp number for the current account.
  void updateWhatsAppNumber(String? number) {
    if (_currentAccount == null) return;
    _currentAccount!.whatsappNumber = _normalizePhone(number);
    _saveAccounts();
    notifyListeners();
  }

  /// Update the parent name for the current account.
  void updateParentName(String? name) {
    if (_currentAccount == null) return;
    _currentAccount!.parentName = name?.trim().isNotEmpty == true ? name!.trim() : null;
    _saveAccounts();
    notifyListeners();
  }

  /// Toggle quiz notification preference.
  void setQuizNotifications(bool enabled) {
    if (_currentAccount == null) return;
    _currentAccount!.sendQuizNotifications = enabled;
    _saveAccounts();
    notifyListeners();
  }

  /// Toggle weekly summary preference.
  void setWeeklySummary(bool enabled) {
    if (_currentAccount == null) return;
    _currentAccount!.sendWeeklySummary = enabled;
    _saveAccounts();
    notifyListeners();
  }

  /// Normalize a phone number — strip spaces and dashes, keep + prefix.
  String? _normalizePhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // ==================== Developer Mode (2FA) ====================

  /// Generate a 6-digit verification code for developer mode activation.
  /// Returns the code (to be sent via webhook email).
  String generateDevVerificationCode() {
    final code = (100000 + Random().nextInt(900000)).toString();
    // Store code + 10-minute expiry
    _prefs.setString(_keyDevCode, code);
    _prefs.setInt(
      _keyDevCodeExpiry,
      DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
    return code;
  }

  /// Verify the 6-digit code and enable developer mode if correct.
  /// Returns null on success, error string on failure.
  String? verifyDevCode(String inputCode) {
    final storedCode = _prefs.getString(_keyDevCode);
    final expiryMs = _prefs.getInt(_keyDevCodeExpiry) ?? 0;

    if (storedCode == null) return 'No verification code pending';

    if (DateTime.now().millisecondsSinceEpoch > expiryMs) {
      _prefs.remove(_keyDevCode);
      _prefs.remove(_keyDevCodeExpiry);
      return 'Verification code expired. Try again.';
    }

    if (inputCode.trim() != storedCode) {
      return 'Incorrect verification code';
    }

    // Success — enable dev mode
    _devModeManuallyEnabled = true;
    _prefs.setBool(_keyDevMode, true);
    _prefs.remove(_keyDevCode);
    _prefs.remove(_keyDevCodeExpiry);
    notifyListeners();
    return null;
  }

  /// Disable developer mode and cancel the inactivity timer.
  void disableDevMode() {
    _devModeTimer?.cancel();
    _devModeTimer = null;
    _devModeManuallyEnabled = false;
    _prefs.setBool(_keyDevMode, false);
    debugPrint('Developer mode deactivated');
    notifyListeners();
  }

  /// Enable developer mode directly (used after 2FA verification).
  /// Starts the 5-minute inactivity auto-disable timer.
  void enableDevMode() {
    _devModeManuallyEnabled = true;
    _prefs.setBool(_keyDevMode, true);
    _resetDevModeTimer();
    debugPrint('Developer mode activated (auto-disables after 5 min inactivity)');
    notifyListeners();
  }

  /// Reset the developer mode inactivity timer.
  /// Call this whenever the developer interacts with a developer-only feature.
  void resetDevModeActivity() {
    if (_devModeManuallyEnabled) {
      _resetDevModeTimer();
    }
  }

  void _resetDevModeTimer() {
    _devModeTimer?.cancel();
    _devModeTimer = Timer(_devModeTimeout, () {
      debugPrint('Developer mode auto-disabled after 5 min inactivity');
      disableDevMode();
    });
  }

  /// Get all accounts (developer only).
  List<UserAccount> getAllAccounts() {
    if (!isDeveloper) return [];
    return _accounts.values.toList();
  }

  /// Get total user count across all accounts.
  int get totalProfileCount =>
      _accounts.values.fold(0, (sum, a) => sum + a.profiles.length);

  /// Unlock a level manually (developer only).
  void devUnlockLevel(String profileId, String level) {
    if (!isDeveloper) return;
    for (final account in _accounts.values) {
      for (final profile in account.profiles) {
        if (profile.id == profileId) {
          switch (level) {
            case 'medium':
              profile.mediumUnlocked = true;
              break;
            case 'expert':
              profile.expertUnlocked = true;
              break;
          }
          _saveAccounts();
          notifyListeners();
          return;
        }
      }
    }
  }

  // ==================== Persistence ====================

  void _loadAccounts() {
    final json = _prefs.getString(_keyAccounts);
    if (json == null) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      _accounts = decoded.map(
        (k, v) => MapEntry(k, UserAccount.fromJson(v)),
      );
    } catch (e) {
      if (kDebugMode) print('Error loading accounts: $e');
    }
  }

  void _saveAccounts() {
    final map = _accounts.map((k, v) => MapEntry(k, v.toJson()));
    _prefs.setString(_keyAccounts, jsonEncode(map));
  }

  void _restoreSession() {
    final email = _prefs.getString(_keyCurrentEmail);
    if (email == null) return;

    _currentAccount = _accounts[email];
    if (_currentAccount == null) return;

    final profileId = _prefs.getString(_keyCurrentProfileId);
    if (profileId != null) {
      try {
        _currentProfile = _currentAccount!.profiles.firstWhere(
          (p) => p.id == profileId,
        );
      } catch (_) {
        // Profile deleted
      }
    }
  }
}
