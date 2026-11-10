import 'package:flutter/widgets.dart';

import '../widgets/sprites.dart';
import 'charades/charades_screen.dart';
import 'dial/dial_screen.dart';
import 'fishbowl/fishbowl_screen.dart';
import 'hot_potato/hot_potato_screen.dart';
import 'ride_the_bus/ride_the_bus_screen.dart';
import 'horse_racing/horse_racing_screen.dart';
import 'imposter/imposter_screen.dart';
import 'kings_cup/kings_cup_screen.dart';
import 'mafia/mafia_screen.dart';
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
    required this.builder,
  });

  final String id;
  final String title;
  final String tagline;
  final Sprite icon;
  final WidgetBuilder builder;
}

final List<GameMode> gameModes = [
  GameMode(
    id: 'kings_cup',
    title: 'Four Kings',
    tagline: 'Draw a card, obey the rule. Fourth king takes the pot.',
    icon: Sprites.crown,
    builder: (_) => const KingsCupScreen(),
  ),
  GameMode(
    id: 'one_of_a_kind',
    title: 'One of a Kind',
    tagline: 'Answer in 15s. Match anyone and you are out.',
    icon: Sprites.question,
    builder: (_) => const UniqueAnswerScreen(),
  ),
  GameMode(
    id: 'charades',
    title: 'Charades',
    tagline: 'Phone on your forehead. Tilt down if you got it.',
    icon: Sprites.mask,
    builder: (_) => const CharadesScreen(),
  ),
  GameMode(
    id: 'imposter',
    title: 'Imposter',
    tagline: 'Everyone knows the word but one. Find the faker.',
    icon: Sprites.spy,
    builder: (_) => const ImposterScreen(),
  ),
  GameMode(
    id: 'fishbowl',
    title: 'Fishbowl',
    tagline: 'Fill a bowl with slips. Describe, one word, then act.',
    icon: Sprites.fishbowl,
    builder: (_) => const FishbowlScreen(),
  ),
  GameMode(
    id: 'dial',
    title: 'Dial It In',
    tagline: 'One clue, one hidden target. Can your team read your mind?',
    icon: Sprites.dial,
    builder: (_) => const DialScreen(),
  ),
  GameMode(
    id: 'mafia',
    title: 'Mafia',
    tagline: 'Secret roles, deadly nights, no narrator needed. 5+ players.',
    icon: Sprites.moon,
    builder: (_) => const MafiaScreen(),
  ),
  GameMode(
    id: 'paranoia',
    title: 'Paranoia',
    tagline: 'A secret question, a name said out loud.',
    icon: Sprites.eye,
    builder: (_) => const ParanoiaScreen(),
  ),
  GameMode(
    id: 'horse_racing',
    title: 'Horse Racing',
    tagline: 'Bet penalties and dares on a suit. Watch the aces race.',
    icon: Sprites.horse,
    builder: (_) => const HorseRacingScreen(),
  ),
  GameMode(
    id: 'ride_the_bus',
    title: 'Ride the Bus',
    tagline: 'Four right in a row to get off. Miss and start over.',
    icon: Sprites.bus,
    builder: (_) => const RideTheBusScreen(),
  ),
  GameMode(
    id: 'hot_potato',
    title: 'Hot Potato Bomb',
    tagline: 'Name one, pass it on. Hidden fuse. Boom.',
    icon: Sprites.bomb,
    builder: (_) => const HotPotatoScreen(),
  ),
];
