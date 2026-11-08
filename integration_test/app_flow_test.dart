// End-to-end smoke test of the basic flows, run on a real phone:
//   flutter test integration_test/app_flow_test.dart -d <device-id>
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sip_quest/app_state.dart';
import 'package:sip_quest/main.dart';
import 'package:sip_quest/services/fx.dart';

Future<void> wait(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> tap(WidgetTester tester, String text, {bool scroll = false}) async {
  final f = find.text(text).first;
  if (scroll) {
    await tester.ensureVisible(f);
    await tester.pump();
  }
  await tester.tap(f);
  await wait(tester, const Duration(milliseconds: 900));
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back).first);
  await wait(tester, const Duration(milliseconds: 900));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // CI runs this on flutter-tester, which has no audio or sensor plugins.
  // On a real phone they stay on.
  Fx.hardware = !Platform.environment.containsKey('FLUTTER_TEST');

  testWidgets('basic flow across games', (tester) async {
    await tester.pumpWidget(SipQuestApp(state: AppState()));
    await wait(tester, const Duration(seconds: 1));
    expect(find.text('SIP QUEST'), findsOneWidget);

    // Add players.
    await tap(tester, 'NAMES (OPTIONAL)');
    for (final name in ['Deez', 'Sam', 'Alex', 'Jo']) {
      await tester.enterText(find.byType(TextField), name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await wait(tester, const Duration(milliseconds: 300));
    }
    expect(find.text('Jo'), findsOneWidget);
    await tap(tester, 'DONE');
    expect(find.text('NAMES: 4'), findsOneWidget);

    // Switch style and back to the default.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.textContaining('STYLE:'));
      await wait(tester, const Duration(milliseconds: 400));
    }
    expect(find.text('STYLE: NEON ARCADE'), findsOneWidget);

    // King's Cup: shuffle, draw a few.
    await tap(tester, "KING'S CUP", scroll: true);
    await wait(tester, const Duration(seconds: 3));
    await tap(tester, 'DRAW FIRST CARD');
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'DRAW');
    }
    expect(find.text('47'), findsOneWidget);
    await back(tester);

    // One of a Kind: one full round with a real 10 second timer.
    await tap(tester, 'ONE OF A KIND', scroll: true);
    for (var i = 0; i < 50 && find.text('HOST').evaluate().isEmpty; i++) {
      await wait(tester, const Duration(milliseconds: 200));
    }
    await tap(tester, '10s');
    await tap(tester, 'START', scroll: true);
    await tap(tester, 'GO! 10S');
    await wait(tester, const Duration(seconds: 11));
    expect(find.text('REVEAL!'), findsOneWidget);
    await tap(tester, 'Sam');
    await tap(tester, 'KNOCK OUT 1');
    expect(find.text('ROUND 2'), findsOneWidget);
    await back(tester);

    // Charades: heads-up round in landscape using the tap fallback.
    await tap(tester, 'CHARADES', scroll: true);
    await tap(tester, 'START');
    expect(find.text('PHONE ON YOUR FOREHEAD'), findsOneWidget);
    await tester.tap(find.byKey(const Key('charades-place')));
    await wait(tester, const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('charades-got')));
    await wait(tester, const Duration(seconds: 1));
    expect(find.text('GOT 1'), findsOneWidget);
    await wait(tester, const Duration(seconds: 31));
    expect(find.text("TIME'S UP!"), findsOneWidget);
    await back(tester);

    // How to play from the menu.
    await tester.ensureVisible(find.byKey(const Key('help-kings_cup')));
    await tester.tap(find.byKey(const Key('help-kings_cup')));
    await wait(tester, const Duration(seconds: 2));
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    await tap(tester, 'GOT IT', scroll: true);

    // Ride the Bus: one guess.
    await tap(tester, 'RIDE THE BUS', scroll: true);
    await tap(tester, 'RED');
    expect(find.textContaining(RegExp(r'NICE|WRONG')), findsOneWidget);
    await back(tester);

    // Pixel Roulette: one spin.
    await tap(tester, 'PIXEL ROULETTE', scroll: true);
    await tap(tester, 'SPIN');
    await wait(tester, const Duration(seconds: 4));
    expect(find.text('Spin to find your fate.'), findsNothing);
    await back(tester);

    expect(find.text('SIP QUEST'), findsWidgets);
    // Let the last sound effects finish so no audio frame callbacks outlive the test.
    await wait(tester, const Duration(seconds: 3));
  });
}
