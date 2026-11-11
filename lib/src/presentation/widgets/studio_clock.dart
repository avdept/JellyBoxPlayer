import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

class StudioClock extends ValueNotifier<double> {
  StudioClock({required bool playing, int fps = defaultFps})
    : isPlaying = playing,
      _rate = playing ? playingRate : pausedRate,
      _fps = max(1, fps),
      super(0);

  static const playingRate = 1.0;
  static const pausedRate = 0.2;
  static const defaultFps = 15;
  static const _rampSeconds = 1.5;

  final _watch = Stopwatch();
  Timer? _timer;
  bool isPlaying;
  int _fps;
  double _speedScale = 1;
  double _rate;

  bool get isRunning => _timer != null;
  int get fps => _fps;

  set fps(int value) {
    final next = max(1, value);
    if (next == _fps) return;
    _fps = next;
    if (_timer == null) return;
    _timer!.cancel();
    _timer = Timer.periodic(_interval, _tick);
  }

  Duration get _interval => Duration(microseconds: 1000000 ~/ _fps);

  void run({required bool animate, required double speedScale}) {
    _speedScale = speedScale;
    if (!animate || speedScale <= 0) {
      stop();
      return;
    }
    if (_timer != null) return;
    _watch
      ..reset()
      ..start();
    _timer = Timer.periodic(_interval, _tick);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _watch
      ..stop()
      ..reset();
  }

  void _tick(Timer timer) {
    final dt = _watch.elapsedMicroseconds / 1e6;
    _watch.reset();
    final target = (isPlaying ? playingRate : pausedRate) * _speedScale;
    _rate += (target - _rate) * (1 - exp(-dt / _rampSeconds));
    value += dt * _rate;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
