import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

Future<List<LibraryItem>> loadGeneratedPlaylistSongs(
  Ref ref, {
  required String playlistId,
  required bool isOffline,
}) async {
  final userId = ref.read(currentUserProvider)?.userId;
  if (userId == null) return const [];

  final libraryId = (await ref.read(currentLibraryProvider.future))?.id;
  final dayKey = ref.read(currentDayProvider);
  final database = ref.read(generatedPlaylistDatabaseProvider);

  final stored = await database.getSongs(
    playlistId: playlistId,
    userId: userId,
    libraryId: libraryId,
    dayKey: dayKey,
  );
  if (stored.isNotEmpty) return stored;
  if (isOffline) throw const OfflineException();

  final songs = await ref
      .read(mediaServerClientProvider)
      .getGeneratedPlaylistSongs(
        userId: userId,
        playlistId: playlistId,
        libraryId: libraryId,
      );

  await database.saveSongs(
    songs,
    playlistId: playlistId,
    userId: userId,
    libraryId: libraryId,
    dayKey: dayKey,
  );
  return songs;
}

class TodaysPlaylistsNotifier
    extends AutoDisposeAsyncNotifier<List<GeneratedPlaylist>> {
  @override
  FutureOr<List<GeneratedPlaylist>> build() async {
    if (ref.watch(settingProvider(AppSetting.generatedPlaylistsDisabled))) {
      return const [];
    }

    final userId = ref.watch(currentUserProvider)?.userId;
    if (userId == null) return const [];

    final libraryId = (await ref.watch(currentLibraryProvider.future))?.id;
    final dayKey = ref.watch(currentDayProvider);
    final isOffline = ref.watch(isOfflineProvider);

    final stored = await ref
        .watch(generatedPlaylistDatabaseProvider)
        .getPlaylists(userId: userId, libraryId: libraryId, dayKey: dayKey);
    if (stored.isNotEmpty) return stored;
    if (isOffline) throw const OfflineException();

    return _generate(userId: userId, libraryId: libraryId, dayKey: dayKey);
  }

  Future<void> regenerate() async {
    final userId = ref.read(currentUserProvider)?.userId;
    if (userId == null) return;

    final libraryId = (await ref.read(currentLibraryProvider.future))?.id;
    final dayKey = ref.read(currentDayProvider);

    state = const AsyncLoading<List<GeneratedPlaylist>>();
    state = await AsyncValue.guard(
      () => _generate(userId: userId, libraryId: libraryId, dayKey: dayKey),
    );
  }

  Future<List<GeneratedPlaylist>> _generate({
    required String userId,
    required String? libraryId,
    required String dayKey,
  }) async {
    if (ref.read(isOfflineProvider)) throw const OfflineException();

    final playlists = await ref
        .read(mediaServerClientProvider)
        .generateTodaysPlaylists(
          userId: userId,
          libraryId: libraryId,
          includeDiscovery: true,
        );

    final database = ref.read(generatedPlaylistDatabaseProvider);
    await database.savePlaylists(
      playlists,
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );

    return database.getPlaylists(
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
  }
}

final AutoDisposeAsyncNotifierProvider<
  TodaysPlaylistsNotifier,
  List<GeneratedPlaylist>
>
todaysPlaylistsProvider = AsyncNotifierProvider.autoDispose(
  TodaysPlaylistsNotifier.new,
);

final AutoDisposeProvider<AsyncValue<List<LibraryItem>>>
todaysPlaylistItemsProvider = Provider.autoDispose((ref) {
  return ref
      .watch(todaysPlaylistsProvider)
      .whenData(
        (playlists) => [for (final playlist in playlists) playlist.item],
      );
});

class TodaysPlaylistSongsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<LibraryItem>, String> {
  @override
  FutureOr<List<LibraryItem>> build(String playlistId) {
    return loadGeneratedPlaylistSongs(
      ref,
      playlistId: playlistId,
      isOffline: ref.watch(isOfflineProvider),
    );
  }

  void updateItem(LibraryItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.id == updated.id) updated else item,
    ]);

    final userId = ref.read(currentUserProvider)?.userId;
    if (userId == null) return;
    unawaited(
      ref
          .read(generatedPlaylistDatabaseProvider)
          .updateSong(
            updated,
            userId: userId,
            libraryId: ref.read(currentLibraryProvider).valueOrNull?.id,
            dayKey: ref.read(currentDayProvider),
          ),
    );
  }
}

final todaysPlaylistSongsProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      TodaysPlaylistSongsNotifier,
      List<LibraryItem>,
      String
    >(TodaysPlaylistSongsNotifier.new);
