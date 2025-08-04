import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/presentation/pages/library_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockCurrentLibraryNotifier extends StateNotifier<LibraryDTO?>
    with Mock
    implements CurrentLibraryNotifier {
  MockCurrentLibraryNotifier(super.state);
}

class MockAuthNotifier extends StateNotifier<AsyncValue<bool?>>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier(super.state);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentLibraryNotifier mockCurrentLibraryNotifier;
  late AuthNotifier mockAuthNotifier;

  final faker = Faker.instance;
  final mockLibrary = LibraryDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    path: faker.internet.url(),
    type: 'CollectionFolder',
    collectionType: 'music',
  );

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        currentLibraryProvider.overrideWith((_) => mockCurrentLibraryNotifier),
        authProvider.overrideWith((_) => mockAuthNotifier),
      ],
    ),
    home: const LibraryPage(),
  );

  setUpAll(() {
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier(null);
    mockAuthNotifier = MockAuthNotifier(const AsyncData(true));
    when(
      () => mockCurrentLibraryNotifier.fetchLibraries(),
    ).thenAnswer((_) async => [mockLibrary]);
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
            matching: find.text(mockLibrary.name ?? 'Untitled'),
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
