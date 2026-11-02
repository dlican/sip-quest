import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/cards.dart';
import '../theme/palette.dart';
import 'sprites.dart';

Sprite suitSprite(Suit s) => switch (s) {
      Suit.hearts => Sprites.heart,
      Suit.diamonds => Sprites.diamond,
      Suit.clubs => Sprites.club,
      Suit.spades => Sprites.spade,
    };

/// Card proportions are 5:7, like a real poker card.
const double kCardRatio = 5 / 7;

class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, required this.width});
  final PlayingCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final h = width / kCardRatio;
    final ink = card.suit.isRed ? pal.cardRed : pal.cardBlack;
    final px = (width / 26).floorToDouble().clamp(2.0, 12.0);
    final corner = PixelFonts.title(ink, size: max(10, width / 9));

    Widget cornerMark() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.rankLabel, style: corner),
            SizedBox(height: px),
            PixelSprite(suitSprite(card.suit), pixel: px / 2),
          ],
        );

    final isFace = card.rank >= 11;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: pal.cardFace,
        border: Border.all(color: pal.cardBlack, width: max(3, px / 1.5)),
        boxShadow: const [BoxShadow(color: Color(0xAA000000), offset: Offset(6, 6))],
      ),
      child: Stack(
        children: [
          Positioned(left: px * 1.5, top: px * 1.5, child: cornerMark()),
          Positioned(
            right: px * 1.5,
            bottom: px * 1.5,
            child: Transform.rotate(angle: pi, child: cornerMark()),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFace && card.rank == 13)
                  PixelSprite(Sprites.crown, pixel: px * 0.9),
                if (isFace) SizedBox(height: px),
                PixelSprite(suitSprite(card.suit), pixel: isFace ? px * 1.2 : px * 1.8),
                if (isFace) ...[
                  SizedBox(height: px),
                  Text(card.rankLabel, style: PixelFonts.title(ink, size: width / 5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      width: width,
      height: width / kCardRatio,
      decoration: BoxDecoration(
        color: pal.cardFace,
        border: Border.all(color: pal.cardBlack, width: 3),
        boxShadow: const [BoxShadow(color: Color(0xAA000000), offset: Offset(4, 4))],
      ),
      padding: EdgeInsets.all(width / 14),
      child: CustomPaint(painter: _BackPainter(pal)),
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.pal);
  final SipPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = max(4.0, (size.width / 10).floorToDouble());
    final a = Paint()..color = pal.cardBackA;
    final b = Paint()..color = pal.cardBackB;
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final i = (x / cell).round() + (y / cell).round();
        // Diagonal diamond stripes: a classic 8-bit card back.
        canvas.drawRect(
          Rect.fromLTWH(x, y, min(cell, size.width - x), min(cell, size.height - y)),
          i % 3 == 0 ? b : a,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) => old.pal != pal;
}

/// Animates a card from face-down to face-up with a 3D Y-axis flip.
/// Re-runs whenever [card] changes.
class FlippingCard extends StatefulWidget {
  const FlippingCard({super.key, required this.card, required this.width});
  final PlayingCard card;
  final double width;

  @override
  State<FlippingCard> createState() => _FlippingCardState();
}

class _FlippingCardState extends State<FlippingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();

  @override
  void didUpdateWidget(FlippingCard old) {
    super.didUpdateWidget(old);
    if (old.card != widget.card) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_c.value).clamp(0.0, 1.1);
        // Rises from the deck (below) while it turns over.
        final angle = pi * (1 - _c.value.clamp(0.0, 1.0));
        final showFace = angle < pi / 2;
        final lift = (1 - t) * 120;
        final scale = 0.7 + 0.3 * t;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle);
        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: m,
              child: showFace
                  ? CardFace(card: widget.card, width: widget.width)
                  : CardBack(width: widget.width),
            ),
          ),
        );
      },
    );
  }
}
