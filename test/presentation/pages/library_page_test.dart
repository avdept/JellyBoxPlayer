import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/presentation/pages/library_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockLibrariesNotifier extends AutoDisposeAsyncNotifier<List<ItemDTO>>
    with Mock
    implements LibrariesNotifier {}

class MockAuthNotifier extends AsyncNotifier<bool?>
    with Mock
    implements AuthNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibrariesNotifier mockLibrariesNotifier;
  late AuthNotifier mockAuthNotifier;

  final faker = Faker.instance;
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
        librariesProvider.overrideWith(() => mockLibrariesNotifier),
        authProvider.overrideWith(() => mockAuthNotifier),
      ],
    ),
    home: const LibraryPage(),
  );

  setUpAll(() {
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockLibrariesNotifier = MockLibrariesNotifier();
    mockAuthNotifier = MockAuthNotifier();
    when(mockLibrariesNotifier.build).thenAnswer((_) async => [mockLibrary]);
    when(mockAuthNotifier.build).thenAnswer((_) async => true);
    when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});
  });

  group('LibraryPage', () {
    testWidgets(
      '- displays list of libraries',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final libraryFinder = find.byType(LibraryView);
        expect(libraryFinder, findsOneWidget);
        expect(
          find.descendant(
            of: libraryFinder,
            matching: find.text(mockLibrary.name),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- has a logout button',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final buttonFinder = find.text('Logout');
        expect(buttonFinder, findsOneWidget);
        await widgetTester.tap(buttonFinder);
        await widgetTester.pumpAndSettle();
        verify(mockAuthNotifier.logout).called(1);
      },
    );
  });
}
