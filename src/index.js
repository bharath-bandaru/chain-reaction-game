import React, { useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import { useState } from "react";
import "./css/index.css";
import "./css/robot.css";
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
// import gitsvg from './images/github.svg';
import love from './images/love.svg';
import party from './images/party.svg';
import rocket from './images/rocket.svg';
import logo from './images/logo.png';
import * as serviceWorkerRegistration from './serviceWorkerRegistration';
import { getNextMove } from './ai';

const MyPromise = window.Promise;
const confetti = require('canvas-confetti');
confetti.Promise = MyPromise;
logEvent(analytics, 'notification_received');
const notify = (message) => toast(message);

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
    const [wonStatus, setWonStatus] = useState({ won: true });
    const [showAboutMe, setShowAboutMe] = useState(false);
    const [numberOfLikes, setNumberOfLikes] = useState(null);
    const [likeIcon, setLikeIcon] = useState(love);
    const [isSafari, setIsSafari] = useState(false);
    const [aiPlayerIndex, setAiPlayerIndex] = useState();
    const [showAnimation, setShowAnimation] = useState(false);
    const [aiLevel, setAiLevel] = useState(localStorage.getItem("ai-level") || "1");


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
        if (squares[i][j] === null) {
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
        if (isInit) checkAndUpdateNextPlayer();
        return false;
    }

    const checkGameOver = async () => {
        if (numSteps.n >= player_n.n) {
            var state = loopAllStates();
            var gameOverFlag = state[0];
            if (gameOverFlag) {
                setCanClick(false);
                gameOver = true;
                if (isLive.live) {
                    var gameOverORef = ref(database, 'gameOverOnline/');
                    get(gameOverORef).then(snapshot => {
                        if (snapshot.exists) {
                            set(gameOverORef, snapshot.val() + 1);
                        }
                    });
                } else {
                    var gameOverRef = ref(database, 'gameOver/');
                    get(gameOverRef).then(snapshot => {
                        if (snapshot.exists) {
                            set(gameOverRef, snapshot.val() + 1);
                        }
                    });
                }
                var src = wonStatus;
                if (isLive.live && curr_player.player !== main_player.player) {
                    setShowIwon(true);
                    src.won = false;
                    setWonStatus({ ...src });
                    setTitleMessage("restart")
                } else if(aiPlayerIndex === 1 && curr_player.player === 1){
                    setShowIwon(true);
                    src.won = false;
                    setWonStatus({ ...src });
                    setTitleMessage("restart");
                }else {
                    if(aiPlayerIndex === 1 && curr_player.player !== 1){
                        let level = Number(aiLevel)+1;
                        playConfetti();
                        setAiLevel(level.toString());
                        localStorage.setItem("ai-level", level.toString());
                    }
                    setShowIwon(true);
                    playConfetti();
                    src.won = true;
                    setWonStatus({ ...src });
                    setTitleMessage("restart")
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
                        checkAndUpdateNextPlayer();
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
        var myCanvas = document.createElement('canvas');
        myCanvas.style.position = "absolute";
        myCanvas.style.width = "100%";
        myCanvas.style.height = "100%";
        myCanvas.style.pointerEvents = "none";
        myCanvas.style.top = "0px";
        myCanvas.style.left = "50%";
        myCanvas.style.transform = "translateX(-50%)";
        myCanvas.style.zIndex = "1001";
        document.body.appendChild(myCanvas);

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
        onValue(ref(database, 'likes'), (snapshot) => {
            setNumberOfLikes(snapshot.val());
        });
    }, [box_size, player_n.n]);

    const stopwatch = async () => {
        interval = setInterval(startInterval, 450);
    }

    const getBrowser = () => {
        if ((navigator.userAgent.indexOf("Opera") || navigator.userAgent.indexOf('OPR')) !== -1) {
            return 'opera';
        }
        else if (navigator.userAgent.indexOf("Edg") !== -1) {
            return 'edge';
        }
        else if (navigator.userAgent.indexOf("Samsung") !== -1) {
            return 'samsung';
        }
        else if (navigator.userAgent.indexOf("Chrome") !== -1) {
            return 'chrome';
        }
        else if (navigator.userAgent.indexOf("Safari") !== -1) {
            return 'safari';
        }
        else if (navigator.userAgent.indexOf("Firefox") !== -1) {
            return 'firefox';
        }
        else if ((navigator.userAgent.indexOf("MSIE") !== -1) || (!!document.documentMode === true)) //IF IE > 10
        {
            return 'ie';
        }
        else {
            return 'unknown';
        }
    }

    useEffect(() => {
        var bro = getBrowser();
        if (bro === 'safari') {
            setIsSafari(true);
        } else if (bro === 'unknown' || bro === 'ie' || bro === 'samsung') {
            alert("Make chrome as default browser and Restart the game");
        }
        setUUID(uuidv4());
        signIn();
        const { innerWidth: width, innerHeight: height } = window;
        if (height < 663 || width < 572) {
            setBoardOptions({
                "0": <p style={{paddingLeft:"5px", margin: "0", fontSize: "15px"}}>6 x 9</p>
            });
        } else {
            setBoardOptions({
                "0": <p style={{paddingLeft:"5px", margin: "0", fontSize: "15px"}}>6 x 9</p>,
                "1": <p style={{paddingLeft:"5px", margin: "0", fontSize: "15px"}}>10 x 10</p>,
            });
        }
        if (height >= 800 && width >= 1100) {
            setShowAboutMe(true);
        }
    }, [])

    const startInterval = async () => {
        checkPlayerState();
        if (!gameOver) {
            checkAndUpdateNextPlayer();
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

    const playAI = (np) => {
        if (aiPlayerIndex && np.player === aiPlayerIndex) {
            let [i, j] = getNextMove(squares, aiLevel);
            onClickSquare(i, j, false);
        }
    }


    const checkAndUpdateNextPlayer = () => {
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
        // check if AI player is there and if its AI player's turn
        let t = setTimeout(() => {
            playAI(np);
            clearTimeout(t);
        }, 450);
        console.log("next player", np);
    }

    const createAnimation = (i, j, color) => {
        // Get reference positions
        let startElement = document.querySelector(".dot-2");
        const targetElement = document.getElementById(`${i}_${j}`);
        if(!startElement) startElement = document.querySelector(`.cute-robot-v1`);

        if (!startElement || !targetElement) return;

        const startRect = startElement.getBoundingClientRect();
        const endRect = targetElement.getBoundingClientRect();

        // Create the circle dynamically
        const circle = document.createElement("div");
        circle.style.position = "absolute";
        circle.style.height = "18px";
        circle.style.width = "18px";
        circle.style.borderRadius = "50%";
        circle.style.margin = "5px";
        circle.style.display = "inline-block";
        circle.style.backgroundColor = color;
        circle.style.left = `${startRect.left}px`;
        circle.style.top = `${startRect.top}px`;
        circle.style.opacity = "1"; // Initially fully visible

        // Apply transition styles
        circle.style.transition = `
            transform 0.5s cubic-bezier(0.42, 0, 0, 0.98),
            opacity 0.5s ease-in-out
        `;

        // Append to body
        document.body.appendChild(circle);

        // Move and start fading immediately
        setTimeout(() => {
            circle.style.transform = `translate(
                ${endRect.left + endRect.width / 2 - startRect.left - 9}px,
                ${endRect.top + endRect.height / 2 - startRect.top - 9}px
            )`;
            circle.style.opacity = "0"; // Gradual fade-out
        }, 50);

        // Remove the circle after animation completes
        setTimeout(() => {
            document.body.removeChild(circle);
        }, 550);
    };

    const onClickSquare = async (i, j, isCloud) => {
        
        var curr = curr_player;
        curr.player = next_player.player;
        setCurrentPlayer({ ...curr });
        if (squares[i][j] !== null && squares[i][j].player !== curr.player) return;
        if (!isLive.live) {
            if (numSteps.n === 0) {
                gameOver = false;
            }
            if(aiPlayerIndex === 1 && curr.player !== 1) {
                 handleClick(i, j, true,);
                return;
            }
            if(aiPlayerIndex === 1 || showAnimation) {
                createAnimation(i, j, curr.player === 0 ? "#00A8CD" : curr.player === 1 ? "#CD00C5" : curr.player === 2 ? "#B0CD00" : "#CD0000");
                await new Promise(resolve => setTimeout(resolve, 400));
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
            createAnimation(i, j, curr.player === 0 ? "#00A8CD" : curr.player === 1 ? "#CD00C5" : curr.player === 2 ? "#B0CD00" : "#CD0000");
            await new Promise(resolve => setTimeout(resolve, 400));
        }
        else {
            if (numSteps.n === 0) {
                gameOver = false;
            }
            if(aiPlayerIndex === 1 || showAnimation) {
                createAnimation(i, j, curr.player === 0 ? "#00A8CD" : curr.player === 1 ? "#CD00C5" : curr.player === 2 ? "#B0CD00" : "#CD0000");
                await new Promise(resolve => setTimeout(resolve, 400));
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
                    if(aiPlayerIndex && aiPlayerIndex === next_player.player) return;
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
        var curr = curr_player;
        curr.player = 0;
        setCurrentPlayer({ ...curr });
        setCanClick(true);
        var nStep = numSteps;
        setShowIwon(false);
        nStep.n = 0;
        setNumSteps(nStep);
        var next = next_player;
        next.player = 0;
        setNextPlayer({ ...next });
        setLoser(Array(player_n.n).fill(false));
        setShowHowToPlay(false);
        setTitleMessage(aiPlayerIndex === 1?"Level "+aiLevel:"chain reaction");
        Object.keys(squares).forEach(i => {
            Object.keys(squares[i]).forEach(j => {
                squares[i][j] = null;
                setSquares({ ...squares, [i]: { ...squares[i], [j]: squares[i][j] } });
            }
            )
        });
        console.log(squares);
    }

    const shareGame = () => {
        notify("🚀 Copied to clipboard");
        navigator.clipboard.writeText("CODE: " + code + "\nLINK: 'https://bharath-bandaru.github.io/chain-reaction-game/'");
    }

    const joinRoom = (input) => {
        setBoxSize("0");
        if (input) {
            connectToRoom(input);
        } else {
            var groupID = prompt("Enter the room code: ");
            if (groupID) {
                connectToRoom(groupID);
            }
        }
    }


    const createRoom = () => {
        var liveStatus = isLive;
        liveStatus.live = true;
        setBoxSize("0");
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
        notify("share the code.")
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
            if (data.move !== null && data.move.i < 0 && data.move.j < 0) {
                setSquares({ ...initialArray });
                restartGame(true);
            } else if (data.move !== null) {
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
                setTitleMessage("rejoin room")
            }
        });
        onDisconnect(disconnectRef).set(true);
    }

    const connectToRoom = (groupID) => {
        var onlineGroupRef = ref(database, 'online/' + groupID)
        get(onlineGroupRef).then((snapshot) => {
            if (snapshot.exists()) {
                var liveStatus = isLive;
                liveStatus.live = true;
                setIsLive({ ...liveStatus });
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
            } else {
                notify("room not found");
            }
        }).catch((error) => {
            notify("Room not found");
            console.error(error);
        });
    }

    const generateGroupIds = async (userId) => {
        var uniqs = new Set();
        var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        var charactersLength = characters.length;

        for (var j = 0; j < 10000; j++) {
            var result = ""
            for (var i = 0; i < 4; i++) {
                result += characters.charAt(Math.floor(Math.random() * charactersLength));
            }
            uniqs.add(result);
        }

        const promises = [];
        for (const each of uniqs) {
            const promise = set(ref(database, 'groups/' + each), { emp: "val" });
            promises.push(promise);
        }

        try {
            await Promise.all(promises);
            console.log("All group IDs saved successfully!");

            getNewRoom(userId);
        } catch (error) {
            console.error("Error saving group IDs:", error);
        }
        console.log(uniqs);
    }


    const getNewRoom = (userId) => {
        console.log(database);
        get(child(ref(database), `groups`)).then((snapshot) => {
            if (snapshot.exists()) {
                const groups = snapshot.val();
                if (Object.keys(groups).length > 1) {
                    const key = Object.keys(groups).filter(key => key !== 'count')[0];
                    var keyref = ref(database, 'groups/' + key);
                    remove(keyref);
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
                generateGroupIds(userId);
                console.log("No data available");
            }
        }).catch((error) => {
            console.error(error);
        });
    }

    const updateLike = () => {
        get(ref(database, 'likes')).then((snapshot) => {
            set(ref(database, 'likes'), snapshot.val() + 1);
        });
    }

    const likeButton = async () => {
        var butt = document.getElementById("like-button");
        updateLike();
        playConfetti();
        if (isSafari) butt.innerHTML = '🥳'; else setLikeIcon(party);
        var t = await timer(3000);
        clearTimeout(t);
        if (isSafari) butt.innerHTML = '❤️'; else setLikeIcon(love);
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
        } else if (title_message === "rejoin room") {
            joinRoom(code);
            setTitleMessage("chain reaction");
        } else if (title_message === "restart") {
            restartGame();
        }
    }

    const robotHtml = (showThinking) => {
        return (
            <div className={`cute-robot-v1 ${showThinking ? 'thinking' : ''}`} >
            <div className="circle-bg">
                <div className="robot-ear left"></div>
                <div className="robot-head">
                <div className="robot-face">
                    <div className="eyes left"></div>
                    <div className="eyes right"></div>
                    <div className="mouth"></div>
                </div>
                </div>
                <div className="robot-ear right"></div>
                <div className="robot-body"></div>
                
                {/* Thinking Bars */}
                <div className="thinking-stripes">
                <div className="bar one"></div>
                <div className="bar two"></div>
                <div className="bar three"></div>
                </div>
            </div>
            </div>
        );
    };

    const logEventOnFirebase = (eventName) => {
        const eventRef = ref(database, 'events/' + eventName);
        get(eventRef).then((snapshot) => {
            if (snapshot.exists()) {
                set(eventRef, snapshot.val() + 1);
            } else {
                set(eventRef, 1);
            }
        });
    }


    return (
        <>
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet"></link>
            <div className="root">
                {
                    (showIwon) &&
                    <IWon
                        wonStatus={wonStatus.won}
                        showAboutMe={!showAboutMe}
                    />
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
                            <Menu style = {{padding: "0px"}} menuButton={<span className="material-icons mui noselect button-big"> dashboard_customize </span>} theming={"dark"}>
                                { !isLive.live &&
                                    <>
                                <MenuItem
                                    onClick={() => {
                                        let aiPlayerIndexTemp = aiPlayerIndex;
                                        setAiPlayerIndex(aiPlayerIndexTemp?undefined:1);
                                        var n = player_n;
                                        n.n = 2;
                                        setNoPlayer({ ...n });
                                        restartGame();
                                        if(!aiPlayerIndexTemp) logEventOnFirebase("play-with-computer");
                                        if(!aiPlayerIndexTemp) setTitleMessage("Level "+aiLevel);
                                        else setTitleMessage("chain reaction");

                                    }}>
                                    {
                                        (aiPlayerIndex) ?
                                        <span style={{ fontWeight: '600', display:"flex", gap:"3px" }} >
                                            <span style={{paddingTop:"2px"}}>Exit to Play with Friends</span>
                                            <span className="material-icons mui noselect">exit_to_app</span>
                                        </span>
                                        :
                                        <span style={{ fontWeight: '600' }} >Play with Computer</span>
                                    }
                                </MenuItem>
                                {
                                    
                                    <>
                                        <MenuDivider />

                                        <MenuRadioGroup value={aiLevel} onRadioChange={e => {
                                            logEventOnFirebase("change-ai-level "+e.value);
                                            logEventOnFirebase("play-with-computer");
                                            setAiLevel(e.value);
                                            localStorage.setItem("ai-level", e.value);
                                            var n = player_n;
                                            if (aiPlayerIndex) {
                                                n.n = 2;
                                                setNoPlayer({ ...n });
                                                restartGame();
                                            }else{
                                                setAiPlayerIndex(1);
                                                n.n = 2;
                                                setNoPlayer({ ...n });
                                                restartGame();
                                            }
                                            setTitleMessage("Level " + e.value);
                                        }}>
                                            <MenuItem type="radio" value="1"><span style={{paddingLeft:"5px"}}>Easy</span></MenuItem>
                                            <MenuItem type="radio" value="2"><span style={{paddingLeft:"5px"}}>Medium</span></MenuItem>
                                            <MenuItem type="radio" value="3"><span style={{paddingLeft:"5px"}}>Hard</span></MenuItem>
                                        </MenuRadioGroup>
                                    </>
                                }

                                <MenuDivider />
                                </>
                                }

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
                                {
                                    <MenuItem
                                    onClick={() => {
                                        setShowAnimation(!showAnimation);
                                    }}
                                    >
                                        {
                                        (showAnimation) ?
                                        <span style={{ fontWeight: '600' }} >Hide Player Move Animation</span>:
                                        <span style={{ fontWeight: '600' }} >Show Player Move Animation</span>
                                        }   
                                    </MenuItem>
                                }
                                <MenuDivider />
                                <MenuItem
                                    onClick={() => {
                                        setShowHowToPlay(true);
                                        setTitleMessage("next");
                                    }}>
                                    <span style={{ fontWeight: '600' }} >How to Play?</span>
                                </MenuItem>
                            </Menu>
                        </div>
                        <div style={{ zIndex: 100 }}>
                            {
                                !isLive.live &&
                                <div style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
                                    <span className="material-icons mui noselect butt" onClick={addPlayer}> add </span>
                                    <span className="material-icons mui-people noselect"> groups </span>
                                    <span className="material-icons mui noselect butt" onClick={removePlayer}> remove </span>
                                </div>
                            }
                            {
                                isLive.live &&
                                <div className='flex' style={{ paddingBottom: "6px", paddingTop: "4px" }}>
                                    <span className="live-code">{code}</span>
                                    <span className="material-icons mui pl-5 f-23 noselect" onClick={shareGame}> content_copy </span>
                                </div>
                            }
                            {
                                <div className='flex' style={{ paddingBottom: "6px", paddingTop: "4px", gap:"5px" }}>
                                    {
                                        player_color.map((item, index) => {

                                            return (
                                                <>
                                                    {
                                                        (isLive.live && index < player_n.n && index === main_player.player) &&
                                                        <div className="dot-2" style={{ backgroundColor: item, border: "3px solid #fff" }}></div>
                                                    }
                                                    {
                                                        (isLive.live && index < player_n.n && index !== main_player.player) &&
                                                        <div className="dot" style={{ backgroundColor: item, border : "3px solid #191919" }}></div>
                                                    }
                                                    {
                                                        (!isLive.live && index < player_n.n && index !== next_player.player && index !== aiPlayerIndex) &&
                                                        <div className="dot" style={{ backgroundColor: item, border : "3px solid #191919" }}></div>
                                                    }
                                                    {
                                                        (!isLive.live && index < player_n.n && index === next_player.player && index !== aiPlayerIndex) &&
                                                        <div className="dot-2" style={{ backgroundColor: item, border: "3px solid #fff" }}></div>
                                                    }
                                                    {
                                                        (!isLive.live && index < player_n.n && index === aiPlayerIndex) &&
                                                        robotHtml(index === next_player.player)
                                                    }
                                                </>
                                            )
                                        }
                                        )
                                    }

                                </div>
                            }
                        </div>
                        {showHowToPlay ?
                            <span className="material-icons mui noselect button-big" onClick={() => {
                                setShowHowToPlay(false);
                                setTitleMessage(aiPlayerIndex === 1?"Level "+aiLevel:"chain reaction");
                            } }> close </span>
                            :
                            <span className="material-icons mui noselect button-big" onClick={() => { restartGame() }}> cached </span>
                        }
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
                    <div>
                        <div className='footer'>
                            <div id='like-button' onClick={likeButton} className='buttons button-big like noselect'>
                                {isSafari ? <span>❤️</span> : <img src={likeIcon} alt="like" width="20px" />}
                            </div>
                            {(!isLoading && (title_message === 'start' || title_message === 'chain reaction')) &&
                                <h3 id='title' className={(title_message === "start") ? 'title-button cursor-pointer noselect' : 'cursor-pointer noselect'} onClick={() => onClickTitle()}>{title_message}</h3>}
                            {!isMainLoading && (title_message === 'waiting' || isLoading) && <div style={{ margin: "26px" }} className="loading"></div>}
                            {!isMainLoading && (title_message === 'next') &&
                                <h3 className='title-y-button cursor-pointer noselect'
                                    onClick={onClickTitle}>{title_message}
                                </h3>}
                            {(title_message === "rejoin room" || title_message === "restart") &&
                                <h3 className='title-o-button cursor-pointer noselect' style={{ zIndex: '1000' }}
                                    onClick={onClickTitle}>{title_message}
                                </h3>
                            }
                            {!isLoading && title_message === "Level " + aiLevel &&
                                <h3 className='noselect'>{title_message}</h3>

                            }
                            <div style={{ zIndex: '101' }}>
                                <Menu menuButton={<div className='buttons button-big tooltip noselect'>
                                    {isSafari ? <span>🚀</span> : <img src={rocket} alt="online" width="20px" />}
                                </div>} direction='top' theming={"dark"}>
                                    <div style={{ fontWeight: "bold", marginBottom: "6px", marginTop:"6px" }}>Play Online</div>
                                    <MenuDivider />
                                    <MenuItem onClick={() => joinRoom()} disabled={isLive.live}>Join Room</MenuItem>
                                    <MenuItem onClick={() => createRoom()} disabled={isLive.live}>Create Room</MenuItem>
                                    <MenuItem onClick={() => leaveRoom()} disabled={!isLive.live}>Leave Room</MenuItem>
                                </Menu>
                            </div>
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
                </div>
            </div>

            {
                (showIwon && showAboutMe) && <div className={"abme"}>
                    <span style={{ color: '#6a6a6a', marginBottom: '3px' }}> Designed and Developed by &nbsp;</span>
                    <a href='http://www.bharathbandaru.com/' target={'_blank'}
                        rel="noopener noreferrer"><img style={{ opacity: '1', borderRadius: "50%" }} src={logo} alt="logo" width={"20px"} /></a>
                    <a style={{ color: 'rgb(115 115 115)', marginLeft: '5px', marginBottom: '3px' }} href='http://www.bharathbandaru.com/' target={'_blank'} rel="noopener noreferrer">Bharath Bandaru</a>
                </div>
            }
            {
                <div className={"abme-top"}>
                    <span>{numberOfLikes}</span>
                    <span className="material-icons mui pl-5 f-15 noselect" onClick={likeButton}> favorite </span>
                </div>
            }
        </>
    );
}
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Game />);
serviceWorkerRegistration.register();