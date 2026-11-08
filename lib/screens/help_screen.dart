import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/how_to_play.dart';
import '../games/registry.dart';
import '../theme/palette.dart';
import '../widgets/game_icon.dart';
import '../widgets/pixel_ui.dart';

/// Help page: the basics of the app, then every game's how-to-play.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _basics = [
    'Pass one phone around. No accounts, no internet needed.',
    'Names are optional. Add them under Names and games will call out whose turn it is.',
    'Tap the ? on any game, or in a game\'s top bar, to see how it works.',
    'Change sound, haptics and style in Settings.',
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PixelScaffold(
      title: 'Help',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          PixelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE BASICS',
                  style: PixelFonts.title(pal.accent, size: 12),
                ),
                const SizedBox(height: 8),
                for (final b in _basics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '* $b',
                      style: PixelFonts.body(pal.text, size: 22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('HOW TO PLAY', style: PixelFonts.title(pal.textDim, size: 10)),
          const SizedBox(height: 10),
          for (final g in gameModes)
            if (howToPlay.containsKey(g.id))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Pressable(
                  onTap: () => showHowToPlay(context, g.id),
                  child: PixelBox(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Center(
                            child: AnimatedGameIcon(
                              gameId: g.id,
                              sprite: g.icon,
                              pixel: 3.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            g.title.toUpperCase(),
                            style: PixelFonts.title(pal.accent, size: 12),
                          ),
                        ),
                        Text(
                          '?',
                          style: PixelFonts.title(pal.secondary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text(
            'Legal drinking age only. Know your limits. Water counts as a drink.',
            textAlign: TextAlign.center,
            style: PixelFonts.body(pal.textDim, size: 20),
          ),
        ],
      ),
    );
  }
}
