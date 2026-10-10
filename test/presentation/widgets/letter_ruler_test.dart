import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/letter_ruler.dart';

void main() {
  Widget ruler({
    required ValueChanged<String> onLetterSelected,
    bool reversed = false,
  }) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          height: 540,
          child: LetterRuler(
            reversed: reversed,
            haptics: false,
            onLetterSelected: onLetterSelected,
          ),
        ),
      ),
    ),
  );

  testWidgets('maps a touch position onto a letter', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(ruler(onLetterSelected: selected.add));
    final box = tester.getRect(find.byType(LetterRuler));
    final slot = box.height / 27;

    await tester.tapAt(box.topCenter + Offset(0, slot * 0.5));
    await tester.tapAt(box.topCenter + Offset(0, slot * 13.5));
    await tester.tapAt(box.bottomCenter - const Offset(0, 1));

    expect(selected, ['#', 'M', 'Z']);
  });

  testWidgets('reports each letter crossed while dragging', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(ruler(onLetterSelected: selected.add));
    final box = tester.getRect(find.byType(LetterRuler));

    final gesture = await tester.startGesture(
      box.topCenter + const Offset(0, 2),
    );
    for (var i = 1; i <= 27; i++) {
      await gesture.moveBy(Offset(0, box.height / 27));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();

    expect(selected.first, '#');
    expect(selected.last, 'Z');
    expect(selected.toSet().length, selected.length);
  });

  testWidgets('a reversed ruler runs from Z down to #', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      ruler(onLetterSelected: selected.add, reversed: true),
    );
    final box = tester.getRect(find.byType(LetterRuler));

    await tester.tapAt(box.topCenter + const Offset(0, 2));
    await tester.tapAt(box.bottomCenter - const Offset(0, 1));

    expect(selected, ['Z', '#']);
  });

  testWidgets('a hovered letter and its neighbours grow', (tester) async {
    await tester.pumpWidget(ruler(onLetterSelected: (_) {}));
    final box = tester.getRect(find.byType(LetterRuler));
    final slot = box.height / 27;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(box.topCenter + Offset(0, slot * 13.5));
    await tester.pumpAndSettle();

    double scaleOf(String letter) => tester
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.text(letter),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
    expect(scaleOf('M'), LetterRuler.hoverScales[0]);
    expect(scaleOf('L'), LetterRuler.hoverScales[1]);
    expect(scaleOf('N'), LetterRuler.hoverScales[1]);
    expect(scaleOf('A'), 1);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(scaleOf('M'), 1);
  });
}
