import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/secret_pass.dart';
import '../../widgets/sprites.dart';
import '../common.dart';
import '../how_to_play.dart';
import 'dial.dart';

enum _Phase { clue, guess, reveal }

class DialScreen extends StatefulWidget {
  const DialScreen({super.key});

  @override
  State<DialScreen> createState() => _DialScreenState();
}

class _DialScreenState extends State<DialScreen> {
  final _spectrums = ShuffledQueue(spectrums);
  late DialRound _round = DialRound(spectrum: _spectrums.next());
  _Phase _phase = _Phase.clue;
  double _guess = 50;
  int _turn = 0;
  int _total = 0;
  int _rounds = 0;

  List<String> get _players => context.app.players;
  String? get _giver => _players.isEmpty ? null : _players[_turn % _players.length];

  void _next() {
    setState(() {
      _turn++;
      _round = DialRound(spectrum: _spectrums.next());
      _guess = 50;
      _phase = _Phase.clue;
    });
  }

  void _lockIn() {
    final pts = _round.score(_guess);
    pts == 0 ? Fx.lose() : (pts == 4 ? Fx.win() : Fx.correct());
    setState(() {
      _total += pts;
      _rounds++;
      _phase = _Phase.reveal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Dial It In',
      onHelp: () => showHowToPlay(context, 'dial'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: switch (_phase) {
          _Phase.clue => SecretPass(
              key: ValueKey('dial-$_turn'),
              to: _giver ?? 'the clue giver',
              icon: Sprites.dial,
              hint: 'Only the clue giver looks. Everyone else, eyes off!',
              secret: _clue,
            ),
          _Phase.guess => _guessView(context),
          _Phase.reveal => _reveal(context),
        },
      ),
    );
  }

  Widget _clue(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('THE TARGET IS HERE', style: PixelFonts.title(pal.primary, size: 11)),
      const SizedBox(height: 16),
      PixelDial(spectrum: _round.spectrum, target: _round.target),
      const SizedBox(height: 20),
      Text('Think of one thing that sits at the target between '
          '"${_round.spectrum.left}" and "${_round.spectrum.right}". Say it out loud.',
          style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: 'New scale',
        expand: true,
        size: 11,
        color: pal.panel,
        textColor: pal.text,
        onTap: () => setState(() => _round = DialRound(spectrum: _spectrums.next())),
      ),
      const SizedBox(height: 10),
      PixelButton(
        label: 'Hide it, team guesses',
        expand: true,
        onTap: () {
          Fx.close();
          setState(() => _phase = _Phase.guess);
        },
      ),
    ]);
  }

  Widget _guessView(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${(_giver ?? 'the clue giver').toUpperCase()} GAVE A CLUE',
          style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 16),
      PixelDial(
        spectrum: _round.spectrum,
        guess: _guess,
        onChanged: (v) => setState(() => _guess = v),
      ),
      const SizedBox(height: 20),
      Text('Talk it over, then drag the needle to where the clue belongs.',
          style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(label: 'Lock it in', expand: true, onTap: _lockIn),
    ]);
  }

  Widget _reveal(BuildContext context) {
    final pal = context.pal;
    final pts = _round.score(_guess);
    final giver = _giver ?? 'The clue giver';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PixelDial(spectrum: _round.spectrum, target: _round.target, guess: _guess),
      const Spacer(),
      Text(
        switch (pts) { 4 => 'BULLSEYE!', 0 => 'MISSED!', _ => 'CLOSE!' },
        textAlign: TextAlign.center,
        style: PixelFonts.title(pts == 0 ? pal.primary : pal.secondary, size: 22),
      ),
      const SizedBox(height: 8),
      Text('+$pts', textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 18)),
      const SizedBox(height: 10),
      Text(
        switch (pts) {
          4 => '$giver hands out a penalty.',
          0 => 'The guessers take a penalty.',
          _ => 'Nobody takes a penalty this time.',
        },
        textAlign: TextAlign.center,
        style: PixelFonts.body(pal.text),
      ),
      const SizedBox(height: 6),
      Text('Team score: $_total in $_rounds ${_rounds == 1 ? 'round' : 'rounds'}',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
      const Spacer(),
      PixelButton(label: 'Next clue giver', expand: true, onTap: _next),
    ]);
  }
}

/// A 0..100 scale with labelled ends. Shows the scoring bands around
/// [target] when given, and a needle at [guess]; drag to move it when
/// [onChanged] is set.
class PixelDial extends StatelessWidget {
  const PixelDial({super.key, required this.spectrum, this.target, this.guess, this.onChanged});

  final Spectrum spectrum;
  final int? target;
  final double? guess;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final bandColors = [pal.primary, pal.secondary, pal.accent];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('< ${spectrum.left}', style: PixelFonts.title(pal.text, size: 10))),
        Expanded(
          child: Text('${spectrum.right} >', textAlign: TextAlign.right, style: PixelFonts.title(pal.text, size: 10)),
        ),
      ]),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        double x(num v) => (v.clamp(0, 100) / 100) * w;
        void drag(Offset p) => onChanged?.call((p.dx / w * 100).clamp(0, 100).toDouble());
        return GestureDetector(
          key: const Key('dial-bar'),
          behavior: HitTestBehavior.opaque,
          onTapDown: onChanged == null ? null : (d) => drag(d.localPosition),
          onHorizontalDragUpdate: onChanged == null ? null : (d) => drag(d.localPosition),
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: pal.cardBlack,
              border: Border.all(color: pal.border, width: 3),
            ),
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              if (target != null)
                // Widest band first so the narrower ones paint on top.
                for (var i = DialRound.bands.length - 1; i >= 0; i--)
                  Positioned(
                    left: x(target! - DialRound.bands[i]),
                    width: x(target! + DialRound.bands[i]) - x(target! - DialRound.bands[i]),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: bandColors[i],
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 4),
                      child: i == 0 ? Text('4', style: PixelFonts.title(pal.bg, size: 9)) : null,
                    ),
                  ),
              if (guess != null)
                Positioned(
                  left: x(guess!) - 3,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 6, color: pal.text),
                ),
            ]),
          ),
        );
      }),
    ]);
  }
}
