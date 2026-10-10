import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_preference.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/letter_index.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/backend/remote_access.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late JellyfinClient client;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    client = JellyfinClient(
      dio: Dio(),
      baseUrl: 'http://jelly.local:8096',
      userId: 'user-1',
      token: 'token-1',
      deviceId: 'device-1',
    );
  });

  LibraryItem songWith({String? container, String? codec, int? bitRate}) =>
      ItemDTO.fromJson({
        'Id': 'song-1',
        'Name': 'Roads',
        'Type': 'Audio',
        'MediaSources': [
          {
            'Container': container,
            'MediaStreams': [
              {'Type': 'Audio', 'Codec': codec, 'BitRate': bitRate},
            ],
          },
        ],
      }).toLibraryItem();

  LibraryItem imageSong({
    String? primary,
    String? albumId,
    String? albumPrimary,
  }) => LibraryItem(
    id: 'song-1',
    name: 'Roads',
    kind: ItemKind.song,
    albumId: albumId,
    images: ImageRefs(primary: primary, albumPrimary: albumPrimary),
  );

  LibraryItem albumWith({
    required String id,
    String? primary,
    List<String> backdrops = const [],
  }) => LibraryItem(
    id: id,
    name: 'Dummy',
    kind: ItemKind.album,
    images: ImageRefs(primary: primary, backdrops: backdrops),
  );

  group('getLyrics', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient lyricsClient;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      lyricsClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
    });

    void respondWith(int statusCode, Object? body) {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(body),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    }

    test('- maps the payload onto synced lyrics', () async {
      respondWith(200, {
        'Metadata': {'IsSynced': true},
        'Lyrics': [
          {'Text': 'first line', 'Start': 0},
          {'Text': 'second line', 'Start': 100000000},
        ],
      });

      final lyrics = await lyricsClient.getLyrics('song-1');

      expect(lyrics!.isSynced, isTrue);
      expect(lyrics.lines.map((line) => line.text), [
        'first line',
        'second line',
      ]);
      expect(lyrics.lines.last.start, const Duration(seconds: 10));
    });

    test('- returns null when the track has no lyrics', () async {
      respondWith(404, {'error': 'not found'});

      expect(await lyricsClient.getLyrics('song-1'), isNull);
    });

    test('- returns null when the server predates the endpoint', () async {
      respondWith(400, {'error': 'bad request'});

      expect(await lyricsClient.getLyrics('song-1'), isNull);
    });

    test('- surfaces any other failure', () async {
      respondWith(500, {'error': 'boom'});

      await expectLater(
        lyricsClient.getLyrics('song-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('resolveStreamSource', () {
    StreamTargetProfile capped(int kbps) => StreamTargetProfile.localPlayer(
      isAndroid: false,
    ).withPreference(StreamPreference(maxBitRate: kbps));

    test('- caps a source over the limit and reports what arrives', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'flac', codec: 'flac', bitRate: 1000000),
        playSessionId: 'session-1',
        target: capped(192),
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.uri.path, '/Audio/song-1/main.m3u8');
      expect(source.uri.queryParameters['AudioCodec'], 'aac');
      expect(source.uri.queryParameters['MaxStreamingBitrate'], '192000');
      expect(source.uri.queryParameters['AudioBitRate'], '192000');
      expect(source.delivered?.codec, 'aac');
      expect(source.delivered?.bitRate, 192000);
    });

    test('- reports no more than the 256k Jellyfin encodes to', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'flac', codec: 'flac', bitRate: 1000000),
        playSessionId: 'session-1',
        target: capped(320),
      );

      expect(source.uri.queryParameters['AudioBitRate'], '320000');
      expect(source.delivered?.bitRate, 256000);
    });

    test('- direct plays a source under the limit', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'mp3', codec: 'mp3', bitRate: 128000),
        playSessionId: 'session-1',
        target: capped(192),
      );

      expect(source.requiresTranscode, isFalse);
      expect(source.uri.path, '/Audio/song-1/universal');
      expect(
        source.uri.queryParameters.containsKey('MaxStreamingBitrate'),
        isFalse,
      );
      expect(source.uri.queryParameters.containsKey('AudioBitRate'), isFalse);
      expect(source.delivered?.codec, 'mp3');
      expect(source.delivered?.bitRate, 128000);
    });

    test(
      '- leaves the server no room to transcode a source exactly at the cap',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'mp3', codec: 'mp3', bitRate: 320000),
          playSessionId: 'session-1',
          target: capped(320),
        );

        expect(source.requiresTranscode, isFalse);
        expect(source.mimeType, 'audio/mpeg');
        expect(
          source.uri.queryParameters.containsKey('MaxStreamingBitrate'),
          isFalse,
        );
        expect(source.uri.queryParameters['Container'], contains('mp3'));
      },
    );

    test('- caps a forced transcode', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'mp3', codec: 'mp3', bitRate: 128000),
        playSessionId: 'session-1',
        target: capped(192),
        forceTranscode: true,
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.uri.queryParameters['AudioBitRate'], '192000');
    });

    test('- sends no bitrate when uncapped', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'flac', codec: 'flac', bitRate: 1000000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(
        source.uri.queryParameters.containsKey('MaxStreamingBitrate'),
        isFalse,
      );
      expect(source.uri.queryParameters.containsKey('AudioBitRate'), isFalse);
      expect(source.delivered?.bitRate, 1000000);
    });

    test(
      '- returns a direct-play universal URL for a supported container',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'mp3', codec: 'mp3'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.localPlayer(isAndroid: false),
        );

        expect(source.isHls, isFalse);
        expect(source.outputContainer, 'mp3');
        expect(source.mimeType, 'audio/mpeg');
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.uri.queryParameters['UserId'], 'user-1');
        expect(source.uri.queryParameters['ApiKey'], 'token-1');
        expect(source.uri.queryParameters['DeviceId'], 'device-1');
        expect(source.uri.queryParameters['PlaySessionId'], 'session-1');
        expect(source.uri.queryParameters['MediaSourceId'], 'song-1');
        expect(source.uri.queryParameters['TranscodingProtocol'], 'http');
        expect(
          source.uri.queryParameters.containsKey('SegmentContainer'),
          isFalse,
        );
      },
    );

    test('- transcodes an unsupported container to HLS', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'ogg', codec: 'vorbis'),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(source.isHls, isTrue);
      expect(source.outputContainer, 'm4a');
      expect(source.mimeType, 'application/vnd.apple.mpegurl');
      expect(source.uri.path, '/Audio/song-1/main.m3u8');
      expect(source.uri.queryParameters['AudioCodec'], 'aac');
      expect(source.uri.queryParameters['SegmentContainer'], 'ts');
      expect(
        source.uri.queryParameters.containsKey('TranscodingProtocol'),
        isFalse,
      );
    });

    test(
      '- falls back to a progressive stream when HLS is not preferred, '
      'even for a source that would otherwise transcode to HLS',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'ogg', codec: 'vorbis'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.download(isAndroid: false),
        );

        expect(source.isHls, isFalse);
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.uri.queryParameters['TranscodingContainer'], 'aac');
        expect(source.outputContainer, 'aac');
        expect(source.mimeType, 'audio/aac');
        expect(source.delivered?.container, 'aac');
      },
    );

    test('- downloads Dolby Digital in m4a on Android as ADTS', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'm4a', codec: 'eac3', bitRate: 768000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.download(isAndroid: true),
      );

      expect(source.isHls, isFalse);
      expect(source.requiresTranscode, isTrue);
      expect(source.uri.queryParameters['AudioCodec'], 'aac');
      expect(source.uri.queryParameters['TranscodingContainer'], 'aac');
      expect(source.outputContainer, 'aac');
    });

    test('- direct-plays Dolby Digital in m4a off Android', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'm4a', codec: 'eac3', bitRate: 768000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.download(isAndroid: false),
      );

      expect(source.requiresTranscode, isFalse);
      expect(source.outputContainer, 'm4a');
      expect(source.uri.queryParameters['Container'], contains('m4a|eac3'));
    });
    test(
      '- routes ALAC on Android through a lossless HLS transcode',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'm4a', codec: 'alac'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.localPlayer(isAndroid: true),
        );

        expect(source.isHls, isTrue);
        expect(source.outputContainer, 'flac');
        expect(source.uri.path, '/Audio/song-1/main.m3u8');
        expect(source.uri.queryParameters['AudioCodec'], 'flac');
        expect(source.uri.queryParameters['SegmentContainer'], 'mp4');
      },
    );

    test('- downloads ALAC on Android as progressive FLAC', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'm4a', codec: 'alac'),
        playSessionId: 'session-1',
        target: StreamTargetProfile.download(isAndroid: true),
      );

      expect(source.isHls, isFalse);
      expect(source.outputContainer, 'flac');
      expect(source.mimeType, 'audio/flac');
      expect(source.uri.path, '/Audio/song-1/universal');
      expect(source.uri.queryParameters['AudioCodec'], 'flac');
      expect(source.uri.queryParameters['TranscodingContainer'], 'flac');
      expect(
        source.uri.queryParameters['Container'],
        'mp3,aac,m4a|aac,m4b|aac,flac,wav',
      );
    });

    test('- direct-plays the same ALAC file off Android', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'm4a', codec: 'alac'),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(source.isHls, isFalse);
      expect(source.outputContainer, 'm4a');
      expect(source.uri.queryParameters['Container'], contains('m4a|alac'));
    });

    test(
      '- asks for a progressive mp3 transcode for an mp3-only renderer',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'flac', codec: 'flac'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.renderer(
            sinkMimeTypes: const {'audio/mpeg'},
          ),
        );

        expect(source.isHls, isFalse);
        expect(source.outputContainer, 'mp3');
        expect(source.mimeType, 'audio/mpeg');
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.uri.queryParameters['AudioCodec'], 'mp3');
        expect(source.uri.queryParameters['TranscodingContainer'], 'mp3');
        expect(source.uri.queryParameters['Container'], 'mp3');
        expect(source.uri.queryParameters['ApiKey'], 'token-1');
      },
    );
  });

  group('imageUri', () {
    test('- builds a primary image URL from the item own tag', () {
      final uri = client.imageUri(albumWith(id: 'album-1', primary: 'tag-1'));

      expect(uri!.path, '/Items/album-1/Images/Primary');
      expect(uri.queryParameters['tag'], 'tag-1');
      expect(uri.queryParameters['fillHeight'], '420');
      expect(uri.queryParameters['fillWidth'], '420');
    });

    test('- falls back to the album image for a song without its own', () {
      final uri = client.imageUri(
        imageSong(albumId: 'album-1', albumPrimary: 'tag-1'),
      );

      expect(uri!.path, '/Items/album-1/Images/Primary');
      expect(uri.queryParameters['tag'], 'tag-1');
    });

    test('- prefers the album image when the album kind is asked for', () {
      final uri = client.imageUri(
        imageSong(primary: 'own', albumId: 'album-1', albumPrimary: 'tag-1'),
        kind: ImageKind.album,
      );

      expect(uri!.path, '/Items/album-1/Images/Primary');
      expect(uri.queryParameters['tag'], 'tag-1');
    });

    test('- returns null when the item has no image reference', () {
      expect(client.imageUri(imageSong()), isNull);
    });

    test('- builds a backdrop image URL at a custom size', () {
      final uri = client.imageUri(
        albumWith(id: 'album-1', backdrops: const ['tag-1']),
        kind: ImageKind.backdrop,
        size: 800,
      );

      expect(uri!.path, '/Items/album-1/Images/Backdrop');
      expect(uri.queryParameters['fillHeight'], '800');
    });
  });

  group('resizedImageUri', () {
    test('- rewrites the fill params and leaves the rest alone', () {
      final uri = client.resizedImageUri(
        Uri.parse(
          'http://jelly.local/Items/a/Images/Primary'
          '?fillWidth=420&fillHeight=420&quality=96&tag=t1',
        ),
        1024,
      );

      expect(uri.queryParameters['fillWidth'], '1024');
      expect(uri.queryParameters['fillHeight'], '1024');
      expect(uri.queryParameters['quality'], '96');
      expect(uri.queryParameters['tag'], 't1');
    });

    test('- leaves a url without size params untouched', () {
      final original = Uri.parse('http://jelly.local/Items/a/Images/Primary');

      expect(client.resizedImageUri(original, 1024), original);
    });
  });

  group('artist scope', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient scopedClient;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      scopedClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    });

    String requestedPath() {
      final captured = verify(
        () => mockAdapter.fetch(captureAny(), any(), any()),
      ).captured.single;
      return (captured as RequestOptions).uri.path;
    }

    test('- browses album artists through the AlbumArtists endpoint', () async {
      await scopedClient.getArtists(
        const LibraryQuery(artistScope: ArtistScope.albumArtists),
      );

      expect(requestedPath(), '/Artists/AlbumArtists');
    });

    test('- browses every artist through the Artists endpoint', () async {
      await scopedClient.getArtists(
        const LibraryQuery(artistScope: ArtistScope.allArtists),
      );

      expect(requestedPath(), '/Artists');
    });

    test('- scopes artists to the selected library', () async {
      await scopedClient.getArtists(
        const LibraryQuery(
          libraryId: 'lib-1',
          artistScope: ArtistScope.albumArtists,
        ),
      );

      final captured = verify(
        () => mockAdapter.fetch(captureAny(), any(), any()),
      ).captured.single;
      final uri = (captured as RequestOptions).uri;
      expect(uri.path, '/Artists/AlbumArtists');
      expect(uri.queryParameters['ParentId'], 'lib-1');
    });

    test(
      '- searches album artists through the AlbumArtists endpoint',
      () async {
        await scopedClient.searchArtists(
          const SearchQuery(
            term: 'portishead',
            artistScope: ArtistScope.albumArtists,
          ),
        );

        expect(requestedPath(), '/Artists/AlbumArtists');
      },
    );

    test('- searches every artist through the Artists endpoint', () async {
      await scopedClient.searchArtists(
        const SearchQuery(
          term: 'portishead',
          artistScope: ArtistScope.allArtists,
        ),
      );

      expect(requestedPath(), '/Artists');
    });

    test('- advertises both scopes', () {
      expect(scopedClient.capabilities.artistScopes, {
        ArtistScope.albumArtists,
        ArtistScope.allArtists,
      });
    });
  });

  group('getInstantMix', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient mixClient;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      mixClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({
            'Items': [
              {'Id': 'song-1', 'Name': 'Roads', 'Type': 'Audio'},
              {'Id': 'song-2', 'Name': 'Glory Box', 'Type': 'Audio'},
            ],
            'TotalRecordCount': 2,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    });

    Uri requestedUri() {
      final captured = verify(
        () => mockAdapter.fetch(captureAny(), any(), any()),
      ).captured.single;
      return (captured as RequestOptions).uri;
    }

    test('- seeds the mix from any item id', () async {
      final songs = await mixClient.getInstantMix('album-1', limit: 25);

      final uri = requestedUri();
      expect(uri.path, '/Items/album-1/InstantMix');
      expect(uri.queryParameters['userId'], 'user-1');
      expect(uri.queryParameters['Limit'], '25');
      expect(uri.queryParametersAll['Fields'], [
        'MediaSources',
        'ProviderIds',
      ]);
      expect(songs.map((song) => song.id), ['song-1', 'song-2']);
      expect(songs.first.kind, ItemKind.song);
    });
  });

  group('searchBySound', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient soundClient;
    final requests = <RequestOptions>[];

    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    setUp(() {
      requests.clear();
      mockAdapter = MockHttpClientAdapter();
      soundClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
    });

    void answer(ResponseBody Function(RequestOptions options) respond) {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        requests.add(options);
        return respond(options);
      });
    }

    test('- posts the query and hydrates ids in similarity order', () async {
      answer(
        (options) => options.path.endsWith('/AudioMuseAI/clap/search')
            ? json({
                'query': 'calm piano',
                'count': 2,
                'results': [
                  {
                    'item_id': 'song-2',
                    'title': 'Glory Box',
                    'similarity': 0.9,
                  },
                  {'item_id': 'song-1', 'title': 'Roads', 'similarity': 0.7},
                ],
              })
            : json({
                'Items': [
                  {'Id': 'song-1', 'Name': 'Roads', 'Type': 'Audio'},
                  {'Id': 'song-2', 'Name': 'Glory Box', 'Type': 'Audio'},
                ],
                'TotalRecordCount': 2,
              }),
      );

      final songs = await soundClient.searchBySound('calm piano', limit: 30);

      final search = requests.first;
      expect(search.method, 'POST');
      expect(
        search.uri.toString(),
        'http://jelly.local:8096/AudioMuseAI/clap/search',
      );
      expect(search.data, {'query': 'calm piano', 'limit': 30});
      final hydrate = requests.last;
      expect(hydrate.uri.path, '/Users/user-1/Items');
      expect(hydrate.uri.queryParameters['Ids'], 'song-2,song-1');
      expect(songs.map((song) => song.id), ['song-2', 'song-1']);
    });

    test('- treats a disabled or unready index as no matches', () async {
      for (final status in [400, 503]) {
        answer((_) => json({'error': 'not ready'}, status));

        expect(await soundClient.searchBySound('calm piano'), isEmpty);
      }
      expect(requests, hasLength(2));
    });

    test('- surfaces any other failure', () async {
      answer((_) => json({'error': 'boom'}, 500));

      await expectLater(
        soundClient.searchBySound('calm piano'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('resolveCapabilities', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient probeClient;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      probeClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
    });

    void respondWith(int statusCode) {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode({'version': '0.1.52'}),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    }

    test('- enables sound search when the AudioMuse plugin answers', () async {
      respondWith(200);

      final capabilities = await probeClient.resolveCapabilities();

      final probe =
          verify(
                () => mockAdapter.fetch(captureAny(), any(), any()),
              ).captured.single
              as RequestOptions;
      expect(probe.uri.path, '/AudioMuseAI/info');
      expect(capabilities.soundSearch, isTrue);
      expect(capabilities.artistScopes, probeClient.capabilities.artistScopes);
    });

    test('- keeps the defaults when the plugin is absent', () async {
      respondWith(404);

      expect((await probeClient.resolveCapabilities()).soundSearch, isFalse);
    });

    test('- probes once', () async {
      respondWith(200);

      await probeClient.resolveCapabilities();
      await probeClient.resolveCapabilities();

      verify(() => mockAdapter.fetch(any(), any(), any())).called(1);
    });
  });

  group('letterOffset', () {
    late MockHttpClientAdapter mockAdapter;
    late JellyfinClient countingClient;
    final requests = <Uri>[];

    setUp(() {
      requests.clear();
      mockAdapter = MockHttpClientAdapter();
      countingClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://jelly.local:8096',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final uri =
            (invocation.positionalArguments.first as RequestOptions).uri;
        requests.add(uri);
        final filtered = uri.queryParameters.containsKey('NameLessThan');
        return ResponseBody.fromString(
          jsonEncode({
            'Items': <Object>[],
            'TotalRecordCount': filtered ? 420 : 1200,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    });

    test('- ascending counts the names below the letter once', () async {
      final offset = await countingClient.letterOffset(
        ItemKind.album,
        const LibraryQuery(libraryId: 'lib-1'),
        'M',
      );

      expect(offset, const LetterOffset(420));
      final uri = requests.single;
      expect(uri.path, '/Users/user-1/Items');
      expect(uri.queryParameters['IncludeItemTypes'], 'MusicAlbum');
      expect(uri.queryParameters['ParentId'], 'lib-1');
      expect(uri.queryParameters['SortBy'], 'SortName');
      expect(uri.queryParameters['NameLessThan'], 'm');
      expect(uri.queryParameters['Limit'], '1');
    });

    test('- # needs no request', () async {
      expect(
        await countingClient.letterOffset(
          ItemKind.album,
          const LibraryQuery(),
          '#',
        ),
        const LetterOffset(0),
      );
      expect(requests, isEmpty);
    });

    test('- descending subtracts the next letter from the total', () async {
      final offset = await countingClient.letterOffset(
        ItemKind.artist,
        const LibraryQuery(direction: SortDirection.descending),
        'M',
      );

      expect(offset, const LetterOffset(780, total: 1200));
      expect(requests.map((uri) => uri.path), ['/Artists', '/Artists']);
      expect(
        requests.map((uri) => uri.queryParameters['NameLessThan']),
        [isNull, 'n'],
      );
    });

    test('- songs count by the same SortName they are listed by', () async {
      await countingClient.getAllSongs(const LibraryQuery());
      await countingClient.letterOffset(
        ItemKind.song,
        const LibraryQuery(),
        'B',
      );

      expect(
        requests.map((uri) => uri.queryParameters['SortBy']),
        ['SortName', 'SortName'],
      );
      expect(requests.last.queryParameters['IncludeItemTypes'], 'Audio');
    });

    test('- is unavailable for other sort orders', () async {
      expect(
        await countingClient.letterOffset(
          ItemKind.album,
          const LibraryQuery(sort: ItemSort.dateCreated),
          'M',
        ),
        isNull,
      );
      expect(requests, isEmpty);
    });
  });

  group('remoteAccess', () {
    late MockHttpClientAdapter adapter;
    late JellyfinClient remoteClient;

    setUp(() {
      adapter = MockHttpClientAdapter();
      remoteClient = JellyfinClient(
        dio: Dio()..httpClientAdapter = adapter,
        baseUrl: 'http://jelly.local:8096/jf',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
    });

    void respond(int status, Object body) {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    }

    test('- reads the address the plugin publishes', () async {
      respond(200, {
        'Url': 'https://abc.tunnel.jellybox.app',
        'Fingerprint': 'AB12',
        'Connected': true,
      });

      expect(
        await remoteClient.remoteAccess(),
        const RemoteAccessResult(
          access: RemoteAccess(
            url: 'https://abc.tunnel.jellybox.app',
            fingerprint: 'ab12',
          ),
        ),
      );
      final request =
          verify(
                () => adapter.fetch(captureAny(), any(), any()),
              ).captured.single
              as RequestOptions;
      expect(request.uri.path, '/jf/JellyboxRemote/Info');
    });

    test(
      '- does not mistake a network failure for having no address',
      () async {
        when(() => adapter.fetch(any(), any(), any())).thenThrow(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/'),
            reason: 'unreachable',
          ),
        );

        await expectLater(
          remoteClient.remoteAccess(),
          throwsA(isA<DioException>()),
        );
      },
    );

    test('- has no address without a fingerprint to pin', () async {
      respond(200, {'Url': 'https://abc.tunnel.jellybox.app'});

      expect((await remoteClient.remoteAccess())?.access, isNull);
    });

    test('- carries the reason when this user gets no seat', () async {
      respond(200, {'Url': null, 'Fingerprint': 'ab12', 'Reason': 'plan_full'});

      expect(
        await remoteClient.remoteAccess(),
        const RemoteAccessResult(denied: 'plan_full'),
      );
    });

    test('- is null on a server without the plugin', () async {
      respond(404, {'error': 'not found'});

      expect(await remoteClient.remoteAccess(), isNull);
    });
  });
}
