import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/sleep_timer_provider.dart';

import '../../provider_container.dart';

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  int pauseCalls = 0;

  PlaybackState get current => state;

  set current(PlaybackState next) => state = next;

  @override
  Future<void> pause() async {
    pauseCalls++;
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  const songs = [
    LibraryItem(id: 'one', name: 'One', kind: ItemKind.song),
    LibraryItem(id: 'two', name: 'Two', kind: ItemKind.song),
    LibraryItem(id: 'three', name: 'Three', kind: ItemKind.song),
    LibraryItem(id: 'four', name: 'Four', kind: ItemKind.song),
  ];

  late _StubPlayback playback;
  late ProviderContainer container;

  PlaybackState playingAt(int index) => PlaybackState(
    album: album,
    songs: songs,
    status: PlaybackStatus.playing,
    position: Duration.zero,
    cacheProgress: Duration.zero,
    currentMediaIndex: index,
  );

  SleepTimerNotifier setUpTimer() {
    playback = _StubPlayback();
    container = createProviderContainer(
      overrides: [playbackProvider.overrideWith((ref) => playback)],
    );
    playback.current = playingAt(0);
    return container.read(sleepTimerProvider.notifier);
  }

  test('pauses after the configured number of tracks', () {
    final notifier = setUpTimer()..startTracks(2);

    playback.current = playingAt(1);
    expect(playback.pauseCalls, 0);
    expect(container.read(sleepTimerProvider)?.tracksLeft, 1);

    playback.current = playingAt(2);
    expect(playback.pauseCalls, 1);
    expect(container.read(sleepTimerProvider), isNull);
    expect(notifier.mounted, isTrue);
  });

  test('pauses when the minutes run out', () {
    fakeAsync((async) {
      setUpTimer().startMinutes(30);

      async.elapse(const Duration(minutes: 29));
      expect(playback.pauseCalls, 0);
      expect(container.read(sleepTimerProvider)?.minutes, 30);

      async.elapse(const Duration(minutes: 1));
      expect(playback.pauseCalls, 1);
      expect(container.read(sleepTimerProvider), isNull);
    });
  });

  test('cancel stops the countdown', () {
    fakeAsync((async) {
      setUpTimer()
        ..startMinutes(5)
        ..cancel();

      async.elapse(const Duration(minutes: 10));
      playback.current = playingAt(1);
      expect(playback.pauseCalls, 0);
      expect(container.read(sleepTimerProvider), isNull);
    });
  });

  test('saving a new timer replaces the previous one', () {
    fakeAsync((async) {
      setUpTimer()
        ..startTracks(1)
        ..startMinutes(5);

      playback.current = playingAt(1);
      expect(playback.pauseCalls, 0);

      async.elapse(const Duration(minutes: 5));
      expect(playback.pauseCalls, 1);
    });
  });

  test('pauses at the chosen time later today', () {
    fakeAsync((async) {
      final target = DateTime.now().add(const Duration(hours: 2));
      setUpTimer().startTime(target.hour, target.minute);

      final endsAt = container.read(sleepTimerProvider)!.endsAt!;
      expect(endsAt.difference(DateTime.now()).inMinutes, lessThan(121));

      async.elapse(const Duration(hours: 1, minutes: 59));
      expect(playback.pauseCalls, 0);

      async.elapse(const Duration(minutes: 2));
      expect(playback.pauseCalls, 1);
      expect(container.read(sleepTimerProvider), isNull);
    });
  });

  test('a time already passed today schedules for tomorrow', () {
    fakeAsync((async) {
      final target = DateTime.now().subtract(const Duration(hours: 1));
      setUpTimer().startTime(target.hour, target.minute);

      final endsAt = container.read(sleepTimerProvider)!.endsAt!;
      expect(endsAt.isAfter(DateTime.now()), isTrue);
      expect(endsAt.difference(DateTime.now()).inHours, greaterThan(21));

      async.elapse(const Duration(hours: 22));
      expect(playback.pauseCalls, 0);

      async.elapse(const Duration(hours: 2));
      expect(playback.pauseCalls, 1);
    });
  });

  test('remembers the last saved selection', () {
    final notifier = setUpTimer();
    final settings = container.read(appSettingsProvider.notifier);

    SleepTimerSelection last() => SleepTimerSelection.parse(
      settings.valueOf(AppSetting.sleepTimerLast),
    );

    notifier.startMinutes(30);
    expect(last().mode, SleepTimerMode.minutes);
    expect(last().minutes, 30);

    notifier.startTracks(3);
    expect(last().mode, SleepTimerMode.tracks);
    expect(last().tracks, 3);

    notifier.startTime(23, 30);
    expect(last().mode, SleepTimerMode.time);
    expect(last().hour, 23);
    expect(last().minute, 30);
  });

  test('an unparseable remembered selection is ignored', () {
    const invalid = [
      '',
      'minutes',
      'minutes:0',
      'minutes:90',
      'time:25:00',
      'time:23',
      'tracks:x',
    ];
    for (final raw in invalid) {
      expect(SleepTimerSelection.parse(raw).mode, isNull, reason: raw);
    }
  });

  test('does not pause when playback is already paused', () {
    fakeAsync((async) {
      setUpTimer().startMinutes(1);
      playback.current = playingAt(0).copyWith(status: PlaybackStatus.paused);

      async.elapse(const Duration(minutes: 1));
      expect(playback.pauseCalls, 0);
      expect(container.read(sleepTimerProvider), isNull);
    });
  });
}
