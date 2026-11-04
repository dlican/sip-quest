/// Turns accelerometer readings into "tilted down" / "tilted up" gestures for
/// heads-up charades. The phone sits sideways on the player's forehead with
/// the screen facing the room.
///
/// Uses the z axis (out of the screen): about 0 when the phone is upright,
/// strongly negative when the screen faces the floor (tilted forward / down)
/// and strongly positive when it faces the ceiling (tilted back / up). Works
/// for either landscape direction.
enum Tilt { down, up }

class TiltDetector {
  TiltDetector({this.trigger = 6.0, this.rearm = 3.5, this.smoothing = 0.35});

  /// |z| in m/s^2 that counts as a tilt (about 38 degrees).
  final double trigger;

  /// |z| under which the phone counts as level again.
  final double rearm;

  /// Low-pass factor for incoming samples (1 = no smoothing).
  final double smoothing;

  double _z = 0;
  bool _primed = false;
  bool _armed = false;

  /// True once the phone is held upright, so a new tilt can register.
  bool get isLevel => _armed;

  double get z => _z;

  /// Feeds one accelerometer z sample; returns a tilt once per gesture.
  Tilt? feed(double rawZ) {
    _z = _primed ? _z + (rawZ - _z) * smoothing : rawZ;
    _primed = true;
    if (_z.abs() < rearm) {
      _armed = true;
      return null;
    }
    if (!_armed) return null;
    if (_z <= -trigger) {
      _armed = false;
      return Tilt.down;
    }
    if (_z >= trigger) {
      _armed = false;
      return Tilt.up;
    }
    return null;
  }

  void reset() {
    _z = 0;
    _primed = false;
    _armed = false;
  }
}
