import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';

class SongListSliver extends ConsumerStatefulWidget {
  const SongListSliver({
    required this.songs,
    required this.onItemUpdated,
    this.queue,
    this.limit,
    this.edgePadding,
    this.set,
    this.showPosition = false,
    this.showAlbum = false,
    this.showCover,
    this.asColumn = false,
    super.key,
  });

  final List<LibraryItem> songs;
  final void Function(LibraryItem updated) onItemUpdated;
  final List<LibraryItem>? queue;
  final int? limit;
  final double? edgePadding;
  final LibraryItem? set;
  final bool showPosition;
  final bool showAlbum;
  final bool? showCover;
  final bool asColumn;

  @override
  ConsumerState<SongListSliver> createState() => _SongListSliverState();
}

class _SongListSliverState extends ConsumerState<SongListSliver> {
  void _onSongTap(LibraryItem song, List<LibraryItem> songs) {
    final set = widget.set;
    if (set != null) {
      unawaited(
        ref
            .read(playbackProvider.notifier)
            .play(song, songs, set, sourceId: set.id),
      );
      return;
    }
    final syntheticAlbum = LibraryItem(
      id: song.albumId ?? song.id,
      name: song.albumName ?? '',
      kind: ItemKind.album,
      albumArtist: song.albumArtist,
      albumArtists: song.albumArtists,
      images: song.images,
    );
    ref.read(playbackProvider.notifier).play(song, songs, syntheticAlbum);
  }

  Future<void> _onLikePressed(LibraryItem song) async {
    final isFavorite = song.userData.isFavorite;
    await ref
        .read(mediaServerClientProvider)
        .setFavorite(song.id, favorite: !isFavorite);
    ref.read(favouritesChangedProvider.notifier).state++;
    widget.onItemUpdated(
      song.copyWith(
        userData: song.userData.copyWith(isFavorite: !isFavorite),
      ),
    );
  }

  Future<void> _onRatingChanged(LibraryItem song, int rating) async =>
      widget.onItemUpdated(await rateItem(ref, song, rating));

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    if (songs.isEmpty) {
      return widget.asColumn
          ? const SizedBox.shrink()
          : const SliverToBoxAdapter();
    }

    final currentSongId = ref.watch(
      barSongProvider.select((song) => song?.id),
    );
    final limit = widget.limit;
    final visible = (limit != null && limit < songs.length)
        ? songs.sublist(0, limit)
        : songs;

    if (widget.asColumn) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < visible.length; index++)
            _row(visible[index], index, visible, currentSongId),
        ],
      );
    }

    return SliverList.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) =>
          _row(visible[index], index, visible, currentSongId),
    );
  }

  Widget _row(
    LibraryItem song,
    int index,
    List<LibraryItem> visible,
    String? currentSongId,
  ) => SongRowView(
    song: song,
    isPlaying: currentSongId == song.id,
    onTap: (song) => _onSongTap(song, widget.queue ?? visible),
    onLikePressed: _onLikePressed,
    onRatingChanged: _onRatingChanged,
    position: widget.showPosition ? index + 1 : null,
    showAlbum: widget.showAlbum,
    showCover: widget.showCover,
    edgePadding: widget.edgePadding,
    optionsBuilder: (context) => contextMenuActions(
      context,
      ref,
      song,
      scope: ContextMenuScope.browse,
      onLike: _onLikePressed,
    ),
  );
}
