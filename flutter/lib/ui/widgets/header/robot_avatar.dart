import 'package:flutter/material.dart';

/// Small robot indicator shown in place of the AI player's dot. While the AI
/// is searching for a move it shows animated "thinking" bars (the web app's
/// `cute-robot-v1 thinking` state).
class RobotAvatar extends StatelessWidget {
  const RobotAvatar({super.key, required this.thinking, required this.color});

  final bool thinking;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(
                color: thinking ? Colors.white : color,
                width: 2,
              ),
            ),
            child: Icon(Icons.smart_toy, size: 15, color: color),
          ),
          if (thinking) const Positioned(bottom: -1, child: _ThinkingBars()),
        ],
      ),
    );
  }
}

/// Three tiny bouncing bars.
class _ThinkingBars extends StatefulWidget {
  const _ThinkingBars();

  @override
  State<_ThinkingBars> createState() => _ThinkingBarsState();
}

class _ThinkingBarsState extends State<_ThinkingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 3,
                height: 3 + 4 * (0.5 + 0.5 * _phase(_controller.value, i / 3)),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Simple staggered triangle wave in [0, 1].
  double _phase(double t, double offset) {
    final x = (t + offset) % 1.0;
    return x < 0.5 ? x * 2 : (1 - x) * 2;
  }
}
