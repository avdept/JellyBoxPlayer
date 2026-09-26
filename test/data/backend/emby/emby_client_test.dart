import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_preference.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/emby/emby_client.dart';
import 'package:jplayer/src/data/backend/emby/mappers/emby_item_mapper.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late EmbyClient client;

  EmbyClient clientAt(String baseUrl) => EmbyClient(
    dio: Dio(),
    baseUrl: baseUrl,
    userId: 'user-1',
    token: 'token-1',
    deviceId: 'device-1',
  );

  setUp(() {
    client = clientAt('http://emby.local:8096');
  });

  LibraryItem songWith({
    String? container,
    String? codec,
    String? mediaSourceId = 'mediasource_song-1',
    int? bitRate,
  }) => ItemDTO.fromJson({
    'Id': 'song-1',
    'Name': 'Roads',
    'Type': 'Audio',
    'MediaSources': [
      {
        'Id': mediaSourceId,
        'Container': container,
        'MediaStreams': [
          {'Type': 'Audio', 'Codec': codec, 'BitRate': bitRate},
        ],
      },
    ],
  }).toEmbyLibraryItem();

  group('resolveStreamSource', () {
    test('- caps a source over the limit', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'flac', codec: 'flac', bitRate: 1000000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(
          isAndroid: false,
        ).withPreference(const StreamPreference(maxBitRate: 128)),
      );

      expect(source.requiresTranscode, isTrue);
      expect(source.uri.queryParameters['AudioCodec'], 'aac');
      expect(source.uri.queryParameters['MaxStreamingBitrate'], '128000');
      expect(source.uri.queryParameters['AudioBitRate'], '128000');
      expect(source.delivered?.bitRate, 128000);
    });

    test('- sends no cap when the source direct plays under it', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'mp3', codec: 'mp3', bitRate: 128000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(
          isAndroid: false,
        ).withPreference(const StreamPreference(maxBitRate: 192)),
      );

      expect(source.requiresTranscode, isFalse);
      expect(
        source.uri.queryParameters.containsKey('MaxStreamingBitrate'),
        isFalse,
      );
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
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.uri.queryParameters['UserId'], 'user-1');
        expect(source.uri.queryParameters['api_key'], 'token-1');
        expect(source.uri.queryParameters['DeviceId'], 'device-1');
        expect(source.uri.queryParameters['PlaySessionId'], 'session-1');
        expect(
          source.uri.queryParameters['MediaSourceId'],
          'mediasource_song-1',
        );
        expect(source.uri.queryParameters['TranscodingProtocol'], 'http');
      },
    );

    test(
      '- transcodes an unsupported container to HLS in ts segments',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'ogg', codec: 'vorbis'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.localPlayer(isAndroid: false),
        );

        expect(source.isHls, isTrue);
        expect(source.uri.path, '/Audio/song-1/main.m3u8');
        expect(source.uri.queryParameters['AudioCodec'], 'aac');
        expect(source.uri.queryParameters['SegmentContainer'], 'ts');
      },
    );

    test(
      '- streams FLAC directly on Apple platforms, never over HLS',
      () async {
        final source = await client.resolveStreamSource(
          songWith(container: 'flac', codec: 'flac'),
          playSessionId: 'session-1',
          target: StreamTargetProfile.localPlayer(
            isAndroid: false,
            isDarwin: true,
          ),
        );

        expect(source.isHls, isFalse);
        expect(source.requiresTranscode, isFalse);
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.mimeType, 'audio/flac');
      },
    );

    test('- transcodes ALAC on Android to progressive FLAC', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'm4a', codec: 'alac'),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(source.isHls, isFalse);
      expect(source.requiresTranscode, isTrue);
      expect(source.uri.path, '/Audio/song-1/universal');
      expect(source.uri.queryParameters['TranscodingContainer'], 'flac');
      expect(source.outputContainer, 'flac');
    });

    test('- asks for ADTS rather than m4a on the progressive path', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'flac', codec: 'flac', bitRate: 1000000),
        playSessionId: 'session-1',
        target: StreamTargetProfile.download(
          isAndroid: false,
        ).withPreference(const StreamPreference(maxBitRate: 128)),
      );

      expect(source.isHls, isFalse);
      expect(source.uri.queryParameters['TranscodingContainer'], 'aac');
      expect(source.outputContainer, 'aac');
      expect(source.mimeType, 'audio/aac');
      expect(source.delivered?.container, 'aac');
      expect(source.delivered?.codec, 'aac');
    });

    test('- falls back to the item id when the source has no id', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'mp3', codec: 'mp3', mediaSourceId: null),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(source.uri.queryParameters['MediaSourceId'], 'song-1');
    });

    test('- keeps the /emby path prefix of the server url', () async {
      final source =
          await clientAt(
            'http://emby.local:8096/emby',
          ).resolveStreamSource(
            songWith(container: 'mp3', codec: 'mp3'),
            playSessionId: 'session-1',
            target: StreamTargetProfile.localPlayer(isAndroid: false),
          );

      expect(source.uri.path, '/emby/Audio/song-1/universal');
      expect(source.uri.queryParameters['api_key'], 'token-1');
    });
  });

  LibraryItem imageItem({
    String id = 'album-1',
    String? primary,
    String? primaryItemId,
    String? albumId,
    String? albumPrimary,
    List<String> backdrops = const [],
  }) => LibraryItem(
    id: id,
    name: 'Dummy',
    kind: ItemKind.album,
    albumId: albumId,
    images: ImageRefs(
      primary: primary,
      primaryItemId: primaryItemId,
      albumPrimary: albumPrimary,
      backdrops: backdrops,
    ),
  );

  group('imageUri', () {
    test('- builds a primary image URL with a tag', () {
      final uri = client.imageUri(imageItem(primary: 'tag-1'))!;

      expect(uri.path, '/Items/album-1/Images/Primary');
      expect(uri.queryParameters['Tag'], 'tag-1');
      expect(uri.queryParameters['MaxWidth'], '420');
      expect(uri.queryParameters['MaxHeight'], '420');
    });

    test('- points at the item emby resolved the image from', () {
      final uri = client.imageUri(
        imageItem(id: 'song-1', primary: 'tag-1', primaryItemId: 'album-1'),
      )!;

      expect(uri.path, '/Items/album-1/Images/Primary');
    });

    test('- falls back to the album image for a song without its own', () {
      final uri = client.imageUri(
        imageItem(id: 'song-1', albumId: 'album-1', albumPrimary: 'tag-1'),
      )!;

      expect(uri.path, '/Items/album-1/Images/Primary');
      expect(uri.queryParameters['Tag'], 'tag-1');
    });

    test('- returns null when the item has no image reference', () {
      expect(client.imageUri(imageItem()), isNull);
    });

    test('- builds a backdrop image URL at a custom size', () {
      final uri = client.imageUri(
        imageItem(backdrops: const ['tag-1']),
        kind: ImageKind.backdrop,
        size: 800,
      )!;

      expect(uri.path, '/Items/album-1/Images/Backdrop');
      expect(uri.queryParameters['MaxHeight'], '800');
    });

    test('- keeps the /emby path prefix of the server url', () {
      final uri = clientAt(
        'http://emby.local:8096/emby',
      ).imageUri(imageItem(primary: 'tag-1'))!;

      expect(uri.path, '/emby/Items/album-1/Images/Primary');
    });
  });

  group('resizedImageUri', () {
    test('- rewrites the max params and leaves the rest alone', () {
      final uri = client.resizedImageUri(
        Uri.parse(
          'http://emby.local/Items/11/Images/Primary'
          '?MaxWidth=420&MaxHeight=420&Quality=96&Tag=t1',
        ),
        1024,
      );

      expect(uri.queryParameters['MaxWidth'], '1024');
      expect(uri.queryParameters['MaxHeight'], '1024');
      expect(uri.queryParameters['Quality'], '96');
      expect(uri.queryParameters['Tag'], 't1');
    });

    test('- does not add size params to a url that has none', () {
      final uri = client.resizedImageUri(
        Uri.parse('http://emby.local/Items/11/Images/Primary?Tag=t1'),
        1024,
      );

      expect(uri.queryParameters.keys, ['Tag']);
    });

    test('- leaves a url without a query untouched', () {
      final original = Uri.parse('http://emby.local/Items/11/Images/Primary');

      expect(client.resizedImageUri(original, 1024), original);
    });
  });

  group('getLyrics', () {
    late MockHttpClientAdapter mockAdapter;
    late EmbyClient lyricsClient;

    setUpAll(() {
      registerFallbackValue(RequestOptions(path: '/'));
      registerFallbackValue(const Stream<Uint8List>.empty());
    });

    ResponseBody json(Object? body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

    Map<String, Object?> itemWith(List<Map<String, Object?>> streams) => {
      'Id': '57',
      'Name': 'Scavenger',
      'Type': 'Audio',
      'MediaSources': [
        {
          'Id': 'mediasource_57',
          'Container': 'flac',
          'MediaStreams': streams,
        },
      ],
    };

    void respond(List<Map<String, Object?>> streams) {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.contains('/Subtitles/')) {
          return ResponseBody.fromString(
            '\u{feff}{"TrackEvents":['
            '{"Text":"Yeah!","StartPositionTicks":24000000},'
            '{"Text":"second line","StartPositionTicks":167600000}]}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return json(itemWith(streams));
      });
    }

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      lyricsClient = EmbyClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://emby.local:8096/emby',
        userId: 'user-1',
        token: 'token-1',
        deviceId: 'device-1',
      );
    });

    test('- fetches the lrc subtitle stream of the lyric track', () async {
      respond([
        {'Index': 0, 'Type': 'Audio', 'Codec': 'flac'},
        {'Index': 2, 'Type': 'Subtitle', 'Codec': 'lrc'},
      ]);

      await lyricsClient.getLyrics('57');

      final requested = verify(
        () => mockAdapter.fetch(captureAny(), any(), any()),
      ).captured.cast<RequestOptions>().map((o) => o.uri.toString()).toList();
      expect(requested.first, contains('/emby/Users/user-1/Items/57'));
      expect(
        requested.last,
        'http://emby.local:8096/emby/Items/57/mediasource_57/Subtitles/2/Stream.js',
      );
    });

    test('- maps the track events onto synced lyrics', () async {
      respond([
        {'Index': 2, 'Type': 'Subtitle', 'Codec': 'lrc'},
      ]);

      final lyrics = await lyricsClient.getLyrics('57');

      expect(lyrics!.isSynced, isTrue);
      expect(lyrics.lines.map((line) => line.text), ['Yeah!', 'second line']);
      expect(lyrics.lines.first.start, const Duration(milliseconds: 2400));
    });

    test('- returns no lyrics without a second request when the song '
        'has no lyric stream', () async {
      respond([
        {'Index': 0, 'Type': 'Audio', 'Codec': 'flac'},
      ]);

      final lyrics = await lyricsClient.getLyrics('57');

      expect(lyrics, isNull);
      verify(() => mockAdapter.fetch(any(), any(), any())).called(1);
    });
  });

  group('artist scope', () {
    late MockHttpClientAdapter mockAdapter;
    late EmbyClient scopedClient;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      scopedClient = EmbyClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://emby.local:8096',
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
    late EmbyClient mixClient;

    setUpAll(() {
      registerFallbackValue(RequestOptions(path: '/'));
      registerFallbackValue(const Stream<Uint8List>.empty());
    });

    setUp(() {
      mockAdapter = MockHttpClientAdapter();
      mixClient = EmbyClient(
        dio: Dio()..httpClientAdapter = mockAdapter,
        baseUrl: 'http://emby.local:8096',
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
      expect(uri.queryParameters['UserId'], 'user-1');
      expect(uri.queryParameters['Limit'], '25');
      expect(uri.queryParametersAll['Fields'], [
        'MediaSources',
        'ProviderIds',
      ]);
      expect(songs.map((song) => song.id), ['song-1', 'song-2']);
      expect(songs.first.kind, ItemKind.song);
    });
  });
}
