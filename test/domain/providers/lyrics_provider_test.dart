import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';
import 'package:jplayer/src/data/backend/mappers/lyrics_dto_mapper.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockLrclibClient extends Mock implements LrclibClient {}

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);

  void emit(PlaybackState value) => state = value;
}

LibraryItem _song(String id, {required bool hasLyrics, String? artist}) =>
    LibraryItem(
      id: id,
      name: id,
      kind: ItemKind.song,
      hasLyrics: hasLyrics,
      albumArtist: artist,
    );

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

  ProviderContainer containerWith({
    PlaybackNotifier? playback,
    LrclibClient? lrclib,
  }) => createProviderContainer(
    overrides: [
      mediaServerClientProvider.overrideWithValue(mockClient),
      remoteRendererProvider.overrideWithValue(null),
      playbackProvider.overrideWith(
        (_) => playback ?? FakePlaybackNotifier(PlaybackState.initial()),
      ),
      if (lrclib != null) lrclibClientProvider.overrideWithValue(lrclib),
    ],
  );

  setUp(() {
    mockClient = MockMediaServerClient();
    when(
      () => mockClient.capabilities,
    ).thenReturn(const MediaServerCapabilities());
    when(
      () => mockClient.getLyrics(any()),
    ).thenAnswer((_) => Completer<Lyrics?>().future);
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

      final container = containerWith();
      container
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.lrclibLyrics, value: false);

      await expectLater(
        container.read(lyricsProvider('song-1').future),
        throwsA(isA<MediaServerException>()),
      );
    });
  });

  group('lyricsProvider with LRCLIB', () {
    late MockLrclibClient lrclib;

    setUp(() {
      lrclib = MockLrclibClient();
    });

    ProviderContainer lrclibContainer({required bool enabled}) {
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: false, artist: 'Artist')], 0),
      );
      final container = containerWith(playback: playback, lrclib: lrclib);
      container
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.lrclibLyrics, value: enabled);
      return container;
    }

    test('- falls back to LRCLIB when the server has nothing', () async {
      when(() => mockClient.getLyrics('song-1')).thenAnswer((_) async => null);
      when(
        () => lrclib.search(trackName: 'song-1', artistName: 'Artist'),
      ).thenAnswer(
        (_) async => [
          const LrclibTrack(id: 1, syncedLyrics: '[00:10.00] Hello there'),
        ],
      );

      final result = await lrclibContainer(
        enabled: true,
      ).read(lyricsProvider('song-1').future);

      expect(result!.isSynced, isTrue);
      expect(result.lines.single.text, 'Hello there');
      verify(() => mockClient.getLyrics('song-1')).called(1);
    });

    test('- leaves LRCLIB alone when the server has lyrics', () async {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer((_) async => lyrics);

      final result = await lrclibContainer(
        enabled: true,
      ).read(lyricsProvider('song-1').future);

      expect(result, lyrics);
      verifyZeroInteractions(lrclib);
    });

    test('- stays quiet when the setting is turned off', () async {
      when(() => mockClient.getLyrics('song-1')).thenAnswer((_) async => null);

      final result = await lrclibContainer(
        enabled: false,
      ).read(lyricsProvider('song-1').future);

      expect(result, isNull);
      verifyZeroInteractions(lrclib);
    });

    test('- still answers when the backend has no lyrics support', () async {
      when(
        () => mockClient.capabilities,
      ).thenReturn(const MediaServerCapabilities(lyrics: false));
      when(
        () => lrclib.search(trackName: 'song-1', artistName: 'Artist'),
      ).thenAnswer(
        (_) async => [const LrclibTrack(id: 1, plainLyrics: 'Plain line')],
      );

      final result = await lrclibContainer(
        enabled: true,
      ).read(lyricsProvider('song-1').future);

      expect(result!.isSynced, isFalse);
      expect(result.lines.single.text, 'Plain line');
      verifyNever(() => mockClient.getLyrics(any()));
    });
  });

  group('currentSongHasLyricsProvider', () {
    test('- is off for a lyric-less track until the server says otherwise', () {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer(
        (_) => Future.delayed(const Duration(days: 1), () => null),
      );
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: false)], 0),
      );

      expect(
        containerWith(playback: playback).read(currentSongHasLyricsProvider),
        isFalse,
      );
    });

    test('- turns on when a stale lyric-less track has lyrics now', () async {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer((_) async => lyrics);
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: false)], 0),
      );
      final container = containerWith(playback: playback);
      container.listen(currentSongHasLyricsProvider, (_, _) {});

      await container.read(lyricsProvider('song-1').future);

      expect(container.read(currentSongHasLyricsProvider), isTrue);
    });

    test('- stays on while the lyrics are still loading', () async {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer(
        (_) => Future.delayed(const Duration(days: 1), () => lyrics),
      );
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: true)], 0),
      );

      expect(
        containerWith(playback: playback).read(currentSongHasLyricsProvider),
        isTrue,
      );
    });

    test('- turns off once the server answers with nothing', () async {
      when(() => mockClient.getLyrics('song-1')).thenAnswer((_) async => null);
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: true)], 0),
      );
      final container = containerWith(playback: playback);
      container.listen(currentSongHasLyricsProvider, (_, _) {});

      await container.read(lyricsProvider('song-1').future);

      expect(container.read(currentSongHasLyricsProvider), isFalse);
      container.read(lyricsVisibleProvider.notifier).state = true;
      expect(container.read(lyricsShownProvider), isFalse);
    });

    test('- stays on when real lyrics arrive', () async {
      when(
        () => mockClient.getLyrics('song-1'),
      ).thenAnswer((_) async => lyrics);
      final playback = FakePlaybackNotifier(
        _playing([_song('song-1', hasLyrics: true)], 0),
      );
      final container = containerWith(playback: playback);
      container.listen(currentSongHasLyricsProvider, (_, _) {});

      await container.read(lyricsProvider('song-1').future);

      expect(container.read(currentSongHasLyricsProvider), isTrue);
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
