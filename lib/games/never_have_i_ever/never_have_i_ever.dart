enum NhieLevel { mild, spicy }

const Map<NhieLevel, List<String>> nhiePrompts = {
  NhieLevel.mild: [
    'Never have I ever fallen asleep in a movie theater.',
    'Never have I ever pretended to be sick to skip work or school.',
    'Never have I ever sung in the shower.',
    'Never have I ever broken a bone.',
    'Never have I ever been on TV.',
    'Never have I ever lied about my age.',
    'Never have I ever cheated at a board game.',
    'Never have I ever eaten food that fell on the floor.',
    'Never have I ever gotten lost in a foreign country.',
    'Never have I ever forgotten someone\'s name right after meeting them.',
    'Never have I ever ghosted a group chat.',
    'Never have I ever binge-watched a whole season in one day.',
    'Never have I ever been stuck in an elevator.',
    'Never have I ever laughed so hard I cried.',
    'Never have I ever walked into a glass door.',
    'Never have I ever regifted a present.',
    'Never have I ever stalked someone on social media.',
    'Never have I ever missed a flight.',
    'Never have I ever dyed my hair a crazy color.',
    'Never have I ever been to a music festival.',
    'Never have I ever cried at a movie.',
    'Never have I ever lost my phone on a night out.',
    'Never have I ever sent a text to the wrong person.',
    'Never have I ever pulled an all-nighter.',
    'Never have I ever had a crush on a teacher.',
  ],
  NhieLevel.spicy: [
    'Never have I ever kissed someone in this room.',
    'Never have I ever drunk-texted an ex.',
    'Never have I ever been kicked out of a bar.',
    'Never have I ever lied to get out of a date.',
    'Never have I ever had a one night stand.',
    'Never have I ever skinny dipped.',
    'Never have I ever slid into someone\'s DMs.',
    'Never have I ever woken up not knowing where I was.',
    'Never have I ever been caught sneaking out.',
    'Never have I ever dated two people at once.',
    'Never have I ever used a fake ID.',
    'Never have I ever kissed a stranger.',
    'Never have I ever had a crush on a friend\'s partner.',
    'Never have I ever thrown up in a cab.',
    'Never have I ever lied in this game.',
    'Never have I ever been on a dating app date.',
    'Never have I ever made out in a public place.',
    'Never have I ever forgotten a whole night out.',
    'Never have I ever called in sick with a hangover.',
    'Never have I ever had a secret relationship.',
  ],
};

/// Fingers-down tracker. Everyone starts with [fingers]. Putting one down
/// means you've done it (and you drink). Zero fingers and you're out.
class NhieTracker {
  NhieTracker(List<String> players, {this.fingers = 5})
      : _left = {for (final p in players) p: fingers};

  final int fingers;
  final Map<String, int> _left;

  int fingersOf(String p) => _left[p] ?? 0;
  List<String> get players => _left.keys.toList();
  List<String> get standing => [for (final e in _left.entries) if (e.value > 0) e.key];
  bool get isOver => _left.length > 1 && standing.length <= 1;

  void fingerDown(String p) {
    final n = _left[p];
    if (n == null || n == 0) return;
    _left[p] = n - 1;
  }

  void undo(String p) {
    final n = _left[p];
    if (n == null || n >= fingers) return;
    _left[p] = n + 1;
  }
}
