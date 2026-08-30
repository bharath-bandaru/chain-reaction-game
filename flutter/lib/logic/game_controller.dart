import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/cell.dart';
import '../models/game_events.dart';
import '../services/firebase_service.dart';
import '../services/preferences_service.dart';
import 'ai/minimax_ai.dart';

/// Tone of a toast message; the UI maps it to a snackbar style.
enum ToastTone { info, success, error }

/// Footer title states, mirroring the web app's `title_message` strings.
abstract final class TitleMessages {
  static const chainReaction = AppConstants.appTitle;
  static const start = 'start';
  static const next = 'next';
  static const restart = 'restart';
  static const rejoinRoom = 'rejoin room';
}

/// Central game state + rules engine (the Flutter equivalent of the `Game`
/// component in `src/index.js`). All mutations notify listeners; widgets stay
/// purely presentational.
class GameController extends ChangeNotifier {
  GameController({
    required this.firebase,
    required this.prefs,
    this.waveDelay = AppConstants.explosionWave,
    this.flyDelay = AppConstants.flyingDot,
    this.aiDelay = AppConstants.aiMoveDelay,
  }) {
    aiLevel = prefs.aiLevel;
    showAnimation = prefs.showAnimation;
    showUndo = prefs.showUndo;
    _resetBoard();
    _likesSubscription = firebase.likesStream().listen((value) {
      numberOfLikes = value;
      notifyListeners();
    });
  }

  final FirebaseService firebase;
  final PreferencesService prefs;
  final String sessionId = const Uuid().v4();

  /// Animation pacing — injectable so headless tests can run at full speed.
  final Duration waveDelay;
  final Duration flyDelay;
  final Duration aiDelay;

  // ------------------------------------------------------------ board state

  int rows = AppConstants.defaultRows;
  int cols = AppConstants.defaultCols;
  String boardSizeKey = '0'; // '0' = 6x9, '1' = 10x10
  late Board board;

  int playerCount = AppConstants.minPlayers;
  int currentPlayer = 0;
  int nextPlayer = 0;
  int mainPlayer = 0;
  List<bool> losers = List.filled(AppConstants.minPlayers, false);
  int moveCount = 0;
  bool gameOver = false;
  bool canClick = true;

  // --------------------------------------------------------------- UI state

  String titleMessage = TitleMessages.chainReaction;
  bool isLoading = false; // footer spinner (waiting in a room)
  bool isMainLoading = false; // full-screen spinner (players joining)
  bool showHowToPlay = false;
  int howToPlayState = 0;
  bool showIWon = false;
  bool wonStatus = true;
  int? numberOfLikes;

  // -------------------------------------------------------------- AI state

  int? aiPlayerIndex;
  bool aiThinking = false;
  String aiLevel = '1';
  bool _aiMovePending = false;

  /// Bumped whenever the board is reset (restart, undo, mode/size change).
  /// An in-flight AI computation captures the generation it was scheduled
  /// for and discards its result if the world changed underneath it —
  /// otherwise a restart mid-think could land a stale move on a fresh board.
  int _aiGeneration = 0;

  // -------------------------------------------------------------- settings

  bool showAnimation = false;
  bool showUndo = true;

  // ------------------------------------------------------------ animations

  final List<ExplosionEvent> explosions = [];
  FlyingDotEvent? flyingDot;
  int _eventId = 0;

  /// Cell of the most recent move — its orb plays the glitch marker effect.
  (int, int)? lastPlaced;

  // ------------------------------------------------------------------ undo

  final List<GameSnapshot> _history = [];
  bool get canUndo => _history.isNotEmpty;

  // ---------------------------------------------------------------- online

  bool isLive = false;
  String roomCode = '••••';
  final List<StreamSubscription> _roomSubscriptions = [];
  StreamSubscription? _likesSubscription;
  bool _skipNextHookEvent = false;

  /// True for a player who joined while a game was in progress: they hold a
  /// seat but sit in the waiting room (ignoring move events, since they have
  /// no board history) until the next restart starts a fresh game.
  bool waitingForNextGame = false;

  /// Player count seen on the room while a game was in progress — applied at
  /// the next restart so the running game's turn order is never disturbed.
  int? _pendingPlayerCount;

  /// Last `n` seen on the room stream, to detect mid-game arrivals.
  int? _lastRoomCount;

  /// Whether the room's game has been started (from the room stream) —
  /// disconnects are handled differently in the lobby vs mid-game.
  bool _roomStarted = false;

  /// Message shown under the full-screen spinner (e.g. the waiting room).
  String? mainLoadingMessage;

