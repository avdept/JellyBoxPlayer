import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/presentation/widgets/singer_view.dart';
import 'package:jplayer/src/screen_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Main app rendering', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: SingerView(name: 'Test')));

      // Verify the counter starts at 0.
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
