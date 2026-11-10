import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/palette.dart';
import '../widgets/demos.dart';
import '../widgets/motion.dart';
import '../widgets/pixel_ui.dart';
import 'registry.dart';

/// How a game is played: an animated pixel demo plus a few short steps.
class HowTo {
  const HowTo({required this.demo, required this.steps, required this.penalty, this.period = const Duration(seconds: 4)});
  final DemoBuilder demo;
  final Duration period;
  final List<String> steps;

  /// The penalty rule in one line.
  final String penalty;
}

const Map<String, HowTo> howToPlay = {
  'kings_cup': HowTo(
    demo: kingsCupDemo,
    period: Duration(milliseconds: 3600),
    steps: [
      'Put the phone in the middle of the table.',
      'Take turns tapping to draw a card. Each card has a rule.',
      'Every King: the drawer adds a penalty to the pot.',
      'Tap the book icon to change any card rule for your table.',
    ],
    penalty: 'Whoever draws the 4th King takes the whole pot.',
  ),
  'one_of_a_kind': HowTo(
    demo: oneOfAKindDemo,
    steps: [
      'The host holds the phone and reads the prompt out loud.',
      'Everyone else writes an answer (paper or their own notes) before the timer ends.',
      'Reveal together. Anyone who matched someone else is out.',
      'Last two standing must also dodge the host\'s answer.',
    ],
    penalty: 'Knocked out? Take a penalty. Winner hands out penalties.',
  ),
  'charades': HowTo(
    demo: charadesDemo,
    period: Duration(milliseconds: 4600),
    steps: [
      'Pick decks, tap Start, then hold the phone sideways on your forehead, screen facing out.',
      'Friends shout clues. No saying the word itself!',
      'Got it? Tilt the phone down. Want to pass? Tilt it up.',
      'You have 30 seconds. Then hand the phone to the next player.',
    ],
    penalty: 'One penalty per pass. Get 5+ and hand out that many penalties.',
  ),
  'imposter': HowTo(
    demo: imposterDemo,
    period: Duration(milliseconds: 4400),
    steps: [
      'Pass the phone around. Everyone sees the same secret word, except the imposter.',
      'Go around the table twice. Each person says one word linked to the secret.',
      'Then point at who you think is faking it on 3. Reveal on the phone.',
      'A caught imposter still wins if they can guess the word.',
    ],
    penalty: 'Imposter wins: everyone else takes a penalty. Caught: the imposter does.',
  ),
  'dial': HowTo(
    demo: dialDemo,
    period: Duration(milliseconds: 4200),
    steps: [
      'The clue giver secretly sees a target on a scale, like Cold to Hot.',
      'They say one thing that sits right at the target ("soup", "a sauna").',
      'Everyone else talks it over and drags the needle where they think it is.',
      'Lock it in: 4 points for a bullseye, then 3 and 2 for close calls.',
    ],
    penalty: 'Miss completely: the guessers take a penalty. Bullseye: the clue giver hands one out.',
  ),
  'mafia': HowTo(
    demo: mafiaDemo,
    period: Duration(milliseconds: 4400),
    steps: [
      'Needs 5+ names. Pass the phone so everyone sees their secret role.',
      'At night the phone goes around again. Everyone taps a name, so nobody can tell who has a power.',
      'Mafia pick a target, the Doctor saves someone, the Detective checks someone.',
      'By day, discuss and vote someone out. Repeat until one side wins.',
    ],
    penalty: 'Town catches every Mafia: the Mafia take a penalty. Mafia match the town: everyone else does.',
  ),
  'fishbowl': HowTo(
    demo: fishbowlDemo,
    period: Duration(milliseconds: 4800),
    steps: [
      'Pass the phone around. Everyone secretly adds a few slips: people, movies, phrases.',
      'Two teams take turns. The clue giver gets a timer and pulls slips; only their team guesses.',
      'Round 1: describe it. Round 2: one word only. Round 3: act it out.',
      'Same slips every round, so remember them! The bowl refills each round.',
    ],
    penalty: 'Most slips after three rounds wins. The losing team takes a penalty.',
  ),
  'paranoia': HowTo(
    demo: paranoiaDemo,
    steps: [
      'Pass the phone to the person on your left.',
      'They read the question in secret, then say a name out loud.',
      'The named person can take a penalty to hear the question, or flip a coin.',
      'Heads, the question is read out. Tails, it stays a secret.',
    ],
    penalty: 'A penalty is the price of knowing.',
  ),
  'horse_racing': HowTo(
    demo: horseRacingDemo,
    period: Duration(milliseconds: 3400),
    steps: [
      'Everyone picks a suit and bets penalties and dares on it.',
      'Turn the phone sideways. Each card drawn moves that suit\'s ace forward.',
      'Once every horse passes a sideways setback card, it flips and that suit moves back.',
    ],
    penalty: 'Winners hand out double their bet. Everyone else takes theirs.',
  ),
  'ride_the_bus': HowTo(
    demo: rideTheBusDemo,
    steps: [
      'Guess four cards in a row: red or black, higher or lower, inside or outside, then the suit.',
      'Miss any guess and you start over from the first card.',
      'Pass the phone to the next rider when you get off.',
    ],
    penalty: 'Every wrong guess is a penalty.',
  ),
  'hot_potato': HowTo(
    demo: hotPotatoDemo,
    period: Duration(milliseconds: 3200),
    steps: [
      'Light the fuse. A category appears.',
      'Name something in it, then pass the phone to your left.',
      'The ticking speeds up. Nobody knows when it blows.',
    ],
    penalty: 'Holding the phone when it explodes? Penalty.',
  ),
};

Future<void> showHowToPlay(BuildContext context, String gameId) {
  final game = gameModes.firstWhere((g) => g.id == gameId);
  return showPixelSheet(
    context: context,
    builder: (_) => HowToSheet(game: game),
  );
}

class HowToSheet extends StatelessWidget {
  const HowToSheet({super.key, required this.game});
  final GameMode game;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final how = howToPlay[game.id]!;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH, maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: pal.panel,
            border: Border(top: BorderSide(color: pal.border, width: 4)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 48, height: 6, color: pal.border)),
                  const SizedBox(height: 14),
                  Text('HOW TO PLAY', style: PixelFonts.title(pal.textDim, size: 10)),
                  const SizedBox(height: 6),
                  Text(game.title.toUpperCase(), style: PixelFonts.title(pal.accent, size: 16)),
                  const SizedBox(height: 14),
                  DemoStage(period: how.period, builder: how.demo),
                  const SizedBox(height: 14),
                  for (var i = 0; i < how.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(right: 10, top: 2),
                            alignment: Alignment.center,
                            color: pal.secondary,
                            child: Text('${i + 1}', style: PixelFonts.title(pal.bg, size: 10)),
                          ),
                          Expanded(child: Text(how.steps[i], style: PixelFonts.body(pal.text, size: 23))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  PixelBox(
                    color: pal.bg,
                    borderColor: pal.primary,
                    padding: const EdgeInsets.all(10),
                    shadow: false,
                    child: Text(how.penalty, style: PixelFonts.body(pal.primary, size: 23)),
                  ),
                  const SizedBox(height: 16),
                  PixelButton(label: 'Got it', expand: true, onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
