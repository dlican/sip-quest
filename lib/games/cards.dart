import 'dart:math';

enum Suit { hearts, diamonds, clubs, spades }

extension SuitX on Suit {
  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
  String get label => switch (this) {
        Suit.hearts => 'Hearts',
        Suit.diamonds => 'Diamonds',
        Suit.clubs => 'Clubs',
        Suit.spades => 'Spades',
      };
}

class PlayingCard {
  const PlayingCard(this.rank, this.suit);

  /// 1 = Ace, 11 = Jack, 12 = Queen, 13 = King.
  final int rank;
  final Suit suit;

  String get rankLabel => switch (rank) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rank',
      };

  String get name {
    final r = switch (rank) {
      1 => 'Ace',
      11 => 'Jack',
      12 => 'Queen',
      13 => 'King',
      _ => '$rank',
    };
    return '$r of ${suit.label}';
  }

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => '$rankLabel${suit.name[0]}';
}

/// A standard 52 card deck that draws from the top.
class Deck {
  Deck._(this._cards);

  factory Deck.standard({Random? random, bool Function(PlayingCard)? where}) {
    final cards = [
      for (final s in Suit.values)
        for (var r = 1; r <= 13; r++) PlayingCard(r, s),
    ].where(where ?? (_) => true).toList()
      ..shuffle(random ?? Random());
    return Deck._(cards);
  }

  final List<PlayingCard> _cards;

  int get remaining => _cards.length;
  bool get isEmpty => _cards.isEmpty;

  PlayingCard draw() => _cards.removeLast();
}
