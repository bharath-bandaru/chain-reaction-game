/// A single occupied board cell: which player owns it and how many orbs
/// (`state`, 1..3) it currently holds. Empty cells are represented as `null`
/// inside the board matrix, matching the React implementation.
class Cell {
  Cell({required this.player, required this.state});

  int player;
  int state;

  Cell copy() => Cell(player: player, state: state);
}

/// A full board: `rows x cols` matrix of nullable cells.
typedef Board = List<List<Cell?>>;

/// Creates an empty [rows] x [cols] board.
Board emptyBoard(int rows, int cols) =>
    List.generate(rows, (_) => List<Cell?>.filled(cols, null));

/// Deep copy of a board (used for undo history and AI simulations).
Board copyBoard(Board board) => [
      for (final row in board) [for (final cell in row) cell?.copy()],
    ];

/// Critical mass of cell (i, j): 1 for corners, 2 for edges, 3 for inner
/// cells. A cell explodes when an orb is added while it is already at its
/// critical mass.
int maxStateFor(int i, int j, int rows, int cols) {
  final onRowEdge = i == 0 || i == rows - 1;
  final onColEdge = j == 0 || j == cols - 1;
  if (onRowEdge && onColEdge) return 1;
  if (onRowEdge || onColEdge) return 2;
  return 3;
}
