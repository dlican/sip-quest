import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  _Bet(this.suit);
  Suit suit;
  int sips = 2;
  int shots = 0;
}

/// "3 sips + 1 shot", or "nothing" for an empty bet.
String betAmount(int sips, int shots) {
  final parts = [
    if (sips > 0) '$sips sip${sips == 1 ? '' : 's'}',
    if (shots > 0) '$shots shot${shots == 1 ? '' : 's'}',
  ];
  return parts.isEmpty ? 'nothing' : parts.join(' + ');
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
    _setLandscape(false);
    super.dispose();
  }

  /// The track needs width, so the race itself runs sideways.
  void _setLandscape(bool on) {
    SystemChrome.setPreferredOrientations(
      on
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
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
    _setLandscape(true);
    setState(() {
      _race = HorseRace();
      _log = 'And they\'re off!';
      _phase = _Phase.race;
    });
  }

  void _step() {
    final events = _race.step();
    Fx.flip();
    if (events.any((e) => e.checkpoint)) Fx.pass();
    setState(() {
      if (events.isNotEmpty) {
        _log = events
            .map(
              (e) => e.checkpoint
                  ? 'SETBACK! ${e.card.name} flips. ${e.suit.label} moves back one.'
                  : '${e.card.name}: ${e.suit.label} gallops ahead.',
            )
            .join('\n');
      }
    });
    if (_race.isOver) {
      _auto?.cancel();
      _auto = null;
      Fx.win();
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _setLandscape(false);
        setState(() => _phase = _Phase.results);
      });
    }
  }

  void _toggleAuto() {
    setState(() {
      if (_auto != null) {
        _auto!.cancel();
        _auto = null;
      } else {
        _auto = Timer.periodic(
          const Duration(milliseconds: 750),
          (_) => _step(),
        );
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
      _bets.putIfAbsent(p, () => _Bet(Suit.values[Random().nextInt(4)]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelBox(
          child: Text(
            'Pick a horse and bet sips and shots. If your horse wins, hand out double. If not, drink your bet.',
            style: PixelFonts.body(pal.text, size: 22),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: players.isEmpty
              ? Center(
                  child: Text(
                    'No players added. Call your bets out loud!',
                    textAlign: TextAlign.center,
                    style: PixelFonts.body(pal.textDim),
                  ),
                )
              : ListView(
                  children: [
                    for (final p in players) _betRow(context, p, _bets[p]!),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        PixelButton(label: 'Start race', expand: true, onTap: _startRace),
      ],
    );
  }

  Widget _stepper(
    String unit,
    int value,
    Color color,
    void Function(int) set,
    int maxValue,
  ) {
    final pal = context.pal;
    Widget tap(String label, Color c, int next) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => set(next.clamp(0, maxValue))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: PixelFonts.title(c, size: 16)),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tap('-', pal.primary, value - 1),
        SizedBox(
          width: 84,
          child: Text(
            '$value $unit${value == 1 ? '' : 's'}',
            textAlign: TextAlign.center,
            style: PixelFonts.title(color, size: 11),
          ),
        ),
        tap('+', pal.secondary, value + 1),
      ],
    );
  }

  Widget _betRow(BuildContext context, String player, _Bet bet) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelBox(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player, style: PixelFonts.body(pal.text, size: 28)),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                _stepper('sip', bet.sips, pal.accent, (v) => bet.sips = v, 10),
                _stepper(
                  'shot',
                  bet.shots,
                  pal.primary,
                  (v) => bet.shots = v,
                  5,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final s in Suit.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => bet.suit = s),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          // Card-face tiles keep the black suits readable on dark styles.
                          color: pal.cardFace.withValues(
                            alpha: bet.suit == s ? 1 : 0.4,
                          ),
                          border: Border.all(
                            color: bet.suit == s ? _suitColor(s) : pal.panel,
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: PixelSprite(suitSprite(s), pixel: 3),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A flipped setback card, sideways. Full card art is unreadable this small,
  /// so it shows just the rank and the suit that falls back.
  Widget _setbackFace(PlayingCard card, double height) {
    final pal = context.pal;
    return Container(
      width: height / kCardRatio,
      height: height,
      decoration: BoxDecoration(
        color: pal.cardFace,
        border: Border.all(color: _suitColor(card.suit), width: 2),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.rankLabel,
                style: PixelFonts.title(
                  card.suit.isRed ? pal.cardRed : pal.cardBlack,
                  size: 12,
                ),
              ),
              const SizedBox(width: 3),
              PixelSprite(suitSprite(card.suit), pixel: 2),
            ],
          ),
        ),
      ),
    );
  }

  /// Setback cards lie sideways above the lanes, one per checkpoint. Once every
  /// horse has passed one, it flips and that suit's horse moves back a step.
  Widget _track(BuildContext context, double width, double height) {
    final pal = context.pal;
    final r = _race;
    const badge = 34.0;
    final cells = r.finish + 1;
    final cell = (width - badge) / cells;
    // A sideways card is 1/kCardRatio wide for every 1 tall.
    final cardH = min(cell * 0.92 * kCardRatio, height * 0.22);
    final sideRowH = cardH + 10;
    final laneH = max(20.0, (height - sideRowH - 4 * 4) / 4);
    final horse = min(min(cell * 1.3, laneH * 0.95), 64.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: sideRowH,
          child: Row(
            children: [
              const SizedBox(width: badge),
              SizedBox(width: cell),
              for (var i = 0; i < r.trackLength; i++)
                SizedBox(
                  width: cell,
                  child: Center(
                    child: i < r.sideRevealed
                        ? _setbackFace(r.sideCards[i], cardH)
                        : RotatedBox(
                            quarterTurns: 1,
                            child: CardBack(width: cardH),
                          ),
                  ),
                ),
              SizedBox(
                width: cell,
                child: Center(
                  child: PixelSprite(
                    Sprites.flag,
                    pixel: max(2, min(cell, sideRowH) / 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final s in Suit.values)
          Container(
            height: laneH,
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: badge - 4,
                  height: min(badge - 4, laneH),
                  margin: const EdgeInsets.only(right: 4),
                  color: pal.cardFace,
                  alignment: Alignment.center,
                  child: PixelSprite(suitSprite(s), pixel: 3),
                ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < cells; i++)
                            Container(
                              width: cell,
                              decoration: BoxDecoration(
                                color: i == cells - 1
                                    ? pal.cardBlack
                                    : (i.isEven ? pal.panel : pal.bgAlt),
                                border: Border(
                                  right: BorderSide(color: pal.bg, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        left:
                            min(r.position[s]!, r.finish) * cell +
                            (cell - horse) / 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: PixelSprite(
                            Sprites.horse,
                            pixel: horse / 12,
                            tint: {'A': _suitColor(s), 'T': pal.cardBlack},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _raceLog(BuildContext context, {required double cardWidth}) {
    final pal = context.pal;
    final r = _race;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.lastCard != null)
          FlippingCard(card: r.lastCard!, width: cardWidth)
        else
          CardBack(width: cardWidth),
        const SizedBox(width: 12),
        Expanded(
          child: PixelBox(
            padding: const EdgeInsets.all(10),
            child: Text(
              r.isOver ? '${r.winner!.label} WINS!' : _log,
              style: r.isOver
                  ? PixelFonts.title(pal.accent, size: 14)
                  : PixelFonts.body(pal.text, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  /// Side by side in portrait; stacked in the narrow landscape side panel.
  Widget _raceButtons(BuildContext context, {bool stacked = false}) {
    final pal = context.pal;
    final r = _race;
    final auto = PixelButton(
      label: _auto == null ? 'Auto' : 'Stop',
      color: pal.accent,
      size: 12,
      expand: true,
      onTap: r.isOver ? null : _toggleAuto,
    );
    final flip = PixelButton(
      label: 'Flip card',
      size: 12,
      expand: true,
      onTap: r.isOver || _auto != null ? null : _step,
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [flip, const SizedBox(height: 8), auto],
      );
    }
    return Row(
      children: [
        Expanded(child: auto),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: flip),
      ],
    );
  }

  Widget _raceView(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) =>
                  _track(context, box.maxWidth, box.maxHeight),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 270,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _raceLog(context, cardWidth: 64),
                  ),
                ),
                const SizedBox(height: 8),
                _raceButtons(context, stacked: true),
              ],
            ),
          ),
        ],
      );
    }
    // Portrait fallback, e.g. while the phone is still turning.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) =>
              _track(context, box.maxWidth, box.maxWidth * 0.9),
        ),
        const SizedBox(height: 14),
        Expanded(child: _raceLog(context, cardWidth: 90)),
        _raceButtons(context),
      ],
    );
  }

  Widget _resultsView(BuildContext context) {
    final pal = context.pal;
    final w = _race.winner!;
    final players = context.app.players;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: PixelSprite(
            Sprites.horse,
            pixel: 10,
            tint: {'A': _suitColor(w), 'T': pal.cardBlack},
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${w.label.toUpperCase()} WIN!',
          textAlign: TextAlign.center,
          style: PixelFonts.title(pal.accent, size: 20),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              for (final p in players)
                if (_bets[p] case final bet?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PixelBox(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        bet.suit == w
                            ? '$p hands out ${betAmount(bet.sips * 2, bet.shots * 2)}'
                            : '$p drinks ${betAmount(bet.sips, bet.shots)}',
                        style: PixelFonts.body(
                          bet.suit == w ? pal.secondary : pal.text,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
              if (players.isEmpty)
                Text(
                  'Winners hand out double their sips and shots. Everyone else drinks theirs.',
                  textAlign: TextAlign.center,
                  style: PixelFonts.body(pal.text),
                ),
            ],
          ),
        ),
        PixelButton(
          label: 'New race',
          expand: true,
          onTap: () => setState(() => _phase = _Phase.bets),
        ),
      ],
    );
  }
}
