import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../logic/game_controller.dart';
import '../common/ui_kit.dart';
import '../layout/custom_bottom_page.dart';
import '../../../core/haptics.dart';

/// Actions the sheet can resolve to.
enum OnlineAction { create, join, leave }

/// Opens the "Play Online" bottom sheet and runs the chosen action after the
/// sheet closes (using the caller's still-mounted context for follow-up UI).
Future<void> showOnlineSheet(BuildContext context, GameController game) async {
  final action = await Navigator.of(context).push<OnlineAction>(
    CustomBottomPage<OnlineAction>(
      // Lighter than the default black54: the glass needs the board
      // showing through it, not a near-opaque wall behind it.
      barrierColorOverride: const Color(0x47000000),
      child: CustomBottomSheetScaffold(child: OnlineSheet(game: game)),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case OnlineAction.create:
      await game.createRoom();
    case OnlineAction.join:
      await promptJoinRoom(context, game);
    case OnlineAction.leave:
      game.leaveRoom();
  }
}

/// Rich bottom sheet for online play: rounded dark panel with a drag handle,
/// header (title + live room code), and card-style option rows.
class OnlineSheet extends StatelessWidget {
  const OnlineSheet({super.key, required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Text(
                  'Play Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (game.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      game.roomCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              game.isLive
                  ? 'You are in a room — share the code with friends.'
                  : 'Play with 2–4 friends on any device, in real time.',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 18),
            SheetOptionRow(
              icon: Icons.add,
              chipColor: AppColors.players[0],
              title: 'Create Room',
              subtitle: 'Start a new room and share the code',
              enabled: !game.isLive,
              onTap: () => Navigator.of(context).pop(OnlineAction.create),
            ),
            const SizedBox(height: 12),
            SheetOptionRow(
              icon: Icons.meeting_room,
              chipColor: AppColors.chipGreen,
              title: 'Join Room',
              subtitle: 'Enter a 4-letter room code',
              enabled: !game.isLive,
              onTap: () => Navigator.of(context).pop(OnlineAction.join),
            ),
            const SizedBox(height: 12),
            SheetOptionRow(
              icon: Icons.logout,
              chipColor: AppColors.players[3],
              title: 'Leave Room',
              subtitle: game.isLive
                  ? 'Exit room ${game.roomCode}'
                  : 'You are not in a room yet',
              enabled: game.isLive,
              onTap: () => Navigator.of(context).pop(OnlineAction.leave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Room-code entry dialog, shown after "Join Room" is picked.
Future<void> promptJoinRoom(BuildContext context, GameController game) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Enter the room code',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 4,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
          color: Colors.white,
          letterSpacing: 8,
          fontSize: 22,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Haptics.tap();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
        TextButton(
          onPressed: () {
            Haptics.tap();
            Navigator.of(context).pop(controller.text);
          },
          child: const Text(
            'Join',
            style: TextStyle(
              color: AppColors.chipGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  if (code != null && code.trim().isNotEmpty) {
    await game.joinRoom(code);
  }
}
