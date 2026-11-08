import 'dart:math';

import '../cards.dart';

class KingsRule {
  const KingsRule(this.title, this.description);
  final String title;
  final String description;

  KingsRule copyWith({String? title, String? description}) =>
      KingsRule(title ?? this.title, description ?? this.description);
}

/// The common house rules. Players can edit these in-game.
const Map<int, KingsRule> defaultKingsRules = {
  1: KingsRule('Hot Seat',
      'You are in the hot seat. Everyone asks you one question. Answer honestly or drink.'),
  2: KingsRule('Back to Back',
      'Pick two people to stand back to back. Ask questions like "Who is the better driver?". They each raise a hand for themselves or keep it down for the other. If they both raise or both stay down, they both drink.'),
  3: KingsRule('Give 3', 'Hand out 3 drinks. Give them all to one person or split them up.'),
  4: KingsRule('Floor', 'Last person to touch the floor drinks.'),
  5: KingsRule('Drive',
      'Go around the circle saying "vroom" to pass it on. "Skrrt" reverses direction, "beep beep" skips the next person. Hesitate or mess up and you drink.'),
  6: KingsRule('Most Likely To',
      'Ask "Who is most likely to...?". On 3, everyone points. Drink once for every finger pointing at you.'),
  7: KingsRule('Heaven', 'Last person to point to the sky drinks.'),
  8: KingsRule('Mate', 'Pick a mate. Every time you drink, they drink too, until the next 8.'),
  9: KingsRule('Would You Rather',
      'Ask a "Would you rather...?". Everyone picks a side at once. The smaller side drinks.'),
  10: KingsRule('Thumb Master',
      'You are the Thumb Master until the next 10. Whenever you like, quietly put your thumb on your nose. The last person to notice and copy you drinks.'),
  11: KingsRule('Make a Rule', 'Invent a rule everyone must follow. Break it, drink.'),
  12: KingsRule('Question Queen',
      'You are the Question Queen until the next Queen. Anyone who answers a question you ask drinks.'),
  13: KingsRule("King's Cup",
      'Pour some of your drink into the cup. Whoever draws the 4th King drinks the whole cup.'),
};

enum KingsCupStatus { playing, fourthKing, deckEmpty }

/// Pure game logic, kept free of Flutter so it can be unit tested.
class KingsCupGame {
  KingsCupGame({required List<String> players, Random? random, Map<int, KingsRule>? rules})
      : _players = List.of(players),
        _random = random ?? Random(),
        rules = Map.of(rules ?? defaultKingsRules) {
    deck = Deck.standard(random: _random);
  }

  final List<String> _players;
  final Random _random;
  final Map<int, KingsRule> rules;

  late Deck deck;
  PlayingCard? current;
  final List<PlayingCard> drawn = [];
  final List<String> houseRules = [];
  int kingsDrawn = 0;
  int _turn = -1;
  String? questionMaster;

  /// Who drew the last 10. Their thumb-on-nose power lasts until the next 10.
  String? thumbMaster;
  KingsCupStatus status = KingsCupStatus.playing;

  bool get hasPlayers => _players.isNotEmpty;

  /// Player who drew [current], or null when no players are set.
  String? get currentPlayer => hasPlayers && _turn >= 0 ? _players[_turn % _players.length] : null;

  /// Player who will draw next.
  String? get nextPlayer => hasPlayers ? _players[(_turn + 1) % _players.length] : null;

  KingsRule get currentRule => rules[current!.rank]!;

  PlayingCard? draw() {
    if (status != KingsCupStatus.playing || deck.isEmpty) return null;
    final c = deck.draw();
    _turn++;
    current = c;
    drawn.add(c);
    if (c.rank == 13) {
      kingsDrawn++;
      if (kingsDrawn == 4) status = KingsCupStatus.fourthKing;
    }
    if (c.rank == 12) questionMaster = currentPlayer;
    if (c.rank == 10) thumbMaster = currentPlayer;
    if (status == KingsCupStatus.playing && deck.isEmpty) status = KingsCupStatus.deckEmpty;
    return c;
  }

  void addHouseRule(String rule) {
    final r = rule.trim();
    if (r.isNotEmpty) houseRules.add(r);
  }
}
