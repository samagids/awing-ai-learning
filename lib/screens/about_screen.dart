import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:awing_ai_learning/services/auth_service.dart';

/// About screen — credits, version, app information, and hidden developer mode entry.
class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const String appVersion = '1.11.0';
  static const String buildNumber = '44';
  static const String developerName = 'Dr. Guidion Sama, DIT';
  static const String developerEmail = 'samagids@gmail.com';
  static const String appDescription =
      'Awing AI Learning is an interactive mobile application designed to '
      'teach the Awing language — a Grassfields Bantu language spoken by '
      'about 19,000 people in the Mezam division, North West Province, '
      'Republic of Cameroon. The app targets kids and beginners with '
      'AI-powered lessons across three proficiency levels.';

  static const Color _awingGreen = Color(0xFF006432);
  static const Color _awingGold = Color(0xFFDAA520);
  static const Color _awingAmber = Color(0xFFF5AF19);
  static const Color _awingDarkGreen = Color(0xFF004623);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Developer mode entry state
  int _versionTapCount = 0;
  int _devCodeFailedAttempts = 0;
  DateTime? _devCodeLockoutUntil;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // App icon
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            // App name
            Text(
              'Awing AI Learning',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
              ),
            ),
            const SizedBox(height: 4),
            // Version text — 5 taps to enter developer mode
            GestureDetector(
              onTap: () {
                final auth = context.read<AuthService>();
                _versionTapCount++;
                if (_versionTapCount >= 5 && !auth.isDeveloper) {
                  _versionTapCount = 0;
                  _showDevModeDialog(context, auth);
                } else if (_versionTapCount >= 5 && auth.isDeveloper) {
                  _versionTapCount = 0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Developer mode is already active')),
                  );
                } else if (_versionTapCount >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${5 - _versionTapCount} more taps...'),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              child: Text(
                'Version ${AboutScreen.appVersion} (Build ${AboutScreen.buildNumber})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Text(
                AboutScreen.appDescription,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Developer section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E2E1E), const Color(0xFF252525)]
                      : [AboutScreen._awingGreen.withAlpha(20), AboutScreen._awingGold.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : AboutScreen._awingGold.withAlpha(80),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AboutScreen.developerName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchEmail(),
                    child: Text(
                      AboutScreen.developerEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Linguistic credits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linguistic References',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreditRow(
                    title: 'Awing Orthography Guide (2005)',
                    author: 'Alomofor Christian & Stephen C. Anderson',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _CreditRow(
                    title: 'Awing English Dictionary (2007)',
                    author: 'Alomofor Christian, CABTAL',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _CreditRow(
                    title: 'A Phonological Sketch of Awing (2009)',
                    author: 'Bianca van den Berg, SIL Cameroon',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Technology section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Built With',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TechRow(icon: Icons.phone_android, label: 'Flutter & Dart', isDark: isDark),
                  _TechRow(icon: Icons.smart_toy, label: 'TensorFlow Lite (On-device AI)', isDark: isDark),
                  _TechRow(icon: Icons.record_voice_over, label: 'Edge TTS (Bantu Neural Voices)', isDark: isDark),
                  _TechRow(icon: Icons.mic, label: 'Speech-to-Text Recognition', isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support / Donation section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E2E1E), const Color(0xFF252525)]
                      : [AboutScreen._awingGold.withAlpha(25), AboutScreen._awingAmber.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : AboutScreen._awingGold.withAlpha(100),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFDAA520), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Support This Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help preserve the Awing language for future generations. '
                    'Your donation supports app development, linguistic research, '
                    'and native speaker recordings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDonationInfo(context),
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text(
                        'Donate via Zelle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AboutScreen._awingGold,
                        foregroundColor: AboutScreen._awingDarkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Copyright
            Text(
              '\u00A9 ${DateTime.now().year} ${AboutScreen.developerName}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: AboutScreen.developerEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDonationInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFFDAA520)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Donate via Zelle', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send your donation via Zelle to:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E2E1E) : const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDAA520).withAlpha(100),
                ),
              ),
              child: SelectableText(
                AboutScreen.developerEmail,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Open your banking app, select Zelle, and send to the email above. '
              'Every contribution helps keep the Awing language alive!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Developer Mode Entry ──────────────────────────────────────────────

  /// Load the analytics webhook URL from bundled config.
  Future<String?> _getAnalyticsWebhookUrl() async {
    try {
      final jsonStr = await rootBundle.loadString('config/webhooks.json');
      final config = jsonDecode(jsonStr) as Map<String, dynamic>;
      return config['analytics_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Send a 6-digit verification code to the developer's Gmail via webhook.
  Future<bool> _sendDevVerificationEmail(String code) async {
    final webhookUrl = await _getAnalyticsWebhookUrl();
    if (webhookUrl == null) return false;

    final payload = jsonEncode({
      'action': 'send_dev_code',
      'code': code,
      'email': 'samagids@gmail.com',
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Step 1: POST the payload — Apps Script processes it and returns 302
      final postRequest = await client.postUrl(Uri.parse(webhookUrl));
      postRequest.followRedirects = false;
      postRequest.headers.contentType = ContentType.json;
      postRequest.write(payload);
      final postResponse = await postRequest.close();

      debugPrint('Webhook POST: ${postResponse.statusCode}');

      // Step 2: Follow 302 redirect with GET to read the response
      if (postResponse.statusCode == 302 || postResponse.statusCode == 301) {
        await postResponse.drain<void>();
        final location = postResponse.headers.value('location');
        if (location == null) {
          client.close();
          debugPrint('Webhook error: redirect with no location header');
          return false;
        }
        debugPrint('Webhook redirect to: ${location.substring(0, 80)}...');

        // Follow redirect chain with GET
        var getUri = Uri.parse(location);
        for (int i = 0; i < 5; i++) {
          final getRequest = await client.getUrl(getUri);
          getRequest.followRedirects = false;
          final getResponse = await getRequest.close();

          if (getResponse.statusCode == 302 || getResponse.statusCode == 301) {
            await getResponse.drain<void>();
            final nextLocation = getResponse.headers.value('location');
            if (nextLocation == null) break;
            getUri = Uri.parse(nextLocation);
            continue;
          }

          final body = await getResponse.transform(utf8.decoder).join();
          client.close();
          debugPrint('Webhook response: ${getResponse.statusCode} $body');
          final result = jsonDecode(body);
          return result is Map && result['status'] == 'ok';
        }
      } else {
        // No redirect — read directly
        final body = await postResponse.transform(utf8.decoder).join();
        client.close();
        debugPrint('Webhook response (no redirect): ${postResponse.statusCode} $body');
        final result = jsonDecode(body);
        return result is Map && result['status'] == 'ok';
      }

      client.close();
      debugPrint('Webhook error: could not get response after redirects');
      return false;
    } catch (e) {
      debugPrint('Webhook error: $e');
      return false;
    }
  }

  void _showDevModeDialog(BuildContext context, AuthService auth) {
    // Step 1: Must be signed in with the developer Gmail
    if (!auth.isDeveloperEmail) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.red),
              SizedBox(width: 8),
              Text('Access Denied'),
            ],
          ),
          content: const Text(
            'Developer Mode is only available for the designated developer account. '
            'Sign in with the developer Google account to access this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Rate limit: lock out for 5 minutes after 3 failed attempts
    if (_devCodeLockoutUntil != null &&
        DateTime.now().isBefore(_devCodeLockoutUntil!)) {
      final remaining = _devCodeLockoutUntil!.difference(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many failed attempts. Try again in ${remaining.inMinutes + 1} minutes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 2: Enter access code
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: Colors.grey),
            SizedBox(width: 8),
            Text('Developer Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 1 of 2: Enter the developer access code.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text == 'awing2026') {
                _devCodeFailedAttempts = 0;
                _devCodeLockoutUntil = null;
                Navigator.pop(ctx);
                _startDevMode2FA(context, auth);
              } else {
                _devCodeFailedAttempts++;
                Navigator.pop(ctx);
                if (_devCodeFailedAttempts >= 3) {
                  _devCodeLockoutUntil =
                      DateTime.now().add(const Duration(minutes: 5));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Too many failed attempts. Locked for 5 minutes.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid access code (${3 - _devCodeFailedAttempts} attempts remaining)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  /// Step 3: Send verification code to developer Gmail and show input dialog.
  void _startDevMode2FA(BuildContext context, AuthService auth) async {
    // Generate and store code
    final code = auth.generateDevVerificationCode();

    // Show loading dialog while sending email
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Sending verification code to your Gmail...')),
          ],
        ),
      ),
    );

    // Send code via webhook — must succeed for security
    final sent = await _sendDevVerificationEmail(code);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send verification email. Check internet connection and webhook deployment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show code entry dialog
    final verifyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Email Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 2 of 2: A 6-digit code was sent to your Gmail. '
              'Enter it below to activate Developer Mode.',
            ),
            const SizedBox(height: 8),
            Text(
              'Code expires in 10 minutes.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verifyController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final error = auth.verifyDevCode(verifyController.text);
              Navigator.pop(ctx);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer mode activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String title;
  final String author;
  final bool isDark;

  const _CreditRow({
    required this.title,
    required this.author,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade200 : Colors.black87,
            ),
          ),
          Text(
            author,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _TechRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF006432),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
