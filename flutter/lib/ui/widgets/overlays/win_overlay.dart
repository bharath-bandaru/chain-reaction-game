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
    // Rendered at 300 wide; the GIFs carry ~20px of baked-in margin on every
    // side, so the visible frame is inset by 20 and the image overflows it
    // (centered), cropping all four edges equally.
    // won.gif is 480x288, lose.gif is 498x305.
    final renderedHeight = won ? 300 * 288 / 480 : 300 * 305 / 498;

    return Container(
      color: const Color(0xE3000000),
      child: Center(
        child: SingleChildScrollView(
          // Bottom inset lifts the content (result GIF) above dead center.
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Designed and Developed by © ',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 9),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => launchUrl(
                      Uri.parse(AppConstants.ephileoUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text(
                      'ephileo',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 300 - 3,
                  height: renderedHeight - 3,
                  child: OverflowBox(
                    maxWidth: 300,
                    maxHeight: renderedHeight,
                    child: Image.asset(
                      won ? 'assets/images/won.gif' : 'assets/images/lose.gif',
                      width: 300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layered support button: the solid `#FFC43A` pill sits up-left of a
/// slightly larger white-outlined backdrop box; on press the button expands
/// to fill the backdrop exactly, then launches the support link and springs
/// back.
class SupportShadowButton extends StatefulWidget {
  const SupportShadowButton({super.key});

  @override
  State<SupportShadowButton> createState() => _SupportShadowButtonState();
}

class _SupportShadowButtonState extends State<SupportShadowButton> {
  static const Color _gold = Color(0xFFFFC43A);

  /// Idle button size; the backdrop box is [_inflate] wider on each side
  /// and sits [_dropY] lower.
  static const double _width = 120;
  static const double _height = 36;
  static const double _inflate = 6;
  static const double _dropY = 10;

  bool _expanded = false;

  Future<void> _handleTap() async {
    // Expanded was already set by onTapDown; hold it so the grow into the
    // backdrop is visible, then launch and spring back.
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 220));
    await launchUrl(
      Uri.parse(AppConstants.supportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (mounted) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    const content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, size: 19, color: AppColors.background),
        SizedBox(width: 6),
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _expanded = true),
      onTapCancel: () => setState(() => _expanded = false),
      onTap: _handleTap,
      child: SizedBox(
        width: _width + _inflate * 2,
        height: _height + _dropY,
        child: Stack(
          children: [
            // White-outlined backdrop box, offset down behind the button.
            Positioned(
              left: 0,
              right: 0,
              top: _dropY,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // The gold button; on press it grows to fill the backdrop.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: _expanded ? 0 : _inflate,
              right: _expanded ? 0 : _inflate,
              top: _expanded ? _dropY : 0,
              bottom: _expanded ? 0 : _dropY,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(_expanded ? 10 : 8),
                ),
                // scaleDown keeps wide font metrics from overflowing the
                // fixed-size button (identical rendering when content fits).
                child: const Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: content),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
