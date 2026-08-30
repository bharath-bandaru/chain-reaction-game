import 'package:flutter/material.dart';

/// Small robot indicator shown in place of the AI player's dot. On the AI's
/// turn (and while it searches for a move) the robot breathes with a soft
/// glow in the AI's color.
class RobotAvatar extends StatefulWidget {
  const RobotAvatar({super.key, required this.thinking, required this.color});

  final bool thinking;
  final Color color;

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.thinking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(RobotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thinking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.thinking && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = widget.thinking
                ? Curves.easeInOut.transform(_controller.value)
                : 0.0;
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
                border: Border.all(color: widget.color, width: 2),
                boxShadow: widget.thinking
                    ? [
                        BoxShadow(
                          color: widget.color
                              .withValues(alpha: 0.25 + 0.55 * glow),
                          blurRadius: 4 + 8 * glow,
                          spreadRadius: 0.5 + 2.5 * glow,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: Icon(
            Icons.smart_toy,
            size: 14,
            color: widget.thinking ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}
