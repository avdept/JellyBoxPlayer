import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';

void main() {
  Duration? seekedTo;
  var duration = const Duration(minutes: 3);
  late StateSetter setDuration;

  Future<void> pumpSeekBar(WidgetTester tester) async {
    seekedTo = null;
    duration = const Duration(minutes: 3);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  setDuration = setState;
                  return SeekBar(
                    duration: duration,
                    position: const Duration(seconds: 30),
                    bufferedPosition: const Duration(minutes: 1),
                    onChangeEnd: (value) => seekedTo = value,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('SeekBar', () {
    testWidgets('- hovering shows the time a click would seek to', (
      tester,
    ) async {
      await pumpSeekBar(tester);
      final center = tester.getCenter(find.byType(SeekBar));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(center + const Offset(40, 0));
      await tester.pump();

      expect(find.text('1:50'), findsOneWidget);
      final bubble = tester.getRect(find.text('1:50'));
      expect(bubble.bottom, lessThan(center.dy));
      expect(bubble.bottom, greaterThan(center.dy - 40));
      expect(bubble.center.dx, moreOrLessEquals(center.dx + 40, epsilon: 1));

      await mouse.moveTo(Offset.zero);
      await tester.pump();

      expect(find.text('1:50'), findsNothing);
    });

    testWidgets('- leaving after the track loses its duration mid-hover', (
      tester,
    ) async {
      await pumpSeekBar(tester);
      final center = tester.getCenter(find.byType(SeekBar));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(center);
      await tester.pump();
      await mouse.down(center);
      await tester.pump();
      await mouse.moveBy(const Offset(120, 0));
      await tester.pump();
      await mouse.up();
      setDuration(() => duration = Duration.zero);
      await tester.pump();
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      setDuration(() => duration = const Duration(minutes: 3));
      await tester.pump();
      await mouse.moveTo(center);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(seekedTo, isNotNull);
      expect(find.text('1:30'), findsOneWidget);
    });
  });
}
