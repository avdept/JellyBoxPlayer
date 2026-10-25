import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

enum SleepTimerMode { tracks, minutes, time }

class SleepTimerState {
  const SleepTimerState.tracks({required int this.tracks, required this.tracksLeft})
    : mode = SleepTimerMode.tracks,
      minutes = null,
      endsAt = null;

  const SleepTimerState.minutes({required int this.minutes, required this.endsAt})
    : mode = SleepTimerMode.minutes,
      tracks = null,
      tracksLeft = null;

  const SleepTimerState.time({required DateTime this.endsAt})
    : mode = SleepTimerMode.time,
      tracks = null,
      tracksLeft = null,
      minutes = null;

  final SleepTimerMode mode;
  final int? tracks;
  final int? tracksLeft;
  final int? minutes;
  final DateTime? endsAt;
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState?> {
  SleepTimerNotifier(this._ref) : super(null) {
    _ref.listen<int?>(
      playbackProvider.select((state) => state.currentMediaIndex),
      _onTrackChanged,
    );
  }

  final Ref _ref;
  Timer? _timer;

  void startTracks(int tracks) {
    _stopCountdown();
    state = SleepTimerState.tracks(tracks: tracks, tracksLeft: tracks);
  }

  void startMinutes(int minutes) {
    _stopCountdown();
    _timer = Timer(Duration(minutes: minutes), _fire);
    state = SleepTimerState.minutes(
      minutes: minutes,
      endsAt: DateTime.now().add(Duration(minutes: minutes)),
    );
  }

  void startTime(int hour, int minute) {
    _stopCountdown();
    final now = DateTime.now();
    var endsAt = DateTime(now.year, now.month, now.day, hour, minute);
    if (!endsAt.isAfter(now)) endsAt = endsAt.add(const Duration(days: 1));
    _timer = Timer(endsAt.difference(now), _fire);
    state = SleepTimerState.time(endsAt: endsAt);
  }

  void cancel() {
    _stopCountdown();
    state = null;
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTrackChanged(int? previous, int? next) {
    final timer = state;
    if (timer == null || timer.mode != SleepTimerMode.tracks) return;
    if (previous == null || next == null || previous == next) return;
    final left = (timer.tracksLeft ?? 1) - 1;
    if (left <= 0) {
      _fire();
    } else {
      state = SleepTimerState.tracks(tracks: timer.tracks ?? left, tracksLeft: left);
    }
  }

  void _fire() {
    _stopCountdown();
    state = null;
    if (_ref.read(playbackProvider).status.isPlaying) {
      unawaited(_ref.read(playbackProvider.notifier).pause());
    }
  }

  @override
  void dispose() {
    _stopCountdown();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState?>(
      SleepTimerNotifier.new,
    );