  /// True while the room is frozen because a player disconnected. The UI
  /// state from just before the freeze is kept so it can be restored exactly
  /// when they return.
  bool waitingForRejoin = false;
  ({
    String title,
    bool loading,
    bool mainLoading,
    bool click,
    String? message
  })? _stateBeforeDisconnect;

  /// Serializes cloud events (moves, restarts). A move can arrive while the
  /// previous move's cascade is still animating locally — applying it
  /// concurrently would interleave two cascades and desync the board, so
  /// every cloud event waits for the one before it.
  Future<void> _cloudEventQueue = Future.value();

  void _enqueueCloudEvent(String code, Future<void> Function() action) {
    _cloudEventQueue = _cloudEventQueue.then((_) async {
      // The room may have been left (or switched) while this was queued.
      if (!isLive || roomCode != code) return;
      await action();
    }).catchError((Object error) {
      debugPrint('cloud event failed: $error');
    });
  }

  /// UI hooks, wired up by the game screen.
  void Function(String message, ToastTone tone)? onToast;
  VoidCallback? onConfetti;

  Color get activeColor => AppColors.players[nextPlayer];

  /// True while a game is underway: moves are on the board and nobody has
  /// won yet. Used to confirm destructive actions like changing players.
  bool get isMidGame => moveCount > 0 && !gameOver;

  // ========================================================== board control

  void _resetBoard() {
    board = emptyBoard(rows, cols);
    moveCount = 0;
    currentPlayer = 0;
    nextPlayer = 0;
    losers = List.filled(playerCount, false);
    gameOver = false;
  }

  /// Switches between the 6x9 and 10x10 boards and restarts everything.
  void setBoardSize(String key) {
    boardSizeKey = key;
    if (key == '0') {
      rows = AppConstants.defaultRows;
      cols = AppConstants.defaultCols;
    } else {
      rows = AppConstants.largeRows;
      cols = AppConstants.largeCols;
    }
    restartGame();
  }

  void addPlayer() {
    if (isLive || playerCount >= AppConstants.maxPlayers) return;
    playerCount++;
    restartGame();
  }

  void removePlayer() {
    if (isLive || playerCount <= AppConstants.minPlayers) return;
    playerCount--;
    restartGame();
  }

  void restartGame({bool fromCloud = false}) {
    if (!fromCloud && isLive) {
      firebase.sendRestart(roomCode);
      return;
    }
    _resetBoard();
    canClick = true;
    showIWon = false;
    showHowToPlay = false;
    howToPlayState = 0;
    titleMessage = aiPlayerIndex == AppConstants.aiPlayerIndex
        ? 'Level $aiLevel'
        : TitleMessages.chainReaction;
    _history.clear();
    explosions.clear();
    flyingDot = null;
    lastPlaced = null;
    // Invalidate any in-flight AI computation; its result belongs to the
    // previous board.
    _aiGeneration++;
    _aiMovePending = false;
    aiThinking = false;
    notifyListeners();
  }

  // ================================================================== moves

  /// Tap handler for a board cell (guards ported from `renderSquare`).
  void onSquareTap(int i, int j) {
    if (!canClick || gameOver) return;
    if (aiPlayerIndex != null && nextPlayer == aiPlayerIndex) return;
    if (isLive && nextPlayer != mainPlayer) return;
    _playMove(i, j, fromCloud: false);
  }

  /// The web app's `onClickSquare`: validates the move, records undo history,
  /// plays the flying-dot animation, and either applies the move locally or
  /// publishes it to the room's move hook.
  Future<void> _playMove(
    int i,
    int j, {
    required bool fromCloud,
    bool ownEcho = false,
  }) async {
    currentPlayer = nextPlayer;
    final cell = board[i][j];
    if (cell != null && cell.player != currentPlayer) return;

    if (!isLive) {
      if (!fromCloud && currentPlayer != aiPlayerIndex) _saveSnapshot();

      // The human's move in AI mode plays instantly; the AI's own move (and
      // any move when the setting is on) gets the flying-dot animation —
      // matching the web app's `onClickSquare`.
      final humanVsAi = aiPlayerIndex == AppConstants.aiPlayerIndex &&
          currentPlayer != AppConstants.aiPlayerIndex;
      if (!humanVsAi && (aiPlayerIndex != null || showAnimation)) {
        await _playFlyingDot(i, j);
      }
      await _resolveMove(i, j);
      return;
    }

    if (!fromCloud) {
      // Online: publish the move; every client (including us) applies it
      // when it arrives on the hook stream.
      try {
        await firebase.sendMove(roomCode, i, j, nextPlayer, sessionId);
      } catch (error) {
        debugPrint('sendMove failed: $error');
        onToast?.call(
            'Move not sent — check your connection', ToastTone.error);
      }
      return;
    }

    // Online: other players' moves always animate (it shows whose move just
    // arrived); your OWN move's echo follows your animation preference.
    if (!ownEcho || showAnimation) await _playFlyingDot(i, j);
    await _resolveMove(i, j);
  }

