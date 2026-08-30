import 'package:flutter/material.dart';

/// Color palette following the roamates/Escape design language: pure black
/// canvas, dark rounded cards, and solid colorful icon chips.
abstract final class AppColors {
  /// Dark app canvas (#191919, same as the web app).
  static const Color background = Color(0xFF191919);

  /// Rounded cards / rows sitting on the canvas.
  static const Color card = Color(0xFF232323);

  /// Popup menus, dialogs and sheets. Sits *below* [card] so the rows inside
  /// a sheet read as raised panels on a near-black backdrop.
  static const Color surface = Color(0xFF121212);

  /// Circular header/footer buttons.
  static const Color buttonBackground = Color(0xFF262626);

  /// Board cell fill (matches the canvas, like the web `.square`).
  static const Color cellFill = Color(0xFF191919);

  /// Muted gray used for secondary text.
  static const Color mutedText = Color(0xFF8E8E93);

  /// Dimmer gray for hints/credits.
  static const Color faintText = Color(0xFF6A6A6A);

  /// Yellow accent used by the "How to Play" screens.
  static const Color accentYellow = Color(0xFFFFFF09);

  /// iOS-style red heart.
  static const Color heartRed = Color(0xFFFF453A);

  /// Solid icon-chip tints (reference: Currency green, Help yellow, ...).
  static const Color chipGreen = Color(0xFF34C759);
  static const Color chipYellow = Color(0xFFFFC01E);
  static const Color chipOrange = Color(0xFFFF9F0A);
  static const Color chipRed = Color(0xFFFF453A);
  static const Color chipBlue = Color(0xFF0A84FF);
  static const Color chipTeal = Color(0xFF30B0C7);
  static const Color chipPurple = Color(0xFFBF5AF2);

  /// Player colors, indexed by player number (0..3).
  static const List<Color> players = [
    Color(0xFF00A8CD), // Blue
    Color(0xFFCD00C5), // Pink
    Color(0xFFB0CD00), // Green
    Color(0xFFCD0000), // Red
  ];

  /// Human readable player color names, indexed by player number.
  static const List<String> playerNames = ['Blue', 'Pink', 'Green', 'Red'];
}
