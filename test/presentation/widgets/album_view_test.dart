import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final faker = Faker.instance;
  final mockAlbum = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.album,
    albumArtist: faker.name.fullName(),
  );

  Widget getWidgetUT({
    Future<void> Function(LibraryItem)? onPlayPressed,
    void Function(LibraryItem)? onTap,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(),
      home: Center(
        child: SizedBox(
          width: 200,
          height: 260,
          child: AlbumView(
            album: mockAlbum,
            onTap: onTap,
            onPlayPressed: onPlayPressed,
          ),
        ),
      ),
    );
  }

  double playButtonOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(MaterialButton),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  double playButtonScale(WidgetTester tester) => tester
      .widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(MaterialButton),
          matching: find.byType(AnimatedScale),
        ),
      )
      .scale;

  Future<TestGesture> hoverOverCard(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(AlbumView)));
    await tester.pumpAndSettle();
    return gesture;
  }

  group('AlbumView', () {
    testWidgets(
      '- has no play button when onPlayPressed is not set',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        expect(find.byType(MaterialButton), findsNothing);
      },
    );

    testWidgets(
      '- keeps the play button hidden until the card is hovered',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(onPlayPressed: (_) async {}));
        await widgetTester.pump(Duration.zero);
        expect(playButtonOpacity(widgetTester), 0);

        await hoverOverCard(widgetTester);
        expect(playButtonOpacity(widgetTester), 1);
      },
    );

    testWidgets(
      '- zooms the play button while it is hovered itself',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(onPlayPressed: (_) async {}));
        await widgetTester.pump(Duration.zero);

        final gesture = await hoverOverCard(widgetTester);
        expect(playButtonScale(widgetTester), 1);

        await gesture.moveTo(
          widgetTester.getCenter(find.byIcon(Icons.play_arrow_outlined)),
        );
        await widgetTester.pumpAndSettle();
        expect(playButtonScale(widgetTester), greaterThan(1));

        await gesture.moveTo(widgetTester.getTopLeft(find.byType(AlbumView)));
        await widgetTester.pumpAndSettle();
        expect(playButtonScale(widgetTester), 1);
      },
    );

    testWidgets(
      '- reports the album on play press without triggering onTap',
      (widgetTester) async {
        final played = <LibraryItem>[];
        var tapCounter = 0;
        await widgetTester.pumpWidget(
          getWidgetUT(
            onPlayPressed: (album) async => played.add(album),
            onTap: (_) => tapCounter++,
          ),
        );
        await widgetTester.pump(Duration.zero);
        await hoverOverCard(widgetTester);

        await widgetTester.tap(find.byIcon(Icons.play_arrow_outlined));
        await widgetTester.pumpAndSettle();

        expect(played, [mockAlbum]);
        expect(tapCounter, 0);
      },
    );
  });
}
