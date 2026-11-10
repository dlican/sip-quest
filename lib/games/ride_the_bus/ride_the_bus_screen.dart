import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/playing_card.dart';
import '../../widgets/sprites.dart';
import '../cards.dart';
import '../common.dart';
import 'ride_the_bus.dart';

class RideTheBusScreen extends StatefulWidget {
  const RideTheBusScreen({super.key});

  @override
  State<RideTheBusScreen> createState() => _RideTheBusScreenState();
}

class _RideTheBusScreenState extends State<RideTheBusScreen> {
  RideTheBus _game = RideTheBus();
  late final TurnOrder _riders = TurnOrder(context.app.players);
  BusResult? _last;

  String _question() {
    final r = _game.row;
    return switch (_game.stage) {
      BusStage.color => 'Red or black?',
      BusStage.higherLower => 'Higher or lower than ${r[0].rankLabel}?',
      BusStage.insideOutside => 'Inside or outside ${r[0].rankLabel} and ${r[1].rankLabel}?',
      BusStage.suit => 'Pick the suit.',
    };
  }

  static String _label(BusGuess g) => switch (g) {
    BusGuess.red => 'Red',
    BusGuess.black => 'Black',
    BusGuess.higher => 'Higher',
    BusGuess.lower => 'Lower',
    BusGuess.inside => 'Inside',
    BusGuess.outside => 'Outside',
    _ => g.name,
  };

  static bool _isSuit(BusGuess g) => g.index >= BusGuess.hearts.index;

  void _guess(BusGuess g) {
    final res = _game.guess(g);
    if (res.correct) {
      Fx.correct();
    } else {
      Fx.lose();
    }
    setState(() => _last = res);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final rider = _riders.current;
    return PixelScaffold(
      title: 'Ride the Bus',
      onHelp: () => showHowToPlay(context, 'ride_the_bus'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (rider != null) Text(rider, style: PixelFonts.body(pal.secondary, size: 26)),
                const Spacer(),
                Text('TRY ${_game.attempts}  ', style: PixelFonts.title(pal.textDim, size: 10)),
                Text('PENALTIES ${_game.penalties}', style: PixelFonts.title(pal.primary, size: 10)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 3 * 10) / 4;
                return Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      i < _game.row.length
                          ? CardFace(card: _game.row[i], width: w)
                          : Opacity(
                              opacity: i == _game.row.length ? 1 : 0.35,
                              child: CardBack(width: w),
                            ),
                    ],
                  ],
                );
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Center(
                  child: _last == null
                      ? Text(
                          'Four right in a row gets you off the bus.\nMiss one: penalty, and start over.',
                          textAlign: TextAlign.center,
                          style: PixelFonts.body(pal.text),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FlippingCard(
                              card: _last!.card,
                              width: min(box.maxWidth * 0.42, box.maxHeight * 0.8 * kCardRatio),
                            ),
                            const SizedBox(width: 18),
                            Flexible(
                              child: Text(
                                _last!.finished
                                    ? 'OFF THE BUS!'
                                    : _last!.correct
                                    ? 'NICE!'
                                    : 'WRONG!\nDrink and start over.',
                                style: PixelFonts.title(
                                  _last!.correct ? pal.secondary : pal.primary,
                                  size: _last!.finished ? 18 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (_game.finished) ...[
              Text(
                'Done in ${_game.attempts} ${_game.attempts == 1 ? 'try' : 'tries'}, ${_game.penalties} penalties.',
                textAlign: TextAlign.center,
                style: PixelFonts.body(pal.accent),
              ),
              const SizedBox(height: 12),
              PixelButton(
                label: rider == null ? 'Ride again' : 'Next rider',
                expand: true,
                onTap: () => setState(() {
                  _riders.advance();
                  _game = RideTheBus();
                  _last = null;
                }),
              ),
            ] else ...[
              Text(_question(), textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 14)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final (i, g) in RideTheBus.optionsFor(_game.stage).indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _isSuit(g)
                          ? PixelButton(
                              label: '',
                              expand: true,
                              color: pal.cardFace,
                              leading: PixelSprite(suitSprite(Suit.values.byName(g.name)), pixel: 3),
                              onTap: () => _guess(g),
                            )
                          : PixelButton(
                              label: _label(g),
                              expand: true,
                              size: 12,
                              color: [pal.primary, pal.secondary][min(i, 1)],
                              onTap: () => _guess(g),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
