import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimum interval between auto-sync backup calls (prevents API flooding).
const Duration _autoSyncDebounce = Duration(minutes: 2);

/// Keep in sync with AboutScreen.appVersion and AboutScreen.buildNumber.
/// Stamped on every Firestore doc so Developer Mode can see which client
/// last wrote a given user's data.
const String _kAppVersion = '1.11.0+46';

/// Cloud backup service using Firebase Firestore.
///
/// Data is stored per Google account email in Firestore:
///   users/{email}/data/accounts   — user accounts with profiles
///   users/{email}/data/progress   — learning progress, XP, badges, streaks
///   users/{email}/data/settings   — app settings (theme, analytics opt-out)
///
/// Firebase Firestore free tier (Spark plan):
///   - 1 GB storage, 50K reads/day, 20K writes/day
///   - More than enough for a learning app
///   - No billing account required
class CloudBackupService extends ChangeNotifier {
  static const String _keyAutoSync = 'cloud_auto_sync';
  static const String _keyLastBackup = 'cloud_last_backup';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// GoogleSignIn for login only — just 'email' scope, no verification needed.
  static final GoogleSignIn loginGoogleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // State
  bool _isSignedIn = false;
  bool _isSyncing = false;
  String? _lastBackupTime;
  String? _syncError;
  bool _autoSync = true; // On by default — sync progress automatically
  String? _connectedEmail;
  DateTime? _lastAutoSyncTime; // Debounce auto-sync calls

  // Getters
  bool get isSignedIn => _isSignedIn;
  bool get isSyncing => _isSyncing;
  String? get lastBackupTime => _lastBackupTime;
  String? get syncError => _syncError;
  bool get autoSync => _autoSync;
  String? get connectedEmail => _connectedEmail;

  /// Firestore instance
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Get the Firestore document path for a user's data.
  /// Uses email as document ID (sanitized: dots replaced, lowercased).
  String _userDocPath(String email) {
    final sanitized = email.toLowerCase().replaceAll('.', '_dot_');
    return 'users/$sanitized';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _autoSync = _prefs.getBool(_keyAutoSync) ?? true;
    _lastBackupTime = _prefs.getString(_keyLastBackup);

    // Check if already signed in silently
    try {
      final account = await loginGoogleSignIn.signInSilently();
      if (account != null) {
        _isSignedIn = true;
        _connectedEmail = account.email;
        // Also ensure Firebase Auth is signed in
        await _ensureFirebaseAuth(account);
      }
    } catch (e) {
      debugPrint('Cloud backup silent sign-in check failed: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  /// Ensure Firebase Auth is signed in using Google credentials.
  /// Required for Firestore security rules (request.auth != null).
  Future<void> _ensureFirebaseAuth(GoogleSignInAccount account) async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase Auth: signed in as ${account.email}');
    } catch (e) {
      debugPrint('Firebase Auth sign-in failed: $e');
    }
  }

  /// Sign in — called from backup settings if user wants to explicitly connect.
  /// For normal flow, login_screen.dart uses loginGoogleSignIn directly.
  Future<bool> signIn() async {
    try {
      _syncError = null;
      final account = await loginGoogleSignIn.signIn();
      if (account == null) {
        _syncError = 'Sign-in cancelled.';
        notifyListeners();
        return false;
      }

      await _ensureFirebaseAuth(account);
      _isSignedIn = true;
      _connectedEmail = account.email;
      _autoSync = true;
      _prefs.setBool(_keyAutoSync, true);
      _syncError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _syncError = 'Sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await loginGoogleSignIn.signOut();
    } catch (_) {}
    _isSignedIn = false;
    _connectedEmail = null;
    _autoSync = false;
    _prefs.setBool(_keyAutoSync, false);
    notifyListeners();
  }

  void setAutoSync(bool value) {
    _autoSync = value;
    _prefs.setBool(_keyAutoSync, value);
    notifyListeners();
  }

  /// Backup all app data to Firestore.
  Future<bool> backupAll() async {
    if (_isSyncing || _connectedEmail == null) return false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final basePath = _userDocPath(_connectedEmail!);

      // Collect accounts data
      final accountsJson = _prefs.getString('auth_accounts');
      dynamic accountsData = {};
      if (accountsJson != null) {
        try {
          accountsData = jsonDecode(accountsJson);
        } catch (e) {
          debugPrint('Cloud backup: corrupt accounts JSON: $e');
        }
      }

      // Collect progress data
      final progressData = <String, dynamic>{};
      for (final key in [
        'completed_lessons',
        'quiz_scores',
        'daily_streak',
        'last_open_date',
        'words_learned',
        'spaced_repetition',
        'total_xp',
        'badges',
        'viewed_letters',
        'viewed_words',
        'tried_difficulty_levels',
      ]) {
        final value = _prefs.get(key);
        if (value != null) progressData[key] = value;
      }

      // Collect settings
      final settingsData = <String, dynamic>{
        'isDarkMode': _prefs.getBool('isDarkMode') ?? false,
        'cloud_auto_sync': _prefs.getBool(_keyAutoSync) ?? true,
      };

      final now = DateTime.now().toIso8601String();

      // Write all three documents in a batch for atomicity
      final batch = _db.batch();

      // Count profiles for the parent user document
      int pCount = 0;
      if (accountsData is Map) {
        for (final v in (accountsData as Map).values) {
          if (v is Map && v['profiles'] is List) {
            pCount += (v['profiles'] as List).length;
          }
        }
      }

      // Write the parent user document so collection('users').get() finds it
      batch.set(
        _db.doc(basePath),
        {
          'email': _connectedEmail,
          'updated_at': now,
          'app_version': _kAppVersion,
          'profile_count': pCount,
        },
        SetOptions(merge: true),
      );

      batch.set(
        _db.doc('$basePath/data/accounts'),
        {
          'data': accountsData is Map ? accountsData : {},
          'updated_at': now,
          'app_version': _kAppVersion,
        },
        SetOptions(merge: true),
      );

      batch.set(
        _db.doc('$basePath/data/progress'),
        {
          'data': progressData,
          'updated_at': now,
        },
        SetOptions(merge: true),
      );

      batch.set(
        _db.doc('$basePath/data/settings'),
        {
          'data': settingsData,
          'updated_at': now,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _lastBackupTime = now;
      _prefs.setString(_keyLastBackup, now);
      _syncError = null;
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud backup to Firestore: success');
      return true;
    } catch (e, stack) {
      _syncError = 'Backup failed: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud backup error: $e');
      debugPrint('Cloud backup stack: $stack');
      return false;
    }
  }

  /// Restore all app data from Firestore.
  Future<bool> restoreAll() async {
    if (_isSyncing || _connectedEmail == null) return false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final basePath = _userDocPath(_connectedEmail!);

      // Read all three documents
      final accountsDoc = await _db.doc('$basePath/data/accounts').get();
      final progressDoc = await _db.doc('$basePath/data/progress').get();
      final settingsDoc = await _db.doc('$basePath/data/settings').get();

      // If no data found at all, nothing to restore
      if (!accountsDoc.exists && !progressDoc.exists && !settingsDoc.exists) {
        _syncError = 'No backup found for ${_connectedEmail}.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Restore accounts
      if (accountsDoc.exists) {
        final accountsData = accountsDoc.data()?['data'];
        if (accountsData != null) {
          await _prefs.setString('auth_accounts', jsonEncode(accountsData));
        }
      }

      // Restore progress — each key stored individually
      if (progressDoc.exists) {
        final progressData = progressDoc.data()?['data'];
        if (progressData is Map) {
          const intKeys = {'daily_streak', 'total_xp'};
          for (final entry in progressData.entries) {
            try {
              final key = entry.key.toString();
              final value = entry.value;
              if (intKeys.contains(key)) {
                final intVal = int.tryParse(value.toString());
                if (intVal != null) await _prefs.setInt(key, intVal);
              } else if (value is bool) {
                await _prefs.setBool(key, value);
              } else if (value is int) {
                await _prefs.setInt(key, value);
              } else if (value is double) {
                await _prefs.setDouble(key, value);
              } else if (value is String) {
                await _prefs.setString(key, value);
              } else if (value != null) {
                await _prefs.setString(key, jsonEncode(value));
              }
            } catch (e) {
              debugPrint('Cloud restore key "${entry.key}" error: $e');
            }
          }
        }
      }

      // Restore settings
      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data()?['data'];
        if (settingsData is Map) {
          if (settingsData['isDarkMode'] != null) {
            await _prefs.setBool(
              'isDarkMode',
              settingsData['isDarkMode'] == true,
            );
          }
        }
      }

      // Update last backup time from cloud
      final backupTime = accountsDoc.data()?['updated_at'] ??
          progressDoc.data()?['updated_at'];
      if (backupTime is String) {
        _lastBackupTime = backupTime;
        _prefs.setString(_keyLastBackup, backupTime);
      }

      _syncError = null;
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud restore from Firestore: success');
      return true;
    } catch (e, stack) {
      _syncError = 'Restore error: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('Cloud restore error: $e');
      debugPrint('Cloud restore stack: $stack');
      return false;
    }
  }

