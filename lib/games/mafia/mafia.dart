import 'dart:math';

enum MafiaRole {
  mafia('Mafia', 'Each night, pick someone to eliminate. Blend in by day.'),
  doctor('Doctor', 'Each night, pick someone to save. You can save yourself.'),
  detective('Detective', 'Each night, check one player to learn if they are Mafia.'),
  villager('Villager', 'Find the Mafia and vote them out. At night, just tap a name.');

  const MafiaRole(this.title, this.goal);
  final String title;
  final String goal;
}

enum MafiaSide { town, mafia }

/// Default Mafia count: one per four players.
int defaultMafiaCount(int players) => max(1, players ~/ 4);

/// A narrator-free game: at night the phone goes round the table and every
/// living player taps a name in secret, so nobody can tell who has a power.
class MafiaGame {
  MafiaGame(List<String> players, {int? mafiaCount, Random? random})
      : players = List.unmodifiable(players),
        _random = random ?? Random() {
    if (players.length < 5) throw ArgumentError('Mafia needs at least 5 players');
    final m = mafiaCount ?? defaultMafiaCount(players.length);
    final deck = [
      for (var i = 0; i < m; i++) MafiaRole.mafia,
      MafiaRole.doctor,
      if (players.length >= 6) MafiaRole.detective,
    ];
    if (m < 1 || deck.length >= players.length) throw ArgumentError('Too many Mafia');
    while (deck.length < players.length) {
      deck.add(MafiaRole.villager);
    }
    deck.shuffle(_random);
    roles = {for (var i = 0; i < players.length; i++) players[i]: deck[i]};
    alive.addAll(players);
  }

  final List<String> players;
  final Random _random;
  late final Map<String, MafiaRole> roles;
  final Set<String> alive = {};
  int night = 1;

  final Map<String, String> _mafiaPicks = {};
  String? _saved;

  List<String> get living => [for (final p in players) if (alive.contains(p)) p];
  List<String> get mafia => [for (final p in players) if (roles[p] == MafiaRole.mafia) p];

  /// Records a player's secret night tap. Returns what the Detective learns.
  bool? act(String player, String target) {
    if (!alive.contains(player) || !alive.contains(target)) throw ArgumentError('Dead players cannot act');
    switch (roles[player]!) {
      case MafiaRole.mafia:
        _mafiaPicks[player] = target;
      case MafiaRole.doctor:
        _saved = target;
      case MafiaRole.detective:
        return roles[target] == MafiaRole.mafia;
      case MafiaRole.villager:
        break;
    }
    return null;
  }

  /// Ends the night. The Mafia's most-picked target is eliminated unless the
  /// Doctor saved them (ties are broken at random). Returns who died, if anyone.
  String? resolveNight() {
    final counts = <String, int>{};
    for (final t in _mafiaPicks.values) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    String? victim;
    if (counts.isNotEmpty) {
      final top = counts.values.reduce(max);
      final tied = [for (final e in counts.entries) if (e.value == top) e.key];
      victim = tied[_random.nextInt(tied.length)];
    }
    if (victim == _saved) victim = null;
    if (victim != null) alive.remove(victim);
    _mafiaPicks.clear();
    _saved = null;
    night++;
    return victim;
  }

  /// The town voted someone out by day.
  void voteOut(String player) {
    if (!alive.remove(player)) throw ArgumentError('$player is not alive');
  }

  /// Mafia win once they match the town in number; town wins when no Mafia
  /// are left. Null while the game goes on.
  MafiaSide? get winner {
    final m = living.where((p) => roles[p] == MafiaRole.mafia).length;
    if (m == 0) return MafiaSide.town;
    if (m >= living.length - m) return MafiaSide.mafia;
    return null;
  }
}
