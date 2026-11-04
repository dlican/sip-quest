import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/motion.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../../widgets/playing_card.dart';
import '../../widgets/sprites.dart';
import '../cards.dart';
import 'horse_race.dart';

class _Bet {
  _Bet(this.suit, this.sips);
  Suit suit;
  int sips;
}

enum _Phase { bets, race, results }

class HorseRacingScreen extends StatefulWidget {
  const HorseRacingScreen({super.key});

  @override
  State<HorseRacingScreen> createState() => _HorseRacingScreenState();
}

class _HorseRacingScreenState extends State<HorseRacingScreen> {
  _Phase _phase = _Phase.bets;
  final Map<String, _Bet> _bets = {};
  HorseRace _race = HorseRace();
  String _log = 'And they\'re off!';
  Timer? _auto;

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  Color _suitColor(Suit s) {
    final p = context.pal;
    return switch (s) {
      Suit.hearts => p.primary,
      Suit.diamonds => p.accent,
      Suit.clubs => p.secondary,
      Suit.spades => p.text,
    };
  }

  void _startRace() {
    setState(() {
      _race = HorseRace();
      _log = 'And they\'re off!';
      _phase = _Phase.race;
    });
  }

  void _step() {
    final events = _race.step();
    Fx.flip();
    setState(() {
      if (events.isNotEmpty) {
        _log = events
            .map((e) => e.checkpoint
                ? 'Checkpoint! ${e.card.name}: ${e.suit.label} falls back.'
                : '${e.card.name}: ${e.suit.label} gallops ahead.')
            .join('\n');
      }
    });
    if (_race.isOver) {
      _auto?.cancel();
      _auto = null;
      Fx.win();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _phase = _Phase.results);
      });
    }
  }

  void _toggleAuto() {
    setState(() {
      if (_auto != null) {
        _auto!.cancel();
        _auto = null;
      } else {
        _auto = Timer.periodic(const Duration(milliseconds: 750), (_) => _step());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PixelScaffold(
      title: 'Horse Racing',
      onHelp: () => showHowToPlay(context, 'horse_racing'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: PhaseSwitcher(
          child: KeyedSubtree(
            key: ValueKey(_phase),
            child: switch (_phase) {
              _Phase.bets => _betsView(context),
              _Phase.race => _raceView(context),
              _Phase.results => _resultsView(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _betsView(BuildContext context) {
    final pal = context.pal;
    final players = context.app.players;
    for (final p in players) {
      _bets.putIfAbsent(p, () => _Bet(Suit.values[Random().nextInt(4)], 2));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PixelBox(
        child: Text(
          'Pick a horse and bet sips. If your horse wins, hand out double. If not, drink your bet.',
          style: PixelFonts.body(pal.text, size: 22),
        ),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: players.isEmpty
            ? Center(
                child: Text('No players added. Call your bets out loud!',
                    textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)))
            : ListView(children: [
                for (final p in players) _betRow(context, p, _bets[p]!),
              ]),
      ),
      const SizedBox(height: 12),
      PixelButton(label: 'Start race', expand: true, onTap: _startRace),
    ]);
  }

  Widget _betRow(BuildContext context, String player, _Bet bet) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelBox(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(player, style: PixelFonts.body(pal.text, size: 28))),
            GestureDetector(
              onTap: () => setState(() => bet.sips = max(1, bet.sips - 1)),
              child: Text(' - ', style: PixelFonts.title(pal.primary, size: 16)),
            ),
            Text('${bet.sips} sips', style: PixelFonts.title(pal.accent, size: 11)),
            GestureDetector(
              onTap: () => setState(() => bet.sips = min(10, bet.sips + 1)),
              child: Text(' + ', style: PixelFonts.title(pal.secondary, size: 16)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (final s in Suit.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => bet.suit = s),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: bet.suit == s ? pal.cardFace : pal.bg,
                      border: Border.all(color: bet.suit == s ? _suitColor(s) : pal.panel, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: PixelSprite(suitSprite(s), pixel: 3),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _raceView(BuildContext context) {
    final pal = context.pal;
    final r = _race;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, box) {
        // Lane layout: suit badge, then start cell + side-card cells + finish.
        const badge = 34.0;
        final cells = r.finish + 1;
        final cell = (box.maxWidth - badge) / cells;
        return Column(children: [
          // Side cards above the track, one per checkpoint.
          Row(children: [
            const SizedBox(width: badge),
            SizedBox(width: cell),
            for (var i = 0; i < r.trackLength; i++)
              SizedBox(
                width: cell,
                child: Center(
                  child: i < r.sideRevealed
                      ? CardFace(card: r.sideCards[i], width: cell * 0.8)
                      : CardBack(width: cell * 0.8),
                ),
              ),
            SizedBox(width: cell, child: Center(child: PixelSprite(Sprites.flag, pixel: max(2, cell / 10)))),
          ]),
          const SizedBox(height: 10),
          for (final s in Suit.values)
            Container(
              height: cell * 1.6,
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Container(
                  width: badge - 4,
                  height: badge - 4,
                  margin: const EdgeInsets.only(right: 4),
                  color: pal.cardFace,
                  alignment: Alignment.center,
                  child: PixelSprite(suitSprite(s), pixel: 3),
                ),
                Expanded(
                  child: Stack(clipBehavior: Clip.none, children: [
                    // Lane cells
                    Row(children: [
                      for (var i = 0; i < cells; i++)
                        Container(
                          width: cell,
                          decoration: BoxDecoration(
                            color: i == cells - 1 ? pal.cardBlack : (i.isEven ? pal.panel : pal.bgAlt),
                            border: Border(right: BorderSide(color: pal.bg, width: 2)),
                          ),
                        ),
                    ]),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      left: min(r.position[s]!, r.finish) * cell + (cell - min(cell * 1.3, 64)) / 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: PixelSprite(
                          Sprites.horse,
                          pixel: min(cell * 1.3, 64) / 12,
                          tint: {'A': _suitColor(s), 'T': pal.cardBlack},
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
        ]);
      }),
      const SizedBox(height: 14),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (r.lastCard != null) FlippingCard(card: r.lastCard!, width: 90) else CardBack(width: 90),
          const SizedBox(width: 16),
          Expanded(
            child: PixelBox(
              child: Text(r.isOver ? '${r.winner!.label} WINS!' : _log,
                  style: r.isOver ? PixelFonts.title(pal.accent, size: 14) : PixelFonts.body(pal.text, size: 22)),
            ),
          ),
        ]),
      ),
      Row(children: [
        Expanded(
          child: PixelButton(
            label: _auto == null ? 'Auto' : 'Stop',
            color: pal.accent,
            expand: true,
            onTap: r.isOver ? null : _toggleAuto,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: PixelButton(label: 'Flip card', expand: true, onTap: r.isOver || _auto != null ? null : _step),
        ),
      ]),
    ]);
  }

  Widget _resultsView(BuildContext context) {
    final pal = context.pal;
    final w = _race.winner!;
    final players = context.app.players;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 10),
      Center(
        child: PixelSprite(Sprites.horse, pixel: 10, tint: {'A': _suitColor(w), 'T': pal.cardBlack}),
      ),
      const SizedBox(height: 14),
      Text('${w.label.toUpperCase()} WIN!', textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 20)),
      const SizedBox(height: 16),
      Expanded(
        child: ListView(children: [
          for (final p in players)
            if (_bets[p] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PixelBox(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _bets[p]!.suit == w
                        ? '$p hands out ${_bets[p]!.sips * 2} sips'
                        : '$p drinks ${_bets[p]!.sips}',
                    style: PixelFonts.body(_bets[p]!.suit == w ? pal.secondary : pal.text, size: 26),
                  ),
                ),
              ),
          if (players.isEmpty)
            Text('Winners hand out double their bet. Everyone else drinks theirs.',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
        ]),
      ),
      PixelButton(label: 'New race', expand: true, onTap: () => setState(() => _phase = _Phase.bets)),
    ]);
  }
}