  /// Get info about the existing backup (if any).
  Future<Map<String, dynamic>?> getBackupInfo() async {
    if (_connectedEmail == null) return null;
    try {
      final basePath = _userDocPath(_connectedEmail!);
      final doc = await _db.doc('$basePath/data/accounts').get();
      return doc.data();
    } catch (e) {
      debugPrint('Cloud getBackupInfo error: $e');
      return null;
    }
  }

  /// Silently attempt to restore from Firestore.
  /// Returns true if restore succeeded.
  Future<bool> tryAutoRestore() async {
    if (_isSyncing) return false;
    try {
      final account = await loginGoogleSignIn.signInSilently();
      if (account == null) {
        debugPrint('Auto-restore: not signed in');
        return false;
      }

      _isSignedIn = true;
      _connectedEmail = account.email;
      await _ensureFirebaseAuth(account);

      debugPrint(
        'Auto-restore: signed in as ${account.email}, checking Firestore...',
      );
      final result = await restoreAll();

      if (result) {
        _autoSync = true;
        _prefs.setBool(_keyAutoSync, true);
        debugPrint('Auto-restore: success, auto-sync enabled');
      }

      return result;
    } catch (e) {
      debugPrint('Auto-restore error: $e');
      return false;
    }
  }

  /// Called when data changes — auto-backup if enabled.
  /// Debounced: skips if last auto-sync was less than 2 minutes ago.
  Future<void> onDataChanged() async {
    if (!_autoSync || !_isSignedIn || _isSyncing) return;

    final now = DateTime.now();
    if (_lastAutoSyncTime != null &&
        now.difference(_lastAutoSyncTime!) < _autoSyncDebounce) {
      return;
    }

    _lastAutoSyncTime = now;
    await backupAll();
  }
}
