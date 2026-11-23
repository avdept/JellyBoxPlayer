import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/sync_hydrator_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final generatedPlaylistsChangedProvider = StateProvider<int>((ref) => 0);

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

  Future<List<LibraryItem>> read() => database.getSongs(
    playlistId: playlistId,
    userId: userId,
    libraryId: libraryId,
    dayKey: dayKey,
  );
  final stored = await read();
  if (stored.isNotEmpty) {
    if (isOffline || stored.every((song) => song.name.isNotEmpty)) {
      return stored;
    }
    await ref.read(syncHydratorProvider).hydrateGeneratedPlaylists();
    return read();
  }
  if (isOffline) throw const OfflineException();

  final songs = await ref
      .read(mediaServerClientProvider)
      .getGeneratedPlaylistSongs(
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
  ref.read(generatedPlaylistsChangedProvider.notifier).state++;
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

    final database = ref.watch(generatedPlaylistDatabaseProvider);
    final stored = await database.getPlaylists(
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
    if (stored.isNotEmpty) return stored;
    if (isOffline) throw const OfflineException();

    final generating = _attempt(libraryId: libraryId);
    await ref.read(cloudTrackProvider)(const {
      'k': 'generated_playlists',
      'now': true,
    });
    final shared = await database.getPlaylists(
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
    if (shared.isNotEmpty) return shared;

    final (:playlists, :error, :stackTrace) = await generating;
    if (playlists == null) {
      Error.throwWithStackTrace(error ?? const OfflineException(), stackTrace!);
    }
    return _store(
      playlists,
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
  }

  Future<void> forgetToday() async {
    final userId = ref.read(currentUserProvider)?.userId;
    if (userId == null) return;

    final libraryId = (await ref.read(currentLibraryProvider.future))?.id;
    await ref
        .read(generatedPlaylistDatabaseProvider)
        .deletePlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: ref.read(currentDayProvider),
        );
    await ref.read(cloudTrackProvider)(const {
      'k': 'generated_playlists',
      'reset': true,
    });
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
    final playlists = await _fetch(libraryId: libraryId);
    return _store(
      playlists,
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
  }

  Future<List<GeneratedPlaylist>> _fetch({required String? libraryId}) => ref
      .read(mediaServerClientProvider)
      .generateTodaysPlaylists(libraryId: libraryId, includeDiscovery: true);

  Future<
    ({
      List<GeneratedPlaylist>? playlists,
      Object? error,
      StackTrace? stackTrace,
    })
  >
  _attempt({required String? libraryId}) async {
    try {
      return (
        playlists: await _fetch(libraryId: libraryId),
        error: null,
        stackTrace: null,
      );
    } on Object catch (error, stackTrace) {
      return (playlists: null, error: error, stackTrace: stackTrace);
    }
  }

  Future<List<GeneratedPlaylist>> _store(
    List<GeneratedPlaylist> playlists, {
    required String userId,
    required String? libraryId,
    required String dayKey,
  }) async {
    final database = ref.read(generatedPlaylistDatabaseProvider);
    await database.savePlaylists(
      playlists,
      userId: userId,
      libraryId: libraryId,
      dayKey: dayKey,
    );
    ref.read(generatedPlaylistsChangedProvider.notifier).state++;

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
