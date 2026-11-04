import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/motion.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/sprites.dart';

const paranoiaPrompts = [
  'Who here is most likely to get arrested?',
  'Who would survive the longest in a zombie apocalypse?',
  'Who here has the worst taste in partners?',
  'Who would you call to help hide a body?',
  'Who is most likely to cry tonight?',
  'Who here is the biggest flirt?',
  'Who would be the worst roommate?',
  'Who is most likely to text their ex tonight?',
  'Who here gives the best advice?',
  'Who would win in a fist fight?',
  'Who is secretly the smartest person here?',
  'Who here is most likely to become famous?',
  'Who would you trust with your phone unlocked?',
  'Who has the most embarrassing search history?',
  'Who here would be the first to die in a horror movie?',
  'Who is the worst driver here?',
  'Who would you want as your lawyer?',
  'Who here is most likely to get married first?',
  'Who would last the shortest on a deserted island?',
  'Who here is the best kisser?',
  'Who is most likely to fall asleep at this party?',
  'Who here would make the best parent?',
  'Who is the most dramatic person here?',
  'Who here could you never keep a secret from?',
  'Who would you swap lives with for a week?',
  'Who is most likely to start a cult?',
  'Who here is hiding something right now?',
  'Who would be the worst person to be stuck in an elevator with?',
  'Who has the best laugh here?',
  'Who is most likely to throw up tonight?',
  'Who here would you want on your trivia team?',
  'Who is the most likely to lie about their age?',
  'Who would spend their last dollar on something dumb?',
  'Who here is the best dancer?',
  'Who is most likely to forget everyone\'s birthday?',
  'Who here would you least want to see angry?',
  'Who has the most chaotic dating life?',
  'Who would be the funniest drunk text?',
  'Who here would win a reality TV show?',
  'Who is most likely to adopt five cats?',
];

enum _Phase { pass, secret, decide, coin, result }

class ParanoiaScreen extends StatefulWidget {
  const ParanoiaScreen({super.key});

  @override
  State<ParanoiaScreen> createState() => _ParanoiaScreenState();
}

class _ParanoiaScreenState extends State<ParanoiaScreen> with SingleTickerProviderStateMixin {
  final _random = Random();
  late final List<String> _queue = List.of(paranoiaPrompts)..shuffle(_random);
  _Phase _phase = _Phase.pass;
  int _turn = 0;
  String _question = '';
  String? _named;
  bool _revealed = false;
  bool _heads = true;

