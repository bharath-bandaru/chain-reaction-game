const convertBoardToArray = (board) => {
  let boardArray = [];
  let rows = Object.keys(board).length;
  let cols = Object.keys(board[0]).length;
  for (let i = 0; i < rows; i++) {
    boardArray.push([]);
    for (let j = 0; j < cols; j++) {
      boardArray[i].push(board[i][j]);
    }
  }
  return boardArray;
}

const getMaxState = (i, j, board) => {
  let rows = Object.keys(board).length;
  let cols = Object.keys(board[0]).length;
  let maxState = 0;
  if (i === 0 || i === rows - 1) {
    if (j === 0 || j === cols - 1) {
      maxState = 1;
    } else if (j === 1 || j === cols - 2) {
      maxState = 2;
    } else {
      maxState = 3;
    }
  } else if (i === 1 || i === rows - 2) {
    if (j === 0 || j === cols - 1) {
      maxState = 2;
    } else {
      maxState = 3;
    }
  } else {
    maxState = 3;
  }
  return maxState;
}

const getAvailableMoves = (board) => {
  board = convertBoardToArray(board);
  let availableMoves = [];
  let rows = board.length;
  let cols = board[0].length;

  for (let i = 0; i < rows; i++) {
    for (let j = 0; j < cols; j++) {
      if (board[i][j] !== null && board[i][j].player !== 1) {
        for (let x = Math.max(0, i - 2); x <= Math.min(rows - 1, i + 2); x++) {
          for (let y = Math.max(0, j - 2); y <= Math.min(cols - 1, j + 2); y++) {
            let maxState = getMaxState(x, y, board);
            if (board[x][y] === null || (board[x][y].player === 1 && board[x][y].state < maxState)) {
              availableMoves.push([x, y]);
            }
          }
        }
      }
    }
  }
  return availableMoves;
}

const makeMove = (board, move) => {
  let newBoard = JSON.parse(JSON.stringify(board));
  let i = move[0];
  let j = move[1];
  let maxState = getMaxState(i, j, newBoard);
  if (newBoard[i][j] === null) {
    newBoard[i][j] = { player: 1, color: "#CD00C5", state: 1 };
  } else if (newBoard[i][j].player === 1 && newBoard[i][j].state < maxState) {
    newBoard[i][j].state += 1;
  }
  return newBoard;
}

const evaluate = (board) => {
  let score = 0;
  let rows = board.length;
  let cols = board[0].length;
  for (let i = 0; i < rows; i++) {
    for (let j = 0; j < cols; j++) {
      if (board[i][j] !== null) {
        if (board[i][j].player === 1) {
          score += board[i][j].state;
        } else {
          score -= board[i][j].state;
        }
      }
    }
  }
  return score;
}

const minMax = (board, depth, alpha, beta, maximizingPlayer) => {
  if (depth === 0) {
    return evaluate(board);
  }

  let availableMoves = getAvailableMoves(board);

  if (maximizingPlayer) {
    let maxEval = -Infinity;
    for (let i = 0; i < availableMoves.length; i++) {
      let move = availableMoves[i];
      let newBoard = makeMove(board, move);
      let evalu = minMax(newBoard, depth - 1, alpha, beta, false);
      maxEval = Math.max(maxEval, evalu);
      alpha = Math.max(alpha, evalu);
      if (beta <= alpha) {
        break;
      }
    }
    return maxEval;
  } else {
    let minEval = Infinity;
    for (let i = 0; i < availableMoves.length; i++) {
      let move = availableMoves[i];
      let newBoard = makeMove(board, move);
      let evalu = minMax(newBoard, depth - 1, alpha, beta, true);
      minEval = Math.min(minEval, evalu);
      beta = Math.min(beta, evalu);
      if (beta <= alpha) {
        break;
      }
    }
    return minEval;
  }
}

const getNextMove = (board) => {
  board = convertBoardToArray(board);
  let bestMove = null;
  let bestValue = -Infinity;
  let availableMoves = getAvailableMoves(board);

  for (let i = 0; i < availableMoves.length; i++) {
    let move = availableMoves[i];
    let newBoard = makeMove(board, move);
    let moveValue = minMax(newBoard, 4, -Infinity, Infinity, false);
    if (moveValue > bestValue) {
      bestValue = moveValue;
      bestMove = move;
    }
  }

  return bestMove;
}

module.exports = {
  getNextMove
};