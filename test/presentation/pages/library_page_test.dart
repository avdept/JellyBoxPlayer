import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart' hide LibraryPage;
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/presentation/pages/library_page.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockLibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>>
    with Mock
    implements LibrariesNotifier {}

class MockAuthNotifier extends AsyncNotifier<bool?>
    with Mock
    implements AuthNotifier {}

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

class FakeLibraryItem extends Fake implements LibraryItem {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibrariesNotifier mockLibrariesNotifier;
  late AuthNotifier mockAuthNotifier;
  late CurrentLibraryNotifier mockCurrentLibraryNotifier;

  final faker = Faker.instance;

  LibraryItem buildLibrary() => LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    path: faker.internet.url(),
    kind: ItemKind.library,
    collectionType: 'music',
  );

  final mockLibraries = [buildLibrary(), buildLibrary()];

  List<Override> overrides() => [
    librariesProvider.overrideWith(() => mockLibrariesNotifier),
    authProvider.overrideWith(() => mockAuthNotifier),
    currentLibraryProvider.overrideWith(() => mockCurrentLibraryNotifier),
  ];

  Widget getWidgetUT() => createTestApp(
    providerContainer: createProviderContainer(overrides: overrides()),
    home: const LibraryPage(),
  );

  Widget getRoutedWidgetUT() => UncontrolledProviderScope(
    container: createProviderContainer(overrides: overrides()),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: Themes.red,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LibraryPage(),
          ),
          GoRoute(
            path: Routes.browse.path,
            name: Routes.browse.name,
            builder: (context, state) =>
                const Scaffold(body: Text('browse page')),
          ),
        ],
      ),
    ),
  );

  setUpAll(() {
    deviceId = faker.datatype.uuid();
    registerFallbackValue(FakeLibraryItem());
  });

  setUp(() {
    mockLibrariesNotifier = MockLibrariesNotifier();
    mockAuthNotifier = MockAuthNotifier();
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier();
    when(mockLibrariesNotifier.build).thenAnswer((_) async => mockLibraries);
    when(mockAuthNotifier.build).thenAnswer((_) async => true);
    when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});
    when(mockCurrentLibraryNotifier.build).thenAnswer((_) async => null);
    when(
      () => mockCurrentLibraryNotifier.setLibrary(any()),
    ).thenAnswer((_) async {});
  });

  group('LibraryPage', () {
    testWidgets(
      '- displays list of libraries',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final libraryFinder = find.byType(LibraryView);
        expect(libraryFinder, findsNWidgets(mockLibraries.length));
        for (final library in mockLibraries) {
          expect(
            find.descendant(
              of: libraryFinder,
              matching: find.text(library.name),
            ),
            findsOneWidget,
          );
        }
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

    testWidgets(
      '- auto selects the library when there is only one',
      (widgetTester) async {
        final onlyLibrary = buildLibrary();
        when(mockLibrariesNotifier.build).thenAnswer(
          (_) async => [
            onlyLibrary,
          ],
        );

        await widgetTester.pumpWidget(getRoutedWidgetUT());
        await widgetTester.pumpAndSettle();

        verify(
          () => mockCurrentLibraryNotifier.setLibrary(onlyLibrary),
        ).called(1);
        expect(find.byType(LibraryView), findsNothing);
        expect(find.text('Select Library'), findsNothing);
        expect(find.text('browse page'), findsOneWidget);
      },
    );

    testWidgets(
      '- keeps the picker when there is more than one library',
      (widgetTester) async {
        await widgetTester.pumpWidget(getRoutedWidgetUT());
        await widgetTester.pumpAndSettle();

        verifyNever(() => mockCurrentLibraryNotifier.setLibrary(any()));
        expect(find.text('Select Library'), findsOneWidget);
        expect(find.text('browse page'), findsNothing);
      },
    );

    testWidgets(
      '- shows a message when there are no libraries',
      (widgetTester) async {
        when(mockLibrariesNotifier.build).thenAnswer((_) async => []);

        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);

        expect(find.text('No libraries found :('), findsOneWidget);
        expect(find.byType(LibraryView), findsNothing);
        expect(find.text('Logout'), findsOneWidget);
      },
    );
  });
}
