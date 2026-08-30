import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../logic/game_controller.dart';

/// Full-screen layer that animates a small orb from the active player's
/// indicator dot down to the tapped cell — the web app's `createAnimation`.
///
/// Geometry is resolved through [activeDotKey] (start) and [boardKey]
/// (target cell center, computed from the board's box size and grid shape).
class FlyingDotLayer extends StatelessWidget {
  const FlyingDotLayer({
    super.key,
    required this.boardKey,
    required this.activeDotKey,
  });

  final GlobalKey boardKey;
  final GlobalKey activeDotKey;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final event = game.flyingDot;
    if (event == null) return const SizedBox.shrink();

    final boardBox = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return const SizedBox.shrink();

    final boardOrigin = boardBox.localToGlobal(Offset.zero);
    final cellSize = boardBox.size.width / game.cols;
    final target = boardOrigin +
        Offset((event.col + 0.5) * cellSize, (event.row + 0.5) * cellSize);

    final dotBox =
        activeDotKey.currentContext?.findRenderObject() as RenderBox?;
    final start = (dotBox != null && dotBox.hasSize)
        ? dotBox.localToGlobal(dotBox.size.center(Offset.zero))
        // Fallback: fly from just above the board's top center.
        : boardOrigin + Offset(boardBox.size.width / 2, -20);

    const dotSize = 18.0;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(event.id),
        tween: Tween(begin: 0, end: 1),
        duration: AppConstants.flyingDot,
        curve: const Cubic(0.42, 0, 0, 0.98),
        builder: (context, t, _) {
          final position = Offset.lerp(start, target, t)!;
          // Solid for the whole flight — it lands in the cell and the placed
          // orb takes over, no fading.
          return Stack(
            children: [
              Positioned(
                left: position.dx - dotSize / 2,
                top: position.dy - dotSize / 2,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
