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
  1: KingsRule('Waterfall',
      'Everyone starts drinking. You can only stop when the person before you stops. The drawer goes first and can stop whenever.'),
  2: KingsRule('You', 'Pick someone to take a drink.'),
  3: KingsRule('Me', 'You take a drink.'),
  4: KingsRule('Floor', 'Last person to touch the floor drinks.'),
  5: KingsRule('Guys', 'All the guys drink.'),
  6: KingsRule('Ladies', 'All the ladies drink.'),
  7: KingsRule('Heaven', 'Last person to point to the sky drinks.'),
  8: KingsRule('Mate', 'Pick a mate. Every time you drink, they drink too, until the next 8.'),
  9: KingsRule('Rhyme', 'Say a word. Go around rhyming. First to repeat or freeze drinks.'),
  10: KingsRule('Categories', 'Pick a category. Go around naming things in it. First to blank drinks.'),
  11: KingsRule('Make a Rule', 'Invent a rule everyone must follow. Break it, drink.'),
  12: KingsRule('Question Master',
      'Anyone who answers a question you ask drinks, until the next Queen.'),
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
    if (status == KingsCupStatus.playing && deck.isEmpty) status = KingsCupStatus.deckEmpty;
    return c;
  }

  void addHouseRule(String rule) {
    final r = rule.trim();
    if (r.isNotEmpty) houseRules.add(r);
  }
}
