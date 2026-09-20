import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobble_queue.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const album = LibraryItem(id: 'album', name: 'Dummy', kind: ItemKind.album);
  Listen listenAt(int second) => Listen(
    song: LibraryItem(id: 'song-$second', name: 'Track', kind: ItemKind.song),
    album: album,
    listenedAt: DateTime.utc(2026, 9, 20, 12, 0, second),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists listens across instances and removes in order', () async {
    final queue = ScrobbleQueue('lb');
    await queue.add(listenAt(1));
    await queue.add(listenAt(2));
    await queue.add(listenAt(3));

    final reloaded = ScrobbleQueue('lb');
    expect(await reloaded.pending(), hasLength(3));

    await reloaded.remove([listenAt(1), listenAt(2)]);
    final remaining = await ScrobbleQueue('lb').pending();
    expect(remaining, [listenAt(3)]);
    expect(remaining.single.album, album);
  });

  test('remove only drops the listens that were sent', () async {
    final queue = ScrobbleQueue('lb');
    await queue.add(listenAt(1));
    await queue.add(listenAt(2));
    final batch = await queue.pending();
    await queue.add(listenAt(3));

    await queue.remove(batch);
    expect(await queue.pending(), [listenAt(3)]);
  });

  test('a clear during a concurrent add is not undone', () async {
    final queue = ScrobbleQueue('lb');
    await queue.add(listenAt(1));
    final adding = queue.add(listenAt(2));
    final clearing = queue.clear();
    await Future.wait([adding, clearing]);

    expect(await queue.pending(), isEmpty);
    expect(await ScrobbleQueue('lb').pending(), isEmpty);
  });

  test('keeps queues of different services apart', () async {
    await ScrobbleQueue('lb').add(listenAt(1));
    expect(await ScrobbleQueue('lastfm').pending(), isEmpty);
  });

  test('drops the oldest listens beyond capacity', () async {
    final queue = ScrobbleQueue('lb');
    for (var i = 0; i < ScrobbleQueue.capacity + 5; i++) {
      await queue.add(listenAt(i));
    }
    final pending = await queue.pending();
    expect(pending, hasLength(ScrobbleQueue.capacity));
    expect(pending.first.song.id, 'song-5');
  });

  test('survives unreadable stored data', () async {
    SharedPreferences.setMockInitialValues({
      ScrobbleQueue.storageKeyFor('lb'): '{oops',
    });
    expect(await ScrobbleQueue('lb').pending(), isEmpty);
  });
}
