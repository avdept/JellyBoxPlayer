import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => prefs),
      ],
    );
  }

  test('- restores a library that has no path, as Emby reports it', () async {
    final container = await containerWith({
      'library_id': '3',
      'library_name': 'Music',
      'library_path': '',
    });
    addTearDown(container.dispose);

    final library = await container.read(currentLibraryProvider.future);

    expect(library, isNotNull);
    expect(library!.id, '3');
    expect(library.name, 'Music');
  });

  test(
    '- restores a library that has a path, as Jellyfin reports it',
    () async {
      final container = await containerWith({
        'library_id': 'abc',
        'library_name': 'Music',
        'library_path': '/media/music',
      });
      addTearDown(container.dispose);

      final library = await container.read(currentLibraryProvider.future);

      expect(library?.id, 'abc');
      expect(library?.path, '/media/music');
    },
  );

  test('- has no library when none was ever selected', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    expect(await container.read(currentLibraryProvider.future), isNull);
  });

  test('- keeps the selection across a restart', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    await container.read(currentLibraryProvider.future);
    await container
        .read(currentLibraryProvider.notifier)
        .setLibrary(
          const LibraryItem(id: '3', name: 'Music', kind: ItemKind.library),
        );

    final prefs = await SharedPreferences.getInstance();
    final restored = await (await containerWith({
      'library_id': prefs.getString('library_id')!,
      'library_name': prefs.getString('library_name')!,
      'library_path': prefs.getString('library_path')!,
    })).read(currentLibraryProvider.future);

    expect(restored?.id, '3');
  });
}
