import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sip_quest/services/fx.dart';

/// Load the real pixel fonts so layout tests measure text like the device does.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // No audio or sensor plugins in widget tests.
  Fx.hardware = false;
  Future<void> load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  await load('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  await load('VT323', 'assets/fonts/VT323-Regular.ttf');
  await testMain();
}
