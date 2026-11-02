import 'dart:math';

class RouletteSlice {
  const RouletteSlice(this.title, this.description);
  final String title;
  final String description;
}

const rouletteSlices = [
  RouletteSlice('Take 2', 'Take two sips.'),
  RouletteSlice('Give 3', 'Hand out three sips however you like.'),
  RouletteSlice('Social', 'Everybody drinks!'),
  RouletteSlice('Waterfall', 'Everyone drinks; you stop first, then each person in turn.'),
  RouletteSlice('Swap Seats', 'Swap seats with the person across from you.'),
  RouletteSlice('Accent', 'Talk in an accent until your next turn. Slip up, drink.'),
  RouletteSlice('Safe', 'Nothing happens. Lucky you.'),
  RouletteSlice('Left Drinks', 'The person on your left drinks twice.'),
  RouletteSlice('Thumb Master', 'Whenever you put your thumb on the table, last to copy drinks.'),
  RouletteSlice('Finish It', 'Finish your drink. Or take 5 if it is full.'),
];

/// Picks a slice and the wheel angle that lands on it.
class RouletteSpin {
  RouletteSpin(this.index, this.turns);
  final int index;

  /// Total rotation in full turns (fractional), ending centred on [index]
  /// under a pointer at the top.
  final double turns;
}

class Roulette {
  Roulette({this.slices = rouletteSlices, Random? random}) : _random = random ?? Random();
  final List<RouletteSlice> slices;
  final Random _random;
  double _rest = 0; // current resting rotation in turns (0..1)

  double get rest => _rest;

  RouletteSpin spin() {
    final i = _random.nextInt(slices.length);
    final per = 1 / slices.length;
    // Slice i spans [i*per, (i+1)*per) clockwise from the top. Rotating the
    // wheel by r turns brings angle (1 - r) under the top pointer.
    final target = 1 - (i + 0.5) * per;
    var delta = (target - _rest) % 1.0;
    final turns = _rest + delta + 4 + _random.nextInt(3); // 4 to 6 extra turns
    _rest = turns % 1.0;
    return RouletteSpin(i, turns);
  }

  /// Which slice sits under the pointer when the wheel rests at [turns].
  int sliceAt(double turns) {
    final a = (1 - (turns % 1.0)) % 1.0;
    return (a * slices.length).floor() % slices.length;
  }
}
