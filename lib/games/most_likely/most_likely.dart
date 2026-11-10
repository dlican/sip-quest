const mostLikelyPrompts = [
  'Who is most likely to become a millionaire?',
  'Who is most likely to get lost in their own city?',
  'Who is most likely to go viral for something embarrassing?',
  'Who is most likely to marry a celebrity?',
  'Who is most likely to forget their own birthday?',
  'Who is most likely to survive a horror movie?',
  'Who is most likely to cry at a commercial?',
  'Who is most likely to win a hot dog eating contest?',
  'Who is most likely to start a fight at a wedding?',
  'Who is most likely to be late to their own funeral?',
  'Who is most likely to adopt a pet without asking anyone?',
  'Who is most likely to quit their job to travel the world?',
  'Who is most likely to sing karaoke without being asked?',
  'Who is most likely to text the wrong person?',
  'Who is most likely to become a reality TV star?',
  'Who is most likely to fall asleep first tonight?',
  'Who is most likely to get kicked out of a bar?',
  'Who is most likely to have a secret talent?',
  'Who is most likely to laugh at the worst moment?',
  'Who is most likely to eat something off the floor?',
  'Who is most likely to lose their phone tonight?',
  'Who is most likely to start a podcast?',
  'Who is most likely to get a tattoo they regret?',
  'Who is most likely to win the lottery and lose it all?',
  'Who is most likely to befriend a stranger at the bar?',
  'Who is most likely to go skydiving?',
  'Who is most likely to stalk an ex online?',
  'Who is most likely to say "one more episode" five times?',
  'Who is most likely to get married in Vegas?',
  'Who is most likely to be a secret agent?',
];

/// One round of secret voting. Each player votes once for anyone (including
/// themselves). The most-voted players take one penalty per vote.
class VoteRound {
  VoteRound(List<String> players) : players = List.unmodifiable(players);

  final List<String> players;
  final Map<String, String> _votes = {};

  int get votesCast => _votes.length;
  bool get complete => _votes.length == players.length;

  /// Next player who still needs to vote, in seat order.
  String? get nextVoter {
    for (final p in players) {
      if (!_votes.containsKey(p)) return p;
    }
    return null;
  }

  void cast(String voter, String target) {
    if (!players.contains(voter) || !players.contains(target)) {
      throw ArgumentError('Unknown player');
    }
    if (_votes.containsKey(voter)) throw StateError('$voter already voted');
    _votes[voter] = target;
  }

  Map<String, int> get tally {
    final t = {for (final p in players) p: 0};
    for (final v in _votes.values) {
      t[v] = t[v]! + 1;
    }
    return t;
  }

  /// Players with the most votes (several on a tie).
  List<String> get winners {
    final t = tally;
    final top = t.values.fold(0, (a, b) => a > b ? a : b);
    if (top == 0) return const [];
    return [for (final e in t.entries) if (e.value == top) e.key];
  }
}
