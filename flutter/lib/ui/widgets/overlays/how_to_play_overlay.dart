import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Five-page tutorial overlay, ported from `HowToPlay.js`, with a close
/// button in the top-right corner. The "next" button floats above it in the
/// footer row (the undo spot), rendered by the game screen.
class HowToPlayOverlay extends StatelessWidget {
  const HowToPlayOverlay({
    super.key,
    required this.state,
    required this.onClose,
  });

  final int state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xE3000000),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: switch (state) {
                  0 => const _RulesPage(),
                  1 => const _CriticalMassPage(
                      number: '1',
                      numberColor: Color(0xFF05A8CD),
                      image: 'assets/images/edge_corner.png',
                      caption: 'EDGE CORNERS',
                      quote: '"1 explodes to 2!"',
                    ),
                  2 => const _CriticalMassPage(
                      number: '2',
                      numberColor: Color(0xFFCD00C5),
                      image: 'assets/images/edge.png',
                      caption: 'SIDES',
                      quote: '"2 explodes to 3!"',
                    ),
                  3 => const _CriticalMassPage(
                      number: '3',
                      numberColor: Color(0xFFCC0100),
                      image: 'assets/images/inner.png',
                      caption: 'INNER CELLS',
                      quote: '"3 explodes to 4!"',
                    ),
                  _ => const _ChainReactionPage(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      color: AppColors.accentYellow,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.number, this.color, {this.textColor = Colors.white});

  final String number;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(number,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _RulesPage extends StatelessWidget {
  const _RulesPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Heading('HOW TO PLAY?'),
        _NumberBadge('1', Color(0xFF05A8CD), textColor: Colors.black),
        _Quote('"A strategy game that can be played online '
            'for 2 to 4 players."'),
        _NumberBadge('2', Color(0xFFCD00C5)),
        _Quote('"The objective of the game is to take control of the board '
            'by eliminating your opponents\' balls. Players take turns to '
            'place their balls in a cell."'),
        _NumberBadge('3', AppColors.accentYellow, textColor: Colors.black),
        _Quote('"Once a cell reaches "critical mass", the balls explode into '
            'the surrounding cells adding an extra ball and claiming the '
            'cells of the player."'),
        _NumberBadge('4', Color(0xFFCC0100)),
        _Quote('"A player can only place their balls in a Blank cell (or) a '
            'cell that contains balls of their Own color. As soon as a '
            'player loses all their balls they are out of the game."'),
      ],
    );
  }
}

class _CriticalMassPage extends StatelessWidget {
  const _CriticalMassPage({
    required this.number,
    required this.numberColor,
    required this.image,
    required this.caption,
    required this.quote,
  });

  final String number;
  final Color numberColor;
  final String image;
  final String caption;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Heading('critical mass?'),
        _NumberBadge(number, numberColor),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Image.asset(image, width: 300),
        ),
        _Quote(caption, bold: true),
        _Quote(quote),
      ],
    );
  }
}

class _ChainReactionPage extends StatelessWidget {
  const _ChainReactionPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Heading('chain reaction!'),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Image.asset('assets/images/ch.gif', width: 300),
        ),
        const _Quote('"Now, you can play ONLINE with your friends!"'),
        const _Quote('"(Click 🚀 on bottom right)"'),
      ],
    );
  }
}
