import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/fx.dart';
import '../../theme/palette.dart';
import '../../widgets/pixel_ui.dart';
import '../how_to_play.dart';
import '../common.dart';
import 'never_have_i_ever.dart';

class NeverHaveIEverScreen extends StatefulWidget {
  const NeverHaveIEverScreen({super.key});

  @override
  State<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends State<NeverHaveIEverScreen> {
  NhieLevel _level = NhieLevel.mild;
  late ShuffledQueue<String> _deck = ShuffledQueue(nhiePrompts[_level]!);
  late String _prompt = _deck.next();
  late NhieTracker _tracker = NhieTracker(context.app.players);

  void _setLevel(NhieLevel l) => setState(() {
        _level = l;
        _deck = ShuffledQueue(nhiePrompts[l]!);
        _prompt = _deck.next();
      });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final players = _tracker.players;
    return PixelScaffold(
      title: 'Never Have I Ever',
      onHelp: () => showHowToPlay(context, 'never_have_i_ever'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            for (final l in NhieLevel.values) ...[
              PixelChip(label: l.name, selected: _level == l, onTap: () => _setLevel(l)),
              const SizedBox(width: 8),
            ],
          ]),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(_prompt, textAlign: TextAlign.center, style: PixelFonts.title(pal.text, size: 18)),
            ),
          ),
          if (players.isEmpty)
            Text('Done it? Drink. Add players to track fingers.',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim))
          else ...[
            Text(_tracker.isOver ? 'LAST HAND UP: ${_tracker.standing.join()}' : 'DONE IT? TAP YOUR NAME',
                style: PixelFonts.title(_tracker.isOver ? pal.accent : pal.textDim, size: 10)),
            const SizedBox(height: 8),
            Expanded(
              flex: 4,
              child: ListView(children: [
                for (final p in players) _fingerRow(context, p),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (players.isNotEmpty) ...[
              Expanded(
                child: PixelButton(
                  label: 'Reset',
                  size: 11,
                  color: pal.panel,
                  textColor: pal.text,
                  expand: true,
                  onTap: () => setState(() => _tracker = NhieTracker(context.app.players)),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: PixelButton(label: 'Next', expand: true, onTap: () => setState(() => _prompt = _deck.next())),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _fingerRow(BuildContext context, String p) {
    final pal = context.pal;
    final n = _tracker.fingersOf(p);
    return GestureDetector(
      onTap: () {
        Fx.select();
        setState(() => _tracker.fingerDown(p));
      },
      onLongPress: () => setState(() => _tracker.undo(p)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: pal.panel, border: Border.all(color: pal.border, width: 2)),
        child: Row(children: [
          Expanded(
            child: Text(p,
                style: PixelFonts.body(n == 0 ? pal.textDim : pal.text, size: 26)
                    .copyWith(decoration: n == 0 ? TextDecoration.lineThrough : null)),
          ),
          for (var i = 0; i < _tracker.fingers; i++)
            Container(
              width: 10,
              height: 22,
              margin: const EdgeInsets.only(left: 4),
              color: i < n ? pal.accent : pal.bg,
            ),
        ]),
      ),
    );
  }
}
