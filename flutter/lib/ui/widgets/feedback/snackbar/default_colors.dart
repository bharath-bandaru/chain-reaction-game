import 'package:flutter/cupertino.dart';

/// Single source of truth for the custom snackbar pill palette.
///
/// "Roamates logo" palette — the pill tones are pulled from the brand
/// logo's teal blue plus the brand red. Success and info are two shades
/// of the logo teal (lighter / deeper) so they stay distinct while
/// sharing one hue family; error is the brand red. The same hex values
/// render in both light and dark mode: the pill is a self-contained,
/// solid-fill bubble with a hard offset shadow, so it stays loud and
/// legible against every scaffold variant without per-mode branching.
///
/// All three tones carry WHITE text (each clears the WCAG 3:1
/// large-bold bar comfortably). Each tone still exposes its own
/// foreground so `custom_snackbar.dart` can pick the text/icon color per
/// tone if a lighter background is ever reintroduced.
///
/// Each tone is a background + matching darker hard-shadow pair. The
/// shadow tone is ~18–22% darker than the background and gives the pill
/// its 3D "physical button" feel. Wired into `_PillTone` in
/// `custom_snackbar.dart`.
class DefaultColors {
  // Success — brand "Teal Blue" from the logo (the lighter, brighter
  // teal). Carries white text.
  static const Color successGreen = Color(0xFF008AAD);
  static const Color successGreenShadow = Color(0xFF006C87);

  // Info — a deeper teal, one shade darker than success so the two
  // tones stay visually distinct while sharing the logo's teal family.
  // Carries white text.
  static const Color helpBlue = Color(0xFF00667D);
  static const Color helpBlueShadow = Color(0xFF004E61);

  // Error — brand red. Carries white text. `ContentType.warning`
  // collapses into this tone too (see `_toneForContentType` in
  // `custom_snackbar.dart`).
  static const Color failureRed = Color(0xFFE41B32);
  static const Color failureRedShadow = Color(0xFFB81427);
}
