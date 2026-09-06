import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/anchored_dropdown.dart';

void main() {
  late AnchoredDropdownController controller;

  setUp(() => controller = AnchoredDropdownController());

  Future<void> pumpDropdown(
    WidgetTester tester, {
    required Alignment anchorAt,
    DropDirection direction = DropDirection.down,
    DropAlignment alignment = DropAlignment.end,
    Size menuSize = const Size(200, 120),
    Size screen = const Size(800, 600),
    bool dismissOnTapOutside = true,
  }) async {
    tester.view
      ..physicalSize = screen
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: anchorAt,
            child: AnchoredDropdown(
              controller: controller,
              direction: direction,
              alignment: alignment,
              dismissOnTapOutside: dismissOnTapOutside,
              menuBuilder: (context) => Material(
                child: SizedBox(
                  width: menuSize.width,
                  height: menuSize.height,
                  child: const Text('menu'),
                ),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: ElevatedButton(
                  onPressed: controller.toggle,
                  child: const Text('trigger'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect menuRect(WidgetTester tester) => tester.getRect(find.text('menu'));

  Rect triggerRect(WidgetTester tester) =>
      tester.getRect(find.byType(ElevatedButton));

  group('controller', () {
    testWidgets('- opens, closes and toggles', (tester) async {
      await pumpDropdown(tester, anchorAt: Alignment.center);

      expect(controller.isOpen, isFalse);
      expect(find.text('menu'), findsNothing);

      controller.open();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(find.text('menu'), findsOneWidget);

      controller.toggle();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('menu'), findsNothing);
    });

    testWidgets('- reports closed once the widget is gone', (tester) async {
      await pumpDropdown(tester, anchorAt: Alignment.center);
      controller.open();
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });
  });

  group('direction', () {
    testWidgets('- down puts the menu below the anchor', (tester) async {
      await pumpDropdown(tester, anchorAt: Alignment.center);
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).top,
        greaterThanOrEqualTo(triggerRect(tester).bottom),
      );
    });

    testWidgets('- up puts the menu above the anchor', (tester) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.center,
        direction: DropDirection.up,
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).bottom,
        lessThanOrEqualTo(triggerRect(tester).top),
      );
    });

    testWidgets('- up flips below when there is no room above', (tester) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.topCenter,
        direction: DropDirection.up,
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).top,
        greaterThanOrEqualTo(triggerRect(tester).bottom),
      );
    });

    testWidgets('- down flips above when there is no room below', (
      tester,
    ) async {
      await pumpDropdown(tester, anchorAt: Alignment.bottomCenter);
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).bottom,
        lessThanOrEqualTo(triggerRect(tester).top),
      );
    });
  });

  group('alignment', () {
    testWidgets('- end lines the menu up with the anchor right edge', (
      tester,
    ) async {
      await pumpDropdown(tester, anchorAt: Alignment.center);
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).right,
        moreOrLessEquals(triggerRect(tester).right, epsilon: 0.5),
      );
    });

    testWidgets('- start lines the menu up with the anchor left edge', (
      tester,
    ) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.center,
        alignment: DropAlignment.start,
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(
        menuRect(tester).left,
        moreOrLessEquals(triggerRect(tester).left, epsilon: 0.5),
      );
    });

    testWidgets('- center ignores the anchor and centres on screen', (
      tester,
    ) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.centerLeft,
        alignment: DropAlignment.center,
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(menuRect(tester).center.dx, moreOrLessEquals(400, epsilon: 0.5));
    });

    testWidgets('- keeps a wide menu inside the viewport', (tester) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.centerLeft,
        menuSize: const Size(360, 120),
        screen: const Size(375, 812),
      );
      controller.open();
      await tester.pumpAndSettle();

      final rect = menuRect(tester);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(375));
    });

    testWidgets('- shrinks a menu that asks for more than the screen', (
      tester,
    ) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.center,
        menuSize: const Size(900, 120),
        screen: const Size(375, 812),
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(menuRect(tester).width, lessThanOrEqualTo(375 - 24));
    });
  });

  group('barrier', () {
    testWidgets('- closes on a tap outside', (tester) async {
      await pumpDropdown(tester, anchorAt: Alignment.center);
      controller.open();
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('menu'), findsNothing);
    });

    testWidgets('- stays open on a tap outside when told to', (tester) async {
      await pumpDropdown(
        tester,
        anchorAt: Alignment.center,
        dismissOnTapOutside: false,
      );
      controller.open();
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('menu'), findsOneWidget);
    });
  });
}
