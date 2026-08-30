@Tags(['slow'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/services/firebase_service.dart';
import 'package:chain_reaction/services/preferences_service.dart';

/// Headless end-to-end AI games: plays random legal human moves against the
/// real controller + AI (real isolates, real timers) and fails loudly if the
/// game ever stops progressing — a deadlock detector for "my game is stuck".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameController> makeGame(String level, {String boardSize = '0'}) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameController(
      firebase: FirebaseService(),
      prefs: await PreferencesService.load(),
    );
    game.setBoardSize(boardSize);
    game.playWithComputer(level);
    return game;
  }

  int totalOrbs(GameController g) {
    var total = 0;
    for (final row in g.board) {
      for (final cell in row) {
        total += cell?.state ?? 0;
      }
    }
    return total;
  }

  Future<bool> waitUntil(bool Function() condition,
      {Duration timeout = const Duration(seconds: 25)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return true;
      await Future.delayed(const Duration(milliseconds: 25));
    }
    return condition();
  }

  String debugState(GameController g) =>
      'moveCount=${g.moveCount} nextPlayer=${g.nextPlayer} '
      'canClick=${g.canClick} aiThinking=${g.aiThinking} '
      'gameOver=${g.gameOver} showIWon=${g.showIWon}';

  (int, int)? randomHumanMove(GameController g, Random rng) {
    final options = <(int, int)>[];
    for (var i = 0; i < g.rows; i++) {
      for (var j = 0; j < g.cols; j++) {
        final cell = g.board[i][j];
        if (cell == null || cell.player == 0) options.add((i, j));
      }
    }
    if (options.isEmpty) return null;
    return options[rng.nextInt(options.length)];
  }

  Future<void> playOneGame(String level, int seed,
      {int maxPlies = 80, String boardSize = '0'}) async {
    final game = await makeGame(level, boardSize: boardSize);
    final rng = Random(seed);
    final aiDurations = <Duration>[];

    for (var ply = 0; ply < maxPlies && !game.gameOver; ply++) {
      // Wait for the human's turn (or game over).
      final humanTurn = await waitUntil(
          () => game.gameOver || (game.nextPlayer == 0 && game.canClick));
      expect(humanTurn, isTrue,
          reason: 'STUCK waiting for human turn at ply $ply '
              '(level $level, seed $seed): ${debugState(game)}');
      if (game.gameOver) break;

      final move = randomHumanMove(game, rng);
      expect(move, isNotNull, reason: 'no legal human move but not game over');
      game.onSquareTap(move!.$1, move.$2);

      // Wait for the AI to respond (its move fully resolved -> back to the
      // human) or the game to end.
      final aiStart = DateTime.now();
      final aiDone = await waitUntil(
          () => game.gameOver || (game.nextPlayer == 0 && game.canClick),
          timeout: const Duration(seconds: 30));
      aiDurations.add(DateTime.now().difference(aiStart));
      expect(aiDone, isTrue,
          reason: 'STUCK waiting for AI at ply $ply '
              '(level $level, seed $seed): ${debugState(game)}');

      // Orbs are conserved (+1 per move) while the game is running.
      if (!game.gameOver) {
        expect(totalOrbs(game), game.moveCount,
            reason: 'conservation broken at ply $ply '
                '(level $level, seed $seed)');
      }
    }

    if (aiDurations.isNotEmpty) {
      final worst =
          aiDurations.reduce((a, b) => a > b ? a : b).inMilliseconds;
      // ignore: avoid_print
      print('level $level seed $seed: ${aiDurations.length} AI turns, '
          'worst ${worst}ms, gameOver=${game.gameOver}');
    }
    game.dispose();
  }

  for (final level in ['1', '2', '3']) {
    test('full AI game at level $level never deadlocks', () async {
      await playOneGame(level, 7 + int.parse(level));
    }, timeout: const Timeout(Duration(minutes: 4)));
  }

  test('full AI game at level 5 (deepest search) never deadlocks', () async {
    await playOneGame('5', 42, maxPlies: 30);
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('full AI game on the 10x10 board never deadlocks', () async {
    await playOneGame('2', 13, maxPlies: 60, boardSize: '1');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
