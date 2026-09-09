import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/downloads/cache_downloader.dart';

void main() {
  group('BackgroundCacheDownloader', () {
    test('- namespaces task ids away from user downloads', () {
      expect(
        BackgroundCacheDownloader.taskIdFor('song-1'),
        'queue-cache-song-1',
      );
      expect(BackgroundCacheDownloader.taskIdFor('song-1'), isNot('song-1'));
    });
  });
}
