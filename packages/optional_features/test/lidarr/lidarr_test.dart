import 'package:optional_features/lidarr.dart';
import 'package:test/test.dart';

void main() {
  test('the stub is unavailable and refuses every call', () async {
    final client = LidarrClient(baseUrl: 'http://lidarr', apiKey: 'k');

    expect(client.available, isFalse);
    await expectLater(client.status(), throwsA(isA<LidarrException>()));
    await expectLater(client.rootFolders(), throwsA(isA<LidarrException>()));
  });

  test('models read the fields the app shows', () {
    final album = LidarrAlbum.fromJson({
      'id': 5,
      'artistId': 2,
      'foreignAlbumId': 'rg-1',
      'title': 'Kid A',
      'monitored': true,
      'statistics': {
        'totalTrackCount': 10,
        'trackFileCount': 10,
        'percentOfTracks': 100,
      },
      'artist': {'id': 2, 'foreignArtistId': 'ar-1', 'artistName': 'Radiohead'},
    });

    expect(album.isAdded, isTrue);
    expect(album.isDownloaded, isTrue);
    expect(album.artist?.isAdded, isTrue);
    expect(
      LidarrAlbum.fromJson({'foreignAlbumId': 'x', 'title': 't'}).isAdded,
      isFalse,
    );
  });
}
