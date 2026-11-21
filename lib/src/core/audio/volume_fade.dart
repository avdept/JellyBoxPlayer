import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/core/audio/session_play.dart';
import 'package:just_audio/just_audio.dart';

class VolumeFade {
  VolumeFade._(this._player);

  factory VolumeFade.of(AudioPlayer player) =>
      _byPlayer[player] ??= VolumeFade._(player);

  static final _byPlayer = Expando<VolumeFade>();

  static const duration = Duration(milliseconds: 50);
  static const steps = 5;

  final AudioPlayer _player;
  var _level = 1.0;
  var _current = 1.0;
  var _generation = 0;
  var _wantsPlay = false;

  double get level => _level;

  Future<void> setLevel(double level) {
    _level = level;
    _generation++;
    return _apply(level);
  }

  Future<void> play() async {
    _wantsPlay = true;
    final generation = ++_generation;
    final silenced = _level > 0 && _current > 0 ? _apply(0) : null;
    final playing = playWithSession(_player);
    await silenced;
    await _ramp(generation, to: _level);
    await playing;
  }

  Future<void> pause() => _silenceThen(_player.pause);

  Future<void> stop() => _silenceThen(_player.stop);

  Future<void> _silenceThen(Future<void> Function() action) async {
    _wantsPlay = false;
    final generation = ++_generation;
    if (_player.playing) await _ramp(generation, to: 0);
    if (_wantsPlay) return;
    await action();
    if (_generation == generation) await _apply(_level);
  }

  Future<void> _ramp(int generation, {required double to}) async {
    final from = _current;
    if (from == to) return;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(duration ~/ steps);
      if (_generation != generation) return;
      await _apply(from + (to - from) * step / steps);
    }
  }

  Future<void> _apply(double level) async {
    _current = level;
    try {
      await _player.setVolume(level);
    } on MissingPluginException {
      debugPrint('[VolumeFade] volume noted; player is between sessions');
    }
  }
}
