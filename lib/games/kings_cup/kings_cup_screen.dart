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
  }

  void _draw() {
    if (_shuffling) return;
    setState(() {
      final c = _game.draw();
      if (c != null) {
        c.rank == 13 ? Fx.coin() : Fx.flip();
        if (_game.status == KingsCupStatus.fourthKing) Fx.boom();
      }
    });
  }

  Future<void> _writeRule() async {
    final rule = await showPixelDialog<String>(
      context: context,
      builder: (_) => const _TextPrompt(title: 'New house rule', hint: 'e.g. No saying "you"'),
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
      title: 'Four Kings',
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
                          ? _ShuffleDeck(width: w * 0.75, onDone: () => setState(() => _shuffling = false))
                          : g.current == null
                          ? _DeckPile(width: w * 0.75, count: g.deck.remaining)
                          : FlippingCard(card: g.current!, width: w),
                    ),
                  );
                },
              ),
            ),
            _RulePanel(game: g, shuffling: _shuffling, onWriteRule: _writeRule),
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
          Text('Q.M. ', style: PixelFonts.title(pal.textDim, size: 10)),
          Text(game.questionMaster!, style: PixelFonts.body(pal.accent, size: 26)),
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
    if (game.status == KingsCupStatus.fourthKing) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4TH KING!', style: PixelFonts.title(pal.primary, size: 18)),
          const SizedBox(height: 8),
          Text(
            '${game.currentPlayer ?? 'Whoever drew it'} takes the whole pot. Game over.',
            style: PixelFonts.body(pal.text),
          ),
        ],
      );
    } else if (c == null) {
      content = Text(
        shuffling ? 'Shuffling the deck...' : 'Phone in the middle of the table. Tap to draw.',
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
  const _ShuffleDeck({required this.width, required this.onDone});
  final double width;
  final VoidCallback onDone;

  @override
  State<_ShuffleDeck> createState() => _ShuffleDeckState();
}

class _ShuffleDeckState extends State<_ShuffleDeck> with SingleTickerProviderStateMixin {
  static const _cycles = 3;
  static const _cards = 10;
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 650 * _cycles),
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