  Future<void> _playFlyingDot(int i, int j) async {
    canClick = false;
    flyingDot = FlyingDotEvent(
      id: _eventId++,
      row: i,
      col: j,
      color: AppColors.players[currentPlayer],
    );
    notifyListeners();
    await Future.delayed(flyDelay);
    flyingDot = null;
    canClick = true;
    notifyListeners();
  }

  /// Applies a move and resolves the resulting chain reaction wave by wave,
  /// pausing on each wave so explosion animations can play (this is the
  /// recursive `handleClick` + `chainReact` pair from the web app, flattened
  /// into a breadth-first loop).
  Future<void> _resolveMove(int startRow, int startCol) async {
    if (gameOver) return;
    moveCount++;
    lastPlaced = (startRow, startCol);
    // A wave maps each receiving cell to how many orbs land on it this round.
    // Cells MUST be aggregated: one fed by several exploding neighbours takes
    // all of their orbs at once and still fires only once. Keeping the wave as
    // a flat list instead let a cell fire once per incoming orb, which minted
    // orbs out of nothing and turned big cascades into a runaway that never
    // converged (the board froze mid-chain).
    var wave = <(int, int), int>{(startRow, startCol): 1};
    var isInitial = true;
    var turnAdvanced = false;

    while (wave.isNotEmpty && !gameOver) {
      final exploders = <(int, int)>[];
      for (final entry in wave.entries) {
        final (i, j) = entry.key;
        if (_addOrbs(i, j, entry.value)) exploders.add(entry.key);
      }

      if (isInitial && exploders.isEmpty) {
        // Simple placement: pass the turn immediately (board border color
        // switches right away, like the web app).
        _advanceNextPlayer();
        turnAdvanced = true;
      }
      isInitial = false;
      notifyListeners();
      if (exploders.isEmpty) break;

      // A chain reaction invalidates the "last placed" marker — no glitch
      // during or after a cascade.
      lastPlaced = null;

      canClick = false;
      final waveIds = <int>[];
      for (final (i, j) in exploders) {
        _explode(i, j);
        final event = ExplosionEvent(
          id: _eventId++,
          row: i,
          col: j,
          color: AppColors.players[currentPlayer],
        );
        waveIds.add(event.id);
        explosions.add(event);
      }
      notifyListeners();
      await Future.delayed(waveDelay);
      explosions.removeWhere((e) => waveIds.contains(e.id));

      // Next wave: every orthogonal neighbor of each exploded cell
      // receives one orb.
      final next = <(int, int), int>{};
      void feed(int i, int j) =>
          next.update((i, j), (count) => count + 1, ifAbsent: () => 1);
      for (final (i, j) in exploders) {
        if (i - 1 >= 0) feed(i - 1, j);
        if (i + 1 < rows) feed(i + 1, j);
        if (j - 1 >= 0) feed(i, j - 1);
        if (j + 1 < cols) feed(i, j + 1);
      }
      wave = next;

      // Stop endless chains once the board is fully captured.
      if (_boardDominatedByCurrentPlayer()) break;
    }

    _finishMove(turnAdvanced: turnAdvanced);
  }

  /// Drops [count] orbs on (i, j) for the current player, who takes the cell
  /// over. Returns true when the cell has passed its critical mass and must
  /// explode. [count] is 1 for a placement and 1..4 inside a cascade.
  bool _addOrbs(int i, int j, int count) {
    final cell = board[i][j];
    if (cell == null) {
      board[i][j] = Cell(player: currentPlayer, state: count);
    } else {
      cell.state += count;
      cell.player = currentPlayer;
    }
    return board[i][j]!.state > maxStateFor(i, j, rows, cols);
  }

  /// Fires (i, j): it sheds exactly one orb per orthogonal neighbour — always
  /// `max + 1` of them — and keeps whatever is left over, so the cascade can
  /// never create orbs. Almost always that leaves the cell empty.
  void _explode(int i, int j) {
    final cell = board[i][j]!;
    final leftover = cell.state - (maxStateFor(i, j, rows, cols) + 1);
    if (leftover > 0) {
      cell.state = leftover;
      cell.player = currentPlayer;
    } else {
      board[i][j] = null;
    }
  }

