import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Win / lose overlay (`IWon.js`): result GIF and credits. The support and
/// restart buttons float above it near the footer (placed by the screen).
class WinOverlay extends StatelessWidget {
  const WinOverlay({super.key, required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xE3000000),
      child: Center(
        child: SingleChildScrollView(
          // Bottom inset lifts the content (result GIF) above dead center.
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Designed and Developed by © Bharath Bandaru',
                style: TextStyle(color: AppColors.mutedText, fontSize: 9),
              ),
              const SizedBox(height: 5),
              Image.asset(
                won ? 'assets/images/won.gif' : 'assets/images/lose.gif',
                width: 300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The web app's layered support button: the solid `#FFC43A` `.support-btn`
/// stacked 8px above a white-outlined ghost copy (`.support-btn-2`), and on
/// press the solid button drops down into the shadow.
class SupportShadowButton extends StatefulWidget {
  const SupportShadowButton({super.key});

  @override
  State<SupportShadowButton> createState() => _SupportShadowButtonState();
}

class _SupportShadowButtonState extends State<SupportShadowButton> {
  static const double _drop = 8;
  static const Color _gold = Color(0xFFFFC43A);

  bool _pressed = false;

  Future<void> _handleTap() async {
    // Pressed was already set by onTapDown; hold it briefly so the drop
    // into the shadow is visible, then launch and release.
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    await launchUrl(
      Uri.parse(AppConstants.supportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (mounted) setState(() => _pressed = false);
  }

  /// One pill layer. Both layers carry a 1px border (the solid one in its
  /// own fill color) so their metrics are pixel-identical and the drop
  /// lands exactly on the outline.
  Widget _pill({required bool ghost}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.favorite, size: 19, color: AppColors.background),
        SizedBox(width: 4),
        Text(
          'Support',
          style: TextStyle(
            color: AppColors.background,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.2,
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
      decoration: BoxDecoration(
        color: ghost ? Colors.transparent : _gold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ghost ? Colors.white : _gold),
      ),
      child: ghost ? Opacity(opacity: 0, child: content) : content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: Stack(
        children: [
          // White-outlined ghost sitting below the solid button.
          Padding(
            padding: const EdgeInsets.only(top: _drop),
            child: _pill(ghost: true),
          ),
          // Solid button drops into the ghost while pressed.
          AnimatedPadding(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(top: _pressed ? _drop : 0),
            child: _pill(ghost: false),
          ),
        ],
      ),
    );
  }
}
