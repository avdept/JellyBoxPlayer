import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class _FakePlayback extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  _FakePlayback(super.state);
}

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

  ProviderContainer containerWith({bool shuffleEnabled = false}) {
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
      () => playback.setShuffle(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    return createProviderContainer(
      overrides: [
        playbackProvider.overrideWith((_) => playback),
        setPlaybackProvider.overrideWith(
          (ref) => SetPlaybackNotifier(ref, random: Random(7)),
        ),
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
}
