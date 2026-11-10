import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/motion.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import '../common.dart';
import '../how_to_play.dart';
import 'most_likely.dart';

enum _Phase { ask, countdown, pointed, handoff, voting, results }

/// Two ways to play on one phone: everyone points on 3 (no names needed), or
/// a secret ballot passed around when names are added.
class MostLikelyScreen extends StatefulWidget {
  const MostLikelyScreen({super.key});

  @override
  State<MostLikelyScreen> createState() => _MostLikelyScreenState();
}

class _MostLikelyScreenState extends State<MostLikelyScreen> {
  final _prompts = ShuffledQueue(mostLikelyPrompts);
  late String _prompt = _prompts.next();
  late VoteRound _round = VoteRound(context.app.players);
  _Phase _phase = _Phase.ask;
  int _count = 3;
  Timer? _timer;

  bool get _canVote => context.app.players.length >= 3;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _vote(String target) {
    Fx.select();
    setState(() {
      _round.cast(_round.nextVoter!, target);
      _phase = _round.complete ? _Phase.results : _Phase.handoff;
    });
    if (_round.complete) Fx.win();
  }

  void _countdown() {
    _timer?.cancel();
    setState(() {
      _count = 3;
      _phase = _Phase.countdown;
    });
    Fx.tick();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (_count > 1) {
        setState(() => _count--);
        Fx.tick();
      } else {
        t.cancel();
        Fx.start();
        setState(() => _phase = _Phase.pointed);
      }
    });
  }

  void _next() {
    _timer?.cancel();
    setState(() {
      _prompt = _prompts.next();
      _round = VoteRound(context.app.players);
      _phase = _Phase.ask;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final players = context.app.players;
    final voting = _phase == _Phase.handoff || _phase == _Phase.voting || _phase == _Phase.results;
    return PixelScaffold(
      title: 'Most Likely To',
      onHelp: () => showHowToPlay(context, 'most_likely'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PixelBox(
              child: PopIn(
                value: _prompt,
                child: Text(_prompt, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 15)),
              ),
            ),
            const SizedBox(height: 8),
            if (voting)
              Text(
                '${_round.votesCast}/${players.length} votes in',
                textAlign: TextAlign.right,
                style: PixelFonts.body(pal.textDim, size: 22),
              ),
            Expanded(
              child: PhaseSwitcher(
                child: KeyedSubtree(
                  key: ValueKey('$_phase${_round.votesCast}'),
                  child: switch (_phase) {
                    _Phase.ask => _ask(context),
                    _Phase.countdown => _countdownView(context),
                    _Phase.pointed => _pointed(context),
                    _Phase.handoff => _handoff(context),
                    _Phase.voting => _voting(context),
                    _Phase.results => _results(context),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ask(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(child: PixelSprite(Sprites.ballot, pixel: 9)),
        const SizedBox(height: 20),
        Text(
          'Read it out. On 3, everyone points at who fits best.',
          textAlign: TextAlign.center,
          style: PixelFonts.body(pal.text),
        ),
        const Spacer(),
        PixelButton(label: 'Count down', expand: true, onTap: _countdown),
        if (_canVote) ...[
          const SizedBox(height: 10),
          PixelButton(
            label: 'Secret vote instead',
            expand: true,
            color: pal.secondary,
            onTap: () => setState(() => _phase = _Phase.handoff),
          ),
        ],
        const SizedBox(height: 10),
        PixelButton(label: 'Skip', expand: true, color: pal.panel, textColor: pal.text, onTap: _next),
      ],
    );
  }

  Widget _countdownView(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: PopIn(
        value: _count,
        child: Text('$_count', style: PixelFonts.title(pal.accent, size: 80)),
      ),
    );
  }

  Widget _pointed(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        PopIn(
          value: 'point',
          child: Text('POINT!', textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 40)),
        ),
        const SizedBox(height: 20),
        Text(
          'One penalty for every finger pointing at you.',
          textAlign: TextAlign.center,
          style: PixelFonts.body(pal.text),
        ),
        const Spacer(),
        PixelButton(label: 'Next question', expand: true, onTap: _next),
      ],
    );
  }

  Widget _handoff(BuildContext context) {
    final pal = context.pal;
    return Column(
      children: [
        const Spacer(),
        PixelSprite(Sprites.ballot, pixel: 9),
        const SizedBox(height: 20),
        Text('PASS THE PHONE TO', style: PixelFonts.title(pal.textDim, size: 11)),
        const SizedBox(height: 10),
        Text(_round.nextVoter!, style: PixelFonts.title(pal.accent, size: 22)),
        const Spacer(),
        PixelButton(label: 'Vote in secret', expand: true, onTap: () => setState(() => _phase = _Phase.voting)),
      ],
    );
  }

  Widget _voting(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text('${_round.nextVoter}, tap your pick:', style: PixelFonts.body(pal.text)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final p in context.app.players) PixelChip(label: p, onTap: () => _vote(p))],
        ),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final pal = context.pal;
    final tally = _round.tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = tally.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          '${_round.winners.join(' & ')} take${_round.winners.length == 1 ? 's' : ''} $top!',
          textAlign: TextAlign.center,
          style: PixelFonts.title(pal.primary, size: 15),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            children: [
              for (final e in tally)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(e.key, style: PixelFonts.body(pal.text), overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: top == 0 ? 0 : e.value / top),
                            duration: Motion.slow,
                            curve: Motion.enter,
                            builder: (context, w, _) => FractionallySizedBox(
                              widthFactor: w,
                              child: Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: e.value == top ? pal.primary : pal.secondary,
                                  border: Border.all(color: pal.cardBlack, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: PixelFonts.title(pal.accent, size: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        PixelButton(label: 'Next question', expand: true, onTap: _next),
      ],
    );
  }
}
