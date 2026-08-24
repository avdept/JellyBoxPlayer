import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?> {
  late SharedPreferences _prefs;

  static const String _libraryIdStorageKey = 'library_id';
  static const String _libraryPathStorageKey = 'library_path';
  static const String _libraryNameStorageKey = 'library_name';

  @override
  FutureOr<LibraryItem?> build() async {
    _prefs = ref.watch(sharedPreferencesProvider).requireValue;
    final keepAliveLink = ref.keepAlive();
    ref.onDispose(keepAliveLink.close);

    state = const AsyncLoading();
    final library = LibraryItem(
      id: _prefs.getString(_libraryIdStorageKey) ?? '',
      path: _prefs.getString(_libraryPathStorageKey),
      name: _prefs.getString(_libraryNameStorageKey) ?? '',
      kind: ItemKind.library,
    );

    if (library.id.isEmpty) return null;

    return library;
  }

  Future<void> setLibrary(LibraryItem lib) async {
    state = AsyncData(lib);
    await Future.wait([
      _prefs.setString(_libraryIdStorageKey, lib.id),
      _prefs.setString(_libraryPathStorageKey, lib.path ?? ''),
      _prefs.setString(_libraryNameStorageKey, lib.name),
    ]);
  }
}

final currentLibraryProvider =
    AutoDisposeAsyncNotifierProvider<CurrentLibraryNotifier, LibraryItem?>(
      CurrentLibraryNotifier.new,
    );
