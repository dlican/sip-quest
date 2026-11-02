import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import 'charades_words.dart';

enum _Phase { setup, ready, acting, summary }

class CharadesScreen extends StatefulWidget {
  const CharadesScreen({super.key});

  @override
  State<CharadesScreen> createState() => _CharadesScreenState();
}

class _CharadesScreenState extends State<CharadesScreen> {
  _Phase _phase = _Phase.setup;
  final Set<String> _cats = {'Movies', 'Animals', 'Actions'};
  int _seconds = 60;
  int _actorIndex = 0;

  final List<String> _queue = [];
  String _word = '';
  final List<String> _got = [];
  final List<String> _passed = [];
  Timer? _timer;
  double _left = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? get _actor {
    final ps = context.app.players;
    return ps.isEmpty ? null : ps[_actorIndex % ps.length];
  }

  void _fill() {
    _queue
      ..clear()
      ..addAll([for (final c in _cats) ...charadesWords[c]!])
      ..shuffle();
  }

  String _take() {
    if (_queue.isEmpty) _fill();
    return _queue.removeLast();
  }

  void _go() {
    _got.clear();
    _passed.clear();
    _word = _take();
    _left = _seconds.toDouble();
    setState(() => _phase = _Phase.acting);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() => _left = (_left - 0.1).clamp(0, 999));
      if (_left <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        setState(() => _phase = _Phase.summary);
      }
    });
  }

  void _mark(bool correct) {
    HapticFeedback.lightImpact();
    setState(() {
      (correct ? _got : _passed).add(_word);
      _word = _take();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Charades',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: switch (_phase) {
          _Phase.setup => _setup(context),
          _Phase.ready => _ready(context),
          _Phase.acting => _acting(context),
          _Phase.summary => _summary(context),
        },
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(s, style: PixelFonts.title(context.pal.textDim, size: 10)),
      );

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    return ListView(children: [
      PixelBox(
        child: Text(
          'One actor sees the word and acts it out. No talking, no pointing at things. '
          'Everyone else shouts guesses. Actor drinks for every pass; whoever guesses right hands out a sip.',
          style: PixelFonts.body(pal.text, size: 22),
        ),
      ),
      _label('DECKS'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in charadesWords.keys)
          PixelChip(
            label: c,
            selected: _cats.contains(c),
            onTap: () => setState(() {
              if (_cats.contains(c)) {
                if (_cats.length > 1) _cats.remove(c);
              } else {
                _cats.add(c);
              }
            }),
          ),
      ]),
      _label('ROUND LENGTH'),
      Wrap(spacing: 8, children: [
        for (final s in [45, 60, 90])
          PixelChip(label: '${s}s', selected: _seconds == s, onTap: () => setState(() => _seconds = s)),
      ]),
      const SizedBox(height: 24),
      PixelButton(
        label: 'Start',
        expand: true,
        onTap: () {
          _fill();
          setState(() => _phase = _Phase.ready);
        },
      ),
    ]);
  }

  Widget _ready(BuildContext context) {
    final pal = context.pal;
    return Column(children: [
      const Spacer(),
      PixelSprite(Sprites.mask, pixel: 9),
      const SizedBox(height: 24),
      Text(_actor == null ? 'ACTOR UP' : 'HAND THE PHONE TO',
          style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 10),
      if (_actor != null) Text(_actor!, style: PixelFonts.title(pal.accent, size: 24)),
      const SizedBox(height: 10),
      Text('Only the actor looks at the screen.', style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(label: "I'm ready", expand: true, onTap: _go),
    ]);
  }

  Widget _acting(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('${_left.ceil()}s', style: PixelFonts.title(_left <= 10 ? pal.primary : pal.secondary, size: 18)),
        const Spacer(),
        Text('GOT ${_got.length}', style: PixelFonts.title(pal.accent, size: 12)),
      ]),
      const SizedBox(height: 8),
      PixelBar(value: _left / _seconds, segments: 20, color: _left <= 10 ? pal.primary : pal.secondary),
      Expanded(
        child: Center(
          child: Text(_word.toUpperCase(),
              textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 26)),
        ),
      ),
      Row(children: [
        Expanded(
          child: PixelButton(
              label: 'Pass', color: pal.panel, textColor: pal.text, expand: true, onTap: () => _mark(false)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: PixelButton(label: 'Got it!', color: pal.secondary, expand: true, onTap: () => _mark(true)),
        ),
      ]),
    ]);
  }

  Widget _summary(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text("TIME'S UP!", textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 22)),
      const SizedBox(height: 14),
      PixelBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_actor ?? 'Actor'} got ${_got.length}', style: PixelFonts.title(pal.accent, size: 13)),
          const SizedBox(height: 6),
          Text(
            _passed.isEmpty
                ? 'No passes. Clean round!'
                : '${_actor ?? 'Actor'} drinks ${_passed.length} for passing.',
            style: PixelFonts.body(pal.text),
          ),
          if (_got.length < 3) Text('Under 3 correct: actor finishes their drink.', style: PixelFonts.body(pal.primary)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(children: [
          for (final w in _got) Text('+ $w', style: PixelFonts.body(pal.secondary)),
          for (final w in _passed) Text('- $w', style: PixelFonts.body(pal.textDim)),
        ]),
      ),
      PixelButton(
        label: 'Next actor',
        expand: true,
        onTap: () => setState(() {
          _actorIndex++;
          _phase = _Phase.ready;
        }),
      ),
    ]);
  }
}
