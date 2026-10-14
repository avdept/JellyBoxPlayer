import 'dart:async';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/providers/server_capabilities_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/downloads_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockDownloadManager extends Mock implements DownloadManager {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockMediaServerClient extends Mock implements MediaServerClient {}

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
  DownloadedSong downloadedSong(String name) => DownloadedSong(
    item: LibraryItem(
      id: faker.datatype.uuid(),
      name: name,
      kind: ItemKind.song,
    ),
    filePath: '/music/$name.flac',
    sizeInBytes: 1,
    downloadDate: DateTime.now(),
  );
  const keys = DownloadsPageKeys(
    counterText: Key('counterText'),
  );

  Widget getWidgetUT({
    List<DownloadedAlbum> albums = const [],
    List<DownloadedPlaylist> playlists = const [],
    List<DownloadedSong> songs = const [],
  }) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        downloadedAlbumsProvider.overrideWith((_) async => albums),
        downloadedPlaylistsProvider.overrideWith((_) async => playlists),
        standaloneDownloadedSongsProvider.overrideWith((_) async => songs),
        isSongDownloadedProvider.overrideWith((_, _) async => true),
        serverCapabilitiesProvider.overrideWithValue(
          const MediaServerCapabilities(),
        ),
      ],
    ),
    home: const DownloadsPage(testKeys: keys),
  );

  setUpAll(() => deviceId = 'test-device');

  Future<void> pumpTall(WidgetTester widgetTester, Widget widget) async {
    widgetTester.view.physicalSize = const Size(390, 2000);
    widgetTester.view.devicePixelRatio = 1;
    addTearDown(widgetTester.view.reset);
    await widgetTester.pumpWidget(widget);
    await widgetTester.pump(Duration.zero);
  }

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
      '- lists songs downloaded on their own under a Songs header',
      (widgetTester) async {
        await pumpTall(
          widgetTester,
          getWidgetUT(
            albums: [mockAlbum],
            songs: [downloadedSong('Loose one'), downloadedSong('Loose two')],
          ),
        );
        expect(find.text('Songs'), findsOneWidget);
        expect(find.byType(SongRowView), findsNWidgets(2));
        expect(find.text('Loose one'), findsOneWidget);
        expect(find.text('Loose two'), findsOneWidget);
      },
    );

    testWidgets(
      '- shows only the songs when nothing else is downloaded',
      (widgetTester) async {
        await pumpTall(
          widgetTester,
          getWidgetUT(songs: [downloadedSong('Loose one')]),
        );
        expect(find.text('No downloads yet'), findsNothing);
        expect(find.text('Songs'), findsNothing);
        expect(find.byType(SongRowView), findsOneWidget);
      },
    );

    testWidgets(
      '- counts standalone songs',
      (widgetTester) async {
        await pumpTall(
          widgetTester,
          getWidgetUT(
            albums: [mockAlbum],
            songs: [downloadedSong('Loose one'), downloadedSong('Loose two')],
          ),
        );
        expect(
          widgetTester.widget<Text>(find.byKey(keys.counterText)).data,
          '1 album • 2 songs',
        );
      },
    );

    testWidgets(
      '- keeps the list on screen while a removal refetches it',
      (widgetTester) async {
        final before = [
          downloadedSong('Loose one'),
          downloadedSong('Loose two'),
        ];
        final refetch = Completer<List<DownloadedSong>>();
        final container = createProviderContainer(
          overrides: [
            downloadedAlbumsProvider.overrideWith((_) async => [mockAlbum]),
            downloadedPlaylistsProvider.overrideWith((_) async => const []),
            standaloneDownloadedSongsProvider.overrideWith((ref) {
              final revision = ref.watch(downloadsRevisionProvider);
              return revision == 0 ? Future.value(before) : refetch.future;
            }),
            isSongDownloadedProvider.overrideWith((_, _) async => true),
            serverCapabilitiesProvider.overrideWithValue(
              const MediaServerCapabilities(),
            ),
          ],
        );
        await pumpTall(
          widgetTester,
          createTestApp(
            providerContainer: container,
            home: const DownloadsPage(testKeys: keys),
          ),
        );
        expect(find.byType(SongRowView), findsNWidgets(2));

        container.read(downloadsRevisionProvider.notifier).bump();
        await widgetTester.pump();

        expect(find.byType(AlbumCardsGridShimmer), findsNothing);
        expect(find.byType(SongRowView), findsNWidgets(2));

        refetch.complete(before.sublist(1));
        await widgetTester.pump(Duration.zero);
        await widgetTester.pump();

        expect(find.text('Loose one'), findsNothing);
        expect(find.byType(SongRowView), findsOneWidget);
      },
    );

    testWidgets(
      '- confirms a song removal even though its row goes away',
      (widgetTester) async {
        final song = downloadedSong('Loose one');
        final manager = MockDownloadManager();
        final database = MockDownloadDatabase();
        late ProviderContainer container;
        when(() => database.isSongDownloaded(song.item.id)).thenAnswer(
          (_) async => true,
        );
        when(() => manager.deleteSong(song.item.id)).thenAnswer((_) async {
          container.read(downloadsRevisionProvider.notifier).bump();
        });
        container = createProviderContainer(
          overrides: [
            downloadedAlbumsProvider.overrideWith((_) async => [mockAlbum]),
            downloadedPlaylistsProvider.overrideWith((_) async => const []),
            standaloneDownloadedSongsProvider.overrideWith(
              (ref) async =>
                  ref.watch(downloadsRevisionProvider) == 0 ? [song] : [],
            ),
            isSongDownloadedProvider.overrideWith((_, _) async => true),
            serverCapabilitiesProvider.overrideWithValue(
              const MediaServerCapabilities(),
            ),
            downloadManagerProvider.overrideWithValue(manager),
            downloadDatabaseProvider.overrideWithValue(database),
            mediaServerClientProvider.overrideWithValue(
              MockMediaServerClient(),
            ),
          ],
        );
        await pumpTall(
          widgetTester,
          createTestApp(
            providerContainer: container,
            home: const DownloadsPage(testKeys: keys),
          ),
        );

        await widgetTester.tap(
          find.descendant(
            of: find.byType(SongRowView),
            matching: find.byType(ContextMenuButton),
          ),
        );
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text('Remove download'));
        await widgetTester.pumpAndSettle();

        verify(() => manager.deleteSong(song.item.id)).called(1);
        expect(find.byType(SongRowView), findsNothing);
        expect(find.text('Removed "Loose one" from downloads'), findsOneWidget);
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
