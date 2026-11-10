import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/games/cards.dart';
import 'package:sip_quest/games/common.dart';
import 'package:sip_quest/games/dial/dial.dart';
import 'package:sip_quest/games/fishbowl/fishbowl.dart';
import 'package:sip_quest/games/hot_potato/hot_potato.dart';
import 'package:sip_quest/games/imposter/imposter.dart';
import 'package:sip_quest/games/mafia/mafia.dart';
import 'package:sip_quest/games/ride_the_bus/ride_the_bus.dart';

PlayingCard c(int rank, [Suit suit = Suit.spades]) => PlayingCard(rank, suit);

void main() {
  group('ShuffledQueue', () {
    test('deals every item once per cycle', () {
      final q = ShuffledQueue([1, 2, 3, 4, 5], random: Random(1));
      final first = {for (var i = 0; i < 5; i++) q.next()};
      expect(first, {1, 2, 3, 4, 5});
    });
    test('never repeats back to back across reshuffles', () {
      final q = ShuffledQueue([1, 2, 3], random: Random(7));
      var prev = q.next();
      for (var i = 0; i < 300; i++) {
        final n = q.next();
        expect(n, isNot(prev));
        prev = n;
      }
    });
  });

  group('Ride the Bus', () {
    test('judges each stage, aces high, ties lose', () {
      expect(
        RideTheBus.judge(BusStage.color, BusGuess.red, c(5, Suit.hearts), []),
        isTrue,
      );
      expect(
        RideTheBus.judge(BusStage.color, BusGuess.red, c(5, Suit.clubs), []),
        isFalse,
      );
      expect(
        RideTheBus.judge(BusStage.higherLower, BusGuess.higher, c(1), [c(13)]),
        isTrue,
      );
      expect(
        RideTheBus.judge(BusStage.higherLower, BusGuess.higher, c(7), [c(7)]),
        isFalse,
      );
      expect(
        RideTheBus.judge(BusStage.higherLower, BusGuess.lower, c(7), [c(7)]),
        isFalse,
      );
      expect(
        RideTheBus.judge(BusStage.insideOutside, BusGuess.inside, c(6), [
          c(3),
          c(9),
        ]),
        isTrue,
      );
      expect(
        RideTheBus.judge(BusStage.insideOutside, BusGuess.inside, c(9), [
          c(3),
          c(9),
        ]),
        isFalse,
      );
      expect(
        RideTheBus.judge(BusStage.insideOutside, BusGuess.outside, c(9), [
          c(3),
          c(9),
        ]),
        isFalse,
      );
      expect(
        RideTheBus.judge(BusStage.insideOutside, BusGuess.outside, c(2), [
          c(9),
          c(3),
        ]),
        isTrue,
      );
      expect(
        RideTheBus.judge(
          BusStage.suit,
          BusGuess.diamonds,
          c(4, Suit.diamonds),
          [],
        ),
        isTrue,
      );
    });
    test(
      'wrong answer resets the row and costs a penalty; eventually finishes',
      () {
        final g = RideTheBus(random: Random(5));
        var guard = 0;
        while (!g.finished && guard++ < 5000) {
          final before = g.row.length;
          final r = g.guess(RideTheBus.optionsFor(g.stage).first);
          if (r.correct) {
            expect(g.row.length, before + 1);
          } else {
            expect(g.row, isEmpty);
          }
        }
        expect(g.finished, isTrue);
        expect(g.attempts, g.penalties + 1);
        expect(() => g.guess(BusGuess.red), throwsStateError);
      },
    );
    test('rejects guesses for the wrong stage', () {
      expect(() => RideTheBus().guess(BusGuess.higher), throwsArgumentError);
    });
  });

  group('Hot Potato', () {
    test('fuse stays within bounds and ticks speed up', () {
      for (var s = 0; s < 100; s++) {
        final b = BombRound(random: Random(s));
        expect(b.fuse.inMilliseconds, inInclusiveRange(10000, 45000));
        expect(b.exploded(b.fuse), isTrue);
        expect(b.exploded(b.fuse - const Duration(milliseconds: 1)), isFalse);
        expect(b.tickInterval(Duration.zero) > b.tickInterval(b.fuse), isTrue);
      }
    });
  });

  group('Fishbowl', () {
    test('teams alternate seats', () {
      final t = fishbowlTeams(['A', 'B', 'C', 'D', 'E']);
      expect(t[0].players, ['A', 'C', 'E']);
      expect(t[1].players, ['B', 'D']);
      expect(fishbowlTeams([]).every((t) => t.clueGiver == null), isTrue);
    });

    test('three rounds reuse every slip and the clearing team keeps going', () {
      final g = Fishbowl(slips: ['a', 'b', 'c'], teams: fishbowlTeams(['A', 'B', 'C', 'D']), random: Random(2));
      for (final round in FishbowlRound.values) {
        expect(g.round, round);
        expect(g.slipsLeft, 3);
        final seen = <String>{};
        while (!g.roundOver) {
          seen.add(g.draw());
          g.gotIt();
        }
        expect(seen, {'a', 'b', 'c'});
        if (!g.isLastRound) g.nextRound();
      }
      expect(g.team.name, 'Team A');
      expect(g.teams[0].score, 9);
      expect(g.winner, g.teams[0]);
      expect(() => g.nextRound(), throwsStateError);
    });

    test('skip returns the slip and draws a different one', () {
      final g = Fishbowl(slips: ['a', 'b'], teams: fishbowlTeams([]), random: Random(1));
      final first = g.draw();
      expect(g.skip(), isNot(first));
      expect(g.slipsLeft, 2);
    });

    test('ending a turn puts the slip back and rotates team and clue giver', () {
      final g = Fishbowl(slips: ['a', 'b'], teams: fishbowlTeams(['A', 'B', 'C', 'D']), random: Random(1));
      expect(g.team.clueGiver, 'A');
      g.draw();
      g.endTurn();
      expect(g.slipsLeft, 2);
      expect(g.team.name, 'Team B');
      expect(g.team.clueGiver, 'B');
      g.endTurn();
      expect(g.team.clueGiver, 'C');
      expect(g.winner, isNull);
    });
  });

  group('Imposter', () {
    test('right number of imposters, and one never starts', () {
      for (var seed = 0; seed < 100; seed++) {
        final r = ImposterRound(playerCount: 7, imposterCount: 2, random: Random(seed));
        expect(r.imposters.length, 2);
        expect(r.isImposter(r.starter), isFalse);
        expect(imposterWords[r.category], contains(r.word));
      }
    });
    test('a chosen category is respected', () {
      final r = ImposterRound(playerCount: 4, category: 'Animals', random: Random(1));
      expect(imposterWords['Animals'], contains(r.word));
    });
  });

  group('Dial It In', () {
    test('scores by distance from the target', () {
      final r = DialRound(spectrum: spectrums.first, random: Random(4));
      expect(r.target, inInclusiveRange(8, 92));
      expect(r.score(r.target.toDouble()), 4);
      expect(r.score(r.target + 7.0), 3);
      expect(r.score(r.target - 15.0), 2);
      expect(r.score(r.target + 17.0), 0);
    });
  });

  group('Mafia', () {
    const names = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    test('deals the right roles', () {
      final g = MafiaGame(names, random: Random(1));
      final counts = <MafiaRole, int>{};
      for (final r in g.roles.values) {
        counts[r] = (counts[r] ?? 0) + 1;
      }
      expect(counts, {MafiaRole.mafia: 2, MafiaRole.doctor: 1, MafiaRole.detective: 1, MafiaRole.villager: 4});
      expect(MafiaGame(names.take(5).toList(), random: Random(1)).roles.values, isNot(contains(MafiaRole.detective)));
      expect(() => MafiaGame(['A', 'B', 'C', 'D']), throwsArgumentError);
    });

    test('night kills unless the doctor saves; detective learns the truth', () {
      final g = MafiaGame(names, random: Random(3));
      String who(MafiaRole r) => g.roles.entries.firstWhere((e) => e.value == r).key;
      final villager = who(MafiaRole.villager);
      for (final m in g.mafia) {
        g.act(m, villager);
      }
      g.act(who(MafiaRole.doctor), villager);
      expect(g.act(who(MafiaRole.detective), g.mafia.first), isTrue);
      expect(g.resolveNight(), isNull);
      expect(g.alive.length, 8);
      for (final m in g.mafia) {
        g.act(m, villager);
      }
      expect(g.resolveNight(), villager);
      expect(g.alive.contains(villager), isFalse);
      expect(g.night, 3);
    });

    test('town wins with no mafia left; mafia win at parity', () {
      final g = MafiaGame(names.take(5).toList(), random: Random(2));
      expect(g.winner, isNull);
      g.voteOut(g.mafia.single);
      expect(g.winner, MafiaSide.town);

      final h = MafiaGame(names.take(5).toList(), random: Random(2));
      final town = [for (final p in h.players) if (h.roles[p] != MafiaRole.mafia) p];
      h.voteOut(town[0]);
      h.voteOut(town[1]);
      expect(h.winner, isNull);
      h.voteOut(town[2]);
      expect(h.winner, MafiaSide.mafia);
    });
  });
}
