import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
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
  }) => ItemDTO.fromJson({
    'Id': 'song-1',
    'Name': 'Roads',
    'Type': 'Audio',
    'MediaSources': [
      {
        'Id': mediaSourceId,
        'Container': container,
        'MediaStreams': [
          {'Type': 'Audio', 'Codec': codec},
        ],
      },
    ],
  }).toEmbyLibraryItem();

  group('resolveStreamSource', () {
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

    test('- transcodes an unsupported container to HLS', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'ogg', codec: 'vorbis'),
        playSessionId: 'session-1',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(source.isHls, isTrue);
      expect(source.outputContainer, 'm4a');
      expect(source.uri.path, '/Audio/song-1/main.m3u8');
      expect(source.uri.queryParameters['AudioCodec'], 'aac');
      expect(source.uri.queryParameters['SegmentContainer'], 'ts');
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

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.lyrics.map((line) => line.text), ['Yeah!', 'second line']);
      expect(lyrics.lyrics.first.startTime, const Duration(milliseconds: 2400));
    });

    test('- returns empty lyrics without a second request when the song '
        'has no lyric stream', () async {
      respond([
        {'Index': 0, 'Type': 'Audio', 'Codec': 'flac'},
      ]);

      final lyrics = await lyricsClient.getLyrics('57');

      expect(lyrics.lyrics, isEmpty);
      verify(() => mockAdapter.fetch(any(), any(), any())).called(1);
    });
  });
}
