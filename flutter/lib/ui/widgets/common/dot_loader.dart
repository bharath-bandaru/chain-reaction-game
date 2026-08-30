import 'package:flutter/material.dart';

/// The web app's `.loading` indicator: three round dots flashing from
/// magenta to pale pink, staggered left to right (CSS `dotFlashing`
/// keyframes — 1s alternate loop with 0s / 0.5s / 1s delays).
class DotFlashingLoader extends StatefulWidget {
  const DotFlashingLoader({super.key, this.dotSize = 7});

  final double dotSize;

  @override
  State<DotFlashingLoader> createState() => _DotFlashingLoaderState();
}

class _DotFlashingLoaderState extends State<DotFlashingLoader>
    with SingleTickerProviderStateMixin {
  /// One full alternate cycle of the CSS animation (1s forward + 1s back).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  static const Color _base = Color(0xFFCD00C5); // rgb(205, 0, 197)
  static const Color _flash = Color(0xFFF9D4FF); // rgb(249, 212, 255)

  /// Per-dot animation-delay in seconds, as in the CSS.
  static const List<double> _delays = [0, 0.5, 1];

  /// Color of one dot at loop time [t] (0..1 over the 2s cycle), shifted by
  /// [delay]. Mirrors the keyframes: base at 0%, flash from 50% on, with
  /// `alternate` playing every other iteration backwards.
  Color _colorAt(double t, double delay) {
    var u = (t * 2 - delay) % 2;
    if (u < 0) u += 2;
    final iteration = u < 1 ? u : 2 - u;
    return Color.lerp(_base, _flash, (iteration * 2).clamp(0.0, 1.0))!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.dotSize;
    // Centers sit 15px apart in the CSS (7px dot + 8px gap), scaled here.
    final gap = size * 8 / 7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _colorAt(_controller.value, _delays[i]),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