  void _finishMove({required bool turnAdvanced}) {
    _checkEliminations();
    _checkGameOver();
    if (!gameOver) {
      if (!turnAdvanced) _advanceNextPlayer();
      canClick = true;
    }
    notifyListeners();
    _maybeScheduleAiMove();
  }

  bool _boardDominatedByCurrentPlayer() {
    for (final row in board) {
      for (final cell in row) {
        if (cell != null && cell.player != currentPlayer) return false;
      }
    }
    return true;
  }

  /// Marks players with no orbs left as eliminated (after everyone has had a
  /// first turn) and announces it, like the web `checkPlayerState`.
  void _checkEliminations() {
    if (gameOver || moveCount < playerCount) return;
    final hasOrbs = List.filled(playerCount, false);
    for (final row in board) {
      for (final cell in row) {
        if (cell != null && cell.player < playerCount) {
          hasOrbs[cell.player] = true;
        }
      }
    }
    for (var p = 0; p < playerCount; p++) {
      if (!hasOrbs[p] && !losers[p]) {
        losers[p] = true;
        // Online, address the local player directly instead of by color.
        final message = isLive && p == mainPlayer
            ? 'You lost'
            : '${AppColors.playerNames[p]} lost.';
        onToast?.call(message, ToastTone.error);
      }
    }
  }

  void _checkGameOver() {
    if (moveCount < playerCount || !_boardDominatedByCurrentPlayer()) return;

    gameOver = true;
    canClick = false;
    firebase.countGameOver(online: isLive);

    final lostOnline = isLive && currentPlayer != mainPlayer;
    final lostToAi = aiPlayerIndex == AppConstants.aiPlayerIndex &&
        currentPlayer == AppConstants.aiPlayerIndex;

    if (lostOnline || lostToAi) {
      wonStatus = false;
    } else {
      if (aiPlayerIndex == AppConstants.aiPlayerIndex) _increaseAiLevel();
      wonStatus = true;
      onConfetti?.call();
      // Online, tell the winner directly (this replaces the "<color> lost."
      // elimination toast that fires just before the game ends).
      if (isLive) onToast?.call('You won! 🎉', ToastTone.success);
    }
    showIWon = true;
    titleMessage = TitleMessages.restart;
  }

  void _increaseAiLevel() {
    final next = (int.parse(aiLevel) + 1).clamp(1, 5);
    aiLevel = next.toString();
    prefs.aiLevel = aiLevel;
  }

  void _advanceNextPlayer() {
    var candidate = currentPlayer < playerCount - 1 ? currentPlayer + 1 : 0;
    if (moveCount >= playerCount) {
      // Bounded scan: the mover always retains orbs so a non-loser exists,
      // but if that invariant ever broke this must not hang the UI thread.
      for (var hops = 0;
          hops < playerCount && losers[candidate];
          hops++) {
        candidate = candidate < playerCount - 1 ? candidate + 1 : 0;
      }
    }
    nextPlayer = candidate;
  }

  // ===================================================================== AI

  /// Selects the AI difficulty without starting a game (used by the menu's
  /// segmented switch while the AI is off).
  void setAiLevel(String level) {
    aiLevel = level;
    prefs.aiLevel = level;
    notifyListeners();
  }

  /// Enables the AI opponent at the given difficulty and restarts.
  void playWithComputer(String level) {
    aiLevel = level;
    prefs.aiLevel = level;
    aiPlayerIndex = AppConstants.aiPlayerIndex;
    playerCount = 2;
    firebase.logEvent('change-ai-level $level');
    firebase.logEvent('play-with-computer');
    restartGame();
  }

  /// Turns the AI off and returns to local multiplayer.
  void exitComputerMode() {
    aiPlayerIndex = null;
    aiThinking = false;
    playerCount = 2;
    restartGame();
  }

  void _maybeScheduleAiMove() {
    if (gameOver ||
        isLive ||
        aiPlayerIndex == null ||
        nextPlayer != aiPlayerIndex ||
        _aiMovePending) {
      return;
    }
    _aiMovePending = true;
    aiThinking = true;
    final generation = _aiGeneration;
    notifyListeners();

    Future.delayed(aiDelay, () async {
      // The board was reset while we waited — a newer schedule (if any)
      // owns the flags now; this stale computation just bows out.
      if (generation != _aiGeneration) return;
      try {
        final encoded = [
          for (final row in board)
            [
              for (final cell in row)
                cell == null ? 0 : encodeCell(cell.player, cell.state),
            ],
        ];
        final move = await compute(
            findBestMove, {'board': encoded, 'level': aiLevel});
        if (generation != _aiGeneration) return; // reset mid-compute
        aiThinking = false;
        _aiMovePending = false;
        if (move != null && !gameOver && nextPlayer == aiPlayerIndex) {
          await _playMove(move[0], move[1], fromCloud: false);
        }
        notifyListeners();
        // Watchdog: if the turn somehow ended move-less and it is still the
        // AI's turn, re-arm rather than leaving a dead board. The guards in
        // _maybeScheduleAiMove make this a no-op otherwise.
        _maybeScheduleAiMove();
      } catch (error) {
        debugPrint('AI move failed: $error');
        if (generation != _aiGeneration) return;
        aiThinking = false;
        _aiMovePending = false;
        notifyListeners();
        _maybeScheduleAiMove();
      }
    });
  }

