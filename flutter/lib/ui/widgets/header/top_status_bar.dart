import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/game_controller.dart';

/// Top overlay row, rendered just below the system status bar: the global
/// like counter with a heart, aligned right.
///
/// The counter reveals itself when the app opens and, after a couple of
/// seconds, disintegrates into dust — tiny motes crumble off left-to-right
/// and drift upward. A like (yours, or anyone's arriving through the live
/// counter) brings it back for another round. The (invisible) spot stays
/// tappable, so tapping the corner always likes and reveals.
class TopStatusBar extends StatefulWidget {
  const TopStatusBar({super.key, required this.onLike});

  final VoidCallback onLike;

  @override
  State<TopStatusBar> createState() => _TopStatusBarState();
}

class _TopStatusBarState extends State<TopStatusBar>
    with SingleTickerProviderStateMixin {
  static const Duration _visibleFor = Duration(seconds: 2);
  static const Duration _dustDuration = Duration(milliseconds: 900);

  late final GameController _game;
  late final AnimationController _dust = AnimationController(
    vsync: this,
    duration: _dustDuration,
  );

  bool _visible = true;
  Timer? _hideTimer;
  int? _lastLikes;
  int _lastPulse = 0;
  int _dustSeed = 7;

  @override
  void initState() {
    super.initState();
    _game = context.read<GameController>();
    _lastLikes = _game.numberOfLikes;
    _lastPulse = _game.likePulse;
    _game.addListener(_onGameChanged);
    _dust.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
    _scheduleDust();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _dust.dispose();
    _game.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    // Reveal on any like activity: a local tap (pulse) or the live counter
    // changing (someone, possibly us, liked).
    if (_game.numberOfLikes != _lastLikes || _game.likePulse != _lastPulse) {
      _lastLikes = _game.numberOfLikes;
      _lastPulse = _game.likePulse;
      _reveal();
    }
  }

  void _reveal() {
    if (!mounted) return;
    _dust.stop();
    _dust.value = 0;
    setState(() => _visible = true);
    _scheduleDust();
  }

  void _scheduleDust() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleFor, () {
      if (!mounted) return;
      _dustSeed = math.Random().nextInt(1 << 30);
      _dust.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final likes = context.select<GameController, int?>((g) => g.numberOfLikes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: widget.onLike,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _dust,
            builder: (context, child) {
              if (!_visible) return Opacity(opacity: 0, child: child);
              return CustomPaint(
                foregroundPainter: _dust.value > 0
                    ? _DustPainter(progress: _dust.value, seed: _dustSeed)
                    : null,
                child: _SweepFade(progress: _dust.value, child: child!),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    likes?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Muted heart, same color as the count text.
                  const Icon(Icons.favorite, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Erases the content with a soft left-to-right sweep, so the pixels vanish
/// where the dust motes are breaking away.
class _SweepFade extends StatelessWidget {
  const _SweepFade({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return child;
    return ShaderMask(
      shaderCallback: (bounds) {
        // The erased edge leads the sweep slightly ahead of the particles.
        final edge = (progress * 1.35).clamp(0.0, 1.0);
        final soft = (edge + 0.25).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.transparent, Colors.white],
          stops: [edge, soft],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

/// The dust itself: a wind gust from the left carries the motes off to the
/// right — a fast initial puff that decelerates into a drift, with a light
/// turbulent wobble — while they shrink and dim.
class _DustPainter extends CustomPainter {
  _DustPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  static const int _motes = 70;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0) return;
    final rand = math.Random(seed);

    for (var i = 0; i < _motes; i++) {
      final sx = rand.nextDouble() * size.width;
      final sy = rand.nextDouble() * size.height;
      // The gust hits the left edge first, sweeping across to the right.
      final delay = (sx / size.width) * 0.5 + rand.nextDouble() * 0.15;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOut.transform(t);
      // Carried rightward by the wind, with a slight upward lift and a
      // sinusoidal wobble like real dust in an air stream.
      final carry = 30 + rand.nextDouble() * 55;
      final lift = -(2 + rand.nextDouble() * 8);
      final wobblePhase = rand.nextDouble() * math.pi * 2;
      final wobble = math.sin(t * math.pi * 3 + wobblePhase) * 2.0;
      final position = Offset(
        sx + carry * eased,
        sy + lift * eased + wobble,
      );
      final radius = (0.4 + rand.nextDouble() * 0.7) * (1 - t * 0.5);
      canvas.drawCircle(
        position,
        radius,
        Paint()..color = Colors.white.withValues(alpha: (1 - t) * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.seed != seed;
}
