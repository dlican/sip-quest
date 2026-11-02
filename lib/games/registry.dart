import 'package:flutter/widgets.dart';

import '../widgets/sprites.dart';
import 'beat_the_dealer/beat_the_dealer_screen.dart';
import 'charades/charades_screen.dart';
import 'higher_lower/higher_lower_screen.dart';
import 'hot_potato/hot_potato_screen.dart';
import 'most_likely/most_likely_screen.dart';
import 'never_have_i_ever/never_have_i_ever_screen.dart';
import 'ride_the_bus/ride_the_bus_screen.dart';
import 'roulette/roulette_screen.dart';
import 'truth_or_drink/truth_or_drink_screen.dart';
import 'horse_racing/horse_racing_screen.dart';
import 'kings_cup/kings_cup_screen.dart';
import 'paranoia/paranoia_screen.dart';
import 'unique_answer/unique_answer_screen.dart';

/// One entry per mini-game. To add a game: build its screen under
/// lib/games/NAME/ and add a GameMode here. The home grid picks it up.
class GameMode {
  const GameMode({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.minPlayers,
    required this.builder,
  });

  final String id;
  final String title;
  final String tagline;
  final Sprite icon;
  final int minPlayers;
  final WidgetBuilder builder;
}

final List<GameMode> gameModes = [
  GameMode(
    id: 'kings_cup',
    title: "King's Cup",
    tagline: 'Draw a card, obey the rule. Fourth king drinks the cup.',
    icon: Sprites.crown,
    minPlayers: 0,
    builder: (_) => const KingsCupScreen(),
  ),
  GameMode(
    id: 'one_of_a_kind',
    title: 'One of a Kind',
    tagline: 'Answer in 15s. Match anyone and you are out.',
    icon: Sprites.question,
    minPlayers: 3,
    builder: (_) => const UniqueAnswerScreen(),
  ),
  GameMode(
    id: 'charades',
    title: 'Charades',
    tagline: 'Act it out before the clock runs dry.',
    icon: Sprites.mask,
    minPlayers: 0,
    builder: (_) => const CharadesScreen(),
  ),
  GameMode(
    id: 'paranoia',
    title: 'Paranoia',
    tagline: 'A secret question, a name said out loud.',
    icon: Sprites.eye,
    minPlayers: 3,
    builder: (_) => const ParanoiaScreen(),
  ),
  GameMode(
    id: 'horse_racing',
    title: 'Horse Racing',
    tagline: 'Bet sips on a suit. Watch the aces race.',
    icon: Sprites.horse,
    minPlayers: 0,
    builder: (_) => const HorseRacingScreen(),
  ),
  GameMode(
    id: 'ride_the_bus',
    title: 'Ride the Bus',
    tagline: 'Four right in a row to get off. Miss and start over.',
    icon: Sprites.bus,
    minPlayers: 0,
    builder: (_) => const RideTheBusScreen(),
  ),
  GameMode(
    id: 'hot_potato',
    title: 'Hot Potato Bomb',
    tagline: 'Name one, pass it on. Hidden fuse. Boom.',
    icon: Sprites.bomb,
    minPlayers: 0,
    builder: (_) => const HotPotatoScreen(),
  ),
  GameMode(
    id: 'most_likely',
    title: 'Most Likely To',
    tagline: 'Secret votes. Most votes drinks.',
    icon: Sprites.ballot,
    minPlayers: 3,
    builder: (_) => const MostLikelyScreen(),
  ),
  GameMode(
    id: 'higher_lower',
    title: 'Higher or Lower',
    tagline: 'Build the streak. Break it, drink it.',
    icon: Sprites.arrows,
    minPlayers: 0,
    builder: (_) => const HigherLowerScreen(),
  ),
  GameMode(
    id: 'never_have_i_ever',
    title: 'Never Have I Ever',
    tagline: 'Mild or spicy. Five fingers each.',
    icon: Sprites.hand,
    minPlayers: 0,
    builder: (_) => const NeverHaveIEverScreen(),
  ),
  GameMode(
    id: 'roulette',
    title: 'Pixel Roulette',
    tagline: 'Spin the wheel of fate.',
    icon: Sprites.wheel,
    minPlayers: 0,
    builder: (_) => const RouletteScreen(),
  ),
  GameMode(
    id: 'beat_the_dealer',
    title: 'Beat the Dealer',
    tagline: 'Two guesses to name the card.',
    icon: Sprites.dealer,
    minPlayers: 0,
    builder: (_) => const BeatTheDealerScreen(),
  ),
  GameMode(
    id: 'truth_or_drink',
    title: 'Truth or Drink',
    tagline: 'Answer honestly, or drink.',
    icon: Sprites.lips,
    minPlayers: 0,
    builder: (_) => const TruthOrDrinkScreen(),
  ),
];
