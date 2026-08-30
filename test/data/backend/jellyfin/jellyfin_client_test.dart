import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  late JellyfinClient client;

  setUp(() {
    client = JellyfinClient(
      dio: Dio(),
      baseUrl: 'http://jelly.local:8096',
      userId: 'user-1',
      token: 'token-1',
      deviceId: 'device-1',
    );
  });

  LibraryItem songWith({String? container, String? codec}) => ItemDTO.fromJson({
    'Id': 'song-1',
    'Name': 'Roads',
    'Type': 'Audio',
    'MediaSources': [
      {
        'Container': container,
        'MediaStreams': [
          {'Type': 'Audio', 'Codec': codec},
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

  group('resolveStreamSource', () {
    test('- returns a direct-play universal URL for a supported container', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'mp3', codec: 'mp3'),
        playSessionId: 'session-1',
      );

      expect(source.isHls, isFalse);
      expect(source.outputContainer, 'mp3');
      expect(source.uri.path, '/Audio/song-1/universal');
      expect(source.uri.queryParameters['UserId'], 'user-1');
      expect(source.uri.queryParameters['ApiKey'], 'token-1');
      expect(source.uri.queryParameters['DeviceId'], 'device-1');
      expect(source.uri.queryParameters['PlaySessionId'], 'session-1');
      expect(source.uri.queryParameters['MediaSourceId'], 'song-1');
      expect(source.uri.queryParameters['TranscodingProtocol'], 'http');
      expect(source.uri.queryParameters.containsKey('SegmentContainer'), isFalse);
    });

    test('- transcodes an unsupported container to HLS', () async {
      final source = await client.resolveStreamSource(
        songWith(container: 'ogg', codec: 'vorbis'),
        playSessionId: 'session-1',
      );

      expect(source.isHls, isTrue);
      expect(source.outputContainer, 'm4a');
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
          preferHls: false,
        );

        expect(source.isHls, isFalse);
        expect(source.uri.path, '/Audio/song-1/universal');
        expect(source.uri.queryParameters['TranscodingContainer'], 'm4a');
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
}
