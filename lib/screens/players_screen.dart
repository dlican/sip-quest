import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/palette.dart';
import '../widgets/pixel_ui.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key, this.reason});
  final String? reason;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  void _add() {
    if (context.app.addPlayer(_ctrl.text)) _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pal = app.palette;
    return PixelScaffold(
      title: 'Names',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.reason != null) ...[
            PixelBox(
              borderColor: pal.accent,
              child: Text(widget.reason!, style: PixelFonts.body(pal.accent)),
            ),
            const SizedBox(height: 16),
          ],
          PixelBox(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: false,
                    textCapitalization: TextCapitalization.words,
                    style: PixelFonts.body(pal.text, size: 28),
                    cursorColor: pal.accent,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Player name',
                      hintStyle: PixelFonts.body(pal.textDim, size: 28),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                PixelButton(label: '+', onTap: _add, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (app.players.isEmpty)
            Text('Optional. Every game works without names.\nAdd them and the phone will call whose turn it is.',
                textAlign: TextAlign.center, style: PixelFonts.body(pal.textDim)),
          for (var i = 0; i < app.players.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelBox(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text('P${i + 1}', style: PixelFonts.title(pal.secondary, size: 11)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(app.players[i], style: PixelFonts.body(pal.text, size: 28)),
                    ),
                    GestureDetector(
                      onTap: () => app.removePlayer(app.players[i]),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('X', style: PixelFonts.title(pal.primary, size: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Done',
            expand: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
