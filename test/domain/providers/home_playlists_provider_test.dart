import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient client;
  late AppSettingsNotifier settings;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const LibraryQuery()));

  setUp(() {
    client = MockMediaServerClient();
    when(
      () => client.getPlaylists(any()),
    ).thenAnswer((_) async => const LibraryPage());
    settings = AppSettingsNotifier(null);
    container = createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWithValue(client),
        appSettingsProvider.overrideWith((_) => settings),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 't'),
        ),
        isOfflineProvider.overrideWithValue(false),
      ],
    );
  });

  Future<LibraryQuery> queryFor(Filter filter) async {
    settings.setHomePlaylistSort(filter);
    await container.read(homePlaylistsProvider.future);
    return verify(() => client.getPlaylists(captureAny())).captured.last
        as LibraryQuery;
  }

  group('homePlaylistsProvider', () {
    test('- asks for the most recently updated playlists by default', () async {
      await container.read(homePlaylistsProvider.future);

      final query =
          verify(() => client.getPlaylists(captureAny())).captured.single
              as LibraryQuery;
      expect(query.sort, ItemSort.dateLastContentAdded);
      expect(query.direction, SortDirection.descending);
    });

    test('- sorts by name ascending when the user picks Name', () async {
      final query = await queryFor(
        const Filter(orderBy: EntityFilter.sortName),
      );

      expect(query.sort, ItemSort.name);
      expect(query.direction, SortDirection.ascending);
    });

    test('- sorts newest first when the user picks Date Added', () async {
      final query = await queryFor(
        const Filter(orderBy: EntityFilter.dateCreated, desc: true),
      );

      expect(query.sort, ItemSort.dateCreated);
      expect(query.direction, SortDirection.descending);
    });

    test('- reverses the direction when the same field is chosen', () async {
      final query = await queryFor(
        const Filter(
          orderBy: EntityFilter.sortName,
        ).select(EntityFilter.sortName),
      );

      expect(query.sort, ItemSort.name);
      expect(query.direction, SortDirection.descending);
    });
  });
}