  // =================================================================== undo

  void _saveSnapshot() {
    _history.add(GameSnapshot(
      board: copyBoard(board),
      currentPlayer: currentPlayer,
      nextPlayer: nextPlayer,
      losers: List.of(losers),
      moveCount: moveCount,
    ));
  }

  void undoMove() {
    // canClick blocks undo while a cascade/animation is still resolving —
    // swapping the board mid-wave would corrupt the running chain.
    if (!canClick || _history.isEmpty || isLive) return;
    final snapshot = _history.removeLast();
    board = snapshot.board;
    currentPlayer = snapshot.currentPlayer;
    nextPlayer = snapshot.nextPlayer;
    losers = snapshot.losers;
    moveCount = snapshot.moveCount;
    showIWon = false;
    gameOver = false;
    canClick = true;
    lastPlaced = null;
    // The board changed under any in-flight AI computation.
    _aiGeneration++;
    _aiMovePending = false;
    aiThinking = false;
    titleMessage = aiPlayerIndex == AppConstants.aiPlayerIndex
        ? 'Level $aiLevel'
        : TitleMessages.chainReaction;
    notifyListeners();
  }

  // =============================================================== settings

  void toggleAnimation() {
    showAnimation = !showAnimation;
    prefs.showAnimation = showAnimation;
    firebase.logEvent('toggle-animations $showAnimation');
    notifyListeners();
  }

  void toggleUndoButton() {
    showUndo = !showUndo;
    prefs.showUndo = showUndo;
    notifyListeners();
  }

  // ============================================================ how to play

  void openHowToPlay() {
    showHowToPlay = true;
    howToPlayState = 0;
    titleMessage = TitleMessages.next;
    notifyListeners();
  }

  void closeHowToPlay() {
    showHowToPlay = false;
    howToPlayState = 0;
    titleMessage = aiPlayerIndex == AppConstants.aiPlayerIndex
        ? 'Level $aiLevel'
        : TitleMessages.chainReaction;
    notifyListeners();
  }

  // ============================================================ footer title

  /// Handles taps on the footer title (start / next / rejoin / restart).
  void onTitleTap() {
    switch (titleMessage) {
      case TitleMessages.start:
        startOnlineGame();
      case TitleMessages.next:
        if (howToPlayState < 4) {
          howToPlayState++;
          notifyListeners();
        } else {
          closeHowToPlay();
        }
      case TitleMessages.rejoinRoom:
        joinRoom(roomCode, resume: true);
        titleMessage = TitleMessages.chainReaction;
        notifyListeners();
      case TitleMessages.restart:
        restartGame();
    }
  }

  // ================================================================= likes

  /// Bumped on every local like tap so the likes indicator can reveal
  /// itself immediately (before the server round-trip updates the count).
  int likePulse = 0;

  Future<void> like() async {
    likePulse++;
    notifyListeners();
    await firebase.addLike();
    onConfetti?.call();
  }

  // ================================================================ online

  /// Online rooms always play on the 6x9 board (web clients only support
  /// that size). Rather than silently switching the local board, entering a
  /// room while on 10x10 is blocked with an explanation.
  bool _blockUnlessDefaultBoard() {
    if (boardSizeKey == '0') return false;
    onToast?.call(
        'Online rooms play on the 6 x 9 board — switch your board size first',
        ToastTone.error);
    return true;
  }

  Future<void> createRoom() async {
    if (_blockUnlessDefaultBoard()) return;
    _roomStarted = false;
    if (!firebase.isAvailable) {
      onToast?.call('You are offline', ToastTone.error);
      return;
    }
    setBoardSize('0'); // must happen before isLive so it resets locally
    isLive = true;
    canClick = false;
    playerCount = 1;
    losers = List.filled(AppConstants.maxPlayers, false);
    titleMessage = TitleMessages.start;
    mainPlayer = 0;
    aiPlayerIndex = null;
    isLoading = true;
    onToast?.call('share the code.', ToastTone.info);
    notifyListeners();

    final code = await firebase.createRoom();
    if (code == null) {
      onToast?.call('Could not create a room', ToastTone.error);
      leaveRoom();
      return;
    }
    roomCode = code;
    await _listenToRoom(code);
    notifyListeners();
  }

