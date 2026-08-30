import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Plays the "critical mass" explosion for one cell: orbs travel to each
/// valid neighbor fully solid (no fading — each one visually *becomes* the
/// neighbor's orb), easing gently into the target, with a soft glow that
/// adds energy on the dark board.
class Explosion extends StatelessWidget {
  const Explosion({
    super.key,
    required this.color,
    required this.cellSize,
    required this.directions,
  });

  final Color color;
  final double cellSize;

  /// Unit offsets toward valid neighbors, e.g. `Offset(-1, 0)` for left.
  final List<Offset> directions;

  @override
  Widget build(BuildContext context) {
    // Matches the single-orb painter size so the hand-off into the arriving
    // orb is seamless.
    final dotSize = cellSize * 0.30;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppConstants.explosionWave,
      builder: (context, t, _) {
        // Linear, constant-speed travel: consecutive waves flow into each
        // other without a stutter at cell boundaries.
        final travel = t;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            for (final direction in directions)
              Positioned(
                left: (cellSize - dotSize) / 2 +
                    direction.dx * cellSize * travel,
                top: (cellSize - dotSize) / 2 +
                    direction.dy * cellSize * travel,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
