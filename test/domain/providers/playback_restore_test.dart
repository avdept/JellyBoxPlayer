import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/cast_session_resume.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/pending_media_play_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  int plays = 0;
  bool playOnLoad = false;
  final loads = <({int index, Duration position, bool autoPlay})>[];

  TargetPlaybackState _state = TargetPlaybackState.idle;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.localPlayer(isAndroid: false);

  @override
  bool get supportsLocalFiles => true;

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    loads.add((
      index: initialIndex,
      position: initialPosition,
      autoPlay: autoPlay,
    ));
    _state = TargetPlaybackState(
      status: playOnLoad ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: initialPosition,
      currentIndex: initialIndex,
    );
    _controller.add(_state);
  }

  @override
  Future<void> play() async => plays++;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

class _MockCastResume extends Mock implements CastSessionResume {}

class _MockAvTransport extends Mock implements AvTransport {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late _FakeTarget target;
  late MediaServerClient client;
  late int pendingTakes;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        duration: const Duration(minutes: 5),
      ),
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('playback_restore_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
    registerFallbackValue(Uri.parse('http://example.org'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    deviceId = 'test-device';
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    target = _FakeTarget();
    client = _MockMediaServerClient();
    pendingTakes = 0;
    when(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer(
      (_) async => StreamSource(
        uri: Uri.parse('http://server/audio/stream'),
        isHls: false,
        outputContainer: 'flac',
        mimeType: 'audio/flac',
      ),
    );
    when(() => client.reportPlaybackStarted(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackStopped(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackProgress(any())).thenAnswer((_) async {});
  });

  ProviderContainer containerWith({
    required bool pendingPress,
    bool offline = false,
    CastSessionResume? castResume,
  }) {
    final container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(offline),
        pendingMediaPlayProvider.overrideWithValue(() {
          pendingTakes++;
          return pendingPress;
        }),
        if (castResume != null)
          castSessionResumeProvider.overrideWithValue(castResume),
      ],
    );
    container.read(currentServerIdProvider.notifier).state = 'srv';
    addTearDown(() async {
      await container.read(playbackProvider.notifier).clear();
      container.dispose();
    });
    return container;
  }

  Future<void> saveQueue({String? sourceId, String serverId = 'srv'}) =>
      PlaybackStorage().save(
        serverId: serverId,
        songs: songs,
        album: album,
        songId: 'b',
        positionMs: 90000,
        sourceId: sourceId,
      );

  test(
    '- restores the saved queue paused when nothing asked to play',
    () async {
      await saveQueue();
      final container = containerWith(pendingPress: false);

      final restored = await container
          .read(playbackProvider.notifier)
          .tryRestore();

      expect(restored, isTrue);
      expect(target.loads.single.index, 1);
      expect(target.loads.single.position, const Duration(seconds: 90));
      expect(target.loads.single.autoPlay, isFalse);
      expect(target.plays, 0);
      expect(container.read(playbackProvider).status, PlaybackStatus.paused);
    },
  );

  test('- plays the restored queue for a press that woke the app', () async {
    await saveQueue();
    final container = containerWith(pendingPress: true);

    await container.read(playbackProvider.notifier).tryRestore();

    expect(target.plays, 1);
    expect(container.read(playbackProvider).status, PlaybackStatus.playing);
  });

  test('- follows a player that already started during the restore', () async {
    await saveQueue();
    target.playOnLoad = true;
    final container = containerWith(pendingPress: false);

    await container.read(playbackProvider.notifier).tryRestore();

    expect(container.read(playbackProvider).status, PlaybackStatus.playing);
  });

  test('- drops a pending press when there is nothing to restore', () async {
    final container = containerWith(pendingPress: true);

    final restored = await container
        .read(playbackProvider.notifier)
        .tryRestore();

    expect(restored, isFalse);
    expect(pendingTakes, 1);
    expect(target.loads, isEmpty);
    expect(target.plays, 0);
  });

  test('- leaves alone a queue that arrived while it was loading', () async {
    await saveQueue();
    final container = containerWith(pendingPress: true);
    final playback = container.read(playbackProvider.notifier);
    final handedOff = [songs.last];

    final restoring = playback.tryRestore();
    await playback.play(songs.last, handedOff, album);

    expect(await restoring, isFalse);
    expect(pendingTakes, 1);
    expect(target.loads, hasLength(1));
    expect(target.loads.single.autoPlay, isTrue);
    expect(container.read(playbackProvider).songs.map((s) => s.id), ['c']);
  });

  test('- a newer queue wins over one still being prepared', () async {
    final gate = Completer<void>();
    when(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((invocation) async {
      final song = invocation.positionalArguments.first as LibraryItem;
      if (song.id == 'a') await gate.future;
      return StreamSource(
        uri: Uri.parse('http://server/audio/${song.id}'),
        isHls: false,
        outputContainer: 'flac',
        mimeType: 'audio/flac',
      );
    });
    final container = containerWith(pendingPress: false);
    final playback = container.read(playbackProvider.notifier);

    final older = playback.play(songs.first, songs, album);
    await pumpEventQueue();
    await playback.play(songs.last, [songs.last], album);
    gate.complete();
    await older;

    expect(target.loads, hasLength(1));
    expect(container.read(playbackProvider).songs.map((s) => s.id), ['c']);
  });

  test("- ignores another server's queue and leaves it in place", () async {
    await saveQueue(serverId: 'other');
    final container = containerWith(pendingPress: false);

    final restored = await container
        .read(playbackProvider.notifier)
        .tryRestore();

    expect(restored, isFalse);
    expect(target.loads, isEmpty);
    expect((await PlaybackStorage().load('other'))?.songId, 'b');
  });

  test('- adopts a pre-multi-server snapshot for the active server', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pb_songs',
      jsonEncode(songs.map((s) => s.toJson()).toList()),
    );
    await prefs.setString('pb_album', jsonEncode(album.toJson()));
    await prefs.setString('pb_song_id', 'b');
    await prefs.setInt('pb_position_ms', 90000);

    final snapshot = await PlaybackStorage().load('srv');

    expect(snapshot?.songId, 'b');
    expect(snapshot?.positionMs, 90000);
    expect(prefs.getString('pb_songs'), isNull);
    expect(await PlaybackStorage().load('other'), isNull);
  });

  test('- each server keeps its own snapshot', () async {
    await saveQueue();
    await PlaybackStorage().save(
      serverId: 'other',
      songs: [songs.first],
      album: album,
      songId: 'a',
      positionMs: 1000,
    );

    expect((await PlaybackStorage().load('srv'))?.songId, 'b');
    expect((await PlaybackStorage().load('other'))?.songId, 'a');

    await PlaybackStorage().clear('other');

    expect(await PlaybackStorage().load('other'), isNull);
    expect((await PlaybackStorage().load('srv'))?.songId, 'b');
  });

  test('- restores which set the queue was started from', () async {
    await saveQueue(sourceId: 'album');
    final container = containerWith(pendingPress: false);

    await container.read(playbackProvider.notifier).tryRestore();

    expect(container.read(playbackProvider).sourceId, 'album');
  });

  test(
    '- drops the source when a loose song list replaces the queue',
    () async {
      final container = containerWith(pendingPress: false);
      final playback = container.read(playbackProvider.notifier);

      await playback.play(songs.first, songs, album, sourceId: 'album');
      await pumpEventQueue();
      expect((await PlaybackStorage().load('srv'))?.sourceId, 'album');

      await playback.play(songs.last, songs, album);

      expect(container.read(playbackProvider).sourceId, isNull);
      await pumpEventQueue();
      expect((await PlaybackStorage().load('srv'))?.sourceId, isNull);
    },
  );

  group('offline at launch', () {
    test('- restores the whole streamed queue paused', () async {
      await saveQueue();
      final container = containerWith(pendingPress: false, offline: true);

      final restored = await container
          .read(playbackProvider.notifier)
          .tryRestore();

      expect(restored, isTrue);
      expect(
        container.read(playbackProvider).songs.map((s) => s.id),
        ['a', 'b', 'c'],
      );
      expect(target.loads.single.index, 1);
      expect(target.loads.single.position, const Duration(seconds: 90));
      expect(container.read(playbackProvider).status, PlaybackStatus.paused);
    });

    test('- still plays it for a press that woke the app', () async {
      await saveQueue();
      final container = containerWith(pendingPress: true, offline: true);

      await container.read(playbackProvider.notifier).tryRestore();

      expect(target.plays, 1);
    });

    test('- a fresh queue started offline still skips streams', () async {
      final container = containerWith(pendingPress: false, offline: true);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);

      expect(target.loads, isEmpty);
      expect(container.read(playbackProvider).status, PlaybackStatus.error);
    });
  });

  group('cast session re-attach', () {
    late _MockAvTransport transport;
    late _MockCastResume castResume;

    UpnpRenderer renderer() => UpnpRenderer(
      device: UpnpDevice(
        udn: 'uuid:kef',
        friendlyName: 'KEF LS50',
        deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
        location: Uri.parse('http://192.168.0.20:49152/description.xml'),
        services: const [],
      ),
      avTransport: transport,
    );

    setUp(() {
      transport = _MockAvTransport();
      castResume = _MockCastResume();
      when(() => transport.supportsNextUri).thenReturn(true);
      when(() => transport.supportsSeek).thenReturn(true);
      when(() => transport.supportsPause).thenReturn(true);
      when(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      ).thenAnswer((_) async {});
      when(transport.play).thenAnswer((_) async {});
      when(transport.stopTransport).thenAnswer((_) async {});
      when(transport.transportInfo).thenAnswer(
        (_) async => const AvTransportInfo(
          state: AvTransportState.playing,
          status: 'OK',
        ),
      );
      when(transport.positionInfo).thenAnswer(
        (_) async => const AvPositionInfo(position: Duration(seconds: 95)),
      );
      when(() => castResume.find(any())).thenAnswer((_) async => null);
      when(
        () => client.resolveStreamSource(
          any(),
          playSessionId: any(named: 'playSessionId'),
          target: any(named: 'target'),
        ),
      ).thenAnswer((invocation) async {
        final song = invocation.positionalArguments.first as LibraryItem;
        return StreamSource(
          uri: Uri.parse('http://192.168.0.9:8096/Audio/${song.id}/universal'),
          isHls: false,
          outputContainer: 'flac',
          mimeType: 'audio/flac',
        );
      });
    });

    void rendererPlays(
      String songId, {
      Duration position = const Duration(seconds: 95),
      bool playing = true,
    }) {
      when(() => castResume.find('srv')).thenAnswer(
        (_) async => ResumableCastSession(
          renderer: renderer(),
          playing: playing,
          trackUri: Uri.parse(
            'http://192.168.0.9:8096/Audio/$songId/universal'
            '?PlaySessionId=before-the-crash',
          ),
          position: position,
        ),
      );
    }

    test('- re-attaches to a renderer still playing the saved queue',
        () async {
      await saveQueue();
      rendererPlays('b');
      final container = containerWith(
        pendingPress: false,
        castResume: castResume,
      );

      final restored = await container
          .read(playbackProvider.notifier)
          .tryRestore();

      expect(restored, isTrue);
      expect(target.loads, isEmpty);
      final active = container.read(playbackTargetProvider);
      expect(active, isA<UpnpPlaybackTarget>());
      expect(active.id, 'uuid:kef');
      final state = container.read(playbackProvider);
      expect(state.status, PlaybackStatus.playing);
      expect(state.currentMediaIndex, 1);
      expect(state.position, const Duration(seconds: 95));
      verifyNever(
        () => transport.setUri(any(), metadata: any(named: 'metadata')),
      );
      verifyNever(transport.play);
      verify(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      ).called(1);
    });

    test('- follows the renderer past the track the snapshot saved',
        () async {
      await saveQueue();
      rendererPlays('c', position: const Duration(seconds: 5));
      final container = containerWith(
        pendingPress: false,
        castResume: castResume,
      );

      await container.read(playbackProvider.notifier).tryRestore();

      final state = container.read(playbackProvider);
      expect(state.currentMediaIndex, 2);
      expect(state.position, const Duration(seconds: 5));
    });

    test('- adopts a paused renderer without resuming it', () async {
      await saveQueue();
      rendererPlays('b', playing: false);
      final container = containerWith(
        pendingPress: false,
        castResume: castResume,
      );

      await container.read(playbackProvider.notifier).tryRestore();

      expect(container.read(playbackProvider).status, PlaybackStatus.paused);
      verifyNever(transport.play);
    });

    test('- a press that woke the app resumes the paused renderer', () async {
      await saveQueue();
      rendererPlays('b', playing: false);
      final container = containerWith(
        pendingPress: true,
        castResume: castResume,
      );

      await container.read(playbackProvider.notifier).tryRestore();

      verify(transport.play).called(1);
      expect(container.read(playbackProvider).status, PlaybackStatus.playing);
    });

    test(
      '- restores locally when the renderer plays something else',
      () async {
        await saveQueue();
        rendererPlays('not-in-the-queue');
        final container = containerWith(
          pendingPress: false,
          castResume: castResume,
        );

        final restored = await container
            .read(playbackProvider.notifier)
            .tryRestore();

        expect(restored, isTrue);
        expect(target.loads.single.index, 1);
        expect(
          container.read(playbackTargetProvider).kind,
          PlaybackTargetKind.local,
        );
      },
    );

    test('- does not look for a cast session offline', () async {
      await saveQueue();
      rendererPlays('b');
      final container = containerWith(
        pendingPress: false,
        offline: true,
        castResume: castResume,
      );

      final restored = await container
          .read(playbackProvider.notifier)
          .tryRestore();

      expect(restored, isTrue);
      verifyNever(() => castResume.find(any()));
      expect(target.loads, hasLength(1));
    });
  });
}
