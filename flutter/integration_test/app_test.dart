import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/main.dart' as app;

/// On-device smoke test: boots the real app (including Firebase), plays a
/// full opening including a corner explosion, and wins a game against a
/// second local player.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapCell(WidgetTester tester, int i, int j) async {
    await tester.tap(find.byKey(ValueKey('cell_${i}_$j')));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('boot, play, explode, win', (tester) async {
    await app.main();
    // Discrete pumps: the header clock ticks every second, so
    // pumpAndSettle would never settle.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Chain Reaction'), findsOneWidget);
    final game =
        tester.element(find.byType(Scaffold).first).read<GameController>();

    // Opening moves.
    await tapCell(tester, 0, 0); // P0 corner
    await tapCell(tester, 0, 1); // P1 next to it
    expect(game.board[0][0]!.player, 0);
    expect(game.board[0][1]!.player, 1);

    // P0 explodes the corner, captures P1's only orb -> win.
    await tapCell(tester, 0, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(game.board[0][0], isNull);
    expect(game.gameOver, isTrue);
    expect(game.wonStatus, isTrue);
    expect(find.text('restart'), findsOneWidget);

    // Restart from the win screen.
    await tester.tap(find.text('restart'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.moveCount, 0);
  });
}
