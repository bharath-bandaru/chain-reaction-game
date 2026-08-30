# Chain Reaction — Flutter

Full-screen mobile port (iOS + Android) of the [Chain Reaction web game](https://bharath-bandaru.github.io/chain-reaction-game/), sharing the same Firebase backend so mobile and web players can join the same online rooms.

- **iOS bundle id:** `us.ephileo.chainreaction`
- **Android application id:** `com.bhvp.chainreaction`

## Features

- 2–4 player local hotseat on 6x9 or 10x10 boards
- AI opponent (minimax with alpha-beta pruning), 3 selectable difficulties, auto level-up on wins, runs in a background isolate
- Online multiplayer via Firebase Realtime Database (create/join/leave room, restart sync, disconnect detection) — same `online/`, `hooks/`, `groups/` contract as the web app; mid-game joiners sit in a waiting room and enter at the next round
- Orb-conserving wave-based chain reactions with explosion / flying-dot animations, a periodic glitch marker on the last placed orb, and subtle win confetti
- System status bar visible over the dark canvas; global like counter top-right
- Bottom sheets for the game menu and online play; roamates-style pill snackbars
- Undo (with history), move-animation and undo-button settings persisted locally; How to Play tutorial; win/lose screen

## Architecture

```
lib/
├── main.dart                 # bootstrap: edge-to-edge, orientation, services
├── app.dart                  # MaterialApp + provider wiring + dark theme
├── firebase_options.dart     # Firebase creds (gitignored, see below)
├── core/constants/           # colors, game constants
├── models/                   # Cell/Board, animation events, undo snapshot
├── logic/
│   ├── game_controller.dart  # ChangeNotifier: rules, turns, online flows
│   └── ai/minimax_ai.dart    # isolate-friendly minimax AI
├── services/
│   ├── firebase_service.dart # auth, RTDB paths, room/move streams
│   └── preferences_service.dart # SharedPreferences settings
└── ui/
    ├── screens/game_screen.dart
    └── widgets/
        ├── board/            # grid, orb painter, explosion, flying dot
        ├── header/           # likes row, player dots, header controls
        ├── footer/           # like, title/undo, online menu
        ├── sheets/           # game menu + online bottom sheets
        ├── feedback/snackbar # pill snackbar (ported from roamates)
        └── overlays/         # how-to-play, win/lose
```

State management is `provider` + `ChangeNotifier`; widgets are presentational and all rules live in `GameController`.

## Setup

`lib/firebase_options.dart` is **gitignored** (it contains the Firebase credentials, like `src/components/firebase.js` in the web app). Recreate it with the project's `FirebaseOptions`, or run `flutterfire configure` against the `chain-reaction-game-fa325` project.

```sh
flutter pub get
flutter test                             # fast suite (rules, cascades, fuzz, UI flows)
flutter test --tags=slow --run-skipped   # full AI game simulations (few minutes)
flutter run                # device or simulator
flutter build appbundle    # Android release (needs a release keystore)
flutter build ipa          # iOS release (requires signing)
```

## Before shipping to stores

- Replace the default Flutter launcher icons (e.g. `flutter_launcher_icons`)
- Configure Android release signing (`android/app/build.gradle.kts` still signs release builds with the debug key)
