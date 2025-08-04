import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/item_list_providers.dart';
import 'package:jplayer/src/presentation/pages/listen_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockItemListNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, ItemList>
    with Mock
    implements ItemListNotifier {}

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<ItemDTO?>
    with Mock
    implements CurrentLibraryNotifier {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ItemListNotifier mockItemListNotifier;
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
        itemListProvider.overrideWith(() => mockItemListNotifier),
        currentLibraryProvider.overrideWith(() => mockCurrentLibraryNotifier),
        currentUserProvider.overrideWith((_) => mockUser),
      ],
    ),
    home: const ListenPage(),
  );

  setUp(() {
    mockItemListNotifier = MockItemListNotifier();
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier();
    mockUser = MockUser();
    when(() => mockItemListNotifier.loadMore()).thenAnswer((_) async {});
    when(() => mockUser.userId).thenReturn(faker.datatype.uuid());
    when(
      () => mockItemListNotifier.build(ItemList.albums),
    ).thenAnswer((_) async => mockAlbums);
    when(
      () => mockItemListNotifier.build(ItemList.artists),
    ).thenAnswer((_) async => mockArtists);
    when(
      () => mockItemListNotifier.build(ItemList.playlists),
    ).thenAnswer((_) async => mockPlaylists);
    when(mockCurrentLibraryNotifier.build).thenAnswer((_) async => mockLibrary);
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
