import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/fx.dart';
import '../theme/palette.dart';
import '../widgets/motion.dart';
import '../widgets/pixel_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pal = app.palette;
    return PixelScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('SOUND'),
          _ToggleRow(
            label: 'Sound effects',
            value: app.sound,
            onChanged: (v) {
              app.setSound(v);
              if (v) Fx.correct();
            },
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.enter,
            child: app.sound
                ? Column(
                    children: [
                      const SizedBox(height: 10),
                      _VolumeRow(value: app.volume, onChanged: app.setVolume),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        label: 'Countdown ticks',
                        hint: 'Beeps in the last seconds of a timer',
                        value: app.ticks,
                        onChanged: app.setTicks,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: PixelButton(
                              label: 'Test',
                              size: 11,
                              expand: true,
                              color: pal.secondary,
                              onTap: Fx.win,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          _Section('FEEL'),
          _ToggleRow(
            label: 'Haptics',
            hint: 'Buzz on taps, flips and timers',
            value: app.haptics,
            onChanged: (v) {
              app.setHaptics(v);
              if (v) Fx.flip();
            },
          ),
          _Section('LOOK'),
          PixelButton(label: 'Style: ${pal.name}', size: 11, expand: true, color: pal.accent, onTap: app.cyclePalette),
          const SizedBox(height: 24),
          Text(
            'Settings are saved on this phone.',
            textAlign: TextAlign.center,
            style: PixelFonts.body(pal.textDim, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(text, style: PixelFonts.title(context.pal.textDim, size: 10)),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged, this.hint});
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Semantics(
      toggled: value,
      label: label,
      child: Pressable(
        onTap: () => onChanged(!value),
        sound: false,
        child: PixelBox(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PixelFonts.body(pal.text, size: 26)),
                    if (hint != null) Text(hint!, style: PixelFonts.body(pal.textDim, size: 20)),
                  ],
                ),
              ),
              PixelSwitch(value: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chunky two-state switch whose knob glides across.
class PixelSwitch extends StatelessWidget {
  const PixelSwitch({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.enter,
      width: 64,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? pal.secondary : pal.bg,
        border: Border.all(color: pal.cardBlack, width: 3),
      ),
      child: AnimatedAlign(
        duration: Motion.medium,
        curve: Motion.pop,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          color: value ? pal.bg : pal.textDim,
          alignment: Alignment.center,
          child: Text(value ? 'I' : 'O', style: PixelFonts.title(value ? pal.secondary : pal.bg, size: 8)),
        ),
      ),
    );
  }
}

/// Ten-step pixel volume bar. Tap or drag across it.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  static const _steps = 10;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final lit = (value * _steps).round();
    return PixelBox(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Volume', style: PixelFonts.body(pal.text, size: 26)),
              const Spacer(),
              Text('${lit * 10}%', style: PixelFonts.title(pal.accent, size: 11)),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              void set(double dx, {bool preview = false}) {
                final v = ((dx / box.maxWidth) * _steps).ceil().clamp(0, _steps) / _steps;
                if (v != value) {
                  onChanged(v);
                  Fx.tick();
                }
                if (preview) Fx.play(Sfx.select);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => set(d.localPosition.dx, preview: true),
                onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
                onHorizontalDragEnd: (_) => Fx.play(Sfx.select),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _steps; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: Motion.fast,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 10 + i * 2.6,
                            decoration: BoxDecoration(
                              color: i < lit ? pal.secondary : pal.bg,
                              border: Border.all(color: pal.cardBlack, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
