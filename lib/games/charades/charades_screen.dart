import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/motion.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import '../how_to_play.dart';
import 'charades_words.dart';
import 'tilt.dart';

enum _Phase { setup, place, countdown, playing, summary }

class _Result {
  const _Result(this.word, this.got);
  final String word;
  final bool got;
}

/// Heads-up charades: the player holds the phone sideways on their forehead,
/// friends shout clues, tilt down for "got it" and up to pass. 30s rounds.
class CharadesScreen extends StatefulWidget {
  const CharadesScreen({super.key});

  @override
  State<CharadesScreen> createState() => _CharadesScreenState();
}

class _CharadesScreenState extends State<CharadesScreen> {
  _Phase _phase = _Phase.setup;
  final Set<String> _cats = {'Movies', 'Animals', 'Actions'};
  int _seconds = 30;
  int _turn = 0;

  final List<String> _queue = [];
  String _word = '';
  final List<_Result> _results = [];
  Timer? _timer;
  double _left = 0;
  int _count = 3;

  /// Colour flash after a tilt: true = got it, false = pass, null = none.
  bool? _flash;
  Timer? _flashTimer;

  final _tilt = TiltDetector();
  StreamSubscription<AccelerometerEvent>? _sensor;
  bool _hasSensor = false;
  DateTime? _levelSince;

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    _sensor?.cancel();
    _setLandscape(false);
    super.dispose();
  }

  String? get _player {
    final ps = context.app.players;
    return ps.isEmpty ? null : ps[_turn % ps.length];
  }

  int get _got => _results.where((r) => r.got).length;
  int get _passed => _results.length - _got;

  // --- Device ------------------------------------------------------------

  void _setLandscape(bool on) {
    try {
      SystemChrome.setPreferredOrientations(
        on
            ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
            : const [DeviceOrientation.portraitUp],
      ).catchError((_) {});
      SystemChrome.setEnabledSystemUIMode(
        on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ).catchError((_) {});
    } catch (_) {}
  }

  void _listen() {
    if (_sensor != null || !Fx.hardware || kIsWeb) return;
    try {
      _sensor = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onSample, onError: (_) => _sensor = null, cancelOnError: true);
    } catch (_) {
      _sensor = null;
    }
  }

  void _onSample(AccelerometerEvent e) {
    if (!_hasSensor) setState(() => _hasSensor = true);
    final tilt = _tilt.feed(e.z);
    switch (_phase) {
      case _Phase.place:
        // Start once the phone has been held upright for a moment.
        if (_tilt.isLevel) {
          _levelSince ??= DateTime.now();
          if (DateTime.now().difference(_levelSince!) > const Duration(milliseconds: 700)) _countdown();
        } else {
          _levelSince = null;
        }
      case _Phase.playing:
        if (tilt != null) _mark(tilt == Tilt.down);
      default:
        break;
    }
  }

  // --- Flow --------------------------------------------------------------

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

  void _toPlace() {
    if (_queue.isEmpty) _fill();
    _setLandscape(true);
    _tilt.reset();
    _levelSince = null;
    _listen();
    setState(() => _phase = _Phase.place);
  }

  void _countdown() {
    if (_phase != _Phase.place) return;
    _timer?.cancel();
    setState(() {
      _phase = _Phase.countdown;
      _count = 3;
    });
    Fx.tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count > 1) {
        setState(() => _count--);
        Fx.tick();
      } else {
        t.cancel();
        _go();
      }
    });
  }

  void _go() {
    _results.clear();
    _word = _take();
    _left = _seconds.toDouble();
    _flash = null;
    Fx.start();
    setState(() => _phase = _Phase.playing);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final before = _left.ceil();
      setState(() => _left = (_left - 0.1).clamp(0, 999));
      if (_left.ceil() != before && _left <= 5 && _left > 0) Fx.tick();
      if (_left <= 0) {
        t.cancel();
        _end();
      }
    });
  }

  void _end() {
    _timer?.cancel();
    _flashTimer?.cancel();
    _sensor?.cancel();
    _sensor = null;
    Fx.timeUp();
    _setLandscape(false);
    setState(() {
      _flash = null;
      _phase = _Phase.summary;
    });
  }

  void _mark(bool got) {
    if (_phase != _Phase.playing || _flash != null) return;
    got ? Fx.correct() : Fx.pass();
    setState(() {
      _results.add(_Result(_word, got));
      _flash = got;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _phase != _Phase.playing) return;
      setState(() {
        _flash = null;
        _word = _take();
      });
    });
  }

  void _nextPlayer() {
    setState(() => _turn++);
    _toPlace();
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final fullScreen = _phase == _Phase.place || _phase == _Phase.countdown || _phase == _Phase.playing;
    final child = switch (_phase) {
      _Phase.setup => _setup(context),
      _Phase.place => _place(context),
      _Phase.countdown => _countdownView(context),
      _Phase.playing => _playing(context),
      _Phase.summary => _summary(context),
    };
    final body = PhaseSwitcher(
      child: KeyedSubtree(key: ValueKey(_phase), child: child),
    );
    if (fullScreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _end();
        },
        child: Scaffold(backgroundColor: pal.bg, body: body),
      );
    }
    return PixelScaffold(
      title: 'Charades',
      onHelp: () => showHowToPlay(context, 'charades'),
      body: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: body),
    );
  }

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(s, style: PixelFonts.title(context.pal.textDim, size: 10)),
  );

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    return ListView(
      children: [
        PixelBox(
          child: Row(
            children: [
              PixelSprite(Sprites.mask, pixel: 5),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Phone on your forehead, screen out. Friends shout clues. '
                  'Tilt DOWN when you get it, tilt UP to pass.',
                  style: PixelFonts.body(pal.text, size: 22),
                ),
              ),
            ],
          ),
        ),
        _label('DECKS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
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
                  _queue.clear();
                }),
              ),
          ],
        ),
        _label('ROUND LENGTH'),
        Wrap(
          spacing: 8,
          children: [
            for (final s in [30, 45, 60])
              PixelChip(label: '${s}s', selected: _seconds == s, onTap: () => setState(() => _seconds = s)),
          ],
        ),
        const SizedBox(height: 24),
        PixelButton(label: 'Start', expand: true, onTap: _toPlace),
      ],
    );
  }

  Widget _place(BuildContext context) {
    final pal = context.pal;
    return GestureDetector(
      key: const Key('charades-place'),
      behavior: HitTestBehavior.opaque,
      onTap: _countdown,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_player != null) ...[
                Text("${_player!.toUpperCase()}'S TURN", style: PixelFonts.title(pal.accent, size: 16)),
                const SizedBox(height: 14),
              ],
              Text('PHONE ON YOUR FOREHEAD', style: PixelFonts.title(pal.text, size: 18), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Screen facing your friends. Hold it level to start.',
                textAlign: TextAlign.center,
                style: PixelFonts.body(pal.textDim, size: 26),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hint('TILT DOWN', 'GOT IT', pal.secondary),
                  const SizedBox(width: 24),
                  _hint('TILT UP', 'PASS', pal.accent),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _hasSensor ? 'or tap anywhere to start' : 'Tap anywhere to start',
                style: PixelFonts.title(pal.textDim, size: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(String a, String b, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(border: Border.all(color: c, width: 3)),
    child: Column(
      children: [
        Text(a, style: PixelFonts.title(c, size: 10)),
        const SizedBox(height: 4),
        Text('= $b', style: PixelFonts.body(context.pal.text, size: 22)),
      ],
    ),
  );

  Widget _countdownView(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: PopIn(
        value: _count,
        child: Text('$_count', style: PixelFonts.title(pal.accent, size: 96)),
      ),
    );
  }

  Widget _playing(BuildContext context) {
    final pal = context.pal;
    final low = _left <= 5;
    final flashColor = _flash == null ? pal.bg : (_flash! ? pal.secondary : pal.accent);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      color: flashColor,
      child: SafeArea(
        child: Stack(
          children: [
            // Tap fallback: left half passes, right half scores.
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: const Key('charades-pass'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _mark(false),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    key: const Key('charades-got'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _mark(true),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('${_left.ceil()}', style: PixelFonts.title(low ? pal.primary : pal.text, size: 26)),
                        const Spacer(),
                        Text('GOT $_got', style: PixelFonts.title(pal.text, size: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PixelBar(value: _left / _seconds, segments: 30, color: low ? pal.primary : pal.secondary),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: Motion.medium,
                          switchInCurve: Motion.pop,
                          transitionBuilder: (c, a) => FadeTransition(
                            opacity: a,
                            child: ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: c),
                          ),
                          child: _flash != null
                              ? Text(
                                  _flash! ? 'GOT IT!' : 'PASS',
                                  key: ValueKey('flash$_flash${_results.length}'),
                                  style: PixelFonts.title(pal.bg, size: 44),
                                )
                              : FittedBox(
                                  key: ValueKey(_word),
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _word.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: PixelFonts.title(pal.text, size: 40),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('< TAP: PASS', style: PixelFonts.title(pal.textDim, size: 8)),
                        const Spacer(),
                        Text('TAP: GOT IT >', style: PixelFonts.title(pal.textDim, size: 8)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final pal = context.pal;
    final who = _player ?? 'You';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("TIME'S UP!", textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 22)),
        const SizedBox(height: 14),
        PixelBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$who got $_got', style: PixelFonts.title(pal.accent, size: 13)),
              const SizedBox(height: 6),
              Text(
                _passed == 0
                    ? 'No passes. Clean round!'
                    : '$who drink${_player == null ? '' : 's'} $_passed for passing.',
                style: PixelFonts.body(pal.text),
              ),
              if (_got >= 5) Text('5+ correct: hand out $_got sips!', style: PixelFonts.body(pal.secondary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final r in _results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      PixelSprite(r.got ? Sprites.check : Sprites.cross, pixel: 3),
                      const SizedBox(width: 10),
                      Text(r.word, style: PixelFonts.body(r.got ? pal.text : pal.textDim)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PixelButton(
                label: 'Decks',
                expand: true,
                color: pal.panel,
                textColor: pal.text,
                onTap: () => setState(() => _phase = _Phase.setup),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PixelButton(label: 'Next player', expand: true, onTap: _nextPlayer),
            ),
          ],
        ),
      ],
    );
  }
}
