import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart';

import '../../provider_container.dart';

class MockJellyfinApi extends Mock implements JellyfinApi {}

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);

  void emit(PlaybackState value) => state = value;
}

ItemDTO _song(String id, {required bool hasLyrics}) =>
    ItemDTO(id: id, name: id, type: 'Audio', hasLyrics: hasLyrics);

PlaybackState _playing(List<ItemDTO> songs, int index) => PlaybackState(
  album: null,
  songs: songs,
  status: PlaybackStatus.playing,
  position: Duration.zero,
  cacheProgress: Duration.zero,
  currentMediaIndex: index,
);

DioException _failure(int? statusCode) {
  final options = RequestOptions(path: '/Audio/song-1/Lyrics');
  return DioException(
    requestOptions: options,
    response: statusCode == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  late MockJellyfinApi mockApi;

  final lyrics = LyricsDTO.fromJson({
    'Metadata': {'IsSynced': true},
    'Lyrics': [
      {'Text': 'first line', 'Start': 0},
      {'Text': 'second line', 'Start': 100000000},
    ],
  });

  ProviderContainer containerWith({PlaybackNotifier? playback}) =>
      createProviderContainer(
        overrides: [
          jellyfinApiProvider.overrideWithValue(mockApi),
          if (playback != null) playbackProvider.overrideWith((_) => playback),
        ],
      );

  setUp(() => mockApi = MockJellyfinApi());

  group('lyricsProvider', () {
    test('- returns the lyrics the server sends back', () async {
      when(() => mockApi.getLyrics(itemId: 'song-1')).thenAnswer(
        (_) async => HttpResponse(
          lyrics,
          Response<dynamic>(requestOptions: RequestOptions(path: '')),
        ),
      );

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(lyrics),
      );
      verify(() => mockApi.getLyrics(itemId: 'song-1')).called(1);
    });

    test('- returns null when the track has no lyrics (404)', () async {
      when(
        () => mockApi.getLyrics(itemId: 'song-1'),
      ).thenThrow(_failure(404));

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(isNull),
      );
    });

    test('- returns null when the server predates the endpoint (400)', () async {
      when(
        () => mockApi.getLyrics(itemId: 'song-1'),
      ).thenThrow(_failure(400));

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(isNull),
      );
    });

    test('- surfaces other failures', () async {
      when(
        () => mockApi.getLyrics(itemId: 'song-1'),
      ).thenThrow(_failure(500));

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('lyricsShownProvider', () {
    test('- stays off until the user asks for lyrics', () {
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: true)], 0),
      );
      final container = containerWith(playback: playback);

      expect(container.read(lyricsShownProvider), isFalse);

      container.read(lyricsVisibleProvider.notifier).state = true;

      expect(container.read(lyricsShownProvider), isTrue);
    });

    test('- stays off for a track without lyrics', () {
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: false)], 0),
      );
      final container = containerWith(playback: playback);
      container.read(lyricsVisibleProvider.notifier).state = true;

      expect(container.read(lyricsShownProvider), isFalse);
    });

    test('- falls back to the artwork when the next track has no lyrics, '
        'then picks back up', () {
      final songs = [
        _song('with-lyrics', hasLyrics: true),
        _song('without-lyrics', hasLyrics: false),
        _song('with-lyrics-again', hasLyrics: true),
      ];
      final playback = FakePlaybackNotifier(_playing(songs, 0));
      final container = containerWith(playback: playback);
      container.read(lyricsVisibleProvider.notifier).state = true;
      expect(container.read(lyricsShownProvider), isTrue);

      playback.emit(_playing(songs, 1));
      expect(container.read(lyricsShownProvider), isFalse);
      expect(container.read(lyricsVisibleProvider), isTrue);

      playback.emit(_playing(songs, 2));
      expect(container.read(lyricsShownProvider), isTrue);
    });

    test('- stays off while nothing is playing', () {
      final playback = FakePlaybackNotifier(PlaybackState.initial());
      final container = containerWith(playback: playback);
      container.read(lyricsVisibleProvider.notifier).state = true;

      expect(container.read(lyricsShownProvider), isFalse);
    });
  });
}
