import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

const _playlist = LibraryItem(
  id: 'p1',
  name: 'Road Trip',
  kind: ItemKind.playlist,
);

void main() {
  late MockMediaServerClient client;

  setUpAll(() => registerFallbackValue(const LibraryQuery()));

  setUp(() {
    client = MockMediaServerClient();
    when(() => client.getPlaylists(any())).thenAnswer(
      (_) async => const LibraryPage(items: [_playlist], totalRecordCount: 1),
    );
  });

  ProviderContainer containerWith(
    MediaServerCapabilities capabilities, {
    List<Override> overrides = const [],
  }) {
    when(() => client.capabilities).thenReturn(capabilities);
    return createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWithValue(client),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 't'),
        ),
        isOfflineProvider.overrideWithValue(false),
        ...overrides,
      ],
    );
  }

  group('favouritePlaylistsProvider', () {
    test('- asks the server for favourite playlists only', () async {
      final container = containerWith(const MediaServerCapabilities());

      final playlists = await container.read(
        favouritePlaylistsProvider.future,
      );

      expect(playlists, [_playlist]);
      final query =
          verify(() => client.getPlaylists(captureAny())).captured.single
              as LibraryQuery;
      expect(query.filters, {ItemFilterFlag.favorite});
    });

    test(
      '- skips the server when it cannot list favourite playlists',
      () async {
        final container = containerWith(
          const MediaServerCapabilities(playlistFavourites: false),
        );

        final playlists = await container.read(
          favouritePlaylistsProvider.future,
        );

        expect(playlists, isEmpty);
        verifyNever(() => client.getPlaylists(any()));
      },
    );
  });

  group('homeFavouritesProvider', () {
    test('- lists favourite playlists ahead of favourite albums', () async {
      const album = LibraryItem(id: 'a1', name: 'Album', kind: ItemKind.album);
      final container = containerWith(
        const MediaServerCapabilities(),
        overrides: [
          favouriteAlbumsProvider.overrideWith((_) async => const [album]),
        ],
      );

      final items = await container.read(homeFavouritesProvider.future);

      expect(items, [_playlist, album]);
    });
  });
}
