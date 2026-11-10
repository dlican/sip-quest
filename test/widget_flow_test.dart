import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/app_state.dart';
import 'package:sip_quest/games/registry.dart';
import 'package:sip_quest/main.dart';
import 'package:sip_quest/theme/palette.dart';
import 'package:sip_quest/widgets/pixel_ui.dart';

const players = ['Deez', 'Sam', 'Alex', 'Jo'];

Future<void> pumpApp(
  WidgetTester tester, {
  String? open,
  List<String> names = players,
  SipPalette? style,
  Size size = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final state = AppState();
  if (style != null) state.setPalette(style);
  for (final n in names) {
    state.addPlayer(n);
  }
  await tester.pumpWidget(PartyPartyApp(state: state, open: open));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  // Start, finish, then unmount any outgoing phase transition.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump();
}

/// Unmount so periodic timers are cancelled before the test ends.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('home lists every game and cycles styles', (tester) async {
    await pumpApp(tester);
    expect(find.text('PARTY PARTY'), findsOneWidget);
    for (final g in gameModes) {
      await tester.scrollUntilVisible(find.text(g.title.toUpperCase()), 200);
      expect(find.text(g.title.toUpperCase()), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('STYLE: NEON ARCADE'), -300);
    await tapText(tester, 'STYLE: NEON ARCADE');
    expect(find.text('STYLE: PIXEL TAVERN'), findsOneWidget);
  });

  for (final g in gameModes) {
    for (final style in SipPalette.all) {
      testWidgets('${g.title} opens cleanly in ${style.name}', (tester) async {
        await pumpApp(tester, open: g.id, style: style);
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
        expect(find.text(g.title.toUpperCase()), findsWidgets);
        await unmount(tester);
      });
    }
  }

  // Small Android phone (about 360 x 640 dp) with 6 long-ish names.
  for (final g in gameModes) {
    testWidgets('${g.title} fits a small phone', (tester) async {
      await pumpApp(
        tester,
        open: g.id,
        size: const Size(990, 1760),
        names: [
          'Alexandra',
          'Benjamin',
          'Christopher',
          'Danielle',
          'Elizabeth',
          'Fitz',
        ],
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('players screen adds and removes names', (tester) async {
    await pumpApp(tester, names: []);
    await tapText(tester, 'NAMES (OPTIONAL)');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Priya');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Priya'), findsOneWidget);
    await tester.tap(find.text('X'));
    await tester.pump();
    expect(find.text('Priya'), findsNothing);
  });

  testWidgets("Four Kings: shuffle, draw, rule shown, turns rotate", (
    tester,
  ) async {
    await pumpApp(tester, open: 'kings_cup');
    expect(find.text('SHUFFLING...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tapText(tester, 'DRAW FIRST CARD');
    expect(find.text('51'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget); // up next
    for (var i = 0; i < 5; i++) {
      await tapText(tester, 'DRAW');
    }
    expect(find.text('46'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets("Four Kings: rules editor opens", (tester) async {
    await pumpApp(tester, open: 'kings_cup');
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pumpAndSettle();
    expect(find.text('CLAP CHAIN'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('One of a Kind: timer runs out, reveal, knock out, next round', (
    tester,
  ) async {
    // Earlier tests cached the asset future inside their own fake-async zone.
    rootBundle.clear();
    await pumpApp(tester, open: 'one_of_a_kind');
    // The prompt bank loads from assets asynchronously.
    for (var i = 0; i < 50 && find.text('HOST').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.scrollUntilVisible(find.text('START'), 300);
    await tapText(tester, 'START');
    expect(find.text('ROUND 1'), findsOneWidget);
    await tapText(tester, 'GO! 15S');
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('REVEAL!'), findsOneWidget);
    await tapText(tester, 'Sam');
    await tapText(tester, 'KNOCK OUT 1');
    expect(find.text('ROUND 2'), findsOneWidget);
    expect(find.textContaining('Sam is out'), findsOneWidget);
    expect(find.textContaining('FINAL TWO'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Charades: heads-up round with tap fallback ends with a summary', (tester) async {
    await pumpApp(tester, open: 'charades');
    await tapText(tester, 'START');
    expect(find.text('PHONE ON YOUR FOREHEAD'), findsOneWidget);
    await tester.tap(find.byKey(const Key('charades-place')));
    await tester.pump(const Duration(seconds: 4)); // 3-2-1
    await tester.tap(find.byKey(const Key('charades-got')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('charades-pass')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('GOT 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("TIME'S UP!"), findsOneWidget);
    expect(find.text('Deez got 1'), findsOneWidget);
    expect(find.text('Deez takes 1 for passing.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Paranoia: pass, answer, coin flip', (tester) async {
    await pumpApp(tester, open: 'paranoia');
    await tapText(tester, 'SHOW ME');
    await tapText(tester, 'Sam');
    expect(find.text('THE ANSWER WAS'), findsOneWidget);
    await tapText(tester, 'FLIP THE COIN');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('NEXT ROUND'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Horse Racing: auto race reaches results', (tester) async {
    await pumpApp(tester, open: 'horse_racing');
    await tapText(tester, 'START RACE');
    await tapText(tester, 'AUTO');
    await tester.pump(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('NEW RACE'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'Horse Racing: bets take penalties and dares, race lays out in landscape',
    (tester) async {
      await pumpApp(tester, open: 'horse_racing');
      expect(find.text('2 penalties'), findsNWidgets(players.length));
      await tester.tap(find.text('+').at(1)); // first player's dares
      await tester.pump();
      expect(find.text('1 dare'), findsOneWidget);
      await tapText(tester, 'START RACE');
      // Phone turned sideways.
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('FLIP CARD'), findsOneWidget);
      await tapText(tester, 'AUTO');
      await tester.pump(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('NEW RACE'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('Ride the Bus: guesses advance or reset', (tester) async {
    await pumpApp(tester, open: 'ride_the_bus');
    await tapText(tester, 'RED');
    expect(find.textContaining(RegExp(r'NICE|WRONG')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Hot Potato: bomb always explodes within 45s', (tester) async {
    await pumpApp(tester, open: 'hot_potato');
    await tapText(tester, 'LIGHT IT');
    await tapText(tester, 'PASSED (0)');
    expect(find.text('PASSED (1)'), findsOneWidget);
    for (var i = 0; i < 50 && find.text('BOOM!').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('BOOM!'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Fishbowl: named players fill the bowl and play a turn', (tester) async {
    await pumpApp(tester, open: 'fishbowl');
    expect(find.text('Team A: Deez, Alex'), findsOneWidget);
    await tapText(tester, 'FILL THE BOWL');
    for (final p in players) {
      expect(find.text('${p.toUpperCase()}, ADD 3 MORE'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byKey(const Key('fishbowl-slip')), '$p slip $i');
        await tapText(tester, '+');
      }
      if (p != players.last) await tapText(tester, "I'M ${players[players.indexOf(p) + 1].toUpperCase()}");
    }
    expect(find.text('ROUND 1 OF 3'), findsOneWidget);
    expect(find.text('Deez gives clues. Only your team guesses.'), findsOneWidget);
    await tapText(tester, 'START TURN');
    await tester.tap(find.byKey(const Key('fishbowl-got')));
    await tester.pump();
    expect(find.text('GOT 1 · 11 LEFT'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fishbowl-skip')));
    await tester.pump(const Duration(seconds: 46));
    expect(find.text("TIME'S UP!"), findsOneWidget);
    await tapText(tester, 'PASS TO TEAM B');
    expect(find.text('Sam gives clues. Only your team guesses.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Fishbowl: no names, random slips, clear all three rounds', (tester) async {
    await pumpApp(tester, open: 'fishbowl', names: []);
    await tapText(tester, 'FILL THE BOWL');
    await tapText(tester, 'ADD 5 RANDOM SLIPS');
    await tapText(tester, 'DONE, START GAME');
    for (var round = 1; round <= 3; round++) {
      if (round == 1) await tapText(tester, 'START TURN');
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('fishbowl-got')));
        await tester.pump();
      }
      if (round < 3) {
        expect(find.text('BOWL EMPTY!'), findsOneWidget);
        await tapText(tester, 'KEEP GOING');
      }
    }
    expect(find.text('TEAM A WINS!'), findsOneWidget);
    expect(find.text('Team B takes a penalty.'), findsOneWidget);
    await tapText(tester, 'PLAY AGAIN, SAME SLIPS');
    expect(find.text('ROUND 1 OF 3'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Imposter: deal to everyone, discuss, reveal', (tester) async {
    await pumpApp(tester, open: 'imposter');
    await tapText(tester, 'DEAL THE CARDS');
    var imposters = 0;
    for (var i = 0; i < players.length; i++) {
      expect(find.text(players[i].toUpperCase()), findsOneWidget);
      await tapText(tester, 'SHOW ME');
      imposters += find.byKey(const Key('imposter-you')).evaluate().length;
      expect(find.byKey(const Key('imposter-word')).evaluate().length + find.byKey(const Key('imposter-you')).evaluate().length, 1);
      await tapText(tester, i == players.length - 1 ? 'HIDE, START CLUES' : 'HIDE AND PASS');
    }
    expect(imposters, 1);
    expect(find.textContaining('STARTS'), findsOneWidget);
    await tapText(tester, 'REVEAL THE IMPOSTER');
    expect(find.text('THE IMPOSTER WAS'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Imposter: no names uses a player count', (tester) async {
    await pumpApp(tester, open: 'imposter', names: []);
    await tapText(tester, '-');
    await tapText(tester, 'DEAL THE CARDS');
    expect(find.text('PLAYER 1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Dial It In: clue, drag, lock in, score', (tester) async {
    await pumpApp(tester, open: 'dial');
    expect(find.text('DEEZ'), findsOneWidget);
    await tapText(tester, 'SHOW ME');
    expect(find.text('THE TARGET IS HERE'), findsOneWidget);
    await tapText(tester, 'HIDE IT, TEAM GUESSES');
    await tester.drag(find.byKey(const Key('dial-bar')), const Offset(-60, 0));
    await tester.pump();
    await tapText(tester, 'LOCK IT IN');
    expect(find.textContaining(RegExp(r'BULLSEYE|CLOSE|MISSED')), findsOneWidget);
    expect(find.textContaining('Team score:'), findsOneWidget);
    await tapText(tester, 'NEXT CLUE GIVER');
    expect(find.text('SAM'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Mafia: asks for names with fewer than five', (tester) async {
    await pumpApp(tester, open: 'mafia');
    expect(find.text('MAFIA NEEDS 5+ NAMES'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Mafia: roles, a full night, then the vote', (tester) async {
    const five = ['Deez', 'Sam', 'Alex', 'Jo', 'Priya'];
    await pumpApp(tester, open: 'mafia', names: five);
    await tapText(tester, 'DEAL ROLES');
    for (var i = 0; i < five.length; i++) {
      await tapText(tester, 'SHOW ME');
      expect(find.byKey(const Key('mafia-role')), findsOneWidget);
      await tapText(tester, i == five.length - 1 ? 'HIDE, NIGHT FALLS' : 'HIDE AND PASS');
    }
    for (var i = 0; i < five.length; i++) {
      expect(find.text(five[i].toUpperCase()), findsOneWidget);
      await tapText(tester, 'SHOW ME');
      expect(find.text('NIGHT 1'), findsOneWidget);
      await tester.tap(find.byType(PixelChip).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.text('MORNING'), findsOneWidget);
    await tapText(tester, 'DISCUSS AND VOTE');
    await tapText(tester, 'NO ONE, SKIP THE VOTE');
    expect(find.text('PASS THE PHONE TO'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Paranoia: plays with no names', (tester) async {
    await pumpApp(tester, open: 'paranoia', names: []);
    expect(find.textContaining('ON YOUR LEFT'), findsOneWidget);
    await tapText(tester, 'SHOW ME');
    await tapText(tester, 'I SAID A NAME');
    expect(find.text('WHOEVER WAS NAMED'), findsOneWidget);
    await tapText(tester, 'TAKE A PENALTY TO FIND OUT');
    expect(find.text('THE QUESTION WAS'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('One of a Kind: quick mode with no names', (tester) async {
    rootBundle.clear();
    await pumpApp(tester, open: 'one_of_a_kind', names: []);
    for (var i = 0; i < 50 && find.text('HOST').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.scrollUntilVisible(find.text('START'), 300);
    await tapText(tester, 'START');
    await tapText(tester, 'GO! 15S');
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('REVEAL!'), findsOneWidget);
    await tapText(tester, 'NEXT PROMPT');
    expect(find.text('ROUND 2'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('every game opens with no names', (tester) async {
    for (final g in gameModes) {
      await pumpApp(tester, open: g.id, names: []);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull, reason: g.title);
      await unmount(tester);
    }
  });

  for (final g in gameModes) {
    testWidgets('${g.title}: how-to-play sheet opens from the menu and closes', (tester) async {
      await pumpApp(tester);
      final help = find.byKey(Key('help-${g.id}'));
      await tester.scrollUntilVisible(help, 200);
      await tester.tap(help);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      // Let the demo loop run a full cycle.
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('GOT IT'));
      await tester.tap(find.text('GOT IT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('HOW TO PLAY'), findsNothing);
      await unmount(tester);
    });
  }

  testWidgets('in-game ? opens how to play', (tester) async {
    await pumpApp(tester, open: 'kings_cup');
    await tester.tap(find.byIcon(Icons.question_mark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('settings toggles sound, haptics and volume', (tester) async {
    final state = AppState();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PartyPartyApp(state: state));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Volume'), findsOneWidget);
    await tester.tap(find.text('Sound effects'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.sound, isFalse);
    expect(find.text('Volume'), findsNothing);
    await tester.tap(find.text('Haptics'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.haptics, isFalse);
    await tester.tap(find.text('Sound effects'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('80%'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets("Four Kings: write-a-rule dialog animates open and closed", (tester) async {
    await pumpApp(tester, open: 'kings_cup');
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLAP CHAIN'));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-transition: dialog is on its way in.
    expect(find.text('RULE NAME'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).last, 'Splash');
    await tester.tap(find.text('SAVE').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).last, 'Everyone claps');
    await tester.tap(find.text('SAVE').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SPLASH'), findsOneWidget);
    await unmount(tester);
  });
}
