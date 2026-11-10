import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/motion.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/sprites.dart';
import 'question_bank.dart';
import 'unique_answer_game.dart';

enum _Phase { setup, prompt, timing, reveal, winner }

class UniqueAnswerScreen extends StatefulWidget {
  const UniqueAnswerScreen({super.key});

  @override
  State<UniqueAnswerScreen> createState() => _UniqueAnswerScreenState();
}

class _UniqueAnswerScreenState extends State<UniqueAnswerScreen> {
  QuestionBank? _bank;
  QuestionDeck? _deck;
  UniqueAnswerGame? _game;
  _Phase _phase = _Phase.setup;

  /// Quick mode (fewer than 3 names): the phone hosts, players track who is out.
  bool get _quick => context.app.players.length < 3;
  int _quickRound = 1;

  // Setup choices
  String? _host;
  int _seconds = 15;
  final Set<String> _categories = {};
  final Set<Difficulty> _difficulties = {Difficulty.easy, Difficulty.medium};

  // Round state
  String _prompt = '';
  final Set<String> _matched = {};
  String? _lastResult;
  Timer? _timer;
  double _left = 0;

  @override
  void initState() {
    super.initState();
    QuestionBank.load().then((b) {
      if (mounted) setState(() => _bank = b);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final players = context.app.players;
    if (_quick) {
      _game = null;
      _quickRound = 1;
    } else {
      final host = _host ?? players.first;
      _game = UniqueAnswerGame(host: host, contestants: [...players.where((p) => p != host)]);
    }
    _deck = _bank!.deck(categories: _categories, difficulties: _difficulties);
    _lastResult = null;
    _nextPrompt();
  }

  void _nextPrompt() {
    setState(() {
      _prompt = _deck!.next();
      _matched.clear();
      _phase = _Phase.prompt;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _left = _seconds.toDouble();
      _phase = _Phase.timing;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final before = _left.ceil();
      setState(() => _left = (_left - 0.1).clamp(0, 999));
      if (_left.ceil() != before && _left <= 3 && _left > 0) Fx.tick();
      if (_left <= 0) {
        t.cancel();
        Fx.timeUp();
        setState(() => _phase = _Phase.reveal);
      }
    });
  }

  void _lockIn() {
    final g = _game!;
    final hits = Set.of(_matched);
    hits.isEmpty ? Fx.correct() : Fx.lose();
    final ok = g.eliminate(hits);
    setState(() {
      if (!ok) {
        _lastResult = 'Everyone matched! Everyone takes a penalty, nobody is out.';
      } else if (hits.isEmpty) {
        _lastResult = 'All unique! The host takes a penalty.';
      } else {
        _lastResult = '${hits.join(', ')} ${hits.length == 1 ? 'is' : 'are'} out. Penalty!';
      }
    });
    if (g.isOver) {
      Fx.win();
      setState(() => _phase = _Phase.winner);
    } else {
      _nextPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'One of a Kind',
      onHelp: () => showHowToPlay(context, 'one_of_a_kind'),
      body: _bank == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: PhaseSwitcher(
                child: KeyedSubtree(
                  key: ValueKey(_phase == _Phase.timing ? _Phase.prompt : _phase),
                  child: switch (_phase) {
                    _Phase.setup => _setup(context),
                    _Phase.prompt || _Phase.timing => _round(context),
                    _Phase.reveal => _reveal(context),
                    _Phase.winner => _winner(context),
                  },
                ),
              ),
            ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(s, style: PixelFonts.title(context.pal.textDim, size: 10)),
      );

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    final players = context.app.players;
    final host = _quick ? null : (_host ?? players.first);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PixelBox(
          child: Text(
            'The host reads a prompt. Everyone else writes an answer before time runs out. '
            'Reveal together. Match anyone and you are out. Final two must also dodge the host\'s answer.',
            style: PixelFonts.body(pal.text, size: 22),
          ),
        ),
        _label('HOST'),
        if (_quick)
          Text('Whoever holds the phone. Players keep track of who is out. '
              'Add 3+ names and the phone tracks it for you.',
              style: PixelFonts.body(pal.textDim, size: 22))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in players)
              PixelChip(label: p, selected: p == host, onTap: () => setState(() => _host = p)),
          ]),
        _label('TIMER'),
        Wrap(spacing: 8, children: [
          for (final s in [10, 15, 20, 30])
            PixelChip(label: '${s}s', selected: _seconds == s, onTap: () => setState(() => _seconds = s)),
        ]),
        _label('DIFFICULTY'),
        Wrap(spacing: 8, children: [
          for (final d in Difficulty.values)
            PixelChip(
              label: d.name,
              selected: _difficulties.contains(d),
              onTap: () => setState(() {
                if (!_difficulties.remove(d)) _difficulties.add(d);
              }),
            ),
        ]),
        _label('CATEGORIES (NONE = ALL)'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _bank!.categories)
            PixelChip(
              label: c.name,
              selected: _categories.contains(c.id),
              selectedColor: pal.secondary,
              onTap: () => setState(() {
                if (!_categories.remove(c.id)) _categories.add(c.id);
              }),
            ),
        ]),
        const SizedBox(height: 24),
        PixelButton(label: 'Start', expand: true, onTap: _start),
      ]),
    );
  }

  Widget _standing(BuildContext context) {
    final g = _game;
    if (g == null) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final p in g.alive) PixelChip(label: p),
      for (final p in g.out) PixelChip(label: p, struck: true),
    ]);
  }

  Widget _round(BuildContext context) {
    final pal = context.pal;
    final g = _game;
    final timing = _phase == _Phase.timing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text('ROUND ${g?.round ?? _quickRound}', style: PixelFonts.title(pal.accent, size: 11)),
          const Spacer(),
          if (g != null) Text('HOST: ${g.host}', style: PixelFonts.body(pal.textDim, size: 22)),
        ]),
        if (_lastResult != null) ...[
          const SizedBox(height: 10),
          PixelBox(
            borderColor: pal.primary,
            padding: const EdgeInsets.all(10),
            child: Text(_lastResult!, style: PixelFonts.body(pal.primary, size: 22)),
          ),
        ],
        if (g?.finalTwo ?? false) ...[
          const SizedBox(height: 10),
          PixelBox(
            borderColor: pal.accent,
            padding: const EdgeInsets.all(10),
            child: Text('FINAL TWO: the host writes an answer too. Don\'t match it!',
                style: PixelFonts.body(pal.accent, size: 22)),
          ),
        ],
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelSprite(Sprites.question, pixel: 5),
                const SizedBox(height: 18),
                Text(_prompt,
                    textAlign: TextAlign.center,
                    style: PixelFonts.title(pal.text, size: 20)),
                const SizedBox(height: 26),
                if (timing) ...[
                  Text('${_left.ceil()}',
                      style: PixelFonts.title(_left <= 3 ? pal.primary : pal.secondary, size: 44)),
                  const SizedBox(height: 12),
                  PixelBar(
                    value: _left / _seconds,
                    color: _left <= 3 ? pal.primary : pal.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
        _standing(context),
        const SizedBox(height: 14),
        if (!timing)
          Row(children: [
            Expanded(
              child: PixelButton(label: 'Skip', color: pal.panel, textColor: pal.text, expand: true, onTap: _nextPrompt),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: PixelButton(label: 'Go! ${_seconds}s', expand: true, onTap: _startTimer)),
          ])
        else
          PixelButton(
            label: 'Pens down',
            expand: true,
            color: pal.accent,
            onTap: () {
              _timer?.cancel();
              Fx.flip();
              setState(() => _phase = _Phase.reveal);
            },
          ),
      ],
    );
  }

  Widget _quickReveal(BuildContext context) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('REVEAL!', textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 26)),
        const SizedBox(height: 10),
        Text(_prompt, textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
        const SizedBox(height: 18),
        PixelBox(
          child: Text(
            'Everyone flips their answer. Matched someone or left it blank? You are out. Penalty!\n\n'
            'Down to two? They also need to dodge the host\'s answer.',
            style: PixelFonts.body(pal.text, size: 22),
          ),
        ),
        const Spacer(),
        PixelButton(
          label: 'Next prompt',
          expand: true,
          onTap: () {
            _quickRound++;
            _nextPrompt();
          },
        ),
        const SizedBox(height: 10),
        PixelButton(
          label: 'We have a winner',
          expand: true,
          color: pal.accent,
          onTap: () {
            Fx.win();
            setState(() => _phase = _Phase.winner);
          },
        ),
      ],
    );
  }

  Widget _reveal(BuildContext context) {
    final pal = context.pal;
    final g = _game;
    if (g == null) return _quickReveal(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('REVEAL!', textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 26)),
        const SizedBox(height: 10),
        Text(_prompt, textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
        const SizedBox(height: 18),
        PixelBox(
          child: Text(
            g.finalTwo
                ? 'Host, tap anyone who matched the other player OR your answer (or left it blank).'
                : 'Host, tap everyone whose answer matched someone else (or left it blank).',
            style: PixelFonts.body(pal.text, size: 22),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              for (final p in g.alive)
                PixelChip(
                  label: p,
                  selected: _matched.contains(p),
                  onTap: () => setState(() {
                    if (!_matched.remove(p)) _matched.add(p);
                  }),
                ),
            ]),
          ),
        ),
        PixelButton(
          label: _matched.isEmpty ? 'Nobody matched' : 'Knock out ${_matched.length}',
          expand: true,
          onTap: _lockIn,
        ),
      ],
    );
  }

  Widget _winner(BuildContext context) {
    final pal = context.pal;
    final g = _game;
    return Column(
      children: [
        const Spacer(),
        PixelSprite(Sprites.crown, pixel: 9),
        const SizedBox(height: 20),
        Text(g?.winner ?? 'WINNER!', style: PixelFonts.title(pal.accent, size: 24)),
        const SizedBox(height: 10),
        Text(g == null ? 'Last one standing is one of a kind!' : 'is one of a kind!',
            textAlign: TextAlign.center, style: PixelFonts.body(pal.text, size: 28)),
        const SizedBox(height: 10),
        Text(g == null ? 'Winner hands out a penalty per player.' : 'Winner hands out ${g.out.length} penalties.',
            style: PixelFonts.body(pal.textDim)),
        const Spacer(),
        PixelButton(label: 'Play again', expand: true, onTap: () => setState(() => _phase = _Phase.setup)),
      ],
    );
  }
}
