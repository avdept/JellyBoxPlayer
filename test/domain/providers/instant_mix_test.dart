import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  final loaded = <({List<TargetTrack> tracks, int at})>[];
  final replaced = <({int current, List<TargetTrack> upcoming})>[];

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
  TargetPlaybackState get state => TargetPlaybackState.idle;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    loaded.add((tracks: tracks, at: initialIndex));
  }

  @override
  Future<void> replaceAroundCurrent(
    int currentIndex,
    List<TargetTrack> upcoming,
  ) async {
    replaced.add((current: currentIndex, upcoming: upcoming));
  }

  @override
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

LibraryItem _song(String id) => LibraryItem(
  id: id,
  name: 'song $id',
  kind: ItemKind.song,
  duration: const Duration(minutes: 4),
);

List<String> _ids(List<LibraryItem> items) => [
  for (final item in items) item.id,
];

List<String> _trackIds(List<TargetTrack> tracks) => [
  for (final track in tracks) track.itemId,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProviderContainer container;
  final restarted = <ProviderContainer>[];
  late _FakeTarget target;
  late MediaServerClient client;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final queue = [
    for (final id in ['a', 'b', 'c', 'd']) _song(id),
  ];

  var tick = 0;
  DateTime nextMoment() =>
      DateTime.fromMillisecondsSinceEpoch(1700000000000 + 1000 * tick++);

  ProviderContainer newContainer({String? userId}) => ProviderContainer(
    overrides: [
      instantMixesProvider.overrideWith(
        (ref) => InstantMixesNotifier(
          ref,
          ref.watch(instantMixDatabaseProvider),
          now: nextMoment,
        ),
      ),
      localPlaybackTargetProvider.overrideWithValue(target),
      mediaServerClientProvider.overrideWith((_) => client),
      isOfflineProvider.overrideWithValue(false),
      if (userId != null)
        currentUserProvider.overrideWith(
          (_) => User(userId: userId, token: 'token'),
        ),
    ],
  );

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('instant_mix_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(queue.first);
    registerFallbackValue(ItemKind.song);
    registerFallbackValue(<String>[]);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    deviceId = 'test-device';
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    target = _FakeTarget();
    client = _MockMediaServerClient();
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

    container = newContainer();
  });

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
    for (final other in restarted) {
      other.dispose();
    }
    restarted.clear();
  });

  void mixReturns(String seedId, List<LibraryItem> songs) => when(
    () => client.getInstantMix(seedId, limit: any(named: 'limit')),
  ).thenAnswer((_) async => songs);

  group('- creating a mix', () {
    test('- a song seed leads the mix even when the server omits it', () async {
      final seed = _song('seed');
      mixReturns('seed', [_song('x'), _song('y')]);

      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(seed);

      expect(_ids(mix!.songs), ['seed', 'x', 'y']);
      expect(mix.item.name, "song seed's mix");
      expect(isInstantMixId(mix.item.id), isTrue);
    });

    test('- a song seed returned mid-mix moves to the front once', () async {
      final seed = _song('seed');
      mixReturns('seed', [_song('x'), _song('seed'), _song('y')]);

      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(seed);

      expect(_ids(mix!.songs), ['seed', 'x', 'y']);
    });

    test('- an album seed keeps the server order', () async {
      const seed = LibraryItem(id: 'alb', name: 'Alb', kind: ItemKind.album);
      mixReturns('alb', [_song('x'), _song('y')]);

      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(seed);

      expect(_ids(mix!.songs), ['x', 'y']);
    });

    test('- an empty answer creates nothing', () async {
      mixReturns('seed', const []);

      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(_song('seed'));

      expect(mix, isNull);
      expect(container.read(instantMixesProvider), isEmpty);
    });

    test('- every mix gets its own timestamped id', () async {
      final notifier = container.read(instantMixesProvider.notifier);
      mixReturns('seed', [_song('x')]);

      final first = await notifier.create(_song('seed'));
      final second = await notifier.create(_song('seed'));

      expect(first!.item.id, isNot(second!.item.id));
      final parsed = EphemeralPlaylistId.parse(second.item.id)!;
      expect(parsed.kind, EphemeralPlaylistKind.instantMix);
      expect(parsed.key, 'seed');
      expect(parsed.createdAt, isNotNull);
      expect(container.read(instantMixesProvider), hasLength(2));
    });

    test('- recents are newest first and capped', () async {
      final notifier = container.read(instantMixesProvider.notifier);
      for (var i = 0; i < recentInstantMixesLimit + 1; i++) {
        mixReturns('s$i', [_song('x')]);
        await notifier.create(_song('s$i'));
      }
      mixReturns('s2', [_song('x')]);
      await notifier.create(_song('s2'));

      final seeds = [
        for (final mix in container.read(instantMixesProvider)) mix.seed.id,
      ];
      expect(seeds, ['s2', 's5', 's4', 's3', 's2']);
    });
  });

  group('- a mix from a sound search', () {
    test('- is named after the query and keeps the match order', () {
      final mix = container.read(instantMixesProvider.notifier).createSoundMix(
        'calm piano',
        [_song('b'), _song('a')],
      );

      expect(mix!.item.name, 'Calm piano Mix');
      expect(mix.item.id, startsWith('instant-mix:sound:calm piano:'));
      final parsed = EphemeralPlaylistId.parse(mix.item.id)!;
      expect(parsed.kind, EphemeralPlaylistKind.soundMix);
      expect(parsed.key, 'calm piano');
      expect(_ids(mix.songs), ['b', 'a']);
      expect(container.read(instantMixesProvider).single.item.id, mix.item.id);
    });

    test('- asking again for the same query makes a new mix', () {
      final notifier = container.read(instantMixesProvider.notifier);
      notifier.createSoundMix('Calm Piano', [_song('a')]);
      notifier.createSoundMix('calm piano', [_song('b')]);

      final mixes = container.read(instantMixesProvider);
      expect(mixes, hasLength(2));
      expect(_ids(mixes.first.songs), ['b']);
      expect(mixes.first.item.id, isNot(mixes.last.item.id));
    });

    test('- nothing is created without matches', () {
      final mix = container
          .read(instantMixesProvider.notifier)
          .createSoundMix('silence', const []);

      expect(mix, isNull);
      expect(container.read(instantMixesProvider), isEmpty);
    });
  });

  group('- playing a mix', () {
    test('- from the playing song keeps it and swaps the rest', () async {
      final playback = container.read(playbackProvider.notifier);
      await playback.play(queue[2], queue, album);
      final positionBefore = container.read(playbackProvider).position;

      mixReturns('c', [_song('c'), _song('x'), _song('y')]);
      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(queue[2]);
      final result = await container
          .read(setPlaybackProvider.notifier)
          .playInstantMix(mix!);

      expect(result, SetPlaybackResult.started);
      expect(target.loaded, hasLength(1));
      final replace = target.replaced.single;
      expect(replace.current, 2);
      expect(_trackIds(replace.upcoming), ['x', 'y']);

      final state = container.read(playbackProvider);
      expect(_ids(state.songs), ['c', 'x', 'y']);
      expect(state.currentMediaIndex, 0);
      expect(state.position, positionBefore);
      expect(state.album?.id, mix.item.id);
      expect(state.sourceId, mix.item.id);
    });

    test('- from another song starts the mix at its seed', () async {
      final playback = container.read(playbackProvider.notifier);
      await playback.play(queue[0], queue, album);

      mixReturns('c', [_song('x'), _song('y')]);
      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(queue[2]);
      await container.read(setPlaybackProvider.notifier).playInstantMix(mix!);

      expect(target.replaced, isEmpty);
      expect(target.loaded, hasLength(2));
      expect(_trackIds(target.loaded.last.tracks), ['c', 'x', 'y']);
      expect(target.loaded.last.at, 0);
    });

    test('- an album seed always reloads the queue', () async {
      final playback = container.read(playbackProvider.notifier);
      await playback.play(queue[0], queue, album);

      mixReturns('album', [_song('a'), _song('x')]);
      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(album);
      await container.read(setPlaybackProvider.notifier).playInstantMix(mix!);

      expect(target.replaced, isEmpty);
      expect(_trackIds(target.loaded.last.tracks), ['a', 'x']);
    });

    test('- with shuffle on, the playing song stays first', () async {
      final playback = container.read(playbackProvider.notifier);
      await playback.play(queue[1], queue, album);
      await playback.setShuffle(enabled: true);

      final songs = [
        _song('b'),
        for (final id in ['p', 'q', 'r', 's']) _song(id),
      ];
      mixReturns('b', songs);
      final mix = await container
          .read(instantMixesProvider.notifier)
          .create(queue[1]);
      await container.read(setPlaybackProvider.notifier).playInstantMix(mix!);

      final state = container.read(playbackProvider);
      expect(state.songs.first.id, 'b');
      expect(state.currentMediaIndex, 0);
      expect(_ids(state.songs), unorderedEquals(_ids(songs)));
      expect(
        _trackIds(target.replaced.single.upcoming),
        _ids(state.songs).skip(1),
      );
    });
  });

  group('- persisting mixes', () {
    Future<ProviderContainer> signedIn(String userId) async {
      final signedIn = newContainer(userId: userId);
      restarted.add(signedIn);
      await signedIn.read(instantMixesProvider.notifier).restored;
      return signedIn;
    }

    Future<void> flush(ProviderContainer session) =>
        session.read(instantMixDatabaseProvider).getMixes();

    List<String> seedsOf(ProviderContainer session) => [
      for (final mix in session.read(instantMixesProvider)) mix.seed.id,
    ];

    void serverHas(List<LibraryItem> songs) {
      final byId = {for (final song in songs) song.id: song};
      when(() => client.getItemsByIds(any())).thenAnswer((invocation) async {
        final ids = invocation.positionalArguments.first as List<String>;
        return [
          for (final id in ids) ?byId[id],
        ];
      });
    }

    Future<void> createMixes(
      ProviderContainer session,
      List<String> seeds,
    ) async {
      final notifier = session.read(instantMixesProvider.notifier);
      for (final seed in seeds) {
        mixReturns(seed, [_song(seed), _song('$seed-x')]);
        await notifier.create(_song(seed));
      }
      await flush(session);
    }

    String mixId(String seed) => restarted
        .expand((session) => session.read(instantMixesProvider))
        .firstWhere((mix) => mix.seed.id == seed)
        .item
        .id;

    test(
      '- mixes come back with their songs without asking the server',
      () async {
        final session = await signedIn('user-1');
        await createMixes(session, ['s1', 's2']);

        final restartedSession = await signedIn('user-1');

        expect(seedsOf(restartedSession), ['s2', 's1']);
        final mix = restartedSession.read(instantMixesProvider).last;
        expect(_ids(mix.songs), ['s1', 's1-x']);
        expect(mix.item.name, "song s1's mix");
        verifyNever(() => client.getItemsByIds(any()));
        verifyNever(() => client.getItem(any(), kind: any(named: 'kind')));
      },
    );

    test('- a sound mix comes back under its query name', () async {
      final session = await signedIn('user-1');
      session.read(instantMixesProvider.notifier).createSoundMix('calm piano', [
        _song('a'),
        _song('b'),
      ]);
      await flush(session);

      final restartedSession = await signedIn('user-1');

      final mix = restartedSession.read(instantMixesProvider).single;
      expect(mix.item.name, 'Calm piano Mix');
      expect(mix.item.id, startsWith('instant-mix:sound:calm piano:'));
      expect(_ids(mix.songs), ['a', 'b']);
    });

    test('- opening a restored mix swaps in the server songs', () async {
      final session = await signedIn('user-1');
      await createMixes(session, ['s1']);
      serverHas([
        _song('s1').copyWith(
          userData: const PlaybackUserData(isFavorite: true),
        ),
      ]);

      final restartedSession = await signedIn('user-1');
      await restartedSession
          .read(instantMixesProvider.notifier)
          .refresh(mixId('s1'));

      final songs = restartedSession.read(instantMixesProvider).single.songs;
      expect(_ids(songs), ['s1']);
      expect(songs.single.userData.isFavorite, isTrue);

      await flush(restartedSession);
      final nextLaunch = await signedIn('user-1');
      final saved = nextLaunch.read(instantMixesProvider).single.songs;
      expect(saved.single.userData.isFavorite, isTrue);
    });

    test('- a mix is refetched at most once per session', () async {
      final session = await signedIn('user-1');
      await createMixes(session, ['s1']);
      await session.read(instantMixesProvider.notifier).refresh(mixId('s1'));
      verifyNever(() => client.getItemsByIds(any()));

      serverHas([_song('s1'), _song('s1-x')]);
      final restartedSession = await signedIn('user-1');
      final notifier = restartedSession.read(instantMixesProvider.notifier);
      await Future.wait([
        notifier.refresh(mixId('s1')),
        notifier.refresh(mixId('s1')),
      ]);
      await notifier.refresh(mixId('s1'));

      verify(() => client.getItemsByIds(any())).called(1);
    });

    test(
      '- a failed refetch keeps the saved songs and retries later',
      () async {
        final session = await signedIn('user-1');
        await createMixes(session, ['s1']);
        when(
          () => client.getItemsByIds(any()),
        ).thenAnswer((_) async => throw const SocketException('offline'));

        final restartedSession = await signedIn('user-1');
        final notifier = restartedSession.read(instantMixesProvider.notifier);
        await notifier.refresh(mixId('s1'));

        expect(
          _ids(restartedSession.read(instantMixesProvider).single.songs),
          ['s1', 's1-x'],
        );

        serverHas([_song('s1')]);
        await notifier.refresh(mixId('s1'));
        expect(
          _ids(restartedSession.read(instantMixesProvider).single.songs),
          ['s1'],
        );
      },
    );

    test('- only the most recent mixes are kept', () async {
      final session = await signedIn('user-1');
      await createMixes(session, [
        for (var i = 0; i <= recentInstantMixesLimit; i++) 's$i',
      ]);

      final restartedSession = await signedIn('user-1');

      expect(seedsOf(restartedSession), ['s5', 's4', 's3', 's2', 's1']);
      final stored = await restartedSession
          .read(instantMixDatabaseProvider)
          .getMixes();
      expect(stored, hasLength(recentInstantMixesLimit));
    });

    test('- replaying a mix moves it to the front after a restart', () async {
      final session = await signedIn('user-1');
      await createMixes(session, ['s1', 's2']);
      session.read(instantMixesProvider.notifier).touch(mixId('s1'));
      await flush(session);

      final restartedSession = await signedIn('user-1');

      expect(seedsOf(restartedSession), ['s1', 's2']);
    });

    test('- another user does not see them', () async {
      final session = await signedIn('user-1');
      await createMixes(session, ['s1']);

      final otherUser = await signedIn('user-2');

      expect(otherUser.read(instantMixesProvider), isEmpty);
    });
  });
}
