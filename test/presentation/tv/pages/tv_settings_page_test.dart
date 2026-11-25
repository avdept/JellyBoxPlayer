import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_settings_page.dart';

import '../../../app_wrapper.dart';
import '../../../provider_container.dart';

void main() {
  testWidgets('TvSettingsPage - picks a lyrics text size with the remote', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1920, 1080)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = createProviderContainer(
      overrides: [cloudAvailableProvider.overrideWithValue(false)],
    );
    await tester.pumpWidget(
      createTestApp(
        providerContainer: container,
        home: const Scaffold(body: TvSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.text('Lyrics text size'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('160%'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(container.read(lyricsTextSizeProvider), 130);
    expect(find.text('130%'), findsOneWidget);
  });
}
