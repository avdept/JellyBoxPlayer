import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient mockClient;
  late ImageService imageService;

  final song = LibraryItem(
    id: 'song-1',
    name: 'Roads',
    kind: ItemKind.song,
    albumId: 'album-1',
    images: const ImageRefs(albumPrimary: 'tag-1'),
  );

  setUpAll(() {
    registerFallbackValue(song);
    registerFallbackValue(ImageKind.primary);
    registerFallbackValue(Uri.parse('http://server.local/'));
  });

  setUp(() {
    mockClient = MockMediaServerClient();
    imageService = ImageService(client: () => mockClient);
  });

  void stubImageUri(Uri? uri) => when(
    () => mockClient.imageUri(
      any(),
      kind: any(named: 'kind'),
      size: any(named: 'size'),
    ),
  ).thenReturn(uri);

  group('itemUri', () {
    test('- hands the item to the backend to resolve', () {
      final resolved = Uri.parse('http://server.local/Items/album-1/Primary');
      stubImageUri(resolved);

      expect(imageService.itemUri(song), resolved);
      verify(
        () => mockClient.imageUri(song, kind: ImageKind.primary, size: null),
      ).called(1);
    });

    test('- passes the requested kind and size through', () {
      final artist = song.copyWith(
        images: const ImageRefs(backdrops: ['backdrop-1']),
      );
      stubImageUri(Uri.parse('http://server.local/backdrop'));

      imageService.itemUri(artist, kind: ImageKind.backdrop, size: 800);

      verify(
        () => mockClient.imageUri(artist, kind: ImageKind.backdrop, size: 800),
      ).called(1);
    });

    test('- returns null when the backend has no image for the item', () {
      stubImageUri(null);

      expect(imageService.itemUri(song), isNull);
    });

    test('- does not ask the backend for an item carrying no image refs', () {
      stubImageUri(Uri.parse('http://server.local/never'));

      expect(
        imageService.itemUri(song.copyWith(images: const ImageRefs())),
        isNull,
      );
      verifyNever(
        () => mockClient.imageUri(
          any(),
          kind: any(named: 'kind'),
          size: any(named: 'size'),
        ),
      );
    });

    test(
      '- does not ask the backend for a backdrop the item does not have',
      () {
        stubImageUri(Uri.parse('http://server.local/never'));

        expect(imageService.itemUri(song, kind: ImageKind.backdrop), isNull);
        verifyNever(
          () => mockClient.imageUri(
            any(),
            kind: any(named: 'kind'),
            size: any(named: 'size'),
          ),
        );
      },
    );
  });

  group('itemImage', () {
    test('- wraps a resolved url in a network image provider', () {
      stubImageUri(Uri.parse('http://server.local/Items/album-1/Primary'));

      expect(imageService.itemImage(song), isNot(isA<AssetImage>()));
    });

    test('- falls back to the placeholder asset when there is no image', () {
      stubImageUri(null);

      expect(
        imageService.itemImage(song),
        isA<AssetImage>().having((it) => it.assetName, 'asset', Images.album),
      );
    });

    test('- takes the fallback asset the caller asks for', () {
      stubImageUri(null);

      expect(
        imageService.itemImage(song, fallback: Images.librarySample),
        isA<AssetImage>().having(
          (it) => it.assetName,
          'asset',
          Images.librarySample,
        ),
      );
    });

    test('- returns null instead of a placeholder when asked for it', () {
      stubImageUri(null);

      expect(imageService.itemImageOrNull(song), isNull);
    });
  });

  group('artworkImage', () {
    test('- asks the backend to resize a url when a size is given', () {
      final artUri = Uri.parse('http://server.local/art?fillWidth=420');
      final resized = Uri.parse('http://server.local/art?fillWidth=1024');
      when(() => mockClient.resizedImageUri(any(), any())).thenReturn(resized);

      imageService.artworkImage(artUri, size: 1024);

      verify(() => mockClient.resizedImageUri(artUri, 1024)).called(1);
    });

    test('- leaves the url alone when no size is given', () {
      imageService.artworkImage(
        Uri.parse('http://server.local/art?fillWidth=420'),
      );

      verifyNever(() => mockClient.resizedImageUri(any(), any()));
    });

    test('- reads a downloaded cover straight off disk', () {
      final image = imageService.artworkImage(
        Uri.file('/music/album-1/cover.jpg'),
        size: 1024,
      );

      expect(image, isA<FileImage>());
      verifyNever(() => mockClient.resizedImageUri(any(), any()));
    });

    test('- falls back to the placeholder asset without a url', () {
      expect(
        imageService.artworkImage(null),
        isA<AssetImage>().having((it) => it.assetName, 'asset', Images.album),
      );
    });
  });
}
