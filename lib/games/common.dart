import 'dart:math';

/// Endless non-repeating draw from a list: shuffles, deals every item once,
/// then reshuffles. Used by every prompt-based game.
class ShuffledQueue<T> {
  ShuffledQueue(List<T> items, {Random? random})
      : _items = List.unmodifiable(items),
        _random = random ?? Random();

  final List<T> _items;
  final Random _random;
  final List<T> _queue = [];
  T? _last;

  bool get isEmpty => _items.isEmpty;

  T next() {
    if (_items.isEmpty) throw StateError('ShuffledQueue is empty');
    if (_queue.isEmpty) {
      _queue.addAll(_items);
      _queue.shuffle(_random);
      // Avoid showing the same item twice in a row across a reshuffle.
      if (_queue.length > 1 && _queue.last == _last) {
        final t = _queue.removeLast();
        _queue.insert(0, t);
      }
    }
    return _last = _queue.removeLast();
  }
}

/// Cycles through players in seat order.
class TurnOrder {
  TurnOrder(List<String> players) : players = List.unmodifiable(players);
  final List<String> players;
  int _i = 0;

  bool get isEmpty => players.isEmpty;
  String? get current => players.isEmpty ? null : players[_i % players.length];
  String? get next => players.isEmpty ? null : players[(_i + 1) % players.length];

  void advance() => _i++;
}
