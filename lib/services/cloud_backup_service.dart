import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Cloud backup service using Google Drive appDataFolder.
///
/// The appDataFolder is a hidden, app-specific folder in the user's Google Drive.
/// Only this app can read/write to it — the user can't see it in Drive.
/// This allows progress to sync across devices when the same Google account
/// is used to sign in.
///
/// Data stored:
///   - accounts.json — all user accounts with profiles, progress, PINs
///   - settings.json — app settings (theme, analytics opt-out)
///   - backup_meta.json — last backup timestamp
///
/// Free tier — uses only the user's own Drive storage (no billing needed).
class CloudBackupService extends ChangeNotifier {
  static const String _keyAutoSync = 'cloud_auto_sync';
  static const String _keyLastBackup = 'cloud_last_backup';

  // Google Drive API constants
  static const String _driveUploadUrl =
      'https://www.googleapis.com/upload/drive/v3/files';
  static const String _driveFilesUrl =
      'https://www.googleapis.com/drive/v3/files';
  static const String _scope = 'https://www.googleapis.com/auth/drive.appdata';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// GoogleSignIn for login only — just 'email' scope, no verification needed.
  /// Cloud backup uses a separate instance that requests drive.appdata
  /// only when the user explicitly enables backup.
  static final GoogleSignIn loginGoogleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// GoogleSignIn for cloud backup — requests drive.appdata scope.
  /// Only used when user explicitly enables cloud backup from settings.
  final GoogleSignIn _driveGoogleSignIn = GoogleSignIn(
    scopes: ['email', _scope],
  );

  // State
  bool _isSignedIn = false;
  bool _isSyncing = false;
  String? _lastBackupTime;
  String? _syncError;
  bool _autoSync = false; // Off by default — user enables from backup settings
  String? _connectedEmail;

  // Getters
  bool get isSignedIn => _isSignedIn;
  bool get isSyncing => _isSyncing;
  String? get lastBackupTime => _lastBackupTime;
  String? get syncError => _syncError;
  bool get autoSync => _autoSync;
  String? get connectedEmail => _connectedEmail;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _autoSync = _prefs.getBool(_keyAutoSync) ?? false;
    _lastBackupTime = _prefs.getString(_keyLastBackup);

    // Check if already signed in with Drive scope silently
    if (_autoSync) {
      try {
        final account = await _driveGoogleSignIn.signInSilently();
        if (account != null) {
          _isSignedIn = true;
          _connectedEmail = account.email;
        }
      } catch (e) {
        debugPrint('Cloud backup silent sign-in failed: $e');
      }
    }

