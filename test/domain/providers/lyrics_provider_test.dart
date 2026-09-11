import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/mappers/lyrics_dto_mapper.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);

  void emit(PlaybackState value) => state = value;
}

LibraryItem _song(String id, {required bool hasLyrics}) =>
    LibraryItem(id: id, name: id, kind: ItemKind.song, hasLyrics: hasLyrics);

PlaybackState _playing(List<LibraryItem> songs, int index) => PlaybackState(
  album: null,
  songs: songs,
  status: PlaybackStatus.playing,
  position: Duration.zero,
  cacheProgress: Duration.zero,
  currentMediaIndex: index,
);

void main() {
  late MockMediaServerClient mockClient;

  final lyrics = LyricsDTO.fromJson({
    'Metadata': {'IsSynced': true},
    'Lyrics': [
      {'Text': 'first line', 'Start': 0},
      {'Text': 'second line', 'Start': 100000000},
    ],
  }).toLyrics();

  ProviderContainer containerWith({PlaybackNotifier? playback}) =>
      createProviderContainer(
        overrides: [
          mediaServerClientProvider.overrideWithValue(mockClient),
          if (playback != null) playbackProvider.overrideWith((_) => playback),
        ],
      );

  setUp(() {
    mockClient = MockMediaServerClient();
    when(
      () => mockClient.capabilities,
    ).thenReturn(const MediaServerCapabilities());
  });

  group('lyricsProvider', () {
    test('- returns the lyrics the server sends back', () async {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer((_) async => lyrics);

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(lyrics),
      );
      verify(() => mockClient.getLyrics('song-1')).called(1);
    });

    test('- returns null when the backend reports no lyrics', () async {
      when(() => mockClient.getLyrics('song-1')).thenAnswer((_) async => null);

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(isNull),
      );
    });

    test('- asks for nothing when the backend has no lyrics support', () async {
      when(
        () => mockClient.capabilities,
      ).thenReturn(const MediaServerCapabilities(lyrics: false));

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        completion(isNull),
      );
      verifyNever(() => mockClient.getLyrics(any()));
    });

    test('- surfaces a backend failure', () async {
      when(() => mockClient.getLyrics('song-1')).thenThrow(
        const MediaServerException(MediaServerErrorKind.server),
      );

      await expectLater(
        containerWith().read(lyricsProvider('song-1').future),
        throwsA(isA<MediaServerException>()),
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
