import 'dart:async';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/cast/cast_media_feed.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/cast_playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock
    implements GoogleCastRemoteMediaClientPlatformInterface {}

class MockSessions extends Mock
    implements GoogleCastSessionManagerPlatformInterface {}

class MockDiscovery extends Mock
    implements GoogleCastDiscoveryManagerPlatformInterface {}

class _FakeFeed implements CastMediaFeed {
  final statusEvents = StreamController<CastReceiverStatus>.broadcast();
  final queueEvents = StreamController<List<CastQueueEntry>>.broadcast();
  final positionEvents = StreamController<Duration>.broadcast();

  @override
  Stream<CastReceiverStatus> get statuses => statusEvents.stream;

  @override
  Stream<List<CastQueueEntry>> get queue => queueEvents.stream;

  @override
  Stream<Duration> get positions => positionEvents.stream;

  Future<void> close() async {
    await statusEvents.close();
    await queueEvents.close();
    await positionEvents.close();
  }
}

class FakeSession extends GoogleCastSession {
  FakeSession(GoogleCastDevice device, GoogleCastConnectState state)
    : super(
        device: device,
        sessionID: 'session',
        connectionState: state,
        currentDeviceMuted: false,
        currentDeviceVolume: 0.4,
        deviceStatusText: '',
      );
}

class FakeDevice extends Fake implements GoogleCastDevice {}

class FakeSeekOption extends Fake implements GoogleCastMediaSeekOption {}

CastReceiverStatus _status({
  required PlaybackStatus status,
  int? currentItemId,
  String? contentId,
  int? mediaSessionId,
  bool finished = false,
}) => CastReceiverStatus(
  status: status,
  itemId: currentItemId,
  contentId: contentId,
  mediaSessionId: mediaSessionId,
  finished: finished,
);

CastQueueEntry _queueItem(int itemId, String contentId) =>
    CastQueueEntry(itemId: itemId, contentId: contentId);

TargetTrack _track(String id) => TargetTrack(
  itemId: id,
  uri: Uri.parse('http://192.168.1.10:8096/stream/$id'),
  mimeType: 'audio/mpeg',
  isHls: false,
  title: 'Track $id',
  duration: const Duration(minutes: 3),
);

