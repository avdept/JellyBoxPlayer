import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/scrobbling/listen_tracker.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  const album = LibraryItem(id: 'album', name: 'Dummy', kind: ItemKind.album);
  const short = LibraryItem(
    id: 'short',
    name: 'Sour Times',
    kind: ItemKind.song,
    duration: Duration(minutes: 3),
  );
  const long = LibraryItem(
    id: 'long',
    name: 'Glory Box',
    kind: ItemKind.song,
    duration: Duration(minutes: 12),
  );

  var now = DateTime.utc(2026, 9, 20, 12);
  late ListenTracker tracker;

  PlaybackState stateAt(
    Duration position, {
    PlaybackStatus status = PlaybackStatus.playing,
    List<LibraryItem> songs = const [short, long],
    int? index = 0,
  }) => PlaybackState(
    album: album,
    songs: songs,
    status: status,
    position: position,
    cacheProgress: Duration.zero,
    currentMediaIndex: index,
  );

  List<ScrobbleEvent> play(
    Duration from,
    Duration to, {
    int? index = 0,
    Duration step = const Duration(seconds: 1),
  }) {
    final events = <ScrobbleEvent>[];
    for (var at = from; at <= to; at += step) {
      now = now.add(step);
      events.addAll(tracker.update(stateAt(at, index: index)));
    }
    return events;
  }

  setUp(() {
    now = DateTime.utc(2026, 9, 20, 12);
    tracker = ListenTracker(clock: () => now);
  });

  test('announces now playing when a track starts', () {
    final events = tracker.update(stateAt(Duration.zero));
    expect(events, [isA<NowPlayingEvent>()]);
    expect(events.single.listen.song.id, 'short');
    expect(events.single.listen.album, album);
    expect(tracker.current, events.single.listen);
  });

  test('does not announce a track that is loaded but paused', () {
    final events = tracker.update(
      stateAt(Duration.zero, status: PlaybackStatus.paused),
    );
    expect(events, isEmpty);
    expect(tracker.current, isNotNull);
  });

  test('submits a listen after half of a short track, dated at its start', () {
    final startedAt = now;
    tracker.update(stateAt(Duration.zero));
    final events = play(Duration.zero, const Duration(seconds: 89));
    expect(events.whereType<ListenedEvent>(), isEmpty);

    final crossed = play(
      const Duration(seconds: 90),
      const Duration(seconds: 91),
    );
    final listened = crossed.whereType<ListenedEvent>().single;
    expect(listened.listen.song.id, 'short');
    expect(listened.listen.listenedAt, startedAt);

    expect(
      play(
        const Duration(seconds: 92),
        const Duration(minutes: 3),
      ).whereType<ListenedEvent>(),
      isEmpty,
    );
  });

  test('caps the required time at four minutes for long tracks', () {
    tracker.update(stateAt(Duration.zero, index: 1));
    expect(
      play(
        Duration.zero,
        const Duration(minutes: 3, seconds: 59),
        index: 1,
      ).whereType<ListenedEvent>(),
      isEmpty,
    );
    expect(
      play(
        const Duration(minutes: 4),
        const Duration(minutes: 4, seconds: 1),
        index: 1,
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
  });

  test('seeking forward does not count as listening', () {
    tracker
      ..update(stateAt(Duration.zero))
      ..update(stateAt(const Duration(seconds: 1)));
    expect(tracker.update(stateAt(const Duration(minutes: 2))), isEmpty);
    expect(
      play(
        const Duration(minutes: 2, seconds: 1),
        const Duration(minutes: 2, seconds: 30),
      ).whereType<ListenedEvent>(),
      isEmpty,
    );
    expect(
      play(
        const Duration(minutes: 2, seconds: 31),
        const Duration(minutes: 3, seconds: 31),
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
  });

  test('time spent paused does not count and resuming re-announces', () {
    tracker.update(stateAt(Duration.zero));
    play(Duration.zero, const Duration(seconds: 60));
    tracker.update(
      stateAt(const Duration(seconds: 60), status: PlaybackStatus.paused),
    );
    now = now.add(const Duration(minutes: 10));
    expect(
      tracker.update(stateAt(const Duration(seconds: 60))),
      [isA<NowPlayingEvent>()],
    );
    expect(
      play(
        const Duration(seconds: 61),
        const Duration(seconds: 89),
      ).whereType<ListenedEvent>(),
      isEmpty,
    );
    expect(
      play(
        const Duration(seconds: 90),
        const Duration(seconds: 91),
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
  });

  test('buffering in the middle of a track does not re-announce', () {
    tracker.update(stateAt(Duration.zero));
    play(Duration.zero, const Duration(seconds: 5));
    tracker.update(
      stateAt(const Duration(seconds: 5), status: PlaybackStatus.buffering),
    );
    expect(tracker.update(stateAt(const Duration(seconds: 5))), isEmpty);
  });

  test('switching tracks before the threshold submits nothing', () {
    tracker.update(stateAt(Duration.zero));
    play(Duration.zero, const Duration(seconds: 30));
    final events = tracker.update(stateAt(Duration.zero, index: 1));
    expect(events, [isA<NowPlayingEvent>()]);
    expect(events.single.listen.song.id, 'long');
  });

  test('replaying a track from the start counts as a new listen', () {
    tracker.update(stateAt(Duration.zero));
    expect(
      play(
        Duration.zero,
        const Duration(minutes: 3),
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
    expect(tracker.update(stateAt(Duration.zero)), [isA<NowPlayingEvent>()]);
    expect(
      play(
        Duration.zero,
        const Duration(seconds: 91),
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
  });

  test('seeking back to the start begins a new play', () {
    tracker.update(stateAt(Duration.zero));
    play(Duration.zero, const Duration(seconds: 60));
    final restarted = tracker.update(stateAt(Duration.zero));
    expect(restarted, [isA<NowPlayingEvent>()]);
    expect(
      play(
        Duration.zero,
        const Duration(seconds: 60),
      ).whereType<ListenedEvent>(),
      isEmpty,
    );
    expect(
      play(
        const Duration(seconds: 61),
        const Duration(seconds: 91),
      ).whereType<ListenedEvent>(),
      hasLength(1),
    );
  });

  test('replaying a finished single-track queue scrobbles again', () {
    tracker.update(stateAt(Duration.zero, songs: const [short]));
    play(Duration.zero, const Duration(minutes: 3));
    tracker.update(
      stateAt(
        Duration.zero,
        status: PlaybackStatus.stopped,
        songs: const [short],
      ),
    );

    now = now.add(const Duration(minutes: 10));
    final resumedAt = now;
    final resumed = tracker.update(
      stateAt(Duration.zero, songs: const [short]),
    );
    expect(resumed, [isA<NowPlayingEvent>()]);
    expect(resumed.single.listen.listenedAt, resumedAt);

    final listened = play(
      const Duration(seconds: 1),
      const Duration(seconds: 91),
    ).whereType<ListenedEvent>().single;
    expect(listened.listen.listenedAt, resumedAt);
  });

  test('a track loaded while paused is dated from when it starts', () {
    tracker.update(stateAt(Duration.zero, status: PlaybackStatus.paused));
    now = now.add(const Duration(minutes: 2));
    final started = tracker.update(stateAt(Duration.zero));
    expect(started.single.listen.listenedAt, now);
  });

  test('an empty queue resets tracking', () {
    tracker.update(stateAt(Duration.zero));
    expect(
      tracker.update(stateAt(Duration.zero, songs: [], index: null)),
      isEmpty,
    );
    expect(tracker.current, isNull);
    expect(tracker.update(stateAt(Duration.zero)), [isA<NowPlayingEvent>()]);
  });
}
