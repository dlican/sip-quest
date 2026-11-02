import 'dart:math';

import '../cards.dart';

enum DealerOutcome { correctFirst, correctSecond, higher, lower, miss }

class DealerResult {
  const DealerResult(this.outcome, {this.drinks = 0, this.dealerDrinks = 0, this.dealerPasses = false});
  final DealerOutcome outcome;

  /// Sips for the guesser (difference between guess and card on a miss).
  final int drinks;

  /// Sips for the dealer when the guesser gets it.
  final int dealerDrinks;

  /// True when the dealer has survived [BeatTheDealer.passAfter] guessers in a
  /// row and hands the deck on.
  final bool dealerPasses;
}

/// The dealer looks at the top card. The guesser names a rank. If wrong, the
/// dealer says higher or lower and they get one more try. Miss twice and the
/// guesser drinks the difference. Get it and the dealer drinks (4 on the first
/// try, 2 on the second). After [passAfter] misses in a row the deck passes on.
class BeatTheDealer {
  BeatTheDealer({this.passAfter = 3, Random? random}) {
    _deck = Deck.standard(random: random ?? Random());
    _flip();
  }

  final int passAfter;
  late Deck _deck;
  late PlayingCard card;
  int tries = 0;
  int missStreak = 0;
  final List<PlayingCard> played = [];

  bool isOver = false;

  int get remaining => _deck.remaining;

  void _flip() {
    card = _deck.draw();
    tries = 0;
  }

  DealerResult guess(int rank) {
    if (isOver) throw StateError('Deck is finished');
    if (rank < 1 || rank > 13) throw ArgumentError('rank 1..13');
    if (rank == card.rank) {
      final first = tries == 0;
      _finishCard(missed: false);
      return DealerResult(first ? DealerOutcome.correctFirst : DealerOutcome.correctSecond,
          dealerDrinks: first ? 4 : 2);
    }
    if (tries == 0) {
      tries = 1;
      return DealerResult(card.rank > rank ? DealerOutcome.higher : DealerOutcome.lower);
    }
    final diff = (card.rank - rank).abs();
    final passes = _finishCard(missed: true);
    return DealerResult(DealerOutcome.miss, drinks: diff, dealerPasses: passes);
  }

  bool _finishCard({required bool missed}) {
    played.add(card);
    var passes = false;
    if (missed) {
      missStreak++;
      if (missStreak >= passAfter) {
        missStreak = 0;
        passes = true;
      }
    } else {
      missStreak = 0;
    }
    if (_deck.isEmpty) {
      isOver = true;
      tries = 0;
    } else {
      _flip();
    }
    return passes;
  }
}
