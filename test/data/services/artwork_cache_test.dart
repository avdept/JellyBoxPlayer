import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';

class _Response implements FileServiceResponse {
  const _Response({this.statusCode = 200, this.fileExtension = '.png'});

  @override
  final int statusCode;

  @override
  final String fileExtension;

  @override
  Stream<List<int>> get content => const Stream.empty();

  @override
  int? get contentLength => null;

  @override
  String? get eTag => null;

  @override
  DateTime get validTill => DateTime(2100);
}

void main() {
  const home = 'http://jellyfin.home';
  const relay = 'https://cloud.jellybox.app/r/key';
  const cover = '/Items/a1/Images/Primary?fillWidth=420&tag=t';

  const onRelay = ArtworkRoute(addresses: [home, relay], active: relay);

  test('- files a cover under the same key at home and over the tunnel', () {
    expect(onRelay.keyFor('$home$cover'), cover);
    expect(onRelay.keyFor('$relay$cover'), cover);
  });

  test('- fetches a cover built for home through the active address', () {
    expect(onRelay.fetchUrl('$home$cover'), '$relay$cover');
    expect(onRelay.fetchUrl('$relay$cover'), '$relay$cover');
  });

  test('- refuses to file an error document as artwork', () {
    expect(ArtworkCache.isArtwork(const _Response()), isTrue);
    expect(ArtworkCache.isArtwork(const _Response(fileExtension: '')), isTrue);
    expect(
      ArtworkCache.isArtwork(const _Response(fileExtension: '.bin')),
      isTrue,
    );
    expect(
      ArtworkCache.isArtwork(const _Response(fileExtension: '.json')),
      isFalse,
    );
    expect(
      ArtworkCache.isArtwork(const _Response(fileExtension: '.html')),
      isFalse,
    );
    expect(
      ArtworkCache.isArtwork(
        const _Response(statusCode: 404, fileExtension: '.json'),
      ),
      isTrue,
    );
  });

  test('- leaves addresses of other hosts alone', () {
    const elsewhere = 'http://jellyfin.homelab/Items/a1/Images/Primary';

    expect(onRelay.keyFor(elsewhere), elsewhere);
    expect(onRelay.fetchUrl(elsewhere), elsewhere);
  });
}
