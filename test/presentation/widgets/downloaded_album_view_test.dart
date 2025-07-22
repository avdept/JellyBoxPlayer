import 'dart:async';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final faker = Faker.instance;
  final mockAlbum = DownloadedAlbumDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    serverId: faker.datatype.uuid(),
    type: 'Album',
    durationInTicks: faker.datatype.number(),
    sizeInBytes: faker.datatype.number(),
  );
  const keys = DownloadedAlbumViewKeys(
    deleteButton: Key('deleteButton'),
    confirmationDialog: Key('confirmationDialog'),
  );

  Widget getWidgetUT({
    required DownloadedAlbumDTO album,
    FutureOr<void> Function(DownloadedAlbumDTO)? onDelete,
  }) {
    return createTestApp(
      providerContainer: ProviderContainer(),
      home: Center(
        child: DownloadedAlbumView(
          album: album,
          onDelete: onDelete,
          testKeys: keys,
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
        expect(find.text(mockAlbum.name), findsOneWidget);
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
              if (album.id == mockAlbum.id) deleteCounter++;
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
  });
}
