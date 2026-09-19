@Tags(['subsonic'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_backends.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_client.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  final env = Platform.environment;
  final baseUrl = env['SUBSONIC_URL'] ?? 'http://localhost:4533';
  final username = env['SUBSONIC_USER'];
  final password = env['SUBSONIC_PASS'];
  final configured = username != null && password != null;

  late Dio dio;
  late SubsonicClient client;

  setUpAll(() async {
    if (!configured) return;
    dio = Dio(BaseOptions(contentType: 'application/json'));
    final session =
        await authenticatorFor(
          ServerType.subsonic,
          dio: dio,
        ).signIn(
          UserCredentials(username: username, pw: password, serverUrl: baseUrl),
          serverUrl: baseUrl,
        );
    client =
        clientFor(
              ServerType.subsonic,
              dio: dio,
              baseUrl: baseUrl,
              userId: session.userId,
              token: session.token,
              deviceId: 'jellybox-live-test',
            )
            as SubsonicClient;
  });

  test(
    'probe identifies the server as Subsonic',
    () async {
      final identity = await ServerProbeService().discover(baseUrl);
      expect(identity?.serverType, ServerType.subsonic);
      expect(identity?.productName, isNotEmpty);
      expect(identity?.version, isNotEmpty);
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'session validates and capabilities resolve',
    () async {
      expect(await client.validateSession(), SessionStatus.valid);
      final capabilities = await client.resolveCapabilities();
      expect(capabilities.similarAlbums, isFalse);
      expect(capabilities.lyrics, isTrue);
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'wrong password is reported as invalid',
    () async {
      final bad = clientFor(
        ServerType.subsonic,
        dio: dio,
        baseUrl: baseUrl,
        userId: username ?? '',
        token: 'deadbeef:salt',
        deviceId: 'jellybox-live-test',
      );
      expect(await bad.validateSession(), SessionStatus.invalid);
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'browsing returns libraries, albums, artists, genres and songs',
    () async {
      final libraries = await client.getLibraries();
      expect(libraries.items, isNotEmpty);
      final libraryId = libraries.items.first.id;

      final albums = await client.getAlbums(
        LibraryQuery(libraryId: libraryId, limit: 5),
      );
      expect(albums.items, isNotEmpty);
      expect(albums.items.first.images.hasCover, isTrue);

      final artists = await client.getArtists(
        LibraryQuery(libraryId: libraryId, limit: 5),
      );
      expect(artists.items, isNotEmpty);

      final genres = await client.getGenres(const LibraryQuery(limit: 5));
      expect(genres.items, isNotEmpty);

      final songs = await client.getSongs(albums.items.first.id);
      expect(songs.items, isNotEmpty);
      expect(songs.items.first.audioSources.single.container, isNotNull);
      expect(songs.items.first.audioSources.single.codec, isNotNull);

      final byGenre = await client.getAlbums(
        LibraryQuery(genreIds: [genres.items.first.id], limit: 5),
      );
      expect(byGenre.items, isNotEmpty);

      final ofArtist = await client.getAlbums(
        LibraryQuery(artistIds: [artists.items.first.id]),
      );
      expect(ofArtist.items, isNotEmpty);

      final latest = await client.getLatestAlbums(
        libraryId: libraryId,
        limit: 3,
      );
      expect(latest, isNotEmpty);

      final all = await client.getAllSongs(
        LibraryQuery(libraryId: libraryId, limit: 3),
      );
      expect(all.items, hasLength(3));
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'search finds items of every kind',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 1));
      final song = songs.items.single;
      final term = song.name.split(' ').first;

      expect(
        (await client.searchSongs(SearchQuery(term: term))).items,
        isNotEmpty,
      );
      expect(
        (await client.searchAlbums(SearchQuery(term: song.albumName!))).items,
        isNotEmpty,
      );
      expect(
        (await client.searchArtists(SearchQuery(term: song.artistLabel))).items,
        isNotEmpty,
      );
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'favourites round-trip on a song, an album and an artist',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 1));
      final song = songs.items.single;
      final album = await client.getItem(song.albumId!, kind: ItemKind.album);
      final artist = await client.getItem(
        song.effectiveArtists.first.id,
        kind: ItemKind.artist,
      );

      for (final item in [song, album, artist]) {
        await client.setFavorite(item.id, favorite: true);
      }
      final starredAlbums = await client.getAlbums(
        const LibraryQuery(filters: {ItemFilterFlag.favorite}),
      );
      final starredArtists = await client.getArtists(
        const LibraryQuery(filters: {ItemFilterFlag.favorite}),
      );
      final starredSongs = await client.getAllSongs(
        const LibraryQuery(filters: {ItemFilterFlag.favorite}),
      );
      for (final item in [song, album, artist]) {
        await client.setFavorite(item.id, favorite: false);
      }

      expect(starredAlbums.items.map((a) => a.id), contains(album.id));
      expect(starredArtists.items.map((a) => a.id), contains(artist.id));
      expect(starredSongs.items.map((s) => s.id), contains(song.id));
      expect(
        starredSongs.items
            .firstWhere((s) => s.id == song.id)
            .userData
            .isFavorite,
        isTrue,
      );
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'playlists can be created, filled, trimmed and deleted',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 3));
      final ids = [for (final song in songs.items) song.id];
      final name = 'jellybox-live-${DateTime.now().millisecondsSinceEpoch}';

      await client.createPlaylist(
        PlaylistData(name: name, userId: username!, isPublic: true),
      );
      final playlists = await client.getPlaylists(
        const LibraryQuery(limit: 500),
      );
      final playlist = playlists.items.firstWhere((p) => p.name == name);

      try {
        await client.addPlaylistItems(playlistId: playlist.id, itemIds: ids);
        var entries = await client.getPlaylistSongs(playlist.id);
        expect(entries.items.map((s) => s.id), ids);

        await client.removePlaylistItem(
          playlistId: playlist.id,
          entryId: entries.items[1].playlistItemId!,
        );
        entries = await client.getPlaylistSongs(playlist.id);
        expect(entries.items.map((s) => s.id), [ids[0], ids[2]]);

        final found = await client.searchPlaylists(SearchQuery(term: name));
        expect(found.items.map((p) => p.id), [playlist.id]);
      } finally {
        await client.deletePlaylist(playlist.id);
      }
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'stream URLs are fetchable with the expected content type',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 1));
      final song = songs.items.single;

      final direct = await client.resolveStreamSource(
        song,
        playSessionId: 'live',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );
      final head = await Dio().headUri<void>(direct.uri);
      expect(head.statusCode, 200);
      expect(head.headers.value('content-type'), direct.mimeType);
      expect(head.headers.value('accept-ranges'), 'bytes');

      final transcoded = await client.resolveStreamSource(
        song,
        playSessionId: 'live',
        target: StreamTargetProfile.renderer(sinkMimeTypes: {'audio/x-ms-wma'}),
      );
      expect(transcoded.requiresTranscode, isTrue);
      final response = await Dio().getUri<List<int>>(
        transcoded.uri,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Range': 'bytes=0-1023'},
        ),
      );
      expect(response.headers.value('content-type'), 'audio/mpeg');

      final art = await Dio().headUri<void>(
        client.imageUri(song, kind: ImageKind.album, size: 64)!,
      );
      expect(art.headers.value('content-type'), startsWith('image/'));
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'playback reports are accepted',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 1));
      final song = songs.items.single;
      final report = PlaybackReport(
        itemId: song.id,
        playSessionId: 'live',
        position: Duration.zero,
        duration: song.duration,
      );

      await client.reportPlaybackStarted(report);
      await client.reportPlaybackProgress(report);
      await client.reportPlaybackStopped(report);
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );

  test(
    'lyrics and generated playlists do not fail',
    () async {
      final songs = await client.getAllSongs(const LibraryQuery(limit: 1));
      await client.getLyrics(songs.items.single.id);
      await client.generateTodaysPlaylists(includeDiscovery: true);
    },
    skip: configured ? false : 'set SUBSONIC_USER/SUBSONIC_PASS',
  );
}
