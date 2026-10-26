import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:jplayer/src/domain/models/models.dart';

class _FakeSource implements LyricsSource {
  _FakeSource(this._fetch);

  final Future<Lyrics?> Function() _fetch;
  int calls = 0;

  @override
  String get id => 'fake';

  @override
  Future<Lyrics?> fetch(LyricsRequest request) {
    calls++;
    return _fetch();
  }
}

void main() {
  const request = LyricsRequest(itemId: 'song-1');
  const lyrics = Lyrics(lines: [LyricLine(text: 'line')]);

  test('returns the first source that has lyrics', () async {
    final first = _FakeSource(() async => lyrics);
    final second = _FakeSource(() async => lyrics);

    expect(await resolveLyrics([first, second], request), lyrics);
    expect(second.calls, 0);
  });

  test('moves past sources without lyrics', () async {
    final empty = _FakeSource(() async => null);
    final filled = _FakeSource(() async => lyrics);

    expect(await resolveLyrics([empty, filled], request), lyrics);
    expect(empty.calls, 1);
  });

  test('moves past a failing source', () async {
    final failing = _FakeSource(() async => throw Exception('down'));
    final filled = _FakeSource(() async => lyrics);

    expect(await resolveLyrics([failing, filled], request), lyrics);
  });

  test('returns null when one source answered and another failed', () async {
    final failing = _FakeSource(() async => throw Exception('down'));
    final empty = _FakeSource(() async => null);

    expect(await resolveLyrics([failing, empty], request), isNull);
  });

  test('throws the first error when every source fails', () async {
    final first = _FakeSource(() async => throw StateError('first'));
    final second = _FakeSource(() async => throw StateError('second'));

    await expectLater(
      resolveLyrics([first, second], request),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'first'),
      ),
    );
  });

  test('returns null without sources', () async {
    expect(await resolveLyrics(const [], request), isNull);
  });
}
