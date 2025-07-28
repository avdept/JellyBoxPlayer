import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/downloads_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final faker = Faker.instance;
  final mockAlbum = DownloadedAlbumDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    type: 'Album',
    runTimeTicks: faker.datatype.number(),
    sizeInBytes: faker.datatype.number(),
  );
  const keys = DownloadsPageKeys(
    counterText: Key('counterText'),
  );

  Widget getWidgetUT({
    required List<DownloadedAlbumDTO> albums,
  }) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        downloadedAlbumsProvider.overrideWith((_) async => albums),
      ],
    ),
    home: const DownloadsPage(testKeys: keys),
  );

  group('DownloadsPage', () {
    testWidgets(
      '- displays list of albums',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(albums: [mockAlbum]));
        await widgetTester.pump(Duration.zero);
        final albumFinder = find.byType(DownloadedAlbumView);
        expect(albumFinder, findsOneWidget);
        expect(
          find.descendant(
            of: albumFinder,
            matching: find.text(mockAlbum.name),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays albums counter',
      (widgetTester) async {
        final mockAlbums = List.generate(
          faker.datatype.number(min: 1, max: 3),
          (_) => mockAlbum,
        );
        await widgetTester.pumpWidget(getWidgetUT(albums: mockAlbums));
        await widgetTester.pump(Duration.zero);
        final counterFinder = find.byKey(keys.counterText);
        expect(counterFinder, findsOneWidget);
        expect(
          widgetTester.widget<Text>(counterFinder).data,
          contains(RegExp('${mockAlbums.length} \\w+')),
        );
      },
    );
  });
}
