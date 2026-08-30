# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Dev server:** `npm start` (localhost:3000)
- **Build:** `npm run build`
- **Deploy to GitHub Pages:** `npm run deploy` (runs build first via predeploy)
- **Tests:** `npm test` (CRA test runner, interactive watch mode)

## Architecture

This is a **Chain Reaction board game** built with React 18 and Create React App. Live at https://bharath-bandaru.github.io/chain-reaction-game/

### Core Game Logic

**`src/index.js`** (~1400 lines) — The main React component containing all game state and logic:
- `chainReact(i, j, isInit)` — Core mechanic: places orbs, detects critical mass (corners=1, edges=2, center=3), triggers recursive chain reactions to adjacent cells
- `handleClick(i, j, isInit)` — Validates moves, executes chain reactions, applies animations, checks game over
- `checkGameOver()` — Scans board for remaining players; triggers win/loss UI
- Board state is a 2D array in `squares` (9x6 default, 10x10 on large screens), each cell has `{count, player}`
- Supports 2-4 players (local hotseat or online multiplayer)

**`src/ai.js`** — AI opponent using **minimax with alpha-beta pruning**:
- 5 difficulty levels controlling search depth (level 1: depth 0-1, level 5: depth 3)
- `getNextMove(board, aiLevel)` — Entry point; evaluates all moves, biases toward opponent adjacency
- `evaluate(board)` — Scores positions by net orb advantage; returns ±999999 for win/loss
- AI level persists in localStorage and auto-increments on player win

### Multiplayer (Firebase)

**`src/components/firebase.js`** (gitignored) — Firebase config for:
- Anonymous auth via `signInAnonymously()`
- Realtime Database for online game rooms (`/online/{groupId}`), move streaming (`/hooks/{groupId}`), player tracking
- Analytics event logging

### UI Components

- `Square.js` — Board cell; renders orb actors based on count
- `Actor.js` + `actors/ActorOne|Two|Three.js` — SVG orb visualizations (1-3 orbs per cell)
- `HowToPlay.js` — Tutorial modal
- `IWon.js` — Win/lose screen with confetti (`canvas-confetti`)
- `src/css/index.css` — All styling including animations, difficulty selection UI, dark theme (#191919)

### Key Libraries

- `@szhsin/react-menu` — Dropdown menus for game settings
- `react-toastify` — Toast notifications
- `canvas-confetti` — Win celebration effects
- `uuid` — Room code generation for online play

## Important Notes

- `src/components/firebase.js` and `others/.firebaserc` are **gitignored** (contain Firebase credentials)
- No linter or formatter configured beyond CRA defaults
- All game state is managed via React hooks in the single `index.js` component (no Redux/Context)
- CSS animations for orb explosions are toggled via a user setting stored in localStorage
