import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentLibraryNotifier extends AutoDisposeAsyncNotifier<ItemDTO?> {
  static const String _libraryIdStorageKey = 'library_id';
  static const String _libraryPathStorageKey = 'library_path';
  static const String _libraryNameStorageKey = 'library_name';

  @override
  FutureOr<ItemDTO?> build() async {
    final keepAliveLink = ref.keepAlive();
    ref.onDispose(keepAliveLink.close);

    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    final library = ItemDTO(
      id: prefs.getString(_libraryIdStorageKey) ?? '',
      path: prefs.getString(_libraryPathStorageKey),
      name: prefs.getString(_libraryNameStorageKey) ?? '',
      type: 'Library',
    );

    if (library.id.isEmpty || (library.path?.isEmpty ?? true)) return null;

    return library;
  }

  Future<void> setLibrary(ItemDTO lib) async {
    state = AsyncData(lib);
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_libraryIdStorageKey, lib.id),
      prefs.setString(_libraryPathStorageKey, lib.path ?? ''),
      prefs.setString(_libraryNameStorageKey, lib.name),
    ]);
  }
}

final currentLibraryProvider =
    AutoDisposeAsyncNotifierProvider<CurrentLibraryNotifier, ItemDTO?>(
      CurrentLibraryNotifier.new,
    );
