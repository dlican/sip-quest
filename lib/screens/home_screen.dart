import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/registry.dart';
import '../theme/palette.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprites.dart';
import 'players_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, GameMode g) {
    final app = context.app;
    if (app.players.length < g.minPlayers) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlayersScreen(
              reason: '${g.title} needs at least ${g.minPlayers} players.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: g.builder));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pal = app.palette;
    return PixelScaffold(
      title: '',
      showBack: false,
      // Not lazy: the list is short and every tile stays findable in tests.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Center(child: PixelSprite(Sprites.mug, pixel: 7)),
          const SizedBox(height: 14),
          Center(
            child: Text('SIP QUEST',
                style: PixelFonts.title(pal.primary, size: 28).copyWith(
                  shadows: [Shadow(color: pal.secondary, offset: const Offset(3, 3))],
                )),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('party games, pixel sized',
                style: PixelFonts.body(pal.textDim, size: 24)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: app.players.isEmpty ? 'Add players' : 'Players: ${app.players.length}',
                  size: 11,
                  expand: true,
                  color: pal.secondary,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PlayersScreen())),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'Style: ${pal.name}',
                  size: 11,
                  expand: true,
                  color: pal.accent,
                  onTap: app.cyclePalette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final g in gameModes) ...[
            _GameTile(game: g, onTap: () => _open(context, g)),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 12),
          Center(
            child: Text('Legal drinking age only. Water counts as a drink.',
                textAlign: TextAlign.center,
                style: PixelFonts.body(pal.textDim, size: 20)),
          ),
        ]),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});
  final GameMode game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: PixelBox(
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              color: pal.bg,
              alignment: Alignment.center,
              child: PixelSprite(game.icon, pixel: 5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title.toUpperCase(),
                      style: PixelFonts.title(pal.accent, size: 13)),
                  const SizedBox(height: 6),
                  Text(game.tagline, style: PixelFonts.body(pal.text, size: 22)),
                  if (game.minPlayers > 0)
                    Text('${game.minPlayers}+ players',
                        style: PixelFonts.body(pal.textDim, size: 20)),
                ],
              ),
            ),
            Text('>', style: PixelFonts.title(pal.secondary, size: 18)),
          ],
        ),
      ),
    );
  }
}
