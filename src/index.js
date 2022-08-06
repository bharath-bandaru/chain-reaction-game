import React, { useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./index.css";
import { ToastContainer, toast, Slide } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import {
    Menu,
    MenuItem,
    MenuRadioGroup
} from '@szhsin/react-menu';
import '@szhsin/react-menu/dist/index.css';
import '@szhsin/react-menu/dist/transitions/slide.css';
import "@szhsin/react-menu/dist/theme-dark.css";
import { signIn, localuser, database, analytics } from './firebase';
import { child, get, onValue, ref, remove, set } from "firebase/database";
import { logEvent } from 'firebase/analytics';
import { v4 as uuidv4 } from 'uuid';

const MyPromise = window.Promise;
const confetti = require('canvas-confetti');
confetti.Promise = MyPromise;
logEvent(analytics, 'notification_received');
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

const Square = ({ id, value, max, hints, currrentPlayer, onClick, canClick, isLive, mainPLayer }) => {
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    return (
        <>
            {
                <button className="square" id={id} onClick={onClick} disabled={!canClick} style={isLive?{ "color": player_color[mainPLayer] }:
                                                                                                            { "color": player_color[currrentPlayer] }}>
                    <Player
                        color={value != null ? value.color : ''}
                        state={value != null ? value.state : 0}
                        max={max}
                        hints={hints}
                    />
                </button>
            }
        </>
    );
}

const Game = () => {
    const [board_x, setBoardX] = useState(9);
    const [board_y, setBoardY] = useState(6);
    var squaresArray = Array.from({ length: board_x }, _ => new Array(board_y).fill(null));
    const initialArray = squaresArray.map(a => Object.assign({}, a)).map(a => Object.assign({}, a));
    const [squares, setSquares] = useState({ ...initialArray });
    const [player_n, setNoPlayer] = useState(2);
    const [curr_player, setCurrentPlayer] = useState({ player: 0 });
    const [next_player, setNextPlayer] = useState({ player: 0 });
    const [loser, setLoser] = useState(Array(player_n).fill(false));
    const [main_player, setMainPlayer] = useState(0);
    var gameOver = false;
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    const player_color_names = ["Blue", "Pink", "Green", "Red"];
    const [numSteps, setNumSteps] = useState({n:0});
    var hints = useState(true);
    const [canClick, setCanClick] = useState(true);
    const [isLive, setIsLive] = useState(false);
    const [title_message, setTitleMessage] = useState("chain reaction");
    const [isLoading, setIsLoading] = useState(false);
    const [isMainLoading, setIsMainLoading] = useState(false);
    const [code, setCode] = useState('••••');
    const [UUID, setUUID] = useState('');
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
            // setCanClick(false);
            var anim_ele = document.getElementById(i + "_" + j).children[0].children[0];
            var atom = document.getElementById(i + "_" + j).children[0].children[1];
            var elements = anim_ele.children;
            elements = removeAniClass(elements);
            var colors = [];
            atom.style.fill = player_color[curr_player.player]
            anim_ele.style.backgroundColor = player_color[curr_player.player]
            anim_ele.style.zIndex = 0;
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
        // if (!gameOver) setCanClick(true);
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
            squares[i][j] = { player: curr_player.player, color: player_color[curr_player.player], state: 1 };
        } else if (isInit && squares[i][j].state < max && squares[i][j].player === curr_player.player) {
            squares[i][j].state += 1;
        } else if (!isInit && squares[i][j].state < max) {
            squares[i][j].state += 1;
            squares[i][j].player = curr_player.player;
            squares[i][j].color = player_color[curr_player.player];
        } else {
            if (isInit) {
                setCanClick(false);
                clearInterval(interval);
                stopwatch();
            }
            return true;
        }
        setSquares({ ...squares, [i]: { ...squares[i], [j]: squares[i][j] } });
        if (isInit) checkNextPlayer();
        return false;
    }

    const checkGameOver = () => {
        if (numSteps.n >= player_n) {
            var state = loopAllStates();
            var gameOverFlag = state[0];
            if (gameOverFlag) {
                setCanClick(false);
                gameOver = true;
                gameOverNotify("🎯 Game Over! " + player_color_names[curr_player.player] + " won. 🎯")
                playConfetti();
            }
        }
    };

    const checkPlayerState = () => {
        if (!gameOver && numSteps.n >= player_n) {
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
                if (squares[i][j] !== null && squares[i][j].player !== curr_player.player) gameOverFlag = false;
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

    const [box_size, setBoxSize] = useState("0");
    const [boardSizes, setBoardSizes] = useState({});

    useEffect(() => {
        var squaresArray = [];
        if (box_size === "0") {
            setBoardX(9);
            setBoardY(6);
            squaresArray = Array.from({ length: 9 }, _ => new Array(6).fill(null));
            setSquares(squaresArray.map(a => Object.assign({}, a)).map(a => Object.assign({}, a)));
        } else {
            setBoardX(10);
            setBoardY(10);
            squaresArray = Array.from({ length: 10 }, _ => new Array(10).fill(null));
            setSquares(squaresArray.map(a => Object.assign({}, a)).map(a => Object.assign({}, a)));
        }
        setNumSteps({n:0});
        setNextPlayer({ player: 0 });
        setLoser(Array(player_n).fill(false));
        setCurrentPlayer({ player: 0 });
    }, [box_size, player_n]);

    const stopwatch = async () => {
        interval = setInterval(startInterval, 450);
    }

    useEffect(() => {
        setUUID(uuidv4());
        signIn();
        const { innerWidth: width, innerHeight: height } = window;
        if (height < 670 || width < 930) {
            setBoardSizes({
                "0": "6 x 9"
            })
        } else {
            setBoardSizes({
                "0": "6 x 9",
                "1": "10 x 10",
            })
        }
    }, [])

    const startInterval = async () => {
        checkPlayerState();
        if (!gameOver) {
            checkNextPlayer();
            setCanClick(true);
        }
        clearInterval(interval);
    }

    const handleClick = async (i, j, isInit) => {
        if (gameOver) return;
        var nStep = numSteps;
        nStep.n = nStep.n + 1;
        setNumSteps(nStep);
        if (chainReact(i, j, isInit)) {
            clearInterval(interval);
            stopwatch();
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
        var nextP = curr_player.player < player_n - 1 ? curr_player.player + 1 : 0;
        var np = next_player;
        if (numSteps.n < player_n) {
            next_player.player = nextP;
            setNextPlayer({ ...np });
        }
        while (numSteps.n >= player_n) {
            if (!loser[nextP]) {
                np = next_player;
                next_player.player = nextP;
                setNextPlayer({ ...np });
                break;
            }
            nextP = nextP < player_n - 1 ? nextP + 1 : 0;
        }
    }

    const onClickSquare = async (i, j, isCloud) => {
        console.log(squares)
        var curr = curr_player;
        curr.player = next_player.player;
        setCurrentPlayer(curr);
        if (squares[i][j] != null && squares[i][j].player !== curr.player) return;
        if(!isLive){
            if (numSteps.n === 0) {
                gameOver = false;
            }
            handleClick(i, j, true,);
            return;
        }
        
        var hookRef = ref(database, 'hooks/' + code);
        if(!isCloud) {
            set(hookRef, {
            move: {
                i: i,
                j: j,
            },
            nextPlayer: next_player.player,
            uuid: UUID,
            });
        }
        else {
            if (numSteps.n === 0) {
                gameOver = false;
            }
            handleClick(i, j, true,);
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
                    if(isLive && next_player.player !== main_player) return;
                    onClickSquare(i,j,false);
                }}
                currrentPlayer={next_player.player}
                hints={hints}
                mainPLayer= {main_player}
                isLive={isLive}
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

    const restartGame = (isCloud) => {
        if(!isCloud && isLive) {
            // set(ref(database, 'restartHook/' + code), true);
            set(ref(database, 'hooks/' + code), {
                move: {
                    i: -1,
                    j: -1
                }
            });
            return;
        }
        var curr = curr_player;
        curr.player = 0;
        setCurrentPlayer(curr);
        setCanClick(true);
        var nStep = numSteps;
        nStep.n = 0;
        setNumSteps(nStep);
        setNextPlayer({ player: 0 });
        setLoser(Array(player_n).fill(false));
        // const squaresArray = Array.from({ length: board_x }, _ => new Array(board_y).fill(null));
        // const initialArray = Object.assign({}, squaresArray.map(a => Object.assign({}, a)))
        // setSquares({ ...initialArray });
        Object.keys(squares).forEach(i => {
            Object.keys(squares[i]).forEach(j => {
                    squares[i][j] = null;
                    setSquares({ ...squares, [i]: { ...squares[i], [j]: squares[i][j] } });
                }
            )
        });
        console.log(squares);
    }

    // const shareGame = () => {
    //     signIn();
    //     navigator.clipboard.writeText("Here is the link to play chain reaction 💣: 'https://bharath-bandaru.github.io/chain-reaction-game/'");
    // }

    const joinRoom = () => {
        var groupID = prompt("Enter the room code: ");
        if(groupID){
            setIsLive(true);
            connectToRoom(groupID);
        }
    }


    const createRoom = () => {
        setIsLive(true);
        setCanClick(false);
        setNoPlayer(1);
        setTitleMessage("start");
        getNewRoom(localuser);
        setMainPlayer(0)
        setIsLoading(true);
    }

    const waitForPlayers = async (groupID) => {
        var hookRef = ref(database, 'hooks/' + groupID);
        var onlineGroupRef = ref(database, 'online/' + groupID)
        onValue(onlineGroupRef, (snapshot) => {
            let color = ["🔵", "🟣", "🟡", "🔴"]
            const data = snapshot.val();
            var n = data.n;
            setNoPlayer(n);
            if(data.status === 'started'){
                setIsMainLoading(false);
                setTitleMessage("chain reaction");
                setCanClick(true);
                setIsLoading(false);
            }else if (n > 1) {
                setIsLoading(false);
                notify(color[n-1] + " player added");
                setIsMainLoading(true);
            }
        });
         
        onValue(hookRef,(snapshot) => {
            const data = snapshot.val();
            if(data.move != null && data.move.i < 0 && data.move.j < 0){
                setSquares({ ...initialArray });
                restartGame(true);
            }else if(data.move != null){
                onClickSquare(data.move.i, data.move.j, true);
            }
        });

        var restartRef = ref(database, 'restartHook/' + groupID);
        onValue(restartRef,(snapshot) => {
            const shouldRestart = snapshot.val();
            if(shouldRestart){
                setSquares({ ...initialArray});
                restartGame(true);
            }
        });
    }

    const leaveRoom = () => {
        setIsLive(false);
        setNoPlayer(2);
        setIsLoading(false);
        setTitleMessage("chain reaction");
    }

    const connectToRoom = (groupID) => {
        var onlineGroupRef = ref(database, 'online/' + groupID)
        get(onlineGroupRef).then((snapshot) => {
            if (snapshot.exists()) {
                const group = snapshot.val();
                if (group.n > 4) {
                    notify("Room is full");
                } else {
                    if(!group.players.includes(localuser.uid)){
                        set(onlineGroupRef, {
                            ...group,
                            n: group.n + 1,
                            players: [...group.players, localuser.uid]
                        }).then(() => {
                            setCode(groupID);
                            setIsLive(true);
                            setCanClick(false);
                            setNoPlayer(group.n);
                            setTitleMessage("chain reaction");
                            setMainPlayer(group.n);
                            setIsLoading(true);
                            var hookRef = ref(database, 'hooks/' + groupID);
                            get(hookRef).then((snapshot) => {
                                waitForPlayers(groupID);
                            }).catch(error => {
                                console.log(error);
                            });
                        }).catch((error) => {
                            // The write failed...
                        });
                    }else{
                        get(child(ref(database), 'players/'+localuser.uid)).then((snapshot) => {
                            setCode(groupID);
                            setIsLive(true);
                            setCanClick(false);
                            setNoPlayer(group.n-1);
                            setTitleMessage("chain reaction");
                            setMainPlayer(group.n);
                            setIsLoading(true);
                            var hookRef = ref(database, 'hooks/' + groupID);
                            get(hookRef).then((snapshot) => {
                                waitForPlayers(groupID);
                            }).catch(error => {
                                console.log(error);
                            });
                        })
                    }
                }
            }
        }).catch((error) => {
            console.error(error);
        });
    }

    const getNewRoom = (userId) => {
        get(child(ref(database), `groups1`)).then((snapshot) => {
            if (snapshot.exists()) {
                const groups = snapshot.val();
                if (groups.count > 1) {
                    const key = Object.keys(groups).filter(key => key !== 'count')[0];
                    var keyref = ref(database, 'groups1/' + key);
                    remove(keyref);

                    set(ref(database, 'groups1/count'), groups.count - 1)
                        .then(() => {
                            console.log("count updated successfully!");
                        })
                        .catch((error) => {
                            console.log("count failed!", error);
                        });
                    var onlineGroupRef = ref(database, 'online/' + key);
                    set(onlineGroupRef, {
                        players: [
                            userId.uid,
                        ],
                        n: 1,
                        status: "waiting"
                    }).then(() => {
                        setMainPlayer(0);
                        var hookRef = ref(database, 'hooks/' + key);
                        set(hookRef,{
                            move: null,
                            nextPlayer: curr_player
                        }).then(() => {
                            waitForPlayers(key);
                            console.log("Data saved successfully!");
                            setCode(key);
                        }).catch(error => {
                            console.log(error);
                        });
                    })
                }
            } else {
                console.log("No data available");
            }
        }).catch((error) => {
            console.error(error);
        });
    }

    const likeButton = async () => {
        var butt = document.getElementById("like-button");
        playConfetti();
        butt.innerHTML = '🥳';
        var t = await timer(3000);
        clearTimeout(t);
        butt.innerHTML = '❤️';
    }

    const startGame = () => {
        setIsMainLoading(false);
        setTitleMessage("chain reaction");
        setCanClick(true);
        set(ref(database, 'online/'+code+'/status'), 'started')
            .then(() => {
                console.log("count updated successfully!");
            })
            .catch((error) => {
                console.log("count failed!", error);
        });
    }

    const onClickTitle = () => {
        if (title_message === "start") {
            startGame();
        } else if (title_message === "chain reaction") {
            console.log("chain reaction");
        }
    }

    return (
        <>
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">

                {
                    isMainLoading && <div className='loader-center-div'>
                        <div className="loader-center loading"></div>
                    </div>
                }
                <div className="game" style={{ color: player_color[next_player.player] }} id="game">
                    <div className='header'>
                        <div>
                            <Menu menuButton={<span className="material-icons mui"> dashboard_customize </span>} theming={"dark"}>
                                <MenuRadioGroup value={box_size}
                                    onRadioChange={e => setBoxSize(e.value)}>
                                    <span style={{ fontWeight: "bold", paddingBottom: "20px" }}>Available Boards</span>
                                    <>
                                        {
                                            Object.entries(boardSizes).map(([key, val]) => {
                                                return (<MenuItem type="radio" value={key}>{val}</MenuItem>)
                                            })
                                        }
                                    </>
                                </MenuRadioGroup>
                            </Menu>
                        </div>
                        <div style={{ zIndex: 100 }}>
                            {
                                !isLive &&
                                <div>
                                    <span className="material-icons mui" onClick={addPlayer}> add </span>
                                    <span className="material-icons mui-people"> groups </span>
                                    <span className="material-icons mui" onClick={removePlayer}> remove </span>
                                </div>
                            }
                            {
                                isLive &&
                                <div className='flex' style={{ paddingBottom: "6px", paddingTop: "4px" }}>
                                    <span className="live-code">{code}</span>
                                    <span className="material-icons mui pl-5 f-23"> content_copy </span>
                                </div>
                            }
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
                        <span className="material-icons mui" onClick={()=>{restartGame()}}> cached </span>
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
                        {(!isLoading && (title_message === 'start' || title_message === 'chain reaction')) && <h3 id='title' className= {(title_message === "start")?'title-button cursor-pointer':'cursor-pointer'}  onClick={() => onClickTitle()}>{title_message}</h3>}
                        { !isMainLoading && (title_message === 'waiting' || isLoading) && <div style={{ margin: "26px" }} className="loading"></div>}
                        <div style={{zIndex:'101'}}>
                            <Menu menuButton={<div className='buttons tooltip'>🚀</div>} theming={"dark"}>
                                <MenuItem onClick={() => joinRoom()} disabled={isLive}>Join Room</MenuItem>
                                <MenuItem onClick={() => createRoom()} disabled={isLive}>Create Room</MenuItem>
                                <MenuItem onClick={() => leaveRoom()} disabled={!isLive}>Leave Room</MenuItem>
                            </Menu>
                        </div>
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