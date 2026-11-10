import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../screens/players_screen.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../../widgets/secret_pass.dart';
import '../../widgets/sprites.dart';
import '../how_to_play.dart';
import 'mafia.dart';

enum _Phase { setup, roles, night, morning, vote, voted, over }

class MafiaScreen extends StatefulWidget {
  const MafiaScreen({super.key});

  @override
  State<MafiaScreen> createState() => _MafiaScreenState();
}

class _MafiaScreenState extends State<MafiaScreen> {
  _Phase _phase = _Phase.setup;
  int? _mafiaCount;
  MafiaGame? _game;
  int _games = 0;
  // Index into the seat list for the roles and night passes.
  int _seat = 0;
  List<String> _order = const [];
  bool? _check;
  String? _victim;
  String? _votedOut;

  List<String> get _players => context.app.players;

  /// The most Mafia that still leaves room for the Doctor, Detective and a
  /// couple of villagers.
  int get _maxMafia => ((_players.length - 3) ~/ 2).clamp(1, 4);
  int get _mafia => (_mafiaCount ?? defaultMafiaCount(_players.length)).clamp(1, _maxMafia);

  void _start() {
    Fx.start();
    setState(() {
      _game = MafiaGame(_players, mafiaCount: _mafia);
      _games++;
      _order = _game!.players;
      _seat = 0;
      _phase = _Phase.roles;
    });
  }

  void _nextPass(_Phase after) {
    Fx.close();
    setState(() {
      _check = null;
      if (_seat < _order.length - 1) {
        _seat++;
      } else {
        _phase = after;
        if (after == _Phase.morning) {
          _victim = _game!.resolveNight();
          _victim == null ? Fx.correct() : Fx.boom();
        }
      }
    });
  }

  void _finish() {
    _game!.winner == MafiaSide.town ? Fx.win() : Fx.lose();
    setState(() => _phase = _Phase.over);
  }

  void _toNight() {
    setState(() {
      _order = _game!.living;
      _seat = 0;
      _phase = _Phase.night;
    });
  }

  @override
  Widget build(BuildContext context) {
    final named = _players.length >= 5;
    return PixelScaffold(
      title: 'Mafia',
      onHelp: () => showHowToPlay(context, 'mafia'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: !named && _game == null
            ? _needNames(context)
            : switch (_phase) {
                _Phase.setup => _setup(context),
                _Phase.roles => SecretPass(
                    key: ValueKey('mafia-role-$_games-$_seat'),
                    to: _order[_seat],
                    icon: Sprites.moon,
                    hint: 'Check your secret role.',
                    secret: _roleCard,
                  ),
                _Phase.night => SecretPass(
                    key: ValueKey('mafia-night-$_games-${_game!.night}-$_seat'),
                    to: _order[_seat],
                    icon: Sprites.moon,
                    hint: 'Everyone taps a name at night, so nobody can tell who has a power.',
                    secret: _nightTurn,
                  ),
                _Phase.morning => _morning(context),
                _Phase.vote => _vote(context),
                _Phase.voted => _voted(context),
                _Phase.over => _over(context),
              },
      ),
    );
  }

