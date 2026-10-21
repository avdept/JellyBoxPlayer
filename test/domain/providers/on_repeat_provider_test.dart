import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/data/storages/play_history_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockPlayHistoryDatabase extends Mock implements PlayHistoryDatabase {}

LibraryItem _song(String id, {String? name}) =>
    LibraryItem(id: id, name: name ?? id, kind: ItemKind.song);

void main() {
  late MockMediaServerClient client;
  late MockPlayHistoryDatabase history;
  final now = DateTime.utc(2026, 10, 21);
  final snapshotProbe = FutureProvider.autoDispose(onRepeatSnapshotOf);
  final songsProbe = FutureProvider.autoDispose(onRepeatSongsOf);

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    client = MockMediaServerClient();
    history = MockPlayHistoryDatabase();
  });

  ProviderContainer containerWith({bool offline = false}) =>
      createProviderContainer(
        overrides: [
          mediaServerClientProvider.overrideWith((_) => client),
          playHistoryDatabaseProvider.overrideWithValue(history),
          isOfflineProvider.overrideWithValue(offline),
        ],
      );

  void tracked(List<String> songIds) {
    when(
      () => history.topPlayed(
        window: any(named: 'window'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => [
        for (final id in songIds) (songId: id, playCount: 1, lastPlayed: now),
      ],
    );
    when(() => history.playedSongsByIds(any())).thenAnswer(
      (invocation) async => {
        for (final id in invocation.positionalArguments.single as List<String>)
          id: _song(id, name: 'stored $id'),
      },
    );
  }

  test(
    '- the snapshot comes from the database alone, in ranked order',
    () async {
      tracked(['b', 'a']);
      final container = containerWith();

      final snapshot = await container.read(snapshotProbe.future);

      expect(snapshot.ids, ['b', 'a']);
      expect(
        [for (final song in snapshot.songs) song.name],
        ['stored b', 'stored a'],
      );
      verifyNever(() => client.getItemsByIds(any()));
      verify(
        () => history.topPlayed(
          window: onRepeatWindow,
          limit: onRepeatSongsLimit,
        ),
      ).called(1);
    },
  );

  test(
    '- songs not yet snapshotted appear once the server resolves them',
    () async {
      tracked(['known', 'legacy']);
      when(() => history.playedSongsByIds(any())).thenAnswer(
        (_) async => {'known': _song('known', name: 'stored known')},
      );
      when(() => client.getItemsByIds(any())).thenAnswer((invocation) async {
        final ids = invocation.positionalArguments.single as List<String>;
        return [for (final id in ids) _song(id, name: 'fresh $id')];
      });
      final container = containerWith();

      final snapshot = await container.read(snapshotProbe.future);
      final songs = await container.read(songsProbe.future);

      expect([for (final song in snapshot.songs) song.id], ['known']);
      expect(
        [for (final song in songs) song.name],
        ['fresh known', 'fresh legacy'],
      );
    },
  );

  test(
    '- online, the list is enriched from the server in ranked order',
    () async {
      tracked(['b', 'a']);
      when(() => client.getItemsByIds(any())).thenAnswer((invocation) async {
        final ids = invocation.positionalArguments.single as List<String>;
        return [for (final id in ids.reversed) _song(id, name: 'fresh $id')];
      });
      final container = containerWith();

      final songs = await container.read(songsProbe.future);

      expect([for (final song in songs) song.name], ['fresh b', 'fresh a']);
    },
  );

  test('- offline, the snapshot is served without any requests', () async {
    tracked(['a']);
    final container = containerWith(offline: true);

    final songs = await container.read(songsProbe.future);

    expect([for (final song in songs) song.name], ['stored a']);
    verifyNever(() => client.getItemsByIds(any()));
  });

  test('- a failing server leaves the snapshot in place', () async {
    tracked(['a']);
    when(() => client.getItemsByIds(any())).thenThrow(Exception('down'));
    final container = containerWith();

    final songs = await container.read(songsProbe.future);

    expect([for (final song in songs) song.name], ['stored a']);
  });

  test('- the home card hides below the minimum and shows at it', () async {
    final counts = [onRepeatMinimumSongs - 1, onRepeatMinimumSongs];
    when(
      () => history.trackedSongCount(window: any(named: 'window')),
    ).thenAnswer((_) async => counts.removeAt(0));
    final container = createProviderContainer(
      overrides: [
        playHistoryDatabaseProvider.overrideWithValue(history),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 't'),
        ),
      ],
    );

    expect(await container.read(onRepeatCardProvider.future), isNull);

    container.read(playHistoryChangedProvider.notifier).state++;
    final card = await container.read(onRepeatCardProvider.future);

    expect(card?.name, onRepeatName);
  });

  test('- empty history asks nobody for anything', () async {
    tracked(const []);
    final container = containerWith();

    final songs = await container.read(songsProbe.future);

    expect(songs, isEmpty);
    verifyNever(() => client.getItemsByIds(any()));
  });
}
