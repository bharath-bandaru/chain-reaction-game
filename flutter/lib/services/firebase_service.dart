import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Thin wrapper around Firebase Auth + Realtime Database.
///
/// Mirrors the web app's database contract exactly so web and mobile players
/// share rooms:
///   * `players/{uid}`        — presence flags
///   * `likes`                — global like counter
///   * `numOfVisits`          — visit counter
///   * `events/{name}`        — analytics-style event counters
///   * `gameOver` / `gameOverOnline` — finished game counters
///   * `groups/{code}`        — pool of unused 4-char room codes
///   * `online/{code}`        — room membership + status
///   * `hooks/{code}`         — move stream for a room
///   * `restartHook/{code}`   — restart signal
///   * `disconnectHook/{code}`— player-left signal
///
/// Every method is a safe no-op when Firebase failed to initialize, so the
/// game remains fully playable offline (local + AI modes).
class FirebaseService {
  bool _available = false;
  FirebaseDatabase? _database;
  User? _user;

  bool get isAvailable => _available;
  String? get uid => _user?.uid;

  DatabaseReference? _ref(String path) => _database?.ref(path);

  /// Initializes Firebase and signs in anonymously (same flow as the web
  /// app's `signIn` + `onAuthStateChanged` presence bookkeeping).
  Future<void> init() async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      _database = FirebaseDatabase.instance;
      final credential = await FirebaseAuth.instance.signInAnonymously();
      _user = credential.user;
      _available = _user != null;
      if (_available) await _registerPresence();
    } catch (error) {
      debugPrint('Firebase unavailable, running offline: $error');
      _available = false;
    }
  }

  Future<void> _registerPresence() async {
    // Standard Firebase presence pattern: re-assert on EVERY (re)connect.
    // `onDisconnect(false)` fires once per drop, so without re-assertion a
    // player would look permanently offline after any network blip — and
    // the lobby caretaker (which reads presence) would wrongly prune them.
    final playerRef = _ref('players/${_user!.uid}')!;
    connectionStream().listen((connected) async {
      if (!connected) return;
      try {
        await playerRef.set({'id': true});
        await playerRef.onDisconnect().set(false);
      } catch (error) {
        debugPrint('presence re-assert failed: $error');
      }
    });
    await _increment('numOfVisits');
  }

  /// Reads an int counter at [path] and writes it back incremented.
  Future<void> _increment(String path) async {
    final ref = _ref(path);
    if (ref == null) return;
    try {
      final snapshot = await ref.get();
      final value = (snapshot.value as num?)?.toInt() ?? 0;
      await ref.set(value + 1);
    } catch (error) {
      debugPrint('increment $path failed: $error');
    }
  }

  // ---------------------------------------------------------------- likes

  Stream<int?> likesStream() {
    final ref = _ref('likes');
    if (ref == null) return const Stream.empty();
    return ref.onValue.map((event) => (event.snapshot.value as num?)?.toInt());
  }

  Future<void> addLike() => _increment('likes');

  // --------------------------------------------------------------- events

  /// Counts an event under `events/{name}` (web `logEventOnFirebase`).
  Future<void> logEvent(String name) => _increment('events/$name');

  Future<void> countGameOver({required bool online}) =>
      _increment(online ? 'gameOverOnline' : 'gameOver');

  // ---------------------------------------------------------------- rooms

  /// Claims a room code from the `groups` pool and creates the room.
  /// Returns the room code, or null when unavailable.
  Future<String?> createRoom() async {
    if (!_available) return null;
    final groupsRef = _ref('groups')!;
    var snapshot = await groupsRef.get();
    if (!snapshot.exists) {
      await _generateGroupIds();
      snapshot = await groupsRef.get();
      if (!snapshot.exists) return null;
    }
    final groups = Map<String, dynamic>.from(snapshot.value as Map);
    final key = groups.keys.firstWhere((k) => k != 'count', orElse: () => '');
    if (key.isEmpty) return null;

    await _ref('groups/$key')!.remove();
    await _ref('online/$key')!.set({
      'players': [_user!.uid],
      'n': 1,
      'status': 'waiting',
      // Board size marker; web clients ignore it and always play 6x9 ('0').
      'board': '0',
    });
    await _ref('hooks/$key')!.set({'move': null, 'nextPlayer': 0});
    return key;
  }

  /// Refills the room-code pool (web `generateGroupIds`). Writes the codes in
  /// a single multi-path update instead of 10k individual writes.
  Future<void> _generateGroupIds() async {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final codes = <String>{};
    while (codes.length < 10000) {
      codes.add(List.generate(
              4, (_) => characters[random.nextInt(characters.length)])
          .join());
    }
    final updates = {for (final code in codes) code: {'emp': 'val'}};
    await _ref('groups')!.update(updates);
  }

  Future<Map<String, dynamic>?> getRoom(String code) async {
    final ref = _ref('online/$code');
    if (ref == null) return null;
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> joinRoom(
      String code, Map<String, dynamic> room, List<String> players) async {
    await _ref('online/$code')!.set({
      ...room,
      'n': (room['n'] as num).toInt() + 1,
      'players': players,
    });
  }

  /// Whether [uid]'s presence node says they are currently connected
  /// (`players/{uid}` is set on sign-in and flipped false by onDisconnect).
  Future<bool> isPlayerOnline(String uid) async {
    final ref = _ref('players/$uid');
    if (ref == null) return false;
    try {
      final value = (await ref.get()).value;
      if (value is Map) return value['id'] == true;
      return value == true;
    } catch (_) {
      return false;
    }
  }

  /// Rewrites the room's seat list (used to prune players who left while
  /// the room was still in the lobby).
  Future<void> setRoomPlayers(
      String code, Map<String, dynamic> room, List<String> players) async {
    await _ref('online/$code')!.set({
      ...room,
      'players': players,
      'n': players.length,
    });
  }

  /// Removes [uid]'s seat from a lobby room; deletes the room when it was
  /// the last seat.
  Future<void> removeFromRoom(String code, String uid) async {
    final room = await getRoom(code);
    if (room == null) return;
    final players = [
      for (final id in (room['players'] as List? ?? const []))
        if (id.toString() != uid) id.toString(),
    ];
    if (players.isEmpty) {
      await _ref('online/$code')!.remove();
    } else {
      await setRoomPlayers(code, room, players);
    }
  }

  Future<void> setRoomStarted(String code) async {
    await _ref('online/$code/status')?.set('started');
  }

  Stream<Map<String, dynamic>?> roomStream(String code) {
    final ref = _ref('online/$code');
    if (ref == null) return const Stream.empty();
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return Map<String, dynamic>.from(value as Map);
    });
  }

  // ---------------------------------------------------------------- moves

  Future<void> sendMove(String code, int i, int j, int nextPlayer,
      String senderId) async {
    await _ref('hooks/$code')?.set({
      'move': {'i': i, 'j': j},
      'nextPlayer': nextPlayer,
      'uuid': senderId,
    });
  }

  /// The web app signals a restart by sending move (-1, -1).
  Future<void> sendRestart(String code) async {
    await _ref('hooks/$code')?.set({
      'move': {'i': -1, 'j': -1},
    });
  }

  Stream<Map<String, dynamic>?> moveStream(String code) {
    final ref = _ref('hooks/$code');
    if (ref == null) return const Stream.empty();
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return Map<String, dynamic>.from(value as Map);
    });
  }

  Stream<bool> restartStream(String code) {
    final ref = _ref('restartHook/$code');
    if (ref == null) return const Stream.empty();
    return ref.onValue.map((event) => event.snapshot.value == true);
  }

  // ----------------------------------------------------------- disconnect

  /// Resets the disconnect flag, arms `onDisconnect`, and returns a stream
  /// that emits when any player in the room drops.
  Future<Stream<bool>> watchDisconnects(String code) async {
    final ref = _ref('disconnectHook/$code');
    if (ref == null) return const Stream.empty();
    await ref.set(false);
    await ref.onDisconnect().set(true);
    return ref.onValue.map((event) => event.snapshot.value == true);
  }

  /// Explicit leave: fires the same signal `onDisconnect` would, so the
  /// other players learn immediately instead of waiting for our connection
  /// to actually drop, and disarms our pending `onDisconnect` write.
  Future<void> signalLeft(String code) async {
    final ref = _ref('disconnectHook/$code');
    if (ref == null) return;
    await ref.onDisconnect().cancel();
    await ref.set(true);
  }

  /// Emits the client's RTDB connection state (`.info/connected`).
  Stream<bool> connectionStream() {
    final ref = _database?.ref('.info/connected');
    if (ref == null) return const Stream.empty();
    return ref.onValue.map((event) => event.snapshot.value == true);
  }

  /// After our own connection blip: the server flipped `disconnectHook` on
  /// our behalf, freezing the room. Clear it (everyone resumes, including
  /// us) and re-arm `onDisconnect` for the next drop.
  Future<void> rearmDisconnect(String code) async {
    final ref = _ref('disconnectHook/$code');
    if (ref == null) return;
    await ref.set(false);
    await ref.onDisconnect().set(true);
  }
}
