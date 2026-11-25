import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/resume_points_provider.dart';
import 'package:mocktail/mocktail.dart';

class _FakePlayback extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  _FakePlayback(super.state);
}

const _album = LibraryItem(id: 'album-1', name: 'Roads', kind: ItemKind.album);
const _other = LibraryItem(id: 'album-2', name: 'Dummy', kind: ItemKind.album);

final ResumePoint _point = (
  item: _album,
  songId: 'song-3',
  songName: 'Glory Box',
  songIndex: 2,
  songCount: 11,
  position: const Duration(minutes: 1),
  updatedAt: DateTime(2026, 11, 25),
);

PlaybackState _playing(LibraryItem set, PlaybackStatus status) => PlaybackState(
  album: set,
  songs: const [
    LibraryItem(id: 'song-1', name: 'Mysterons', kind: ItemKind.song),
  ],
  status: status,
  position: const Duration(seconds: 20),
  cacheProgress: Duration.zero,
  currentMediaIndex: 0,
  sourceId: set.id,
);

void main() {
  late _FakePlayback playback;
  late ProviderContainer container;

  setUp(() {
    playback = _FakePlayback(
      const PlaybackState(
        album: null,
        songs: [],
        status: PlaybackStatus.stopped,
        position: Duration.zero,
        cacheProgress: Duration.zero,
      ),
    );
    container = ProviderContainer(
      overrides: [
        playbackProvider.overrideWith((_) => playback),
        resumePointProvider.overrideWith(
          (ref, id) => id == _album.id ? _point : null,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  ResumePoint? offer() => container.read(resumeOfferProvider(_album.id));

  group('resumeOfferProvider', () {
    test('- offers resume while nothing is playing', () {
      expect(offer(), _point);
    });

    test('- offers resume while another album is playing', () {
      playback.state = _playing(_other, PlaybackStatus.playing);

      expect(offer(), _point);
    });

    test('- offers resume while this album is paused', () {
      playback.state = _playing(_album, PlaybackStatus.paused);

      expect(offer(), _point);
    });

    test('- hides resume while this album is the one playing', () {
      final sub = container.listen(resumeOfferProvider(_album.id), (_, _) {});
      addTearDown(sub.close);

      playback.state = _playing(_album, PlaybackStatus.playing);
      expect(sub.read(), isNull);

      playback.state = _playing(_album, PlaybackStatus.buffering);
      expect(sub.read(), isNull);

      playback.state = _playing(_album, PlaybackStatus.playing);
      expect(sub.read(), isNull);

      playback.state = _playing(_other, PlaybackStatus.playing);
      expect(sub.read(), _point);
    });
  });
}
