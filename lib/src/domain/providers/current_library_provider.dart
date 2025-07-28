import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currentLibraryProvider = StateNotifierProvider.autoDispose<CurrentLibraryNotifier, ItemDTO?>(
  (ref) {
    final notifier = CurrentLibraryNotifier(api: ref.read(jellyfinApiProvider), userId: ref.read(currentUserProvider)!.userId);
    final keepAliveLink = ref.keepAlive();

    ref.onDispose(keepAliveLink.close);
    notifier.initLibrarySelection();

    return notifier;
  },
);

class CurrentLibraryNotifier extends StateNotifier<ItemDTO?> {
  CurrentLibraryNotifier({
    required JellyfinApi api,
    required String userId,
  })  : _api = api,
        _userId = userId,
        super(null);

  final JellyfinApi _api;
  final String _userId;
  final String libraryIdStorageKey = 'library_id';
  final String libraryPathStorageKey = 'library_path';
  final String libraryNameStorageKey = 'library_name';

  ItemDTO? getCurrentLibrary() {
    print(state);
    return state;
  }

  Future<void> initLibrarySelection() async {
    final libId = prefs.getString(libraryIdStorageKey);
    final libPath = prefs.getString(libraryPathStorageKey);
    final libName = prefs.getString(libraryNameStorageKey);

    if ((libPath?.isNotEmpty ?? false) && (libId?.isNotEmpty ?? false)) {
      state = ItemDTO(id: libId!, name: libName ?? 'Untitled', path: libPath, type: 'Library');
    }
  }

  Future<void> setSelectLibrary(ItemDTO lib) async {
    state = lib;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(libraryIdStorageKey, lib.id);
    await prefs.setString(libraryPathStorageKey, lib.path ?? '');
  }

  Future<List<ItemDTO>> fetchLibraries() async {
    // try {
    final libraries = await _api.getLibraries(userId: _userId);
    return libraries.data.items;
    // } on DioException catch (e) {
    //   log(e.message ?? "Error while fetching libraries");
    //   state = null;
    // }
    // return [];
  }
}
