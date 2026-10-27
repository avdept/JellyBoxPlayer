import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory sandbox;
  late Directory root;
  late Directory outside;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('download-paths');
    root = await Directory(p.join(sandbox.path, 'music')).create();
    outside = await Directory(p.join(sandbox.path, 'outside')).create();
    DownloadPaths.root = root.path;
  });

  tearDown(() async {
    DownloadPaths.root = null;
    if (sandbox.existsSync()) await sandbox.delete(recursive: true);
  });

  const hostile = [
    '../x',
    '../../x',
    r'..\x',
    '/abs/path',
    r'C:\x',
    'a/../../x',
    '.',
    '..',
    'a\u0000b',
    'trailing.',
    'trailing ',
    'CON',
    'nul',
    'COM1',
    'jellybox:liked-songs:user-1',
  ];
  final tooLong = 'a' * 500;
  const guid = '3f1a2b4c5d6e7f8091a2b3c4d5e6f708';
  const navidrome = '0a1b2c3d-4e5f-6071-8293-a4b5c6d7e8f9';

  group('DownloadPaths.segment', () {
    test('- keeps ordinary ids unchanged', () {
      expect(DownloadPaths.segment(guid), guid);
      expect(DownloadPaths.segment(navidrome), navidrome);
      expect(DownloadPaths.segment('album_1'), 'album_1');
      expect(DownloadPaths.segment('12345'), '12345');
    });

    test('- encodes hostile ids to a bare hex name', () {
      for (final id in [...hostile, tooLong]) {
        final segment = DownloadPaths.segment(id);
        expect(segment, matches(RegExp(r'^[0-9a-f]{64}$')), reason: id);
        expect(p.basename(segment), segment, reason: id);
      }
    });

    test('- is stable', () {
      expect(DownloadPaths.segment('../x'), DownloadPaths.segment('../x'));
      expect(
        DownloadPaths.segment('../x'),
        isNot(DownloadPaths.segment('../y')),
      );
    });

    test('- rejects an empty id', () {
      expect(() => DownloadPaths.segment(''), throwsArgumentError);
    });
  });

  group('DownloadPaths.fileName', () {
    test('- joins a safe id with a lower-cased extension', () {
      expect(DownloadPaths.fileName(guid, 'FLAC'), '$guid.flac');
      expect(DownloadPaths.fileName('../x', 'mp3'), endsWith('.mp3'));
      expect(p.basename(DownloadPaths.fileName('../x', 'mp3')), isNot('x.mp3'));
    });

    test('- rejects unsafe extensions', () {
      for (final extension in ['', '../x', 'flac/..', 'm4a\u0000', '.flac']) {
        expect(
          () => DownloadPaths.fileName(guid, extension),
          throwsArgumentError,
          reason: extension,
        );
      }
    });
  });

  group('DownloadPaths directories', () {
    test('- album and cover paths stay inside the root', () {
      for (final id in [...hostile, tooLong, guid, navidrome]) {
        final album = DownloadPaths.albumDirectory(id)!;
        final cover = DownloadPaths.coverPath(id)!;
        final song = DownloadPaths.songPath(id, 'song.flac')!;
        expect(p.isWithin(root.path, album), isTrue, reason: id);
        expect(p.isWithin(album, cover), isTrue, reason: id);
        expect(p.isWithin(album, song), isTrue, reason: id);
        expect(p.dirname(album), root.path, reason: id);
      }
    });

    test('- ordinary ids resolve to the same directories as before', () {
      expect(DownloadPaths.albumDirectory(guid), p.join(root.path, guid));
      expect(
        DownloadPaths.coverPath(navidrome),
        p.join(root.path, navidrome, DownloadPaths.coverFileName),
      );
    });

    test('- empty ids resolve to nothing', () {
      expect(DownloadPaths.albumDirectory(''), isNull);
      expect(DownloadPaths.coverPath(''), isNull);
      expect(DownloadPaths.coverFile(''), isNull);
      expect(DownloadPaths.coverFile(null), isNull);
    });

    test('- song paths refuse file names with directory parts', () {
      for (final name in ['../x.flac', 'a/b.flac', '']) {
        expect(
          () => DownloadPaths.songPath(guid, name),
          throwsArgumentError,
          reason: name,
        );
      }
    });

    test('- resolveWithin refuses escapes and the root itself', () {
      expect(
        () => DownloadPaths.resolveWithin(root.path, ['..', 'x']),
        throwsA(isA<UnsafePathException>()),
      );
      expect(
        () => DownloadPaths.resolveWithin(root.path, ['a', '..', '..', 'x']),
        throwsA(isA<UnsafePathException>()),
      );
      expect(
        () => DownloadPaths.resolveWithin(root.path, ['/abs/path']),
        throwsA(isA<UnsafePathException>()),
      );
      expect(
        () => DownloadPaths.resolveWithin(root.path, []),
        throwsA(isA<UnsafePathException>()),
      );
      expect(
        () => DownloadPaths.resolveWithin(root.path, ['.']),
        throwsA(isA<UnsafePathException>()),
      );
      expect(
        DownloadPaths.resolveWithin(root.path, ['a', 'b']),
        p.join(root.path, 'a', 'b'),
      );
    });
  });

  group('DownloadPaths.deleteAlbumDirectory', () {
    test('- deletes a real album directory', () async {
      final album = Directory(p.join(root.path, guid));
      await File(p.join(album.path, 'song.flac')).create(recursive: true);

      await DownloadPaths.deleteAlbumDirectory(guid);

      expect(album.existsSync(), isFalse);
      expect(root.existsSync(), isTrue);
    });

    test('- never touches anything outside the root', () async {
      final victim = await File(p.join(outside.path, 'keep.txt')).create();
      final rootFile = await File(p.join(root.path, 'keep.txt')).create();

      for (final id in [...hostile, tooLong, '../outside', '../music']) {
        await DownloadPaths.deleteAlbumDirectory(id);
      }

      expect(victim.existsSync(), isTrue);
      expect(rootFile.existsSync(), isTrue);
      expect(root.existsSync(), isTrue);
      expect(sandbox.existsSync(), isTrue);
    });

    test('- refuses a symlinked album directory', () async {
      final victim = await File(p.join(outside.path, 'keep.txt')).create();
      final link = await Link(
        p.join(root.path, 'linked'),
      ).create(outside.path);

      await DownloadPaths.deleteAlbumDirectory('linked');

      expect(victim.existsSync(), isTrue);
      expect(link.existsSync(), isTrue);
    });

    test('- refuses a symlink back to the root', () async {
      final rootFile = await File(p.join(root.path, 'keep.txt')).create();
      await Link(p.join(root.path, 'self')).create(root.path);

      await DownloadPaths.deleteAlbumDirectory('self');

      expect(rootFile.existsSync(), isTrue);
      expect(root.existsSync(), isTrue);
    });
  });

  group('StoredFilePath.relativize', () {
    test('- keeps the album and file segments of an absolute path', () {
      expect(
        StoredFilePath.relativize(
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/music/'
          'album1/track.flac',
          depth: 2,
        ),
        'album1/track.flac',
      );
      expect(
        StoredFilePath.relativize(
          r'C:\Users\old\AppData\Roaming\jellybox\music\album2\track.flac',
          depth: 2,
        ),
        'album2/track.flac',
      );
      expect(
        StoredFilePath.relativize('/old/Library/queue_cache/a.flac', depth: 1),
        'a.flac',
      );
    });

    test('- leaves relative values alone', () {
      expect(StoredFilePath.relativize('album1/track.flac', depth: 2), isNull);
      expect(StoredFilePath.relativize('a.flac', depth: 1), isNull);
    });

    test('- refuses paths that are too shallow or escape', () {
      expect(StoredFilePath.relativize('/track.flac', depth: 2), isNull);
      expect(StoredFilePath.relativize('/a/track.flac', depth: 2), isNull);
      expect(StoredFilePath.relativize('/a/b/../track.flac', depth: 2), isNull);
    });
  });

  group('StoredFilePath.resolve', () {
    test('- joins a relative value under the root', () {
      expect(
        StoredFilePath.resolve('album1/track.flac', root: root.path, depth: 2),
        p.join(root.path, 'album1', 'track.flac'),
      );
      expect(
        StoredFilePath.resolve('a.flac', root: root.path, depth: 1),
        p.join(root.path, 'a.flac'),
      );
    });

    test('- rebases an absolute path from an old container', () {
      expect(
        StoredFilePath.resolve(
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/music/'
          'album1/track.flac',
          root: root.path,
          depth: 2,
        ),
        p.join(root.path, 'album1', 'track.flac'),
      );
      expect(
        StoredFilePath.resolve(
          r'C:\Users\old\AppData\Roaming\jellybox\music\album1\track.flac',
          root: root.path,
          depth: 2,
        ),
        p.join(root.path, 'album1', 'track.flac'),
      );
    });

    test('- a path already under the root resolves to itself', () {
      final current = p.join(root.path, 'album1', 'track.flac');
      expect(
        StoredFilePath.resolve(current, root: root.path, depth: 2),
        current,
      );
    });

    test('- never resolves outside the root', () {
      for (final stored in [
        '../x.flac',
        '../../outside/x.flac',
        'a/../../x.flac',
        '/x.flac',
        '',
        '/',
      ]) {
        final resolved = StoredFilePath.resolve(
          stored,
          root: root.path,
          depth: 2,
        );
        expect(resolved, isNull, reason: stored);
      }
    });

    test('- without a root only absolute values pass through', () {
      expect(
        StoredFilePath.resolve('/old/music/a/b.flac', root: null, depth: 2),
        '/old/music/a/b.flac',
      );
      expect(StoredFilePath.resolve('a/b.flac', root: null, depth: 2), isNull);
    });
  });

  group('StoredFilePath.relativeTo', () {
    test('- stores paths under the root as portable relative values', () {
      expect(
        StoredFilePath.relativeTo(
          p.join(root.path, 'album1', 'track.flac'),
          root: root.path,
        ),
        'album1/track.flac',
      );
    });

    test('- keeps paths outside the root untouched', () {
      final foreign = p.join(outside.path, 'track.flac');
      expect(StoredFilePath.relativeTo(foreign, root: root.path), foreign);
      expect(StoredFilePath.relativeTo(foreign, root: null), foreign);
    });
  });

  group('DownloadPaths.isResolvedWithinRoot', () {
    test('- accepts real children and rejects the root and escapes', () async {
      final album = await Directory(p.join(root.path, guid)).create();
      expect(await DownloadPaths.isResolvedWithinRoot(album.path), isTrue);
      expect(await DownloadPaths.isResolvedWithinRoot(root.path), isFalse);
      expect(await DownloadPaths.isResolvedWithinRoot(outside.path), isFalse);
      expect(
        await DownloadPaths.isResolvedWithinRoot(p.join(root.path, 'missing')),
        isFalse,
      );
    });
  });
}
