import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import 'truth_or_drink.dart';

class TruthOrDrinkScreen extends StatefulWidget {
  const TruthOrDrinkScreen({super.key});

  @override
  State<TruthOrDrinkScreen> createState() => _TruthOrDrinkScreenState();
}

class _TruthOrDrinkScreenState extends State<TruthOrDrinkScreen> {
  late final TruthOrDrink _game = TruthOrDrink(context.app.players);
  late TruthTurn _turn = _game.deal();
  String? _verdict;

  void _resolve(bool answered) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (answered) {
        _game.answered();
        _verdict = 'Truth told. Respect.';
      } else {
        _game.drank();
        _verdict = '${_turn.answerer ?? 'They'} chose to drink!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = _turn;
    return PixelScaffold(
      title: 'Truth or Drink',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (t.asker != null)
            Text('${t.asker} asks ${t.answerer}:',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.secondary, size: 26)),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              PixelSprite(Sprites.lips, pixel: 7),
              const SizedBox(height: 22),
              PixelBox(
                child: Text(t.question, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 16)),
              ),
              if (_verdict != null) ...[
                const SizedBox(height: 16),
                Text(_verdict!, style: PixelFonts.title(pal.accent, size: 12), textAlign: TextAlign.center),
              ],
            ]),
          ),
          if (_game.drinks.isNotEmpty)
            Text(
              'Drinks so far: ${_game.drinks.entries.map((e) => '${e.key} ${e.value}').join(', ')}',
              textAlign: TextAlign.center,
              style: PixelFonts.body(pal.textDim, size: 20),
            ),
          const SizedBox(height: 10),
          if (_verdict == null)
            Row(children: [
              Expanded(
                child: PixelButton(label: 'Drink', expand: true, color: pal.primary, onTap: () => _resolve(false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(label: 'Answer', expand: true, color: pal.secondary, onTap: () => _resolve(true)),
              ),
            ])
          else
            PixelButton(
              label: 'Next',
              expand: true,
              onTap: () => setState(() {
                _turn = _game.deal();
                _verdict = null;
              }),
            ),
        ]),
      ),
    );
  }
}
