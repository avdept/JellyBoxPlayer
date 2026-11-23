import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/data/storages/pins_database.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/sync/sync_hydrator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    registerFallbackValue(ItemKind.album);
    registerFallbackValue(
      const LibraryItem(id: '', name: '', kind: ItemKind.song),
    );
    final dir = await Directory.systemTemp.createTemp('sync_hydrator');
    await databaseFactory.setDatabasesPath(dir.path);
  });

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  late DownloadDatabase owner;
  late MockMediaServerClient client;
  late ResumePointDatabase resume;
  late PinsDatabase pins;
  late GeneratedPlaylistDatabase generated;
  late InstantMixDatabase mixes;
  late SyncHydrator hydrator;

  setUp(() async {
    await deleteDb();
    owner = DownloadDatabase(serverId: 'srv');
    client = MockMediaServerClient();
    resume = ResumePointDatabase(owner, userId: 'u1');
    pins = PinsDatabase(owner, userId: 'u1');
    generated = GeneratedPlaylistDatabase(owner);
    mixes = InstantMixDatabase(owner, userId: 'u1');
    hydrator = SyncHydrator(
      client: client,
      resumePoints: resume,
      pins: pins,
      generated: generated,
      instantMixes: mixes,
      userId: 'u1',
    );
  });
  tearDown(deleteDb);

  Map<String, Object?> stub(String id, String kind, [String name = '']) => {
    'id': id,
    'name': name,
    'kind': kind,
  };

  LibraryItem song(String id) =>
      LibraryItem(id: id, name: 'Song $id', kind: ItemKind.song);

  Future<void> insertResume(String source, Map<String, Object?> item) async {
    final db = await owner.database;
    await db.insert('ResumePoints', {
      'ServerId': 'srv',
      'UserId': 'u1',
      'SourceId': source,
      'LibraryId': '',
      'Item': jsonEncode(item),
      'SongId': 'song-1',
      'SongName': '',
      'SongIndex': 2,
      'SongCount': 9,
      'PositionMs': 60000,
      'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  group('resume points', () {
    test('- a stub stays hidden until the set and song are fetched', () async {
      await insertResume('album-1', stub('album-1', 'album'));
      when(() => client.getItem('album-1', kind: ItemKind.album)).thenAnswer(
        (_) async => const LibraryItem(
          id: 'album-1',
          name: 'Netherworlds',
          kind: ItemKind.album,
        ),
      );
      when(
        () => client.getItemsByIds(['song-1']),
      ).thenAnswer((_) async => [song('song-1')]);

      expect(await resume.recent(), isEmpty);
      expect(await hydrator.hydrateResumePoints(), isTrue);

      final point = (await resume.recent()).single;
      expect(point.item.name, 'Netherworlds');
      expect(point.songName, 'Song song-1');
      expect(point.position, const Duration(minutes: 1));
    });

    test('- a set made by the app only needs its song name', () async {
      const id = 'jellybox:liked-songs:u1';
      await insertResume(id, stub(id, 'playlist', 'Liked songs'));
      when(
        () => client.getItemsByIds(['song-1']),
      ).thenAnswer((_) async => [song('song-1')]);

      await hydrator.hydrateResumePoints();

      expect((await resume.recent()).single.songName, 'Song song-1');
      verifyNever(() => client.getItem(any(), kind: any(named: 'kind')));
    });

    test('- a failed lookup leaves the stub hidden for the next try', () async {
      await insertResume('album-1', stub('album-1', 'album'));
      when(
        () => client.getItem('album-1', kind: ItemKind.album),
      ).thenThrow(Exception('down'));
      when(
        () => client.getItemsByIds(any()),
      ).thenThrow(Exception('down'));

      expect(await hydrator.hydrateResumePoints(), isFalse);
      expect(await resume.recent(), isEmpty);
      expect(await resume.stubs(), hasLength(1));
    });
  });

  test('- a pin stub gets its name and cover from the server', () async {
    final db = await owner.database;
    await db.insert('Pins', {
      'ServerId': 'srv',
      'UserId': 'u1',
      'ItemId': 'artist-1',
      'ItemType': 'artist',
      'Name': '',
      'ImageUrl': null,
      'PinnedAt': DateTime.now().millisecondsSinceEpoch,
    });
    const artist = LibraryItem(
      id: 'artist-1',
      name: 'Insomnium',
      kind: ItemKind.artist,
      images: ImageRefs(primary: 'tag'),
    );
    when(
      () => client.getItem('artist-1', kind: ItemKind.artist),
    ).thenAnswer((_) async => artist);
    when(
      () => client.imageUri(artist),
    ).thenReturn(Uri.parse('http://server/artist-1.jpg'));

    expect(await pins.getPins(), isEmpty);
    await hydrator.hydratePins();

    final pin = (await pins.getPins()).single;
    expect(pin.name, 'Insomnium');
    expect(pin.imageUrl, Uri.parse('http://server/artist-1.jpg'));
  });

  test('- generated playlist songs and covers are filled by id', () async {
    final db = await owner.database;
    await db.insert('GeneratedPlaylists', {
      'Id': 'mix-a',
      'UserId': 'u1',
      'LibraryId': '',
      'DayKey': '2026-11-23',
      'Position': 0,
      'GeneratedAt': 1,
      'RemoteId': 'link',
      'Data': jsonEncode(stub('mix-a', 'playlist', 'Discover Metal')),
      'CoverSongs': jsonEncode([stub('s1', 'song')]),
    });
    for (final (index, id) in ['s1', 's2'].indexed) {
      await db.insert('GeneratedPlaylistItems', {
        'PlaylistId': 'mix-a',
        'UserId': 'u1',
        'LibraryId': '',
        'DayKey': '2026-11-23',
        'Position': index,
        'SongId': id,
        'Data': jsonEncode(stub(id, 'song')),
      });
    }
    when(() => client.getItemsByIds(any())).thenAnswer(
      (invocation) async => [
        for (final id in invocation.positionalArguments.first as List<String>)
          song(id),
      ],
    );

    await hydrator.hydrateGeneratedPlaylists();

    final songs = await generated.getSongs(
      playlistId: 'mix-a',
      userId: 'u1',
      dayKey: '2026-11-23',
    );
    expect(songs.map((s) => s.name), ['Song s1', 'Song s2']);
    final playlist = (await generated.getPlaylists(
      userId: 'u1',
      dayKey: '2026-11-23',
    )).single;
    expect(playlist.coverSongs.single.name, 'Song s1');
    expect(await generated.stubSongIds(userId: 'u1'), isEmpty);
  });

  group('instant mixes', () {
    Future<void> insertMix(
      String id,
      Map<String, Object?> seed,
      List<String> songs,
    ) async {
      final db = await owner.database;
      await db.insert('InstantMixes', {
        'Id': id,
        'ServerId': 'srv',
        'UserId': 'u1',
        'LibraryId': '',
        'Seed': jsonEncode(seed),
        'Songs': jsonEncode([for (final id in songs) stub(id, 'song')]),
        'LastUsedAt': 1000,
      });
    }

    test('- a synced mix stays hidden until seed and songs load', () async {
      await insertMix('instant-mix:album-1:1', stub('album-1', 'album'), [
        's1',
        's2',
      ]);
      when(() => client.getItem('album-1', kind: ItemKind.album)).thenAnswer(
        (_) async => const LibraryItem(
          id: 'album-1',
          name: 'Netherworlds',
          kind: ItemKind.album,
        ),
      );
      when(() => client.getItemsByIds(any())).thenAnswer(
        (_) async => [song('s1'), song('s2')],
      );

      expect(await mixes.getMixes(), isEmpty);
      expect(await hydrator.hydrateInstantMixes(), isTrue);

      final mix = (await mixes.getMixes()).single;
      expect(mix.item.name, "Netherworlds's mix");
      expect(mix.songs.map((s) => s.name), ['Song s1', 'Song s2']);
    });

    test('- songs gone from the server are dropped from the mix', () async {
      await insertMix(
        'instant-mix:sound:rain:1',
        stub('sound:rain', 'playlist', 'Rain'),
        ['s1', 'gone'],
      );
      when(
        () => client.getItemsByIds(any()),
      ).thenAnswer((_) async => [song('s1')]);

      await hydrator.hydrateInstantMixes();

      final mix = (await mixes.getMixes()).single;
      expect(mix.item.name, 'Rain Mix');
      expect(mix.songs.map((s) => s.id), ['s1']);
      verifyNever(() => client.getItem(any(), kind: any(named: 'kind')));
    });

    test('- a failed song lookup keeps the mix for the next try', () async {
      await insertMix(
        'instant-mix:sound:rain:1',
        stub('sound:rain', 'playlist', 'Rain'),
        ['s1'],
      );
      when(() => client.getItemsByIds(any())).thenThrow(Exception('down'));

      expect(await hydrator.hydrateInstantMixes(), isFalse);
      expect(await mixes.stubs(), hasLength(1));
    });
  });
}
