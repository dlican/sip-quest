import 'dart:math';

const hotPotatoCategories = [
  'Pizza toppings', 'Car brands', 'Things in a kitchen', 'Disney movies', 'Dog breeds',
  'Soda brands', 'Breakfast foods', 'Countries in Europe', 'Fast food chains', 'Sports teams',
  'Things at the beach', 'Board games', 'Breakfast cereals', 'Superheroes', 'Fruits',
  'Clothing brands', 'Things you find in a bathroom', 'Video game characters', 'Pop stars',
  'Words that rhyme with "cat"', 'Things that are yellow', 'Body parts', 'Apps on your phone',
  'Ice cream flavors', 'Things in a classroom', 'Cartoon characters', 'Card games',
  'Musical instruments', 'Things that fly', 'Reality TV shows', 'Types of shoes',
  'Things you do at a party', 'Words ending in "-ing"', 'Celebrities with one name',
  'Kinds of cheese', 'US states', 'Capital cities', 'Things with wheels', 'Candy bars',
  'Pokemon', 'Things in space', 'Sandwich fillings', 'Halloween costumes', 'Spicy foods',
];

/// A round of Hot Potato Bomb. The fuse length is hidden from players.
class BombRound {
  BombRound({this.minSeconds = 10, this.maxSeconds = 45, Random? random})
      : assert(maxSeconds >= minSeconds) {
    final r = random ?? Random();
    fuse = Duration(
        milliseconds: (minSeconds * 1000) + r.nextInt((maxSeconds - minSeconds) * 1000 + 1));
  }

  final int minSeconds;
  final int maxSeconds;
  late final Duration fuse;
  int passes = 0;

  bool exploded(Duration elapsed) => elapsed >= fuse;

  /// 0 when lit, 1 at the boom. Used to speed up the ticking.
  double heat(Duration elapsed) =>
      (elapsed.inMilliseconds / fuse.inMilliseconds).clamp(0.0, 1.0);

  /// Interval between ticks: slow at first, frantic near the end.
  Duration tickInterval(Duration elapsed) =>
      Duration(milliseconds: (900 - 780 * heat(elapsed)).round());
}
