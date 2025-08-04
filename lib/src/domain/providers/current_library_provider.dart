import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentLibraryNotifier extends AutoDisposeAsyncNotifier<ItemDTO?> {
  late SharedPreferences _prefs;

  static const String _libraryIdStorageKey = 'library_id';
  static const String _libraryPathStorageKey = 'library_path';
  static const String _libraryNameStorageKey = 'library_name';

  @override
  FutureOr<ItemDTO?> build() async {
    _prefs = ref.watch(sharedPreferencesProvider).requireValue;
    final keepAliveLink = ref.keepAlive();
    ref.onDispose(keepAliveLink.close);

    state = const AsyncLoading();
    final library = ItemDTO(
      id: _prefs.getString(_libraryIdStorageKey) ?? '',
      path: _prefs.getString(_libraryPathStorageKey),
      name: _prefs.getString(_libraryNameStorageKey) ?? '',
      type: 'Library',
    );

    if (library.id.isEmpty || (library.path?.isEmpty ?? true)) return null;

    return library;
  }

  Future<void> setLibrary(ItemDTO lib) async {
    state = AsyncData(lib);
    await Future.wait([
      _prefs.setString(_libraryIdStorageKey, lib.id),
      _prefs.setString(_libraryPathStorageKey, lib.path ?? ''),
      _prefs.setString(_libraryNameStorageKey, lib.name),
    ]);
  }
}

final currentLibraryProvider =
    AutoDisposeAsyncNotifierProvider<CurrentLibraryNotifier, ItemDTO?>(
      CurrentLibraryNotifier.new,
    );
