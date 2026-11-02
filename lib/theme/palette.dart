import 'package:flutter/material.dart';

/// A complete visual direction for the app. Every widget reads colours from
/// the active palette, so switching style re-skins the whole app at once.
class SipPalette {
  const SipPalette({
    required this.id,
    required this.name,
    required this.tagline,
    required this.bg,
    required this.bgAlt,
    required this.panel,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.textDim,
    required this.cardFace,
    required this.cardRed,
    required this.cardBlack,
    required this.cardBackA,
    required this.cardBackB,
    required this.scanlines,
  });

  final String id;
  final String name;
  final String tagline;
  final Color bg;
  final Color bgAlt;
  final Color panel;
  final Color border;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color textDim;
  final Color cardFace;
  final Color cardRed;
  final Color cardBlack;
  final Color cardBackA;
  final Color cardBackB;
  final bool scanlines;

  /// Direction 1: synthwave arcade cabinet. Loud, glowy, night-out energy.
  static const neon = SipPalette(
    id: 'neon',
    name: 'Neon Arcade',
    tagline: 'Synthwave cabinet, hot pink and cyan',
    bg: Color(0xFF0D0221),
    bgAlt: Color(0xFF190B3D),
    panel: Color(0xFF241250),
    border: Color(0xFF05D9E8),
    primary: Color(0xFFFF2A6D),
    secondary: Color(0xFF05D9E8),
    accent: Color(0xFFF9C80E),
    text: Color(0xFFF7F3FF),
    textDim: Color(0xFFA99BD1),
    cardFace: Color(0xFFFDF6E3),
    cardRed: Color(0xFFE63946),
    cardBlack: Color(0xFF1B1430),
    cardBackA: Color(0xFFFF2A6D),
    cardBackB: Color(0xFF7A0E3A),
    scanlines: true,
  );

  /// Direction 2: fantasy RPG tavern. Warm wood, parchment, candlelight.
  static const tavern = SipPalette(
    id: 'tavern',
    name: 'Pixel Tavern',
    tagline: 'RPG inn, wood, parchment and gold',
    bg: Color(0xFF24150D),
    bgAlt: Color(0xFF331F14),
    panel: Color(0xFF4A2C1A),
    border: Color(0xFFE8A33D),
    primary: Color(0xFFE8A33D),
    secondary: Color(0xFF7FB069),
    accent: Color(0xFFD94F30),
    text: Color(0xFFF4E4C1),
    textDim: Color(0xFFC2A27A),
    cardFace: Color(0xFFF4E4C1),
    cardRed: Color(0xFFB8322A),
    cardBlack: Color(0xFF2B1A12),
    cardBackA: Color(0xFF7FB069),
    cardBackB: Color(0xFF3E5E33),
    scanlines: false,
  );

  /// Direction 3: four-tone handheld. Minimal, nostalgic, very readable.
  static const pocket = SipPalette(
    id: 'pocket',
    name: 'Pocket Mono',
    tagline: '4-tone handheld green, clean and retro',
    bg: Color(0xFF0F380F),
    bgAlt: Color(0xFF173F17),
    panel: Color(0xFF306230),
    border: Color(0xFF9BBC0F),
    primary: Color(0xFF9BBC0F),
    secondary: Color(0xFF8BAC0F),
    accent: Color(0xFFC4E538),
    text: Color(0xFFE0F8D0),
    textDim: Color(0xFF8BAC0F),
    cardFace: Color(0xFF9BBC0F),
    cardRed: Color(0xFF0F380F),
    cardBlack: Color(0xFF0F380F),
    cardBackA: Color(0xFF306230),
    cardBackB: Color(0xFF0F380F),
    scanlines: true,
  );

  static const all = [neon, tavern, pocket];
}

/// Text styles. Titles use a chunky 8-bit font, body copy uses a taller
/// terminal font so longer rule text stays readable on a phone.
class PixelFonts {
  static TextStyle title(Color color, {double size = 14}) => TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        color: color,
        height: 1.5,
        letterSpacing: 0.5,
      );

  static TextStyle body(Color color, {double size = 24}) => TextStyle(
        fontFamily: 'VT323',
        fontSize: size,
        color: color,
        height: 1.1,
      );
}
