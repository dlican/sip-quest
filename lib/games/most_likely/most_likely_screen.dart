import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import '../common.dart';
import 'most_likely.dart';

enum _Phase { handoff, voting, results }

class MostLikelyScreen extends StatefulWidget {
  const MostLikelyScreen({super.key});

  @override
  State<MostLikelyScreen> createState() => _MostLikelyScreenState();
}

class _MostLikelyScreenState extends State<MostLikelyScreen> {
  final _prompts = ShuffledQueue(mostLikelyPrompts);
  late String _prompt = _prompts.next();
  late VoteRound _round = VoteRound(context.app.players);
  _Phase _phase = _Phase.handoff;

  void _vote(String target) {
    HapticFeedback.mediumImpact();
    setState(() {
      _round.cast(_round.nextVoter!, target);
      _phase = _round.complete ? _Phase.results : _Phase.handoff;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final players = context.app.players;
    if (players.length < 3) {
      return PixelScaffold(title: 'Most Likely To', body: NeedPlayers(min: 3, onAdd: () => Navigator.pop(context)));
    }
    return PixelScaffold(
      title: 'Most Likely To',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PixelBox(
            child: Text(_prompt, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 15)),
          ),
          const SizedBox(height: 8),
          Text('${_round.votesCast}/${players.length} votes in',
              textAlign: TextAlign.right, style: PixelFonts.body(pal.textDim, size: 22)),
          Expanded(
            child: switch (_phase) {
              _Phase.handoff => Column(children: [
                  const Spacer(),
                  PixelSprite(Sprites.ballot, pixel: 9),
                  const SizedBox(height: 20),
                  Text('PASS THE PHONE TO', style: PixelFonts.title(pal.textDim, size: 11)),
                  const SizedBox(height: 10),
                  Text(_round.nextVoter!, style: PixelFonts.title(pal.accent, size: 22)),
                  const Spacer(),
                  PixelButton(
                      label: 'Vote in secret', expand: true, onTap: () => setState(() => _phase = _Phase.voting)),
                ]),
              _Phase.voting => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 10),
                  Text('${_round.nextVoter}, tap your pick:', style: PixelFonts.body(pal.text)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (final p in players) PixelChip(label: p, onTap: () => _vote(p)),
                  ]),
                ]),
              _Phase.results => _results(context),
            },
          ),
        ]),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final pal = context.pal;
    final tally = _round.tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = tally.first.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Text('${_round.winners.join(' & ')} drink${_round.winners.length == 1 ? 's' : ''} $top!',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 15)),
      const SizedBox(height: 14),
      Expanded(
        child: ListView(children: [
          for (final e in tally)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 96, child: Text(e.key, style: PixelFonts.body(pal.text), overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: top == 0 ? 0 : e.value / top,
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
                const SizedBox(width: 8),
                Text('${e.value}', style: PixelFonts.title(pal.accent, size: 12)),
              ]),
            ),
        ]),
      ),
      PixelButton(
        label: 'Next question',
        expand: true,
        onTap: () => setState(() {
          _prompt = _prompts.next();
          _round = VoteRound(context.app.players);
          _phase = _Phase.handoff;
        }),
      ),
    ]);
  }
}
