import 'package:flutter/material.dart';

/// Registration is handled by Google Sign-In.
/// This screen exists only for backward compatibility — redirects to login.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Google Sign-In handles registration — redirect back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
