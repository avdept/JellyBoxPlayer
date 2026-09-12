import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/widgets/quick_connect_dialog.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNotifier extends AsyncNotifier<bool?>
    with Mock
    implements AuthNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthNotifier mockAuthNotifier;
  late Completer<String?> pending;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
    pending = Completer<String?>();
    addTearDown(() {
      if (!pending.isCompleted) pending.complete(null);
    });
    when(mockAuthNotifier.build).thenAnswer((_) async => false);
    when(mockAuthNotifier.awaitQuickConnect).thenAnswer((_) => pending.future);
  });

  Future<void> pumpDialog(
    WidgetTester widgetTester,
    TargetPlatform platform,
  ) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => mockAuthNotifier)],
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          home: const Scaffold(body: QuickConnectDialog(code: '123456')),
        ),
      ),
    );
    await widgetTester.pump();
  }

  group('QuickConnectDialog', () {
    for (final platform in TargetPlatform.values) {
      testWidgets('- renders the code on ${platform.name}', (
        widgetTester,
      ) async {
        await pumpDialog(widgetTester, platform);

        expect(find.text('123456'), findsOneWidget);
      });
    }

    testWidgets('- copies the code when it is tapped', (widgetTester) async {
      String? copied;
      widgetTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => widgetTester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pumpDialog(widgetTester, TargetPlatform.iOS);
      await widgetTester.tap(find.text('123456'));
      await widgetTester.pump();

      expect(copied, '123456');
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('- cancels the pending request', (widgetTester) async {
      await pumpDialog(widgetTester, TargetPlatform.macOS);
      await widgetTester.tap(find.text('Cancel'));
      await widgetTester.pump();

      verify(mockAuthNotifier.cancelQuickConnect).called(1);
    });
  });
}
