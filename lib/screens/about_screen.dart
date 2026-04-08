import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen — credits, version, and app information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const String appVersion = '1.2.0';
  static const String buildNumber = '4';
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
                color: isDark ? const Color(0xFF81C784) : _awingGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $appVersion (Build $buildNumber)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
                appDescription,
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
                      : [_awingGreen.withAlpha(20), _awingGold.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : _awingGold.withAlpha(80),
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
                    developerName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _awingGold : _awingDarkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchEmail(),
                    child: Text(
                      developerEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF81C784) : _awingGreen,
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
                      color: isDark ? Colors.grey.shade200 : _awingDarkGreen,
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
                      color: isDark ? Colors.grey.shade200 : _awingDarkGreen,
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
                      : [_awingGold.withAlpha(25), _awingAmber.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : _awingGold.withAlpha(100),
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
                      color: isDark ? _awingGold : _awingDarkGreen,
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
                        backgroundColor: _awingGold,
                        foregroundColor: _awingDarkGreen,
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
              '\u00A9 ${DateTime.now().year} $developerName',
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
    final uri = Uri(scheme: 'mailto', path: developerEmail);
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
                developerEmail,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF81C784) : _awingGreen,
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
