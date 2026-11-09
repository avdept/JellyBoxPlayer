import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const albumsDefault = Filter(orderBy: EntityFilter.dateCreated, desc: true);
  const byArtist = Filter(orderBy: EntityFilter.albumArtist);

  Future<ProviderContainer> containerFor(
    Map<String, Object> prefs, {
    String? serverId = 'jellyfin',
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(sharedPreferencesProvider.future);
    container.read(currentServerIdProvider.notifier).state = serverId;
    return container;
  }

  test('- falls back to the tab defaults when nothing was saved', () async {
    final container = await containerFor({});

    expect(container.read(browseSortProvider(ItemList.albums)), albumsDefault);
    expect(
      container.read(browseSortProvider(ItemList.artists)),
      const Filter(orderBy: EntityFilter.sortName),
    );
  });

  test('- remembers the chosen sort per tab across restarts', () async {
    final container = await containerFor({});
    container
        .read(appSettingsProvider.notifier)
        .setBrowseSort('jellyfin', ItemList.albums, byArtist);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(browseSortProvider(ItemList.albums)), byArtist);
    expect(
      container.read(browseSortProvider(ItemList.songs)),
      const Filter(orderBy: EntityFilter.sortName, desc: true),
    );

    final stored = (await SharedPreferences.getInstance()).getString(
      'app_settings',
    );
    final restarted = await containerFor({'app_settings': stored!});
    expect(restarted.read(browseSortProvider(ItemList.albums)), byArtist);
  });

  test('- keeps a separate sort for each server', () async {
    final container = await containerFor({});
    container.read(appSettingsProvider.notifier)
      ..setBrowseSort('jellyfin', ItemList.albums, byArtist)
      ..setBrowseSort(
        'navidrome',
        ItemList.albums,
        const Filter(orderBy: EntityFilter.random),
      );

    expect(container.read(browseSortProvider(ItemList.albums)), byArtist);

    container.read(currentServerIdProvider.notifier).state = 'navidrome';
    expect(
      container.read(browseSortProvider(ItemList.albums)),
      const Filter(orderBy: EntityFilter.random),
    );

    container.read(currentServerIdProvider.notifier).state = 'emby';
    expect(container.read(browseSortProvider(ItemList.albums)), albumsDefault);
  });

  test('- ignores a saved field it no longer knows', () async {
    final container = await containerFor({
      'app_settings':
          '{"browse_sort":{"jellyfin":{"albums":{"field":"gone","desc":false}}}}',
    });

    expect(container.read(browseSortProvider(ItemList.albums)), albumsDefault);
  });
}
