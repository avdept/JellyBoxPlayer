import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/downloads_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final faker = Faker.instance;
  final mockAlbum = DownloadedAlbum(
    item: LibraryItem(
      id: faker.datatype.uuid(),
      name: faker.lorem.sentence(),
      kind: ItemKind.album,
    ),
    sizeInBytes: faker.datatype.number(),
    downloadDate: DateTime.now(),
  );
  final mockPlaylist = DownloadedPlaylist(
    item: LibraryItem(
      id: faker.datatype.uuid(),
      name: faker.lorem.sentence(),
      kind: ItemKind.playlist,
    ),
    sizeInBytes: faker.datatype.number(),
    downloadDate: DateTime.now(),
  );
  const keys = DownloadsPageKeys(
    counterText: Key('counterText'),
  );

  Widget getWidgetUT({
    List<DownloadedAlbum> albums = const [],
    List<DownloadedPlaylist> playlists = const [],
  }) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        downloadedAlbumsProvider.overrideWith((_) async => albums),
        downloadedPlaylistsProvider.overrideWith((_) async => playlists),
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
            matching: find.text(mockAlbum.item.name),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays list of playlists',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(playlists: [mockPlaylist]));
        await widgetTester.pump(Duration.zero);
        final playlistFinder = find.byType(DownloadedPlaylistView);
        expect(playlistFinder, findsOneWidget);
        expect(
          find.descendant(
            of: playlistFinder,
            matching: find.text(mockPlaylist.item.name),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- shows section headers when both kinds are downloaded',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(albums: [mockAlbum], playlists: [mockPlaylist]),
        );
        await widgetTester.pump(Duration.zero);
        expect(find.text('Playlists'), findsOneWidget);
        expect(find.text('Albums'), findsOneWidget);
      },
    );

    testWidgets(
      '- shows empty state when nothing is downloaded',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        expect(find.text('No downloads yet'), findsOneWidget);
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

    testWidgets(
      '- counts playlists alongside albums',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(albums: [mockAlbum], playlists: [mockPlaylist]),
        );
        await widgetTester.pump(Duration.zero);
        expect(
          widgetTester.widget<Text>(find.byKey(keys.counterText)).data,
          '1 album • 1 playlist',
        );
      },
    );
  });
}
