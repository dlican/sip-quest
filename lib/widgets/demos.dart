import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/cards.dart';
import '../theme/palette.dart';
import 'playing_card.dart';
import 'sprites.dart';

/// Looping pixel-art animations for the how-to-play sheets. Each demo draws
/// on a fixed 280 x 160 stage that scales to the space it gets.
class DemoStage extends StatefulWidget {
  const DemoStage({super.key, required this.period, required this.builder});
  final Duration period;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<DemoStage> createState() => _DemoStageState();
}

class _DemoStageState extends State<DemoStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: pal.bg,
        border: Border.all(color: pal.border, width: 3),
      ),
      child: AspectRatio(
        aspectRatio: 280 / 160,
        child: FittedBox(
          child: SizedBox(
            width: 280,
            height: 160,
            child: ClipRect(
              child: AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _c.value)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eased progress of [t] through the window [a]..[b], 0 before and 1 after.
double seg(double t, double a, double b, [Curve curve = Curves.easeInOutCubic]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

bool between(double t, double a, double b) => t >= a && t < b;

Widget at(double x, double y, Widget child) => Positioned(left: x, top: y, child: child);

Widget fade(double v, Widget child) => Opacity(opacity: v.clamp(0.0, 1.0), child: child);

Widget popScale(double v, Widget child) => Opacity(
  opacity: v.clamp(0.0, 1.0),
  child: Transform.scale(scale: 0.5 + 0.5 * Curves.easeOutBack.transform(v), child: child),
);

class DemoPerson extends StatelessWidget {
  const DemoPerson({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelSprite(Sprites.head, pixel: 3, tint: {'A': pal.cardFace}),
        Container(
          width: 33,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: pal.cardBlack, width: 2),
          ),
        ),
      ],
    );
  }
}

class DemoBubble extends StatelessWidget {
  const DemoBubble(this.text, {super.key, this.color, this.size = 18});
  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: pal.cardFace,
        border: Border.all(color: color ?? pal.cardBlack, width: 2),
      ),
      child: Text(text, style: PixelFonts.body(pal.cardBlack, size: size).copyWith(height: 1)),
    );
  }
}

class DemoCaption extends StatelessWidget {
  const DemoCaption(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: TextAlign.center, style: PixelFonts.title(color ?? context.pal.accent, size: 8));
}

/// A card turning over: [p] 0 = back, 1 = face.
Widget flipCard(double p, PlayingCard card, double width) {
  final angle = pi * (1 - p);
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateY(angle),
    child: angle < pi / 2 ? CardFace(card: card, width: width) : CardBack(width: width),
  );
}

List<Color> _crowd(SipPalette p) => [p.primary, p.secondary, p.accent, p.textDim];

// --- One demo per game ----------------------------------------------------

Widget kingsCupDemo(BuildContext context, double t) {
  final pal = context.pal;
  final fly = seg(t, 0.12, 0.42);
  final flip = seg(t, 0.25, 0.45);
  return Stack(
    children: [
      at(36, 52, PixelSprite(Sprites.crownEmpty, pixel: 5)),
      at(28, 112, const DemoCaption('POT')),
      at(118, 44, const CardBack(width: 44)),
      at(115, 41, const CardBack(width: 44)),
      at(115 + 90 * fly, 41 - 10 * sin(fly * pi), flipCard(flip, const PlayingCard(13, Suit.hearts), 44)),
      at(206, 14, popScale(seg(t, 0.5, 0.62), PixelSprite(Sprites.crown, pixel: 3))),
      at(
        0,
        136,
        SizedBox(width: 280, child: fade(seg(t, 0.5, 0.6), DemoCaption('KING: ADD A PENALTY TO THE POT', color: pal.text))),
      ),
    ],
  );
}

