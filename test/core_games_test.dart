import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/games/cards.dart';
import 'package:sip_quest/games/horse_racing/horse_race.dart';
import 'package:sip_quest/games/horse_racing/horse_racing_screen.dart';
import 'package:sip_quest/games/kings_cup/kings_cup_game.dart';
import 'package:sip_quest/games/unique_answer/question_bank.dart';
import 'package:sip_quest/games/unique_answer/unique_answer_game.dart';

void main() {
  test('deck has 52 unique cards', () {
    final d = Deck.standard(random: Random(1));
    final seen = <PlayingCard>{};
    while (!d.isEmpty) {
      seen.add(d.draw());
    }
    expect(seen.length, 52);
  });

  test("four kings ends on 4th king and rotates players", () {
    final g = KingsCupGame(players: ['A', 'B', 'C'], random: Random(3));
    var draws = 0;
    while (g.status == KingsCupStatus.playing) {
      g.draw();
      draws++;
      expect(g.currentPlayer, ['A', 'B', 'C'][(draws - 1) % 3]);
    }
    expect(g.status, KingsCupStatus.fourthKing);
    expect(g.kingsDrawn, 4);
    expect(g.current!.rank, 13);
    expect(g.draw(), isNull);
  });

  test('unique answer elimination and replay when everyone matches', () {
    final g = UniqueAnswerGame(host: 'H', contestants: ['A', 'B', 'C']);
    expect(g.eliminate({'A'}), isTrue);
    expect(g.finalTwo, isTrue);
    expect(g.eliminate({'B', 'C'}), isFalse);
    expect(g.alive, ['B', 'C']);
    g.eliminate({'C'});
    expect(g.winner, 'B');
  });

  test('bundled question bank parses and yields prompts', () {
    final j = jsonDecode(
      File('assets/data/unique_answer_prompts.json').readAsStringSync(),
    );
    final bank = QuestionBank.fromJson(j as Map<String, dynamic>);
    expect(bank.questions.length, greaterThan(100));
    final deck = bank.deck(difficulties: {Difficulty.easy}, random: Random(2));
    final out = {for (var i = 0; i < 50; i++) deck.next()};
    expect(out.length, greaterThan(40));
    expect(out.every((q) => !q.contains('{L}')), isTrue);
  });

  test('horse race always finishes with a winner', () {
    for (var seed = 0; seed < 200; seed++) {
      final r = HorseRace(random: Random(seed));
      var guard = 0;
      while (!r.isOver && guard++ < 100) {
        r.step();
        for (final p in r.position.values) {
          expect(p, inInclusiveRange(0, r.finish));
        }
      }
      expect(r.winner, isNotNull);
    }
  });

  test('horse race bets read as penalties and dares', () {
    expect(betAmount(2, 0), '2 penalties');
    expect(betAmount(1, 1), '1 penalty + 1 dare');
    expect(betAmount(0, 4), '4 dares');
    expect(betAmount(0, 0), 'nothing');
  });
}
