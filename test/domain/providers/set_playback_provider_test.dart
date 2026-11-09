import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class _FakePlayback extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  _FakePlayback(super.state);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

const _playlist = LibraryItem(
  id: 'pl',
  name: 'Road trip',
  kind: ItemKind.playlist,
);

LibraryItem _song(String id) =>
    LibraryItem(id: id, name: 'Song $id', kind: ItemKind.song);

void main() {
  late _FakePlayback playback;

  setUpAll(() {
    registerFallbackValue(_playlist);
    registerFallbackValue(<LibraryItem>[]);
  });

  ProviderContainer containerWith({
    bool shuffleEnabled = false,
    List<Override> extra = const [],
  }) {
    playback = _FakePlayback(
      PlaybackState(
        album: null,
        songs: const [],
        status: PlaybackStatus.stopped,
        position: Duration.zero,
        cacheProgress: Duration.zero,
        shuffleEnabled: shuffleEnabled,
      ),
    );
    when(
      () => playback.play(
        any(),
        any(),
        any(),
        sourceId: any(named: 'sourceId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => playback.play(
        any(),
        any(),
        any(),
        sourceId: any(named: 'sourceId'),
        initialPosition: any(named: 'initialPosition'),
        resuming: any(named: 'resuming'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => playback.setShuffle(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    return createProviderContainer(
      overrides: [
        playbackProvider.overrideWith((_) => playback),
        setPlaybackProvider.overrideWith(
          (ref) => SetPlaybackNotifier(ref, random: Random(7)),
        ),
        ...extra,
      ],
    );
  }

  final songs = [for (var i = 0; i < 8; i++) _song('$i')];

  group('shufflePlay', () {
    test('- plays every song once in a new order from its start', () async {
      final container = containerWith();

      final result = await container
          .read(setPlaybackProvider.notifier)
          .shufflePlay(_playlist, () async => songs);

      expect(result, SetPlaybackResult.started);
      final call = verify(
        () => playback.play(
          captureAny(),
          captureAny(),
          _playlist,
          sourceId: _playlist.id,
        ),
      )..called(1);
      final first = call.captured[0] as LibraryItem;
      final queue = call.captured[1] as List<LibraryItem>;
      expect(queue.map((s) => s.id).toSet(), songs.map((s) => s.id).toSet());
      expect(queue, hasLength(songs.length));
      expect(queue.map((s) => s.id), isNot(songs.map((s) => s.id)));
      expect(first, queue.first);
      verifyNever(() => playback.setShuffle(enabled: any(named: 'enabled')));
    });

    test('- turns shuffle mode off before playing the shuffled list', () async {
      final container = containerWith(shuffleEnabled: true);

      await container
          .read(setPlaybackProvider.notifier)
          .shufflePlay(_playlist, () async => songs);

      verifyInOrder([
        () => playback.setShuffle(enabled: false),
        () => playback.play(
          any(),
          any(),
          any(),
          sourceId: any(named: 'sourceId'),
        ),
      ]);
    });

    test('- leaves playback alone when the playlist is empty', () async {
      final container = containerWith(shuffleEnabled: true);

      final result = await container
          .read(setPlaybackProvider.notifier)
          .shufflePlay(_playlist, () async => const []);

      expect(result, SetPlaybackResult.empty);
      verifyNever(() => playback.setShuffle(enabled: any(named: 'enabled')));
      verifyNever(
        () => playback.play(
          any(),
          any(),
          any(),
          sourceId: any(named: 'sourceId'),
        ),
      );
    });
  });

  group('resume', () {
    late _MockMediaServerClient client;

    ResumePoint pointAt(String songId) => (
      item: _playlist,
      songId: songId,
      songName: 'Song $songId',
      songIndex: 4,
      songCount: songs.length,
      position: const Duration(seconds: 75),
      updatedAt: DateTime.utc(2026, 11, 9),
    );

    ProviderContainer resumeContainer(List<LibraryItem> stored) {
      client = _MockMediaServerClient();
      when(
        () => client.getPlaylistSongs(_playlist.id),
      ).thenAnswer((_) async => LibraryPage(items: stored));
      return containerWith(
        extra: [
          mediaServerClientProvider.overrideWith((_) => client),
          isOfflineProvider.overrideWithValue(false),
        ],
      );
    }

    test('- starts the saved song at the saved position', () async {
      final container = resumeContainer(songs);

      final result = await container
          .read(setPlaybackProvider.notifier)
          .resume(pointAt('4'));

      expect(result, SetPlaybackResult.started);
      verify(
        () => playback.play(
          songs[4],
          songs,
          _playlist,
          sourceId: _playlist.id,
          initialPosition: const Duration(seconds: 75),
          resuming: true,
        ),
      ).called(1);
    });

    test('- starts from the top when the saved song is gone', () async {
      final container = resumeContainer(songs);

      final result = await container
          .read(setPlaybackProvider.notifier)
          .resume(pointAt('gone'));

      expect(result, SetPlaybackResult.started);
      verify(
        () => playback.play(
          songs.first,
          songs,
          _playlist,
          sourceId: _playlist.id,
        ),
      ).called(1);
    });

    test('- reports an empty set', () async {
      final container = resumeContainer(const []);

      final result = await container
          .read(setPlaybackProvider.notifier)
          .resume(pointAt('4'));

      expect(result, SetPlaybackResult.empty);
    });
  });
}
