import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/palette.dart';

/// Pixel art is stored as rows of characters so it can be edited by hand and
/// re-coloured by the active palette. '.' is transparent.
///   P primary   S secondary   A accent   T text   K outline (card black)
///   R card red  W card face   D panel    B background
class Sprite {
  const Sprite(this.rows);
  final List<String> rows;
  int get width => rows.first.length;
  int get height => rows.length;
}

Color? spriteColor(String c, SipPalette p) => switch (c) {
      'P' => p.primary,
      'S' => p.secondary,
      'A' => p.accent,
      'T' => p.text,
      'K' => p.cardBlack,
      'R' => p.cardRed,
      'W' => p.cardFace,
      'D' => p.panel,
      'B' => p.bg,
      _ => null,
    };

class PixelSprite extends StatelessWidget {
  const PixelSprite(this.sprite, {super.key, this.pixel = 4, this.tint});

  final Sprite sprite;
  final double pixel;

  /// Optional per-character colour override (e.g. to tint a horse).
  final Map<String, Color>? tint;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return CustomPaint(
      size: Size(sprite.width * pixel, sprite.height * pixel),
      painter: _SpritePainter(sprite, pixel, pal, tint),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite, this.pixel, this.pal, this.tint);
  final Sprite sprite;
  final double pixel;
  final SipPalette pal;
  final Map<String, Color>? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < sprite.height; y++) {
      final row = sprite.rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        final color = tint?[ch] ?? spriteColor(ch, pal);
        if (color == null) continue;
        paint.color = color;
        // +0.5 overlap avoids hairline gaps between pixels on some densities.
        canvas.drawRect(
            Rect.fromLTWH(x * pixel, y * pixel, pixel + 0.5, pixel + 0.5),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.sprite != sprite || old.pal != pal || old.pixel != pixel || old.tint != tint;
}

class Sprites {
  static const crown = Sprite([
    'A....A....A',
    'AA..AAA..AA',
    'AAA.AAA.AAA',
    'AAAAAAAAAAA',
    'ARAAASAAARA',
    'AAAAAAAAAAA',
    '.TTTTTTTTT.',
  ]);

  static const crownEmpty = Sprite([
    'D....D....D',
    'DD..DDD..DD',
    'DDD.DDD.DDD',
    'DDDDDDDDDDD',
    'DDDDDDDDDDD',
    'DDDDDDDDDDD',
    '.DDDDDDDDD.',
  ]);

  static const mug = Sprite([
    '.TTTTTTT...',
    'TTTTTTTTT..',
    'TAAAAAAAT..',
    'TAAAAAAATTT',
    'TATAAAAAT.T',
    'TATAAAAAT.T',
    'TATAAAAATTT',
    'TAAAAAAAT..',
    'TAAAAAAAT..',
    '.TTTTTTT...',
  ]);

  static const question = Sprite([
    '..SSSSS..',
    '.SS...SS.',
    '.SS...SS.',
    '.....SS..',
    '....SS...',
    '....SS...',
    '.........',
    '....SS...',
    '....SS...',
  ]);

  static const eye = Sprite([
    '...TTTTT...',
    '.TTWWWWWTT.',
    'TWWWPPPWWWT',
    'TWWPPKPPWWT',
    'TWWWPPPWWWT',
    '.TTWWWWWTT.',
    '...TTTTT...',
  ]);

  static const horse = Sprite([
    '.........TT.',
    '........TAAT',
    '.......TAAAA',
    'TT....TAAATT',
    'TAT.TTAAAT..',
    '.TAAAAAAAT..',
    '..TAAAAAAT..',
    '..TATTTTAT..',
    '..TT....TT..',
  ]);

  static const mask = Sprite([
    '.TTTTTTTTT.',
    'TSSSSSSSSST',
    'TSTTSSSTTST',
    'TSSSSSSSSST',
    'TSSSSSSSSST',
    'TSSTSSSTSST',
    '.TSSTTTSST.',
    '..TSSSSST..',
    '...TTTTT...',
  ]);

  static const coinHeads = Sprite([
    '..AAAAA..',
    '.AAAAAAA.',
    'AAATTTAAA',
    'AATAAATAA',
    'AATAAATAA',
    'AATAAATAA',
    'AAATTTAAA',
    '.AAAAAAA.',
    '..AAAAA..',
  ]);

  static const coinTails = Sprite([
    '..AAAAA..',
    '.AAAAAAA.',
    'AATTTTTAA',
    'AAAATAAAA',
    'AAAATAAAA',
    'AAAATAAAA',
    'AAAATAAAA',
    '.AAAAAAA.',
    '..AAAAA..',
  ]);

  static const flag = Sprite([
    'TKTKTK',
    'KTKTKT',
    'TKTKTK',
    'KTKTKT',
    'T.....',
    'T.....',
    'T.....',
  ]);

  static const heart = Sprite([
    '.RR.RR.',
    'RRRRRRR',
    'RRRRRRR',
    'RRRRRRR',
    '.RRRRR.',
    '..RRR..',
    '...R...',
  ]);

  static const diamond = Sprite([
    '...R...',
    '..RRR..',
    '.RRRRR.',
    'RRRRRRR',
    '.RRRRR.',
    '..RRR..',
    '...R...',
  ]);

  static const spade = Sprite([
    '...K...',
    '..KKK..',
    '.KKKKK.',
    'KKKKKKK',
    'KKKKKKK',
    '..KKK..',
    '.KKKKK.',
  ]);

  static const club = Sprite([
    '..KKK..',
    '..KKK..',
    'KKKKKKK',
    'KKKKKKK',
    'KK.K.KK',
    '...K...',
    '.KKKKK.',
  ]);

  static const bus = Sprite([
    '.TTTTTTTTTT.',
    'TAAAAAAAAAAT',
    'TASSATSSATST',
    'TASSATSSATST',
    'TAAAAAAAAAAT',
    'TAAAAAAAAAAT',
    'TTTTTTTTTTTT',
    '.TKT....TKT.',
    '..T......T..',
  ]);

  static const bomb = Sprite([
    '.......A.A',
    '........A.',
    '.......T..',
    '...KKKKT..',
    '..KKKKKK..',
    '.KKTKKKKK.',
    '.KTKKKKKK.',
    '.KKKKKKKK.',
    '.KKKKKKKK.',
    '..KKKKKK..',
    '...KKKK...',
  ]);

  static const ballot = Sprite([
    '...TTTTT...',
    '...TWWWT...',
    '...TWSWT...',
    'TTTTWWWTTTT',
    'TPPPPPPPPPT',
    'TPPKKKKKPPT',
    'TPPPPPPPPPT',
    'TPPPPPPPPPT',
    'TTTTTTTTTTT',
  ]);

  static const arrows = Sprite([
    '...S.....',
    '..SSS....',
    '.SSSSS...',
    '...S.....',
    '...S..P..',
    '......P..',
    '....PPPPP',
    '.....PPP.',
    '......P..',
  ]);

  static const hand = Sprite([
    '...T.T.T..',
    '..TATATAT.',
    '..TATATAT.',
    '.TTATATAT.',
    'TATAAAAAT.',
    'TAAAAAAAT.',
    '.TAAAAAAT.',
    '..TAAAAT..',
    '...TTTT...',
  ]);

  static const wheel = Sprite([
    '....TTT....',
    '..TTPPATT..',
    '.TPPPPAAAT.',
    '.TSPPPAAAT.',
    'TSSSPKASSST',
    'TSSSSKSSSST',
    'TAAASSPPPST',
    '.TAAAPPPPT.',
    '.TAAAPPPPT.',
    '..TTAPPTT..',
    '....TTT....',
  ]);

  static const dealer = Sprite([
    '..KKKKKKK..',
    '..KKKKKKK..',
    '..KKKKKKK..',
    'KKKKKKKKKKK',
    '..WWWWWWW..',
    '..WKWWWKW..',
    '..WWWWWWW..',
    '..WWKKKWW..',
    '...WWWWW...',
  ]);

  static const lips = Sprite([
    '..PP...PP..',
    '.PPPP.PPPP.',
    'PPPPPPPPPPP',
    'PTTTTTTTTTP',
    'PPPPPPPPPPP',
    '.PPPPPPPPP.',
    '...PPPPP...',
  ]);

  static const boom = Sprite([
    'A...A...A..',
    '.A..P..A...',
    '..APPPA....',
    'APPPAPPPA..',
    '..APPPA....',
    '.A..P..A...',
    'A...A...A..',
  ]);

  /// A party guest for how-to-play demos. Tint 'A' to tell people apart.
  static const head = Sprite([
    '..TTTTT..',
    '.TAAAAAT.',
    'TAAAAAAAT',
    'TAKAAAKAT',
    'TAAAAAAAT',
    'TAAKKKAAT',
    '.TAAAAAT.',
    '..TTTTT..',
  ]);

  static const check = Sprite([
    '......S',
    '.....SS',
    'S...SS.',
    'SS.SS..',
    '.SSS...',
    '..S....',
  ]);

  static const cross = Sprite([
    'PP...PP',
    '.PP.PP.',
    '..PPP..',
    '.PP.PP.',
    'PP...PP',
  ]);

  static const gear = Sprite([
    '...TT...',
    '.T.TT.T.',
    '..TTTT..',
    'TTT..TTT',
    'TTT..TTT',
    '..TTTT..',
    '.T.TT.T.',
    '...TT...',
  ]);
}