  /// Joins the room [code].
  ///
  /// Cases handled:
  ///   * lobby join (`status == 'waiting'`) — take a seat and wait for start;
  ///   * mid-game join (`status == 'started'`) — take a seat but sit in the
  ///     waiting room until the current game finishes (spectators have no
  ///     board history, so they must not apply in-progress moves);
  ///   * [resume] — reconnecting to the room we were already playing in
  ///     (the "rejoin room" button): keep the local board and seat;
  ///   * a returning uid without local state (app restart) is treated like a
  ///     fresh join into whichever phase the room is in.
  Future<void> joinRoom(String code, {bool resume = false}) async {
    if (!resume && _blockUnlessDefaultBoard()) return;
    if (!firebase.isAvailable) {
      onToast?.call('You are offline', ToastTone.error);
      return;
    }
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final room = await firebase.getRoom(normalized);
    if (room == null) {
      onToast?.call('room not found', ToastTone.error);
      return;
    }
    // Rooms record their board size ('0' implied for rooms created by the
    // web app); anything but 6x9 is unsupported.
    if ((room['board'] ?? '0') != '0') {
      onToast?.call(
          'This room uses an unsupported board size', ToastTone.error);
      return;
    }
    final players = [
      for (final id in (room['players'] as List? ?? const [])) id.toString(),
    ];
    final n = (room['n'] as num?)?.toInt() ?? players.length;
    final started = room['status'] == 'started';
    final uid = firebase.uid!;
    final alreadySeated = players.contains(uid);

    if (!alreadySeated && n >= AppConstants.maxPlayers) {
      onToast?.call('Room is full', ToastTone.error);
      return;
    }

    // Resume after a disconnect: we still hold this room's board state, so
    // keep it and just re-attach the listeners.
    if (resume && alreadySeated && roomCode == normalized && isLive) {
      isMainLoading = false;
      mainLoadingMessage = null;
      canClick = !waitingForNextGame;
      titleMessage = TitleMessages.chainReaction;
      await _listenToRoom(normalized);
      notifyListeners();
      return;
    }

    setBoardSize('0');
    isLive = true;
    aiPlayerIndex = null;
    canClick = false;
    losers = List.filled(AppConstants.maxPlayers, false);
    roomCode = normalized;
    _lastRoomCount = null;
    _roomStarted = started;

    if (alreadySeated) {
      mainPlayer = players.indexOf(uid);
    } else {
      mainPlayer = n; // new joiners take the next seat
      await firebase.joinRoom(normalized, room, [...players, uid]);
    }

    if (started) {
      // Mid-game: reserve the seat, wait for the current game to finish
      // (signalled by the restart hook, which resets every client's board).
      waitingForNextGame = true;
      _pendingPlayerCount = alreadySeated ? n : n + 1;
      playerCount = _pendingPlayerCount!.clamp(1, AppConstants.maxPlayers);
      isLoading = false;
      isMainLoading = true;
      mainLoadingMessage =
          'Game in progress —\nyou will join the next round';
      titleMessage = TitleMessages.chainReaction;
    } else {
      // Lobby: wait for the host to start.
      playerCount = n;
      isLoading = true;
      titleMessage = alreadySeated && mainPlayer == 0
          ? TitleMessages.start
          : TitleMessages.chainReaction;
    }
    await _listenToRoom(normalized);
    // A seated player returning to a game in progress (app relaunch) has no
    // board history — and the game may even be stuck on their turn. Restart
    // the room so everyone begins a fresh round together; the restart echo
    // seats us via the waiting-room path.
    if (started && alreadySeated) {
      await firebase.sendRestart(normalized);
    }
    notifyListeners();
  }

