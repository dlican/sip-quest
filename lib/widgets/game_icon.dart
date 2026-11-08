import 'dart:math';

import 'package:flutter/material.dart';

import 'sprites.dart';

/// A game's pixel icon with a small idle animation of its own: the crown
/// hops, the eye blinks, the horse gallops, the wheel spins, and so on.
/// Motion snaps to half-pixel steps so it stays crisp and retro.
class AnimatedGameIcon extends StatefulWidget {
  const AnimatedGameIcon({
    super.key,
    required this.gameId,
    required this.sprite,
    this.pixel = 5,
  });

  final String gameId;
  final Sprite sprite;
  final double pixel;

  @override
  State<AnimatedGameIcon> createState() => _AnimatedGameIconState();
}

class _AnimatedGameIconState extends State<AnimatedGameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  // Offsets each tile's loop so the home list does not move in lockstep.
  late final double _phase = (widget.gameId.hashCode % 97) / 97;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _snap(double v) {
    final step = widget.pixel / 2;
    return (v / step).roundToDouble() * step;
  }

  /// Returns (dx, dy, angle, scaleX, scaleY) for loop position [t].
  (double, double, double, double, double) _pose(double t) {
    final px = widget.pixel;
    final wave = sin(t * 2 * pi);
    switch (widget.gameId) {
      case 'kings_cup': // Two quick hops, then a rest.
        final hop = t < 0.4 ? (sin(t / 0.4 * 2 * pi * 2).abs()) : 0.0;
        return (0, -hop * px * 1.5, 0, 1, 1);
      case 'one_of_a_kind': // Puzzled wobble.
        final w = t < 0.5 ? sin(t / 0.5 * 2 * pi * 2) * (1 - t / 0.5) : 0.0;
        return (0, 0, w * 0.35, 1, 1);
      case 'charades': // Tilts like a phone on a forehead.
        return (
          0,
          0,
          (t * 4).floor().isEven ? 0.18 * wave.sign : -0.12 * wave.sign,
          1,
          1,
        );
      case 'paranoia': // Looks around, then blinks.
        final look = t < 0.6 ? (t < 0.3 ? -1.0 : 1.0) : 0.0;
        final blink = (t > 0.78 && t < 0.84) ? 0.15 : 1.0;
        return (look * px, 0, 0, 1, blink);
      case 'horse_racing': // Gallops on the spot.
        final stride = (t * 8).floor() % 4;
        return (
          [0.0, px, 0.0, -px][stride],
          stride.isOdd ? -px : 0,
          stride.isOdd ? -0.08 : 0.04,
          1,
          1,
        );
      case 'ride_the_bus': // Drives back and forth on a bumpy road.
        return (
          wave * px * 2,
          (t * 12).floor().isEven ? 0 : -px * 0.5,
          0,
          1,
          1,
        );
      case 'hot_potato': // Shakes harder and harder, then puffs up.
        final shake = (t * 30).floor().isEven ? 1.0 : -1.0;
        final puff = t > 0.85 ? 1.12 : 1.0;
        return (shake * px * 0.6 * t, 0, shake * 0.06 * t, puff, puff);
      case 'roulette': // Spins in eighth-turn clicks.
        return (0, 0, (t * 16).floor() * pi / 4, 1, 1);
      default:
        return (0, wave * px, 0, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final (dx, dy, angle, sx, sy) = _pose((_c.value + _phase) % 1.0);
        return Transform.translate(
          offset: Offset(_snap(dx), _snap(dy)),
          child: Transform.rotate(
            angle: angle,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: child,
            ),
          ),
        );
      },
      child: PixelSprite(widget.sprite, pixel: widget.pixel),
    );
  }
}
