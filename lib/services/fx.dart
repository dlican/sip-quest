import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The chiptune sound effects in assets/sfx (made by tool/make_sfx.py).
enum Sfx { tap, select, open, close, flip, correct, pass, tick, alarm, win, lose, boom, coin, spin, start }

/// Sound + haptic feedback in one place, so every game feels the same and the
/// settings screen can switch either off.
///
/// Call the semantic helpers (`Fx.tap()`, `Fx.correct()`...) instead of
/// HapticFeedback or audio directly.
class Fx {
  Fx._();

  /// False in widget tests, where audio and sensor plugins are not available.
  static bool hardware = true;

  static bool _sound = true;
  static double _volume = 0.8;
  static bool _haptics = true;
  static bool _ticks = true;
  static final Map<Sfx, AudioPool> _pools = {};
  static Future<void>? _loading;

  /// Last effect requested; lets tests check feedback fired.
  @visibleForTesting
  static Sfx? last;

  static void configure({required bool sound, required double volume, required bool haptics, required bool ticks}) {
    _sound = sound;
    _volume = volume;
    _haptics = haptics;
    _ticks = ticks;
    if (_sound) init();
  }

  /// Preloads every effect into a low-latency pool. Safe to call repeatedly.
  static Future<void> init() => _loading ??= _load();

  static Future<void> _load() async {
    if (!hardware) return;
    try {
      // Mix with whatever music is already playing at the party.
      final ctx = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();
      await AudioPlayer.global.setAudioContext(ctx);
      for (final s in Sfx.values) {
        final busy = s == Sfx.tap || s == Sfx.spin || s == Sfx.tick || s == Sfx.select;
        _pools[s] = await AudioPool.create(
          source: AssetSource('sfx/${s.name}.wav'),
          maxPlayers: busy ? 4 : 2,
          playerMode: kIsWeb ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
          audioContext: ctx,
        );
      }
    } catch (e) {
      debugPrint('Sound effects unavailable: $e');
    }
  }

  static void play(Sfx s) {
    last = s;
    if (!hardware || !_sound || _volume <= 0) return;
    if (s == Sfx.tick && !_ticks) return;
    final pool = _pools[s];
    if (pool == null) {
      init();
      return;
    }
    unawaited(pool.start(volume: _volume).then((_) {}, onError: (_) {}));
  }

  static void _buzz(Future<void> Function() f) {
    if (_haptics) unawaited(f().catchError((_) {}));
  }

  static void _pattern(List<Future<void> Function()> steps, {int gapMs = 70}) {
    if (!_haptics) return;
    for (var i = 0; i < steps.length; i++) {
      Future.delayed(Duration(milliseconds: gapMs * i), () => steps[i]().catchError((_) {}));
    }
  }

  // --- Semantic feedback -------------------------------------------------

  static void tap() {
    play(Sfx.tap);
    _buzz(HapticFeedback.lightImpact);
  }

  static void select() {
    play(Sfx.select);
    _buzz(HapticFeedback.selectionClick);
  }

  static void open() {
    play(Sfx.open);
    _buzz(HapticFeedback.lightImpact);
  }

  static void close() => play(Sfx.close);

  static void flip() {
    play(Sfx.flip);
    _buzz(HapticFeedback.mediumImpact);
  }

  static void correct() {
    play(Sfx.correct);
    _pattern([HapticFeedback.lightImpact, HapticFeedback.mediumImpact]);
  }

  static void pass() {
    play(Sfx.pass);
    _buzz(HapticFeedback.heavyImpact);
  }

  static void tick() {
    play(Sfx.tick);
    _buzz(HapticFeedback.selectionClick);
  }

  static void timeUp() {
    play(Sfx.alarm);
    _pattern([HapticFeedback.heavyImpact, HapticFeedback.heavyImpact, HapticFeedback.heavyImpact], gapMs: 140);
  }

  static void win() {
    play(Sfx.win);
    _pattern([HapticFeedback.lightImpact, HapticFeedback.lightImpact, HapticFeedback.heavyImpact], gapMs: 90);
  }

  static void lose() {
    play(Sfx.lose);
    _pattern([HapticFeedback.heavyImpact, HapticFeedback.mediumImpact], gapMs: 120);
  }

  static void boom() {
    play(Sfx.boom);
    _pattern([
      HapticFeedback.heavyImpact,
      HapticFeedback.heavyImpact,
      HapticFeedback.heavyImpact,
      HapticFeedback.heavyImpact,
    ], gapMs: 60);
  }

  static void coin() {
    play(Sfx.coin);
    _buzz(HapticFeedback.mediumImpact);
  }

  static void spinTick() {
    play(Sfx.spin);
    _buzz(HapticFeedback.selectionClick);
  }

  static void start() {
    play(Sfx.start);
    _buzz(HapticFeedback.mediumImpact);
  }
}
