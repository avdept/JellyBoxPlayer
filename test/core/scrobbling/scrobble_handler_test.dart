import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobble_handler.dart';
import 'package:jplayer/src/core/scrobbling/scrobble_queue.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  PlaybackState get current => state;

  set current(PlaybackState next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubConnectivity extends StateNotifier<bool>
    implements ConnectivityNotifier {
  _StubConnectivity() : super(true);

  bool get online => state;

  set online(bool value) => state = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeScrobbler implements Scrobbler {
  _FakeScrobbler(this.id, this.container, ScrobblerAvailability initial)
    : state = StateProvider((ref) => initial);

  @override
  final String id;
  final ProviderContainer container;
  final StateProvider<ScrobblerAvailability> state;
  final nowPlaying = <Listen>[];
  final scrobbled = <List<Listen>>[];
  ScrobbleException? failWith;
  int unauthorized = 0;

  @override
  int get maxBatchSize => 50;

  @override
  ProviderListenable<ScrobblerAvailability> get availability => state;

  ScrobblerAvailability get current => container.read(state);

  set current(ScrobblerAvailability next) =>
      container.read(state.notifier).state = next;

  @override
  Future<void> updateNowPlaying(Listen listen) async {
    if (failWith case final error?) throw error;
    nowPlaying.add(listen);
  }

  @override
  Future<void> scrobble(List<Listen> listens) async {
    if (failWith case final error?) throw error;
    scrobbled.add(listens);
  }

  @override
  void onUnauthorized() {
    unauthorized++;
    current = ScrobblerAvailability.suspended;
  }
}

void main() {
  const album = LibraryItem(id: 'album', name: 'Dummy', kind: ItemKind.album);
  const song = LibraryItem(
    id: 'song',
    name: 'Sour Times',
    kind: ItemKind.song,
    albumArtist: 'Portishead',
    duration: Duration(minutes: 2),
  );

  late _StubPlayback playback;
  late _StubConnectivity connectivity;
  late ProviderContainer container;
  late _FakeScrobbler primary;
  late _FakeScrobbler secondary;
  late Map<String, ScrobbleQueue> queues;

  PlaybackState stateAt(
    Duration position, {
    PlaybackStatus status = PlaybackStatus.playing,
  }) => PlaybackState(
    album: album,
    songs: const [song],
    status: status,
    position: position,
    cacheProgress: Duration.zero,
    currentMediaIndex: 0,
  );

  Future<void> settle() async {
    await pumpEventQueue();
    await ScrobbleHandler.idle;
    await pumpEventQueue();
  }

  Future<void> listenThrough() async {
    for (var second = 0; second <= 61; second++) {
      playback.current = stateAt(Duration(seconds: second));
    }
    await settle();
  }

  void start({
    ScrobblerAvailability primaryState = ScrobblerAvailability.enabled,
    ScrobblerAvailability secondaryState = ScrobblerAvailability.disabled,
  }) {
    primary = _FakeScrobbler('primary', container, primaryState);
    secondary = _FakeScrobbler('secondary', container, secondaryState);
    queues = {
      for (final scrobbler in [primary, secondary])
        scrobbler.id: ScrobbleQueue(scrobbler.id),
    };
    ScrobbleHandler.initialize(
      container,
      scrobblers: [primary, secondary],
      queueFor: (scrobbler) => queues[scrobbler.id]!,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    playback = _StubPlayback();
    connectivity = _StubConnectivity();
    container = createProviderContainer(
      overrides: [
        playbackProvider.overrideWith((ref) => playback),
        connectivityProvider.overrideWith((ref) => connectivity),
      ],
    );
    ScrobbleHandler.reset();
  });

  tearDown(ScrobbleHandler.reset);

  test('sends now playing to enabled scrobblers only', () async {
    start();
    playback.current = stateAt(Duration.zero);
    await settle();

    expect(primary.nowPlaying.single.song.id, 'song');
    expect(primary.nowPlaying.single.album, album);
    expect(secondary.nowPlaying, isEmpty);
  });

  test('scrobbles a completed listen to every enabled scrobbler', () async {
    start(secondaryState: ScrobblerAvailability.enabled);
    await listenThrough();

    expect(primary.scrobbled.single.single.song.id, 'song');
    expect(secondary.scrobbled.single.single.song.id, 'song');
    expect(await queues['primary']!.pending(), isEmpty);
    expect(await queues['secondary']!.pending(), isEmpty);
  });

  test('ignores playback while nothing is enabled', () async {
    start(primaryState: ScrobblerAvailability.disabled);
    await listenThrough();
    expect(primary.scrobbled, isEmpty);
    expect(primary.nowPlaying, isEmpty);
  });

  test('a scrobbler enabled mid-track gets now playing right away', () async {
    start();
    playback
      ..current = stateAt(Duration.zero)
      ..current = stateAt(const Duration(seconds: 10));
    await settle();

    secondary.current = ScrobblerAvailability.enabled;
    await settle();

    expect(secondary.nowPlaying.single.song.id, 'song');
    expect(primary.nowPlaying, hasLength(1));
  });

  test('a failure in one scrobbler does not affect another', () async {
    start(secondaryState: ScrobblerAvailability.enabled);
    secondary.failWith = ScrobbleException.fromStatus(503, 'down');
    await listenThrough();

    expect(primary.scrobbled, hasLength(1));
    expect(secondary.scrobbled, isEmpty);
    expect(await queues['secondary']!.pending(), hasLength(1));
    expect(await queues['primary']!.pending(), isEmpty);
  });

  test('keeps failed listens queued and flushes when back online', () async {
    start();
    primary.failWith = ScrobbleException.fromStatus(503, 'down');
    await listenThrough();
    expect(await queues['primary']!.pending(), hasLength(1));

    primary.failWith = null;
    connectivity.online = false;
    await pumpEventQueue();
    connectivity.online = true;
    await settle();

    expect(primary.scrobbled.single, hasLength(1));
    expect(await queues['primary']!.pending(), isEmpty);
  });

  test('flushes queued listens in one batch when enabled', () async {
    final queue = ScrobbleQueue('primary');
    for (var i = 0; i < 3; i++) {
      await queue.add(
        Listen(
          song: song,
          album: album,
          listenedAt: DateTime.utc(2026, 9, 20, 12, i),
        ),
      );
    }
    start(primaryState: ScrobblerAvailability.disabled);
    primary.current = ScrobblerAvailability.enabled;
    await settle();

    expect(primary.scrobbled.single, hasLength(3));
    expect(await queues['primary']!.pending(), isEmpty);
  });

  test('suspends the scrobbler on unauthorized and keeps the listen', () async {
    start();
    primary.failWith = ScrobbleException.fromStatus(401, 'nope');
    await listenThrough();

    expect(primary.unauthorized, greaterThanOrEqualTo(1));
    expect(container.read(primary.state), ScrobblerAvailability.suspended);
    expect(await queues['primary']!.pending(), hasLength(1));
  });

  test('drops listens the service rejects as malformed', () async {
    start();
    primary.failWith = ScrobbleException.fromStatus(400, 'bad');
    await listenThrough();
    expect(await queues['primary']!.pending(), isEmpty);
  });

  test('disabling a scrobbler clears its pending queue', () async {
    start();
    primary.failWith = ScrobbleException.fromStatus(503, 'down');
    await listenThrough();
    expect(await queues['primary']!.pending(), hasLength(1));

    primary.current = ScrobblerAvailability.disabled;
    await settle();
    expect(await queues['primary']!.pending(), isEmpty);
  });
}
