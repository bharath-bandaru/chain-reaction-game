import 'package:flutter/services.dart';

/// App-wide haptic feedback.
class Haptics {
  Haptics._();

  /// Global switch: set to false to silence all haptics across the app.
  static bool enabled = true;

  /// Light tick played by every tappable element.
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }
}
