import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/rating_stars.dart';

void main() {
  final changes = <int>[];

  Future<void> pumpStars(WidgetTester tester, {int rating = 3}) async {
    changes.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RatingStars(
              rating: rating,
              spacing: 4,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
  }

  int filledStars(WidgetTester tester) =>
      find.byIcon(Icons.star_rounded).evaluate().length;

  double firstStarAlpha(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(Icons.star_rounded).first).color!.a;

  group('RatingStars', () {
    testWidgets('- tapping a star sets that value', (tester) async {
      await pumpStars(tester);
      final stars = find.byIcon(Icons.star_rounded);
      await tester.tap(stars.at(1));
      expect(changes, [2]);
    });

    testWidgets('- tapping the only filled star clears the rating', (
      tester,
    ) async {
      await pumpStars(tester, rating: 1);
      await tester.tap(find.byIcon(Icons.star_rounded));
      expect(changes, [0]);
    });

    testWidgets('- dragging across the stars previews and commits', (
      tester,
    ) async {
      await pumpStars(tester, rating: 1);
      final rect = tester.getRect(find.byType(RatingStars));
      final start = Offset(rect.left + 5, rect.center.dy);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(Offset(rect.right - 2, rect.center.dy));
      await tester.pump();

      expect(filledStars(tester), 5);
      expect(changes, isEmpty);

      await gesture.up();
      await tester.pump();

      expect(changes, [5]);
    });

    testWidgets('- dragging away from the stars clears the rating', (
      tester,
    ) async {
      await pumpStars(tester);
      final rect = tester.getRect(find.byType(RatingStars));
      final gesture = await tester.startGesture(
        Offset(rect.left + 5, rect.center.dy),
      );
      await gesture.moveTo(Offset(rect.center.dx, rect.center.dy));
      await gesture.moveTo(Offset(rect.center.dx, rect.bottom + 60));
      await tester.pump();

      expect(filledStars(tester), 0);

      await gesture.up();
      await tester.pump();

      expect(changes, [0]);
    });

    testWidgets('- dragging left past the first star clears the rating', (
      tester,
    ) async {
      await pumpStars(tester);
      final rect = tester.getRect(find.byType(RatingStars));
      final gesture = await tester.startGesture(
        Offset(rect.left + 30, rect.center.dy),
      );
      await gesture.moveTo(Offset(rect.left - 10, rect.center.dy));
      await gesture.up();
      await tester.pump();

      expect(changes, [0]);
    });

    testWidgets('- dragging right past the last star keeps five', (
      tester,
    ) async {
      await pumpStars(tester);
      final rect = tester.getRect(find.byType(RatingStars));
      final gesture = await tester.startGesture(
        Offset(rect.left + 5, rect.center.dy),
      );
      await gesture.moveTo(Offset(rect.right + 150, rect.center.dy));
      await gesture.up();
      await tester.pump();

      expect(changes, [5]);
    });

    testWidgets('- keeps the released value while the save is pending', (
      tester,
    ) async {
      final save = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RatingStars(rating: 1, onChanged: (_) => save.future),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(RatingStars));
      await tester.dragFrom(
        Offset(rect.left + 5, rect.center.dy),
        Offset(rect.width - 7, 0),
      );
      await tester.pump();

      expect(filledStars(tester), 5);
      expect(firstStarAlpha(tester), moreOrLessEquals(0.6, epsilon: 0.01));

      save.complete();
      await tester.pumpAndSettle();

      expect(filledStars(tester), 5);
      expect(firstStarAlpha(tester), 1);
    });

    testWidgets('- falls back to the old value when the save fails', (
      tester,
    ) async {
      final save = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RatingStars(rating: 1, onChanged: (_) => save.future),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(RatingStars));
      await tester.dragFrom(
        Offset(rect.left + 5, rect.center.dy),
        Offset(rect.width - 7, 0),
      );
      await tester.pump();

      expect(filledStars(tester), 5);

      save.completeError(StateError('offline'));
      await tester.pumpAndSettle();

      expect(filledStars(tester), 1);
    });

    testWidgets('- taps in the touch padding count as the nearest star', (
      tester,
    ) async {
      changes.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RatingStars(
                rating: 3,
                touchPadding: const EdgeInsets.symmetric(horizontal: 20),
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(RatingStars));
      await tester.tapAt(Offset(rect.left + 5, rect.center.dy));
      await tester.tapAt(Offset(rect.right - 5, rect.center.dy));
      expect(changes, [1, 5]);
    });

    testWidgets('- a read-only widget ignores drags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: RatingStars(rating: 2))),
        ),
      );
      final rect = tester.getRect(find.byType(RatingStars));
      await tester.dragFrom(
        Offset(rect.left + 5, rect.center.dy),
        Offset(rect.width, 0),
      );
      await tester.pump();
      expect(filledStars(tester), 2);
    });
  });
}
