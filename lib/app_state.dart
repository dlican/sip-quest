import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/fx.dart';
import 'theme/palette.dart';

/// App-wide state: the active visual style, optional player names and the
/// sound / haptics settings. Everything stays on this phone; there is no
/// backend and nobody has to join anything.
class AppState extends ChangeNotifier {
  SipPalette _palette = SipPalette.neon;
  final List<String> _players = [];
  bool _sound = true;
  double _volume = 0.8;
  bool _haptics = true;
  bool _ticks = true;
  SharedPreferences? _prefs;

  SipPalette get palette => _palette;
  List<String> get players => List.unmodifiable(_players);
  bool get sound => _sound;
  double get volume => _volume;
  bool get haptics => _haptics;

  /// Countdown ticks in the last seconds of timed games.
  bool get ticks => _ticks;

  /// Restores saved settings. Tests skip this and use the defaults.
  Future<void> load() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      final style = p.getString('style');
      for (final s in SipPalette.all) {
        if (s.id == style) _palette = s;
      }
      _players
        ..clear()
        ..addAll(p.getStringList('players') ?? const []);
      _sound = p.getBool('sound') ?? _sound;
      _volume = p.getDouble('volume') ?? _volume;
      _haptics = p.getBool('haptics') ?? _haptics;
      _ticks = p.getBool('ticks') ?? _ticks;
    } catch (_) {
      // No storage (e.g. a browser preview): keep defaults.
    }
    _syncFx();
    notifyListeners();
  }

  void _syncFx() => Fx.configure(sound: _sound, volume: _volume, haptics: _haptics, ticks: _ticks);

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('style', _palette.id);
    p.setStringList('players', _players);
    p.setBool('sound', _sound);
    p.setDouble('volume', _volume);
    p.setBool('haptics', _haptics);
    p.setBool('ticks', _ticks);
  }

  void _changed() {
    _syncFx();
    _save();
    notifyListeners();
  }

  void setPalette(SipPalette p) {
    _palette = p;
    _changed();
  }

  void cyclePalette() {
    final i = SipPalette.all.indexOf(_palette);
    setPalette(SipPalette.all[(i + 1) % SipPalette.all.length]);
  }

  void setSound(bool v) {
    _sound = v;
    _changed();
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    _changed();
  }

  void setHaptics(bool v) {
    _haptics = v;
    _changed();
  }

  void setTicks(bool v) {
    _ticks = v;
    _changed();
  }

  bool addPlayer(String name) {
    final n = name.trim();
    if (n.isEmpty || _players.any((p) => p.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    _players.add(n);
    _changed();
    return true;
  }

  void removePlayer(String name) {
    _players.remove(name);
    _changed();
  }

  void clearPlayers() {
    _players.clear();
    _changed();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
  SipPalette get pal => AppScope.of(this).palette;
}
