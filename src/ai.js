const aiLevels = {
  "1" : [0,1,1,1,1,1],
  "2" : [0,2,2,2],
  "3" : [1],
  "4" : [2],
  "5" : [3],
}

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

  if ((i === 0 || i === rows - 1) && (j === 0 || j === cols - 1)) {
    maxState = 1;
  } else if (i === 0 || i === rows - 1 || j === 0 || j === cols - 1) {
    maxState = 2;
  } else {
    maxState = 3;
  }

  return maxState;
}

const getAvailableMoves = (board, player) => {
  let availableMoves = [];
  for (let i = 0; i < board.length; i++) {
    for (let j = 0; j < board[i].length; j++) {
      let maxState = getMaxState(i, j, board);
      if (board[i][j] === null ||  (board[i][j].player === player && board[i][j].state <= maxState)) {
        availableMoves.push([i, j]);
      }
    }
  }
  return availableMoves;
}

const makeMove = (newBoard, move, player, isInit) => {
  let [i, j] = move;
  let board_x = newBoard.length;
  let board_y = newBoard[0].length;
  let queue = [[i, j]];

  while (queue.length > 0) {
    let nextQueue = [];
    while (queue.length > 0) {
      let [x, y] = queue.shift();
      if (chainReact(x, y, board_x, board_y, newBoard, player)) {
        newBoard[x][y] = null;
        if (x - 1 >= 0) nextQueue.push([x - 1, y]);
        if (x + 1 < board_x) nextQueue.push([x + 1, y]);
        if (y - 1 >= 0) nextQueue.push([x, y - 1]);
        if (y + 1 < board_y) nextQueue.push([x, y + 1]);
      }
    }
    queue = nextQueue;
  }
  return newBoard;
}

const chainReact = (i, j, board_x, board_y, board, player) => {
  let max = (i === 0 || i === board_x - 1 || j === 0 || j === board_y - 1) ?
    (((i === 0 && j === 0)
      || (i === 0 && j === board_y - 1)
      || (j === 0 && i === board_x - 1)
      || (i === board_x - 1 && j === board_y - 1)
    ) ? 1 : 2)
    : 3;
  if (board[i][j] === null) {
    board[i][j] = { player: player, state: 1 };
  } else if (board[i][j].state < max && board[i][j].player === player) {
    board[i][j].player = player;
    board[i][j].state += 1;
  } else if (board[i][j].state < max) {
    board[i][j].state += 1;
    board[i][j].player = player;
  } else {
    let value = evaluate(board);
    if(value === 999999 || value === -999999) return false
    return true;
  }
  return false;
}

const evaluate = (board) => {
  let score = 0;
  let rows = Object.keys(board).length;
  let cols = Object.keys(board[0]).length;
  let didWin = true;
  let didLose = true;

  for (let i = 0; i < rows; i++) {
    for (let j = 0; j < cols; j++) {
      if (board[i][j] !== null) {
        if (board[i][j].player === 1) {
          didLose = false;
          score += board[i][j].state;
        } else if (board[i][j].player === 0) {
          didWin = false;
          score -= board[i][j].state;
        }
      }
    }
  }

  if (didWin) {
    return 999999;
  } else if (didLose) {
    return -999999;
  } else {
    return score;
  }
}

const minMax = (board, depth, alpha, beta, maximizingPlayer) => {
  if (depth === 0) {
    return evaluate(board);
  }

  if (maximizingPlayer) {
    let availableMoves = getAvailableMoves(board, 1);
    let maxEval = -Infinity;
    for (let i = 0; i < availableMoves.length; i++) {
      let move = availableMoves[i];
      let newBoard = JSON.parse(JSON.stringify(board));
      newBoard = makeMove(newBoard, move, 1, false);
      let evalu = minMax(newBoard, depth - 1, alpha, beta, false);
      maxEval = Math.max(maxEval, evalu);
      alpha = Math.max(alpha, evalu);
      if (beta <= alpha) {
        break;
      }
    }
    return maxEval;
  } else {
    let availableMoves = getAvailableMoves(board, 0);
    let minEval = Infinity;
    for (let i = 0; i < availableMoves.length; i++) {
      let move = availableMoves[i];
      let newBoard = JSON.parse(JSON.stringify(board));
      newBoard = makeMove(newBoard, move, 0, false);
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

const getNextMove = (board, aiLevel) => {
  board = convertBoardToArray(board);
  let bestMove = null;
  let bestValue = -Infinity;
  let availableMoves = getAvailableMoves(board, 1);

  let bestMoves = [];
  for (let i = 0; i < availableMoves.length; i++) {
    let move = availableMoves[i];
    let newBoard = JSON.parse(JSON.stringify(board));
    newBoard = makeMove(newBoard, move, 1, true);
    let val = evaluate(newBoard);
    if (val === 999999) {
      return move;
    }
    const depths = aiLevels[aiLevel];
    let depth = depths[Math.floor(Math.random() * depths.length)];
    let moveValue = minMax(newBoard, depth, -Infinity, Infinity, false);
    if (moveValue > bestValue) {
      bestValue = moveValue;
      bestMoves = [move];
    } else if (moveValue === bestValue) {
      bestMoves.push(move);
    }
  }
  if (bestMoves.length > 0) {
    bestMove = bestMoves[Math.floor(Math.random() * bestMoves.length)];
  }
  return bestMove;
}

module.exports = {
  getNextMove
};
