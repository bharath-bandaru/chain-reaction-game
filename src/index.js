import React from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./index.css";
import { ToastContainer, toast, Slide } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
const MyPromise = window.Promise;
const confetti = require('canvas-confetti');
confetti.Promise = MyPromise;

const notify = (message) => toast(message);
const Player = ({ state, color, max, hints }) => {
    return (
        <>
            {
                <div className='container'>
                    <div className='anim hide atom'>
                        <div className="nucleus"></div>
                        <div className="nucleus"></div>
                        <div className="nucleus"></div>
                        <div className="nucleus"></div>
                    </div>
                    <div className="atom" style={{ backgroundColor: color }}>
                        {(state === 0) &&
                            <>
                                {/* <div className="nucleus"></div> */}
                                {
                                    (max === 1 && hints) &&
                                    <>
                                        {/* <div className="electron1"></div> */}
                                    </>
                                }
                            </>
                        }
                        {(state === 1) &&
                            <>
                                <div className="nucleus"></div>
                                {
                                    (max === 1 && hints) &&
                                    <>
                                        {/* <div className="electron1"></div> */}
                                    </>
                                }
                            </>
                        }
                        {(state === 2) &&
                            <>
                                <div className="nucleus2"></div>
                                <div className="nucleus"></div>
                                {
                                    (max === 2 && hints) &&
                                    <>
                                        {/* <div className="electron2"></div> */}
                                    </>
                                }
                            </>
                        }
                        {(state >= 3) &&
                            <>
                                <div className="nucleus2" ></div>
                                <div className="nucleus3"></div>
                                <div className="nucleus"></div>
                                {(max === 3 && hints) &&
                                    <>
                                        {/* <div className="electron3"></div> */}
                                    </>
                                }

                            </>
                        }
                    </div>
                </div>
            }
        </>
    );
}

const Square = ({ id, value, max, hints, onClick, canClick }) => {
    // console.log("Square props: ", id);
    return (
        <button className="square" id={id} onClick={onClick} disabled={!canClick}>
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
    var board_x = 9, board_y = 6;
    var squaresArray = Array.from({ length: board_x }, _ => new Array(board_y).fill(null));
    const [squares, setSquares] = useState(Object.assign({}, squaresArray.map(a => Object.assign({}, a))));
    const [player_n, setNoPlayer] = useState(2);
    var curr_player = 0;
    const [next_player, setNextPlayer] = useState(curr_player);
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
            console.log("play css", i, j, prev)
            var anim_ele = document.getElementById(i + "_" + j).children[0].children[0];
            var atom = document.getElementById(i + "_" + j).children[0].children[1];
            var elements = anim_ele.children;
            elements = removeAniClass(elements);
            var colors = [];
            atom.style.backgroundColor = player_color[curr_player]
            anim_ele.style.backgroundColor = player_color[curr_player]
            anim_ele.style.zIndex = num_steps
            anim_ele.classList.remove("hide");
            atom.classList.add("hide");
            switch (prev.state) {
                case 1:
                    if (i === 0 && j === 0) colors = ["left", "top"];
                    else if (i === board_x - 1 && j === 0) colors = ["left", "bottom"];
                    else if (i === 0 && j === board_y - 1) colors = ["right", "top"];
                    else if (i === board_x - 1 && j === board_y - 1) colors = ["right", "bottom"];

                    //console.log("in play css", i, j, prev, elements)

                    elements[0].classList.add(colors[0]);
                    elements[1].classList.add(colors[1]);
                    await timer(400);
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
                    await timer(400);
                    break;
                case 3:
                    //console.log("in play css", i, j, prev, elements)

                    elements[0].classList.add("right");
                    elements[1].classList.add("left");
                    elements[2].classList.add("bottom");
                    elements[3].classList.add("top");
                    await timer(400);
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
        setCanClick(true);
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


    const checkGame = () => {
        if (num_steps >= player_n) {
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

            if (gameOverFlag) {
                gameOver = true;
                playConfetti();
                restartGame();
                // alert("🎯Game Over. " + player_color_names[next_player] + " won! 🎮");
                notify("🎯 Game Over. " + player_color_names[next_player] + " won! 🎯")

            } else {
                for (i = 0; i < player_n; i++) {
                    if (currLoserState[i] !== loser[i] && currLoserState[i] === true) {
                        // alert("🫠 " + player_color_names[i] + " lost.");
                        notify("🫠 " + player_color_names[i] + " lost.")
                        loser[i] = currLoserState[i];
                        if (next_player === i) {
                            checkNextPlayer();
                        }
                    }
                }
                setLoser(currLoserState);
            }
        }
    };

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
    const handleClick = async (i, j, isInit) => {

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
        if (!gameOver) checkGame();
    }

    const checkNextPlayer = () => {
        var nextP = curr_player < player_n - 1 ? curr_player + 1 : 0;
        if (num_steps < player_n) setNextPlayer(nextP)

        while (num_steps >= player_n) {
            if (!loser[nextP]) {
                setNextPlayer(nextP);
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
                onClick={async () => {
                    curr_player = next_player;
                    if (squares[i][j] != null && squares[i][j].player !== curr_player) return;
                    if (num_steps === 0) {
                        gameOver = false;
                    }
                    await handleClick(i, j, true);
                    checkNextPlayer();
                }}
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
        setNextPlayer(0);
        setLoser(Array(player_n).fill(false));
        setSquares(Object.assign({}, squaresArray.map(a => Object.assign({}, a))));
    }
    const shareGame = () => {
        navigator.clipboard.writeText("Here is the link to play chain reaction 💣: 'https://bharath-bandaru.github.io/chain-reaction-game/'");
    }

    return (
        <>
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">

                <div className="game" style={{ color: player_color[next_player] }} id="game">
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
                                                {(index < player_n && index !== next_player) &&
                                                    <div className="dot" style={{ backgroundColor: item }}></div>
                                                }

                                                {(index < player_n && index === next_player) &&
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
                        <div className='buttons'> ❤️ </div>
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