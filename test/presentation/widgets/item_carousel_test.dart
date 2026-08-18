import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const title = 'Recently played';
  final faker = Faker.instance;

  List<LibraryItem> createAlbums(int count) => List.generate(
    count,
    (_) => LibraryItem(
      id: faker.datatype.uuid(),
      name: faker.lorem.sentence(),
      kind: ItemKind.album,
      albumArtist: faker.name.fullName(),
    ),
  );

  Widget getWidgetUT({
    required AsyncValue<List<LibraryItem>> items,
    void Function(LibraryItem)? onItemTap,
    VoidCallback? onRetry,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(),
      home: Scaffold(
        body: ItemCarousel(
          title: title,
          items: items,
          device: DeviceType.fromScreenSize(const Size(390, 844)),
          onItemTap: onItemTap ?? (_) {},
          onRetry: onRetry,
        ),
      ),
    );
  }

  group('ItemCarousel', () {
    testWidgets('- shows the title and a card per item when there is content', (
      widgetTester,
    ) async {
      final albums = createAlbums(3);
      await widgetTester.pumpWidget(
        getWidgetUT(items: AsyncData(albums)),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.text(title), findsOneWidget);
      expect(find.byType(AlbumView), findsNWidgets(3));
      expect(find.text(albums.first.name), findsOneWidget);
    });

    testWidgets('- renders nothing at all when the section has no items', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        getWidgetUT(items: const AsyncData(<LibraryItem>[])),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.text(title), findsNothing);
      expect(find.byType(AlbumView), findsNothing);
    });

    testWidgets('- takes up no vertical space when the section is empty', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        getWidgetUT(items: const AsyncData(<LibraryItem>[])),
      );
      await widgetTester.pump(Duration.zero);

      expect(
        widgetTester.getSize(find.byType(ItemCarousel)),
        Size.zero,
      );
    });

    testWidgets('- shows the placeholder skeleton while loading', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        getWidgetUT(items: const AsyncLoading()),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.text(title), findsOneWidget);
      expect(find.byType(AlbumView), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ItemCarousel),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('- offers a retry when the section failed to load', (
      widgetTester,
    ) async {
      var retries = 0;
      await widgetTester.pumpWidget(
        getWidgetUT(
          items: AsyncError(Exception('boom'), StackTrace.empty),
          onRetry: () => retries++,
        ),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.text(title), findsOneWidget);
      expect(find.byType(AlbumView), findsNothing);

      await widgetTester.tap(find.widgetWithText(TextButton, 'Retry'));
      expect(retries, 1);
    });

    testWidgets('- reports the tapped item', (widgetTester) async {
      final albums = createAlbums(2);
      LibraryItem? tapped;
      await widgetTester.pumpWidget(
        getWidgetUT(
          items: AsyncData(albums),
          onItemTap: (item) => tapped = item,
        ),
      );
      await widgetTester.pump(Duration.zero);

      await widgetTester.tap(find.text(albums.first.name));
      expect(tapped?.id, albums.first.id);
    });
  });
}
