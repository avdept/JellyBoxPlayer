import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/audio_container_mime.dart';
import 'package:jplayer/src/core/audio/stream_preference.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/backend/subsonic/mappers/subsonic_item_mapper.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_client.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

import 'subsonic_test_support.dart';

void main() {
  late SubsonicFakeServer server;
  late SubsonicClient client;
  var now = DateTime.utc(2026, 9, 18, 12);

  setUpAll(registerSubsonicFallbacks);

  setUp(() {
    server = SubsonicFakeServer();
    now = DateTime.utc(2026, 9, 18, 12);
    client = SubsonicClient(
      dio: server.dio,
      baseUrl: 'http://music.local:4533',
      userId: 'joe',
      token: 'tok:salt',
      deviceId: 'device-1',
      now: () => now,
    );
  });

  void extensions(List<String> names) =>
      server.ok('getOpenSubsonicExtensions', {
        'openSubsonicExtensions': [
          for (final name in names)
            {
              'name': name,
              'versions': [1],
            },
        ],
      });

  LibraryItem song({String suffix = 'mp3', int bitDepth = 0}) =>
      SubsonicChildDTO.fromJson(
        childJson('song-1', suffix: suffix, bitDepth: bitDepth),
      ).toLibraryItem();

  group('resolveStreamSource', () {
    StreamTargetProfile capped(int kbps) => StreamTargetProfile.localPlayer(
      isAndroid: false,
    ).withPreference(StreamPreference(maxBitRate: kbps));

    test('- re-encodes to the cap when the source is over it', () async {
      final source = await client.resolveStreamSource(
        song(),
        playSessionId: 'session-1',
        target: capped(128),
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.outputContainer, 'mp3');
      expect(source.uri.queryParameters['format'], 'mp3');
      expect(source.uri.queryParameters['maxBitRate'], '128');
      expect(source.delivered?.codec, 'mp3');
      expect(source.delivered?.container, 'mp3');
      expect(source.delivered?.bitRate, 128000);
    });

    test('- turns a lossless source lossy under a cap', () async {
      final source = await client.resolveStreamSource(
        song(suffix: 'flac', bitDepth: 16),
        playSessionId: 'session-1',
        target: capped(128),
      );

      expect(source.uri.queryParameters['format'], 'mp3');
      expect(source.uri.queryParameters['maxBitRate'], '128');
    });

    test('- serves the raw file when the source fits the cap', () async {
      final source = await client.resolveStreamSource(
        song(),
        playSessionId: 'session-1',
        target: capped(320),
      );

      expect(source.requiresTranscode, isFalse);
      expect(source.uri.queryParameters['format'], 'raw');
      expect(source.delivered?.bitRate, 320000);
    });

    test('- asks for the codec of the preference when one is set', () async {
      final source = await client.resolveStreamSource(
        song(),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false)
            .withPreference(
              const StreamPreference(
                maxBitRate: 128,
                codec: TranscodeTarget.aac,
              ),
            ),
      );

      expect(source.uri.queryParameters['format'], 'aac');
    });

    test(
      '- direct plays without a format and keeps the source container',
      () async {
        final source = await client.resolveStreamSource(
          song(suffix: 'flac', bitDepth: 16),
          playSessionId: 'session-1',
          target: StreamTargetProfile.localPlayer(isAndroid: false),
        );

        expect(source.isHls, isFalse);
        expect(source.requiresTranscode, isFalse);
        expect(source.outputContainer, 'flac');
        expect(source.mimeType, mimeTypeForContainer('flac'));
        expect(source.uri.path, '/rest/stream');
        expect(source.uri.queryParameters['id'], 'song-1');
        expect(source.uri.queryParameters['u'], 'joe');
        expect(source.uri.queryParameters['t'], 'tok');
        expect(source.uri.queryParameters['s'], 'salt');
        expect(source.uri.queryParameters['format'], 'raw');
        expect(source.uri.queryParameters.containsKey('maxBitRate'), isFalse);
      },
    );

    test('- asks for flac when a lossless source needs transcoding', () async {
      final source = await client.resolveStreamSource(
        song(suffix: 'm4a', bitDepth: 16),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.outputContainer, 'flac');
      expect(source.mimeType, mimeTypeForContainer('flac'));
      expect(source.uri.queryParameters['format'], 'flac');
      expect(source.uri.queryParameters.containsKey('maxBitRate'), isFalse);
    });

    test('- asks for mp3 when the target has no lossless option', () async {
      final source = await client.resolveStreamSource(
        song(suffix: 'flac', bitDepth: 16),
        playSessionId: 'session-1',
        target: StreamTargetProfile.renderer(sinkMimeTypes: {'audio/mpeg'}),
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.outputContainer, 'mp3');
      expect(source.uri.queryParameters['format'], 'mp3');
      expect(source.uri.queryParameters['maxBitRate'], '320');
    });

    test('- lets ALAC direct play where the platform decodes it', () async {
      final source = await client.resolveStreamSource(
        song(suffix: 'm4a', bitDepth: 16),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(source.requiresTranscode, isFalse);
      expect(source.outputContainer, 'm4a');
    });
  });

  group('images', () {
    test('- resolve cover art ids with a size', () {
      final item = LibraryItem(
        id: 's',
        name: 's',
        kind: ItemKind.song,
        images: const ImageRefs(primary: 'mf-s', albumPrimary: 'al-a'),
      );

      final primary = client.imageUri(item, size: 64)!;
      expect(primary.path, '/rest/getCoverArt');
      expect(primary.queryParameters['id'], 'mf-s');
      expect(primary.queryParameters['size'], '64');
      expect(primary.queryParameters['u'], 'joe');

      final album = client.imageUri(item, kind: ImageKind.album)!;
      expect(album.queryParameters['id'], 'al-a');
      expect(album.queryParameters['size'], '420');

      expect(client.imageUri(item, kind: ImageKind.backdrop), isNull);
      expect(
        client.imageUri(
          const LibraryItem(id: 'x', name: 'x', kind: ItemKind.album),
        ),
        isNull,
      );
    });

    test('- rewrite the size on an existing URL', () {
      final item = LibraryItem(
        id: 's',
        name: 's',
        kind: ItemKind.album,
        images: const ImageRefs(primary: 'al-a'),
      );
      final resized = client.resizedImageUri(client.imageUri(item)!, 128);
      expect(resized.queryParameters['size'], '128');
      expect(resized.queryParameters['id'], 'al-a');
    });
  });

  group('validateSession', () {
    test('- is valid on a successful ping', () async {
      server.ok('ping', {});
      expect(await client.validateSession(), SessionStatus.valid);
    });

    test('- is invalid on a wrong-password envelope', () async {
      server.on(
        'ping',
        (_) => subsonicFailed(40, 'Wrong username or password'),
      );
      expect(await client.validateSession(), SessionStatus.invalid);
    });

    test('- is invalid when the stored token cannot be decoded', () async {
      server.ok('ping', {});
      final broken = SubsonicClient(
        dio: server.dio,
        baseUrl: 'http://music.local:4533',
        userId: 'joe',
        token: 'legacy-mediabrowser-token',
        deviceId: 'device-1',
      );

      expect(await broken.validateSession(), SessionStatus.invalid);
      expect(server.requests, isEmpty);
    });

    test('- is unreachable on a transport error', () async {
      when(() => server.adapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/'),
          reason: 'refused',
        ),
      );
      expect(await client.validateSession(), SessionStatus.unreachable);
    });
  });

  group('albums', () {
    test('- browse through getAlbumList2 with an open-ended total', () async {
      server.ok('getAlbumList2', {
        'albumList2': {
          'album': [albumJson('a1', name: 'One'), albumJson('a2', name: 'Two')],
        },
      });

      final page = await client.getAlbums(
        const LibraryQuery(
          libraryId: '1',
          sort: ItemSort.dateCreated,
          startIndex: 100,
          limit: 2,
        ),
      );

      expect(page.items.map((a) => a.id), ['a1', 'a2']);
      expect(page.totalRecordCount, 102);
      final uri = server.calls('getAlbumList2').single;
      expect(uri.queryParameters['type'], 'newest');
      expect(uri.queryParameters['size'], '2');
      expect(uri.queryParameters['offset'], '100');
      expect(uri.queryParameters['musicFolderId'], '1');
    });

    test('- favourites come from getStarred2 with a real total', () async {
      server.ok('getStarred2', {
        'starred2': {
          'album': [
            albumJson('b', name: 'Beta'),
            albumJson('a', name: 'Alpha'),
            albumJson('c', name: 'Gamma'),
          ],
        },
      });

      final page = await client.getAlbums(
        const LibraryQuery(filters: {ItemFilterFlag.favorite}, limit: 2),
      );

      expect(page.items.map((a) => a.name), ['Alpha', 'Beta']);
      expect(page.totalRecordCount, 3);
    });

    test('- by id fan out to getAlbum and skip missing ones', () async {
      server.on('getAlbum', (uri) {
        final id = uri.queryParameters['id']!;
        if (id == 'gone') return subsonicFailed(70, 'not found');
        return subsonicOk({'album': albumJson(id, name: 'Album $id')});
      });

      final page = await client.getAlbums(
        const LibraryQuery(ids: ['a1', 'gone', 'a2'], limit: 3),
      );

      expect(page.items.map((a) => a.id), ['a1', 'a2']);
      expect(page.totalRecordCount, 2);
    });

    test('- by genre use the genre name', () async {
      server.ok('getAlbumList2', {
        'albumList2': {
          'album': [albumJson('a1')],
        },
      });

      await client.getAlbums(
        const LibraryQuery(genreIds: ['Heavy Metal'], limit: 30),
      );

      final uri = server.calls('getAlbumList2').single;
      expect(uri.queryParameters['type'], 'byGenre');
      expect(uri.queryParameters['genre'], 'Heavy Metal');
    });

    test('- appears-on is not available', () async {
      final page = await client.getAlbums(
        const LibraryQuery(appearsOnArtistId: 'ar1'),
      );
      expect(page.items, isEmpty);
      expect(server.requests, isEmpty);
    });
  });

  group('artists', () {
    test('- reuse the index within the cache window and page it', () async {
      server.ok('getArtists', {
        'artists': {
          'index': [
            {
              'name': 'A',
              'artist': [
                {'id': 'ar2', 'name': 'Bob'},
                {'id': 'ar1', 'name': 'Alice'},
              ],
            },
            {
              'name': 'Z',
              'artist': [
                {'id': 'ar3', 'name': 'Zed'},
              ],
            },
          ],
        },
      });

      final first = await client.getArtists(const LibraryQuery(limit: 2));
      final second = await client.getArtists(
        const LibraryQuery(startIndex: 2, limit: 2),
      );

      expect(first.items.map((a) => a.name), ['Alice', 'Bob']);
      expect(first.totalRecordCount, 3);
      expect(second.items.map((a) => a.name), ['Zed']);
      expect(server.calls('getArtists'), hasLength(1));

      now = now.add(SubsonicClient.artistIndexTtl);
      await client.getArtists(const LibraryQuery());
      expect(server.calls('getArtists'), hasLength(2));
    });
  });

  group('songs', () {
    test('- all songs page through search3 in natural order', () async {
      server.ok('search3', {
        'searchResult3': {
          'song': [childJson('s1'), childJson('s2')],
        },
      });

      final page = await client.getAllSongs(
        const LibraryQuery(libraryId: '1', startIndex: 200, limit: 2),
      );

      expect(page.items.map((s) => s.id), ['s1', 's2']);
      expect(page.totalRecordCount, 202);
      final uri = server.calls('search3').single;
      expect(uri.queryParameters['query'], '');
      expect(uri.queryParameters['songCount'], '2');
      expect(uri.queryParameters['songOffset'], '200');
      expect(uri.queryParameters['albumCount'], '0');
      expect(uri.queryParameters['artistCount'], '0');
      expect(uri.queryParameters['musicFolderId'], '1');
    });

    test('- random songs use getRandomSongs', () async {
      server.ok('getRandomSongs', {
        'randomSongs': {
          'song': [childJson('s1')],
        },
      });

      await client.getAllSongs(
        const LibraryQuery(sort: ItemSort.random, limit: 7),
      );

      expect(
        server.calls('getRandomSongs').single.queryParameters['size'],
        '7',
      );
    });

    test(
      '- played songs by play count come from the frequent albums',
      () async {
        server.ok('getAlbumList2', {
          'albumList2': {
            'album': [
              albumJson('a1', playCount: 9),
              albumJson('a2', playCount: 4),
            ],
          },
        });
        server.on('getAlbum', (uri) {
          final id = uri.queryParameters['id']!;
          return subsonicOk({
            'album': albumJson(
              id,
              songs: [
                childJson(
                  '$id-hot',
                  albumId: id,
                  playCount: id == 'a1' ? 7 : 3,
                ),
                childJson('$id-cold', albumId: id),
              ],
            ),
          });
        });

        final page = await client.getAllSongs(
          const LibraryQuery(
            libraryId: '1',
            sort: ItemSort.playCount,
            direction: SortDirection.descending,
            filters: {ItemFilterFlag.played},
            limit: 200,
          ),
        );

        expect(page.items.map((s) => s.id), ['a1-hot', 'a2-hot']);
        expect(page.totalRecordCount, 2);
        final list = server.calls('getAlbumList2').single;
        expect(list.queryParameters['type'], 'frequent');
        expect(list.queryParameters['musicFolderId'], '1');
        expect(server.calls('getAlbum'), hasLength(2));
      },
    );

    test('- a random genre set samples with getRandomSongs', () async {
      server.on('getRandomSongs', (uri) {
        final genre = uri.queryParameters['genre']!;
        return subsonicOk({
          'randomSongs': {
            'song': [
              for (var i = 0; i < 6; i++)
                childJson(
                  '$genre-$i',
                  genres: [genre],
                  playCount: i.isEven ? 1 : 0,
                ),
            ],
          },
        });
      });

      final page = await client.getSongsOfSet(
        const LibraryQuery(
          libraryId: '1',
          genreIds: ['Rock', 'rock'],
          sort: ItemSort.random,
          limit: 40,
        ),
      );

      expect(page.items, hasLength(12));
      final calls = server.calls('getRandomSongs');
      expect(calls.map((c) => c.queryParameters['genre']), ['Rock', 'rock']);
      expect(calls.first.queryParameters['size'], '40');
      expect(calls.first.queryParameters['musicFolderId'], '1');
      expect(server.calls('getSongsByGenre'), isEmpty);
    });

    test(
      '- a filtered genre set over-fetches and trims to the limit',
      () async {
        server.on('getRandomSongs', (uri) {
          return subsonicOk({
            'randomSongs': {
              'song': [
                for (var i = 0; i < 30; i++)
                  childJson('s$i', playCount: i < 10 ? 2 : 0),
              ],
            },
          });
        });

        final page = await client.getSongsOfSet(
          const LibraryQuery(
            genreIds: ['Rock'],
            filters: {ItemFilterFlag.unplayed},
            sort: ItemSort.random,
            limit: 5,
          ),
        );

        expect(page.items, hasLength(5));
        expect(page.items.every((s) => s.userData.playCount == 0), isTrue);
        expect(
          server.calls('getRandomSongs').single.queryParameters['size'],
          '25',
        );
      },
    );

    test('- an album plays in disc and track order', () async {
      server.ok('getAlbum', {
        'album': albumJson(
          'a1',
          songs: [
            childJson('s3', disc: 2, track: 1),
            childJson('s2', disc: 1, track: 2),
            childJson('s1', disc: 1, track: 1),
          ],
        ),
      });

      final page = await client.getSongs('a1');

      expect(page.items.map((s) => s.id), ['s1', 's2', 's3']);
      expect(page.totalRecordCount, 3);
    });

    test('- an artist set walks albums oldest first', () async {
      server.ok('getArtist', {
        'artist': {
          'id': 'ar1',
          'name': 'Artist',
          'album': [
            albumJson('new', year: 2020),
            albumJson('old', year: 1999),
          ],
        },
      });
      server.on('getAlbum', (uri) {
        final id = uri.queryParameters['id']!;
        return subsonicOk({
          'album': albumJson(id, songs: [childJson('$id-1', track: 1)]),
        });
      });

      final page = await client.getSongsOfSet(
        const LibraryQuery(artistIds: ['ar1'], sort: ItemSort.albumOrder),
      );

      expect(page.items.map((s) => s.id), ['old-1', 'new-1']);
    });
  });

  group('playlists', () {
    test(
      '- entries carry a verifiable entry id and playlist position',
      () async {
        server.ok('getPlaylist', {
          'playlist': {
            'id': 'pl1',
            'name': 'Mix',
            'entry': [childJson('s1', track: 9), childJson('s2', track: 2)],
          },
        });

        final page = await client.getPlaylistSongs('pl1');

        expect(page.items.map((s) => s.playlistItemId), ['0:s1', '1:s2']);
        expect(page.items.map((s) => s.indexNumber), [1, 2]);
      },
    );

    test('- removal sends the verified index', () async {
      server.ok('getPlaylist', {
        'playlist': {
          'id': 'pl1',
          'name': 'Mix',
          'entry': [childJson('s1'), childJson('s2'), childJson('s3')],
        },
      });
      server.ok('updatePlaylist', {});

      await client.removePlaylistItem(playlistId: 'pl1', entryId: '1:s2');

      final uri = server.calls('updatePlaylist').single;
      expect(uri.queryParameters['songIndexToRemove'], '1');
    });

    test('- removal re-locates the song when the list shifted', () async {
      server.ok('getPlaylist', {
        'playlist': {
          'id': 'pl1',
          'name': 'Mix',
          'entry': [childJson('s0'), childJson('s1'), childJson('s2')],
        },
      });
      server.ok('updatePlaylist', {});

      await client.removePlaylistItem(playlistId: 'pl1', entryId: '1:s2');

      expect(
        server
            .calls('updatePlaylist')
            .single
            .queryParameters['songIndexToRemove'],
        '2',
      );
    });

    test('- removal refuses to guess between duplicates', () async {
      server.ok('getPlaylist', {
        'playlist': {
          'id': 'pl1',
          'name': 'Mix',
          'entry': [childJson('s2'), childJson('s1'), childJson('s2')],
        },
      });

      await expectLater(
        client.removePlaylistItem(playlistId: 'pl1', entryId: '1:s2'),
        throwsA(
          isA<MediaServerException>().having(
            (e) => e.isNotFound,
            'notFound',
            true,
          ),
        ),
      );
      expect(server.calls('updatePlaylist'), isEmpty);
    });

    test('- creation marks the playlist public afterwards', () async {
      server.ok('createPlaylist', {
        'playlist': {'id': 'pl9', 'name': 'Shared'},
      });
      server.ok('updatePlaylist', {});

      await client.createPlaylist(
        const PlaylistData(name: 'Shared', userId: 'joe', isPublic: true),
      );

      expect(
        server.calls('createPlaylist').single.queryParameters['name'],
        'Shared',
      );
      final update = server.calls('updatePlaylist').single;
      expect(update.queryParameters['playlistId'], 'pl9');
      expect(update.queryParameters['public'], 'true');
    });

    test('- search filters the playlist list by name', () async {
      server.ok('getPlaylists', {
        'playlists': {
          'playlist': [
            {'id': 'p1', 'name': 'Road Trip'},
            {'id': 'p2', 'name': 'Sleep'},
          ],
        },
      });

      final page = await client.searchPlaylists(
        const SearchQuery(term: 'trip'),
      );

      expect(page.items.map((p) => p.id), ['p1']);
    });
  });

  test(
    'playlist creation finds the playlist by name when no body comes back',
    () async {
      server.ok('createPlaylist', {});
      server.ok('getPlaylists', {
        'playlists': {
          'playlist': [
            {'id': 'old', 'name': 'Shared', 'created': '2026-01-01T00:00:00Z'},
            {'id': 'new', 'name': 'Shared', 'created': '2026-09-19T00:00:00Z'},
            {'id': 'other', 'name': 'Other', 'created': '2026-09-19T00:00:00Z'},
          ],
        },
      });
      server.ok('updatePlaylist', {});

      await client.createPlaylist(
        const PlaylistData(name: 'Shared', userId: 'joe', isPublic: true),
      );

      final update = server.calls('updatePlaylist').single;
      expect(update.queryParameters['playlistId'], 'new');
      expect(update.queryParameters['public'], 'true');
    },
  );

  group('artist details', () {
    setUp(() {
      server.ok('getArtist', {
        'artist': {'id': 'ar1', 'name': 'Insomnium', 'coverArt': 'ar-ar1'},
      });
    });

    test('- merge the biography from getArtistInfo2', () async {
      server.ok('getArtistInfo2', {
        'artistInfo2': {
          'biography':
              'Formed in <b>Joensuu</b>. <a href="https://last.fm/x">Read more on Last.fm</a> &amp; enjoy',
          'similarArtist': <Object?>[],
        },
      });

      final artist = await client.getItem('ar1', kind: ItemKind.artist);

      expect(
        artist.overview,
        'Formed in Joensuu. Read more on Last.fm & enjoy',
      );
      expect(
        server.calls('getArtistInfo2').single.queryParameters['id'],
        'ar1',
      );
    });

    test('- keep the artist when the info call fails or is empty', () async {
      server.on('getArtistInfo2', (_) => subsonicFailed(0, 'no agent'));
      expect(
        (await client.getItem('ar1', kind: ItemKind.artist)).overview,
        isNull,
      );

      server.ok('getArtistInfo2', {'artistInfo2': <String, Object?>{}});
      expect(
        (await client.getItem('ar1', kind: ItemKind.artist)).overview,
        isNull,
      );
    });
  });

  test('artist images become the artist page backdrop', () async {
    server.ok('getArtist', {
      'artist': {
        'id': 'ar1',
        'name': 'Insomnium',
        'coverArt': 'ar-ar1_abc',
        'artistImageUrl': 'http://music.local:4533/share/img/token?size=600',
      },
    });

    final artist = await client.getItem('ar1', kind: ItemKind.artist);

    expect(artist.images.hasBackdrop, isTrue);
    expect(
      client.imageUri(artist, kind: ImageKind.backdrop),
      Uri.parse('http://music.local:4533/share/img/token?size=600'),
    );
    expect(
      client.imageUri(artist)!.queryParameters['id'],
      'ar-ar1_abc',
    );
  });

  test(
    'a missing extension endpoint is not re-asked on every report',
    () async {
      server.on(
        'getOpenSubsonicExtensions',
        (_) => subsonicFailed(70, 'not found'),
      );
      server.ok('scrobble', {});
      const report = PlaybackReport(itemId: 'song-1', playSessionId: 's');

      await client.reportPlaybackStarted(report);
      await client.reportPlaybackProgress(report);
      await client.reportPlaybackProgress(report);
      expect(server.calls('getOpenSubsonicExtensions'), hasLength(1));
      expect(server.calls('scrobble'), hasLength(1));

      now = now.add(SubsonicClient.extensionRetryInterval);
      await client.reportPlaybackProgress(report);
      expect(server.calls('getOpenSubsonicExtensions'), hasLength(2));
    },
  );

  group('capabilities', () {
    test('- turn lyrics off when the server lacks the extension', () async {
      extensions(['formPost']);

      final resolved = await client.resolveCapabilities();

      expect(resolved.lyrics, isFalse);
      expect(resolved.similarAlbums, isFalse);
      expect(client.capabilities.lyrics, isFalse);

      server.ok('getSong', {'song': childJson('s1')});
      final item = await client.getItem('s1', kind: ItemKind.song);
      expect(item.hasLyrics, isFalse);
    });

    test(
      '- keep the defaults when the extension list cannot be read',
      () async {
        when(() => server.adapter.fetch(any(), any(), any())).thenThrow(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/'),
            reason: 'refused',
          ),
        );

        final resolved = await client.resolveCapabilities();

        expect(resolved.lyrics, isTrue);
      },
    );
  });

  group('playback reporting', () {
    const report = PlaybackReport(
      itemId: 'song-1',
      playSessionId: 'session',
      position: Duration(seconds: 130),
      duration: Duration(seconds: 200),
    );

    test('- uses reportPlayback when the server advertises it', () async {
      extensions(['playbackReport']);
      server.ok('reportPlayback', {});

      await client.reportPlaybackStarted(report);
      await client.reportPlaybackProgress(report);
      await client.reportPlaybackStopped(report);

      final states = [
        for (final uri in server.calls('reportPlayback'))
          uri.queryParameters['state'],
      ];
      expect(states, ['starting', 'playing', 'stopped']);
      expect(
        server.calls('reportPlayback').last.queryParameters['positionMs'],
        '130000',
      );
      expect(server.calls('scrobble'), isEmpty);
    });

    test('- falls back to scrobble and only submits real listens', () async {
      extensions([]);
      server.ok('scrobble', {});

      await client.reportPlaybackStarted(report);
      await client.reportPlaybackProgress(report);
      await client.reportPlaybackStopped(
        const PlaybackReport(
          itemId: 'song-1',
          playSessionId: 'session',
          position: Duration(seconds: 30),
          duration: Duration(seconds: 200),
        ),
      );

      var calls = server.calls('scrobble');
      expect(calls, hasLength(1));
      expect(calls.single.queryParameters['submission'], 'false');

      await client.reportPlaybackStarted(report);
      await client.reportPlaybackStopped(report);

      calls = server.calls('scrobble');
      expect(calls, hasLength(3));
      expect(calls.last.queryParameters['submission'], 'true');
      expect(
        calls.last.queryParameters['time'],
        '${now.millisecondsSinceEpoch}',
      );
    });

    test('- counts a play at half the track or four minutes', () {
      bool counts(int positionSeconds, int? durationSeconds) =>
          SubsonicClient.countsAsPlay(
            position: Duration(seconds: positionSeconds),
            duration: durationSeconds == null
                ? null
                : Duration(seconds: durationSeconds),
          );

      expect(counts(100, 180), isTrue);
      expect(counts(89, 180), isFalse);
      expect(counts(240, 1200), isTrue);
      expect(counts(239, 1200), isFalse);
      expect(counts(240, null), isTrue);
      expect(counts(100, null), isFalse);
      expect(
        SubsonicClient.countsAsPlay(position: null, duration: null),
        isFalse,
      );
    });
  });

  test('libraries come from the music folders', () async {
    server.ok('getMusicFolders', {
      'musicFolders': {
        'musicFolder': [
          {'id': 1, 'name': 'Music Library'},
        ],
      },
    });

    final page = await client.getLibraries();

    expect(page.items.single.id, '1');
    expect(page.items.single.kind, ItemKind.library);
    expect(page.items.single.collectionType, 'music');
  });

  test('favourites star and unstar by id', () async {
    server.ok('star', {});
    server.ok('unstar', {});

    await client.setFavorite('al-1', favorite: true);
    await client.setFavorite('al-1', favorite: false);

    expect(server.calls('star').single.queryParameters['id'], 'al-1');
    expect(server.calls('unstar').single.queryParameters['id'], 'al-1');
  });

  test('lyrics prefer the synced variant and map offsets', () async {
    server.ok('getLyricsBySongId', {
      'lyricsList': {
        'structuredLyrics': [
          {
            'lang': 'eng',
            'synced': false,
            'line': [
              {'value': 'plain'},
            ],
          },
          {
            'lang': 'eng',
            'synced': true,
            'offset': 250,
            'line': [
              {'start': 1000, 'value': 'first'},
              {'start': 2500, 'value': 'second'},
            ],
          },
        ],
      },
    });

    final lyrics = await client.getLyrics('s1');

    expect(lyrics?.isSynced, isTrue);
    expect(lyrics?.offset, const Duration(milliseconds: 250));
    expect(lyrics?.lines.map((l) => l.text), ['first', 'second']);
    expect(lyrics?.lines.first.start, const Duration(seconds: 1));
  });

  test('lyrics are null when the server has none', () async {
    server.ok('getLyricsBySongId', {'lyricsList': <String, Object?>{}});
    expect(await client.getLyrics('s1'), isNull);

    server.on('getLyricsBySongId', (_) => subsonicFailed(70, 'not found'));
    expect(await client.getLyrics('s1'), isNull);
  });

  group('getInstantMix', () {
    test('- maps similar songs for any seed id', () async {
      server.ok('getSimilarSongs', {
        'similarSongs': {
          'song': [childJson('song-1'), childJson('song-2')],
        },
      });

      final songs = await client.getInstantMix('album-1', limit: 25);

      final uri = server.calls('getSimilarSongs').single;
      expect(uri.queryParameters['id'], 'album-1');
      expect(uri.queryParameters['count'], '25');
      expect(songs.map((song) => song.id), ['song-1', 'song-2']);
      expect(songs.first.kind, ItemKind.song);
    });

    test('- returns nothing when the server knows no similar songs', () async {
      server.ok('getSimilarSongs', {'similarSongs': <String, Object?>{}});

      expect(await client.getInstantMix('song-1'), isEmpty);
    });
  });
}
