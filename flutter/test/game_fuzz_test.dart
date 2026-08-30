import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chain_reaction/logic/ai/minimax_ai.dart';
import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/models/cell.dart';
import 'package:chain_reaction/services/firebase_service.dart';
import 'package:chain_reaction/services/preferences_service.dart';

/// Wait-free property fuzz: hundreds of cascades and dozens of full games at
/// zero animation delay, asserting the invariants that keep the game alive —
/// orb conservation (+1 per move), cascade convergence, elimination and
/// turn-order correctness — across both board sizes and 2–4 players.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameController> makeGame() async {
    SharedPreferences.setMockInitialValues({});
    return GameController(
      firebase: FirebaseService(),
      prefs: await PreferencesService.load(),
      waveDelay: Duration.zero,
      flyDelay: Duration.zero,
      aiDelay: Duration.zero,
    );
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
      {Duration timeout = const Duration(seconds: 10)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return true;
      await Future.delayed(const Duration(milliseconds: 1));
    }
    return condition();
  }

  group('AI internal move model (minimax _makeMove)', () {
    test('conserves orbs across random cascades', () {
      final rng = Random(1234);
      for (var iteration = 0; iteration < 300; iteration++) {
        final rows = rng.nextBool() ? 9 : 10;
        final cols = rows == 9 ? 6 : 10;
        // Random settled board: every cell at or below its critical mass.
        final board = [
          for (var i = 0; i < rows; i++)
            [
              for (var j = 0; j < cols; j++)
                rng.nextInt(3) == 0
                    ? 0
                    : encodeCell(rng.nextInt(2),
                        1 + rng.nextInt(maxStateFor(i, j, rows, cols))),
            ],
        ];
        int sum(List<List<int>> b) => [
              for (final row in b) ...row
            ].fold(0, (a, v) => a + (v == 0 ? 0 : v & 7));

        // Random legal move for the AI (player 1).
        final moves = <List<int>>[];
        for (var i = 0; i < rows; i++) {
          for (var j = 0; j < cols; j++) {
            final v = board[i][j];
            if (v == 0 || (v >> 3) == 1) moves.add([i, j]);
          }
        }
        if (moves.isEmpty) continue;
        final move = moves[rng.nextInt(moves.length)];

        final before = sum(board);
        final after = simulateMoveForTest(board, move, 1);
        final total = sum(after);

        // A mid-cascade domination break may drop in-flight orbs (the game
        // is decided at that point); otherwise conservation is exact.
        final dominated = after.every(
            (row) => row.every((v) => v == 0 || (v >> 3) == 1));
        if (dominated) {
          expect(total, lessThanOrEqualTo(before + 1),
              reason: 'minted orbs at iteration $iteration');
        } else {
          expect(total, before + 1,
              reason: 'conservation broken at iteration $iteration');
        }
      }
    });
  });

  group('full-game fuzz (zero-delay, no AI)', () {
    for (final config in [
      (players: 2, size: '0'),
      (players: 3, size: '0'),
      (players: 4, size: '0'),
      (players: 2, size: '1'),
      (players: 4, size: '1'),
    ]) {
      test('${config.players} players on board ${config.size} stay sound',
          () async {
        for (var seed = 0; seed < 6; seed++) {
          final game = await makeGame();
          game.setBoardSize(config.size);
          for (var p = 2; p < config.players; p++) {
            game.addPlayer();
          }
          final rng = Random(seed * 97 + config.players);

          for (var ply = 0; ply < 400 && !game.gameOver; ply++) {
            final settled = await waitUntil(
                () => game.gameOver || game.canClick);
            expect(settled, isTrue,
                reason: 'board never settled '
                    '(seed $seed ply $ply, ${config.players}p)');
            if (game.gameOver) break;

            // Random legal move for whoever is up.
            final mover = game.nextPlayer;
            expect(game.losers[mover], isFalse,
                reason: 'an eliminated player got a turn (seed $seed)');
            final options = <(int, int)>[];
            for (var i = 0; i < game.rows; i++) {
              for (var j = 0; j < game.cols; j++) {
                final cell = game.board[i][j];
                if (cell == null || cell.player == mover) options.add((i, j));
              }
            }
            expect(options, isNotEmpty,
                reason: 'no legal move but game not over (seed $seed)');
            final move = options[rng.nextInt(options.length)];
            game.onSquareTap(move.$1, move.$2);

            final done = await waitUntil(
                () => game.gameOver ||
                    (game.canClick && game.explosions.isEmpty));
            expect(done, isTrue,
                reason: 'cascade never converged (seed $seed ply $ply)');

            // Orbs are conserved (+1 per move) while the game is running.
            if (!game.gameOver) {
              expect(totalOrbs(game), game.moveCount,
                  reason: 'conservation broken (seed $seed ply $ply)');
            }
          }
          expect(game.gameOver, isTrue,
              reason: 'game never ended in 400 plies '
                  '(seed $seed, ${config.players}p, board ${config.size})');
          game.dispose();
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  test('online rooms are blocked while the 10x10 board is selected',
      () async {
    final game = await makeGame();
    final toasts = <String>[];
    game.onToast = (message, tone) => toasts.add(message);

    game.setBoardSize('1');
    await game.createRoom();
    expect(game.isLive, isFalse);
    expect(toasts.single, contains('6 x 9'));

    toasts.clear();
    await game.joinRoom('ABCD');
    expect(game.isLive, isFalse);
    expect(toasts.single, contains('6 x 9'));

    // Back on 6x9 the block lifts (offline service then reports offline).
    toasts.clear();
    game.setBoardSize('0');
    await game.createRoom();
    expect(toasts.single, 'You are offline');
    game.dispose();
  });

  test('capturing a player eliminates them and skips their turn', () async {
    final game = await makeGame();
    game.addPlayer(); // 3 players
    // Mid-game state: everyone has moved; player 1's only orb sits next to
    // player 0's primed corner.
    game.moveCount = 3;
    game.board[0][0] = Cell(player: 0, state: 1);
    game.board[0][1] = Cell(player: 1, state: 1);
    game.board[5][5] = Cell(player: 2, state: 1);

    game.onSquareTap(0, 0); // corner explodes, captures player 1's orb
    final done = await waitUntil(
        () => game.canClick && game.explosions.isEmpty);
    expect(done, isTrue);

    expect(game.losers[1], isTrue, reason: 'captured player not eliminated');
    expect(game.gameOver, isFalse, reason: 'player 2 still has orbs');
    expect(game.nextPlayer, 2,
        reason: 'turn must skip the eliminated player');
    game.dispose();
  });
}
