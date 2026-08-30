import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/game_controller.dart';
import '../../../core/haptics.dart';

/// Top overlay row, rendered just below the system status bar: the global
/// like counter with a heart, aligned right. Tapping it likes.
class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key, required this.onLike});

  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final likes = context.select<GameController, int?>((g) => g.numberOfLikes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Haptics.tap();
            onLike();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  likes?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 5),
                // Muted heart, same color as the count text.
                const Icon(Icons.favorite, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
