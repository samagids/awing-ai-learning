import 'package:flutter_test/flutter_test.dart';
import 'package:awing_ai_learning/modules/beginner/beginner_module.dart';

void main() {
  test('BeginnerModule initializes correctly', () {
    final module = BeginnerModule();
    expect(module.greeting, 'Welcome to Beginner level');
  });
}
