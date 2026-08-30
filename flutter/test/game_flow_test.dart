import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chain_reaction/app.dart';
import 'package:chain_reaction/logic/game_controller.dart';
import 'package:chain_reaction/services/firebase_service.dart';
import 'package:chain_reaction/services/preferences_service.dart';
import 'package:chain_reaction/ui/widgets/sheets/online_sheet.dart';
import 'package:provider/provider.dart';

/// Full UI flow tests running offline (Firebase not initialized — the
/// service no-ops, exactly like playing with no connection).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ChainReactionApp> buildApp() async {
    SharedPreferences.setMockInitialValues({});
    return ChainReactionApp(
      firebase: FirebaseService(),
      prefs: await PreferencesService.load(),
    );
  }

  GameController controllerOf(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first).read<GameController>();

  Future<void> tapCell(WidgetTester tester, int i, int j) async {
    await tester.tap(find.byKey(ValueKey('cell_${i}_$j')));
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// The default 800x600 test surface has shortestSide == 600, which trips
  /// the tablet layout. Sheet tests assume the phone layout, so they pin a
  /// phone-sized surface.
  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renders the 9x6 board with header and footer',
      (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();

    expect(find.byKey(const ValueKey('cell_0_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cell_8_5')), findsOneWidget);
    expect(find.text('Chain Reaction'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('🚀'), findsOneWidget);
  });

  testWidgets('placing orbs alternates turns and explodes at critical mass',
      (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    // Player 0 takes the corner.
    await tapCell(tester, 0, 0);
    expect(game.board[0][0]!.player, 0);
    expect(game.board[0][0]!.state, 1);
    expect(game.nextPlayer, 1);

    // Player 1 plays far away.
    await tapCell(tester, 8, 5);
    expect(game.board[8][5]!.player, 1);
    expect(game.nextPlayer, 0);

    // Player 0 taps the corner again: critical mass (1) exceeded, the cell
    // explodes into (0,1) and (1,0).
    await tapCell(tester, 0, 0);
    await tester.pump(const Duration(milliseconds: 600));

    expect(game.board[0][0], isNull);
    expect(game.board[0][1]!.player, 0);
    expect(game.board[1][0]!.player, 0);
    expect(game.nextPlayer, 1);
  });

  testWidgets('tapping an opponent cell is rejected', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    await tapCell(tester, 4, 3);
    expect(game.nextPlayer, 1);

    // Player 1 tries to steal player 0's cell — nothing happens.
    await tapCell(tester, 4, 3);
    expect(game.board[4][3]!.state, 1);
    expect(game.board[4][3]!.player, 0);
    expect(game.nextPlayer, 1);
  });

  testWidgets('undo restores the previous position', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    await tapCell(tester, 0, 0);
    await tapCell(tester, 8, 5);
    expect(game.canUndo, isTrue);

    game.undoMove();
    await tester.pump();
    expect(game.board[8][5], isNull);
    expect(game.nextPlayer, 1);
  });

  testWidgets('winning by capturing every opponent orb shows the win screen',
      (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    // P0 corner, P1 adjacent edge cell; P0 explodes the corner and captures
    // P1's only orb -> game over, win overlay.
    await tapCell(tester, 0, 0);
    await tapCell(tester, 0, 1);
    await tapCell(tester, 0, 0);
    // Let explosion waves + game-over handling finish.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(game.gameOver, isTrue);
    expect(game.showIWon, isTrue);
    expect(game.wonStatus, isTrue);
    expect(game.titleMessage, 'restart');

    // Restart via the footer button brings back a clean board.
    game.restartGame();
    await tester.pump();
    expect(game.board[0][1], isNull);
    expect(game.moveCount, 0);
    expect(game.showIWon, isFalse);
  });

  testWidgets('rocket button opens the Play Online bottom sheet',
      (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(await buildApp());
    await tester.pump();

    await tester.tap(find.text('🚀'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Play Online'), findsOneWidget);
    expect(find.text('Create Room'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);
    expect(find.text('Leave Room'), findsOneWidget);

    // Not in a room: leave is disabled, join opens the code dialog.
    await tester.tap(find.text('Join Room'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Enter the room code'), findsOneWidget);
  });

  testWidgets('menu button opens the game menu bottom sheet', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    await tester.tap(find.byIcon(Icons.dashboard_customize));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Game Menu'), findsOneWidget);
    expect(find.text('Opponent'), findsOneWidget);
    // Board size is a tablet-only option.
    expect(find.text('Board Size'), findsNothing);
    expect(find.text('Move Animation'), findsOneWidget);
    expect(find.text('Undo Button'), findsOneWidget);
    expect(find.text('How to Play?'), findsOneWidget);

    // Toggling a switch updates the setting without closing the sheet.
    expect(game.showAnimation, isFalse);
    await tester.tap(find.text('Move Animation'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(game.showAnimation, isTrue);
    expect(find.text('Game Menu'), findsOneWidget);

    // Picking a difficulty only moves the selection (Medium is the default);
    // the "Play with Computer" button starts the game and collapses the
    // sheet.
    await tester.tap(find.text('Hard'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.aiPlayerIndex, isNull);
    expect(game.aiLevel, '3');

    await tester.tap(find.text('Play with Computer'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.aiPlayerIndex, 1);
    expect(game.aiLevel, '3');
    expect(find.text('Game Menu'), findsNothing);
  });

  testWidgets('changing players mid-game asks for confirmation',
      (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(await buildApp());
    await tester.pump();
    final game = controllerOf(tester);

    Future<void> settleSheet() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Before any move: no confirmation needed.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Add a player?'), findsNothing);
    expect(game.playerCount, 3);

    // Mid-game: the confirm sheet appears; cancel keeps everything.
    await tapCell(tester, 4, 3);
    await tester.tap(find.byIcon(Icons.remove));
    await settleSheet();
    expect(find.text('Remove a player?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleSheet();
    expect(game.playerCount, 3);
    expect(game.board[4][3], isNotNull);

    // Confirming restarts with the new player count.
    await tester.tap(find.byIcon(Icons.remove));
    await settleSheet();
    await tester.tap(find.text('Restart'));
    await settleSheet();
    expect(game.playerCount, 2);
    expect(game.board[4][3], isNull);
    expect(game.moveCount, 0);
  });

  testWidgets('bottom sheet renders in the floating tablet layout',
      (tester) async {
    // iPad-sized surface (shortestSide >= 600 -> tablet layout).
    tester.view.physicalSize = const Size(1640, 2360);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pump();

    await tester.tap(find.text('🚀'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Play Online'), findsOneWidget);
    // Floating sheet: capped at 500 logical pixels wide.
    final surface = tester.getSize(find.byType(OnlineSheet));
    expect(surface.width, lessThanOrEqualTo(500));
  });
}
