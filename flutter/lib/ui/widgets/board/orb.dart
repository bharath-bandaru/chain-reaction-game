import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Renders 1, 2 or 3 orbs inside a cell, replicating the SVG "actors" from
/// the web app (`ActorOne/Two/Three.js`): filled circles with a dark outline,
/// arranged singly, diagonally, or in a triangle.
///
/// A short scale "pop" plays whenever the orb count changes. The last placed
/// orb (`glitch: true`) plays a proper digital glitch every 5 seconds: the
/// orb is sliced into horizontal bands that displace in steppy random frames
/// with RGB channel separation, then snaps back to normal.
class Orb extends StatefulWidget {
  const Orb({
    super.key,
    required this.state,
    required this.color,
    required this.cellSize,
    this.glitch = false,
  });

  final int state;
  final Color color;
  final double cellSize;

  /// Marks the last placed move with the recurring glitch effect.
  final bool glitch;

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with SingleTickerProviderStateMixin {
  /// Full cycle: quiet for most of it, glitch burst at the end — so a
  /// freshly placed orb stays clean for the first ~2.6s.
  static const _cycle = Duration(seconds: 3);

  /// Portion of the cycle occupied by the burst (~350ms of 3s).
  static const _burstFraction = 0.12;

  /// Discrete "frames" within one burst — glitches jump, they don't glide.
  static const _burstFrames = 7;

  late final AnimationController _glitchController = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  @override
  void initState() {
    super.initState();
    if (widget.glitch) _glitchController.repeat();
  }

  @override
  void didUpdateWidget(Orb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glitch && !_glitchController.isAnimating) {
      _glitchController.repeat();
    } else if (!widget.glitch && _glitchController.isAnimating) {
      _glitchController.stop();
      _glitchController.value = 0;
    }
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state <= 0) return const SizedBox.shrink();

    // Subtle settle-in: starts near full size so an orb arriving from an
    // explosion hands off without a visible shrink, then overshoots gently.
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.state),
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedBuilder(
        animation: _glitchController,
        builder: (context, _) {
          final t = _glitchController.value;
          var frame = -1;
          if (widget.glitch && t > 1 - _burstFraction) {
            final phase = (t - (1 - _burstFraction)) / _burstFraction;
            frame = (phase * _burstFrames).floor().clamp(0, _burstFrames - 1);
          }
          return CustomPaint(
            size: Size.square(widget.cellSize),
            painter: _OrbPainter(
              state: widget.state,
              color: widget.color,
              glitchFrame: frame,
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.state,
    required this.color,
    this.glitchFrame = -1,
  });

  final int state;
  final Color color;

  /// Current glitch frame (-1 = not glitching). Each frame produces its own
  /// deterministic set of band displacements.
  final int glitchFrame;

  // Circle centers + viewbox sizes lifted from the web app's SVGs.
  // Each tuple: (viewBoxW, viewBoxH, targetWidthFraction, centers).
  static const _one = (60.0, 60.0, 0.37, [Offset(30, 30)]);
  static const _two = (82.0, 90.0, 0.51, [Offset(30, 30), Offset(52, 60)]);
  static const _three = (
    104.0,
    90.0,
    0.65,
    [Offset(52, 30), Offset(30, 60), Offset(74, 60)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final (viewW, viewH, widthFraction, centers) = switch (state) {
      1 => _one,
      2 => _two,
      _ => _three,
    };

    final scale = size.width * widthFraction / viewW;
    final origin = Offset(
      (size.width - viewW * scale) / 2,
      (size.height - viewH * scale) / 2,
    );
    final scaledCenters = [for (final c in centers) origin + c * scale];
    final radius = 29.5 * scale;

    if (glitchFrame < 0) {
      _drawOrbs(canvas, scaledCenters, radius, Offset.zero);
      return;
    }

    // Glitch burst: slice the cell into horizontal bands; each band shows
    // the orb displaced sideways with RGB-separated ghost copies. Offsets
    // are seeded per frame so the effect jumps frame to frame.
    final rand = math.Random(1337 + glitchFrame * 7919 + state);
    const bands = 6;
    final bandHeight = size.height / bands;

    final ghostCyan = Paint()
      ..color = const Color(0xFF00FFF7).withValues(alpha: 0.55);
    final ghostRed = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.55);

    for (var b = 0; b < bands; b++) {
      // Some bands stay put; the rest jump hard.
      final jumps = rand.nextDouble() < 0.65;
      final shift = jumps
          ? (rand.nextDouble() * 2 - 1) * size.width * 0.14
          : (rand.nextDouble() * 2 - 1) * size.width * 0.02;
      final split = rand.nextDouble() * size.width * 0.06;

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, b * bandHeight, size.width, bandHeight + 0.5),
      ); // +0.5 avoids hairline seams
      canvas.translate(shift, 0);

      for (final c in scaledCenters) {
        canvas.drawCircle(c - Offset(split, 0), radius, ghostCyan);
        canvas.drawCircle(c + Offset(split, 0), radius, ghostRed);
      }
      _drawOrbs(canvas, scaledCenters, radius, Offset.zero);

      canvas.restore();
    }
  }

  void _drawOrbs(
    Canvas canvas,
    List<Offset> centers,
    double radius,
    Offset shift,
  ) {
    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = AppColors.cellFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final c in centers) {
      canvas.drawCircle(c + shift, radius, fill);
      canvas.drawCircle(c + shift, radius, outline);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.color != color ||
      oldDelegate.glitchFrame != glitchFrame;
}
