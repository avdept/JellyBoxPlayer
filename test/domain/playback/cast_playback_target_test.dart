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
  bool finished = false,
}) => CastReceiverStatus(
  status: status,
  itemId: currentItemId,
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

  test('fails over when the session is taken away', () async {
    await load();
    await reportQueue();

    emitSession(null);
    await pumpEventQueue();

    expect(target.state.status, PlaybackStatus.error);
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

  test('holds playback when it is handed a paused queue', () async {
    await load(autoPlay: false);
    await reportQueue();

    feed.statusEvents.add(
      _status(status: PlaybackStatus.playing, currentItemId: 10),
    );
    await pumpEventQueue();

    verify(() => client.pause()).called(2);
    expect(target.state.status, isNot(PlaybackStatus.playing));
  });

  test('ends the session when it is disposed', () async {
    await load();
    await target.dispose();

    verify(() => sessions.endSessionAndStopCasting()).called(1);
  });
}
