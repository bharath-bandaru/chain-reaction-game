import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chain_reaction/app.dart';
import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/services/firebase_service.dart';
import 'package:chain_reaction/services/preferences_service.dart';
import 'package:chain_reaction/ui/widgets/board/board_grid.dart';
import 'package:provider/provider.dart';

/// The rendered board must keep exactly the same size and position no matter
/// whose turn it is (turn changes swap dot highlights / footer content, and
/// none of that may re-scale the FittedBox around the board).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ChainReactionApp> buildApp() async {
    SharedPreferences.setMockInitialValues({});
    return ChainReactionApp(
      firebase: FirebaseService(),
      prefs: await PreferencesService.load(),
    );
  }

  testWidgets('board size is identical on every turn (friends mode)',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pump();

    Rect boardRect() => tester.getRect(find.byType(BoardGrid));
    final initial = boardRect();

    // Blue plays -> pink's turn.
    await tester.tap(find.byKey(const ValueKey('cell_4_3')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(boardRect(), initial,
        reason: "board moved/resized on pink's turn");

    // Pink plays -> blue's turn (undo pill now visible too).
    await tester.tap(find.byKey(const ValueKey('cell_2_2')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(boardRect(), initial,
        reason: "board moved/resized back on blue's turn");
  });

  testWidgets('board size is identical on every turn (AI mode)',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = tester
        .element(find.byType(Scaffold).first)
        .read<GameController>();
    game.playWithComputer('1');
    await tester.pump();

    Rect boardRect() => tester.getRect(find.byType(BoardGrid));
    final initial = boardRect();

    // Human plays -> robot's turn (thinking bars show).
    await tester.tap(find.byKey(const ValueKey('cell_4_3')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(game.nextPlayer, 1);
    expect(boardRect(), initial,
        reason: "board moved/resized on the robot's turn");

    // Let the AI finish so no timers leak.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (game.nextPlayer == 0 && game.canClick) break;
    }
  });
}
