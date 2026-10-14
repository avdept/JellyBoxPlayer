import 'dart:async';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final faker = Faker.instance;
  final mockAlbum = DownloadedAlbum(
    item: LibraryItem(
      id: faker.datatype.uuid(),
      name: faker.lorem.sentence(),
      kind: ItemKind.album,
    ),
    sizeInBytes: faker.datatype.number(),
    downloadDate: DateTime.now(),
  );
  const keys = DownloadedAlbumViewKeys(
    deleteButton: Key('deleteButton'),
    confirmationDialog: Key('confirmationDialog'),
  );

  Widget getWidgetUT({
    required DownloadedAlbum album,
    FutureOr<void> Function(DownloadedAlbum)? onDelete,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 246,
            child: DownloadedAlbumView(
              album: album,
              onDelete: onDelete,
              testKeys: keys,
            ),
          ),
        ),
      ),
    );
  }

  group('DownloadedAlbumView', () {
    testWidgets(
      '- displays album details',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pump(Duration.zero);
        expect(find.text(mockAlbum.item.name), findsOneWidget);
      },
    );

    testWidgets(
      '- displays delete button',
      (widgetTester) async {
        var deleteCounter = 0;
        await widgetTester.pumpWidget(
          getWidgetUT(
            album: mockAlbum,
            onDelete: (album) {
              if (album.item.id == mockAlbum.item.id) deleteCounter++;
            },
          ),
        );
        await widgetTester.pump(Duration.zero);
        final deleteButtonFinder = find.byKey(keys.deleteButton);
        expect(deleteButtonFinder, findsOneWidget);
        // Should show confirmation dialog
        await widgetTester.tap(deleteButtonFinder);
        await widgetTester.pumpAndSettle();
        final confirmationDialogFinder = find.byKey(keys.confirmationDialog);
        expect(confirmationDialogFinder, findsOneWidget);
        // Should call onDelete when accepted
        await widgetTester.tap(
          find.descendant(
            of: confirmationDialogFinder,
            matching: find.widgetWithText(AdaptiveDialogAction, 'Yes'),
          ),
        );
        await widgetTester.pumpAndSettle();
        expect(deleteCounter, equals(1));
      },
    );

    testWidgets(
      '- confirms the removal with a message',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(album: mockAlbum, onDelete: (_) {}),
        );
        await widgetTester.pump(Duration.zero);
        await widgetTester.tap(find.byKey(keys.deleteButton));
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(
          find.widgetWithText(AdaptiveDialogAction, 'Yes'),
        );
        await widgetTester.pumpAndSettle();

        expect(
          find.text('Removed "${mockAlbum.item.name}" from downloads'),
          findsOneWidget,
        );
      },
    );
  });
}
