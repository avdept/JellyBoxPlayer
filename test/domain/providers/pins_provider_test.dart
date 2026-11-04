import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/pins_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime.utc(2026, 11, 3);
  late MediaServerClient client;
  final containers = <ProviderContainer>[];

  const album = LibraryItem(
    id: 'album-1',
    name: 'Album',
    kind: ItemKind.album,
    images: ImageRefs(primary: 'tag'),
  );
  const artist = LibraryItem(
    id: 'artist-1',
    name: 'Artist',
    kind: ItemKind.artist,
  );

  ProviderContainer newContainer({String? userId = 'user-1'}) {
    final container = ProviderContainer(
      overrides: [
        pinsProvider.overrideWith(
          (ref) => PinsNotifier(
            ref,
            ref.watch(pinsDatabaseProvider),
            maxAge: ref.watch(pinLongevityProvider).maxAge,
            now: () => now,
          ),
        ),
        currentServerIdProvider.overrideWith((_) => 'server-1'),
        mediaServerClientProvider.overrideWith((_) => client),
        if (userId != null)
          currentUserProvider.overrideWith(
            (_) => User(userId: userId, token: 'token'),
          ),
      ],
    );
    containers.add(container);
    return container;
  }

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('pins_provider_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(album);
    registerFallbackValue(ImageKind.primary);
  });

  setUp(() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    client = _MockMediaServerClient();
    when(
      () => client.imageUri(
        any(),
        kind: any(named: 'kind'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (invocation) => Uri.parse(
        'http://server/Items/'
        '${(invocation.positionalArguments.first as LibraryItem).id}/Primary',
      ),
    );
  });

  tearDown(() {
    for (final container in containers) {
      container.dispose();
    }
    containers.clear();
  });

  test('- toggle pins, unpins and survives a restart', () async {
    final container = newContainer();
    final notifier = container.read(pinsProvider.notifier);
    await notifier.restored;

    await notifier.toggle(album);
    await notifier.toggle(artist);

    expect(
      container.read(pinsProvider).map((p) => p.itemId),
      ['artist-1', 'album-1'],
    );
    expect(container.read(isPinnedProvider('album-1')), isTrue);
    expect(
      container.read(pinsProvider).last.imageUrl,
      Uri.parse('http://server/Items/album-1/Primary'),
    );
    expect(container.read(pinsProvider).first.imageUrl, isNull);

    await notifier.toggle(album);
    expect(container.read(isPinnedProvider('album-1')), isFalse);

    final restarted = newContainer();
    final restartedNotifier = restarted.read(pinsProvider.notifier);
    await restartedNotifier.restored;

    expect(
      restarted.read(pinsProvider).map((p) => p.itemId),
      ['artist-1'],
    );
    expect(restarted.read(pinsProvider).single.pinnedAt, now);
  });

  test('- pins belong to the signed-in user', () async {
    final mine = newContainer();
    await mine.read(pinsProvider.notifier).restored;
    await mine.read(pinsProvider.notifier).pin(album);

    final theirs = newContainer(userId: 'user-2');
    await theirs.read(pinsProvider.notifier).restored;

    expect(theirs.read(pinsProvider), isEmpty);
  });

  test('- refuses ephemeral playlists, genres and radio streams', () async {
    final container = newContainer();
    final notifier = container.read(pinsProvider.notifier);
    await notifier.restored;

    const liked = LibraryItem(
      id: 'jellybox:liked-songs:user-1',
      name: 'Liked songs',
      kind: ItemKind.playlist,
    );
    const genre = LibraryItem(id: 'rock', name: 'Rock', kind: ItemKind.genre);
    const radio = LibraryItem(
      id: 'radio-1',
      name: 'Radio',
      kind: ItemKind.song,
      path: 'https://stream.example/live',
    );
    const playlist = LibraryItem(
      id: 'playlist-1',
      name: 'Mix',
      kind: ItemKind.playlist,
    );

    expect(PinsNotifier.canPin(liked), isFalse);
    expect(PinsNotifier.canPin(genre), isFalse);
    expect(PinsNotifier.canPin(radio), isFalse);
    expect(PinsNotifier.canPin(playlist), isTrue);

    await notifier.pin(liked);
    await notifier.pin(genre);
    await notifier.pin(radio);
    await notifier.pin(playlist);

    expect(container.read(pinsProvider).map((p) => p.itemId), ['playlist-1']);
  });
}
