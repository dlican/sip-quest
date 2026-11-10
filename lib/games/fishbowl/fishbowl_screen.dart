import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/sprites.dart';
import '../charades/charades_words.dart';
import '../how_to_play.dart';
import 'fishbowl.dart';

enum _Phase { setup, adding, handoff, ready, playing, turnOver, roundOver, gameOver }

class FishbowlScreen extends StatefulWidget {
  const FishbowlScreen({super.key});

  @override
  State<FishbowlScreen> createState() => _FishbowlScreenState();
}

class _FishbowlScreenState extends State<FishbowlScreen> {
  static const _times = [30, 45, 60];
  static const _minSlips = 5;

  _Phase _phase = _Phase.setup;
  int _seconds = 45;
  int _perPlayer = 3;
  final List<String> _slips = [];
  int _writer = 0;
  int _written = 0;
  bool _justAdded = false;

  Fishbowl? _game;
  int _turnGot = 0;
  // Counted down by the ticker itself so the turn pauses with the app and
  // stays testable with fake time.
  Duration _left = Duration.zero;
  static const _step = Duration(milliseconds: 100);
  Timer? _timer;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  List<String> get _players => context.app.players;

  /// Under 4 names the teams are too small to split, so they pick sides.
  List<String> get _teamPlayers => _players.length >= 4 ? _players : const [];

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _addSlip() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Fx.select();
    _ctrl.clear();
    setState(() {
      _slips.add(text);
      _justAdded = true;
      _written++;
      if (_players.isNotEmpty && _written >= _perPlayer) {
        _written = 0;
        _writer++;
        _phase = _writer < _players.length ? _Phase.handoff : _Phase.ready;
        if (_phase == _Phase.ready) _newGame();
      }
    });
    if (_phase == _Phase.adding) _focus.requestFocus();
  }

  void _addRandom(int n) {
    final pool = [
      for (final words in charadesWords.values)
        for (final w in words)
          if (!_slips.contains(w)) w,
    ]..shuffle(Random());
    Fx.select();
    setState(() => _slips.addAll(pool.take(n)));
  }

  void _newGame() {
    _game = Fishbowl(slips: _slips, teams: fishbowlTeams(_teamPlayers));
    _left = Duration(seconds: _seconds);
    _phase = _Phase.ready;
  }

  void _startTurn() {
    Fx.start();
    _turnGot = 0;
    _game!.draw();
    setState(() => _phase = _Phase.playing);
    _runClock();
  }

  void _runClock() {
    _timer?.cancel();
    _timer = Timer.periodic(_step, (_) {
      final before = _left.inSeconds;
      _left -= _step;
      if (_left <= Duration.zero) {
        _timer?.cancel();
        Fx.timeUp();
        _game!.endTurn();
        _left = Duration(seconds: _seconds);
        setState(() => _phase = _Phase.turnOver);
        return;
      }
      if (_left.inSeconds < before && before <= 5) Fx.tick();
      setState(() {});
    });
  }

  void _gotIt() {
    final g = _game!;
    g.gotIt();
    _turnGot++;
    if (!g.roundOver) {
      Fx.correct();
      setState(() => g.draw());
      return;
    }
    _timer?.cancel();
    if (g.isLastRound) {
      Fx.win();
      setState(() => _phase = _Phase.gameOver);
    } else {
      Fx.correct();
      setState(() => _phase = _Phase.roundOver);
    }
  }

  void _skip() {
    Fx.pass();
    setState(() => _game!.skip());
  }

  /// The team that emptied the bowl keeps going with its leftover time.
  void _continueRound() {
    _game!.nextRound();
    _game!.draw();
    Fx.start();
    setState(() => _phase = _Phase.playing);
    _runClock();
  }

  void _playAgain({required bool sameSlips}) {
    _timer?.cancel();
    setState(() {
      if (sameSlips) {
        _newGame();
      } else {
        _slips.clear();
        _writer = 0;
        _written = 0;
        _game = null;
        _phase = _Phase.setup;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Fishbowl',
      onHelp: () => showHowToPlay(context, 'fishbowl'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: switch (_phase) {
          _Phase.setup => _setup(context),
          _Phase.adding => _adding(context),
          _Phase.handoff => _handoff(context),
          _Phase.ready => _ready(context),
          _Phase.playing => _playing(context),
          _Phase.turnOver => _turnOver(context),
          _Phase.roundOver => _roundOver(context),
          _Phase.gameOver => _gameOver(context),
        },
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    final teams = fishbowlTeams(_teamPlayers);
    return ListView(children: [
      Center(child: PixelSprite(Sprites.fishbowl, pixel: 9)),
      const SizedBox(height: 14),
      Text('Everyone secretly writes names, things or phrases on slips. '
          'Two teams then guess the same slips over three rounds.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 18),
      Text('TURN LENGTH', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final s in _times)
          PixelChip(label: '${s}s', selected: _seconds == s, onTap: () => setState(() => _seconds = s)),
      ]),
      if (_players.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('SLIPS EACH', style: PixelFonts.title(pal.textDim, size: 10)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final n in const [3, 4, 5])
            PixelChip(label: '$n', selected: _perPlayer == n, onTap: () => setState(() => _perPlayer = n)),
        ]),
      ],
      const SizedBox(height: 16),
      Text('TEAMS', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      if (_teamPlayers.isEmpty)
        Text('Split into two teams. Add 4+ names on the home screen and the phone picks teams for you.',
            style: PixelFonts.body(pal.text))
      else
        for (final t in teams)
          Text('${t.name}: ${t.players.join(', ')}', style: PixelFonts.body(pal.text)),
      const SizedBox(height: 20),
      PixelButton(
        label: 'Fill the bowl',
        expand: true,
        onTap: () => setState(() {
          _phase = _Phase.adding;
          _focus.requestFocus();
        }),
      ),
    ]);
  }

  Widget _adding(BuildContext context) {
    final pal = context.pal;
    final named = _players.isNotEmpty;
    final prompt = named
        ? '${_players[_writer]}, add ${_perPlayer - _written} more'
        : 'Add your slips, then pass the phone';
    return ListView(children: [
      Text(prompt.toUpperCase(), style: PixelFonts.title(pal.accent, size: 12)),
      const SizedBox(height: 6),
      Text('People, movies, characters, inside jokes. Keep the screen hidden!',
          style: PixelFonts.body(pal.textDim)),
      const SizedBox(height: 12),
      PixelBox(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              key: const Key('fishbowl-slip'),
              controller: _ctrl,
              focusNode: _focus,
              textCapitalization: TextCapitalization.sentences,
              style: PixelFonts.body(pal.text, size: 28),
              cursorColor: pal.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write a slip',
                hintStyle: PixelFonts.body(pal.textDim, size: 28),
              ),
              onSubmitted: (_) => _addSlip(),
            ),
          ),
          PixelButton(label: '+', onTap: _addSlip, size: 16),
        ]),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          _justAdded ? 'Slip in the bowl! ${_slips.length} total' : '${_slips.length} slips in the bowl',
          style: PixelFonts.body(_justAdded ? pal.secondary : pal.text),
        ),
      ),
      const SizedBox(height: 20),
      if (!named)
        PixelButton(
          label: 'Next person',
          expand: true,
          color: pal.secondary,
          onTap: () => setState(() {
            _justAdded = false;
            _phase = _Phase.handoff;
          }),
        ),
      if (!named) const SizedBox(height: 10),
      PixelButton(
        label: 'Add 5 random slips',
        expand: true,
        color: pal.panel,
        textColor: pal.text,
        size: 11,
        onTap: () => _addRandom(5),
      ),
      if (!named || _slips.length >= _minSlips) ...[
        const SizedBox(height: 10),
        PixelButton(
          label: named ? 'Skip the rest, start' : 'Done, start game',
          expand: true,
          size: 11,
          onTap: _slips.length < _minSlips ? null : () => setState(_newGame),
        ),
      ],
      if (_slips.length < _minSlips)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Needs at least $_minSlips slips.',
              textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
        ),
    ]);
  }

  Widget _handoff(BuildContext context) {
    final pal = context.pal;
    final next = _players.isEmpty ? null : _players[_writer];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Center(child: PixelSprite(Sprites.fishbowl, pixel: 10)),
      const SizedBox(height: 20),
      Text(next == null ? 'PASS THE PHONE' : 'PASS TO ${next.toUpperCase()}',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 16)),
      const SizedBox(height: 8),
      Text('${_slips.length} slips in the bowl so far.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: next == null ? 'My turn to write' : "I'm $next",
        expand: true,
        onTap: () => setState(() {
          _justAdded = false;
          _phase = _Phase.adding;
          _focus.requestFocus();
        }),
      ),
    ]);
  }

  Widget _scores(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    return Row(children: [
      for (final t in g.teams)
        Expanded(
          child: PixelBox(
            padding: const EdgeInsets.all(8),
            borderColor: t == g.team ? pal.accent : null,
            child: Column(children: [
              Text(t.name.toUpperCase(), style: PixelFonts.title(pal.textDim, size: 9)),
              const SizedBox(height: 4),
              Text('${t.score}', style: PixelFonts.title(pal.text, size: 18)),
            ]),
          ),
        ),
    ].expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast());
  }

  Widget _roundCard(BuildContext context) {
    final pal = context.pal;
    final r = _game!.round;
    return PixelBox(
      child: Column(children: [
        Text('ROUND ${r.index + 1} OF 3', style: PixelFonts.title(pal.textDim, size: 10)),
        const SizedBox(height: 6),
        Text(r.title.toUpperCase(), style: PixelFonts.title(pal.accent, size: 16)),
        const SizedBox(height: 6),
        Text(r.rule, textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      ]),
    );
  }

  Widget _ready(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final giver = g.team.clueGiver;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _scores(context),
      const SizedBox(height: 14),
      _roundCard(context),
      const Spacer(),
      Text(g.team.name.toUpperCase(), textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 18)),
      const SizedBox(height: 8),
      Text(giver == null ? 'Pick someone to give clues.' : '$giver gives clues. Only your team guesses.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 4),
      Text('${g.slipsLeft} slips left · ${_left.inSeconds}s',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
      const Spacer(),
      PixelButton(label: 'Start turn', expand: true, onTap: _startTurn),
    ]);
  }

  Widget _playing(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PixelBar(value: _left.inMilliseconds / (_seconds * 1000), color: _left.inSeconds < 5 ? pal.primary : null),
      const SizedBox(height: 6),
      Row(children: [
        Text(g.round.title.toUpperCase(), style: PixelFonts.title(pal.accent, size: 10)),
        const Spacer(),
        Text('GOT $_turnGot · ${g.slipsLeft} LEFT', style: PixelFonts.title(pal.textDim, size: 10)),
      ]),
      Expanded(
        child: Center(
          child: Text(
            g.current ?? '',
            key: const Key('fishbowl-current'),
            textAlign: TextAlign.center,
            style: PixelFonts.title(pal.text, size: 22).copyWith(height: 1.5),
          ),
        ),
      ),
      Row(children: [
        Expanded(
          child: PixelButton(
            key: const Key('fishbowl-skip'),
            label: 'Skip',
            expand: true,
            color: pal.panel,
            textColor: pal.text,
            onTap: _skip,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: PixelButton(
            key: const Key('fishbowl-got'),
            label: 'Got it',
            expand: true,
            color: pal.secondary,
            onTap: _gotIt,
          ),
        ),
      ]),
    ]);
  }

  Widget _turnOver(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _scores(context),
      const Spacer(),
      Text("TIME'S UP!", textAlign: TextAlign.center, style: PixelFonts.title(pal.primary, size: 22)),
      const SizedBox(height: 10),
      Text('Got $_turnGot this turn. ${g.slipsLeft} slips still in the bowl.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: 'Pass to ${g.team.name}',
        expand: true,
        onTap: () => setState(() => _phase = _Phase.ready),
      ),
    ]);
  }

  Widget _roundOver(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final next = FishbowlRound.values[g.round.index + 1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _scores(context),
      const Spacer(),
      Text('BOWL EMPTY!', textAlign: TextAlign.center, style: PixelFonts.title(pal.secondary, size: 20)),
      const SizedBox(height: 10),
      Text('All slips go back in. Next round: ${next.title}.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 6),
      Text(next.rule, textAlign: TextAlign.center, style: PixelFonts.body(pal.accent)),
      const SizedBox(height: 6),
      Text('${g.team.name} keeps going with ${_left.inSeconds}s left.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
      const Spacer(),
      PixelButton(label: 'Keep going', expand: true, onTap: _continueRound),
    ]);
  }

  Widget _gameOver(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final w = g.winner;
    final losers = [for (final t in g.teams) if (t != w) t.name];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _scores(context),
      const Spacer(),
      Center(child: PixelSprite(Sprites.crown, pixel: 8)),
      const SizedBox(height: 14),
      Text(w == null ? "IT'S A TIE!" : '${w.name.toUpperCase()} WINS!',
          textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 20)),
      const SizedBox(height: 10),
      Text(w == null ? 'Everybody takes a penalty.' : '${losers.join(' & ')} takes a penalty.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(label: 'Play again, same slips', expand: true, size: 11, onTap: () => _playAgain(sameSlips: true)),
      const SizedBox(height: 10),
      PixelButton(
        label: 'New bowl',
        expand: true,
        size: 11,
        color: pal.panel,
        textColor: pal.text,
        onTap: () => _playAgain(sameSlips: false),
      ),
    ]);
  }
}
