import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/how_to_play.dart';
import '../games/registry.dart';
import '../theme/palette.dart';
import '../widgets/motion.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/sprites.dart';
import 'players_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Tiles slide in one after another when the app opens.
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _open(GameMode g) => Navigator.of(context).push(MaterialPageRoute(builder: g.builder));

  Widget _stagger(int i, Widget child) {
    final start = (i * 0.05).clamp(0.0, 0.6);
    final anim = CurvedAnimation(parent: _intro, curve: Interval(start, start + 0.4, curve: Motion.enter));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pal = app.palette;
    return PixelScaffold(
      title: '',
      showBack: false,
      actions: [
        PixelIconButton(
          icon: Icons.settings,
          tooltip: 'Settings',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
      // Not lazy: the list is short and every tile stays findable in tests.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: _BouncingMug()),
          const SizedBox(height: 14),
          Center(
            child: Text('SIP QUEST',
                style: PixelFonts.title(pal.primary, size: 28).copyWith(
                  shadows: [Shadow(color: pal.secondary, offset: const Offset(3, 3))],
                )),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('one phone, the whole party',
                style: PixelFonts.body(pal.textDim, size: 24)),
          ),
          const SizedBox(height: 20),
          // Same height for both, even when one label wraps to two lines.
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PixelButton(
                  label: app.players.isEmpty ? 'Names (optional)' : 'Names: ${app.players.length}',
                  size: 10,
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
                  size: 10,
                  expand: true,
                  color: pal.accent,
                  onTap: app.cyclePalette,
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < gameModes.length; i++) ...[
            _stagger(
              i,
              _GameTile(
                game: gameModes[i],
                onTap: () => _open(gameModes[i]),
                onHelp: () => showHowToPlay(context, gameModes[i].id),
              ),
            ),
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
  const _GameTile({required this.game, required this.onTap, required this.onHelp});
  final GameMode game;
  final VoidCallback onTap;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Pressable(
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
                ],
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'How to play ${game.title}',
              child: Pressable(
                key: Key('help-${game.id}'),
                onTap: onHelp,
                sound: false,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pal.bg,
                    border: Border.all(color: pal.secondary, width: 3),
                  ),
                  child: Text('?', style: PixelFonts.title(pal.secondary, size: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title mug: bobs and tips like it is being raised for a toast, with
/// foam bubbles drifting up. Motion snaps to the sprite's pixel grid so it
/// stays crisp and retro.
class _BouncingMug extends StatefulWidget {
  const _BouncingMug();

  @override
  State<_BouncingMug> createState() => _BouncingMugState();
}

class _BouncingMugState extends State<_BouncingMug>
    with SingleTickerProviderStateMixin {
  static const double _px = 7;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _snap(double v, double step) => (v / step).roundToDouble() * step;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    const mug = Sprites.mug;
    final w = mug.width * _px;
    final h = mug.height * _px;
    const headroom = 5 * _px;
    return SizedBox(
      width: w + 2 * _px,
      height: h + headroom + _px,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          final bob = _snap(math.sin(t) * 1.5 * _px, _px / 2);
          final tilt = _snap(math.sin(t + math.pi / 2) * 0.09, 0.03);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubbles rise from the beer at staggered phases.
              for (var i = 0; i < 3; i++) _bubble(pal.text, i, bob, headroom),
              Positioned(
                left: _px,
                top: headroom + bob,
                child: Transform.rotate(
                  angle: tilt,
                  alignment: Alignment.bottomCenter,
                  child: PixelSprite(mug, pixel: _px),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bubble(Color color, int i, double bob, double headroom) {
    final phase = (_c.value + i / 3) % 1.0;
    final rise = _snap(phase * (headroom + 2 * _px), _px / 2);
    final size = i == 1 ? _px : _px * 0.7;
    final x =
        _px * (2.5 + i * 2.2) +
        _snap(math.sin(phase * 2 * math.pi) * _px * 0.5, _px / 2);
    return Positioned(
      left: x,
      top: headroom + 2 * _px + bob - rise,
      child: Opacity(
        opacity: phase < 0.6 ? 1.0 : ((1 - phase) / 0.4).clamp(0.0, 1.0),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }
}
