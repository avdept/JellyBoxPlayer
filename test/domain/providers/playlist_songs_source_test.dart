import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/generated_playlist_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/genre_playlists.dart';

import '../../provider_container.dart';

class _MockClient extends Mock implements MediaServerClient {}

class _MockDownloads extends Mock implements DownloadDatabase {}

class _MockGenerated extends Mock implements GeneratedPlaylistDatabase {}

class _MockMixes extends Mock implements InstantMixDatabase {}

class _NoLibrary extends CurrentLibraryNotifier {
  @override
  FutureOr<LibraryItem?> build() => null;
}

class _FixedDay extends CurrentDayNotifier {
  @override
  String build() => '2026-10-09';
}

LibraryItem _song(String id, {String? name}) =>
    LibraryItem(id: id, name: name ?? 'song $id', kind: ItemKind.song);

DownloadedSong _downloaded(String id) => DownloadedSong(
  item: _song(id),
  filePath: '/downloads/$id.flac',
  sizeInBytes: 1,
  downloadDate: DateTime(2026),
);

void main() {
  late _MockClient client;
  late _MockDownloads downloads;
  late _MockGenerated generated;
  late _MockMixes mixesDb;
  late ProviderContainer container;
  final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
    registerFallbackValue(<String>[]);
    registerFallbackValue(
      InstantMix(item: _song('m'), seed: _song('m'), songs: const []),
    );
  });

  setUp(() {
    client = _MockClient();
    downloads = _MockDownloads();
    generated = _MockGenerated();
    mixesDb = _MockMixes();
    when(mixesDb.getMixes).thenAnswer((_) async => const []);
    when(
      () => mixesDb.saveMix(any(), keep: any(named: 'keep')),
    ).thenAnswer((_) async {});
    when(() => downloads.getDownloadedPlaylistSongs(any())).thenAnswer(
      (_) async => const [],
    );
    when(
      () => generated.getSongs(
        playlistId: any(named: 'playlistId'),
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        dayKey: any(named: 'dayKey'),
      ),
    ).thenAnswer((_) async => const []);
    container = createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWith((_) => client),
        downloadDatabaseProvider.overrideWithValue(downloads),
        generatedPlaylistDatabaseProvider.overrideWithValue(generated),
        instantMixesProvider.overrideWith(
          (ref) => InstantMixesNotifier(ref, mixesDb, now: () => at),
        ),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 't'),
        ),
        currentLibraryProvider.overrideWith(_NoLibrary.new),
        currentDayProvider.overrideWith(_FixedDay.new),
        isOfflineProvider.overrideWithValue(false),
      ],
    );
  });

  PlaylistSongsSource source() => container.read(playlistSongsSourceProvider);

  void hydrates() {
    when(() => client.getItemsByIds(any())).thenAnswer((invocation) async {
      final ids = invocation.positionalArguments.first as List<String>;
      return [for (final id in ids) _song(id, name: 'fresh $id')];
    });
  }

  test('- a server playlist comes straight from the server', () async {
    when(() => client.getPlaylistSongs('p1')).thenAnswer(
      (_) async => LibraryPage(items: [_song('a'), _song('b')]),
    );

    final songs = await source().songsOf('p1');

    expect(songs.map((s) => s.id), ['a', 'b']);
    verifyNever(() => client.getItemsByIds(any()));
  });

  test('- liked songs walk every favourites page', () async {
    final first = [
      for (var i = 0; i < allFavouritesPageSize; i++) _song('a$i'),
    ];
    when(() => client.getAllSongs(any())).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as LibraryQuery;
      expect(query.filters, {ItemFilterFlag.favorite});
      return query.startIndex == 0
          ? LibraryPage(items: first, totalRecordCount: 201)
          : LibraryPage(items: [_song('z')], totalRecordCount: 201);
    });

    final songs = await source().songsOf(EphemeralPlaylistId.likedSongs('u'));

    expect(songs, hasLength(201));
    expect(songs.last.id, 'z');
  });

  test('- a recent instant mix is refreshed in its own order', () async {
    hydrates();
    final mix = container.read(instantMixesProvider.notifier).createSoundMix(
      'calm',
      [_song('b'), _song('a')],
    );

    final songs = await source().songsOf(mix!.item.id);

    expect(songs.map((s) => s.id), ['b', 'a']);
    expect(songs.first.name, 'fresh b');
  });

  test('- a mix that left the recents plays from its download', () async {
    hydrates();
    final id = EphemeralPlaylistId.instantMix('album-1', at);
    when(() => downloads.getDownloadedPlaylistSongs(id)).thenAnswer(
      (_) async => [_downloaded('x'), _downloaded('y')],
    );

    final songs = await source().songsOf(id);

    expect(songs.map((s) => s.id), ['x', 'y']);
  });

  test('- a failed refresh falls back to the snapshot', () async {
    when(() => client.getItemsByIds(any())).thenThrow(StateError('offline'));
    final mix = container.read(instantMixesProvider.notifier).createSoundMix(
      'calm',
      [_song('b')],
    );

    final songs = await source().songsOf(mix!.item.id);

    expect(songs.single.name, 'song b');
  });

  test('- a genre playlist prefers the stored snapshot', () async {
    hydrates();
    final id = genreMixId(['rock'], at: at);
    when(
      () => generated.getSongs(
        playlistId: id,
        userId: 'user-1',
        libraryId: any(named: 'libraryId'),
        dayKey: '2026-10-09',
      ),
    ).thenAnswer((_) async => [_song('r1'), _song('r2')]);

    final songs = await source().songsOf(id);

    expect(songs.map((s) => s.id), ['r1', 'r2']);
    verifyNever(
      () => client.getGeneratedPlaylistSongs(
        playlistId: any(named: 'playlistId'),
        libraryId: any(named: 'libraryId'),
      ),
    );
  });

  test('- an old genre playlist still plays from its download', () async {
    hydrates();
    final id = genreDiscoveryId(['jazz'], at: at);
    when(() => downloads.getDownloadedPlaylistSongs(id)).thenAnswer(
      (_) async => [_downloaded('j1')],
    );

    final songs = await source().songsOf(id);

    expect(songs.single.id, 'j1');
  });

  test('- hydration goes to the server in batches', () async {
    hydrates();
    final many = [for (var i = 0; i < 250; i++) _song('s$i')];

    final songs = await source().refreshed(many);

    expect(songs, hasLength(250));
    final calls = verify(() => client.getItemsByIds(captureAny())).captured;
    expect(calls.map((ids) => (ids as List).length), [100, 100, 50]);
  });

  test('- liked order keeps what you had and puts new likes first', () {
    final merged = mergeLikedOrder(
      ['c', 'a', 'gone'],
      [_song('a'), _song('new'), _song('c')],
    );

    expect(merged.map((s) => s.id), ['new', 'c', 'a']);
  });
}
