/// Minimax AI with alpha-beta pruning — a direct port of `src/ai.js` from the
/// React app. The AI plays as player 1 against player 0.
///
/// Boards are passed between isolates as an int-encoded matrix so the search
/// can run inside `compute()` without blocking the UI thread:
///   * `0`  — empty cell
///   * else — `(player << 3) | state`
library;

import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Search depth pools per difficulty level; one depth is picked at random for
/// each candidate move (identical to the web version's `aiLevels`).
const Map<String, List<int>> aiLevelDepths = {
  '1': [0, 1, 1, 1],
  '2': [1, 2, 2, 2],
  '3': [2],
  '4': [2, 3],
  '5': [3],
};

const int _won = 999999;
const int _lost = -999999;

/// Bias weight for preferring moves near opponent orbs.
const double _proximityBias = 0.5;

/// Hard wall-clock budget for one full search. Once exceeded, remaining
/// nodes fall back to a static evaluation, so a dense board can degrade the
/// search quality but never the response time.
const int _searchBudgetMs = 2800;

int encodeCell(int player, int state) => (player << 3) | state;
int _cellPlayer(int v) => v >> 3;
int _cellState(int v) => v & 7;

/// Entry point designed for `compute()`. [args] must contain:
///   * `board` — `List<List<int>>` (encoded as above)
///   * `level` — difficulty key `'1'..'5'`
///
/// Returns `[row, col]` of the chosen move, or `null` when no move exists.
List<int>? findBestMove(Map<String, dynamic> args) {
  final board = [
    for (final row in args['board'] as List)
      [for (final v in row as List) v as int],
  ];
  final level = args['level'] as String;
  final random = Random();
  final stopwatch = Stopwatch()..start();

  // Shuffled so that when the time budget cuts the search short, the moves
  // that got the deep treatment aren't biased toward one board corner.
  final availableMoves = _availableMoves(board, 1)..shuffle(random);
  final depths = aiLevelDepths[level] ?? aiLevelDepths['5']!;

  var bestMoves = <List<int>>[];
  var bestComposite = double.negativeInfinity;

  for (final move in availableMoves) {
    final newBoard = _copy(board);
    _makeMove(newBoard, move, 1);
    if (_evaluate(newBoard) == _won) return move;

    final depth = stopwatch.elapsedMilliseconds >= _searchBudgetMs
        ? 0
        : depths[random.nextInt(depths.length)];
    final moveValue = _minimax(
      newBoard,
      depth,
      double.negativeInfinity,
      double.infinity,
      false,
      stopwatch,
    );

    // Prefer moves adjacent to opponent orbs.
    final proximity = _opponentAdjacency(board, move[0], move[1], 1);
    final composite = moveValue + _proximityBias * proximity;

    if (composite > bestComposite) {
      bestComposite = composite;
      bestMoves = [move];
    } else if (composite == bestComposite) {
      bestMoves.add(move);
    }
  }

  if (bestMoves.isEmpty) return null;
  return bestMoves[random.nextInt(bestMoves.length)];
}

/// Test-only window into the cascade simulation: applies [move] for [player]
/// on a copy of [board] and returns the settled result, so tests can assert
/// orb conservation over the search's internal move model.
@visibleForTesting
List<List<int>> simulateMoveForTest(
  List<List<int>> board,
  List<int> move,
  int player,
) {
  final copy = _copy(board);
  _makeMove(copy, move, player);
  return copy;
}

List<List<int>> _copy(List<List<int>> board) => [
  for (final row in board) List<int>.of(row),
];

int _maxState(int i, int j, int rows, int cols) {
  final onRowEdge = i == 0 || i == rows - 1;
  final onColEdge = j == 0 || j == cols - 1;
  if (onRowEdge && onColEdge) return 1;
  if (onRowEdge || onColEdge) return 2;
  return 3;
}

List<List<int>> _availableMoves(List<List<int>> board, int player) {
  final moves = <List<int>>[];
  for (var i = 0; i < board.length; i++) {
    for (var j = 0; j < board[i].length; j++) {
      final v = board[i][j];
      if (v == 0 || _cellPlayer(v) == player) moves.add([i, j]);
    }
  }
  return moves;
}