void main() {
  late MockClient client;
  late MockSessions sessions;
  late MockDiscovery discovery;
  late StreamController<List<GoogleCastDevice>> deviceEvents;
  late StreamController<GoogleCastSession?> sessionEvents;
  late _FakeFeed feed;
  late CastPlaybackTarget target;
  GoogleCastSession? currentSession;

  final device = GoogleCastDevice(
    deviceID: 'dev-1',
    friendlyName: 'Kitchen',
    modelName: 'Chromecast Audio',
    statusText: null,
    deviceVersion: '1.0',
    isOnLocalNetwork: true,
    category: '',
    uniqueID: 'dev-1',
  );

  final tracks = [_track('a'), _track('b'), _track('c')];

  setUpAll(() {
    registerFallbackValue(FakeDevice());
    registerFallbackValue(FakeSeekOption());
  });

  setUp(() {
    client = MockClient();
    sessions = MockSessions();
    discovery = MockDiscovery();
    deviceEvents = StreamController<List<GoogleCastDevice>>.broadcast();
    sessionEvents = StreamController<GoogleCastSession?>.broadcast();
    feed = _FakeFeed();

    when(() => discovery.startDiscovery()).thenAnswer((_) async {});
    when(() => discovery.stopDiscovery()).thenAnswer((_) async {});
    when(() => discovery.devices).thenReturn([device]);
    when(() => discovery.devicesStream).thenAnswer((_) => deviceEvents.stream);

    currentSession = null;
    when(() => sessions.currentSession).thenAnswer((_) => currentSession);
    when(
      () => sessions.currentSessionStream,
    ).thenAnswer((_) => sessionEvents.stream);
    when(
      () => sessions.startSessionWithDevice(any()),
    ).thenAnswer((_) async => true);
    when(
      () => sessions.endSessionAndStopCasting(),
    ).thenAnswer((_) async => true);
    when(() => sessions.setDeviceVolume(any())).thenReturn(null);

    when(
      () => client.queueLoadItems(any(), options: any(named: 'options')),
    ).thenAnswer((_) async {});
    when(() => client.pause()).thenAnswer((_) async {});
    when(() => client.play()).thenAnswer((_) async {});
    when(() => client.seek(any())).thenAnswer((_) async {});
    when(() => client.queuePrevItem()).thenAnswer((_) async {});
    when(() => client.queueNextItem()).thenAnswer((_) async {});
    when(() => client.queueJumpToItemWithId(any())).thenAnswer((_) async {});
    when(() => client.queueRemoveItemsWithIds(any())).thenAnswer((_) async {});
    when(
      () => client.queueReorderItems(
        itemsIds: any(named: 'itemsIds'),
        beforeItemWithId: any(named: 'beforeItemWithId'),
      ),
    ).thenAnswer((_) async {});

    target = CastPlaybackTarget(
      device,
      client: client,
      sessions: sessions,
      discovery: discovery,
      feed: feed,
      attemptTimeout: const Duration(milliseconds: 200),
      pollInterval: Duration.zero,
      discoverySettle: Duration.zero,
      sessionGrace: const Duration(milliseconds: 150),
    );
  });

  void emitSession(GoogleCastSession? session) {
    currentSession = session;
    sessionEvents.add(session);
  }

  tearDown(() async {
    await deviceEvents.close();
    await sessionEvents.close();
    await feed.close();
  });

  Future<void> load({
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    final loading = target.load(
      tracks,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      autoPlay: autoPlay,
    );
    await pumpEventQueue();
    emitSession(FakeSession(device, GoogleCastConnectState.connected));
    await loading;
  }

  Future<void> reportQueue() async {
    feed.queueEvents.add([
      _queueItem(10, 'a'),
      _queueItem(11, 'b'),
      _queueItem(12, 'c'),
    ]);
    await pumpEventQueue();
  }

  test('starts a session and hands the whole queue to the receiver', () async {
    await load(initialIndex: 1, initialPosition: const Duration(seconds: 30));

    verify(() => sessions.startSessionWithDevice(device)).called(1);
    final captured = verify(
      () => client.queueLoadItems(
        captureAny(),
        options: captureAny(named: 'options'),
      ),
    ).captured;

    final items = captured.first as List<GoogleCastQueueItem>;
    expect(
      [for (final item in items) item.mediaInformation.contentId],
      ['a', 'b', 'c'],
    );
    expect(
      [for (final item in items) item.mediaInformation.contentUrl.toString()],
      [for (final track in tracks) track.uri.toString()],
    );

    final options = captured.last as GoogleCastQueueLoadOptions;
    expect(options.startIndex, 1);
    expect(options.playPosition, const Duration(seconds: 30));
  });

  test('keeps discovery running until the target is done with', () async {
    await load();

    verifyInOrder([
      () => discovery.startDiscovery(),
      () => sessions.startSessionWithDevice(device),
    ]);
    verifyNever(() => discovery.stopDiscovery());

    await target.dispose();
    verify(() => discovery.stopDiscovery()).called(1);
  });

  test('waits for the device route before asking for a session', () async {
    when(() => discovery.devices).thenReturn([]);

    final loading = target.load(
      tracks,
      initialIndex: 0,
      initialPosition: Duration.zero,
      autoPlay: true,
    );
    await pumpEventQueue();

    verifyNever(() => sessions.startSessionWithDevice(any()));

    deviceEvents.add([device]);
    await pumpEventQueue();
    emitSession(FakeSession(device, GoogleCastConnectState.connected));
    await loading;

    verify(() => sessions.startSessionWithDevice(device)).called(1);
    verify(
      () => client.queueLoadItems(any(), options: any(named: 'options')),
    ).called(1);
  });

  test('starts a fresh session when the old one is dead', () async {
    currentSession = FakeSession(device, GoogleCastConnectState.disconnected);

    await load();

    verify(() => sessions.startSessionWithDevice(device)).called(1);
    verifyNever(() => sessions.endSessionAndStopCasting());
  });

  test('reuses a session that is already connected to the device', () async {
    currentSession = FakeSession(device, GoogleCastConnectState.connected);

    await load();

    verifyNever(() => sessions.startSessionWithDevice(any()));
    verifyNever(() => sessions.endSessionAndStopCasting());
    verifyNever(() => discovery.startDiscovery());
  });

  test('leaves a session that is still connecting alone', () async {
    currentSession = FakeSession(device, GoogleCastConnectState.connecting);

    await load();

    verifyNever(() => sessions.startSessionWithDevice(any()));
    verifyNever(() => sessions.endSessionAndStopCasting());
  });

  test('asks again when the first route selection goes unanswered', () async {
    var asked = 0;
    when(() => sessions.startSessionWithDevice(any())).thenAnswer((_) async {
      if (++asked > 1) {
        currentSession = FakeSession(device, GoogleCastConnectState.connected);
      }
      return true;
    });

    await target.load(
      tracks,
      initialIndex: 0,
      initialPosition: Duration.zero,
      autoPlay: true,
    );

    expect(asked, 2);
    verify(
      () => client.queueLoadItems(any(), options: any(named: 'options')),
    ).called(1);
  });

  test('gives up and fails the load when no session ever forms', () async {
    final states = <PlaybackStatus>[];
    target.stateStream.listen((state) => states.add(state.status));

    await target.load(
      tracks,
      initialIndex: 0,
      initialPosition: Duration.zero,
      autoPlay: true,
    );
    await pumpEventQueue();

    verifyNever(
      () => client.queueLoadItems(any(), options: any(named: 'options')),
    );
    expect(states, contains(PlaybackStatus.error));
  });

  test('follows the receiver queue to work out the current track', () async {
    await load();
    await reportQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 12),
    );
    await pumpEventQueue();

    expect(target.state.currentIndex, 2);
    expect(target.state.status, PlaybackStatus.playing);
  });

  test('ignores a queue report that is not its own queue', () async {
    await load();

    feed.queueEvents.add([
      _queueItem(90, 'old-x'),
      _queueItem(91, 'old-y'),
      _queueItem(92, 'old-z'),
    ]);
    await pumpEventQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 92),
    );
    await pumpEventQueue();

    expect(target.state.currentIndex, 0);
  });

  test('follows the stale report once the receiver catches up', () async {
    await load();
    await reportQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 12),
    );
    await pumpEventQueue();

    expect(target.state.currentIndex, 2);
  });

  test('reports the queue as finished only on the last track', () async {
    await load();
    await reportQueue();

    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.stopped,
        currentItemId: 10,
        finished: true,
      ),
    );
    await pumpEventQueue();
    expect(target.state.completed, isFalse);

    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.stopped,
        currentItemId: 12,
        finished: true,
      ),
    );
    await pumpEventQueue();
    expect(target.state.completed, isTrue);
  });

  test('turns a playback error into a failed state', () async {
    await load();
    await reportQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.error, currentItemId: 10),
    );
    await pumpEventQueue();

    expect(target.state.status, PlaybackStatus.error);
  });

  test('waits for a dropped session to resume before failing over', () async {
    await load();
    await reportQueue();

    emitSession(null);
    await pumpEventQueue();
    expect(target.state.status, isNot(PlaybackStatus.error));

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(target.state.status, PlaybackStatus.error);
  });

  test('keeps a parked session for as long as it takes', () async {
    await load();
    await reportQueue();

    emitSession(FakeSession(device, GoogleCastConnectState.suspended));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(target.state.status, isNot(PlaybackStatus.error));

    emitSession(FakeSession(device, GoogleCastConnectState.connecting));
    emitSession(FakeSession(device, GoogleCastConnectState.connected));
    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 12),
    );
    await pumpEventQueue();

    expect(target.state.status, PlaybackStatus.playing);
    expect(target.state.currentIndex, 2);
  });

  test('carries on when the session comes back within the grace', () async {
    await load();
    await reportQueue();

    emitSession(null);
    await pumpEventQueue();
    emitSession(FakeSession(device, GoogleCastConnectState.connecting));
    emitSession(FakeSession(device, GoogleCastConnectState.connected));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(target.state.status, isNot(PlaybackStatus.error));
  });

  test(
    'sets a volume asked for before connecting ahead of the queue',
    () async {
      await target.setVolume(0.1);
      verifyNever(() => sessions.setDeviceVolume(any()));
      verifyNever(() => sessions.startSessionWithDevice(any()));

      await load();

      verifyInOrder([
        () => sessions.setDeviceVolume(0.1),
        () => client.queueLoadItems(any(), options: any(named: 'options')),
      ]);
    },
  );

  test(
    'reloads the queue when the receiver has not listed its items',
    () async {
      await load();

      await target.reorder(
        [tracks[2], tracks[1], tracks[0]],
        order: [2, 1, 0],
        currentIndex: 2,
      );

      verifyNever(
        () => client.queueReorderItems(
          itemsIds: any(named: 'itemsIds'),
          beforeItemWithId: any(named: 'beforeItemWithId'),
        ),
      );
      final captured = verify(
        () => client.queueLoadItems(
          captureAny(),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      final items = captured[2] as List<GoogleCastQueueItem>;
      final options = captured[3] as GoogleCastQueueLoadOptions;
      expect(
        [for (final item in items) item.mediaInformation.contentId],
        ['c', 'b', 'a'],
      );
      expect(options.startIndex, 2);
    },
  );

  test('follows the receiver by stream URL when it drops the id', () async {
    await load();
    feed.queueEvents.add([
      CastQueueEntry(itemId: 10, contentUrl: tracks[0].uri.toString()),
      CastQueueEntry(itemId: 11, contentUrl: tracks[1].uri.toString()),
      CastQueueEntry(itemId: 12, contentUrl: tracks[2].uri.toString()),
    ]);
    await pumpEventQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 11),
    );
    await pumpEventQueue();

    expect(target.state.currentIndex, 1);
    await target.remove(2);
    verify(() => client.queueRemoveItemsWithIds([12])).called(1);
  });

  test('moves a queue item in front of the item it lands on', () async {
    await load();
    await reportQueue();

    await target.move(2, 0);
    verify(
      () => client.queueReorderItems(itemsIds: [12], beforeItemWithId: 10),
    ).called(1);

    await target.move(0, 2);
    verify(
      () => client.queueReorderItems(itemsIds: [12], beforeItemWithId: null),
    ).called(1);
  });

  test('removes and reorders by receiver item id', () async {
    await load();
    await reportQueue();

    await target.remove(1);
    verify(() => client.queueRemoveItemsWithIds([11])).called(1);

    feed.queueEvents.add([_queueItem(10, 'a'), _queueItem(12, 'c')]);
    await pumpEventQueue();

    await target.reorder(
      [tracks[2], tracks[0]],
      order: [1, 0],
      currentIndex: 0,
    );
    verify(
      () => client.queueReorderItems(
        itemsIds: [12, 10],
        beforeItemWithId: null,
      ),
    ).called(1);
  });

  test('keeps the playing item and swaps everything around it', () async {
    when(
      () => client.queueInsertItems(
        any(),
        beforeItemWithId: any(named: 'beforeItemWithId'),
      ),
    ).thenAnswer((_) async {});
    await load(initialIndex: 1);
    await reportQueue();

    final upcoming = [_track('x'), _track('y')];
    await target.replaceAroundCurrent(1, upcoming);

    verify(() => client.queueRemoveItemsWithIds([10, 12])).called(1);
    final inserted =
        verify(
              () => client.queueInsertItems(
                captureAny(),
                beforeItemWithId: null,
              ),
            ).captured.single
            as List<GoogleCastQueueItem>;
    expect(
      [for (final item in inserted) item.mediaInformation.contentId],
      ['x', 'y'],
    );
    expect(target.state.currentIndex, 0);
  });

  test('restarts the track unless it has only just started', () async {
    await load();
    await reportQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 11),
    );
    feed.positionEvents.add(const Duration(seconds: 12));
    await pumpEventQueue();

    await target.seekToPrevious();
    verifyNever(() => client.queuePrevItem());
    verify(() => client.seek(any())).called(1);

    feed.positionEvents.add(const Duration(seconds: 1));
    await pumpEventQueue();

    await target.seekToPrevious();
    verify(() => client.queuePrevItem()).called(1);
  });

  test('loads a paused queue without starting it', () async {
    await load(autoPlay: false, initialPosition: const Duration(seconds: 3));

    final options =
        verify(
              () => client.queueLoadItems(
                any(),
                options: captureAny(named: 'options'),
              ),
            ).captured.single
            as GoogleCastQueueLoadOptions;
    expect(options.autoPlay, isFalse);
    expect(options.playPosition, const Duration(seconds: 3));
    verifyNever(() => client.pause());
    expect(target.state.status, PlaybackStatus.paused);
  });

  test('seeks without changing whether it plays', () async {
    await load();
    await target.seek(const Duration(milliseconds: 61500));

    final option =
        verify(() => client.seek(captureAny())).captured.single
            as GoogleCastMediaSeekOption;
    expect(option.position, const Duration(milliseconds: 61500));
    expect(option.resumeState, GoogleCastMediaResumeState.unchanged);
  });

  test('lets go of the speaker when another sender loads it', () async {
    when(() => sessions.endSession()).thenAnswer((_) async => true);
    await load();
    await reportQueue();
    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.playing,
        currentItemId: 10,
        contentId: 'a',
        mediaSessionId: 7,
      ),
    );
    await pumpEventQueue();

    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.playing,
        currentItemId: 1,
        contentId: 'somebody-elses-song',
        mediaSessionId: 8,
      ),
    );
    await pumpEventQueue();

    expect(target.state.status, PlaybackStatus.error);
    expect(target.state.takenOver, isTrue);

    await target.stop();
    verifyNever(() => client.stop());
    await target.dispose();
    verify(() => sessions.endSession()).called(1);
    verifyNever(() => sessions.endSessionAndStopCasting());
  });

  test('does not mistake a late report for a takeover', () async {
    await load();
    await reportQueue();
    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.playing,
        currentItemId: 11,
        contentId: 'b',
        mediaSessionId: 7,
      ),
    );
    await pumpEventQueue();

    await target.remove(1);
    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.playing,
        currentItemId: 11,
        contentId: 'b',
        mediaSessionId: 7,
      ),
    );
    await pumpEventQueue();

    expect(target.state.status, PlaybackStatus.playing);
    expect(target.state.takenOver, isFalse);
  });

  test('ignores what the receiver played before its own queue', () async {
    await load();
    feed.statusEvents.add(
      _status(
        status: PlaybackStatus.playing,
        currentItemId: 3,
        contentId: 'left-over-from-before',
        mediaSessionId: 2,
      ),
    );
    await pumpEventQueue();

    expect(target.state.takenOver, isFalse);
    expect(target.state.status, isNot(PlaybackStatus.error));
  });

  test('ends the session when it is disposed', () async {
    await load();
    await target.dispose();

    verify(() => sessions.endSessionAndStopCasting()).called(1);
  });
}
