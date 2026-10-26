import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

String get onRepeatName => S.current.onRepeat;
const onRepeatWindow = Duration(days: 30);
const onRepeatSongsLimit = 200;
const onRepeatMinimumSongs = 20;

final playHistoryChangedProvider = StateProvider<int>((ref) => 0);

typedef OnRepeatSnapshot = ({List<String> ids, List<LibraryItem> songs});

LibraryItem onRepeatPlaylistFor(String userId) => LibraryItem(
  id: EphemeralPlaylistId.onRepeat(userId),
  name: onRepeatName,
  kind: ItemKind.playlist,
);

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
          .trackedSongCount(window: onRepeatWindow);
      return count >= onRepeatMinimumSongs ? playlist : null;
    });

Future<OnRepeatSnapshot> onRepeatSnapshotOf(Ref ref) async {
  final history = ref.read(playHistoryDatabaseProvider);
  final top = await history.topPlayed(
    window: onRepeatWindow,
    limit: onRepeatSongsLimit,
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
  if (snapshot.ids.isEmpty || ref.read(isOfflineProvider)) {
    return snapshot.songs;
  }
  try {
    return await fetchSongsByRankedIds(
      ref.read(mediaServerClientProvider),
      snapshot.ids,
    );
  } on Object {
    return snapshot.songs;
  }
}

const _hydrationBatch = 100;

Future<List<LibraryItem>> fetchSongsByRankedIds(
  MediaServerClient client,
  List<String> ids,
) async {
  final batches = await Future.wait([
    for (var start = 0; start < ids.length; start += _hydrationBatch)
      client.getItemsByIds(
        ids.sublist(start, min(start + _hydrationBatch, ids.length)),
      ),
  ]);
  final byId = <String, LibraryItem>{
    for (final batch in batches)
      for (final item in batch) item.id: item,
  };
  return [
    for (final id in ids) ?byId[id],
  ];
}

class OnRepeatSongsNotifier
    extends AutoDisposeAsyncNotifier<List<LibraryItem>> {
  @override
  FutureOr<List<LibraryItem>> build() async {
    if (ref.watch(currentUserProvider) == null) return const [];
    final isOffline = ref.watch(isOfflineProvider);
    final client = ref.watch(mediaServerClientProvider);
    final snapshot = await onRepeatSnapshotOf(ref);
    if (!isOffline && snapshot.ids.isNotEmpty) {
      unawaited(_enrich(client, snapshot));
    }
    return snapshot.songs;
  }

  Future<void> _enrich(
    MediaServerClient client,
    OnRepeatSnapshot snapshot,
  ) async {
    try {
      final songs = await fetchSongsByRankedIds(client, snapshot.ids);
      state = AsyncData(songs);
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
