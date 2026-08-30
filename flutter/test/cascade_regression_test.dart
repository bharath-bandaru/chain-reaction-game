import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/models/cell.dart';
import 'package:chain_reaction/services/firebase_service.dart';
import 'package:chain_reaction/services/preferences_service.dart';

/// Regression for the "game stuck mid-chain" bug: a cell fed by several
/// exploding neighbours in the same wave used to fire once per incoming orb,
/// minting orbs out of nothing — dense boards then cascaded (nearly) forever.
/// The cascade must conserve orbs exactly (+1 per move) and converge fast.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameController> makeGame() async {
    SharedPreferences.setMockInitialValues({});
    return GameController(
      firebase: FirebaseService(),
      prefs: await PreferencesService.load(),
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
      {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return true;
      await Future.delayed(const Duration(milliseconds: 25));
    }
    return condition();
  }

  test('a doubly-fed cell fires once and the cascade conserves orbs',
      () async {
    final game = await makeGame();

    // Corner cluster primed so the corner (0,0) explodes into (0,1) and
    // (1,0), which both explode and feed (0,0) AND (1,1) twice in the same
    // wave — the exact shape that used to mint orbs and run away.
    game.board[0][0] = Cell(player: 0, state: 1);
    game.board[0][1] = Cell(player: 0, state: 2);
    game.board[1][0] = Cell(player: 0, state: 2);
    game.board[1][1] = Cell(player: 0, state: 3);
    game.board[8][5] = Cell(player: 1, state: 1); // opponent stays alive

    final before = totalOrbs(game);
    game.onSquareTap(0, 0);

    final settled = await waitUntil(() =>
        game.canClick && game.explosions.isEmpty && game.nextPlayer == 1);
    expect(settled, isTrue,
        reason: 'cascade did not converge — runaway chain reaction');

    // Chain reactions move orbs around but never create or destroy them:
    // exactly one orb was added by the tap.
    expect(totalOrbs(game), before + 1);
    expect(game.gameOver, isFalse);
    game.dispose();
  });

  test('a fully primed dense board converges instead of cycling forever',
      () async {
    final game = await makeGame();

    // Every cell at critical mass for player 0, one opponent orb — tapping
    // anywhere sets off a board-wide chain (131 orbs on a 132-capacity
    // board). In practice it ends through the domination break once the
    // opponent is captured; either way it must converge, not cycle forever.
    for (var i = 0; i < game.rows; i++) {
      for (var j = 0; j < game.cols; j++) {
        game.board[i][j] =
            Cell(player: 0, state: maxStateFor(i, j, game.rows, game.cols));
      }
    }
    game.board[4][3] = Cell(player: 1, state: 1);

    game.onSquareTap(0, 0);
    final settled = await waitUntil(
        () => game.explosions.isEmpty && (game.canClick || game.gameOver),
        timeout: const Duration(seconds: 60));
    expect(settled, isTrue,
        reason: 'dense-board cascade never terminated — runaway chain');

    // The lone opponent orb must have been captured along the way.
    for (final row in game.board) {
      for (final cell in row) {
        if (cell != null) expect(cell.player, 0);
      }
    }
    game.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
