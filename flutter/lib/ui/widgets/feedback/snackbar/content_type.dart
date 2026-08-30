/// Marker for the four snackbar tones. Callers reference the static
/// instances (`ContentType.success` / `.failure` / `.help` / `.warning`);
/// `_toneForContentType` / `_iconForContentType` in `custom_snackbar.dart`
/// switch on instance identity to pick the pill tone and icon.
///
/// `failure` and `warning` both map to the orange/red "error" pill —
/// only three visual tones exist (success, info, error).
class ContentType {
  /// Stable discriminator so each static instance is a distinct const
  /// object (required for the identity-based `==` checks downstream).
  final String name;

  const ContentType._(this.name);

  static const ContentType help = ContentType._('help');
  static const ContentType failure = ContentType._('failure');
  static const ContentType success = ContentType._('success');
  static const ContentType warning = ContentType._('warning');
}