Widget oneOfAKindDemo(BuildContext context, double t) {
  final pal = context.pal;
  final c = _crowd(pal);
  const xs = [36.0, 122.0, 208.0];
  const answers = ['APPLE', 'APPLE', 'KIWI'];
  final show = seg(t, 0.2, 0.32);
  final judge = seg(t, 0.55, 0.65);
  return Stack(
    children: [
      at(
        0,
        6,
        SizedBox(
          width: 280,
          child: Center(child: DemoBubble('NAME A FRUIT', color: pal.accent)),
        ),
      ),
      for (var i = 0; i < 3; i++) ...[
        at(xs[i], 96, DemoPerson(color: c[i])),
        at(xs[i] - 10, 62, popScale(show, DemoBubble(answers[i]))),
        at(xs[i] + 6, 100, popScale(judge, PixelSprite(i < 2 ? Sprites.cross : Sprites.check, pixel: 3))),
      ],
      at(0, 146, SizedBox(width: 280, child: fade(judge, DemoCaption('MATCH = OUT', color: pal.primary)))),
    ],
  );
}

Widget charadesDemo(BuildContext context, double t) {
  final pal = context.pal;
  // Tilt forward (got it), back to level, tilt back (pass), level.
  final fwd = seg(t, 0.12, 0.24) - seg(t, 0.36, 0.46);
  final back = seg(t, 0.58, 0.7) - seg(t, 0.82, 0.92);
  final angle = 0.75 * fwd - 0.75 * back;
  final got = between(t, 0.22, 0.46);
  final passed = between(t, 0.68, 0.92);
  final word = t < 0.4 ? 'PENGUIN' : 'PILOT';
  final left = (30 - t * 6).ceil();
  final screen = got ? pal.secondary : (passed ? pal.accent : pal.panel);
  return Stack(
    children: [
      at(120, 92, DemoPerson(color: pal.primary)),
      at(
        90,
        26,
        Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.006)
            ..rotateX(angle),
          child: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: screen,
              border: Border.all(color: pal.cardBlack, width: 4),
            ),
            child: Stack(
              children: [
                Positioned(left: 4, top: 2, child: Text('${left}s', style: PixelFonts.title(pal.text, size: 7))),
                Center(
                  child: Text(
                    got ? 'GOT IT!' : (passed ? 'PASS' : word),
                    style: PixelFonts.title(got || passed ? pal.bg : pal.text, size: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      at(10, 40, fade(got ? 1 : 0.25, DemoCaption('TILT\nDOWN\nGOT IT', color: pal.secondary))),
      at(214, 40, fade(passed ? 1 : 0.25, DemoCaption('TILT\nUP\nPASS', color: pal.accent))),
      at(0, 146, SizedBox(width: 280, child: DemoCaption('FRIENDS GIVE CLUES', color: pal.textDim))),
    ],
  );
}

Widget imposterDemo(BuildContext context, double t) {
  final pal = context.pal;
  final c = _crowd(pal);
  const xs = [30.0, 124.0, 218.0];
  const words = ['PIZZA', '???', 'PIZZA'];
  final caught = t > 0.7;
  return Stack(
    children: [
      for (var i = 0; i < 3; i++) at(xs[i], 100, DemoPerson(color: c[i])),
      for (var i = 0; i < 3; i++)
        at(xs[i] - 6, 56, popScale(seg(t, 0.1 + i * 0.15, 0.18 + i * 0.15) - seg(t, 0.62, 0.68), DemoBubble(words[i]))),
      if (caught) ...[
        at(xs[0] + 40, 66, fade(seg(t, 0.7, 0.76), Text('->', style: PixelFonts.title(pal.primary, size: 12)))),
        at(xs[2] - 26, 66, fade(seg(t, 0.7, 0.76), Text('<-', style: PixelFonts.title(pal.primary, size: 12)))),
        at(xs[1] + 2, 56, popScale(seg(t, 0.76, 0.84), DemoBubble('FAKER!', color: pal.primary))),
      ],
    ],
  );
}

Widget dialDemo(BuildContext context, double t) {
  final pal = context.pal;
  const left = 30.0, width = 220.0;
  final needle = 0.2 + 0.45 * seg(t, 0.25, 0.6);
  return Stack(
    children: [
      at(left, 8, Text('COLD', style: PixelFonts.title(pal.text, size: 8))),
      at(left + width - 26, 8, Text('HOT', style: PixelFonts.title(pal.text, size: 8))),
      at(left, 26, Container(width: width, height: 50, color: pal.cardBlack)),
      at(left + width * 0.55, 26, fade(seg(t, 0.68, 0.74), Container(width: width * 0.2, height: 50, color: pal.secondary))),
      at(left + width * 0.6, 26, fade(seg(t, 0.68, 0.74), Container(width: width * 0.1, height: 50, color: pal.primary))),
      at(left + width * needle - 3, 22, Container(width: 6, height: 58, color: pal.text)),
      at(left + 60, 96, fade(seg(t, 0.05, 0.15), DemoBubble('"SOUP"'))),
      at(left + 150, 96, popScale(seg(t, 0.76, 0.84), DemoBubble('+3', color: pal.secondary))),
    ],
  );
}

Widget mafiaDemo(BuildContext context, double t) {
  final pal = context.pal;
  final c = _crowd(pal);
  const xs = [30.0, 124.0, 218.0];
  final night = t < 0.5;
  return Stack(
    children: [
      for (var i = 0; i < 3; i++)
        if (night || i != 2) at(xs[i], 100, Opacity(opacity: night ? 0.45 : 1, child: DemoPerson(color: c[i]))),
      if (night) at(124, 18, popScale(seg(t, 0.0, 0.1), PixelSprite(Sprites.moon, pixel: 4))),
      at(0, 8, SizedBox(width: 280, child: DemoCaption(night ? 'NIGHT: SECRET TAPS' : 'DAY: VOTE!', color: night ? pal.text : pal.accent))),
      if (!night) at(xs[2] - 4, 112, popScale(seg(t, 0.5, 0.58), DemoBubble('OUT', color: pal.primary))),
      if (!night) at(xs[0] + 40, 70, fade(seg(t, 0.6, 0.66), Text('->', style: PixelFonts.title(pal.primary, size: 12)))),
      if (!night) at(xs[1] - 2, 56, popScale(seg(t, 0.66, 0.74), DemoBubble('YOU?', color: pal.primary))),
    ],
  );
}

Widget fishbowlDemo(BuildContext context, double t) {
  final pal = context.pal;
  // Three slips drop into the bowl, then the three rounds flash by.
  const labels = ['1: DESCRIBE IT', '2: ONE WORD', '3: ACT IT OUT'];
  final round = t < 0.4 ? -1 : ((t - 0.4) / 0.2).floor().clamp(0, 2);
  return Stack(
    children: [
      at(104, 54, PixelSprite(Sprites.fishbowl, pixel: 6)),
      for (var i = 0; i < 3; i++)
        if (t < 0.12 * i + 0.3)
          at(
            112.0 + i * 18,
            -10 + 70 * seg(t, 0.12 * i, 0.12 * i + 0.25, Curves.easeIn),
            Container(width: 14, height: 10, color: pal.cardFace),
          ),
      at(
        0,
        8,
        SizedBox(
          width: 280,
          child: round < 0
              ? DemoCaption('EVERYONE ADDS SLIPS', color: pal.text)
              : popScale(seg(t, 0.4 + round * 0.2, 0.46 + round * 0.2), DemoCaption(labels[round], color: pal.accent)),
        ),
      ),
    ],
  );
}

Widget paranoiaDemo(BuildContext context, double t) {
  final pal = context.pal;
  final c = _crowd(pal);
  const xs = [30.0, 124.0, 218.0];
  final move = seg(t, 0.05, 0.25);
  final coin = seg(t, 0.72, 0.95, Curves.easeOut);
  return Stack(
    children: [
      for (var i = 0; i < 3; i++) at(xs[i], 100, DemoPerson(color: c[i])),
      at(
        xs[0] + 36 + (xs[1] - xs[0]) * move,
        104 - 18 * sin(move * pi),
        Container(
          width: 20,
          height: 30,
          decoration: BoxDecoration(
            color: pal.panel,
            border: Border.all(color: pal.cardBlack, width: 3),
          ),
        ),
      ),
      at(xs[1] - 6, 52, popScale(seg(t, 0.28, 0.36) - seg(t, 0.46, 0.5), const DemoBubble('psst...'))),
      at(xs[1] + 30, 56, popScale(seg(t, 0.5, 0.58), DemoBubble('YOU!', color: pal.primary))),
      at(xs[2] - 26, 56, fade(seg(t, 0.5, 0.58), Text('->', style: PixelFonts.title(pal.primary, size: 12)))),
      at(
        126,
        14 - 26 * sin(coin * pi),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scaleByDouble(1, cos(coin * pi * 6).abs().clamp(0.1, 1), 1, 1),
          child: fade(seg(t, 0.7, 0.74), PixelSprite(Sprites.coinHeads, pixel: 3)),
        ),
      ),
    ],
  );
}

Widget horseRacingDemo(BuildContext context, double t) {
  final pal = context.pal;
  const sprites = [Sprites.heart, Sprites.spade, Sprites.diamond, Sprites.club];
  const speed = [0.82, 1.0, 0.7, 0.9];
  final p = seg(t, 0.05, 0.8, Curves.linear);
  return Stack(
    children: [
      for (var i = 0; i < 4; i++) ...[
        at(10, 14 + i * 34.0, Container(width: 240, height: 2, color: pal.bgAlt)),
        at(
          12 + 214 * min(1.0, p * speed[i] * 1.12),
          0 + i * 34.0 + (sin(t * 40 + i) > 0 ? 2 : 0),
          Container(padding: const EdgeInsets.all(2), color: pal.cardFace, child: PixelSprite(sprites[i], pixel: 3)),
        ),
      ],
      at(254, 0, PixelSprite(Sprites.flag, pixel: 4)),
      at(220, 140, fade(seg(t, 0.82, 0.88), DemoCaption('SPADES WIN', color: pal.accent))),
      at(8, 140, DemoCaption('BET ON A SUIT', color: pal.textDim)),
    ],
  );
}

Widget rideTheBusDemo(BuildContext context, double t) {
  final pal = context.pal;
  const cards = [
    PlayingCard(5, Suit.hearts),
    PlayingCard(9, Suit.clubs),
    PlayingCard(7, Suit.diamonds),
    PlayingCard(12, Suit.spades),
  ];
  const asks = ['RED?', 'HIGHER?', 'INSIDE?', 'SUIT?'];
  return Stack(
    children: [
      for (var i = 0; i < 4; i++) ...[
        at(18 + i * 66.0, 4, fade(seg(t, 0.05 + i * 0.18, 0.1 + i * 0.18), DemoCaption(asks[i], color: pal.text))),
        at(20 + i * 66.0, 24, flipCard(seg(t, 0.12 + i * 0.18, 0.22 + i * 0.18), cards[i], 50)),
        at(
          38 + i * 66.0,
          102,
          popScale(seg(t, 0.22 + i * 0.18, 0.26 + i * 0.18), PixelSprite(Sprites.check, pixel: 3)),
        ),
      ],
      at(
        0,
        136,
        SizedBox(width: 280, child: fade(seg(t, 0.85, 0.9), DemoCaption('4 RIGHT = OFF THE BUS', color: pal.accent))),
      ),
    ],
  );
}

Widget hotPotatoDemo(BuildContext context, double t) {
  final pal = context.pal;
  final c = _crowd(pal);
  const xs = [30.0, 124.0, 218.0];
  final hop = (t / 0.25).floor().clamp(0, 3);
  final h = (t % 0.25) / 0.25;
  final from = [0, 1, 2, 1][hop];
  final to = [1, 2, 1, 1][hop];
  final exploded = t > 0.78;
  final bx = xs[from] + (xs[to] - xs[from]) * Curves.easeInOut.transform(h);
  final shake = exploded ? sin(t * 200) * 3 : 0.0;
  return Stack(
    children: [
      for (var i = 0; i < 3; i++) at(xs[i] + (i == 1 ? shake : 0), 104, DemoPerson(color: c[i])),
      if (!exploded) at(bx, 60 - 30 * sin(h * pi), PixelSprite(Sprites.bomb, pixel: 3)),
      if (exploded) at(xs[1] - 14, 46, popScale(seg(t, 0.78, 0.84), PixelSprite(Sprites.boom, pixel: 6))),
      at(
        0,
        8,
        SizedBox(
          width: 280,
          child: DemoCaption(
            exploded ? 'BOOM! PENALTY' : 'SAY ONE, PASS IT',
            color: exploded ? pal.primary : pal.text,
          ),
        ),
      ),
    ],
  );
}

typedef DemoBuilder = Widget Function(BuildContext context, double t);
