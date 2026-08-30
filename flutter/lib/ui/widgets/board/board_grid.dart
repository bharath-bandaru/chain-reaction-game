import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../logic/game_controller.dart';
import '../../../models/cell.dart';
import 'explosion.dart';
import 'orb.dart';

/// The playing field: a grid of tappable squares whose borders take the next
/// player's color, plus an overlay layer that renders the currently running
/// explosion animations.
///
/// The cell size is computed by the parent (so the header/footer can align
/// with the board edges); [boardKey] exposes the grid's geometry to the
/// flying-dot animation.
class BoardGrid extends StatelessWidget {
  const BoardGrid({
    super.key,
    required this.boardKey,
    required this.cellSize,
  });

  final GlobalKey boardKey;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final width = cellSize * game.cols;
    final height = cellSize * game.rows;

    return Container(
      key: boardKey,
      width: width,
      height: height,
      // 1.2px frame painted over the edge cells' own 0.6px borders so the
      // outer edge matches the inner lines (two adjacent 0.6px borders).
      foregroundDecoration: BoxDecoration(
        border: Border.all(
            color: game.activeColor.withValues(alpha: 0.85), width: 1.2),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              for (var i = 0; i < game.rows; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var j = 0; j < game.cols; j++)
                      _BoardSquare(
                        key: ValueKey('cell_${i}_$j'),
                        row: i,
                        col: j,
                        cellSize: cellSize,
                        cell: game.board[i][j],
                        borderColor: game.activeColor,
                        glitch: game.lastPlaced == (i, j),
                        onTap: () => game.onSquareTap(i, j),
                      ),
                  ],
                ),
            ],
          ),
          // Explosion animation overlay.
          for (final explosion in game.explosions)
            Positioned(
              left: explosion.col * cellSize,
              top: explosion.row * cellSize,
              width: cellSize,
              height: cellSize,
              child: IgnorePointer(
                child: Explosion(
                  key: ValueKey(explosion.id),
                  color: explosion.color,
                  cellSize: cellSize,
                  directions: [
                    if (explosion.col > 0) const Offset(-1, 0),
                    if (explosion.col < game.cols - 1) const Offset(1, 0),
                    if (explosion.row > 0) const Offset(0, -1),
                    if (explosion.row < game.rows - 1) const Offset(0, 1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One tappable board cell with a thin border in the active player's color.
class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    super.key,
    required this.row,
    required this.col,
    required this.cellSize,
    required this.cell,
    required this.borderColor,
    required this.glitch,
    required this.onTap,
  });

  final int row;
  final int col;
  final double cellSize;
  final Cell? cell;
  final Color borderColor;
  final bool glitch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: AppColors.cellFill,
          border: Border.all(
              color: borderColor.withValues(alpha: 0.85), width: 0.6),
        ),
        child: cell == null
            ? null
            : Orb(
                state: cell!.state,
                color: AppColors.players[cell!.player],
                cellSize: cellSize,
                glitch: glitch,
              ),
      ),
    );
  }
}
