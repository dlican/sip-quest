import 'package:flutter_test/flutter_test.dart';
import 'package:sip_quest/games/charades/tilt.dart';

/// Feeds the same reading several times so the low-pass filter settles.
Tilt? hold(TiltDetector d, double z, [int n = 12]) {
  Tilt? out;
  for (var i = 0; i < n; i++) {
    out ??= d.feed(z);
  }
  return out;
}

void main() {
  test('needs to be level before a tilt counts', () {
    final d = TiltDetector();
    expect(hold(d, -9.8), isNull); // started face down: ignored
    expect(hold(d, 0), isNull);
    expect(d.isLevel, isTrue);
  });

  test('tilting down scores, tilting up passes, once per gesture', () {
    final d = TiltDetector();
    hold(d, 0.5);
    expect(hold(d, -8), Tilt.down);
    expect(hold(d, -9), isNull); // still tilted: no repeat
    hold(d, 0);
    expect(hold(d, 8.5), Tilt.up);
    hold(d, 1);
    expect(hold(d, -7.5), Tilt.down);
  });

  test('small wobbles do nothing', () {
    final d = TiltDetector();
    hold(d, 0);
    for (final z in [2.0, -3.0, 4.5, -5.0, 3.0]) {
      expect(hold(d, z, 3), isNull);
    }
  });
}
