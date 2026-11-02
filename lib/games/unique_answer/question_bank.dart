import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// Pluggable prompt source for "One of a Kind". The bundled bank lives in
/// assets/data/unique_answer_prompts.json; swap or extend that file to change
/// the questions. Schema:
///   categories: [{id, name, emoji}]
///   prompts: [{id, category, difficulty: easy|medium|hard, text}]
///   letter_templates: [{id, category, template ("...{L}..."), easy_letters, all_letters}]
class QuestionCategory {
  const QuestionCategory(this.id, this.name, this.emoji);
  final String id;
  final String name;
  final String emoji;
}

enum Difficulty { easy, medium, hard }

class Question {
  const Question({required this.id, required this.category, required this.difficulty, required this.text});
  final String id;
  final String category;
  final Difficulty difficulty;
  final String text;
}

class LetterTemplate {
  const LetterTemplate(
      {required this.id,
      required this.category,
      required this.template,
      required this.easyLetters,
      required this.allLetters});
  final String id;
  final String category;
  final String template;
  final List<String> easyLetters;
  final List<String> allLetters;
}

class QuestionBank {
  QuestionBank({required this.categories, required this.questions, required this.templates});

  final List<QuestionCategory> categories;
  final List<Question> questions;
  final List<LetterTemplate> templates;

  static const assetPath = 'assets/data/unique_answer_prompts.json';

  static Future<QuestionBank> load() async =>
      QuestionBank.fromJson(jsonDecode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>);

  factory QuestionBank.fromJson(Map<String, dynamic> j) {
    Difficulty diff(Object? d) =>
        Difficulty.values.firstWhere((x) => x.name == d, orElse: () => Difficulty.medium);
    List<String> strs(Object? l) => [for (final x in (l as List? ?? const [])) '$x'];
    return QuestionBank(
      categories: [
        for (final c in (j['categories'] as List? ?? const []))
          QuestionCategory('${c['id']}', '${c['name']}', '${c['emoji'] ?? ''}'),
      ],
      questions: [
        for (final p in (j['prompts'] as List? ?? const []))
          Question(
              id: '${p['id']}',
              category: '${p['category']}',
              difficulty: diff(p['difficulty']),
              text: '${p['text']}'),
      ],
      templates: [
        for (final t in (j['letter_templates'] as List? ?? const []))
          LetterTemplate(
            id: '${t['id']}',
            category: '${t['category']}',
            template: '${t['template']}',
            easyLetters: strs(t['easy_letters']),
            allLetters: strs(t['all_letters']),
          ),
      ],
    );
  }

  /// Builds a non-repeating stream of prompts filtered by category/difficulty.
  /// Letter templates are mixed in (about 1 in 5) with a random letter.
  QuestionDeck deck({Set<String>? categories, Set<Difficulty>? difficulties, Random? random}) {
    final r = random ?? Random();
    bool catOk(String c) => categories == null || categories.isEmpty || categories.contains(c);
    final ds = (difficulties == null || difficulties.isEmpty) ? Difficulty.values.toSet() : difficulties;
    final pool = [
      for (final q in questions)
        if (catOk(q.category) && ds.contains(q.difficulty)) q.text,
    ];
    final tpls = [for (final t in templates) if (catOk(t.category)) t];
    final easyOnly = ds.length == 1 && ds.contains(Difficulty.easy);
    return QuestionDeck._(pool, tpls, easyOnly, r);
  }
}

class QuestionDeck {
  QuestionDeck._(this._pool, this._templates, this._easyLetters, this._random) {
    _refill();
  }

  final List<String> _pool;
  final List<LetterTemplate> _templates;
  final bool _easyLetters;
  final Random _random;
  final List<String> _queue = [];
  final Set<String> _usedTemplates = {};

  bool get isEmpty => _pool.isEmpty && _templates.isEmpty;

  void _refill() {
    _queue
      ..clear()
      ..addAll(_pool)
      ..shuffle(_random);
  }

  String next() {
    if (isEmpty) return 'Name something in this room';
    final useTemplate = _templates.isNotEmpty && (_pool.isEmpty || _random.nextInt(5) == 0);
    if (useTemplate) {
      final t = _templates[_random.nextInt(_templates.length)];
      final letters = (_easyLetters && t.easyLetters.isNotEmpty) ? t.easyLetters : t.allLetters;
      if (letters.isNotEmpty) {
        for (var tries = 0; tries < 8; tries++) {
          final text = t.template.replaceAll('{L}', letters[_random.nextInt(letters.length)]);
          if (_usedTemplates.add(text)) return text;
        }
      }
    }
    if (_queue.isEmpty) _refill();
    if (_queue.isEmpty) return 'Name something in this room';
    return _queue.removeLast();
  }
}
