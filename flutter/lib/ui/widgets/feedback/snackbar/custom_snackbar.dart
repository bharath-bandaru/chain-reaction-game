import 'dart:async';
import 'dart:math' as math;

import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_type.dart';
import 'default_colors.dart';
import '../../../../core/haptics.dart';

/// Public Snackbar facade — `Snackbar.show(...)` / `Snackbar.dismiss()`.
/// Visual is a Duolingo-style pill (up to two lines, fully rounded ends,
/// chunky dual shadow) that always enters from the top with a 4-keyframe
/// squash-and-stretch.
class Snackbar {
  static OverlayEntry? _currentEntry;
  static _SnackbarWidgetState? _currentState;

  static void show(
    BuildContext context, {
    String? title, // Deprecated, kept for backwards compatibility
    required String message,
    required ContentType contentType,
    Duration duration = const Duration(milliseconds: 3500),
    OverlayState? overlay,
    // Optional fixed emoji override. When null the pill picks a random
    // emoji for the tone (the default behavior); pass one to lock a
    // context-specific emoji (e.g. the offline 😶‍🌫️ face). [emojiGlyph]
    // is the static fallback shown if the animated asset fails to load.
    AnimatedEmojiData? emoji,
    String emojiGlyph = '',
    // Fired once the pill has finished dismissing — for ANY reason (user
    // tap/swipe, auto-dismiss timer, or being replaced by a fresh show()).
    // Lets callers react (e.g. revive a persistent offline pill).
    VoidCallback? onDismissed,
    // Anchor the pill to the bottom instead of the default top. Used only
    // for the persistent offline pill; everything else stays at the top.
    bool bottom = false,
  }) {
    // Stack-safe: a fresh snackbar slides the previous one out first.
    dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SnackbarWidget(
        message: message,
        contentType: contentType,
        duration: duration,
        bottom: bottom,
        emojiOverride: emoji,
        emojiGlyphOverride: emojiGlyph,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentState = null;
          }
          onDismissed?.call();
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentEntry = entry;
    final targetOverlay = overlay ?? Overlay.of(context, rootOverlay: true);
    targetOverlay.insert(entry);
  }

  static void dismiss() {
    _currentState?.dismiss();
  }
}

class _SnackbarWidget extends StatefulWidget {
  final String message;
  final ContentType contentType;
  final Duration duration;
  final bool bottom;
  final VoidCallback onDismiss;
  final void Function(_SnackbarWidgetState) onStateCreated;
  final AnimatedEmojiData? emojiOverride;
  final String emojiGlyphOverride;

  const _SnackbarWidget({
    required this.message,
    required this.contentType,
    required this.duration,
    required this.onDismiss,
    required this.onStateCreated,
    this.bottom = false,
    this.emojiOverride,
    this.emojiGlyphOverride = '',
  });

