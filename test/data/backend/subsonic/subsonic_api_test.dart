import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';

import 'subsonic_test_support.dart';

void main() {
  const credentials = SubsonicCredentials(
    username: 'joe',
    token: 'tok',
    salt: 'salt',
  );

  setUpAll(registerSubsonicFallbacks);

  group('uri', () {
    test('- carries auth and protocol params under the server prefix', () {
      final api = SubsonicApi(
        Dio(),
        baseUrl: 'http://music.local:4533/nav/',
        credentials: credentials,
      );

      final uri = api.uri('getAlbum', {
        'id': 'al-1',
        'size': 3,
        'ids': ['a', 'b'],
        'skip': null,
        'empty': <String>[],
      });

      expect(uri.path, '/nav/rest/getAlbum');
      expect(uri.queryParameters['u'], 'joe');
      expect(uri.queryParameters['t'], 'tok');
      expect(uri.queryParameters['s'], 'salt');
      expect(uri.queryParameters['v'], SubsonicApi.apiVersion);
      expect(uri.queryParameters['c'], SubsonicApi.clientId);
      expect(uri.queryParameters['f'], 'json');
      expect(uri.queryParameters['id'], 'al-1');
      expect(uri.queryParameters['size'], '3');
      expect(uri.queryParametersAll['ids'], ['a', 'b']);
      expect(uri.queryParameters.containsKey('skip'), isFalse);
      expect(uri.queryParameters.containsKey('empty'), isFalse);
    });

    test('- omits credentials when probing anonymously', () {
      final uri = SubsonicApi(
        Dio(),
        baseUrl: 'http://music.local',
      ).uri('ping.view');

      expect(uri.path, '/rest/ping.view');
      expect(uri.queryParameters.keys, containsAll(['v', 'c', 'f']));
      expect(uri.queryParameters.containsKey('u'), isFalse);
    });
  });

  group('call', () {
    late SubsonicFakeServer server;
    late SubsonicApi api;

    setUp(() {
      server = SubsonicFakeServer();
      api = SubsonicApi(
        server.dio,
        baseUrl: 'http://music.local',
        credentials: credentials,
      );
    });

    test('- unwraps the envelope', () async {
      server.ok('getMusicFolders', {
        'musicFolders': {
          'musicFolder': [
            {'id': 1, 'name': 'Music Library'},
          ],
        },
      });

      final folders = await api.getMusicFolders();

      expect(folders.single.id, '1');
      expect(folders.single.name, 'Music Library');
    });

    test('- treats an empty section as an empty list', () async {
      server.ok('getPlaylists', {'playlists': <String, Object?>{}});
      server.ok('getStarred2', {'starred2': <String, Object?>{}});
      server.ok('getAlbumList2', {'albumList2': <String, Object?>{}});

      expect(await api.getPlaylists(), isEmpty);
      expect((await api.getStarred2()).song, isEmpty);
      expect(await api.getAlbumList2(type: 'recent'), isEmpty);
    });

    test('- repeats multi-valued playlist params', () async {
      server.ok('updatePlaylist', {});

      await api.updatePlaylist(
        playlistId: 'pl-1',
        public: true,
        songIdToAdd: ['s1', 's2'],
        songIndexToRemove: [3],
      );

      final uri = server.calls('updatePlaylist').single;
      expect(uri.queryParametersAll['songIdToAdd'], ['s1', 's2']);
      expect(uri.queryParametersAll['songIndexToRemove'], ['3']);
      expect(uri.queryParameters['public'], 'true');
    });

    test('- builds stream and cover art URLs with credentials', () {
      final stream = api.streamUri('s1', format: 'mp3', maxBitRate: 320);
      expect(stream.path, '/rest/stream');
      expect(stream.queryParameters['id'], 's1');
      expect(stream.queryParameters['format'], 'mp3');
      expect(stream.queryParameters['maxBitRate'], '320');
      expect(stream.queryParameters['estimateContentLength'], 'true');
      expect(stream.queryParameters['t'], 'tok');

      final art = api.coverArtUri('al-1', size: 64);
      expect(art.path, '/rest/getCoverArt');
      expect(art.queryParameters['id'], 'al-1');
      expect(art.queryParameters['size'], '64');
    });
  });
}
