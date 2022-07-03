import React from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./index.css";


function Player({ state, color, max, hints }) {
    return (
        <>
            {/* <span className="dot" style={{ backgroundColor: color }}>{state}</span> */}
            {(state !== 0) &&
                <div className="atom" style={{ backgroundColor: color }}>

                    {(state >= 1) &&
                        <>
                            <div className="nucleus"></div>
                            {(max === 1 && hints) && <div className="electron1"></div>}
                        </>
                    }
                    {(state >= 2) &&
                        <>
                            <div className="nucleus2"></div>
                            {(max === 2 && hints) && <div className="electron2"></div>}
                        </>
                    }
                    {(state >= 3) &&
                        <>
                            <div className="nucleus3"></div>
                            {(max === 3 && hints) && <div className="electron3"></div>}
                        </>
                    }
                </div>
            }
        </>
    );
}

function Square({ id, value, max, hints, onClick }) {
    console.log("Square props: ", id);
    return (
        <button className="square" id={id} onClick={onClick}>
            <Player
                color={value != null ? value.color : ''}
                state={value != null ? value.state : 0}
                max={max}
                hints={hints}
            />
        </button>
    );
}

function Game() {
    var board_x = 8, board_y = 6;
    const [squares, setSquares] = useState(Array.from({ length: board_x }, _ => new Array(board_y).fill(null)));
    const [player_n, setNoPlayer] = useState(2);
    const [next_plyr, setPlayer] = useState(0);
    const [loser, setLoser] = useState(Array(player_n).fill(false));
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    const [num_steps, setNumSteps] = useState(0);
    const [hints, setHints] = useState(true);
    // var index = 0
    const chainReact = (i, j, isInit) => {
        const nextSquares = squares.slice();
        let max = (i === 0 || i === board_x - 1 || j === 0 || j === board_y - 1) ?
            (((i === 0 && j === 0)
                || (i === 0 && j === board_y - 1)
                || (j === 0 && i === board_x - 1)
                || (i === board_x - 1 && j === board_y - 1)
            ) ? 1 : 2)
            : 3;
        console.log("handleClick: ", i, j);
        if (nextSquares[i][j] == null) {
            nextSquares[i][j] = { player: next_plyr, color: player_color[next_plyr], state: 1 };
        } else if (isInit && nextSquares[i][j].state < max && nextSquares[i][j].player === next_plyr) {
            nextSquares[i][j].state += 1;
        } else if (!isInit && nextSquares[i][j].state < max) {
            nextSquares[i][j].state += 1;
            nextSquares[i][j].player = next_plyr;
            nextSquares[i][j].color = player_color[next_plyr];
        } else {
            nextSquares[i][j] = null
            setSquares(nextSquares);
            return true;
        }
        setSquares(nextSquares);
        return false;
    }

    const gameOver = (tempLoser) => {
        var flag = true;
        for (var i = 0; i < board_x; i++) {
            for (var j = 0; j < board_y; j++) {
                if (num_steps < player_n) flag = false;
                if (squares[i][j] !== null && squares[i][j].player !== next_plyr) flag = false;
                if (squares[i][j] !== null) tempLoser[squares[i][j].player] = true;
            }
        }
        return flag;
    }

    const handleClick = (i, j, isInit) => {
        if (isInit && squares[i][j] != null && squares[i][j].player !== next_plyr) return;
        setNumSteps(num_steps + 1);
        var queue = [];
        queue.push([i, j]);
        var tempLoser = Array(player_n).fill(false);
        while (queue.length > 0) {
            var [k, l] = queue.shift();
            if (chainReact(k, l, isInit)) {
                isInit = false;
                if (k - 1 >= 0) queue.push([k - 1, l]);
                if (k + 1 < board_x) queue.push([k + 1, l]);
                if (l - 1 >= 0) queue.push([k, l - 1]);
                if (l + 1 < board_y) queue.push([k, l + 1]);
            }
            tempLoser = Array(player_n).fill(false);
            if (gameOver(tempLoser)) {
                setNumSteps(0);
                alert("🎮 Game Over 🎯");
                restartGame();
                return;
            }
        }
        for (i = 0; i < player_n; i++) {
            if (tempLoser[i] !== loser[i] && tempLoser[i] === false) {
                alert("Player " + (i + 1) + " loses!");
            }
        }
        setLoser(tempLoser);
        if (num_steps < player_n) setPlayer(next_plyr < player_n - 1 ? next_plyr + 1 : 0)
        var next = next_plyr < player_n - 1 ? next_plyr + 1 : 0;
        while (num_steps >= player_n) {
            if (tempLoser[next]) {
                setPlayer(next);
                break;
            }
            next = next < player_n - 1 ? next + 1 : 0;
        }
    }

    function renderSquare(i, j, id) {
        return (
            <Square
                key={id}
                id={id}
                value={squares[i][j]}
                max={(i === 0 || i === board_x - 1 || j === 0 || j === board_y - 1) ?
                    (((i === 0 && j === 0)
                        || (i === 0 && j === board_y - 1)
                        || (j === 0 && i === board_x - 1)
                        || (i === board_x - 1 && j === board_y - 1)
                    ) ? 1 : 2)
                    : 3}
                onClick={() => {
                    handleClick(i, j, true)
                }}
                hints={hints}
            />
        );
    }
    const addPlayer = () => {
        if (player_n < 4) {
            setNoPlayer(player_n + 1);
            restartGame();
            setLoser(Array(player_n + 1).fill(false));
        }
    }
    const removePlayer = () => {
        if (player_n > 2) {
            setNoPlayer(player_n - 1);
            restartGame();
            setLoser(Array(player_n - 1).fill(false));
        }
    }
    const restartGame = () => {
        setPlayer(0);
        setNumSteps(0);
        setLoser(Array(player_n).fill(false));
        setSquares(Array.from({ length: board_x }, _ => new Array(board_y).fill(null)));
    }
    const shareGame = () => {
        navigator.clipboard.writeText("Here is the link to play chain reaction 💣: 'https://bharath-bandaru.github.io/chain-reaction-game/'");
    }

    return (
        <>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">

                <div className="game" style={{ color: player_color[next_plyr] }} id="game">
                    <div className='header'>
                        <span className="material-icons mui"> dashboard_customize </span>
                        <div>
                            <div>
                                <span className="material-icons mui" onClick={addPlayer}> add </span>
                                <span className="material-icons mui-people"> groups </span>
                                <span className="material-icons mui" onClick={removePlayer}> remove </span>
                            </div>
                            <div>
                                {
                                    player_color.map((item, index) => {
                                        return (
                                            <>
                                                {(index < player_n && index !== next_plyr) &&
                                                    <div className="dot" style={{ backgroundColor: item }}></div>
                                                }

                                                {(index < player_n && index === next_plyr) &&
                                                    <div className="dot" style={{ backgroundColor: item, border: "solid #fff" }}></div>
                                                }
                                            </>
                                        )
                                    }
                                    )
                                }
                            </div>
                        </div>
                        <span className="material-icons mui" onClick={restartGame}> cached </span>
                    </div>
                    {
                        squares.map((row, i) => {
                            return (
                                <div className='row' id={i}>
                                    {
                                        row.map((col, j) => {
                                            return (
                                                renderSquare(i, j, i + "_" + j)
                                            );
                                        })
                                    }
                                </div>
                            );
                        })
                    }
                    <div className='footer'>
                        <div className='buttons'> ❤️ </div>
                        <h3>chain reaction</h3>
                        <div className='buttons tooltip' onClick={shareGame}>🚀 </div>
                    </div>
                </div>
            </div>
        </>
    );
}
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Game />);