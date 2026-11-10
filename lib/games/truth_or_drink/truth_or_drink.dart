import 'dart:math';

import '../common.dart';

const truthOrDrinkQuestions = [
  'What is the most embarrassing thing in your search history?',
  'Who in this room would you call first in an emergency?',
  'What is the worst date you have ever been on?',
  'What is a secret you have never told your parents?',
  'Who was your first crush?',
  'What is the pettiest thing you have ever done?',
  'What is the biggest lie you have told someone here?',
  'What would you do with a million dollars tomorrow?',
  'What is your most irrational fear?',
  'Which person here would you trade lives with?',
  'What is the worst thing you have ever said while half asleep?',
  'What is one thing you would change about your last relationship?',
  'Who here do you think has the best style?',
  'What is the most childish thing you still do?',
  'What is the weirdest thing you have ever eaten?',
  'What was your most awkward moment at work or school?',
  'What is your guilty pleasure song?',
  'Have you ever had a crush on a friend? Who?',
  'What is the dumbest way you have hurt yourself?',
  'What is the last thing you lied about?',
  'What is your most unpopular opinion?',
  'What is a red flag you ignored?',
  'If you had to date someone here, who?',
  'What is the meanest thing you have thought about someone here today?',
  'What do you pretend to like but secretly hate?',
  'What is the longest you have gone without showering?',
  'What is the most money you have wasted on something stupid?',
  'Which ex would you get back with, if any?',
  'What is the best compliment you have ever received?',
  'What would your last meal be?',
];

class TruthTurn {
  const TruthTurn(this.asker, this.answerer, this.question);
  final String? asker;
  final String? answerer;
  final String question;
}

/// Seat order: each player asks the person on their left, then passes on.
/// The answerer either answers honestly or takes a penalty.
class TruthOrDrink {
  TruthOrDrink(List<String> players, {Random? random})
      : _turns = TurnOrder(players),
        _questions = ShuffledQueue(truthOrDrinkQuestions, random: random);

  final TurnOrder _turns;
  final ShuffledQueue<String> _questions;
  final Map<String, int> penalties = {};
  final Map<String, int> answers = {};
  TruthTurn? current;

  TruthTurn deal() {
    if (current != null) _turns.advance();
    return current = TruthTurn(_turns.current, _turns.next, _questions.next());
  }

  void answered() {
    final a = current?.answerer;
    if (a != null) answers[a] = (answers[a] ?? 0) + 1;
  }

  void penalized() {
    final a = current?.answerer;
    if (a != null) penalties[a] = (penalties[a] ?? 0) + 1;
  }
}
