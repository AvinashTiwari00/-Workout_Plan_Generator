/// Session-wide elapsed time, using a monotonic source and excluding pauses.
/// The source can be supplied for deterministic tests without real delays.
class WorkoutSessionClock {
  WorkoutSessionClock({Duration Function()? now}) {
    final stopwatch = Stopwatch()..start();
    _now = now ?? (() => stopwatch.elapsed);
  }
  late final Duration Function() _now;
  Duration _accumulated = Duration.zero;
  Duration? _startedAt;
  bool get isRunning => _startedAt != null;
  Duration get elapsed =>
      _accumulated +
      (_startedAt == null ? Duration.zero : _now() - _startedAt!);
  void start() {
    _startedAt ??= _now();
  }

  void pause() {
    if (_startedAt == null) return;
    _accumulated = elapsed;
    _startedAt = null;
  }

  String get display {
    final seconds = elapsed.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
