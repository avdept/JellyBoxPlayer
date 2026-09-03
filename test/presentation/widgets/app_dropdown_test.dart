import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) => createTestApp(
    providerContainer: createProviderContainer(),
    home: Scaffold(body: Center(child: child)),
  );

  AppDropdown<String> dropdown({
    String value = 'a',
    ValueChanged<String>? onChanged,
  }) => AppDropdown<String>(
    icon: Icons.sort,
    value: value,
    onChanged: onChanged ?? (_) {},
    entries: [
      AppDropdownEntry(
        value: 'a',
        label: 'Alpha',
        leadingBuilder: (color) => Icon(Icons.abc, color: color),
      ),
      AppDropdownEntry(
        value: 'b',
        label: 'Beta',
        trailingBuilder: (color) => Icon(Icons.arrow_upward, color: color),
      ),
    ],
  );

  testWidgets('- shows only the icon until it is opened', (tester) async {
    await tester.pumpWidget(wrap(dropdown()));

    expect(find.byIcon(Icons.sort), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('- opens to reveal the entries, with leading and trailing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(dropdown()));

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byIcon(Icons.abc), findsWidgets);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('- tints the button while the menu is open', (tester) async {
    await tester.pumpWidget(wrap(dropdown()));
    final closed = tester.widget<Icon>(find.byIcon(Icons.sort)).color;

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    final opened = tester.widgetList<Icon>(find.byIcon(Icons.sort)).first.color;
    expect(opened, isNot(closed));
  });

  testWidgets('- reports the picked value', (tester) async {
    String? picked;
    await tester.pumpWidget(wrap(dropdown(onChanged: (v) => picked = v)));

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(picked, 'b');
  });

  testWidgets('- marks the selected entry differently', (tester) async {
    await tester.pumpWidget(wrap(dropdown(value: 'b')));

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    final alpha = tester.widget<Text>(find.text('Alpha')).style?.color;
    final beta = tester.widget<Text>(find.text('Beta')).style?.color;
    expect(beta, isNot(alpha));
  });

  group('custom button', () {
    testWidgets('- renders a caller-supplied button and reports open state', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          AppDropdown<String>(
            value: 'a',
            onChanged: (_) {},
            buttonBuilder: (isOpened) => Text(isOpened ? 'open' : 'closed'),
            entries: const [
              AppDropdownEntry(value: 'a', label: 'Alpha'),
              AppDropdownEntry(value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );

      expect(find.text('closed'), findsOneWidget);

      await tester.tap(find.text('closed'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
    });
  });
}