int _opponentAdjacency(List<List<int>> board, int i, int j, int player) {
  final opponent = player == 1 ? 0 : 1;
  const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  var score = 0;
  for (final (dx, dy) in dirs) {
    final x = i + dx, y = j + dy;
    if (x >= 0 && x < board.length && y >= 0 && y < board[0].length) {
      final v = board[x][y];
      if (v != 0 && _cellPlayer(v) == opponent) score++;
    }
  }
  return score;
}

/// Applies [move] for [player], resolving the full chain reaction
/// breadth-first (wave by wave). Mirrors `GameController._resolveMove`.
///
/// A wave maps each receiving cell (encoded as `row * cols + col`) to how many
/// orbs land on it. Aggregating is what keeps the simulation honest: a cell fed
/// by several exploding neighbours takes all of their orbs at once and still
/// fires once. A flat queue let it fire once per incoming orb, minting orbs out
/// of nothing and blowing the queue up exponentially.
void _makeMove(List<List<int>> board, List<int> move, int player) {
  final rows = board.length, cols = board[0].length;
  var wave = <int, int>{move[0] * cols + move[1]: 1};

  while (wave.isNotEmpty) {
    final exploders = <int>[];
    for (final entry in wave.entries) {
      final i = entry.key ~/ cols, j = entry.key % cols;
      if (_addOrbs(board, i, j, entry.value, player)) exploders.add(entry.key);
    }
    if (exploders.isEmpty) break;

    final next = <int, int>{};
    void feed(int i, int j) =>
        next.update(i * cols + j, (count) => count + 1, ifAbsent: () => 1);
    for (final key in exploders) {
      final i = key ~/ cols, j = key % cols;
      if (i - 1 >= 0) feed(i - 1, j);
      if (i + 1 < rows) feed(i + 1, j);
      if (j - 1 >= 0) feed(i, j - 1);
      if (j + 1 < cols) feed(i, j + 1);
    }
    wave = next;

    // Stop endless chains once the board is fully captured.
    if (_dominatedBy(board, player)) break;
  }
}

/// Drops [count] orbs on (i, j) for [player], who takes the cell over. Returns
/// true when the cell passed its critical mass; the leftover (`total - the
/// neighbour count it sheds`) is written straight away, so the cascade can
/// never create orbs and encoded states stay within their 3 bits.
bool _addOrbs(List<List<int>> board, int i, int j, int count, int player) {
  final max = _maxState(i, j, board.length, board[0].length);
  final v = board[i][j];
  final state = (v == 0 ? 0 : _cellState(v)) + count;

  if (state > max) {
    final leftover = state - (max + 1);
    board[i][j] = leftover > 0 ? encodeCell(player, leftover) : 0;
    return true;
  }
  board[i][j] = encodeCell(player, state);
  return false;
}

/// True when no cell is left to the opponent of [player].
bool _dominatedBy(List<List<int>> board, int player) {
  for (final row in board) {
    for (final v in row) {
      if (v != 0 && _cellPlayer(v) != player) return false;
    }
  }
  return true;
}

/// Net orb advantage for the AI (player 1); +/-999999 for win/loss.
int _evaluate(List<List<int>> board) {
  var score = 0;
  var didWin = true, didLose = true;

  for (final row in board) {
    for (final v in row) {
      if (v == 0) continue;
      if (_cellPlayer(v) == 1) {
        didLose = false;
        score += _cellState(v);
      } else if (_cellPlayer(v) == 0) {
        didWin = false;
        score -= _cellState(v);
      }
    }
  }

  if (didWin) return _won;
  if (didLose) return _lost;
  return score;
}

double _minimax(
  List<List<int>> board,
  int depth,
  double alpha,
  double beta,
  bool maximizing,
  Stopwatch stopwatch,
) {
  // Depth exhausted — or the time budget is: degrade to a static evaluation
  // so one deep subtree can never blow past the response-time cap.
  if (depth == 0 || stopwatch.elapsedMilliseconds >= _searchBudgetMs) {
    return _evaluate(board).toDouble();
  }

  if (maximizing) {
    var maxEval = double.negativeInfinity;
    for (final move in _availableMoves(board, 1)) {
      final newBoard = _copy(board);
      _makeMove(newBoard, move, 1);
      final eval = _minimax(newBoard, depth - 1, alpha, beta, false, stopwatch);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    var minEval = double.infinity;
    for (final move in _availableMoves(board, 0)) {
      final newBoard = _copy(board);
      _makeMove(newBoard, move, 0);
      final eval = _minimax(newBoard, depth - 1, alpha, beta, true, stopwatch);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}
