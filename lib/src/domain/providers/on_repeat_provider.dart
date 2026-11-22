import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/play_history/played_song_hydrator.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/played_song_hydrator_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const onRepeatWindow = Duration(days: 30);
const onRepeatSongsLimit = 100;
const onRepeatMinimumPlays = 2;
const onRepeatMinimumSongs = 20;

final playHistoryChangedProvider = StateProvider<int>((ref) => 0);

typedef OnRepeatSnapshot = ({List<String> ids, List<LibraryItem> songs});

LibraryItem onRepeatPlaylistFor(String userId) =>
    UserPlaylist.onRepeat.itemFor(userId);

bool isOnRepeatId(String id) => EphemeralPlaylistId.isOnRepeat(id);

final Provider<LibraryItem?> onRepeatPlaylistProvider = Provider((ref) {
  final userId = ref.watch(currentUserProvider)?.userId;
  return userId == null ? null : onRepeatPlaylistFor(userId);
});

final AutoDisposeFutureProvider<LibraryItem?> onRepeatCardProvider =
    FutureProvider.autoDispose((ref) async {
      final playlist = ref.watch(onRepeatPlaylistProvider);
      if (playlist == null) return null;
      ref.watch(playHistoryChangedProvider);
      final count = await ref
          .watch(playHistoryDatabaseProvider)
          .trackedSongCount(
            window: onRepeatWindow,
            minPlays: onRepeatMinimumPlays,
          );
      return count >= onRepeatMinimumSongs ? playlist : null;
    });

Future<OnRepeatSnapshot> onRepeatSnapshotOf(Ref ref) async {
  final history = ref.read(playHistoryDatabaseProvider);
  final top = await history.topPlayed(
    window: onRepeatWindow,
    limit: onRepeatSongsLimit,
    minPlays: onRepeatMinimumPlays,
  );
  final ids = [for (final row in top) row.songId];
  final stored = await history.playedSongsByIds(ids);
  return (
    ids: ids,
    songs: [
      for (final id in ids) ?stored[id],
    ],
  );
}

Future<List<LibraryItem>> onRepeatSongsOf(Ref ref) async {
  final snapshot = await onRepeatSnapshotOf(ref);
  if (snapshot.ids.isEmpty) return snapshot.songs;
  return ref.read(playedSongHydratorProvider).refresh(snapshot.ids);
}

class OnRepeatSongsNotifier
    extends AutoDisposeAsyncNotifier<List<LibraryItem>> {
  @override
  FutureOr<List<LibraryItem>> build() async {
    if (ref.watch(currentUserProvider) == null) return const [];
    final isOffline = ref.watch(isOfflineProvider);
    final hydrator = ref.watch(playedSongHydratorProvider);
    final snapshot = await onRepeatSnapshotOf(ref);
    if (!isOffline && snapshot.ids.isNotEmpty) {
      unawaited(_enrich(hydrator, snapshot));
    }
    return snapshot.songs;
  }

  Future<void> _enrich(
    PlayedSongHydrator hydrator,
    OnRepeatSnapshot snapshot,
  ) async {
    try {
      state = AsyncData(await hydrator.refresh(snapshot.ids));
    } on Object {
      return;
    }
  }

  void updateItem(LibraryItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.id == updated.id) updated else item,
    ]);
  }
}

final AutoDisposeAsyncNotifierProvider<OnRepeatSongsNotifier, List<LibraryItem>>
onRepeatSongsProvider = AsyncNotifierProvider.autoDispose(
  OnRepeatSongsNotifier.new,
);
