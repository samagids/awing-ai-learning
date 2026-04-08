import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Parental gate that protects destructive actions from kids.
///
/// Two modes:
/// 1. If the account has a PIN set → asks for 4-digit PIN
/// 2. If no PIN set → asks a simple math problem (e.g. "What is 7 + 5?")
///
/// Use [ParentalGate.verify] to show the gate and get a bool result.
class ParentalGate {
  /// Show a parental gate dialog. Returns true if the parent/adult passes.
  static Future<bool> verify(
    BuildContext context, {
    String title = 'Parent Verification',
    String message = 'This action requires a parent or guardian.',
  }) async {
    final auth = context.read<AuthService>();

    if (auth.hasAccountPin) {
      return await _showPinGate(context, auth, title: title, message: message);
    } else {
      return await _showMathGate(context, title: title, message: message);
    }
  }

  /// PIN-based gate — asks for the 4-digit account PIN.
  static Future<bool> _showPinGate(
    BuildContext context,
    AuthService auth, {
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: const Color(0xFF006432)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 12),
              decoration: InputDecoration(
                labelText: 'Enter PIN',
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

  /// Math-based gate — asks a simple arithmetic question that young kids
  /// typically can't solve but adults can (e.g. "What is 7 + 5?").
  static Future<bool> _showMathGate(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final random = Random();
    final a = random.nextInt(10) + 5; // 5-14
    final b = random.nextInt(10) + 3; // 3-12
    final answer = a + b;
    final controller = TextEditingController();

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calculate, color: const Color(0xFF006432)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(
              'To continue, solve this:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'What is $a + $b?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: '?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
              if (controller.text.trim() == answer.toString()) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect answer, try again'),
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

  /// Show a dialog to set or change the account PIN.
  static Future<void> showSetPinDialog(BuildContext context) async {
    final auth = context.read<AuthService>();
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pin, color: const Color(0xFF006432)),
            const SizedBox(width: 8),
            Text(auth.hasAccountPin ? 'Change PIN' : 'Set PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a 4-digit PIN to protect sign-out and profile deletion. '
              'Only share this with parents/guardians.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 12),
              decoration: InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 12),
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (auth.hasAccountPin)
            TextButton(
              onPressed: () {
                auth.removeAccountPin();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN removed')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove PIN'),
            ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text.trim();
              final confirm = confirmController.text.trim();
              if (pin.length != 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be 4 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              auth.setAccountPin(pin);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN set successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
