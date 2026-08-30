import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:chain_reaction/logic/ai/minimax_ai.dart';
import 'package:chain_reaction/models/cell.dart';

void main() {
  group('board rules', () {
    test('critical mass is 1 for corners, 2 for edges, 3 for inner cells',
        () {
      expect(maxStateFor(0, 0, 9, 6), 1);
      expect(maxStateFor(8, 5, 9, 6), 1);
      expect(maxStateFor(0, 3, 9, 6), 2);
      expect(maxStateFor(4, 0, 9, 6), 2);
      expect(maxStateFor(4, 3, 9, 6), 3);
    });
  });

  group('minimax AI', () {
    List<List<int>> board(int rows, int cols) =>
        List.generate(rows, (_) => List.filled(cols, 0));

    test('returns a valid move on an empty board', () {
      final move = findBestMove({'board': board(9, 6), 'level': '1'});
      expect(move, isNotNull);
      expect(move![0], inInclusiveRange(0, 8));
      expect(move[1], inInclusiveRange(0, 5));
    });

    test('never picks a cell owned by the opponent', () {
      final b = board(9, 6);
      // Opponent (player 0) occupies (4, 3) with 2 orbs.
      b[4][3] = encodeCell(0, 2);
      for (var i = 0; i < 20; i++) {
        final move = findBestMove({'board': b, 'level': '2'});
        expect(move, isNot(equals([4, 3])));
      }
    });

    test('takes an immediately winning capture', () {
      final b = board(9, 6);
      // AI orb in the corner next to the opponent's last remaining orb:
      // exploding the corner captures it and wins.
      b[0][0] = encodeCell(1, 1);
      b[0][1] = encodeCell(0, 1);
      final move = findBestMove({'board': b, 'level': '3'});
      expect(move, equals([0, 0]));
    });

    test('answers within the time budget even on a dense 10x10 board', () {
      // Worst case for search cost: the big board, near-critical everywhere,
      // deepest difficulty. The wall-clock budget must keep the response
      // under ~3.5s regardless.
      final rng = Random(5);
      final b = [
        for (var i = 0; i < 10; i++)
          [
            for (var j = 0; j < 10; j++)
              encodeCell(rng.nextInt(2), maxStateFor(i, j, 10, 10)),
          ],
      ];
      final stopwatch = Stopwatch()..start();
      final move = findBestMove({'board': b, 'level': '5'});
      stopwatch.stop();
      expect(move, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(4500),
          reason: 'AI exceeded its response-time budget');
    });
  });
}
