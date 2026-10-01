import 'dart:async';

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
    Future<void> Function()? onRefresh,
    Widget? trailing,
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
          onRefresh: onRefresh,
          trailing: trailing,
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

    testWidgets('- shows a trailing action beside the title', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        getWidgetUT(
          items: AsyncData(createAlbums(2)),
          trailing: const Icon(Icons.refresh),
        ),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.text(title), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets(
      '- keeps a trailing action reachable when the section is empty',
      (
        widgetTester,
      ) async {
        await widgetTester.pumpWidget(
          getWidgetUT(
            items: const AsyncData(<LibraryItem>[]),
            trailing: const Icon(Icons.refresh),
          ),
        );
        await widgetTester.pump(Duration.zero);

        expect(find.text(title), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(AlbumView), findsNothing);
      },
    );

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
          matching: find.byType(AlbumCardsRowShimmer),
        ),
        findsOneWidget,
      );
      expect(find.byType(AlbumCardShimmer), findsWidgets);
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

    const platforms = TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    });

    testWidgets(
      '- refreshes when pulled past the start of the row',
      variant: platforms,
      (widgetTester) async {
        var refreshes = 0;
        await widgetTester.pumpWidget(
          getWidgetUT(
            items: AsyncData(createAlbums(6)),
            onRefresh: () async => refreshes++,
          ),
        );
        await widgetTester.pump(Duration.zero);

        await widgetTester.drag(
          find.byType(AlbumView).first,
          const Offset(400, 0),
        );
        await widgetTester.pumpAndSettle();

        expect(refreshes, 1);
      },
    );

    testWidgets(
      '- does not refresh on a short pull',
      variant: platforms,
      (widgetTester) async {
        var refreshes = 0;
        await widgetTester.pumpWidget(
          getWidgetUT(
            items: AsyncData(createAlbums(6)),
            onRefresh: () async => refreshes++,
          ),
        );
        await widgetTester.pump(Duration.zero);

        await widgetTester.drag(
          find.byType(AlbumView).first,
          const Offset(30, 0),
        );
        await widgetTester.pumpAndSettle();

        expect(refreshes, 0);
      },
    );

    testWidgets(
      '- does not refresh when scrolling through the row',
      variant: platforms,
      (widgetTester) async {
        var refreshes = 0;
        await widgetTester.pumpWidget(
          getWidgetUT(
            items: AsyncData(createAlbums(6)),
            onRefresh: () async => refreshes++,
          ),
        );
        await widgetTester.pump(Duration.zero);

        await widgetTester.drag(
          find.byType(AlbumView).first,
          const Offset(-300, 0),
        );
        await widgetTester.pumpAndSettle();
        await widgetTester.drag(
          find.byType(AlbumView).last,
          const Offset(150, 0),
        );
        await widgetTester.pumpAndSettle();

        expect(refreshes, 0);
      },
    );

    testWidgets('- ignores pulls while a refresh is running', (
      widgetTester,
    ) async {
      var refreshes = 0;
      final pending = Completer<void>();
      await widgetTester.pumpWidget(
        getWidgetUT(
          items: AsyncData(createAlbums(6)),
          onRefresh: () {
            refreshes++;
            return pending.future;
          },
        ),
      );
      await widgetTester.pump(Duration.zero);

      for (var i = 0; i < 2; i++) {
        await widgetTester.drag(
          find.byType(AlbumView).first,
          const Offset(400, 0),
        );
        await widgetTester.pump(const Duration(seconds: 1));
      }
      expect(refreshes, 1);

      pending.complete();
      await widgetTester.pumpAndSettle();
    });
  });
}
