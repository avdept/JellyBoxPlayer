import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/playlist_picker_sheet.dart';
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
    final artistId = song.albumArtists.firstOrNull?.id;
    if (artistId == null) return;
    final item = await ref.read(mediaServerClientProvider).getItem(artistId);
    if (!mounted) return;
    context.pushNamed(
      branchAwareName(context, Routes.artist),
      extra: {'artist': item},
    );
  }

  Future<void> _onGoToAlbum(LibraryItem song) async {
    final albumId = song.albumId;
    if (albumId == null) return;
    final item = await ref.read(mediaServerClientProvider).getItem(albumId);
    if (!mounted) return;
    ref.read(currentAlbumProvider.notifier).setAlbum(item);
    context.pushNamed(
      branchAwareName(context, Routes.album),
      extra: {'album': item},
    );
  }

  Future<void> _onAddToPlaylistPressed(LibraryItem song) async {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final playlist = await showPlaylistPicker(
      context,
      isDesktop: device.isDesktop,
    );
    if (playlist == null || !mounted) return;
    await ref
        .read(mediaServerClientProvider)
        .addPlaylistItems(playlistId: playlist.id, itemIds: [song.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully added to playlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    if (songs.isEmpty) return const SliverToBoxAdapter();

    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;

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
          optionsBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _onAddToPlaylistPressed(song),
              child: const Text('Add to playlist'),
            ),
            if (!isDesktop)
              PopupMenuItem(
                onTap: () => _onLikePressed(song),
                child: Text(favouriteMenuLabel(song)),
              ),
            if (song.albumArtists.isNotEmpty)
              PopupMenuItem(
                onTap: () => _onArtistTap(song),
                child: const Text('Go to Artist'),
              ),
            if (song.albumId != null)
              PopupMenuItem(
                onTap: () => _onGoToAlbum(song),
                child: const Text('Go to Album'),
              ),
          ],
        );
      },
    );
  }
}
