import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';

class SongListSliver extends ConsumerStatefulWidget {
  const SongListSliver({
    required this.songs,
    required this.onItemUpdated,
    this.limit,
    this.edgePadding,
    super.key,
  });

  final List<LibraryItem> songs;
  final void Function(LibraryItem updated) onItemUpdated;
  final int? limit;
  final double? edgePadding;

  @override
  ConsumerState<SongListSliver> createState() => _SongListSliverState();
}

class _SongListSliverState extends ConsumerState<SongListSliver> {
  void _onSongTap(LibraryItem song, List<LibraryItem> songs) {
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
    widget.onItemUpdated(
      song.copyWith(
        userData: song.userData.copyWith(isFavorite: !isFavorite),
      ),
    );
  }

  Future<void> _onArtistTap(LibraryItem song) async {
    final artistId = song.effectiveArtists.firstOrNull?.id;
    if (artistId == null) return;
    final item = await ref
        .read(mediaServerClientProvider)
        .getItem(artistId, kind: ItemKind.artist);
    if (!mounted) return;
    context.pushNamed(
      branchAwareName(context, Routes.artist),
      extra: {'artist': item},
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    if (songs.isEmpty) return const SliverToBoxAdapter();

    final currentSongId = ref.watch(
      playbackProvider.select((s) {
        final index = s.currentMediaIndex;
        return index != null ? s.songs.elementAtOrNull(index)?.id : null;
      }),
    );
    final limit = widget.limit;
    final visible = (limit != null && limit < songs.length)
        ? songs.sublist(0, limit)
        : songs;

    return SliverList.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final song = visible[index];
        return SongRowView(
          song: song,
          isPlaying: currentSongId == song.id,
          onTap: (song) => _onSongTap(song, visible),
          onLikePressed: _onLikePressed,
          onArtistTap: _onArtistTap,
          edgePadding: widget.edgePadding,
          optionsBuilder: (context) => contextMenuActions(
            context,
            ref,
            song,
            scope: ContextMenuScope.browse,
            onLike: _onLikePressed,
          ),
        );
      },
    );
  }
}
