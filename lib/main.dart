import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awing_ai_learning/modules/beginner/beginner_module.dart';
import 'package:awing_ai_learning/screens/home_screen.dart';
import 'package:awing_ai_learning/screens/auth/login_screen.dart';
import 'package:awing_ai_learning/screens/auth/profile_select_screen.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for Firestore cloud sync)
  await Firebase.initializeApp();

  // Set global audio context so all audio plays on the MUSIC stream.
  // This ensures device volume buttons control app audio volume.
  final AudioContext audioContext = AudioContext(
    android: AudioContextAndroid(
      audioMode: AndroidAudioMode.normal,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );
  AudioPlayer.global.setAudioContext(audioContext);

  await AnalyticsService.instance.initialize();
  runApp(const AwingApp());
}

/// ThemeNotifier manages light/dark mode theme switching with persistence.
///
/// NOTE: Dark mode is temporarily disabled in v1.2.1 because many screens
/// have hardcoded colors that become invisible on dark backgrounds. The
/// toggle is a no-op until we complete a full dark-mode color audit. The
/// getter always returns `false` so the UI shows the light-mode icon.
class ThemeNotifier extends ChangeNotifier {
  // ignore: unused_field
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => false;

  /// Initialize — no-op while dark mode is disabled.
  Future<void> initialize() async {}

  /// Toggle — no-op while dark mode is disabled.
  Future<void> toggle() => toggleTheme();

  Future<void> toggleTheme() async {
    // Dark mode is disabled until full color audit is complete.
    notifyListeners();
  }

  /// Get light theme
  // Awing brand colors — inspired by Cameroon Grassfields & Toghu cloth
  static const Color awingGreen = Color(0xFF006432);       // Deep forest green (Mezam highlands)
  static const Color awingGold = Color(0xFFDAA520);         // Gold (Toghu cloth / royalty)
  static const Color awingAmber = Color(0xFFF5AF19);        // Warm amber (Cameroon sun)
  static const Color awingDarkGreen = Color(0xFF004623);    // Darker green for depth
  static const Color awingCream = Color(0xFFFFF8E6);        // Warm cream

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.green,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: awingCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: awingGreen,
        brightness: Brightness.light,
        primary: awingGreen,
        secondary: awingGold,
        tertiary: awingAmber,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: awingDarkGreen,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.black87),
        bodyMedium: const TextStyle(color: Colors.black87),
        bodySmall: const TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: awingDarkGreen),
        titleMedium: TextStyle(color: awingDarkGreen),
        titleSmall: const TextStyle(color: Colors.black87),
      ),
      iconTheme: IconThemeData(color: awingDarkGreen),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: awingGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Get dark theme — used by MaterialApp
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.green,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: awingGreen,
        brightness: Brightness.dark,
        primary: const Color(0xFF4CAF50),
        secondary: awingGold,
        tertiary: awingAmber,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E2E1E),
        foregroundColor: Colors.grey.shade100,
      ),
      cardColor: const Color(0xFF252525),
      dividerColor: Colors.grey.shade700,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.grey.shade100),
        bodyMedium: TextStyle(color: Colors.grey.shade100),
        bodySmall: TextStyle(color: Colors.grey.shade200),
        titleLarge: const TextStyle(color: Color(0xFF81C784)),
        titleMedium: const TextStyle(color: Color(0xFF81C784)),
        titleSmall: TextStyle(color: Colors.grey.shade200),
      ),
      iconTheme: IconThemeData(color: Colors.grey.shade100),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class AwingApp extends StatelessWidget {
  const AwingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()..initialize()),
        ChangeNotifierProvider(create: (_) => BeginnerModule()),
        ChangeNotifierProvider(
          create: (_) => ProgressService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ContributionService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CloudBackupService()..initialize(),
        ),
        ProxyProvider2<AuthService, ProgressService, ParentNotificationService>(
          update: (_, auth, progress, previous) {
            if (previous != null) return previous;
            final service = ParentNotificationService(
              auth: auth,
              progress: progress,
            )..initialize();
            // Try to send weekly summary on app launch
            service.sendWeeklySummaryIfDue();
            return service;
          },
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: 'Awing AI Learning',
            debugShowCheckedModeBanner: false,
            theme: ThemeNotifier.lightTheme(),
            darkTheme: ThemeNotifier.darkTheme(),
            themeMode:
                themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Authentication gate — routes the user to the appropriate screen based on
/// their auth state: LoginScreen → ProfileSelectScreen → HomeScreen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _wired = false;
  bool _autoRestoreAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_wired) {
      // Wire auth data changes → cloud backup auto-sync
      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();
      auth.onDataChanged = () => cloud.onDataChanged();

      // When cloud restore completes (from login or app launch),
      // refresh ProgressService so XP/streaks/badges are up to date.
      auth.onCloudRestoreComplete = () {
        if (mounted) {
          context.read<ProgressService>().refreshFromPrefs();
          debugPrint('ProgressService refreshed after cloud restore');
        }
      };
      _wired = true;

      // Auto-restore on app launch for returning users who have cloud backup
      _tryAutoRestoreOnLaunch(auth, cloud);
    }
  }

  /// On app launch, if the user is already logged in and has cloud backup
  /// enabled, silently check if cloud has data and restore it. This covers
  /// the case where the user synced from another device.
  Future<void> _tryAutoRestoreOnLaunch(
    AuthService auth,
    CloudBackupService cloud,
  ) async {
    if (_autoRestoreAttempted) return;
    _autoRestoreAttempted = true;

    // Only auto-restore if user already has an account locally AND cloud sync is on
    if (!auth.hasAccount || !cloud.autoSync) return;

    try {
      debugPrint('App launch auto-restore: checking cloud for updates...');
      final ok = await cloud.tryAutoRestore();
      if (ok && mounted) {
        // Reload auth + progress from restored SharedPreferences
        auth.refreshFromPrefs();
        try {
          context.read<ProgressService>().refreshFromPrefs();
        } catch (_) {}
        debugPrint('App launch auto-restore: success, auth + progress refreshed');
      }
    } catch (e) {
      debugPrint('App launch auto-restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Not logged in → show login screen
        if (!auth.hasAccount) {
          return const LoginScreen();
        }

        // Logged in but no profile selected → show profile picker
        // PIN protection is on the profile select screen itself (for switching)
        // and on sensitive actions (sign out, parent settings) — NOT here.
        // This lets kids open the app and go straight to learning.
        if (!auth.hasProfile) {
          return const ProfileSelectScreen();
        }

        // Fully authenticated → show home (PopScope prevents accidental back-exit)
        return const PopScope(
          canPop: false,
          child: HomeScreen(),
        );
      },
    );
  }
}