  Future<void> _listenToRoom(String code) async {
    await _cancelRoomSubscriptions();

    _roomSubscriptions.add(firebase.roomStream(code).listen((room) {
      if (room == null) return;
      const colors = ['🔵', '🟣', '🟡', '🔴'];
      final n = ((room['n'] as num?)?.toInt() ?? playerCount)
          .clamp(1, AppConstants.maxPlayers);
      final started = room['status'] == 'started';
      _roomStarted = started;

      // In the lobby, seats follow the room's player list — if the host
      // leaves, everyone shifts up and the new first seat gets the start
      // button.
      final seats = [
        for (final id in (room['players'] as List? ?? const [])) id.toString(),
      ];
      final uid = firebase.uid;
      if (!started && uid != null && seats.contains(uid)) {
        mainPlayer = seats.indexOf(uid);
        if (!waitingForNextGame && !waitingForRejoin) {
          titleMessage = mainPlayer == 0
              ? TitleMessages.start
              : TitleMessages.chainReaction;
        }
      }

      // A game is "in progress" once moves are on the board (and until it
      // ends). Player-count changes then apply at the next restart so the
      // running game's turn order and losers are never disturbed.
      final previousCount = _lastRoomCount;
      _lastRoomCount = n;
      final gameInProgress =
          started && !gameOver && (moveCount > 0 || waitingForNextGame);
      if (gameInProgress) {
        _pendingPlayerCount = n;
        if (previousCount != null &&
            n > previousCount &&
            !waitingForNextGame) {
          onToast?.call(
              'A player joined — they play next game', ToastTone.info);
        }
      } else {
        playerCount = n;
      }

      if (started) {
        // Lobby -> game-start transition. Only when we were actually
        // waiting for the start; never clobber a running game's state, a
        // game-over "restart" title, or the mid-game waiting room.
        if (!waitingForNextGame && (isLoading || isMainLoading)) {
          isMainLoading = false;
          mainLoadingMessage = null;
          titleMessage = TitleMessages.chainReaction;
          canClick = true;
          showHowToPlay = false;
          isLoading = false;
        }
      } else if (previousCount != null && n < previousCount) {
        // Lobby seat freed (explicit leave, or the caretaker pruned an
        // offline player) — the remaining seats have already shifted up.
        onToast?.call('A player left the room', ToastTone.info);
        if (n <= 1) {
          // Alone again: back to the waiting-for-players state.
          isMainLoading = false;
          mainLoadingMessage = null;
          isLoading = true;
        }
      } else if (n > 1) {
        isLoading = false;
        isMainLoading = true;
        onToast?.call(
            '${colors[(n - 1).clamp(0, 3)]} player added', ToastTone.success);
      }
      notifyListeners();
    }));

    // Skip the snapshot that fires immediately on subscribe so a stale last
    // move is not replayed when (re)joining mid-game.
    _skipNextHookEvent = true;
    _roomSubscriptions.add(firebase.moveStream(code).listen((data) {
      if (_skipNextHookEvent) {
        _skipNextHookEvent = false;
        return;
      }
      final move = data?['move'];
      if (move == null) return;
      final map = Map<String, dynamic>.from(move as Map);
      final i = (map['i'] as num).toInt();
      final j = (map['j'] as num).toInt();
      if (i < 0 || j < 0) {
        _enqueueCloudEvent(code, () async => _startNextGameFromCloud());
      } else if (!waitingForNextGame) {
        // Waiting-room players ignore in-progress moves: they have no board
        // history to apply them to. They sync up at the next restart.
        final ownEcho = data?['uuid'] == sessionId;
        _enqueueCloudEvent(
            code, () => _playMove(i, j, fromCloud: true, ownEcho: ownEcho));
      }
    }));

    _roomSubscriptions.add(firebase.restartStream(code).listen((restart) {
      if (restart) {
        _enqueueCloudEvent(code, () async => _startNextGameFromCloud());
      }
    }));

    final disconnects = await firebase.watchDisconnects(code);
    _roomSubscriptions.add(disconnects.listen((left) {
      if (left && !_roomStarted) {
        // Lobby: nobody's board state is at stake. Prune whoever actually
        // went offline (presence check) so seats shift up — if the host
        // left, the next player inherits the start button.
        _handleLobbyDeparture(code);
        return;
      }
      if (left && !waitingForRejoin) {
        // Freeze the room and remember the exact UI state to restore.
        _stateBeforeDisconnect = (
          title: titleMessage,
          loading: isLoading,
          mainLoading: isMainLoading,
          click: canClick,
          message: mainLoadingMessage,
        );
        waitingForRejoin = true;
        canClick = false;
        isLoading = false;
        isMainLoading = true;
        mainLoadingMessage =
            'A player disconnected —\nwaiting for them to return';
        onToast?.call('player left', ToastTone.error);
        notifyListeners();
      } else if (!left && waitingForRejoin) {
        // They're back (their client cleared the flag): resume exactly
        // where the room was frozen.
        waitingForRejoin = false;
        final previous = _stateBeforeDisconnect;
        _stateBeforeDisconnect = null;
        if (previous != null) {
          titleMessage = previous.title;
          isLoading = previous.loading;
          isMainLoading = previous.mainLoading;
          canClick = previous.click;
          mainLoadingMessage = previous.message;
        } else {
          isMainLoading = false;
          mainLoadingMessage = null;
          canClick = true;
        }
        onToast?.call('player is back!', ToastTone.success);
        notifyListeners();
      }
    }));

    // Self-heal after our OWN connection blip: the server flipped the shared
    // disconnect flag on our behalf, freezing everyone (including us once we
    // reconnect and receive it). On regaining the connection, clear and
    // re-arm the flag so the whole room resumes automatically.
    var wasConnected = true;
    _roomSubscriptions.add(firebase.connectionStream().listen((connected) {
      if (connected && !wasConnected && isLive && roomCode == code) {
        firebase.rearmDisconnect(code).catchError(
            (Object error) => debugPrint('rearm failed: $error'));
      }
      wasConnected = connected;
    }));
  }

