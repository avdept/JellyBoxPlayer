import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/presentation/pages/search_page.dart';

import '../../app_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget getWidgetUT() => createTestApp(
    providerContainer: ProviderContainer(),
    home: const SearchPage(),
  );

  group('SearchPage', () {
    testWidgets(
      '- displays a search field with clear button',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final searchFieldFinder = find.widgetWithIcon(
          TextField,
          JPlayer.search,
        );
        expect(searchFieldFinder, findsOneWidget);
        expect(
          find.descendant(
            of: searchFieldFinder,
            matching: find.widgetWithIcon(IconButton, JPlayer.close),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays filtering toggles',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        const filters = {'All', 'Playlists', 'Albums', 'Artists', 'Songs'};
        final chipFinder = find.byType(ActionChip);
        expect(chipFinder, findsNWidgets(filters.length));
        for (final label in filters) {
          expect(
            find.descendant(of: chipFinder, matching: find.text(label)),
            findsOneWidget,
          );
        }
      },
    );
  });
}
