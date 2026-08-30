import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/game_controller.dart';
import '../menus/settings_menu.dart';
import '../sheets/confirm_sheet.dart';
import 'player_dots.dart';
import '../../../core/haptics.dart';

/// Board header, sized to the board's width so its icons sit right on the
/// board's top corners (per the mockup):
///   * row 1 — add / players / remove controls (or the live room code),
///     centered, flat on the black canvas
///   * row 2 — settings menu icon (left corner), player dots (center),
///     restart icon (right corner)
class GameHeader extends StatelessWidget {
  const GameHeader({super.key, required this.activeDotKey});

  final GlobalKey activeDotKey;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!game.isLive)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FlatIconButton(
                icon: Icons.add,
                onTap: () => _changePlayerCount(context, game, add: true),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Icon(Icons.groups, color: Colors.white, size: 32),
              ),
              _FlatIconButton(
                icon: Icons.remove,
                onTap: () => _changePlayerCount(context, game, add: false),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                painter: _DottedBorderPainter(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  child: Text(
                    game.roomCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              _FlatIconButton(
                icon: Icons.content_copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: game.shareText));
                  game.onToast?.call('Copied to clipboard', ToastTone.success);
                },
              ),
            ],
          ),
        const SizedBox(height: 2),
        Row(
          children: [
            const SettingsMenuButton(),
            Expanded(
              child: Center(child: PlayerDots(activeDotKey: activeDotKey)),
            ),
            _FlatIconButton(
              icon: Icons.cached,
              size: 24,
              onTap: () => _confirmRestart(context, game),
            ),
          ],
        ),
      ],
    );
  }
}

/// Restarts the game; mid-game it asks for confirmation first. Once the
/// game is over (or before it starts) the restart is immediate.
Future<void> _confirmRestart(BuildContext context, GameController game) async {
  if (game.isMidGame) {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Restart game?',
      message: 'A game is in progress — restarting clears the board.',
      confirmColor: AppColors.players[0],
    );
    if (!confirmed) return;
  }
  game.restartGame();
}

/// Adds or removes a hotseat player. A no-op at the 2/4 player limits;
/// mid-game it asks for confirmation first, since changing players restarts
/// the game in progress.
Future<void> _changePlayerCount(
  BuildContext context,
  GameController game, {
  required bool add,
}) async {
  if (add && game.playerCount >= AppConstants.maxPlayers) return;
  if (!add && game.playerCount <= AppConstants.minPlayers) return;

  if (game.isMidGame) {
    final confirmed = await showConfirmSheet(
      context,
      title: add ? 'Add a player?' : 'Remove a player?',
      message: 'A game is in progress — changing players restarts it.',
    );
    if (!confirmed) return;
  }
  if (add) {
    game.addPlayer();
  } else {
    game.removePlayer();
  }
}

/// Borderless white icon button, flat on the black canvas (mockup style).
class _FlatIconButton extends StatelessWidget {
  const _FlatIconButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
/// Web `.live-code` border: evenly spaced round white dots tracing a
/// rounded rectangle around the room code.
class _DottedBorderPainter extends CustomPainter {
  static const double _dotRadius = 1.6;
  static const double _spacing = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    // Dots are laid out per edge, with the per-edge spacing rounded so a
    // dot lands exactly on every corner (each corner is drawn once, as the
    // first dot of its outgoing edge).
    for (var e = 0; e < 4; e++) {
      final a = corners[e];
      final b = corners[(e + 1) % 4];
      final count = ((b - a).distance / _spacing).round().clamp(1, 1 << 16);
      for (var i = 0; i < count; i++) {
        canvas.drawCircle(Offset.lerp(a, b, i / count)!, _dotRadius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) => false;
}