  @override
  State<_SnackbarWidget> createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget>
    with TickerProviderStateMixin {
  // Drives the 4-keyframe entry + reverse exit. Drives the whole
  // scene's translate / scale / opacity.
  late final AnimationController _entry;

  // Tap-down feedback: scene scales briefly to 0.96 before dismiss.
  late final AnimationController _tapScale;

  // Continuous gentle bob — kicks in once the entry settles, gives
  // the pill a subtle "alive" sway. ±3px on a 1200ms cycle.
  late final AnimationController _bob;

  Timer? _autoDismissTimer;

  Offset _dragOffset = Offset.zero;
  bool _isDismissing = false;
  bool _entryStarted = false;

  // Fixed for the pill's lifetime (rebuilds from drags/keyboard must not
  // reshuffle it). An explicit override wins; otherwise a random emoji is
  // chosen once for the tone.
  late final _PillEmoji _emoji = widget.emojiOverride != null
      ? (widget.emojiOverride!, widget.emojiGlyphOverride)
      : _pickEmojiForContentType(widget.contentType);

  static const Duration _entryDur = Duration(milliseconds: 700);
  static const Duration _exitDur = Duration(milliseconds: 340);

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _entry = AnimationController(
      duration: _entryDur,
      reverseDuration: _exitDur,
      vsync: this,
    );
    _tapScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    // Once the keyframe entry has overshot/rebounded into place,
    // start the continuous bob.
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _bob.repeat();
      }
    });

    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted && !_isDismissing) dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _entry.dispose();
    _tapScale.dispose();
    _bob.dispose();
    super.dispose();
  }

  void _startEntry() => _entry.forward();

  void _handleTap() {
    Haptics.tap();
    if (_isDismissing) return;
    HapticFeedback.selectionClick();
    // Quick scale-down press feedback, then dismiss.
    _tapScale.forward().then((_) {
      if (mounted) dismiss();
    });
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_isDismissing) return;
    // Free movement in both directions. The "away from exit"
    // direction gets a rubber-band dampening so it can't be yanked
    // far from its resting position.
    final dy = details.delta.dy;
    // The exit edge is up for a top pill (negative dy) and down for a bottom
    // pill (positive dy). The other direction gets rubber-band dampening so
    // it can't be yanked far from its resting position.
    final movingTowardExit = widget.bottom ? dy > 0 : dy < 0;
    final delta = movingTowardExit ? dy : dy * 0.4;
    setState(() => _dragOffset += Offset(0, delta));
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final speed = details.velocity.pixelsPerSecond.dy;
    final fastEnough = widget.bottom ? speed > 300 : speed < -300;
    final farEnough = _dragOffset.distance > 40;
    if (fastEnough || farEnough) {
      HapticFeedback.lightImpact();
      dismiss();
    } else {
      setState(() => _dragOffset = Offset.zero);
    }
  }

  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    _bob.stop();
    _entry.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  /// Interpolates the 4-keyframe entry animation:
  ///   0%   — translate(0, -120%) scale(0.6, 1.2) opacity 0 (above)
  ///   55%  — translate(0,  +8%) scale(1.08, 0.92) opacity 1 (impact)
  ///   75%  — translate(0,  -4%) scale(0.96, 1.04)            (rebound)
  ///   100% — translate(0,    0) scale(1, 1)                  (settled)
  ///
  /// dy is expressed as a fraction of the scene height (used with
  /// FractionalTranslation). Sign flipped for a bottom pill so it drops in
  /// from below instead of above.
  _EntryState _interpolateEntry(double t) {
    final dySign = widget.bottom ? -1.0 : 1.0;
    double easeInOut(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    double lerp(double a, double b, double f) => a + (b - a) * f;

    // Keyframe values: (dy, sx, sy, opacity)
    const k0 = [-1.2, 0.6, 1.2, 0.0];
    const k1 = [0.08, 1.08, 0.92, 1.0];
    const k2 = [-0.04, 0.96, 1.04, 1.0];
    const k3 = [0.0, 1.0, 1.0, 1.0];

    List<double> from;
    List<double> to;
    double f;
    if (t <= 0.55) {
      from = k0;
      to = k1;
      f = easeInOut(t / 0.55);
    } else if (t <= 0.75) {
      from = k1;
      to = k2;
      f = easeInOut((t - 0.55) / 0.20);
    } else {
      from = k2;
      to = k3;
      f = easeInOut((t - 0.75) / 0.25);
    }

    return _EntryState(
      dy: lerp(from[0], to[0], f) * dySign,
      sx: lerp(from[1], to[1], f),
      sy: lerp(from[2], to[2], f),
      opacity: lerp(from[3], to[3], f).clamp(0.0, 1.0),
    );
  }

  /// Dismiss interpolation: a clean slide off the nearest edge + fade, with
  /// NO squash/stretch. Reversing the bouncy entry keyframes was what caused
  /// the "swoosh"; the exit instead just glides toward its edge so it reads
  /// as a smooth continuation of the slide.
  ///
  /// [t] mirrors `_entry.value` running 1 → 0 on reverse: 1 = fully
  /// shown, 0 = gone.
  _EntryState _interpolateExit(double t) {
    final dySign = widget.bottom ? -1.0 : 1.0;
    final gone = Curves.easeInOutCubic.transform((1 - t).clamp(0.0, 1.0));
    return _EntryState(
      dy: -1.2 * gone * dySign,
      sx: 1.0,
      sy: 1.0,
      opacity: 1.0 - gone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Lift a bottom pill above the keyboard when it's open so it never hides
    // behind it; otherwise sit just above the home indicator.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Kick off the entry animation on the first build.
    if (!_entryStarted) {
      _entryStarted = true;
      _startEntry();
    }

    final tone = _toneForContentType(widget.contentType);

    return Positioned(
      // ~8px from the anchored edge — snug against the status bar (top) or
      // the home indicator / keyboard (bottom).
      top: widget.bottom ? null : topPadding + 8,
      bottom: widget.bottom
          ? (keyboardHeight > 0 ? keyboardHeight + 8 : bottomPadding + 8)
          : null,
      left: 16,
      right: 16,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: _handleVerticalDragEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([_entry, _tapScale]),
            builder: (context, child) {
              // Exit uses a smooth slide+fade (no squash) so dismissing —
              // especially after a slide-up — glides off cleanly instead
              // of replaying the bouncy entry keyframes in reverse.
              final state = _isDismissing
                  ? _interpolateExit(_entry.value)
                  : _interpolateEntry(_entry.value);
              // Tap-down briefly shrinks the whole scene to 0.96
              // before the dismiss reverse animation kicks in.
              final pressScale = 1.0 - 0.04 * _tapScale.value;
              return FractionalTranslation(
                translation: Offset(0, state.dy),
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform(
                    alignment: widget.bottom
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    transform: Matrix4.diagonal3Values(
                      state.sx * pressScale,
                      state.sy * pressScale,
                      1,
                    ),
                    child: Opacity(opacity: state.opacity, child: child),
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: _bob,
                builder: (context, child) {
                  // Subtle ±3px sine bob, same idiom as the
                  // celebration speech bubble.
                  final dy = math.sin(_bob.value * math.pi * 2) * 3.0;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: child,
                  );
                },
                child: _Pill(
                  message: widget.message,
                  tone: tone,
                  icon: _buildEmojiIcon(_emoji),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Result of the 4-keyframe entry interpolation.
class _EntryState {
  final double dy;
  final double sx;
  final double sy;
  final double opacity;
  const _EntryState({
    required this.dy,
    required this.sx,
    required this.sy,
    required this.opacity,
  });
}

/// Maps the existing [ContentType] enum to one of the three Duolingo
/// pill tones spec'd by design.
_PillTone _toneForContentType(ContentType type) {
  if (type == ContentType.success) return _PillTone.success;
  if (type == ContentType.help) return _PillTone.info;
  // failure + warning both use the warm-orange "error" tone — the
  // spec only defines three tones and warning is semantically the
  // same urgency family as error.
  return _PillTone.error;
}

/// (animated emoji, static fallback glyph) pair shown as the pill's
/// leading icon.
typedef _PillEmoji = (AnimatedEmojiData emoji, String glyph);

/// Five emojis per tone. One is picked at random each time a snackbar is
/// shown (chosen once in [_SnackbarWidgetState.initState] so it stays
/// stable for the pill's lifetime instead of reshuffling on rebuild).
const List<_PillEmoji> _successEmojis = [
  (AnimatedEmojis.partyingFace, '🥳'),
  (AnimatedEmojis.fire, '🔥'),
  (AnimatedEmojis.thumbsUp, '👍'),
  (AnimatedEmojis.confettiBall, '🎊'),
  (AnimatedEmojis.sparkles, '✨'),
];

const List<_PillEmoji> _infoEmojis = [
  (AnimatedEmojis.rocket, '🚀'),
  (AnimatedEmojis.eyes, '👀'),
  (AnimatedEmojis.moneyWithWings, '💸'),
  (AnimatedEmojis.nerdFace, '🤓'),
  (AnimatedEmojis.mindBlown, '🤯'),
];

const List<_PillEmoji> _failureEmojis = [
  (AnimatedEmojis.skull, '💀'),
  (AnimatedEmojis.melting, '🫠'),
  (AnimatedEmojis.upsideDownFace, '🙃'),
  (AnimatedEmojis.worried, '😟'),
  (AnimatedEmojis.loudlyCrying, '😭'),
];

final math.Random _emojiRng = math.Random();

/// Picks a random emoji for the tone. Info → [_infoEmojis], success →
/// [_successEmojis], failure/warning → [_failureEmojis].
_PillEmoji _pickEmojiForContentType(ContentType type) {
  final list = type == ContentType.help
      ? _infoEmojis
      : type == ContentType.success
      ? _successEmojis
      : _failureEmojis;
  return list[_emojiRng.nextInt(list.length)];
}

/// Builds the leading animated emoji (a touch larger than the text) with
/// a static glyph fallback if the Lottie asset/network fetch fails.
Widget _buildEmojiIcon(_PillEmoji emoji) {
  return AnimatedEmoji(
    emoji.$1,
    size: 30,
    errorWidget: Text(
      emoji.$2,
      style: const TextStyle(fontSize: 30, height: 1),
    ),
  );
}

/// Duolingo-style pill tones — solid bg + matching darker shadow.
/// Hex values live in [DefaultColors] so the palette has one source of
/// truth. Same values render in both light and dark mode (the pill is
/// intentionally loud against any scaffold).
class _PillTone {
  final Color background;
  final Color hardShadow;

  /// Text + icon color for this tone. White on the dark teal/red tones,
  /// near-black on the light amber tone (white would be unreadable on
  /// amber — see [DefaultColors]).
  final Color foreground;

  const _PillTone({
    required this.background,
    required this.hardShadow,
    required this.foreground,
  });

  static const error = _PillTone(
    background: DefaultColors.failureRed,
    hardShadow: DefaultColors.failureRedShadow,
    foreground: Colors.white,
  );
  static const success = _PillTone(
    background: DefaultColors.successGreen,
    hardShadow: DefaultColors.successGreenShadow,
    foreground: Colors.white,
  );
  static const info = _PillTone(
    background: DefaultColors.helpBlue,
    hardShadow: DefaultColors.helpBlueShadow,
    foreground: Colors.white,
  );
}

/// The Duolingo pill itself — fully rounded ends, dual chunky shadow,
/// icon + up to two lines of text.
class _Pill extends StatelessWidget {
  const _Pill({required this.message, required this.tone, required this.icon});

  final String message;
  final _PillTone tone;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final topBorderColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.4),
      tone.background,
    );

    return ConstrainedBox(
      // Bubble widened — minimum 260 so short messages still look
      // substantial; max 400 so the pill stretches comfortably on
      // most phones without dominating the screen.
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 400),
      child: Container(
        // Vertical padding bumped from 14 → 18 so the pill is
        // taller and more readable; right padding stays heavier than
        // left per the original spec.
        padding: const EdgeInsets.fromLTRB(18, 18, 22, 18),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(24),
          border: Border(top: BorderSide(color: topBorderColor, width: 2)),
          boxShadow: [
            // Hard 6px shadow in the matching dark tone — the 3D
            // "physical button" feel.
            BoxShadow(
              color: tone.hardShadow,
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
            // Soft ambient shadow grounding the pill on the page.
            const BoxShadow(
              color: Color(0x2E000000), // rgba(0,0,0,0.18)
              offset: Offset(0, 12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
              child: icon,
            ),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: tone.foreground,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
