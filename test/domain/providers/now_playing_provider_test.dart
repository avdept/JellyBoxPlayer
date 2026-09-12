import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediaServerClient extends Mock implements MediaServerClient {}

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  void emit(PlaybackState next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('mediaItemFor artwork', () {
    late _MockMediaServerClient client;
    late ImageService images;

    const coverlessSong = LibraryItem(
      id: 'song-9',
      name: 'Untagged',
      kind: ItemKind.song,
      albumId: 'album-9',
    );

    const playlist = LibraryItem(
      id: 'playlist-1',
      name: 'Road trip',
      kind: ItemKind.playlist,
      images: ImageRefs(primary: 'playlist-tag'),
    );

    const ownAlbum = LibraryItem(
      id: 'album-9',
      name: 'Untagged album',
      kind: ItemKind.album,
      images: ImageRefs(primary: 'album-tag'),
    );

    final albumCover = Uri.parse('http://server.local/Items/album-9/Primary');

    setUpAll(() {
      registerFallbackValue(coverlessSong);
      registerFallbackValue(ImageKind.primary);
    });

    setUp(() {
      client = _MockMediaServerClient();
      images = ImageService(client: () => client);
      when(
        () => client.imageUri(
          any(),
          kind: any(named: 'kind'),
          size: any(named: 'size'),
        ),
      ).thenReturn(albumCover);
    });

    test('- leaves a coverless song without artwork in a playlist', () {
      final item = mediaItemFor(coverlessSong, album: playlist, images: images);

      expect(item.artUri, isNull);
    });

    test('- falls back to the cover of the song own album', () {
      final item = mediaItemFor(
        coverlessSong,
        album: ownAlbum,
        images: images,
      );

      expect(item.artUri, albumCover);
    });
  });

  LibraryItem songNamed(
    String id,
    String name, {
    String? artist,
    Duration duration = const Duration(minutes: 3),
  }) => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.song,
    albumArtist: artist,
    albumName: 'Dummy',
    duration: duration,
  );

  final album = LibraryItem(
    id: 'album-1',
    name: 'Dummy',
    kind: ItemKind.album,
    albumArtist: 'Portishead',
  );

  late _StubPlayback playback;
  late ProviderContainer container;

  setUp(() {
    playback = _StubPlayback();
    container = ProviderContainer(
      overrides: [playbackProvider.overrideWith((ref) => playback)],
    );
    addTearDown(container.dispose);
  });

  PlaybackState playing(int index) => PlaybackState(
    album: album,
    songs: [
      songNamed('song-1', 'Sour Times', artist: 'Portishead'),
      songNamed('song-2', 'Roads', artist: 'Portishead'),
    ],
    status: PlaybackStatus.playing,
    position: Duration.zero,
    cacheProgress: Duration.zero,
    currentMediaIndex: index,
  );

  test('- reports nothing while there is no queue', () {
    expect(container.read(nowPlayingProvider), isNull);
    expect(container.read(nowPlayingQueueProvider), isEmpty);
    expect(container.read(hasQueueProvider), isFalse);
  });

  test('- follows the queue without any help from the local player', () {
    playback.emit(playing(0));

    expect(container.read(hasQueueProvider), isTrue);
    expect(container.read(nowPlayingProvider)!.title, 'Sour Times');
    expect(container.read(nowPlayingProvider)!.id, 'song-1');
    expect(container.read(nowPlayingQueueProvider), hasLength(2));

    playback.emit(playing(1));

    expect(container.read(nowPlayingProvider)!.title, 'Roads');
    expect(container.read(nowPlayingProvider)!.id, 'song-2');
  });

  test('- carries the tag fields the player chrome reads', () {
    playback.emit(playing(0));
    final item = container.read(nowPlayingProvider)!;

    expect(item.artist, 'Portishead');
    expect(item.album, 'Dummy');
    expect(item.duration, const Duration(minutes: 3));
  });

  test('- reports nothing for an index outside the queue', () {
    playback.emit(playing(0).copyWith(currentMediaIndex: 9));
    expect(container.read(nowPlayingProvider), isNull);

    playback.emit(playing(0).copyWith(currentMediaIndex: -1));
    expect(container.read(nowPlayingProvider), isNull);

    playback.emit(playing(0).copyWith(currentMediaIndex: null));
    expect(container.read(nowPlayingProvider), isNull);
  });

  test('- falls back to the album for artist and name', () {
    playback.emit(
      playing(0).copyWith(songs: [songNamed('song-1', 'Untitled')]),
    );

    final item = container.read(nowPlayingProvider)!;
    expect(item.artist, 'Portishead');
  });
}
