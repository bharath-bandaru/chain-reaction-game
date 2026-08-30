import 'package:flutter/material.dart';

import 'cell.dart';

/// A cell explosion currently being animated. The UI renders orbs flying from
/// the exploding cell toward each valid neighbor for the wave duration.
class ExplosionEvent {
  ExplosionEvent({
    required this.id,
    required this.row,
    required this.col,
    required this.color,
  });

  final int id;
  final int row;
  final int col;
  final Color color;
}

/// A request to animate a small dot flying from the active player indicator
/// down to the tapped cell (the web app's `createAnimation`).
class FlyingDotEvent {
  FlyingDotEvent({
    required this.id,
    required this.row,
    required this.col,
    required this.color,
  });

  final int id;
  final int row;
  final int col;
  final Color color;
}

/// Immutable snapshot of the mutable game state, used by the undo stack.
class GameSnapshot {
  GameSnapshot({
    required this.board,
    required this.currentPlayer,
    required this.nextPlayer,
    required this.losers,
    required this.moveCount,
  });

  final Board board;
  final int currentPlayer;
  final int nextPlayer;
  final List<bool> losers;
  final int moveCount;
}
