import 'dart:math';

/// The three Fishbowl rounds, played with the same slips each time.
enum FishbowlRound {
  describe('Describe it', 'Say anything except the words on the slip.'),
  oneWord('One word', 'Give exactly one word as a clue. No gestures.'),
  actItOut('Act it out', 'No talking. Act it out like charades.');

  const FishbowlRound(this.title, this.rule);
  final String title;
  final String rule;
}

class FishbowlTeam {
  FishbowlTeam(this.name, this.players);
  final String name;
  final List<String> players;
  int score = 0;
  int _giver = 0;

  /// Whose turn it is to give clues, or null when playing without names.
  String? get clueGiver => players.isEmpty ? null : players[_giver % players.length];
}

/// Splits players into two teams by alternating seats, so teammates are not
/// sitting next to each other. With no names, the teams are anonymous.
List<FishbowlTeam> fishbowlTeams(List<String> players) => [
      FishbowlTeam('Team A', [for (var i = 0; i < players.length; i += 2) players[i]]),
      FishbowlTeam('Team B', [for (var i = 1; i < players.length; i += 2) players[i]]),
    ];

/// Teams take timed turns pulling slips from the bowl. Each round ends when
/// the bowl is empty; then every slip goes back in for the next round.
class Fishbowl {
  Fishbowl({required List<String> slips, required this.teams, Random? random})
      : slips = List.unmodifiable(slips),
        _random = random ?? Random() {
    if (slips.isEmpty) throw ArgumentError('Fishbowl needs at least one slip');
    _bowl.addAll(slips);
  }

  final List<String> slips;
  final List<FishbowlTeam> teams;
  final Random _random;
  final List<String> _bowl = [];
  int _round = 0;
  int _team = 0;

  /// The slip being guessed right now, if any.
  String? current;

  FishbowlRound get round => FishbowlRound.values[_round];
  bool get isLastRound => _round == FishbowlRound.values.length - 1;
  FishbowlTeam get team => teams[_team];
  int get slipsLeft => _bowl.length + (current == null ? 0 : 1);
  bool get roundOver => slipsLeft == 0;

  /// Pulls a random slip. After a skip it avoids handing back the same one.
  String draw({String? avoid}) {
    if (current != null) return current!;
    if (_bowl.isEmpty) throw StateError('The bowl is empty');
    var i = _random.nextInt(_bowl.length);
    if (_bowl.length > 1 && _bowl[i] == avoid) i = (i + 1) % _bowl.length;
    return current = _bowl.removeAt(i);
  }

  /// The team guessed the current slip: it scores and leaves the bowl.
  void gotIt() {
    if (current == null) throw StateError('No slip drawn');
    team.score++;
    current = null;
  }

  /// Puts the current slip back and draws a different one.
  String skip() {
    final s = current;
    if (s == null) throw StateError('No slip drawn');
    _bowl.add(s);
    current = null;
    return draw(avoid: s);
  }

  /// Time is up: the slip goes back and the other team plays next.
  void endTurn() {
    if (current != null) _bowl.add(current!);
    current = null;
    team._giver++;
    _team = (_team + 1) % teams.length;
  }

  /// Refills the bowl for the next round. The team that emptied the bowl
  /// keeps going, with the same clue giver.
  void nextRound() {
    if (!roundOver) throw StateError('Round still has slips');
    if (isLastRound) throw StateError('No rounds left');
    _round++;
    _bowl.addAll(slips);
  }

  /// Highest score wins; null on a tie.
  FishbowlTeam? get winner {
    final sorted = [...teams]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.length > 1 && sorted[0].score == sorted[1].score ? null : sorted.first;
  }
}