  /// A player left while the room was still in the lobby. The first ONLINE
  /// seat acts as caretaker: it prunes offline seats from the room record
  /// (everyone else recomputes their seat — and the start button — from the
  /// room stream) and resets the shared disconnect flag.
  Future<void> _handleLobbyDeparture(String code) async {
    try {
      final room = await firebase.getRoom(code);
      if (room == null || room['status'] == 'started') return;
      final seats = [
        for (final id in (room['players'] as List? ?? const [])) id.toString(),
      ];
      final online = <String>[];
      for (final uid in seats) {
        if (await firebase.isPlayerOnline(uid)) online.add(uid);
      }
      final uid = firebase.uid;
      if (uid == null || online.isEmpty || online.first != uid) return;

      // We are the acting host now (the room stream broadcasts the pruned
      // seat list, which is where the "player left" toast comes from).
      if (online.length != seats.length) {
        await firebase.setRoomPlayers(code, room, online);
      }
      await firebase.rearmDisconnect(code);
    } catch (error) {
      debugPrint('lobby departure handling failed: $error');
    }
  }

  /// A restart arrived from the room: everyone's board resets, deferred
  /// player counts apply, and waiting-room players enter the game.
  void _startNextGameFromCloud() {
    if (_pendingPlayerCount != null) {
      playerCount = _pendingPlayerCount!.clamp(1, AppConstants.maxPlayers);
      _pendingPlayerCount = null;
    }
    final wasWaiting = waitingForNextGame;
    waitingForNextGame = false;
    // A fresh game supersedes any disconnect freeze.
    waitingForRejoin = false;
    _stateBeforeDisconnect = null;
    isMainLoading = false;
    mainLoadingMessage = null;
    restartGame(fromCloud: true);
    if (wasWaiting) {
      onToast?.call('You are in — new game started!', ToastTone.success);
    }
  }

  void startOnlineGame() {
    _roomStarted = true;
    isMainLoading = false;
    mainLoadingMessage = null;
    titleMessage = TitleMessages.chainReaction;
    canClick = true;
    firebase.setRoomStarted(roomCode);
    notifyListeners();
  }

  void leaveRoom() {
    final code = roomCode;
    final roomWasStarted = _roomStarted;
    isLive = false;
    playerCount = AppConstants.minPlayers;
    isMainLoading = false;
    isLoading = false;
    waitingForNextGame = false;
    waitingForRejoin = false;
    _stateBeforeDisconnect = null;
    _roomStarted = false;
    mainLoadingMessage = null;
    _pendingPlayerCount = null;
    _lastRoomCount = null;
    roomCode = '••••';
    titleMessage = TitleMessages.chainReaction;
    // Stop listening first (so we don't react to our own signal). In the
    // lobby, free our seat so the next player inherits it (and the start
    // button); then fire the left-signal either way. Skipped entirely when
    // no room was ever claimed (e.g. create-room failure).
    _cancelRoomSubscriptions().then((_) async {
      if (code == '••••') return;
      if (!roomWasStarted) {
        await firebase.removeFromRoom(code, firebase.uid ?? '');
      }
      await firebase.signalLeft(code);
    }).catchError(
        (Object error) => debugPrint('leave signal failed: $error'));
    restartGame();
  }

  String get shareText => 'CODE: $roomCode\nLINK: ${AppConstants.gameLink}';

  Future<void> _cancelRoomSubscriptions() async {
    for (final subscription in _roomSubscriptions) {
      await subscription.cancel();
    }
    _roomSubscriptions.clear();
  }

  @override
  void dispose() {
    _likesSubscription?.cancel();
    _cancelRoomSubscriptions();
    super.dispose();
  }
}
