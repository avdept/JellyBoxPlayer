import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/albums_provider.dart';
import 'package:jplayer/src/domain/providers/artists_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playlists_provider.dart';
import 'package:jplayer/src/presentation/pages/listen_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockAlbumsNotifier extends StateNotifier<AsyncData<ItemsPage>>
    with Mock
    implements AlbumsNotifier {
  MockAlbumsNotifier(super.state);
}

class MockArtistsNotifier extends StateNotifier<AsyncData<ItemsPage>>
    with Mock
    implements ArtistsNotifier {
  MockArtistsNotifier(super.state);
}

class MockPlaylistsNotifier extends StateNotifier<AsyncData<ItemsPage>>
    with Mock
    implements PlaylistsNotifier {
  MockPlaylistsNotifier(super.state);
}

class MockCurrentLibraryNotifier extends StateNotifier<ItemDTO?>
    with Mock
    implements CurrentLibraryNotifier {
  MockCurrentLibraryNotifier(super.state);
}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AlbumsNotifier mockAlbumsNotifier;
  late ArtistsNotifier mockArtistsNotifier;
  late PlaylistsNotifier mockPlaylistsNotifier;
  late CurrentLibraryNotifier mockCurrentLibraryNotifier;
  late User mockUser;

  final faker = Faker.instance;
  final mockAlbums = ItemsPage(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        type: 'Album',
        runTimeTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockArtists = ItemsPage(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        type: 'Artist',
        runTimeTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockPlaylists = ItemsPage(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        type: 'Playlist',
        runTimeTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockLibrary = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    path: faker.internet.url(),
    type: 'CollectionFolder',
    collectionType: 'music',
  );

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        albumsProvider.overrideWith((_) => mockAlbumsNotifier),
        artistsProvider.overrideWith((_) => mockArtistsNotifier),
        playlistsProvider.overrideWith((_) => mockPlaylistsNotifier),
        currentLibraryProvider.overrideWith((_) => mockCurrentLibraryNotifier),
        currentUserProvider.overrideWith((_) => mockUser),
      ],
    ),
    home: const ListenPage(),
  );

  setUp(() {
    mockAlbumsNotifier = MockAlbumsNotifier(AsyncData(mockAlbums));
    mockArtistsNotifier = MockArtistsNotifier(AsyncData(mockArtists));
    mockPlaylistsNotifier = MockPlaylistsNotifier(AsyncData(mockPlaylists));
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier(mockLibrary);
    mockUser = MockUser();
    when(() => mockAlbumsNotifier.loadMore()).thenAnswer((_) async {});
    when(() => mockArtistsNotifier.loadMore()).thenAnswer((_) async {});
    when(() => mockPlaylistsNotifier.loadMore()).thenAnswer((_) async {});
    when(() => mockUser.userId).thenReturn(faker.datatype.uuid());
  });

  group('ListenPage', () {
    testWidgets(
      '- displays list of albums',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final albumUT = mockAlbums.items.first;
        final albumFinder = find.byType(AlbumView);
        expect(albumFinder, findsWidgets);
        expect(
          find.descendant(of: albumFinder, matching: find.text(albumUT.name)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays view toggles',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        const views = {'Albums', 'Artists', 'Playlists'};
        final chipFinder = find.byType(ActionChip);
        expect(chipFinder, findsNWidgets(views.length));
        for (final label in views) {
          expect(
            find.descendant(of: chipFinder, matching: find.text(label)),
            findsOneWidget,
          );
        }
      },
    );
  });
}
