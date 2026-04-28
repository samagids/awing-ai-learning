import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  /// Whether to show the Sign in with Apple button on this platform.
  ///
  /// REQUIRED on iOS by App Store Review Guideline 4.8 since we also offer
  /// Google Sign-In. Hidden on Android and other platforms where the
  /// `sign_in_with_apple` package falls back to a web-based flow that we
  /// don't support.
  bool get _showAppleSignIn {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Request both name and email scopes — Apple only returns these on the
      // FIRST sign-in for any given Apple ID + app combination, so capturing
      // them now is the only chance to get the user's display name.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Exchange Apple credential for Firebase ID token. Firebase resolves the
      // user's email to either their real address or an @privaterelay.appleid.com
      // forwarder if they chose Hide My Email. Either form is stable per user.
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final firebaseResult = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      final firebaseUser = firebaseResult.user;
      final email = firebaseUser?.email ?? appleCredential.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _error = 'Apple Sign-In did not return an email. Please try again.';
          _isLoading = false;
        });
        return;
      }
      debugPrint('Firebase Auth: signed in via Apple as $email');

      if (!mounted) return;

      // Display name — only present on first sign-in, then null forever after
      // (Apple's design). On second+ sign-ins our existing AuthService account
      // already has the name from before, so this falls through fine.
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      final displayName = [givenName, familyName]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ')
          .trim();

      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();

      final error = auth.loginWithApple(
        email,
        displayName: displayName.isEmpty ? null : displayName,
        cloudBackup: cloud,
      );

      if (error != null) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
      // AuthService notifies listeners -> app rebuilds
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or platform refused (e.g. Apple ID not configured)
      debugPrint('Apple Sign-In authorization error: ${e.code} ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _error = 'Apple Sign-In failed: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      setState(() {
        _error = 'Apple Sign-In failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gsi = CloudBackupService.loginGoogleSignIn;

      // Try silent sign-in first — picks up existing device account
      // without showing the account picker (no "Add account" option).
      GoogleSignInAccount? account = await gsi.signInSilently();

      // Only show the picker if no account was found silently
      account ??= await gsi.signIn();

      if (account == null) {
        // User cancelled sign-in
        setState(() => _isLoading = false);
        return;
      }

      // Sign into Firebase Auth (required for Firestore security rules)
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase Auth: signed in as ${account.email}');

      if (!mounted) return;

      // Register with our local AuthService
      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();

      final error = auth.loginWithGoogle(
        account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        cloudBackup: cloud,
      );

      if (error != null) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
      // AuthService notifies listeners -> app rebuilds
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      setState(() {
        _error = 'Google Sign-In failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo area
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Awing',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF006432),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn the Awing Language',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFFDAA520),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spoken by 19,000 people in Cameroon',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Error message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Google Sign-In button
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.network(
                            'https://developers.google.com/identity/images/g-logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.account_circle, size: 24),
                          ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),
                if (_showAppleSignIn) ...[
                  const SizedBox(height: 12),
                  // Sign in with Apple — required by App Store Review Guideline
                  // 4.8 since Google Sign-In is also offered. Apple HIG also
                  // requires this exact button styling: black background, white
                   // logo + text, "Sign in with Apple" wording.
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                      label: const Text(
                        'Sign in with Apple',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Parent: sign in with your Google account.\nThen create profiles for your kids to use.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
