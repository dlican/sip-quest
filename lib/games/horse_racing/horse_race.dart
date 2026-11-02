import 'dart:math';

import '../cards.dart';

class RaceEvent {
  const RaceEvent(this.card, this.suit, this.delta, {this.checkpoint = false});
  final PlayingCard card;
  final Suit suit;
  final int delta;
  final bool checkpoint;
}

/// Classic card horse race. The four aces are the horses. [trackLength] cards
/// are laid face down along the side of the track. Each flip moves the horse
/// of that suit forward one step. When every horse has passed a side card, it
/// is turned over and that suit's horse moves back one. First horse past the
/// last side card wins.
class HorseRace {
  HorseRace({this.trackLength = 7, Random? random}) {
    final r = random ?? Random();
    _deck = Deck.standard(random: r, where: (c) => c.rank != 1);
    for (var i = 0; i < trackLength; i++) {
      sideCards.add(_deck.draw());
    }
  }

  final int trackLength;
  late final Deck _deck;
  final List<PlayingCard> sideCards = [];
  int sideRevealed = 0;
  final Map<Suit, int> position = {for (final s in Suit.values) s: 0};
  Suit? winner;
  PlayingCard? lastCard;

  /// Finish is one step past the last side card.
  int get finish => trackLength + 1;
  bool get isOver => winner != null;
  int get remaining => _deck.remaining;

  /// Flips the next card and applies any checkpoint penalties.
  List<RaceEvent> step() {
    if (isOver) return const [];
    if (_deck.isEmpty) {
      // Out of cards: whoever is furthest ahead takes it.
      winner = Suit.values.reduce((a, b) => position[b]! > position[a]! ? b : a);
      return const [];
    }
    final events = <RaceEvent>[];
    final c = _deck.draw();
    lastCard = c;
    position[c.suit] = position[c.suit]! + 1;
    events.add(RaceEvent(c, c.suit, 1));
    if (position[c.suit]! >= finish) {
      winner = c.suit;
      return events;
    }
    // Every horse past checkpoint N (1-based) flips side card N.
    while (sideRevealed < trackLength &&
        position.values.every((p) => p >= sideRevealed + 1)) {
      final side = sideCards[sideRevealed++];
      position[side.suit] = max(0, position[side.suit]! - 1);
      events.add(RaceEvent(side, side.suit, -1, checkpoint: true));
    }
    return events;
  }
}
