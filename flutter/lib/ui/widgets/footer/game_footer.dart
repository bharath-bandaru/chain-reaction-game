import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../logic/game_controller.dart';
import '../common/dot_loader.dart';
import '../common/ui_kit.dart';
import '../menus/online_menu.dart';
import '../../../core/haptics.dart';

/// Board footer, sized to the board's width so the like emoji and the online
/// menu sit right on the board's bottom corners (per the mockup), with the
/// title / undo / spinner centered between them.
class GameFooter extends StatelessWidget {
  const GameFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    // Fixed height: the center slot swaps between title text, the undo /
    // action pills, and a spinner — without a constant height those swaps
    // would nudge the vertically-centered board block up and down.
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Haptics.tap();
              game.like();
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text('❤️', style: TextStyle(fontSize: 24)),
            ),
          ),
          Expanded(child: Center(child: _centerContent(game))),
          const OnlineMenuButton(),
        ],
      ),
    );
  }

  Widget _centerContent(GameController game) {
    // Spinner while waiting for players to join a room.
    if (game.isLoading) {
      return const DotFlashingLoader();
    }

    final title = game.titleMessage;

    if (title == TitleMessages.start || title == TitleMessages.chainReaction) {
      if (game.showUndo && game.canUndo && !game.isLive) {
        return PillButton(
          text: 'undo',
          color: game.activeColor,
          onTap: game.undoMove,
        );
      }
      if (title == TitleMessages.start) {
        return PillButton(
          text: title,
          color: AppColors.players[0],
          onTap: game.onTitleTap,
        );
      }
      return const Text(
        TitleMessages.chainReaction,
        style: TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (title == TitleMessages.next) {
      return PillButton(
        text: title,
        color: AppColors.accentYellow,
        onTap: game.onTitleTap,
      );
    }

    if (title == TitleMessages.rejoinRoom || title == TitleMessages.restart) {
      return PillButton(
        text: title,
        color: AppColors.chipOrange,
        onTap: game.onTitleTap,
      );
    }

    // "Level X" while playing against the computer.
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
