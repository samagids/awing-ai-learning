import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// ThemeNotifier manages light/dark mode theme switching with persistence
class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Initialize theme from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggle() => toggleTheme();

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
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
  bool _pinVerified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_wired) {
      // Wire auth data changes → cloud backup auto-sync
      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();
      auth.onDataChanged = () => cloud.onDataChanged();
      _wired = true;
    }
  }

  /// Show account PIN dialog. Returns true if verified.
  /// [allowCancel] — if true, shows a Cancel button that dismisses without signing out.
  Future<bool> _verifyAccountPin(AuthService auth, {bool allowCancel = true}) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: allowCancel,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Color(0xFF006432)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Enter PIN', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your account PIN to continue.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 28, letterSpacing: 12),
              decoration: InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pin),
              ),
              onSubmitted: (value) {
                if (auth.verifyAccountPin(value)) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (auth.verifyAccountPin(controller.text)) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Not logged in → show login screen (and reset PIN gate)
        if (!auth.hasAccount) {
          _pinVerified = false;
          return const LoginScreen();
        }

        // Account restored but has PIN and not yet verified → show PIN gate
        // This only blocks on first app launch; user can dismiss and stay locked
        if (auth.hasAccountPin && !_pinVerified) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Account Locked',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF006432),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your PIN to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 200,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await _verifyAccountPin(auth);
                            if (ok && mounted) {
                              setState(() => _pinVerified = true);
                            }
                          },
                          icon: const Icon(Icons.lock_open),
                          label: const Text(
                            'Unlock',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006432),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => auth.logout(),
                        child: Text(
                          'Sign out instead',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Logged in but no profile selected → show profile picker
        if (!auth.hasProfile) {
          return const ProfileSelectScreen();
        }
        // Fully authenticated → show home
        return const HomeScreen();
      },
    );
  }
}
