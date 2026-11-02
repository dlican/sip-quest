import 'dart:math';

import '../cards.dart';

enum HLGuess { higher, lower }

enum HLOutcome { correct, tie, wrong }

class HLResult {
  const HLResult(this.card, this.outcome, this.drinks);
  final PlayingCard card;
  final HLOutcome outcome;

  /// Sips owed by the guesser when wrong: the length of the streak they broke
  /// (minimum 1).
  final int drinks;
}

/// Guess whether the next card is higher or lower. Each right guess grows the
/// streak. A tie keeps the streak alive. A wrong guess costs sips equal to the
/// streak and resets it. Aces are high.
class HigherLower {
  HigherLower({Random? random}) : _random = random ?? Random() {
    _deck = Deck.standard(random: _random);
    current = _deck.draw();
  }

  final Random _random;
  late Deck _deck;
  late PlayingCard current;
  int streak = 0;
  int best = 0;

  static int value(PlayingCard c) => c.rank == 1 ? 14 : c.rank;

  int get remaining => _deck.remaining;

  HLResult guess(HLGuess g) {
    if (_deck.isEmpty) _deck = Deck.standard(random: _random);
    final next = _deck.draw();
    final a = value(current), b = value(next);
    current = next;
    if (a == b) return HLResult(next, HLOutcome.tie, 0);
    final ok = g == HLGuess.higher ? b > a : b < a;
    if (ok) {
      streak++;
      best = max(best, streak);
      return HLResult(next, HLOutcome.correct, 0);
    }
    final owed = max(1, streak);
    streak = 0;
    return HLResult(next, HLOutcome.wrong, owed);
  }
}
