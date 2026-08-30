import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/game_controller.dart';
import '../sheets/settings_sheet.dart';

/// The top-left menu button: opens the game menu bottom sheet. While playing
/// against the AI it shows an exit icon (flipped to point left, out of the
/// game) instead of the dashboard — same action, the menu is where you exit.
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final playingAi = context.select<GameController, bool>(
      (g) => g.aiPlayerIndex != null,
    );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => showSettingsSheet(context),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: playingAi
            ? Transform.flip(
                flipX: true,
                child: const Icon(
                  Icons.exit_to_app,
                  color: Colors.white,
                  size: 26,
                ),
              )
            : const Icon(
                Icons.dashboard_customize,
                color: Colors.white,
                size: 26,
              ),
      ),
    );
  }
}
