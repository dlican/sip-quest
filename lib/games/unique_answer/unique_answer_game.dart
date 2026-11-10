/// Rules for "One of a Kind":
/// The host reads a prompt. Everyone else secretly writes an answer within the
/// time limit, then all reveal. Anyone whose answer matches another player's is
/// out (and takes a penalty). With two players left, they are also out if they match
/// the host's own answer. Last one standing wins.
class UniqueAnswerGame {
  UniqueAnswerGame({required this.host, required List<String> contestants})
      : alive = List.of(contestants);

  final String host;
  final List<String> alive;
  final List<String> out = [];
  int round = 1;

  bool get finalTwo => alive.length == 2;
  bool get isOver => alive.length <= 1;
  String? get winner => alive.length == 1 ? alive.first : null;

  /// Removes the players whose answers matched. Returns false (and changes
  /// nothing) if that would knock out everyone still standing; in that case
  /// the round is replayed.
  bool eliminate(Set<String> matched) {
    final hits = matched.where(alive.contains).toSet();
    if (hits.length >= alive.length) {
      round++;
      return false;
    }
    alive.removeWhere(hits.contains);
    out.addAll(hits);
    round++;
    return true;
  }
}
