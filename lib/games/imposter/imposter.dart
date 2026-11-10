import 'dart:math';

/// Secret words by category. The imposter can be shown the category as a hint.
const Map<String, List<String>> imposterWords = {
  'Places': [
    'Beach', 'Airport', 'Hospital', 'Library', 'Zoo', 'Movie theater', 'Gym', 'Supermarket',
    'Museum', 'Campsite', 'Bowling alley', 'Theme park', 'Train station', 'Farm', 'Space station',
  ],
  'Food': [
    'Pizza', 'Sushi', 'Tacos', 'Pancakes', 'Ice cream', 'Spaghetti', 'Burger', 'Popcorn',
    'Birthday cake', 'Salad', 'Hot dog', 'Curry', 'Donut', 'Cereal', 'Nachos',
  ],
  'Animals': [
    'Penguin', 'Giraffe', 'Shark', 'Kangaroo', 'Owl', 'Octopus', 'Panda', 'Camel',
    'Flamingo', 'Snake', 'Dolphin', 'Sloth', 'Elephant', 'Bee', 'Crocodile',
  ],
  'Jobs': [
    'Teacher', 'Firefighter', 'Chef', 'Pilot', 'Dentist', 'Astronaut', 'Plumber', 'Lifeguard',
    'Magician', 'Farmer', 'Photographer', 'Detective', 'Barber', 'Mail carrier', 'DJ',
  ],
  'Things at home': [
    'Toothbrush', 'Couch', 'Microwave', 'Pillow', 'Remote control', 'Mirror', 'Vacuum',
    'Fridge', 'Doorbell', 'Bathtub', 'Laundry basket', 'Toaster', 'Lamp', 'Bookshelf', 'Rug',
  ],
  'Sports & games': [
    'Soccer', 'Chess', 'Bowling', 'Surfing', 'Basketball', 'Golf', 'Skiing', 'Tennis',
    'Hide and seek', 'Karate', 'Boxing', 'Skateboarding', 'Volleyball', 'Darts', 'Poker',
  ],
  'Events': [
    'Wedding', 'Birthday party', 'Job interview', 'First date', 'Graduation', 'Road trip',
    'Concert', 'Sleepover', 'Camping trip', 'Halloween', 'Picnic', 'Garage sale', 'Prom',
    'Family reunion', 'Talent show',
  ],
};

/// One round: everyone but the imposters sees the same secret word.
class ImposterRound {
  ImposterRound({
    required this.playerCount,
    this.imposterCount = 1,
    String? category,
    Random? random,
  }) : assert(imposterCount >= 1 && imposterCount < playerCount) {
    final r = random ?? Random();
    final cats = imposterWords.keys.toList();
    this.category = category ?? cats[r.nextInt(cats.length)];
    final words = imposterWords[this.category]!;
    word = words[r.nextInt(words.length)];
    imposters = (List.generate(playerCount, (i) => i)..shuffle(r)).take(imposterCount).toSet();
    // The imposter never has to speak first: that would give them no clues.
    final safe = [for (var i = 0; i < playerCount; i++) if (!imposters.contains(i)) i];
    starter = safe[r.nextInt(safe.length)];
  }

  final int playerCount;
  final int imposterCount;
  late final String category;
  late final String word;
  late final Set<int> imposters;

  /// Seat that gives the first clue.
  late final int starter;

  bool isImposter(int seat) => imposters.contains(seat);
}
