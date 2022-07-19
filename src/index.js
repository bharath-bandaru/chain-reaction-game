import React, { useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./index.css";
import { ToastContainer, toast, Slide } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const MyPromise = window.Promise;
const confetti = require('canvas-confetti');
confetti.Promise = MyPromise;

const notify = (message) => toast(message);
const gameOverNotify = (message) => toast(message, {
    position: "bottom-center",
    autoClose: 5000,
    hideProgressBar: false,
    closeOnClick: true,
    pauseOnHover: true,
    draggable: true,
    progress: undefined,
});
const One = () => {
    return (
        <svg style={{ "width": "18.9px", "fill": "inherit", "marginTop": "4px", "padding": "3px" }}
            viewBox="0 0 60 60"><defs>
            </defs>
            <g >
                <g>
                    <circle style={{ "fill": "inherit" }} cx="30" cy="30" r="29.5" />
                    <path style={{ "fill": "#191919" }}
                        d="M30,1c15.99,0,29,13.01,29,29s-13.01,29-29,29S1,45.99,1,30,14.01,1,30,1m0-1C13.43,0,0,13.43,0,30s13.43,30,30,30,30-13.43,30-30S46.57,0,30,0h0Z" />
                </g>
            </g>
        </svg>
    );
}

const Two = () => {
    return (
        <svg style={{ "width": "26px", "fill": "inherit", "marginTop": "4px", "padding": "3px" }}
            viewBox="0 0 82 90">
            <defs>
            </defs>
            <g>
                <g>
                    <circle cx="52" cy="60" r="29.5" />
                    <path style={{ "fill": "#191919" }} d="M52,31c15.99,0,29,13.01,29,29s-13.01,29-29,29-29-13.01-29-29,13.01-29,29-29m0-1c-16.57,0-30,13.43-30,30s13.43,30,30,30,30-13.43,30-30-13.43-30-30-30h0Z" />
                </g>
                <g>
                    <circle cx="30" cy="30" r="29.5" />
                    <path style={{ "fill": "#191919" }} d="M30,1c15.99,0,29,13.01,29,29s-13.01,29-29,29S1,45.99,1,30,14.01,1,30,1m0-1C13.43,0,0,13.43,0,30s13.43,30,30,30,30-13.43,30-30S46.57,0,30,0h0Z" />
                </g>
            </g>
        </svg>
    );
}

const Three = () => {
    return (
        <svg style={{ "width": "33px", "fill": "inherit", "marginTop": "4px", "padding": "3px" }}
            viewBox="0 0 104 90"><defs>
            </defs><g id="Layer_1-2">
                <g>
                    <circle cx="74" cy="60" r="29.5" />
                    <path style={{ "fill": "#191919" }} d="M74,31c15.99,0,29,13.01,29,29s-13.01,29-29,29-29-13.01-29-29,13.01-29,29-29m0-1c-16.57,0-30,13.43-30,30s13.43,30,30,30,30-13.43,30-30-13.43-30-30-30h0Z" />
                </g>
                <g>
                    <circle cx="30" cy="60" r="29.5" />
                    <path style={{ "fill": "#191919" }} d="M30,31c15.99,0,29,13.01,29,29s-13.01,29-29,29S1,75.99,1,60,14.01,31,30,31m0-1C13.43,30,0,43.43,0,60s13.43,30,30,30,30-13.43,30-30-13.43-30-30-30h0Z" />
                </g>
                <g>
                    <circle cx="52" cy="30" r="29.5" />
                    <path style={{ "fill": "#191919" }} d="M52,1c15.99,0,29,13.01,29,29s-13.01,29-29,29-29-13.01-29-29S36.01,1,52,1m0-1c-16.57,0-30,13.43-30,30s13.43,30,30,30,30-13.43,30-30S68.57,0,52,0h0Z" />
                </g>
            </g>
        </svg>
    );
}
const Player = ({ state, color, max, hints }) => {
    return (
        <>
            {<>
                <div className='container'>
                    <div className='anim hide atom'>
                        {
                            (max === 1) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }
                        {
                            (max === 2) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }
                        {
                            (max === 3) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }

                    </div>
                    <div style={{ fill: color }}>
                        {(state === 1) &&
                            <One />
                        }
                        {(state === 2) &&
                            <Two />
                        }
                        {(state >= 3) &&
                            <Three />
                        }
                    </div>
                </div>
            </>
            }
        </>
    );
}

const Square = ({ id, value, max, hints, currrentPlayer, onClick, canClick }) => {
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    // console.log("Square props: ", id);
    return (
        <button className="square" id={id} onClick={onClick} disabled={!canClick} style={{ "color": player_color[currrentPlayer] }}>
            <Player
                color={value != null ? value.color : ''}
                state={value != null ? value.state : 0}
                max={max}
                hints={hints}
            />
        </button>
    );
}

const Game = () => {
    var board_x = 10, board_y = 15;
    var squaresArray = Array.from({ length: board_x }, _ => new Array(board_y).fill(null));
    const [squares, setSquares] = useState(Object.assign({}, squaresArray.map(a => Object.assign({}, a))));
    const [player_n, setNoPlayer] = useState(2);
    var curr_player = 0;
    const [next_player, setNextPlayer] = useState({ player: 0 });
    const [loser, setLoser] = useState(Array(player_n).fill(false));
    var gameOver = false;
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    const player_color_names = ["Blue", "Pink", "Green", "Red"];
    const [num_steps, setNumSteps] = useState(0);
    var hints = useState(true);
    const [canClick, setCanClick] = useState(true);
    /*
        00  01  02  03  04  05
        10  11  12  13  14  15
        20  21  22  23  24  25
        30  31  32  33  34  35
        40  41  42  43  44  45
        50  51  52  53  54  55
        60  61  62  63  64  65
        70  71  72  73  74  75
    */

    const removeAniClass = (elements) => {
        for (let i = 0; i < elements.length; i++) {
            elements[i].classList.remove("left");
            elements[i].classList.remove("right");
            elements[i].classList.remove("top");
            elements[i].classList.remove("bottom");
        }
        return elements;
    }

    const playCSSAnimation = async (i, j, prev) => {
        try {
            setCanClick(false);
            var anim_ele = document.getElementById(i + "_" + j).children[0].children[0];
            var atom = document.getElementById(i + "_" + j).children[0].children[1];
            var elements = anim_ele.children;
            elements = removeAniClass(elements);
            var colors = [];
            atom.style.fill = player_color[curr_player]
            anim_ele.style.backgroundColor = player_color[curr_player]
            anim_ele.style.zIndex = num_steps
            anim_ele.classList.remove("hide");
            atom.classList.add("hide");
            var t = null;
            switch (prev.state) {
                case 1:
                    if (i === 0 && j === 0) colors = ["left", "top"];
                    else if (i === board_x - 1 && j === 0) colors = ["left", "bottom"];
                    else if (i === 0 && j === board_y - 1) colors = ["right", "top"];
                    else if (i === board_x - 1 && j === board_y - 1) colors = ["right", "bottom"];

                    //console.log("in play css", i, j, prev, elements)

                    elements[0].classList.add(colors[0]);
                    elements[1].classList.add(colors[1]);
                    t = await timer(400);
                    clearTimeout(t);
                    break;
                case 2:
                    if (j === 0) colors = ["left", "bottom", "top"];
                    else if (i === 0) colors = ["right", "left", "top"];
                    else if (i === board_x - 1) colors = ["right", "bottom", "left"];
                    else colors = ["right", "bottom", "top"];

                    //console.log("in play css", i, j, prev, elements)

                    elements[0].classList.add(colors[0]);
                    elements[1].classList.add(colors[1]);
                    elements[2].classList.add(colors[2]);
                    t = await timer(400);
                    clearTimeout(t);
                    break;
                case 3:
                    //console.log("in play css", i, j, prev, elements)

                    elements[0].classList.add("right");
                    elements[1].classList.add("left");
                    elements[2].classList.add("bottom");
                    elements[3].classList.add("top");
                    t = await timer(400);
                    clearTimeout(t);
                    break;
                default:
                    console.log("something went wrong");
            }
        }
        catch (err) {
            console.log("something went wrong", err);
        }
        anim_ele.classList.add("hide");
        atom.classList.remove("hide");
        if (!gameOver) setCanClick(true);
    }

    const timer = (ms) => new Promise(res => setTimeout(res, ms))

    const chainReact = (i, j, isInit) => {
        // const nextSquares = squares.slice();
        let max = (i === 0 || i === board_x - 1 || j === 0 || j === board_y - 1) ?
            (((i === 0 && j === 0)
                || (i === 0 && j === board_y - 1)
                || (j === 0 && i === board_x - 1)
                || (i === board_x - 1 && j === board_y - 1)
            ) ? 1 : 2)
            : 3;
        if (squares[i][j] == null) {
            squares[i][j] = { player: curr_player, color: player_color[curr_player], state: 1 };
        } else if (isInit && squares[i][j].state < max && squares[i][j].player === curr_player) {
            squares[i][j].state += 1;
        } else if (!isInit && squares[i][j].state < max) {
            squares[i][j].state += 1;
            squares[i][j].player = curr_player;
            squares[i][j].color = player_color[curr_player];
        } else {
            return true;
        }
        setSquares({ ...squares, [i]: { ...squares[i], [j]: squares[i][j] } });
        return false;
    }


    const waitAndRestartGame = async () => {
        setCanClick(false);
        var t = await timer(5000);
        clearTimeout(t);
        restartGame();
        setCanClick(true);
    }

    const checkGameOver = () => {
        if (num_steps >= player_n) {
            var state = loopAllStates();
            var gameOverFlag = state[0];
            if (gameOverFlag) {
                setCanClick(false);
                gameOver = true;
                gameOverNotify("🎯 Game Over! " + player_color_names[curr_player] + " won. 🎯")
                playConfetti();
                waitAndRestartGame();
            }
        }
    };

    const checkPlayerState = () => {
        if (!gameOver && num_steps >= player_n) {
            var currLoserState = loser;
            var state = loopAllStates();
            currLoserState = state[1];
            for (var i = 0; i < player_n; i++) {
                if (currLoserState[i] !== loser[i] && currLoserState[i] === true) {
                    notify("🫠 " + player_color_names[i] + " lost.")
                    loser[i] = currLoserState[i];
                    if (next_player.player === i) {
                        checkNextPlayer();
                    }
                }
            }
            setLoser(currLoserState);
        }
    }

    const loopAllStates = () => {
        var gameOverFlag = true;
        var currLoserState = Array(player_n).fill(true);
        for (var i = 0; i < board_x; i++) {
            for (var j = 0; j < board_y; j++) {
                // check Loser
                if (squares[i][j] !== null && squares[i][j].player !== curr_player) gameOverFlag = false;
                if (squares[i][j] !== null && currLoserState[squares[i][j].player]) {
                    currLoserState[squares[i][j].player] = false;
                }
            }
        }
        return [gameOverFlag, currLoserState];
    }

    const playConfetti = () => {
        var myCanvas = document.getElementById("confetti");
        var myConfetti = confetti.create(myCanvas, {
            resize: true,
            useWorker: true
        });
        myConfetti({
            particleCount: 100,
            spread: 160
        });
    }
    var interval;
    const stopwatch = async () => {
        interval = setInterval(startInterval, 450);
    }

    useEffect(() => {
        // clearInterval(interval);
        // stopwatch();
    }, [squares])

    const startInterval = async () => {
        checkPlayerState();
        clearInterval(interval);
    }
    const handleClick = async (i, j, isInit) => {
        clearInterval(interval);
        stopwatch();
        if (gameOver) return;
        setNumSteps(num_steps + 1);
        if (chainReact(i, j, isInit)) {
            var prev = squares[i][j];
            squares[i][j] = null;
            setSquares({ ...squares, [i]: { ...squares[i], [j]: squares[i][j] } });
            await playCSSAnimation(i, j, prev);
            if (i - 1 >= 0) handleClick(i - 1, j, false);
            if (i + 1 < board_x) handleClick(i + 1, j, false);
            if (j - 1 >= 0) handleClick(i, j - 1, false);
            if (j + 1 < board_y) handleClick(i, j + 1, false);
        }
        if (!gameOver) checkGameOver();
    }

    const checkNextPlayer = () => {
        var nextP = curr_player < player_n - 1 ? curr_player + 1 : 0;
        var np = next_player;
        if (num_steps < player_n) {
            next_player.player = nextP;
            setNextPlayer({ ...np });
        }
        while (num_steps >= player_n) {
            if (!loser[nextP]) {
                np = next_player;
                next_player.player = nextP;
                setNextPlayer({ ...np });
                break;
            }
            nextP = nextP < player_n - 1 ? nextP + 1 : 0;
        }
    }
    const renderSquare = (i, j, id, canClick) => {
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
                    curr_player = next_player.player;
                    if (squares[i][j] != null && squares[i][j].player !== curr_player) return;
                    checkNextPlayer();
                    if (num_steps === 0) {
                        gameOver = false;
                    }
                    clearInterval(interval);
                    stopwatch();
                    handleClick(i, j, true,);
                }}
                currrentPlayer={next_player.player}
                hints={hints}
                canClick={canClick}
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
        curr_player = 0;
        setCanClick(true);
        setNumSteps(0);
        setNextPlayer({ player: 0 });
        setLoser(Array(player_n).fill(false));
        setSquares(Object.assign({}, squaresArray.map(a => Object.assign({}, a))));
    }
    const shareGame = () => {
        navigator.clipboard.writeText("Here is the link to play chain reaction 💣: 'https://bharath-bandaru.github.io/chain-reaction-game/'");
    }

    const likeButton = async () => {
        var butt = document.getElementById("like-button");
        playConfetti();
        butt.innerHTML = '🥳';
        var t = await timer(3000);
        clearTimeout(t);
        butt.innerHTML = '❤️';
    }
    return (
        <>
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">
                <div className="game" style={{ color: player_color[next_player.player] }} id="game">
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
                                                {(index < player_n && index !== next_player.player) &&
                                                    <div className="dot" style={{ backgroundColor: item }}></div>
                                                }

                                                {(index < player_n && index === next_player.player) &&
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
                        Object.entries(squares).map(([i, row]) => {
                            return (
                                <div className='row' id={i}>
                                    {
                                        Object.entries(row).map(([j, value]) => {
                                            return (
                                                renderSquare(parseInt(i), parseInt(j), i + "_" + j, canClick)
                                            );
                                        })
                                    }
                                </div>
                            );

                        })

                    }
                    <div className='footer'>
                        <div id='like-button' onClick={likeButton} className='buttons like'> <span>❤️</span> </div>
                        <h3>chain reaction</h3>
                        <div className='buttons tooltip' onClick={shareGame}>🚀 </div>
                    </div>
                    <ToastContainer
                        transition={Slide}
                        hideProgressBar={true}
                        draggablePercent="60"
                        position="bottom-center"
                        closeButton={false}
                        autoClose={2000}
                    />
                    <div id='canvas' style={{ position: "absolute", bottom: "-300px" }}></div>
                </div>
            </div>
        </>
    );
}
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Game />);