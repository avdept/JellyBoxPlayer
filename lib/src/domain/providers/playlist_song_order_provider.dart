import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';

enum PlaylistSongSort { playlistOrder, title, artist, album }

class PlaylistSongOrder {
  const PlaylistSongOrder({
    this.sort = PlaylistSongSort.playlistOrder,
    this.descending = false,
  });

  final PlaylistSongSort sort;
  final bool descending;

  bool get isDefault => sort == PlaylistSongSort.playlistOrder && !descending;

  PlaylistSongOrder select(PlaylistSongSort next) => next == sort
      ? PlaylistSongOrder(sort: sort, descending: !descending)
      : PlaylistSongOrder(sort: next);

  List<LibraryItem> apply(List<LibraryItem> songs) {
    if (isDefault) return songs;
    final sorted = [...songs];
    final compare = _comparator;
    if (compare != null) mergeSort(sorted, compare: compare);
    return descending ? sorted.reversed.toList() : sorted;
  }

  Comparator<LibraryItem>? get _comparator => switch (sort) {
    PlaylistSongSort.playlistOrder => null,
    PlaylistSongSort.title => (a, b) => _compareText(a.name, b.name),
    PlaylistSongSort.artist => (a, b) => _compareText(
      a.artistLabel,
      b.artistLabel,
    ),
    PlaylistSongSort.album => (a, b) {
      final byAlbum = _compareText(a.albumName ?? '', b.albumName ?? '');
      return byAlbum != 0 ? byAlbum : LibraryItem.compareAlbumOrder(a, b);
    },
  };

  static int _compareText(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());
}

final AutoDisposeStateProviderFamily<PlaylistSongOrder, String>
playlistSongOrderProvider = StateProvider.autoDispose
    .family<PlaylistSongOrder, String>((ref, id) => const PlaylistSongOrder());
