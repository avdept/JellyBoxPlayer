import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/genre_albums_provider.dart';
import 'package:jplayer/src/presentation/pages/genre_albums_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockGenreAlbumsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, String>
    with Mock
    implements GenreAlbumsNotifier {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GenreAlbumsNotifier mockGenreAlbumsNotifier;
  late User mockUser;

  final faker = Faker.instance;
  final mockGenre = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.word(),
    type: 'MusicGenre',
    runTimeTicks: faker.datatype.number(min: 10000),
  );
  final mockAlbums = ItemsPage(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        type: 'MusicAlbum',
        runTimeTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );

  Widget getWidgetUT({required ItemDTO genre}) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        genreAlbumsProvider.overrideWith(() => mockGenreAlbumsNotifier),
        currentUserProvider.overrideWith((_) => mockUser),
      ],
    ),
    home: GenreAlbumsPage(genre: genre),
  );

  setUp(() {
    mockGenreAlbumsNotifier = MockGenreAlbumsNotifier();
    mockUser = MockUser();
    when(() => mockGenreAlbumsNotifier.loadMore()).thenAnswer((_) async {});
    when(
      () => mockGenreAlbumsNotifier.build(mockGenre.id),
    ).thenAnswer((_) async => mockAlbums);
    when(() => mockUser.userId).thenReturn(faker.datatype.uuid());
  });

  group('GenreAlbumsPage', () {
    testWidgets(
      '- displays the genre name in the header',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(genre: mockGenre));
        await widgetTester.pump(Duration.zero);
        expect(find.text(mockGenre.name), findsOneWidget);
      },
    );

    testWidgets(
      '- displays the albums for the genre',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(genre: mockGenre));
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
  });
}
