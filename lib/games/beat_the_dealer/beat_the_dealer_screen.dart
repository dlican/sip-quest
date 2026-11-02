import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/playing_card.dart';
import '../cards.dart';
import 'beat_the_dealer.dart';

const _ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

class BeatTheDealerScreen extends StatefulWidget {
  const BeatTheDealerScreen({super.key});

  @override
  State<BeatTheDealerScreen> createState() => _BeatTheDealerScreenState();
}

class _BeatTheDealerScreenState extends State<BeatTheDealerScreen> {
  BeatTheDealer _game = BeatTheDealer();
  int _dealer = 0;
  int _guesser = 1;
  PlayingCard? _revealed;
  String _msg = 'Dealer peeks at the card. Guesser, name a rank.';
  int? _firstGuess;

  List<String> get _players => context.app.players;
  String? _name(int i) => _players.isEmpty ? null : _players[i % _players.length];

  void _nextGuesser() {
    if (_players.length < 2) return;
    _guesser++;
    if (_guesser % _players.length == _dealer % _players.length) _guesser++;
  }

  void _guess(int rank) {
    final card = _game.card;
    final res = _game.guess(rank);
    final guesser = _name(_guesser) ?? 'Guesser';
    final dealer = _name(_dealer) ?? 'Dealer';
    setState(() {
      switch (res.outcome) {
        case DealerOutcome.higher:
        case DealerOutcome.lower:
          HapticFeedback.mediumImpact();
          _firstGuess = rank;
          _msg = '${res.outcome == DealerOutcome.higher ? 'HIGHER' : 'LOWER'} than ${_ranks[rank - 1]}. One more try.';
          return;
        case DealerOutcome.correctFirst:
        case DealerOutcome.correctSecond:
          HapticFeedback.heavyImpact();
          _msg = 'Got it! $dealer drinks ${res.dealerDrinks}.';
        case DealerOutcome.miss:
          HapticFeedback.heavyImpact();
          _msg = 'Nope. $guesser drinks ${res.drinks}.';
          if (res.dealerPasses) {
            _msg += '\n$dealer survived 3 in a row. Deck passes on!';
            if (_players.length >= 2) {
              _dealer++;
              _guesser = _dealer;
            }
          }
      }
      _revealed = card;
      _firstGuess = null;
      _nextGuesser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final seen = <int, int>{};
    for (final c in _game.played) {
      seen[c.rank] = (seen[c.rank] ?? 0) + 1;
    }
    return PixelScaffold(
      title: 'Beat the Dealer',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_players.length >= 2)
            Row(children: [
              Text('DEALER ', style: PixelFonts.title(pal.textDim, size: 10)),
              Expanded(
                child: Text(_name(_dealer)!,
                    overflow: TextOverflow.ellipsis, style: PixelFonts.body(pal.accent, size: 26)),
              ),
              Text('GUESSER ', style: PixelFonts.title(pal.textDim, size: 10)),
              Flexible(
                child: Text(_name(_guesser)!,
                    overflow: TextOverflow.ellipsis, style: PixelFonts.body(pal.secondary, size: 26)),
              ),
            ]),
          Row(children: [
            Text('MISS STREAK ${_game.missStreak}/${_game.passAfter}', style: PixelFonts.title(pal.primary, size: 9)),
            const Spacer(),
            Text('${_game.remaining} left', style: PixelFonts.body(pal.textDim, size: 22)),
          ]),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final w = min(box.maxWidth * 0.4, box.maxHeight * 0.85 * kCardRatio);
              return Center(
                child: _revealed != null
                    ? FlippingCard(card: _revealed!, width: w)
                    : CardBack(width: w),
              );
            }),
          ),
          PixelBox(
            padding: const EdgeInsets.all(10),
            child: Text(_msg, textAlign: TextAlign.center, style: PixelFonts.body(pal.text, size: 23)),
          ),
          const SizedBox(height: 10),
          if (_game.isOver) ...[
            PixelButton(
              label: 'New deck',
              expand: true,
              onTap: () => setState(() {
                _game = BeatTheDealer();
                _revealed = null;
                _msg = 'Fresh deck. Guesser, name a rank.';
              }),
            ),
          ] else if (_revealed != null) ...[
            PixelButton(
              label: 'Next card',
              expand: true,
              onTap: () => setState(() {
                _revealed = null;
                _msg = '${_name(_guesser) ?? 'Guesser'}, name a rank.';
              }),
            ),
          ] else
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.85,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var r = 1; r <= 13; r++) _rankKey(context, r, seen[r] ?? 0),
              ],
            ),
        ]),
      ),
    );
  }

  Widget _rankKey(BuildContext context, int rank, int seen) {
    final pal = context.pal;
    final gone = seen >= 4;
    final picked = _firstGuess == rank;
    return GestureDetector(
      onTap: gone || picked ? null : () => _guess(rank),
      child: Container(
        decoration: BoxDecoration(
          color: picked ? pal.primary : (gone ? pal.bg : pal.cardFace),
          border: Border.all(color: pal.cardBlack, width: 3),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_ranks[rank - 1], style: PixelFonts.title(gone ? pal.textDim : pal.cardBlack, size: 12)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: i < seen ? pal.cardRed : pal.textDim.withValues(alpha: 0.4),
              ),
          ]),
        ]),
      ),
    );
  }
}
