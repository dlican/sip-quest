import 'dart:math';

/// Two ends of a scale. The clue giver names something that sits at the
/// hidden target between them.
class Spectrum {
  const Spectrum(this.left, this.right);
  final String left;
  final String right;
}

const spectrums = [
  Spectrum('Cold', 'Hot'),
  Spectrum('Underrated', 'Overrated'),
  Spectrum('Boring', 'Exciting'),
  Spectrum('Cheap', 'Expensive'),
  Spectrum('Tiny', 'Huge'),
  Spectrum('Useless', 'Useful'),
  Spectrum('Scary', 'Cute'),
  Spectrum('Easy to spell', 'Hard to spell'),
  Spectrum('Bad smell', 'Good smell'),
  Spectrum('Healthy', 'Unhealthy'),
  Spectrum('Old-fashioned', 'Futuristic'),
  Spectrum('Quiet', 'Loud'),
  Spectrum('Soft', 'Hard'),
  Spectrum('Rare', 'Common'),
  Spectrum('Bad movie', 'Great movie'),
  Spectrum('Villain', 'Hero'),
  Spectrum('Normal pet', 'Weird pet'),
  Spectrum('Bad superpower', 'Great superpower'),
  Spectrum('Breakfast food', 'Dinner food'),
  Spectrum('Easy job', 'Hard job'),
  Spectrum('Slow', 'Fast'),
  Spectrum('Forgettable', 'Iconic'),
  Spectrum('Indoor', 'Outdoor'),
  Spectrum('Smells bad', 'Smells amazing'),
  Spectrum('For kids', 'For adults'),
  Spectrum('Unpopular opinion', 'Popular opinion'),
  Spectrum('Mildly annoying', 'Infuriating'),
  Spectrum('Fake', 'Real'),
  Spectrum('Dangerous', 'Safe'),
  Spectrum('Bad gift', 'Great gift'),
  Spectrum('Sad song', 'Happy song'),
  Spectrum('Low effort', 'High effort'),
  Spectrum('Lazy Sunday', 'Busy Monday'),
  Spectrum('Bad first date', 'Great first date'),
  Spectrum('Unhinged', 'Totally normal'),
  Spectrum('Dog person thing', 'Cat person thing'),
  Spectrum('Easy to draw', 'Hard to draw'),
  Spectrum('Worst season', 'Best season'),
  Spectrum('Flavorless', 'Flavorful'),
  Spectrum('Nerdy', 'Cool'),
];

/// A hidden target on a 0..100 dial. Guesses score by how close they land.
class DialRound {
  DialRound({required this.spectrum, Random? random})
      : target = 8 + (random ?? Random()).nextInt(85);

  final Spectrum spectrum;

  /// Kept away from the very edges so every band fits on the dial.
  final int target;

  /// Half-widths of the scoring bands, inner to outer.
  static const bands = [4, 10, 16];

  /// 4 for a bullseye, then 3 and 2, else 0.
  int score(double guess) {
    final d = (guess - target).abs();
    for (var i = 0; i < bands.length; i++) {
      if (d <= bands[i]) return 4 - i;
    }
    return 0;
  }
}
