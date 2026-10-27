import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

enum SleepTimerMode { tracks, minutes, time }

class SleepTimerSelection {
  const SleepTimerSelection._({
    this.mode,
    this.tracks,
    this.minutes,
    this.hour,
    this.minute,
  });

  factory SleepTimerSelection.parse(String raw) {
    final parts = raw.split(':');
    final mode = SleepTimerMode.values.asNameMap()[parts.first];
    final first = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final second = parts.length > 2 ? int.tryParse(parts[2]) : null;
    if (mode == SleepTimerMode.tracks && first != null && first > 0) {
      return SleepTimerSelection._(mode: mode, tracks: first);
    }
    if (mode == SleepTimerMode.minutes &&
        first != null &&
        first >= 1 &&
        first <= 60) {
      return SleepTimerSelection._(mode: mode, minutes: first);
    }
    if (mode == SleepTimerMode.time &&
        first != null &&
        second != null &&
        first >= 0 &&
        first < 24 &&
        second >= 0 &&
        second < 60) {
      return SleepTimerSelection._(mode: mode, hour: first, minute: second);
    }
    return const SleepTimerSelection._();
  }

  final SleepTimerMode? mode;
  final int? tracks;
  final int? minutes;
  final int? hour;
  final int? minute;
}

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
    _remember('${SleepTimerMode.tracks.name}:$tracks');
  }

  void startMinutes(int minutes) {
    _stopCountdown();
    _timer = Timer(Duration(minutes: minutes), _fire);
    state = SleepTimerState.minutes(
      minutes: minutes,
      endsAt: DateTime.now().add(Duration(minutes: minutes)),
    );
    _remember('${SleepTimerMode.minutes.name}:$minutes');
  }

  void startTime(int hour, int minute) {
    _stopCountdown();
    final now = DateTime.now();
    var endsAt = DateTime(now.year, now.month, now.day, hour, minute);
    if (!endsAt.isAfter(now)) endsAt = endsAt.add(const Duration(days: 1));
    _timer = Timer(endsAt.difference(now), _fire);
    state = SleepTimerState.time(endsAt: endsAt);
    _remember('${SleepTimerMode.time.name}:$hour:$minute');
  }

  void _remember(String selection) => _ref
      .read(appSettingsProvider.notifier)
      .setValue(AppSetting.sleepTimerLast, selection);

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
