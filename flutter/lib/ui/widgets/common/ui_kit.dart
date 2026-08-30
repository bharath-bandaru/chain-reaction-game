import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Accent icon tile, iOS-Settings style: a squircle filled with a soft
/// top-lit accent gradient, a crisp white glyph, and a gentle ambient glow
/// in the accent color — no borders, no hard shadows.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Top-lit gradient: slightly lifted at the top-left, slightly sunk at
    // the bottom-right, so the tile reads as softly domed glass.
    final light = Color.lerp(color, Colors.white, 0.22)!;
    final dark = Color.lerp(color, Colors.black, 0.22)!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color, dark],
        ),
        borderRadius: BorderRadius.circular(size * 0.31),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.58, color: Colors.white),
    );
  }
}

/// iPad / tablet detection, same breakpoint as the roamates app.
bool isTabletLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// Drag handle rendered inside a sheet, above its content.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 5,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}


/// Liquid-glass panel shared by the bottom sheets: an even translucent fill
/// over a blurred backdrop, so the board's colour bleeds through. The
/// surface is deliberately flat — no rim light, no gradient wash. On phones
/// only the top corners are rounded (the sheet is flush with the bottom);
/// on tablets the sheet floats, so all corners round.
class SheetSurface extends StatelessWidget {
  const SheetSurface({super.key, required this.child});

  final Widget child;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final shape = isTabletLayout(context)
        ? BorderRadius.circular(_radius)
        : const BorderRadius.vertical(top: Radius.circular(_radius));
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: CustomPaint(
          painter: _GlassBody(),
          child: child,
        ),
      ),
    );
  }
}

/// Even translucent tint, flat by design.
class _GlassBody extends CustomPainter {
  /// Kept well short of opaque — this is what lets the blurred board show
  /// through and makes the panel read as glass rather than as paint.
  static const Color _tint = Color(0xC7191919);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _tint);
  }

  @override
  bool shouldRepaint(_GlassBody oldDelegate) => false;
}

/// Dark circular button used across the header and footer.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 48,
  });

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.buttonBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Card-style bottom-sheet row: colorful icon chip, title + subtitle, and a
/// chevron. Dims and ignores taps when disabled.
class SheetOptionRow extends StatelessWidget {
  const SheetOptionRow({
    super.key,
    required this.icon,
    required this.chipColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color chipColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IconChip(icon: icon, color: chipColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-style bottom-sheet row with a trailing switch instead of a chevron.
class SheetToggleRow extends StatelessWidget {
  const SheetToggleRow({
    super.key,
    required this.icon,
    required this.chipColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color chipColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconChip(icon: icon, color: chipColor, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.chipGreen,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spacebar-style action button mirroring the web `.undo-button` /
/// `.title-*-button` rules: neutral white border and text when idle, and
/// while pressed it fills with the accent [color] and the text turns black
/// (the CSS `:hover`/`:active` state, 150ms transition).
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;

  /// Accent used for the pressed fill (player color, yellow, orange, ...).
  final Color color;

  final VoidCallback onTap;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  /// Fills the button with the accent color and keeps it filled briefly
  /// after the tap, so the click visibly registers.
  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(50, 2, 50, 5),
        decoration: BoxDecoration(
          color: _pressed ? widget.color : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _pressed ? widget.color : Colors.white),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: _pressed ? Colors.black : Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
