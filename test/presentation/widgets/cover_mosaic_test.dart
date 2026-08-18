import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/cover_mosaic.dart';

final _pixel = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<ImageProvider> covers(int count) =>
      List.generate(count, (_) => MemoryImage(_pixel));

  Future<void> pumpMosaic(WidgetTester tester, int count) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox.square(
          dimension: 200,
          child: CoverMosaic(images: covers(count)),
        ),
      ),
    ),
  );

  group('CoverMosaic', () {
    testWidgets('- gives every tile real height with four covers', (
      widgetTester,
    ) async {
      await pumpMosaic(widgetTester, 4);

      final tiles = find.byType(DecoratedBox);
      expect(tiles, findsNWidgets(4));

      for (var i = 0; i < 4; i++) {
        final size = widgetTester.getSize(tiles.at(i));
        expect(size.width, 100);
        expect(size.height, 100);
      }
    });

    testWidgets('- falls back to a single cover below four', (
      widgetTester,
    ) async {
      await pumpMosaic(widgetTester, 3);

      expect(find.byType(DecoratedBox), findsOneWidget);
      expect(
        widgetTester.getSize(find.byType(DecoratedBox)),
        const Size(200, 200),
      );
    });

    testWidgets('- still fills the square with no covers at all', (
      widgetTester,
    ) async {
      await pumpMosaic(widgetTester, 0);

      expect(
        widgetTester.getSize(find.byType(DecoratedBox)),
        const Size(200, 200),
      );
    });
  });
}
