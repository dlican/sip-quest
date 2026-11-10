import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/fx.dart';
import '../theme/palette.dart';
import 'pixel_ui.dart';
import 'sprites.dart';

/// Pass-the-phone privacy gate: "Pass to Sam" until they tap Show me, then the
/// secret. Give it a new key per player so it closes again for the next one.
class SecretPass extends StatefulWidget {
  const SecretPass({
    super.key,
    required this.to,
    required this.secret,
    this.hint = 'Make sure nobody else can see the screen.',
    this.icon = Sprites.eye,
  });

  /// Who should be holding the phone, e.g. "Sam" or "Player 3".
  final String to;
  final String hint;
  final Sprite icon;

  /// Built once revealed. It supplies its own buttons to move on.
  final WidgetBuilder secret;

  @override
  State<SecretPass> createState() => _SecretPassState();
}

class _SecretPassState extends State<SecretPass> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (_shown) return widget.secret(context);
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Center(child: PixelSprite(widget.icon, pixel: 10)),
      const SizedBox(height: 24),
      Text('PASS THE PHONE TO', textAlign: TextAlign.center, style: PixelFonts.title(pal.textDim, size: 11)),
      const SizedBox(height: 10),
      Text(widget.to.toUpperCase(), textAlign: TextAlign.center, style: PixelFonts.title(pal.accent, size: 24)),
      const SizedBox(height: 10),
      Text(widget.hint, textAlign: TextAlign.center, style: PixelFonts.body(pal.text)),
      const Spacer(),
      PixelButton(
        label: 'Show me',
        expand: true,
        onTap: () {
          Fx.open();
          setState(() => _shown = true);
        },
      ),
    ]);
  }
}
