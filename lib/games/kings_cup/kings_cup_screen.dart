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
import 'kings_cup_game.dart';

class KingsCupScreen extends StatefulWidget {
  const KingsCupScreen({super.key});

  @override
  State<KingsCupScreen> createState() => _KingsCupScreenState();
}

class _KingsCupScreenState extends State<KingsCupScreen> {
  late KingsCupGame _game;
  Map<int, KingsRule>? _customRules;
  bool _shuffling = true;
  bool _started = false;

  /// Each Draw re-runs a quick riffle, then deals the card off the deck.
  /// The game state moves on immediately; this only drives the visuals.
  bool _reshuffling = false;
  bool _dealing = false;
  int _drawId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _newGame();
    }
  }

  void _newGame() {
    _game = KingsCupGame(players: context.app.players, rules: _customRules);
    _shuffling = true;
    _reshuffling = false;
    _dealing = false;
    Fx.shuffle();
  }

  /// Tapping again mid-animation draws the next card straight away.
  void _draw() {
    if (_shuffling) return;
    setState(() {
      final c = _game.draw();
      if (c == null) return;
      _drawId++;
      _reshuffling = true;
      _dealing = false;
      Fx.shuffle();
    });
  }

  void _reshuffled(int id) {
    if (id != _drawId || !mounted) return;
    setState(() {
      _reshuffling = false;
      _dealing = true;
    });
    Fx.deal();
  }

  void _dealt(int id) {
    if (id != _drawId || !mounted) return;
    setState(() => _dealing = false);
    final c = _game.current!;
    c.rank == 13 ? Fx.coin() : Fx.flip();
    if (_game.status == KingsCupStatus.fourthKing) Fx.boom();
  }

  Future<void> _writeRule() async {
    final rule = await showPixelDialog<String>(
      context: context,
      builder: (_) => const _TextPrompt(title: 'New house rule', hint: 'e.g. No saying "drink"'),
    );
    if (rule != null) setState(() => _game.addHouseRule(rule));
  }

  Future<void> _editRules() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RulesEditor(
          rules: _game.rules,
          onChanged: (rank, rule) => setState(() {
            _game.rules[rank] = rule;
            _customRules = Map.of(_game.rules);
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final g = _game;
    return PixelScaffold(
      title: "King's Cup",
      onHelp: () => showHowToPlay(context, 'kings_cup'),
      actions: [PixelIconButton(icon: Icons.menu_book, tooltip: 'Edit rules', onTap: _editRules)],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  PixelSprite(
                    i < g.kingsDrawn ? Sprites.crown : Sprites.crownEmpty,
                    pixel: 3,
                    tint: {'D': pal.textDim.withValues(alpha: 0.35)},
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                Text('${g.deck.remaining}', style: PixelFonts.title(pal.accent, size: 14)),
                const SizedBox(width: 6),
                Text('cards left', style: PixelFonts.body(pal.textDim, size: 22)),
              ],
            ),
            if (g.hasPlayers) ...[const SizedBox(height: 8), _TurnBanner(game: g)],
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = min(box.maxWidth * 0.62, box.maxHeight * 0.92 * kCardRatio);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: g.status == KingsCupStatus.playing ? _draw : null,
                    child: Center(
                      child: _shuffling
                          ? _ShuffleDeck(
                              width: w * 0.75,
                              onDone: () {
                                setState(() => _shuffling = false);
                                Fx.select();
                              },
                            )
                          : _reshuffling
                          ? _ShuffleDeck(
                              key: ValueKey('shuffle$_drawId'),
                              width: w * 0.75,
                              cycles: 1,
                              onDone: () => _reshuffled(_drawId),
                            )
                          : _dealing
                          ? _DealCard(
                              key: ValueKey('deal$_drawId'),
                              card: g.current!,
                              width: w,
                              onDone: () => _dealt(_drawId),
                            )
                          : g.current == null
                          ? _DeckPile(width: w * 0.75, count: g.deck.remaining)
                          : CardFace(card: g.current!, width: w),
                    ),
                  );
                },
              ),
            ),
            _RulePanel(
              game: g,
              shuffling: _shuffling || _reshuffling || _dealing,
              onWriteRule: _writeRule,
            ),
            const SizedBox(height: 12),
            if (g.status == KingsCupStatus.playing)
              PixelButton(
                label: _shuffling ? 'Shuffling...' : (g.current == null ? 'Draw first card' : 'Draw'),
                expand: true,
                onTap: _shuffling ? null : _draw,
              )
            else
              PixelButton(label: 'New game', expand: true, color: pal.secondary, onTap: () => setState(_newGame)),
          ],
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.game});
  final KingsCupGame game;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final who = game.status == KingsCupStatus.playing ? game.nextPlayer : game.currentPlayer;
    return Row(
      children: [
        Text(
          game.status == KingsCupStatus.playing ? 'UP NEXT ' : 'LAST ',
          style: PixelFonts.title(pal.textDim, size: 10),
        ),
        Text(who ?? '', style: PixelFonts.body(pal.secondary, size: 26)),
        const Spacer(),
        if (game.questionMaster != null) ...[
          Text('Q.Q. ', style: PixelFonts.title(pal.textDim, size: 10)),
          Text(game.questionMaster!, style: PixelFonts.body(pal.accent, size: 26)),
        ],
        if (game.thumbMaster != null) ...[
          const SizedBox(width: 10),
          Text('THUMB ', style: PixelFonts.title(pal.textDim, size: 10)),
          Text(game.thumbMaster!, style: PixelFonts.body(pal.primary, size: 26)),
        ],
      ],
    );
  }
}