    _initialized = true;
    notifyListeners();
  }

  /// Sign in to Google Drive for cloud backup.
  /// This prompts for the drive.appdata scope — only called from backup settings.
  Future<bool> signIn() async {
    try {
      _syncError = null;
      final account = await _driveGoogleSignIn.signIn();
      if (account == null) {
        _syncError = 'Sign-in cancelled.';
        notifyListeners();
        return false;
      }

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
      await _driveGoogleSignIn.signOut();
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

  /// Get authenticated HTTP headers for Drive API calls.
  Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      final account = await _driveGoogleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      if (auth.accessToken == null) return null;
      return {'Authorization': 'Bearer ${auth.accessToken}'};
    } catch (e) {
      debugPrint('Cloud auth error: $e');
      return null;
    }
  }

  /// Find a file in appDataFolder by name. Returns file ID or null.
  Future<String?> _findFile(String name, Map<String, String> headers) async {
    final query = Uri.encodeQueryComponent(
      "name='$name' and 'appDataFolder' in parents and trashed=false",
    );
    final url = '$_driveFilesUrl?spaces=appDataFolder&q=$query&fields=files(id)';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List;
      if (files.isNotEmpty) return files[0]['id'];
    }
    return null;
  }

  /// Upload a JSON file to appDataFolder (create or update).
  Future<bool> _uploadFile(
    String name,
    Map<String, dynamic> content,
    Map<String, String> headers,
  ) async {
    final jsonStr = jsonEncode(content);

    // Check if file already exists
    final existingId = await _findFile(name, headers);

    if (existingId != null) {
      // Update existing file
      final url = '$_driveUploadUrl/$existingId?uploadType=media';
      final response = await http.patch(
        Uri.parse(url),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonStr,
      );
      return response.statusCode == 200;
    } else {
      // Create new file in appDataFolder
      // Use multipart upload for metadata + content
      final metadata = jsonEncode({
        'name': name,
        'parents': ['appDataFolder'],
      });

      final boundary = '===backup_boundary===';
      final body = '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n'
          '--$boundary\r\n'
          'Content-Type: application/json\r\n\r\n'
          '$jsonStr\r\n'
          '--$boundary--';

      final response = await http.post(
        Uri.parse('$_driveUploadUrl?uploadType=multipart'),
        headers: {
          ...headers,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      );
      return response.statusCode == 200;
    }
  }

  /// Download a JSON file from appDataFolder by name.
  Future<Map<String, dynamic>?> _downloadFile(
    String name,
    Map<String, String> headers,
  ) async {
    final fileId = await _findFile(name, headers);
    if (fileId == null) return null;

    final url = '$_driveFilesUrl/$fileId?alt=media';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Backup all app data to Google Drive appDataFolder.
  Future<bool> backupAll() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        _syncError = 'Not signed in to Google.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Collect data to backup — must match the actual SharedPreferences keys
      // used by AuthService and ProgressService
      final accountsJson = _prefs.getString('auth_accounts');

      // ProgressService stores data across multiple individual keys
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
        final value = _prefs.getString(key) ?? _prefs.getInt(key)?.toString();
        if (value != null) progressData[key] = value;
      }

      // Settings
      final settingsData = <String, dynamic>{
        'isDarkMode': _prefs.getBool('isDarkMode') ?? false,
        'cloud_auto_sync': _prefs.getBool('cloud_auto_sync') ?? true,
      };

      final backup = {
        'accounts': accountsJson != null ? jsonDecode(accountsJson) : {},
        'progress': progressData,
        'settings': settingsData,
        'backup_time': DateTime.now().toIso8601String(),
        'app_version': '1.2.0',
      };

      final ok = await _uploadFile('awing_backup.json', backup, headers);

      if (ok) {
        final now = DateTime.now().toIso8601String();
        _lastBackupTime = now;
        _prefs.setString(_keyLastBackup, now);
        _syncError = null;
      } else {
        _syncError = 'Backup failed. Please try again.';
      }

      _isSyncing = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _syncError = 'Backup error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore all app data from Google Drive appDataFolder.
  Future<bool> restoreAll() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        _syncError = 'Not signed in to Google.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final backup = await _downloadFile('awing_backup.json', headers);
      if (backup == null) {
        _syncError = 'No backup found in your Google Drive.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Restore data — write back to the same individual SharedPreferences keys
      if (backup['accounts'] != null) {
        await _prefs.setString('auth_accounts', jsonEncode(backup['accounts']));
      }

      // Restore progress — each key stored individually
      if (backup['progress'] != null && backup['progress'] is Map) {
        final progress = backup['progress'] as Map<String, dynamic>;
        // Int keys need setInt, string keys need setString
        const intKeys = {'daily_streak', 'total_xp'};
        for (final entry in progress.entries) {
          if (intKeys.contains(entry.key)) {
            final intVal = int.tryParse(entry.value.toString());
            if (intVal != null) await _prefs.setInt(entry.key, intVal);
          } else if (entry.value is String) {
            await _prefs.setString(entry.key, entry.value);
          }
        }
      }

      // Restore settings
      if (backup['settings'] != null && backup['settings'] is Map) {
        final settings = backup['settings'] as Map<String, dynamic>;
        if (settings['isDarkMode'] != null) {
          await _prefs.setBool('isDarkMode', settings['isDarkMode'] == true);
        }
      }

      _lastBackupTime = backup['backup_time'];
      if (_lastBackupTime != null) {
        _prefs.setString(_keyLastBackup, _lastBackupTime!);
      }

      _syncError = null;
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _syncError = 'Restore error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Get info about the existing backup (if any).
  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;
      return await _downloadFile('awing_backup.json', headers);
    } catch (_) {
      return null;
    }
  }

  /// Called when data changes — auto-backup if enabled.
  Future<void> onDataChanged() async {
    if (_autoSync && _isSignedIn) {
      await backupAll();
    }
  }
}
