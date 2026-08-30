import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/game_controller.dart';
import '../sheets/online_sheet.dart';
import '../../../core/haptics.dart';

/// The bottom-right 🚀 button: opens the "Play Online" bottom sheet.
class OnlineMenuButton extends StatelessWidget {
  const OnlineMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        Haptics.tap();
        showOnlineSheet(context, game);
      },
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Text('🚀', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