  late final AnimationController _coin;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller would first be built inside dispose().
    _coin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _question = _queue.removeLast();
  }

  @override
  void dispose() {
    _coin.dispose();
    super.dispose();
  }

  List<String> get _players => context.app.players;

  /// Names are optional: with fewer than two, the phone just goes left.
  bool get _named2 => _players.length >= 2;
  String? get _answerer => _named2 ? _players[_turn % _players.length] : null;

  void _next() {
    if (_queue.isEmpty) _queue.addAll(List.of(paranoiaPrompts)..shuffle(_random));
    setState(() {
      _turn++;
      _question = _queue.removeLast();
      _named = null;
      _phase = _Phase.pass;
    });
  }

  void _flip() {
    _heads = _random.nextBool();
    Fx.flip();
    setState(() => _phase = _Phase.coin);
    _coin.forward(from: 0).then((_) {
      Fx.coin();
      if (mounted) {
        setState(() {
          _revealed = _heads;
          _phase = _Phase.result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Paranoia',
      onHelp: () => showHowToPlay(context, 'paranoia'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: PhaseSwitcher(
          child: KeyedSubtree(
            key: ValueKey('$_phase$_turn'),
            child: switch (_phase) {
              _Phase.pass => _pass(context),
              _Phase.secret => _secret(context),
              _Phase.decide => _decide(context),
              _Phase.coin => _coinView(context),
              _Phase.result => _result(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _pass(BuildContext context) {
    final pal = context.pal;
    return Column(children: [
      const Spacer(),
      PixelSprite(Sprites.eye, pixel: 10),
      const SizedBox(height: 24),
      Text('PASS THE PHONE TO', style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 10),
      Text(_answerer ?? 'THE PERSON\nON YOUR LEFT',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: _answerer == null ? 16 : 24)),
      const SizedBox(height: 10),
      Text('Read the question in secret.\nAnswer with a name, out loud.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(label: 'Show me', expand: true, onTap: () => setState(() => _phase = _Phase.secret)),
    ]);
  }

  Widget _secret(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_answerer == null ? 'SHH... EYES ON YOUR OWN SCREEN' : 'SHH... ONLY $_answerer',
          style: PixelFonts.title(pal.primary, size: 11)),
      const SizedBox(height: 18),
      PixelBox(
        child: Text(_question, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 16)),
      ),
      const SizedBox(height: 22),
      Text(_named2 ? 'Say your answer out loud, then tap them:' : 'Say a name out loud. Nobody else reads this!',
          style: PixelFonts.body(pal.textDim)),
      const SizedBox(height: 12),
      if (!_named2) ...[
        const Spacer(),
        PixelButton(
          label: 'I said a name',
          expand: true,
          onTap: () => setState(() {
            _named = null;
            _phase = _Phase.decide;
          }),
        ),
      ] else
      Expanded(
        child: SingleChildScrollView(
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in _players)
              if (p != _answerer)
                PixelChip(
                  label: p,
                  onTap: () => setState(() {
                    _named = p;
                    _phase = _Phase.decide;
                  }),
                ),
          ]),
        ),
      ),
    ]);
  }

  Widget _decide(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Text(_named == null ? 'WHOEVER WAS NAMED' : 'THE ANSWER WAS',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 10),
      if (_named != null) Text(_named!, textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 26)),
      const SizedBox(height: 18),
      Text(_named == null ? 'Want to know the question?' : '$_named, want to know the question?',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: 'Drink to find out',
        expand: true,
        onTap: () {
          Fx.pass();
          setState(() {
            _revealed = true;
            _phase = _Phase.result;
          });
        },
      ),
      const SizedBox(height: 10),
      PixelButton(label: 'Flip the coin', expand: true, color: pal.accent, onTap: _flip),
      const SizedBox(height: 10),
      PixelButton(
        label: 'Leave it a mystery',
        expand: true,
        color: pal.panel,
        textColor: pal.text,
        onTap: () => setState(() {
          _revealed = false;
          _phase = _Phase.result;
        }),
      ),
    ]);
  }

  Widget _coinView(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: AnimatedBuilder(
        animation: _coin,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_coin.value);
          final spins = 7;
          final angle = t * pi * spins;
          final faceUp = (angle / pi).floor().isEven;
          final showHeads = _coin.isCompleted ? _heads : (faceUp == _heads);
          final y = -sin(t * pi) * 160;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.translate(
              offset: Offset(0, y),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scaleByDouble(1, cos(angle).abs().clamp(0.08, 1), 1, 1),
                child: PixelSprite(showHeads ? Sprites.coinHeads : Sprites.coinTails, pixel: 14),
              ),
            ),
            const SizedBox(height: 30),
            Text('HEADS = REVEAL', style: PixelFonts.title(pal.textDim, size: 10)),
          ]);
        },
      ),
    );
  }

  Widget _result(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      if (_revealed) ...[
        Text('THE QUESTION WAS', textAlign: TextAlign.center, style: PixelFonts.title(pal.textDim, size: 11)),
        const SizedBox(height: 14),
        PixelBox(
          borderColor: pal.primary,
          child: Text(_question, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 16)),
        ),
      ] else ...[
        PixelSprite(Sprites.eye, pixel: 10),
        const SizedBox(height: 20),
        Text('IT STAYS A SECRET', textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 16)),
        const SizedBox(height: 10),
        Text('Paranoia intensifies.', textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
      ],
      const Spacer(),
      PixelButton(label: 'Next round', expand: true, onTap: _next),
    ]);
  }
}
