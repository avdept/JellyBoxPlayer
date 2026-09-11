@Tags(['emby'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/emby/emby_auth_headers.dart';
import 'package:jplayer/src/data/backend/emby/emby_client.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/params/params.dart';

void main() {
  const deviceId = 'jellybox-live-test';
  final env = Platform.environment;
  final baseUrl = env['EMBY_URL'] ?? 'http://localhost:8096';
  final username = env['EMBY_USER'];
  final password = env['EMBY_PASS'];

  final configured = username != null && password != null;

  late EmbyClient client;

  setUpAll(() async {
    if (username == null || password == null) return;
    final dio = Dio(BaseOptions(contentType: 'application/json'))
      ..options.headers.addAll(
        const EmbyAuthHeaders(
          deviceId: deviceId,
          deviceName: 'live-test',
          version: '1.0.0',
        ).build(),
      );

    final auth = await EmbyApi(dio, baseUrl: baseUrl).signIn(
      credentials: UserCredentials(
        username: username,
        pw: password,
        serverUrl: baseUrl,
      ),
    );
    final token = auth.data.accessToken;
    dio.options.headers[EmbyAuthHeaders.tokenHeader] = token;

    client = EmbyClient(
      dio: dio,
      baseUrl: baseUrl,
      userId: auth.data.user.id,
      token: token,
      deviceId: deviceId,
    );
  });

  test('both artist scopes answer on a real Emby server', () async {
    if (!configured) {
      markTestSkipped('set EMBY_URL/EMBY_USER/EMBY_PASS to run this');
      return;
    }

    final all = await client.getArtists(
      const LibraryQuery(artistScope: ArtistScope.allArtists),
    );
    final album = await client.getArtists(
      const LibraryQuery(artistScope: ArtistScope.albumArtists),
    );

    expect(all.items, isNotEmpty);
    final albumNames = album.items.map((item) => item.name).toSet();
    final allNames = all.items.map((item) => item.name).toSet();
    expect(albumNames, everyElement(isIn(allNames)));
  });

  test('both search scopes answer on a real Emby server', () async {
    if (!configured) {
      markTestSkipped('set EMBY_URL/EMBY_USER/EMBY_PASS to run this');
      return;
    }

    final all = await client.getArtists(
      const LibraryQuery(artistScope: ArtistScope.allArtists),
    );
    final term = all.items.first.name;

    final matched = await client.searchArtists(
      SearchQuery(term: term, artistScope: ArtistScope.albumArtists),
    );

    expect(matched.items.map((item) => item.name), contains(term));
  });
}