class _RulePanel extends StatelessWidget {
  const _RulePanel({required this.game, required this.shuffling, required this.onWriteRule});
  final KingsCupGame game;
  final bool shuffling;
  final VoidCallback onWriteRule;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final c = game.current;

    late final Widget content;
    if (shuffling && c != null) {
      content = Text('Shuffling... dealing a card.', style: PixelFonts.body(pal.textDim));
    } else if (game.status == KingsCupStatus.fourthKing) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4TH KING!', style: PixelFonts.title(pal.primary, size: 18)),
          const SizedBox(height: 8),
          Text(
            '${game.currentPlayer ?? 'Whoever drew it'} drinks the whole King\'s Cup. Game over.',
            style: PixelFonts.body(pal.text),
          ),
        ],
      );
    } else if (c == null) {
      content = Text(
        shuffling ? 'Shuffling the deck...' : 'Place a cup in the middle. Spread the cards around it. Tap to draw.',
        style: PixelFonts.body(pal.text),
      );
    } else {
      final rule = game.currentRule;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.rankLabel, style: PixelFonts.title(pal.accent, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(rule.title.toUpperCase(), style: PixelFonts.title(pal.primary, size: 15))),
            ],
          ),
          const SizedBox(height: 8),
          Text(rule.description, style: PixelFonts.body(pal.text)),
          if (c.rank == 13)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${4 - game.kingsDrawn} king(s) left in the deck.',
                style: PixelFonts.body(pal.accent, size: 22),
              ),
            ),
          if (c.rank == 11)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PixelButton(label: 'Write the rule', size: 11, color: pal.accent, onTap: onWriteRule),
            ),
          if (game.status == KingsCupStatus.deckEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('That was the last card!', style: PixelFonts.body(pal.accent, size: 22)),
            ),
        ],
      );
    }

    return PixelBox(
      child: AnimatedSize(
        duration: Motion.medium,
        curve: Motion.enter,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: Motion.medium,
              switchInCurve: Motion.enter,
              switchOutCurve: Motion.exit,
              layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: KeyedSubtree(key: ValueKey('${game.drawn.length}${game.status}$shuffling'), child: content),
            ),
            if (game.houseRules.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('HOUSE RULES', style: PixelFonts.title(pal.textDim, size: 9)),
              for (final r in game.houseRules) Text('* $r', style: PixelFonts.body(pal.secondary, size: 22)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckPile extends StatelessWidget {
  const _DeckPile({required this.width, required this.count});
  final double width;
  final int count;

  @override
  Widget build(BuildContext context) {
    final layers = min(6, max(1, count ~/ 8));
    return SizedBox(
      width: width + layers * 3,
      height: width / kCardRatio + layers * 3,
      child: Stack(
        children: [
          for (var i = 0; i < layers; i++)
            Positioned(
              left: i * 3.0,
              top: (layers - i) * 3.0,
              child: CardBack(width: width),
            ),
        ],
      ),
    );
  }
}

/// Riffle shuffle: two halves fan out and interleave, three times.
class _ShuffleDeck extends StatefulWidget {
  const _ShuffleDeck({super.key, required this.width, required this.onDone, this.cycles = 3});
  final double width;
  final VoidCallback onDone;
  final int cycles;

  @override
  State<_ShuffleDeck> createState() => _ShuffleDeckState();
}

class _ShuffleDeckState extends State<_ShuffleDeck> with SingleTickerProviderStateMixin {
  static const _cards = 10;
  late final int _cycles = widget.cycles;
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (_cycles == 1 ? 520 : 650) * _cycles),
        )
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    return SizedBox(
      width: w * 2.2,
      height: w / kCardRatio + 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final cycleT = (_c.value * _cycles) % 1.0;
          final spread = Curves.easeInOutSine.transform(sin(cycleT * pi));
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _cards; i++)
                Transform.translate(
                  offset: Offset(
                    (i.isEven ? -1 : 1) * spread * w * 0.55,
                    -i * 2.0 + (i.isEven ? 0 : spread * -10),
                  ),
                  child: Transform.rotate(
                    angle: (i.isEven ? -1 : 1) * spread * 0.12,
                    child: CardBack(width: w),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The top card slides off the deck, swings to the middle and turns over.
class _DealCard extends StatefulWidget {
  const _DealCard({super.key, required this.card, required this.width, required this.onDone});
  final PlayingCard card;
  final double width;
  final VoidCallback onDone;

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / kCardRatio;
    final pile = w * 0.75;
    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          // 0-0.55: slide along an arc from the deck. 0.45-1: turn over.
          final travel = Curves.easeOutCubic.transform((v / 0.55).clamp(0.0, 1.0));
          final turn = Curves.easeInOutCubic.transform(((v - 0.45) / 0.55).clamp(0.0, 1.0));
          final from = Offset(-w * 0.62, h * 0.32);
          final pos = Offset.lerp(from, Offset.zero, travel)! + Offset(0, -h * 0.12 * sin(travel * pi));
          final angle = pi * (1 - turn);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // The deck it came from, fading away as the card lands.
              Transform.translate(
                offset: from + Offset(0, (h - pile / kCardRatio) / 2),
                child: Opacity(
                  opacity: (1 - turn).clamp(0.0, 1.0),
                  child: Transform.rotate(angle: -0.08, child: CardBack(width: pile)),
                ),
              ),
              Transform.translate(
                offset: pos,
                child: Transform.rotate(
                  angle: -0.35 * (1 - travel),
                  child: Transform.scale(
                    scale: 0.75 + 0.25 * travel,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: m,
                      child: angle < pi / 2
                          ? CardFace(card: widget.card, width: w)
                          : CardBack(width: w),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({required this.title, required this.hint, this.initial = ''});
  final String title;
  final String hint;
  final String initial;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PixelBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title.toUpperCase(), style: PixelFonts.title(pal.accent, size: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: null,
              style: PixelFonts.body(pal.text),
              cursorColor: pal.accent,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: PixelFonts.body(pal.textDim),
                filled: true,
                fillColor: pal.bg,
                border: InputBorder.none,
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 14),
            PixelButton(label: 'Save', onTap: () => Navigator.pop(context, _ctrl.text)),
          ],
        ),
      ),
    );
  }
}

class _RulesEditor extends StatefulWidget {
  const _RulesEditor({required this.rules, required this.onChanged});
  final Map<int, KingsRule> rules;
  final void Function(int rank, KingsRule rule) onChanged;

  @override
  State<_RulesEditor> createState() => _RulesEditorState();
}

class _RulesEditorState extends State<_RulesEditor> {
  static const _labels = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'};

  Future<void> _edit(int rank) async {
    final r = widget.rules[rank]!;
    final title = await showPixelDialog<String>(
      context: context,
      builder: (_) => _TextPrompt(title: 'Rule name', hint: 'Name', initial: r.title),
    );
    if (title == null || !mounted) return;
    final desc = await showPixelDialog<String>(
      context: context,
      builder: (_) => _TextPrompt(title: 'What happens', hint: 'Description', initial: r.description),
    );
    if (desc == null) return;
    setState(() => widget.onChanged(rank, r.copyWith(title: title, description: desc)));
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PixelScaffold(
      title: 'Card rules',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tap a card to change its rule for your table.', style: PixelFonts.body(pal.textDim)),
          const SizedBox(height: 12),
          for (var rank = 1; rank <= 13; rank++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _edit(rank),
                child: PixelBox(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(_labels[rank] ?? '$rank', style: PixelFonts.title(pal.accent, size: 16)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.rules[rank]!.title.toUpperCase(),
                              style: PixelFonts.title(pal.primary, size: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.rules[rank]!.description, style: PixelFonts.body(pal.text, size: 22)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
