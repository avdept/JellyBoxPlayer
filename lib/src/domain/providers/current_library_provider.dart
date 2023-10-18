import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';

final currentLibraryProvider = StateNotifierProvider.autoDispose<CurrentLibraryNotifier, LibraryDTO?>(
  (ref) {
    final notifier = CurrentLibraryNotifier(api: ref.read(jellyfinApiProvider), storage: ref.read(secureStorageProvider));
    final keepAliveLink = ref.keepAlive();

    ref.onDispose(keepAliveLink.close);

    return notifier;
  },
);

class CurrentLibraryNotifier extends StateNotifier<LibraryDTO?> {
  CurrentLibraryNotifier({
    required JellyfinApi api,
    required FlutterSecureStorage storage,
  })  : _api = api,
        _storage = storage,
        super(null);

  final JellyfinApi _api;
  final FlutterSecureStorage _storage;
  final String libraryIdStorageKey = 'library_id';
  final String libraryPathStorageKey = 'library_path';

  Future<void> setSelectLibrary(LibraryDTO lib) async {
    state = lib;
    await _storage.write(key: libraryIdStorageKey, value: lib.id);
    await _storage.write(key: libraryPathStorageKey, value: lib.path);
  }

  Future<List<LibraryDTO>> fetchLibraries() async {
    try {
      final libraries = await _api.getLibraries();
      return libraries.data.libraries;
    } on DioException catch (e) {
      log(e.message ?? "Error while fetching libraries");
      state = null;
    }
    return [];
  }
}
