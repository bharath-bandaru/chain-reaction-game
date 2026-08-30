import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/game_controller.dart';
import 'robot_avatar.dart';

/// Row of player indicator dots. The active player's dot gets a white ring
/// (`dot-2` in the web CSS); the AI player's dot is replaced by the robot.
///
/// [activeDotKey] is attached to the active player's dot so the flying-dot
/// animation knows where to start.
class PlayerDots extends StatelessWidget {
  const PlayerDots({super.key, required this.activeDotKey});

  final GlobalKey activeDotKey;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < game.playerCount; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _indicatorFor(game, index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _indicatorFor(GameController game, int index) {
    // Online games highlight *your* seat; local games highlight whoever
    // moves next (matching the React render logic).
    final highlighted =
        game.isLive ? index == game.mainPlayer : index == game.nextPlayer;

    if (!game.isLive && index == game.aiPlayerIndex) {
      return KeyedSubtree(
        key: index == game.nextPlayer ? activeDotKey : null,
        child: RobotAvatar(
          thinking: game.aiThinking ||
              (index == game.nextPlayer && !game.gameOver),
          color: AppColors.players[AppConstants.aiPlayerIndex],
        ),
      );
    }

    return Container(
      key: highlighted && !game.isLive ? activeDotKey : null,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.players[index],
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted ? Colors.white : AppColors.background,
          width: 3,
        ),
      ),
    );
  }
}
