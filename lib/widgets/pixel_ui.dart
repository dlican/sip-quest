import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/fx.dart';
import '../theme/palette.dart';
import 'motion.dart';

const double kShadow = 4;

/// A square-cornered panel with a hard pixel border and a drop shadow.
class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.shadow = true,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? pal.panel,
        border: Border.all(color: borderColor ?? pal.border, width: 3),
        boxShadow: shadow
            ? [
                const BoxShadow(
                    color: Color(0xAA000000),
                    offset: Offset(kShadow, kShadow),
                    blurRadius: 0),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Chunky button that "presses in" by sliding onto its own shadow.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.size = 14,
    this.expand = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final double size;
  final bool expand;
  final Widget? leading;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final enabled = widget.onTap != null;
    final bg = enabled ? (widget.color ?? pal.primary) : pal.panel;
    final fg = enabled ? (widget.textColor ?? pal.bg) : pal.textDim;
    final offset = _down ? kShadow : 0.0;

    final label = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
        Flexible(
          child: Text(widget.label.toUpperCase(),
              textAlign: TextAlign.center,
              style: PixelFonts.title(fg, size: widget.size)),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                Fx.tap();
                widget.onTap!();
              }
            : null,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
              left: offset, top: offset, right: kShadow - offset, bottom: kShadow - offset),
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: pal.cardBlack, width: 3),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xAA000000),
                    offset: _down ? Offset.zero : const Offset(kShadow, kShadow),
                    blurRadius: 0)
              ],
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}

/// Shrinks slightly while pressed, then springs back. Wrap any tappable panel.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.sound = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              if (widget.sound) Fx.tap();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: _down ? const Duration(milliseconds: 80) : Motion.medium,
        curve: _down ? Curves.easeOut : Motion.pop,
        child: widget.child,
      ),
    );
  }
}

/// Small square icon button for top bars.
class PixelIconButton extends StatelessWidget {
  const PixelIconButton({super.key, required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Tooltip(
      message: tooltip ?? '',
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: pal.panel,
            border: Border.all(color: pal.border, width: 3),
          ),
          child: Icon(icon, color: pal.text, size: 22),
        ),
      ),
    );
  }
}

/// Screen frame: background, optional CRT scanlines and a pixel title bar.
class PixelScaffold extends StatelessWidget {
  const PixelScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.onHelp,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;

  /// Shows a "?" button that opens the game's how-to-play sheet.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.bg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(pal))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      if (showBack)
                        PixelIconButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      if (showBack) const SizedBox(width: 12),
                      Expanded(
                        child: Text(title.toUpperCase(),
                            maxLines: 2,
                            style: PixelFonts.title(pal.text, size: 15)),
                      ),
                      for (final a in actions) ...[const SizedBox(width: 8), a],
                      if (onHelp != null) ...[
                        const SizedBox(width: 8),
                        PixelIconButton(icon: Icons.question_mark, tooltip: 'How to play', onTap: onHelp!),
                      ],
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
          if (pal.scanlines)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _ScanlinePainter())),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.pal);
  final SipPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = pal.bgAlt;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.pal != pal;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x14000000);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Segmented pixel progress bar (used for timers).
class PixelBar extends StatelessWidget {
  const PixelBar({super.key, required this.value, this.segments = 15, this.color});
  final double value; // 0..1
  final int segments;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final lit = (value.clamp(0, 1) * segments).ceil();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.cardBlack,
        border: Border.all(color: pal.border, width: 3),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments; i++)
            Expanded(
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                color: i < lit ? (color ?? pal.secondary) : pal.panel,
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable player chip.
class PixelChip extends StatelessWidget {
  const PixelChip({
    super.key,
    required this.label,
    this.selected = false,
    this.struck = false,
    this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final bool struck;
  final VoidCallback? onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final bg = selected ? (selectedColor ?? pal.primary) : pal.panel;
    final fg = selected ? pal.bg : (struck ? pal.textDim : pal.text);
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              Fx.select();
              onTap!();
            },
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: selected ? pal.cardBlack : pal.border, width: 3),
        ),
        child: Text(label,
            style: PixelFonts.body(fg, size: 26).copyWith(
                decoration: struck ? TextDecoration.lineThrough : null,
                decorationThickness: 3)),
      ),
    );
  }
}
