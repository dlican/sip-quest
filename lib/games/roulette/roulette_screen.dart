import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../common.dart';
import 'roulette.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  final _wheel = Roulette();
  late final TurnOrder _turns = TurnOrder(context.app.players);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  double _from = 0, _to = 0;
  RouletteSpin? _spin;
  bool _spinning = false;
  int _lastSlice = -1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _turnsNow => _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value);

  void _go() {
    if (_spinning) return;
    _from = _wheel.rest;
    final s = _wheel.spin();
    _to = s.turns;
    setState(() {
      _spin = s;
      _spinning = true;
    });
    _c.forward(from: 0).then((_) {
      Fx.win();
      if (mounted) setState(() => _spinning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final result = !_spinning && _spin != null ? _wheel.slices[_spin!.index] : null;
    return PixelScaffold(
      title: 'Pixel Roulette',
      onHelp: () => showHowToPlay(context, 'roulette'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_turns.current != null)
              Text(
                '${_turns.current} spins',
                textAlign: TextAlign.center,
                style: PixelFonts.body(pal.secondary, size: 26),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = min(box.maxWidth, box.maxHeight) * 0.95;
                  return Center(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _turnsNow;
                        final slice = _wheel.sliceAt(t);
                        if (_spinning && slice != _lastSlice) {
                          _lastSlice = slice;
                          Fx.spinTick();
                        }
                        // Snap rotation to 2-degree steps for a choppy pixel feel.
                        final angle = ((t * 360) / 2).round() * 2 * pi / 180;
                        return SizedBox(
                          width: size,
                          height: size,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Transform.rotate(
                                angle: angle,
                                child: CustomPaint(
                                  size: Size(size, size),
                                  painter: _WheelPainter(_wheel.slices, pal),
                                ),
                              ),
                              CustomPaint(size: const Size(28, 30), painter: _PointerPainter(pal)),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 110),
              child: PixelBox(
                borderColor: result == null ? pal.border : pal.accent,
                child: result == null
                    ? Center(
                        child: Text(
                          _spinning ? 'Round and round...' : 'Spin to find your fate.',
                          style: PixelFonts.body(pal.text),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.title.toUpperCase(), style: PixelFonts.title(pal.accent, size: 15)),
                          const SizedBox(height: 6),
                          Text(result.description, style: PixelFonts.body(pal.text, size: 22)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: _spinning ? 'Spinning...' : 'Spin',
              expand: true,
              onTap: _spinning
                  ? null
                  : () {
                      if (_spin != null) _turns.advance();
                      _go();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices, this.pal);
  final List<RouletteSlice> slices;
  final SipPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = 2 * pi / slices.length;
    final colors = [pal.primary, pal.secondary, pal.accent, pal.panel];
    final fill = Paint()..isAntiAlias = false;
    final line = Paint()
      ..color = pal.cardBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..isAntiAlias = false;

    for (var i = 0; i < slices.length; i++) {
      // Slice 0 starts at 12 o'clock and slices go clockwise.
      final start = -pi / 2 + i * sweep;
      fill.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, true, fill);
      canvas.drawArc(rect, start, sweep, true, line);
    }
    // Labels go on after every wedge so no wedge paints over a label.
    for (var i = 0; i < slices.length; i++) {
      final mid = -pi / 2 + (i + 0.5) * sweep;
      final tp = TextPainter(
        text: TextSpan(
          text: slices[i].title.toUpperCase(),
          style: PixelFonts.title(
            colors[i % colors.length] == pal.panel ? pal.text : pal.cardBlack,
            size: max(6, r / 26),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final scale = min(1.0, (r * 0.66) / tp.width);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(mid);
      canvas.scale(scale);
      // Labels read outward along the radius, ending clear of the pointer.
      tp.paint(canvas, Offset(r * 0.84 / scale - tp.width, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, r, line..strokeWidth = 6);
    canvas.drawCircle(c, r * 0.12, Paint()..color = pal.cardBlack);
    canvas.drawCircle(c, r * 0.07, Paint()..color = pal.accent);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.pal != pal || old.slices != slices;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.pal);
  final SipPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = pal.text);
    canvas.drawPath(
      path,
      Paint()
        ..color = pal.cardBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.pal != pal;
}
