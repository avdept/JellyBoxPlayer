import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/smooth_position.dart';

class _FakeStopwatch implements Stopwatch {
  Duration now = Duration.zero;
  Duration _start = Duration.zero;

  @override
  Duration get elapsed => now - _start;

  @override
  void reset() => _start = now;

  @override
  void start() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStopwatch stopwatch;
  late Duration shown;
  late StateSetter update;
  var reported = Duration.zero;
  var playing = true;

  Future<void> pump(WidgetTester tester) async {
    stopwatch = _FakeStopwatch();
    reported = const Duration(seconds: 30);
    playing = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 2560,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SmoothPosition(
                  position: reported,
                  duration: const Duration(minutes: 4),
                  playing: playing,
                  stopwatch: stopwatch,
                  builder: (context, position) {
                    shown = position;
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> advance(WidgetTester tester, Duration by) async {
    stopwatch.now += by;
    await tester.pump(by);
  }

  Future<void> report(WidgetTester tester, Duration position) async {
    update(() => reported = position);
    await tester.pump();
  }

  group('SmoothPosition', () {
    testWidgets('- moves between position reports while playing', (
      tester,
    ) async {
      await pump(tester);
      await advance(tester, const Duration(milliseconds: 100));

      expect(shown, const Duration(seconds: 30, milliseconds: 100));
    });

    testWidgets('- holds still while paused', (tester) async {
      await pump(tester);
      update(() => playing = false);
      await tester.pump();
      await advance(tester, const Duration(milliseconds: 500));

      expect(shown, const Duration(seconds: 30));
    });

    testWidgets('- a slightly late report never moves the bar backwards', (
      tester,
    ) async {
      await pump(tester);
      await advance(tester, const Duration(milliseconds: 200));
      final before = shown;
      await report(tester, const Duration(seconds: 30, milliseconds: 120));

      expect(shown, before);

      var last = shown;
      for (var i = 0; i < 20; i++) {
        await advance(tester, const Duration(milliseconds: 50));
        expect(shown, greaterThanOrEqualTo(last));
        last = shown;
      }
      expect(
        shown,
        const Duration(seconds: 30, milliseconds: 120) +
            const Duration(seconds: 1),
      );
    });

    testWidgets('- a seek jumps straight to the new position', (tester) async {
      await pump(tester);
      await advance(tester, const Duration(milliseconds: 200));
      await report(tester, const Duration(minutes: 2));

      expect(shown, const Duration(minutes: 2));
    });

    testWidgets('- stops advancing when reports dry up', (tester) async {
      await pump(tester);
      await advance(tester, const Duration(seconds: 5));

      expect(
        shown,
        const Duration(seconds: 30) + SmoothPosition.maxExtrapolation,
      );
    });
  });
}
