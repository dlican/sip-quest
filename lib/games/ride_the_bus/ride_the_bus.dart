import 'dart:math';

import '../cards.dart';

/// The four questions of Ride the Bus, asked in order.
enum BusStage { color, higherLower, insideOutside, suit }

enum BusGuess { red, black, higher, lower, inside, outside, hearts, diamonds, clubs, spades }

class BusResult {
  const BusResult(this.card, this.correct, {this.finished = false});
  final PlayingCard card;
  final bool correct;
  final bool finished;
}

/// Get four right in a row to get off the bus. Any wrong answer costs a drink
/// and sends you back to the first question. Ties (same rank, or landing on a
/// boundary for inside/outside) count as wrong. Aces are high.
class RideTheBus {
  RideTheBus({Random? random}) : _random = random ?? Random() {
    _deck = Deck.standard(random: _random);
  }

  final Random _random;
  late Deck _deck;

  /// Cards dealt in the current attempt (0 to 4).
  final List<PlayingCard> row = [];
  int drinks = 0;
  int attempts = 1;
  bool finished = false;

  BusStage get stage => BusStage.values[row.length.clamp(0, 3)];

  static int value(PlayingCard c) => c.rank == 1 ? 14 : c.rank;

  static List<BusGuess> optionsFor(BusStage s) => switch (s) {
        BusStage.color => [BusGuess.red, BusGuess.black],
        BusStage.higherLower => [BusGuess.higher, BusGuess.lower],
        BusStage.insideOutside => [BusGuess.inside, BusGuess.outside],
        BusStage.suit => [BusGuess.hearts, BusGuess.diamonds, BusGuess.clubs, BusGuess.spades],
      };

  PlayingCard _draw() {
    if (_deck.isEmpty) _deck = Deck.standard(random: _random);
    return _deck.draw();
  }

  /// Judges [g] against a card. Exposed for tests.
  static bool judge(BusStage stage, BusGuess g, PlayingCard card, List<PlayingCard> row) {
    final v = value(card);
    switch (stage) {
      case BusStage.color:
        return card.suit.isRed == (g == BusGuess.red);
      case BusStage.higherLower:
        final prev = value(row[0]);
        return g == BusGuess.higher ? v > prev : v < prev;
      case BusStage.insideOutside:
        final lo = min(value(row[0]), value(row[1]));
        final hi = max(value(row[0]), value(row[1]));
        return g == BusGuess.inside ? (v > lo && v < hi) : (v < lo || v > hi);
      case BusStage.suit:
        return card.suit.name == g.name;
    }
  }

  BusResult guess(BusGuess g) {
    if (finished) throw StateError('Already off the bus');
    if (!optionsFor(stage).contains(g)) throw ArgumentError('$g is not valid for $stage');
    final card = _draw();
    final ok = judge(stage, g, card, row);
    if (!ok) {
      drinks++;
      attempts++;
      row.clear();
      return BusResult(card, false);
    }
    row.add(card);
    if (row.length == 4) finished = true;
    return BusResult(card, true, finished: finished);
  }
}
