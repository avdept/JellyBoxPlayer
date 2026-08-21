import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/generated_playlists_setting_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class DisabledSettingNotifier extends BoolPrefNotifier {
  DisabledSettingNotifier() : super(null, key: 'test', defaultValue: true);
}

class FixedDayNotifier extends CurrentDayNotifier {
  FixedDayNotifier(this.day);

  String day;

  @override
  String build() => day;
}

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const userId = 'user-1';

  late MockMediaServerClient client;
  late GeneratedPlaylistDatabase database;
  late int generationCount;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('mixes_provider_db');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  List<GeneratedPlaylist> generatedFor(String label) => [
    GeneratedPlaylist(
      item: LibraryItem(
        id: 'jellybox:genre-mix:$label',
        name: '$label mix',
        kind: ItemKind.playlist,
      ),
      coverSongs: const [],
    ),
  ];

  Future<List<GeneratedPlaylist>> readPlaylists(
    ProviderContainer container,
  ) async {
    final subscription = container.listen(
      todaysPlaylistsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    try {
      return await container.read(todaysPlaylistsProvider.future);
    } finally {
      subscription.close();
    }
  }

  ProviderContainer makeContainer({
    required String day,
    String? libraryId,
    bool disabled = false,
  }) {
    final CurrentLibraryNotifier libraryNotifier = MockCurrentLibraryNotifier();
    when(libraryNotifier.build).thenAnswer(
      (_) async => libraryId == null
          ? null
          : LibraryItem(
              id: libraryId,
              name: libraryId,
              kind: ItemKind.library,
            ),
    );

    return ProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWithValue(client),
        generatedPlaylistDatabaseProvider.overrideWithValue(database),
        currentDayProvider.overrideWith(() => FixedDayNotifier(day)),
        currentUserProvider.overrideWith(
          (ref) => const User(userId: userId, token: 'token'),
        ),
        currentLibraryProvider.overrideWith(() => libraryNotifier),
        isOfflineProvider.overrideWith((ref) => false),
        if (disabled)
          generatedPlaylistsDisabledProvider.overrideWith(
            (ref) => DisabledSettingNotifier(),
          ),
      ],
    );
  }

  setUp(() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    database = GeneratedPlaylistDatabase(DownloadDatabase());
    generationCount = 0;
    client = MockMediaServerClient();
    when(
      () => client.generateTodaysPlaylists(
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        includeDiscovery: any(named: 'includeDiscovery'),
      ),
    ).thenAnswer((invocation) async {
      generationCount++;
      final library =
          invocation.namedArguments[const Symbol('libraryId')] as String?;
      return generatedFor('${library ?? 'all'}-$generationCount');
    });
  });

  test('generates once for a day, then serves the stored set', () async {
    final first = makeContainer(day: '2026-08-20', libraryId: 'lib-a');
    final generated = await readPlaylists(first);
    first.dispose();

    final second = makeContainer(day: '2026-08-20', libraryId: 'lib-a');
    final reread = await readPlaylists(second);
    second.dispose();

    expect(generationCount, 1);
    expect(reread.map((p) => p.item.id), generated.map((p) => p.item.id));
  });

  test('regenerates when the day key changes', () async {
    final today = makeContainer(day: '2026-08-20', libraryId: 'lib-a');
    await readPlaylists(today);
    today.dispose();

    final tomorrow = makeContainer(day: '2026-08-21', libraryId: 'lib-a');
    final next = await readPlaylists(tomorrow);
    tomorrow.dispose();

    expect(generationCount, 2);
    expect(next.single.item.id, 'jellybox:genre-mix:lib-a-2');
  });

  test(
    'a second library gets its own set without touching the first',
    () async {
      final libA = makeContainer(day: '2026-08-20', libraryId: 'lib-a');
      final first = await readPlaylists(libA);
      libA.dispose();

      final libB = makeContainer(day: '2026-08-20', libraryId: 'lib-b');
      final second = await readPlaylists(libB);
      libB.dispose();

      expect(generationCount, 2);
      expect(first.single.libraryId, 'lib-a');
      expect(second.single.libraryId, 'lib-b');
      expect(second.single.item.id, isNot(first.single.item.id));

      final backToA = makeContainer(day: '2026-08-20', libraryId: 'lib-a');
      final reread = await readPlaylists(backToA);
      backToA.dispose();

      expect(generationCount, 2);
      expect(reread.single.item.id, first.single.item.id);
    },
  );

  test('generates nothing while the setting disables the feature', () async {
    final off = makeContainer(
      day: '2026-08-20',
      libraryId: 'lib-a',
      disabled: true,
    );
    final playlists = await readPlaylists(off);
    off.dispose();

    expect(playlists, isEmpty);
    expect(generationCount, 0);
    verifyNever(
      () => client.generateTodaysPlaylists(
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        includeDiscovery: any(named: 'includeDiscovery'),
      ),
    );
  });
}
