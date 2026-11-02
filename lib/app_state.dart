import 'package:flutter/widgets.dart';

import 'theme/palette.dart';

/// App-wide state: the active visual style and the party's player list.
/// Everything is in memory; the app has no backend.
class AppState extends ChangeNotifier {
  SipPalette _palette = SipPalette.neon;
  final List<String> _players = [];

  SipPalette get palette => _palette;
  List<String> get players => List.unmodifiable(_players);

  void setPalette(SipPalette p) {
    _palette = p;
    notifyListeners();
  }

  void cyclePalette() {
    final i = SipPalette.all.indexOf(_palette);
    setPalette(SipPalette.all[(i + 1) % SipPalette.all.length]);
  }

  bool addPlayer(String name) {
    final n = name.trim();
    if (n.isEmpty || _players.any((p) => p.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    _players.add(n);
    notifyListeners();
    return true;
  }

  void removePlayer(String name) {
    _players.remove(name);
    notifyListeners();
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
