import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/sprites.dart';
import '../common.dart';
import 'hot_potato.dart';

enum _Phase { idle, lit, boom }

class HotPotatoScreen extends StatefulWidget {
  const HotPotatoScreen({super.key});

  @override
  State<HotPotatoScreen> createState() => _HotPotatoScreenState();
}

class _HotPotatoScreenState extends State<HotPotatoScreen> {
  final _cats = ShuffledQueue(hotPotatoCategories);
  late String _category = _cats.next();
  _Phase _phase = _Phase.idle;
  BombRound? _round;
  // Advanced by the ticker itself (not a Stopwatch) so the fuse pauses with
  // the app and stays testable with fake time.
  Duration _elapsed = Duration.zero;
  static const _step = Duration(milliseconds: 40);
  Timer? _timer;
  Duration _lastTick = Duration.zero;
  bool _flash = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _light() {
    _round = BombRound();
    _elapsed = Duration.zero;
    _lastTick = Duration.zero;
    setState(() => _phase = _Phase.lit);
    _timer?.cancel();
    _timer = Timer.periodic(_step, (_) {
      final e = _elapsed += _step;
      if (_round!.exploded(e)) {
        _timer?.cancel();
        Fx.boom();
        setState(() => _phase = _Phase.boom);
        return;
      }
      if (e - _lastTick >= _round!.tickInterval(e)) {
        _lastTick = e;
        Fx.tick();
        setState(() => _flash = !_flash);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PixelScaffold(
      title: 'Hot Potato Bomb',
      onHelp: () => showHowToPlay(context, 'hot_potato'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PixelBox(
            child: Column(children: [
              Text('CATEGORY', style: PixelFonts.title(pal.textDim, size: 10)),
              const SizedBox(height: 8),
              Text(_category, textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 16)),
            ]),
          ),
          Expanded(child: Center(child: _bomb(context))),
          ...switch (_phase) {
            _Phase.idle => [
                Text('Name something in the category, then pass the phone. '
                    'Nobody knows when it blows.',
                    textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: PixelButton(
                      label: 'New topic',
                      color: pal.panel,
                      textColor: pal.text,
                      expand: true,
                      size: 11,
                      onTap: () => setState(() => _category = _cats.next()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: PixelButton(label: 'Light it', expand: true, onTap: _light)),
                ]),
              ],
            _Phase.lit => [
                Text('Say one, pass it on!', textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 13)),
                const SizedBox(height: 14),
                PixelButton(
                  label: 'Passed (${_round!.passes})',
                  expand: true,
                  color: pal.secondary,
                  onTap: () => setState(() => _round!.passes++),
                ),
              ],
            _Phase.boom => [
                Text('Whoever is holding the phone drinks!',
                    textAlign: TextAlign.center, style: PixelFonts.body(pal.text, size: 28)),
                const SizedBox(height: 14),
                PixelButton(
                  label: 'Next round',
                  expand: true,
                  onTap: () => setState(() {
                    _category = _cats.next();
                    _phase = _Phase.idle;
                  }),
                ),
              ],
          },
        ]),
      ),
    );
  }

  Widget _bomb(BuildContext context) {
    final pal = context.pal;
    if (_phase == _Phase.boom) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        PixelSprite(Sprites.boom, pixel: 22),
        const SizedBox(height: 12),
        Text('BOOM!', style: PixelFonts.title(pal.primary, size: 36)),
      ]);
    }
    final heat = _phase == _Phase.lit ? _round!.heat(_elapsed) : 0.0;
    final shake = _phase == _Phase.lit ? (_flash ? 1 : -1) * (2 + heat * 8) : 0.0;
    return Transform.translate(
      offset: Offset(shake, 0),
      child: Transform.rotate(
        angle: shake * pi / 180,
        child: PixelSprite(
          Sprites.bomb,
          pixel: 16,
          tint: _phase == _Phase.lit && _flash ? {'K': pal.primary} : null,
        ),
      ),
    );
  }
}
