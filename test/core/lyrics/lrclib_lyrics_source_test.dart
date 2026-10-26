import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';
import 'package:jplayer/src/core/lyrics/lrclib_lyrics_source.dart';
import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:mocktail/mocktail.dart';

class MockLrclibClient extends Mock implements LrclibClient {}

void main() {
  late MockLrclibClient client;
  late LrclibLyricsSource source;

  const request = LyricsRequest(
    itemId: 'song-1',
    title: 'Song',
    artist: 'Artist',
    album: 'Album',
    duration: Duration(seconds: 200),
  );

  const synced = LrclibTrack(
    id: 1,
    duration: Duration(seconds: 200),
    syncedLyrics: '[00:10.00] First line\n[00:20.00] Second line',
    plainLyrics: 'First line\nSecond line',
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    client = MockLrclibClient();
    source = LrclibLyricsSource(client);
  });

  test('uses the exact match when album and duration are known', () async {
    when(
      () => client.find(
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: const Duration(seconds: 200),
      ),
    ).thenAnswer((_) async => synced);

    final lyrics = await source.fetch(request);

    expect(lyrics!.isSynced, isTrue);
    expect(lyrics.lines, hasLength(2));
    expect(lyrics.lines.first.text, 'First line');
    expect(lyrics.lines.first.start, const Duration(seconds: 10));
    verifyNever(
      () => client.search(
        trackName: any(named: 'trackName'),
        artistName: any(named: 'artistName'),
      ),
    );
  });

  test('falls back to search and prefers a synced duration match', () async {
    when(
      () => client.find(
        trackName: any(named: 'trackName'),
        artistName: any(named: 'artistName'),
        albumName: any(named: 'albumName'),
        duration: any(named: 'duration'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => client.search(trackName: 'Song', artistName: 'Artist'),
    ).thenAnswer(
      (_) async => [
        const LrclibTrack(id: 1, instrumental: true),
        const LrclibTrack(
          id: 2,
          duration: Duration(seconds: 350),
          syncedLyrics: '[00:10.00] Wrong version',
        ),
        const LrclibTrack(
          id: 3,
          duration: Duration(seconds: 202),
          plainLyrics: 'Plain only',
        ),
        const LrclibTrack(
          id: 4,
          duration: Duration(seconds: 198),
          syncedLyrics: '[00:10.00] Right version',
        ),
      ],
    );

    final lyrics = await source.fetch(request);

    expect(lyrics!.isSynced, isTrue);
    expect(lyrics.lines.single.text, 'Right version');
  });

  test('returns plain lyrics unsynced when nothing synced exists', () async {
    when(
      () => client.search(trackName: 'Song', artistName: 'Artist'),
    ).thenAnswer(
      (_) async => [
        const LrclibTrack(id: 3, plainLyrics: 'Line one\nLine two'),
      ],
    );

    final lyrics = await source.fetch(
      const LyricsRequest(itemId: 'song-1', title: 'Song', artist: 'Artist'),
    );

    expect(lyrics!.isSynced, isFalse);
    expect(lyrics.lines.map((line) => line.text), ['Line one', 'Line two']);
  });

  test('skips the lookup without track metadata', () async {
    expect(await source.fetch(const LyricsRequest(itemId: 'song-1')), isNull);
    verifyZeroInteractions(client);
  });

  test('returns null when nothing matches', () async {
    when(
      () => client.search(trackName: 'Song', artistName: 'Artist'),
    ).thenAnswer((_) async => []);

    final lyrics = await source.fetch(
      const LyricsRequest(itemId: 'song-1', title: 'Song', artist: 'Artist'),
    );

    expect(lyrics, isNull);
  });
}