  Widget _needNames(BuildContext context) {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Center(child: PixelSprite(Sprites.moon, pixel: 10)),
      const SizedBox(height: 20),
      Text('MAFIA NEEDS 5+ NAMES', textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 14)),
      const SizedBox(height: 10),
      Text('The phone deals secret roles and runs the night, so it needs to know who is playing.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: 'Add names',
        expand: true,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PlayersScreen()))
            .then((_) => setState(() {})),
      ),
    ]);
  }

  Widget _setup(BuildContext context) {
    final pal = context.pal;
    final n = _players.length;
    final special = n >= 6 ? 'a Doctor and a Detective' : 'a Doctor';
    return ListView(children: [
      Center(child: PixelSprite(Sprites.moon, pixel: 9)),
      const SizedBox(height: 14),
      Text('The phone deals secret roles and runs the night. No narrator needed: '
          'everyone takes a secret turn each night.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 18),
      Text('MAFIA', style: PixelFonts.title(pal.textDim, size: 10)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (var m = 1; m <= _maxMafia; m++)
          PixelChip(label: '$m', selected: _mafia == m, onTap: () => setState(() => _mafiaCount = m)),
      ]),
      const SizedBox(height: 12),
      Text('$n players: $_mafia Mafia, $special, and the rest Villagers.', style: PixelFonts.body(pal.text)),
      const SizedBox(height: 16),
      for (final r in MafiaRole.values)
        if (r != MafiaRole.detective || n >= 6)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${r.title}: ${r.goal}', style: PixelFonts.body(pal.textDim)),
          ),
      const SizedBox(height: 16),
      PixelButton(label: 'Deal roles', expand: true, onTap: _start),
    ]);
  }

  Widget _roleCard(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final me = _order[_seat];
    final role = g.roles[me]!;
    final team = [for (final m in g.mafia) if (m != me) m];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      PixelBox(
        borderColor: role == MafiaRole.mafia ? pal.primary : pal.secondary,
        child: Column(children: [
          Text('YOU ARE', style: PixelFonts.title(pal.textDim, size: 11)),
          const SizedBox(height: 8),
          Text(role.title.toUpperCase(),
              key: const Key('mafia-role'),
              style: PixelFonts.title(role == MafiaRole.mafia ? pal.primary : pal.secondary, size: 22)),
          const SizedBox(height: 12),
          Text(role.goal, textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
          if (role == MafiaRole.mafia && team.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Your partner${team.length == 1 ? '' : 's'}: ${team.join(', ')}',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.primary)),
          ],
        ]),
      ),
      const Spacer(),
      PixelButton(
        label: _seat == _order.length - 1 ? 'Hide, night falls' : 'Hide and pass',
        expand: true,
        onTap: () => _seat == _order.length - 1
            ? setState(() {
                Fx.close();
                _toNight();
              })
            : _nextPass(_Phase.night),
      ),
    ]);
  }

  Widget _nightTurn(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final me = _order[_seat];
    final role = g.roles[me]!;
    if (_check != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        Text(_check! ? 'MAFIA!' : 'NOT MAFIA',
            textAlign: TextAlign.center,
            style: PixelFonts.title(_check! ? pal.primary : pal.secondary, size: 24)),
        const SizedBox(height: 10),
        Text('Keep it to yourself.', textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
        const Spacer(),
        PixelButton(label: 'Hide and pass', expand: true, onTap: () => _nextPass(_Phase.morning)),
      ]);
    }
    final prompt = switch (role) {
      MafiaRole.mafia => 'Mafia: who do you eliminate?',
      MafiaRole.doctor => 'Doctor: who do you save?',
      MafiaRole.detective => 'Detective: who do you check?',
      MafiaRole.villager => 'Villager: tap any name. It does nothing.',
    };
    final targets = [
      for (final p in g.living)
        if (role == MafiaRole.doctor || role == MafiaRole.villager || p != me)
          if (role != MafiaRole.mafia || g.roles[p] != MafiaRole.mafia) p,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('NIGHT ${g.night}', style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 8),
      Text(prompt, style: PixelFonts.title(pal.accent, size: 13).copyWith(height: 1.5)),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in targets)
              PixelChip(
                label: p,
                onTap: () {
                  final result = g.act(me, p);
                  if (result != null) {
                    setState(() => _check = result);
                  } else {
                    _nextPass(_Phase.morning);
                  }
                },
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _morning(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final over = g.winner != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Text('MORNING', textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 20)),
      const SizedBox(height: 14),
      Text(
        _victim == null
            ? 'Everyone wakes up. Nobody was eliminated last night!'
            : '$_victim was eliminated in the night. They were a ${g.roles[_victim]!.title}.',
        textAlign: TextAlign.center,
        style: PixelFonts.body(pal.text, size: 28),
      ),
      const Spacer(),
      PixelButton(
        label: over ? 'See who won' : 'Discuss and vote',
        expand: true,
        onTap: over ? _finish : () => setState(() => _phase = _Phase.vote),
      ),
    ]);
  }

  Widget _vote(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('DAY ${g.night - 1}', style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 8),
      Text('Talk it out, then vote by pointing on 3. Tap who the town voted out.',
          style: PixelFonts.body(pal.text)),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in g.living)
              PixelChip(
                label: p,
                onTap: () {
                  g.voteOut(p);
                  Fx.boom();
                  setState(() {
                    _votedOut = p;
                    _phase = _Phase.voted;
                  });
                },
              ),
          ]),
        ),
      ),
      PixelButton(
        label: 'No one, skip the vote',
        expand: true,
        size: 11,
        color: pal.panel,
        textColor: pal.text,
        onTap: _toNight,
      ),
    ]);
  }

  Widget _voted(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final role = g.roles[_votedOut]!;
    final over = g.winner != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Text('${_votedOut!.toUpperCase()} WAS', textAlign: TextAlign.center, style: PixelFonts.title(pal.textDim, size: 12)),
      const SizedBox(height: 10),
      Text(role == MafiaRole.mafia ? 'MAFIA!' : 'A ${role.title.toUpperCase()}',
          textAlign: TextAlign.center,
          style: PixelFonts.title(role == MafiaRole.mafia ? pal.primary : pal.secondary, size: 22)),
      const Spacer(),
      PixelButton(
        label: over ? 'See who won' : 'Night falls',
        expand: true,
        onTap: over ? _finish : _toNight,
      ),
    ]);
  }

  Widget _over(BuildContext context) {
    final pal = context.pal;
    final g = _game!;
    final town = g.winner == MafiaSide.town;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(town ? 'TOWN WINS!' : 'MAFIA WINS!',
          textAlign: TextAlign.center, style: PixelFonts.title(town ? pal.secondary : pal.primary, size: 22)),
      const SizedBox(height: 8),
      Text(town ? 'The Mafia take a penalty.' : 'Everyone in town takes a penalty.',
          textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const SizedBox(height: 14),
      Expanded(
        child: ListView(children: [
          for (final p in g.players)
            Text('$p: ${g.roles[p]!.title}${g.alive.contains(p) ? '' : ' (out)'}',
                style: PixelFonts.body(g.roles[p] == MafiaRole.mafia ? pal.primary : pal.text)),
        ]),
      ),
      PixelButton(
        label: 'Play again',
        expand: true,
        onTap: () => setState(() {
          _game = null;
          _phase = _Phase.setup;
        }),
      ),
    ]);
  }
}
