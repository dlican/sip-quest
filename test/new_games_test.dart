import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/games/beat_the_dealer/beat_the_dealer.dart';
import 'package:sip_quest/games/cards.dart';
import 'package:sip_quest/games/common.dart';
import 'package:sip_quest/games/higher_lower/higher_lower.dart';
import 'package:sip_quest/games/hot_potato/hot_potato.dart';
import 'package:sip_quest/games/most_likely/most_likely.dart';
import 'package:sip_quest/games/never_have_i_ever/never_have_i_ever.dart';
import 'package:sip_quest/games/ride_the_bus/ride_the_bus.dart';
import 'package:sip_quest/games/roulette/roulette.dart';
import 'package:sip_quest/games/truth_or_drink/truth_or_drink.dart';

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
      expect(RideTheBus.judge(BusStage.color, BusGuess.red, c(5, Suit.hearts), []), isTrue);
      expect(RideTheBus.judge(BusStage.color, BusGuess.red, c(5, Suit.clubs), []), isFalse);
      expect(RideTheBus.judge(BusStage.higherLower, BusGuess.higher, c(1), [c(13)]), isTrue);
      expect(RideTheBus.judge(BusStage.higherLower, BusGuess.higher, c(7), [c(7)]), isFalse);
      expect(RideTheBus.judge(BusStage.higherLower, BusGuess.lower, c(7), [c(7)]), isFalse);
      expect(RideTheBus.judge(BusStage.insideOutside, BusGuess.inside, c(6), [c(3), c(9)]), isTrue);
      expect(RideTheBus.judge(BusStage.insideOutside, BusGuess.inside, c(9), [c(3), c(9)]), isFalse);
      expect(RideTheBus.judge(BusStage.insideOutside, BusGuess.outside, c(9), [c(3), c(9)]), isFalse);
      expect(RideTheBus.judge(BusStage.insideOutside, BusGuess.outside, c(2), [c(9), c(3)]), isTrue);
      expect(RideTheBus.judge(BusStage.suit, BusGuess.diamonds, c(4, Suit.diamonds), []), isTrue);
    });
    test('wrong answer resets the row and costs a drink; eventually finishes', () {
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
      expect(g.attempts, g.drinks + 1);
      expect(() => g.guess(BusGuess.red), throwsStateError);
    });
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

  group('Most Likely To', () {
    test('tallies votes and reports ties', () {
      final v = VoteRound(['A', 'B', 'C', 'D']);
      expect(v.nextVoter, 'A');
      v.cast('A', 'B');
      v.cast('B', 'C');
      v.cast('C', 'B');
      expect(v.complete, isFalse);
      v.cast('D', 'C');
      expect(v.complete, isTrue);
      expect(v.tally, {'A': 0, 'B': 2, 'C': 2, 'D': 0});
      expect(v.winners, ['B', 'C']);
      expect(() => v.cast('A', 'C'), throwsStateError);
      expect(() => v.cast('Z', 'C'), throwsArgumentError);
    });
  });

  group('Higher or Lower', () {
    test('streak grows, ties keep it, misses cost the streak', () {
      final g = HigherLower(random: Random(9));
      var sawWrong = false;
      for (var i = 0; i < 200; i++) {
        final prev = HigherLower.value(g.current);
        final streak = g.streak;
        final r = g.guess(HLGuess.higher);
        final now = HigherLower.value(r.card);
        if (now > prev) {
          expect(r.outcome, HLOutcome.correct);
          expect(g.streak, streak + 1);
        } else if (now == prev) {
          expect(r.outcome, HLOutcome.tie);
          expect(g.streak, streak);
        } else {
          sawWrong = true;
          expect(r.outcome, HLOutcome.wrong);
          expect(r.drinks, max(1, streak));
          expect(g.streak, 0);
        }
        expect(g.best, greaterThanOrEqualTo(g.streak));
      }
      expect(sawWrong, isTrue);
    });
  });

  group('Never Have I Ever', () {
    test('fingers go down, out at zero, last hand wins', () {
      final t = NhieTracker(['A', 'B'], fingers: 2);
      t.fingerDown('A');
      expect(t.fingersOf('A'), 1);
      t.undo('A');
      expect(t.fingersOf('A'), 2);
      t.undo('A');
      expect(t.fingersOf('A'), 2);
      t
        ..fingerDown('A')
        ..fingerDown('A')
        ..fingerDown('A');
      expect(t.fingersOf('A'), 0);
      expect(t.isOver, isTrue);
      expect(t.standing, ['B']);
    });
    test('both levels have prompts', () {
      for (final l in NhieLevel.values) {
        expect(nhiePrompts[l]!.length, greaterThanOrEqualTo(15));
      }
    });
  });

  group('Roulette', () {
    test('spin lands centred on the chosen slice', () {
      final r = Roulette(random: Random(3));
      for (var i = 0; i < 200; i++) {
        final s = r.spin();
        expect(r.sliceAt(s.turns), s.index);
        expect(s.turns, greaterThanOrEqualTo(4));
      }
    });
  });

  group('Beat the Dealer', () {
    test('first-try hit, higher/lower hint, miss difference, pass after 3', () {
      final g = BeatTheDealer(random: Random(11));
      final first = g.card;
      final hit = g.guess(first.rank);
      expect(hit.outcome, DealerOutcome.correctFirst);
      expect(hit.dealerDrinks, 4);

      for (var miss = 1; miss <= 3; miss++) {
        final card = g.card;
        final wrong1 = card.rank == 1 ? 2 : 1;
        final hint = g.guess(wrong1);
        expect(hint.outcome, card.rank > wrong1 ? DealerOutcome.higher : DealerOutcome.lower);
        final wrong2 = card.rank == 13 ? 12 : 13;
        final r = g.guess(wrong2);
        expect(r.outcome, DealerOutcome.miss);
        expect(r.drinks, (card.rank - wrong2).abs());
        expect(r.dealerPasses, miss == 3);
      }
      expect(g.missStreak, 0);
    });
    test('second-try hit gives the dealer 2', () {
      final g = BeatTheDealer(random: Random(2));
      final card = g.card;
      g.guess(card.rank == 1 ? 2 : 1);
      expect(g.guess(card.rank).dealerDrinks, 2);
    });
    test('runs the whole deck then stops', () {
      final g = BeatTheDealer(random: Random(4));
      var n = 0;
      while (!g.isOver) {
        g.guess(g.card.rank);
        n++;
      }
      expect(n, 52);
      expect(() => g.guess(1), throwsStateError);
    });
  });

  group('Truth or Drink', () {
    test('asker asks the next seat and rotates', () {
      final g = TruthOrDrink(['A', 'B', 'C'], random: Random(1));
      final t1 = g.deal();
      expect([t1.asker, t1.answerer], ['A', 'B']);
      g.drank();
      final t2 = g.deal();
      expect([t2.asker, t2.answerer], ['B', 'C']);
      g.answered();
      final t3 = g.deal();
      expect([t3.asker, t3.answerer], ['C', 'A']);
      expect(g.drinks, {'B': 1});
      expect(g.answers, {'C': 1});
    });
    test('works with no players', () {
      final t = TruthOrDrink([]).deal();
      expect(t.asker, isNull);
      expect(t.question, isNotEmpty);
    });
  });
}
