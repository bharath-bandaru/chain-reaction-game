import React, { useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./css/index.css";
import { ToastContainer, toast, Slide } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import {
    Menu,
    MenuDivider,
    MenuItem,
    MenuRadioGroup
} from '@szhsin/react-menu';
import '@szhsin/react-menu/dist/index.css';
import '@szhsin/react-menu/dist/transitions/slide.css';
import "@szhsin/react-menu/dist/theme-dark.css";
import { signIn, localuser, database, analytics } from './components/firebase';
import { child, get, onDisconnect, onValue, ref, remove, set } from "firebase/database";
import { logEvent } from 'firebase/analytics';
import { v4 as uuidv4 } from 'uuid';
import { Square } from './components/Square';
import { HowToPlay } from './components/HowToPlay';
import { IWon } from './components/IWon';

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

const Game = () => {
    const [board_x, setBoardX] = useState(9);
    const [board_y, setBoardY] = useState(6);
    var squaresArray = Array.from({ length: board_x }, _ => new Array(board_y).fill(null));
    const initialArray = squaresArray.map(a => Object.assign({}, a)).map(a => Object.assign({}, a));
    const [squares, setSquares] = useState({ ...initialArray });
    const [player_n, setNoPlayer] = useState({ n: 2 });
    const [curr_player, setCurrentPlayer] = useState({ player: 0 });
    const [next_player, setNextPlayer] = useState({ player: 0 });
    const [loser, setLoser] = useState(Array(player_n.n).fill(false));
    const [main_player, setMainPlayer] = useState({ player: 0 });
    var gameOver = false;
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    const player_color_names = ["Blue", "Pink", "Green", "Red"];
    const [numSteps, setNumSteps] = useState({ n: 0 });
    var hints = useState(true);
    const [canClick, setCanClick] = useState(true);
    const [isLive, setIsLive] = useState({ live: false });
    const [title_message, setTitleMessage] = useState("chain reaction");
    const [isLoading, setIsLoading] = useState(false);
    const [isMainLoading, setIsMainLoading] = useState(false);
    const [showHowToPlay, setShowHowToPlay] = useState(false);
    const [howState, setHowState] = useState(0);
    const [code, setCode] = useState('••••');
    const [showIwon, setShowIwon] = useState(false);
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

    const checkGameOver = async () => {
        if (numSteps.n >= player_n.n) {
            var state = loopAllStates();
            var gameOverFlag = state[0];
            if (gameOverFlag) {
                setCanClick(false);
                gameOver = true;
                if (isLive.live && curr_player.player !== main_player.player) {
                    setShowIwon(true);
                    await timer(5000);
                    setShowIwon(false);
                } else {
                    gameOverNotify("Game over! " + player_color_names[curr_player.player] + " won. 🎮")
                    playConfetti();
                }
            }
        }
    };

    const checkPlayerState = () => {
        if (!gameOver && numSteps.n >= player_n.n) {
            var currLoserState = loser;
            var state = loopAllStates();
            currLoserState = state[1];
            for (var i = 0; i < player_n.n; i++) {
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
        var currLoserState = Array(player_n.n).fill(true);
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
    const [boardOptions, setBoardOptions] = useState({});

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
        setNumSteps({ n: 0 });
        setNextPlayer({ player: 0 });
        setLoser(Array(player_n.n).fill(false));
        setCurrentPlayer({ player: 0 });
    }, [box_size, player_n.n]);

    const stopwatch = async () => {
        interval = setInterval(startInterval, 450);
    }

    useEffect(() => {
        setUUID(uuidv4());
        signIn();
        const { innerWidth: width, innerHeight: height } = window;
        if (height < 663 || width < 572) {
            setBoardOptions({
                "0": "6 x 9"
            })
        } else {
            setBoardOptions({
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
        var nextP = curr_player.player < player_n.n - 1 ? curr_player.player + 1 : 0;
        var np = next_player;
        if (numSteps.n < player_n.n) {
            next_player.player = nextP;
            setNextPlayer({ ...np });
        }
        while (numSteps.n >= player_n.n) {
            if (!loser[nextP]) {
                np = next_player;
                next_player.player = nextP;
                setNextPlayer({ ...np });
                break;
            }
            nextP = nextP < player_n.n - 1 ? nextP + 1 : 0;
        }
    }

    const onClickSquare = async (i, j, isCloud) => {
        console.log(numSteps.n)
        var curr = curr_player;
        curr.player = next_player.player;
        setCurrentPlayer(curr);
        if (squares[i][j] != null && squares[i][j].player !== curr.player) return;
        if (!isLive.live) {
            if (numSteps.n === 0) {
                gameOver = false;
            }
            handleClick(i, j, true,);
            return;
        }

        var hookRef = ref(database, 'hooks/' + code);
        if (!isCloud) {
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
                    if (isLive.live && next_player.player !== main_player.player) return;
                    onClickSquare(i, j, false);
                }}
                currrentPlayer={next_player.player}
                hints={hints}
                mainPLayer={main_player.player}
                isLive={isLive.live}
                canClick={canClick}
            />
        );
    }

    const addPlayer = () => {
        if (player_n.n < 4) {
            var n = player_n;
            n.n += 1;
            setNoPlayer({ ...n });
            restartGame();
            setLoser(Array(player_n.n + 1).fill(false));
        }
    }

    const removePlayer = () => {
        if (player_n.n > 2) {
            var n = player_n;
            n.n -= 1;
            setNoPlayer({ ...n });
            restartGame();
            setLoser(Array(player_n.n - 1).fill(false));
        }
    }

    const restartGame = (isCloud) => {
        if (!isCloud && isLive.live) {
            set(ref(database, 'hooks/' + code), {
                move: {
                    i: -1,
                    j: -1
                }
            });
            return;
        }
        setCurrentPlayer({ ...curr_player, player: 0 });
        setCanClick(true);
        var nStep = numSteps;
        nStep.n = 0;
        setNumSteps(nStep);
        setNextPlayer({ ...next_player, player: 0 });
        setLoser(Array(player_n.n).fill(false));
        setShowHowToPlay(false);
        setTitleMessage("chain reaction");
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
        if (groupID) {
            var liveStatus = isLive;
            liveStatus.live = true;
            setIsLive({ ...liveStatus });
            connectToRoom(groupID);
        }
    }


    const createRoom = () => {
        var liveStatus = isLive;
        liveStatus.live = true;
        setIsLive({ ...liveStatus });
        setCanClick(false);
        var n = player_n;
        n.n = 1;
        setNoPlayer({ ...n });
        setTitleMessage("start");
        getNewRoom(localuser);
        var mainP = main_player;
        mainP.player = 0;
        setMainPlayer({ ...mainP });
        setIsLoading(true);
    }

    const waitForPlayers = async (groupID) => {
        var hookRef = ref(database, 'hooks/' + groupID);
        var onlineGroupRef = ref(database, 'online/' + groupID)
        onValue(onlineGroupRef, (snapshot) => {
            let color = ["🔵", "🟣", "🟡", "🔴"]
            const data = snapshot.val();
            var n = data.n;
            var noOfplayers = player_n;
            noOfplayers.n = n;
            setNoPlayer({ ...noOfplayers });
            if (data.status === 'started') {
                setIsMainLoading(false);
                setTitleMessage("chain reaction");
                setCanClick(true);
                setShowHowToPlay(false);
                setIsLoading(false);
            } else if (n > 1) {
                setIsLoading(false);
                notify(color[n - 1] + " player added");
                setIsMainLoading(true);
            }
        });

        onValue(hookRef, (snapshot) => {
            const data = snapshot.val();
            if (data.move != null && data.move.i < 0 && data.move.j < 0) {
                setSquares({ ...initialArray });
                restartGame(true);
            } else if (data.move != null) {
                onClickSquare(data.move.i, data.move.j, true);
            }
        });

        var restartRef = ref(database, 'restartHook/' + groupID);
        onValue(restartRef, (snapshot) => {
            const shouldRestart = snapshot.val();
            if (shouldRestart) {
                setSquares({ ...initialArray });
                restartGame(true);
            }
        });
    }

    const leaveRoom = () => {
        var liveStatus = isLive;
        liveStatus.live = false;
        setIsLive({ ...liveStatus });
        var noOfplayers = player_n;
        noOfplayers.n = 2;
        setNoPlayer({ ...noOfplayers });
        setIsMainLoading(false);
        setIsLoading(false);
        setTitleMessage("chain reaction");
        restartGame();
    }

    const disConnectFlow = (disconnectRef) => {
        onValue(disconnectRef, (snapshot) => {
            const val = snapshot.val();
            if (val === true) {
                notify("player left");
                setIsMainLoading(true);
                setCanClick(false);
                setTitleMessage("Leave Room")
            }
        });
        onDisconnect(disconnectRef).set(true);
    }

    const connectToRoom = (groupID) => {
        var onlineGroupRef = ref(database, 'online/' + groupID)
        get(onlineGroupRef).then((snapshot) => {
            if (snapshot.exists()) {
                const group = snapshot.val();
                if (group.n > 4) {
                    notify("Room is full");
                } else {
                    if (!group.players.includes(localuser.uid)) {
                        set(onlineGroupRef, {
                            ...group,
                            n: group.n + 1,
                            players: [...group.players, localuser.uid]
                        }).then(() => {
                            setCode(groupID);
                            var liveStatus = isLive;
                            liveStatus.live = true;
                            setIsLive({ ...liveStatus });
                            setCanClick(false);
                            var noOfplayers = player_n;
                            noOfplayers.n = group.n;
                            setNoPlayer({ ...noOfplayers });
                            setTitleMessage("chain reaction");
                            var mainP = main_player;
                            mainP.player = group.n;
                            setMainPlayer({ ...mainP });
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
                        var disRef = ref(database, 'disconnectHook/' + groupID)
                        set(disRef, false).then(() => {
                            disConnectFlow(disRef);
                        });
                    } else {
                        get(child(ref(database), 'players/' + localuser.uid)).then((snapshot) => {
                            var data = snapshot.val();
                            console.log("sadasdasd", data);
                            setCode(groupID);
                            var liveStatus = isLive;
                            liveStatus.live = true;
                            setIsLive({ ...liveStatus });
                            setCanClick(false);
                            var noOfplayers = player_n;
                            noOfplayers.n = group.n - 1;
                            setNoPlayer({ ...noOfplayers });
                            setTitleMessage("chain reaction");
                            var mainP = main_player;
                            mainP.player = group?.players?.indexOf(localuser.uid);
                            setMainPlayer({ ...mainP });
                            if (group?.players?.indexOf(localuser.uid) === 0) {
                                setTitleMessage("start")
                            }
                            setIsLoading(true);
                            var hookRef = ref(database, 'hooks/' + groupID);
                            get(hookRef).then((snapshot) => {
                                waitForPlayers(groupID);
                                var disRef = ref(database, 'disconnectHook/' + groupID);
                                set(disRef, false).then(() => {
                                    disConnectFlow(disRef);
                                });
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
        get(child(ref(database), `groups`)).then((snapshot) => {
            if (snapshot.exists()) {
                const groups = snapshot.val();
                if (groups.count > 1) {
                    const key = Object.keys(groups).filter(key => key !== 'count')[0];
                    var keyref = ref(database, 'groups/' + key);
                    remove(keyref);

                    set(ref(database, 'groups/count'), groups.count - 1)
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
                        var mainP = main_player;
                        mainP.player = 0;
                        setMainPlayer({ ...mainP });
                        var hookRef = ref(database, 'hooks/' + key);
                        set(hookRef, {
                            move: null,
                            nextPlayer: curr_player
                        }).then(() => {
                            waitForPlayers(key);
                            console.log("Data saved successfully!");
                            setCode(key);
                        }).catch(error => {
                            console.log(error);
                        });
                        var disRef = ref(database, 'disconnectHook/' + key)
                        set(disRef, false).then(() => {
                            disConnectFlow(disRef);
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
        get(ref(database, 'likes')).then((snapshot) => {
            set(ref(database, 'likes'), snapshot.val() + 1);
        });
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
        set(ref(database, 'online/' + code + '/status'), 'started')
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
        } else if (title_message === "next") {
            switch (howState) {
                case 0:
                    setShowHowToPlay(true);
                    setHowState(1);
                    break;
                case 1:
                    setShowHowToPlay(true);
                    setHowState(2);
                    break;
                case 2:
                    setShowHowToPlay(true);
                    setHowState(3);
                    break;
                case 3:
                    setShowHowToPlay(true);
                    setHowState(4);
                    break;
                default:
                    setShowHowToPlay(false);
                    setHowState(0);
                    setTitleMessage("chain reaction");
                    console.log("howState: ", howState);
                    break;
            }
        } else if (title_message === "Leave Room") {
            leaveRoom();
            setTitleMessage("chain reaction");
        }
    }

    return (
        <>
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">
                {
                    (showIwon) &&
                    <IWon />
                }
                {
                    (showHowToPlay)
                    &&
                    <HowToPlay
                        state={howState}
                    />
                }
                {
                    (isMainLoading)
                    &&
                    <div className='loader-center-div'>
                        <div className="loader-center loading"></div>
                    </div>
                }
                <div className="game" style={{ color: player_color[next_player.player] }} id="game">
                    <div className='header'>
                        <div>
                            <Menu menuButton={<span className="material-icons mui noselect"> dashboard_customize </span>} theming={"dark"}>
                                {
                                    (!isLive.live) &&
                                    <>
                                        <MenuRadioGroup value={box_size}
                                            onRadioChange={e => setBoxSize(e.value)}>
                                            <span style={{ fontWeight: "bold", paddingBottom: "20px" }}>Available Boards</span>
                                            <>
                                                {
                                                    Object.entries(boardOptions).map(([key, val]) => {
                                                        return (<MenuItem type="radio" value={key}>{val}</MenuItem>)
                                                    })
                                                }
                                            </>
                                        </MenuRadioGroup>
                                        <MenuDivider />
                                    </>
                                }
                                <MenuItem
                                    onClick={() => {
                                        setShowHowToPlay(true);
                                        setTitleMessage("next");
                                    }}>
                                    <span >How to Play</span>
                                </MenuItem>
                            </Menu>
                        </div>
                        <div style={{ zIndex: 100 }}>
                            {
                                !isLive.live &&
                                <div>
                                    <span className="material-icons mui noselect" onClick={addPlayer}> add </span>
                                    <span className="material-icons mui-people noselect"> groups </span>
                                    <span className="material-icons mui noselect" onClick={removePlayer}> remove </span>
                                </div>
                            }
                            {
                                isLive.live &&
                                <div className='flex' style={{ paddingBottom: "6px", paddingTop: "4px" }}>
                                    <span className="live-code">{code}</span>
                                    <span className="material-icons mui pl-5 f-23 noselect"> content_copy </span>
                                </div>
                            }
                            {
                                <div>
                                    {
                                        player_color.map((item, index) => {
                                            return (
                                                <>
                                                    {(index < player_n.n && index !== next_player.player) &&
                                                        <div className="dot" style={{ backgroundColor: item }}></div>
                                                    }

                                                    {(index < player_n.n && index === next_player.player) &&
                                                        <div className="dot" style={{ backgroundColor: item, border: "solid #fff" }}></div>
                                                    }
                                                </>
                                            )
                                        }
                                        )
                                    }
                                </div>
                            }
                        </div>
                        <span className="material-icons mui noselect" onClick={() => { restartGame() }}> cached </span>
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
                        <div id='like-button' onClick={likeButton} className='buttons like noselect'> <span>❤️</span> </div>
                        {(!isLoading && (title_message === 'start' || title_message === 'chain reaction')) &&
                            <h3 id='title' className={(title_message === "start") ? 'title-button cursor-pointer noselect' : 'cursor-pointer noselect'} onClick={() => onClickTitle()}>{title_message}</h3>}
                        {!isMainLoading && (title_message === 'waiting' || isLoading) && <div style={{ margin: "26px" }} className="loading"></div>}
                        {!isMainLoading && (title_message === 'next') &&
                            <h3 className='title-y-button cursor-pointer noselect'
                                onClick={onClickTitle}>{title_message}
                            </h3>}
                        {title_message === "Leave Room" &&
                            <h3 className='title-button cursor-pointer noselect'
                                onClick={onClickTitle}>{title_message}
                            </h3>
                        }
                        <div style={{ zIndex: '101' }}>
                            <Menu menuButton={<div className='buttons tooltip noselect'>🚀</div>} theming={"dark"}>
                                <MenuItem onClick={() => joinRoom()} disabled={isLive.live}>Join Room</MenuItem>
                                <MenuItem onClick={() => createRoom()} disabled={isLive.live}>Create Room</MenuItem>
                                <MenuItem onClick={() => leaveRoom()} disabled={!isLive.live}>Leave Room</MenuItem>
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
            <div></div>
        </>
    );
}
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Game />);