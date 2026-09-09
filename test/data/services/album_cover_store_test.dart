import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/services/album_cover_store.dart';
import 'package:path/path.dart' hide equals;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late AlbumCoverStore store;
  final requested = <Uri>[];
  List<int>? response = [1, 2, 3];

  final artwork = Uri.parse('http://server/Items/album-1/Images/Primary');

  File coverOf(String albumId) =>
      File(join(root.path, albumId, DownloadPaths.coverFileName));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('covers');
    DownloadPaths.root = root.path;
    requested.clear();
    response = [1, 2, 3];
    store = AlbumCoverStore(
      fetch: (uri) async {
        requested.add(uri);
        return response;
      },
    );
  });

  tearDown(() async {
    DownloadPaths.root = null;
    if (root.existsSync()) await root.delete(recursive: true);
  });

  group('AlbumCoverStore', () {
    test('- stores a cover for an album', () async {
      final file = await store.ensure('album-1', artwork);

      expect(file, isNotNull);
      expect(coverOf('album-1').existsSync(), isTrue);
      expect(coverOf('album-1').lengthSync(), 3);
      expect(requested, [artwork]);
    });

    test('- fetches a cover only once', () async {
      await store.ensure('album-1', artwork);
      await store.ensure('album-1', artwork);

      expect(requested, hasLength(1));
    });

    test('- does nothing without an image url', () async {
      expect(await store.ensure('album-1', null), isNull);
      expect(requested, isEmpty);
    });

    test('- leaves nothing behind when the fetch comes back empty', () async {
      response = null;

      expect(await store.ensure('album-1', artwork), isNull);
      expect(coverOf('album-1').existsSync(), isFalse);
    });

    test('- sweeps covers nothing references', () async {
      await store.ensure('album-1', artwork);
      await store.ensure('album-2', artwork);

      await store.sweepUnreferenced({'album-1'});

      expect(coverOf('album-1').existsSync(), isTrue);
      expect(coverOf('album-2').existsSync(), isFalse);
    });

    test('- never sweeps a downloaded album', () async {
      await store.ensure('album-3', artwork);
      File(join(root.path, 'album-3', 'song.flac')).writeAsBytesSync([1]);

      await store.sweepUnreferenced(const {});

      expect(coverOf('album-3').existsSync(), isTrue);
    });
  });
}
