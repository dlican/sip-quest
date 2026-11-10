import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/secret_pass.dart';
import '../../widgets/sprites.dart';
import '../how_to_play.dart';
import 'imposter.dart';

enum _Phase { setup, reveal, discuss, result }

class ImposterScreen extends StatefulWidget {
  const ImposterScreen({super.key});

  @override
  State<ImposterScreen> createState() => _ImposterScreenState();
}

class _ImposterScreenState extends State<ImposterScreen> {
  _Phase _phase = _Phase.setup;
  int _count = 5;
  int _imposters = 1;
  bool _hint = true;
  String? _category;
  ImposterRound? _round;
  int _seat = 0;
  int _games = 0;

  /// Names are optional: under three, seats are just numbered.
  List<String> get _named => context.app.players.length >= 3 ? context.app.players : const [];
  int get _players => _named.isEmpty ? _count : _named.length;
  String _name(int seat) => _named.isEmpty ? 'Player ${seat + 1}' : _named[seat];
  int get _maxImposters => _players >= 7 ? 2 : 1;

  void _start() {
    Fx.start();
    setState(() {
      _round = ImposterRound(
        playerCount: _players,
        imposterCount: _imposters.clamp(1, _maxImposters),
        category: _category,
      );
      _seat = 0;
      _games++;
      _phase = _Phase.reveal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Imposter',
      onHelp: () => showHowToPlay(context, 'imposter'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: switch (_phase) {
          _Phase.setup => _setup(context),
          _Phase.reveal => SecretPass(
              key: ValueKey('imposter-$_games-$_seat'),
              to: _name(_seat),
              icon: Sprites.spy,
              hint: 'Look at your card in secret.',
              secret: _card,
            ),
          _Phase.discuss => _discuss(context),
          _Phase.result => _result(context),
        },
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    return ListView(children: [
      Center(child: PixelSprite(Sprites.spy, pixel: 9)),
      const SizedBox(height: 14),
      Text('Everyone gets the same secret word, except the imposter. '
          'Give one-word clues, then vote out who is faking it.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 18),
      if (_named.isEmpty) ...[
        Text('PLAYERS', style: PixelFonts.title(pal.textDim, size: 10)),
        const SizedBox(height: 8),
        Row(children: [
          PixelButton(label: '-', size: 16, onTap: _count > 3 ? () => setState(() => _count--) : null),
          Expanded(
            child: Text('$_count', textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 18)),
          ),
          PixelButton(label: '+', size: 16, onTap: _count < 12 ? () => setState(() => _count++) : null),
        ]),
        const SizedBox(height: 16),
      ],
      Text('IMPOSTERS', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final n in const [1, 2])
          PixelChip(
            label: '$n',
            selected: _imposters.clamp(1, _maxImposters) == n,
            onTap: n <= _maxImposters ? () => setState(() => _imposters = n) : null,
          ),
      ]),
      if (_maxImposters == 1)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Two imposters needs 7+ players.', style: PixelFonts.body(pal.textDim)),
        ),
      const SizedBox(height: 16),
      Text('CATEGORY', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        PixelChip(label: 'Any', selected: _category == null, onTap: () => setState(() => _category = null)),
        for (final c in imposterWords.keys)
          PixelChip(label: c, selected: _category == c, onTap: () => setState(() => _category = c)),
      ]),
      const SizedBox(height: 16),
      Text('IMPOSTER HINT', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        PixelChip(label: 'Show category', selected: _hint, onTap: () => setState(() => _hint = true)),
        PixelChip(label: 'No hint', selected: !_hint, onTap: () => setState(() => _hint = false)),
      ]),
      const SizedBox(height: 20),
      PixelButton(label: 'Deal the cards', expand: true, onTap: _start),
    ]);
  }

  Widget _card(BuildContext context) {
    final pal = context.pal;
    final r = _round!;
    final imp = r.isImposter(_seat);
    final last = _seat == r.playerCount - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      PixelBox(
        borderColor: imp ? pal.primary : pal.secondary,
        child: Column(children: [
          if (imp) ...[
            Text("YOU'RE THE", style: PixelFonts.title(pal.textDim, size: 11)),
            const SizedBox(height: 8),
            Text('IMPOSTER', key: const Key('imposter-you'), style: PixelFonts.title(pal.primary, size: 24)),
            const SizedBox(height: 12),
            Text(
              _hint ? 'Category: ${r.category}. Blend in and work out the word.' : 'Blend in and work out the word.',
              textAlign: TextAlign.center,
              style: PixelFonts.body(pal.text),
            ),
          ] else ...[
            Text('THE WORD IS', style: PixelFonts.title(pal.textDim, size: 11)),
            const SizedBox(height: 8),
            Text(r.word.toUpperCase(),
                key: const Key('imposter-word'),
                textAlign: TextAlign.center,
                style: PixelFonts.title(pal.secondary, size: 22)),
            const SizedBox(height: 12),
            Text('Category: ${r.category}', style: PixelFonts.body(pal.text)),
          ],
        ]),
      ),
      const Spacer(),
      PixelButton(
        label: last ? 'Hide, start clues' : 'Hide and pass',
        expand: true,
        onTap: () => setState(() {
          Fx.close();
          if (last) {
            _phase = _Phase.discuss;
          } else {
            _seat++;
          }
        }),
      ),
    ]);
  }

  Widget _discuss(BuildContext context) {
    final pal = context.pal;
    final r = _round!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Center(child: PixelSprite(Sprites.spy, pixel: 10)),
      const SizedBox(height: 20),
      Text('${_name(r.starter).toUpperCase()} STARTS',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 18)),
      const SizedBox(height: 12),
      Text('Go around the table. Each person says ONE word linked to the secret. '
          'Too obvious helps the imposter; too vague looks suspicious.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 10),
      Text('Two laps, then point at who you think it is on 3.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
      const Spacer(),
      PixelButton(
        label: 'Reveal the imposter',
        expand: true,
        onTap: () {
          Fx.boom();
          setState(() => _phase = _Phase.result);
        },
      ),
    ]);
  }

  Widget _result(BuildContext context) {
    final pal = context.pal;
    final r = _round!;
    final names = [for (final s in r.imposters.toList()..sort()) _name(s)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Text(names.length == 1 ? 'THE IMPOSTER WAS' : 'THE IMPOSTERS WERE',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 10),
      Text(names.join(' & '), textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 22)),
      const SizedBox(height: 16),
      Text('The word was ${r.word}.', textAlign: TextAlign.center, style: PixelFonts.title(pal.secondary, size: 13)),
      const SizedBox(height: 16),
      Text('Caught? The imposter gets one guess at the word. Right, and they still win.\n'
          'Imposter wins: everyone else takes a penalty. Town wins: the imposter does.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(label: 'Next round', expand: true, onTap: _start),
      const SizedBox(height: 10),
      PixelButton(
        label: 'Change settings',
        expand: true,
        size: 11,
        color: pal.panel,
        textColor: pal.text,
        onTap: () => setState(() => _phase = _Phase.setup),
      ),
    ]);
  }
}
