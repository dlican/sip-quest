import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/playing_card.dart';
import '../common.dart';
import 'higher_lower.dart';

class HigherLowerScreen extends StatefulWidget {
  const HigherLowerScreen({super.key});

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  final _game = HigherLower();
  late final TurnOrder _turns = TurnOrder(context.app.players);
  HLResult? _last;
  String? _loser;

  void _guess(HLGuess g) {
    final guesser = _turns.current;
    final r = _game.guess(g);
    if (r.outcome == HLOutcome.wrong) {
      Fx.lose();
      _loser = guesser;
      _turns.advance();
    } else {
      Fx.correct();
    }
    setState(() => _last = r);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final r = _last;
    final msg = switch (r?.outcome) {
      null => 'Will the next card be higher or lower? Aces high.',
      HLOutcome.correct => 'Streak ${_game.streak}! Keep going.',
      HLOutcome.tie => 'Same rank. Streak survives.',
      HLOutcome.wrong => '${_loser ?? 'Guesser'} drinks ${r!.drinks}! Streak reset.',
    };
    return PixelScaffold(
      title: 'Higher or Lower',
      onHelp: () => showHowToPlay(context, 'higher_lower'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('STREAK ', style: PixelFonts.title(pal.textDim, size: 10)),
            Text('${_game.streak}', style: PixelFonts.title(pal.accent, size: 18)),
            const Spacer(),
            Text('BEST ${_game.best}', style: PixelFonts.title(pal.textDim, size: 10)),
          ]),
          const SizedBox(height: 6),
          PixelBar(value: min(_game.streak, 10) / 10, segments: 10, color: pal.accent),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final w = min(box.maxWidth * 0.55, box.maxHeight * 0.85 * kCardRatio);
              return Center(child: FlippingCard(card: _game.current, width: w));
            }),
          ),
          PixelBox(
            borderColor: r?.outcome == HLOutcome.wrong ? pal.primary : pal.border,
            child: Text(msg,
                textAlign: TextAlign.center,
                style: PixelFonts.body(r?.outcome == HLOutcome.wrong ? pal.primary : pal.text)),
          ),
          const SizedBox(height: 10),
          if (_turns.current != null)
            Text('${_turns.current} is guessing',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.secondary, size: 24)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: PixelButton(label: 'Lower', expand: true, color: pal.secondary, onTap: () => _guess(HLGuess.lower)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PixelButton(label: 'Higher', expand: true, onTap: () => _guess(HLGuess.higher)),
            ),
          ]),
        ]),
      ),
    );
  }
}
