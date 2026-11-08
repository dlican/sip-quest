import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/app_state.dart';
import 'package:sip_quest/games/registry.dart';
import 'package:sip_quest/main.dart';
import 'package:sip_quest/theme/palette.dart';

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
  await tester.pumpWidget(SipQuestApp(state: state, open: open));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await tester.pump(const Duration(milliseconds: 700));
}

/// Unmount so periodic timers are cancelled before the test ends.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('home lists every game and cycles styles', (tester) async {
    await pumpApp(tester);
    expect(find.text('SIP QUEST'), findsOneWidget);
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
    await tapText(tester, 'ADD PLAYERS');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Priya');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Priya'), findsOneWidget);
    await tester.tap(find.text('X'));
    await tester.pump();
    expect(find.text('Priya'), findsNothing);
  });

  testWidgets("King's Cup: shuffle, draw, rule shown, turns rotate", (
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

  testWidgets("King's Cup: rules editor opens", (tester) async {
    await pumpApp(tester, open: 'kings_cup');
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pumpAndSettle();
    expect(find.text('WATERFALL'), findsOneWidget);
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
    expect(find.text('REVEAL!'), findsOneWidget);
    await tapText(tester, 'Sam');
    await tapText(tester, 'KNOCK OUT 1');
    expect(find.text('ROUND 2'), findsOneWidget);
    expect(find.textContaining('Sam is out'), findsOneWidget);
    expect(find.textContaining('FINAL TWO'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Charades: round ends with a summary', (tester) async {
    await pumpApp(tester, open: 'charades');
    await tapText(tester, 'START');
    await tapText(tester, "I'M READY");
    await tapText(tester, 'GOT IT!');
    await tapText(tester, 'PASS');
    await tester.pump(const Duration(seconds: 61));
    expect(find.text("TIME'S UP!"), findsOneWidget);
    expect(find.text('Deez got 1'), findsOneWidget);
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
    'Horse Racing: bets take sips and shots, race lays out in landscape',
    (tester) async {
      await pumpApp(tester, open: 'horse_racing');
      expect(find.text('2 sips'), findsNWidgets(players.length));
      await tester.tap(find.text('+').at(1)); // first player's shots
      await tester.pump();
      expect(find.text('1 shot'), findsOneWidget);
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

  testWidgets('Most Likely To: everyone votes then results', (tester) async {
    await pumpApp(tester, open: 'most_likely');
    for (var i = 0; i < players.length; i++) {
      await tapText(tester, 'VOTE IN SECRET');
      await tapText(tester, 'Sam');
    }
    expect(find.text('Sam drinks 4!'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Pixel Roulette: spin shows a result', (tester) async {
    await pumpApp(tester, open: 'roulette');
    await tapText(tester, 'SPIN');
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Spin to find your fate.'), findsNothing);
    expect(find.text('SPIN'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Truth or Drink: drink then next', (tester) async {
    await pumpApp(tester, open: 'truth_or_drink');
    expect(find.text('Deez asks Sam:'), findsOneWidget);
    await tapText(tester, 'DRINK');
    expect(find.text('Sam chose to drink!'), findsOneWidget);
    await tapText(tester, 'NEXT');
    expect(find.text('Sam asks Alex:'), findsOneWidget);
    await unmount(tester);
  });
}
