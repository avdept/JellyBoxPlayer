import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/jellybox_cloud.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class FakeCloudNotifier extends StateNotifier<CloudState>
    with Mock
    implements CloudNotifier {
  FakeCloudNotifier() : super(const CloudState());

  final sent = <(PlayerCommand, Object?)>[];

  @override
  Future<void> sendCommand(PlayerCommand command, {Object? value}) async =>
      sent.add((command, value));
}

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier([PlaybackState? state])
    : super(state ?? PlaybackState.initial());

  final updated = <LibraryItem>[];

  @override
  void updateSong(LibraryItem song) => updated.add(song);
}

LibraryItem _song(String id) =>
    LibraryItem(id: id, name: id, kind: ItemKind.song);

RemoteSession _remote(SessionDoc doc) =>
    RemoteSession(doc: doc, ageMs: 0, receivedAt: DateTime.now());

const _phone = ConductorDevice(
  id: 'phone',
  name: 'Phone',
  platform: 'android',
  isRenderer: true,
);

void main() {
  late MockMediaServerClient client;
  late FakeCloudNotifier cloud;
  late FakePlaybackNotifier playback;

  setUp(() {
    client = MockMediaServerClient();
    cloud = FakeCloudNotifier();
    playback = FakePlaybackNotifier();
  });

  ProviderContainer containerWith(SessionDoc doc) => createProviderContainer(
    overrides: [
      mediaServerClientProvider.overrideWithValue(client),
      cloudProvider.overrideWith((_) => cloud),
      playbackProvider.overrideWith((_) => playback),
      remoteSessionProvider.overrideWithValue(_remote(doc)),
      remoteRendererProvider.overrideWithValue(_phone),
    ],
  );

  test('the remote queue keeps every track at its position', () async {
    when(
      () => client.getItemsByIds(['b', 'a', 'c']),
    ).thenAnswer((_) async => [_song('a'), _song('b')]);
    final container = containerWith(
      const SessionDoc(itemIds: ['b', 'a', 'c'], queuePosition: 1),
    );

    final queue = await container.read(remoteQueueProvider.future);

    expect([for (final song in queue) song.id], ['b', 'a', 'c']);
    expect(queue.last.name, 'Unavailable track');
    expect(container.read(remoteNowPlayingProvider)?.id, 'a');
  });

  test('local progress carries what the player has buffered', () {
    final container = createProviderContainer(
      overrides: [
        cloudProvider.overrideWith((_) => cloud),
        remoteRendererProvider.overrideWithValue(null),
        playbackProvider.overrideWith(
          (_) => FakePlaybackNotifier(
            PlaybackState.initial().copyWith(
              status: PlaybackStatus.playing,
              position: const Duration(seconds: 10),
              cacheProgress: const Duration(seconds: 45),
              totalDuration: const Duration(minutes: 3),
            ),
          ),
        ),
      ],
    );

    final progress = container.read(barProgressProvider);

    expect(progress.position, const Duration(seconds: 10));
    expect(progress.buffered, const Duration(seconds: 45));
  });

  group('toggleFavourite', () {
    ProviderContainer localWith({required bool offline}) =>
        createProviderContainer(
          overrides: [
            mediaServerClientProvider.overrideWithValue(client),
            cloudProvider.overrideWith((_) => cloud),
            playbackProvider.overrideWith((_) => playback),
            remoteRendererProvider.overrideWithValue(null),
            isOfflineProvider.overrideWithValue(offline),
          ],
        );

    test('saves the like and marks the track', () async {
      when(
        () => client.setFavorite('a', favorite: true),
      ).thenAnswer((_) async {});
      final container = localWith(offline: false);

      final saved = await container
          .read(barControlsProvider)
          .toggleFavourite(_song('a'));

      expect(saved, isTrue);
      verify(() => client.setFavorite('a', favorite: true)).called(1);
      expect(playback.updated.single.userData.isFavorite, isTrue);
    });

    test('reports failure without calling the server when offline', () async {
      final container = localWith(offline: true);

      final saved = await container
          .read(barControlsProvider)
          .toggleFavourite(_song('a'));

      expect(saved, isFalse);
      verifyNever(
        () => client.setFavorite(any(), favorite: any(named: 'favorite')),
      );
      expect(playback.updated, isEmpty);
    });

    test('reports failure when the server refuses', () async {
      when(
        () => client.setFavorite('a', favorite: true),
      ).thenThrow(Exception('offline'));
      final container = localWith(offline: false);

      final saved = await container
          .read(barControlsProvider)
          .toggleFavourite(_song('a'));

      expect(saved, isFalse);
      expect(playback.updated, isEmpty);
    });
  });

  test('the remote repeat mode is read from the session', () {
    final container = containerWith(
      const SessionDoc(itemIds: ['a'], repeat: 'one'),
    );

    expect(container.read(barRepeatProvider), LoopMode.one);
  });

  test('controls go to the playing device, not the local player', () async {
    when(() => client.getItemsByIds(any())).thenAnswer((_) async => []);
    final container = containerWith(
      const SessionDoc(itemIds: ['a', 'b'], playing: true),
    );
    final controls = container.read(barControlsProvider);

    await controls.togglePlay();
    await controls.seek(const Duration(seconds: 42));
    await controls.setShuffle(enabled: true);
    await controls.setRepeat(LoopMode.all);
    await controls.skipTo(1);

    expect(cloud.sent, [
      (PlayerCommand.pause, null),
      (PlayerCommand.seek, 42000),
      (PlayerCommand.shuffle, true),
      (PlayerCommand.repeat, 'all'),
      (PlayerCommand.skipTo, 1),
    ]);
    verifyZeroInteractions(playback);
  });
}
