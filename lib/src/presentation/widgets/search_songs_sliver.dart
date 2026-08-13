import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/playlist_picker_sheet.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';

class SearchSongsSliver extends ConsumerStatefulWidget {
  const SearchSongsSliver({this.limit, super.key});

  final int? limit;

  @override
  ConsumerState<SearchSongsSliver> createState() => _SearchSongsSliverState();
}

class _SearchSongsSliverState extends ConsumerState<SearchSongsSliver> {
  void _onSongTap(ItemDTO song, List<ItemDTO> songs) {
    final syntheticAlbum = ItemDTO(
      id: song.albumId ?? song.id,
      name: song.albumName ?? '',
      type: 'MusicAlbum',
      albumArtist: song.albumArtist,
      albumArtists: song.albumArtists,
      imageTags: song.imageTags,
    );
    ref.read(playbackProvider.notifier).play(song, songs, syntheticAlbum);
  }

  Future<void> _onLikePressed(ItemDTO song) async {
    final api = ref.read(jellyfinApiProvider);
    final isFavorite = song.userData.isFavorite;
    final callback = isFavorite ? api.removeFavorite : api.saveFavorite;
    await callback.call(
      userId: ref.read(currentUserProvider)!.userId,
      itemId: song.id,
    );
    ref
        .read(searchItemsProvider(ItemList.songs).notifier)
        .updateItem(
          song.copyWith(
            userData: song.userData.copyWith(isFavorite: !isFavorite),
          ),
        );
  }

  Future<void> _onArtistTap(ItemDTO song) async {
    final artistId = song.albumArtists.firstOrNull?.id;
    if (artistId == null) return;
    final item = await ref.read(jellyfinApiProvider).getItem(itemId: artistId);
    if (!mounted) return;
    context.pushNamed(Routes.artist.name, extra: {'artist': item.data});
  }

  Future<void> _onGoToAlbum(ItemDTO song) async {
    final albumId = song.albumId;
    if (albumId == null) return;
    final item = await ref.read(jellyfinApiProvider).getItem(itemId: albumId);
    if (!mounted) return;
    ref.read(currentAlbumProvider.notifier).setAlbum(item.data);
    context.pushNamed(Routes.album.name, extra: {'album': item.data});
  }

  Future<void> _onAddToPlaylistPressed(ItemDTO song) async {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final playlist = await showPlaylistPicker(
      context,
      isDesktop: device.isDesktop,
    );
    if (playlist == null || !mounted) return;
    await ref
        .read(jellyfinApiProvider)
        .addPlaylistItems(
          playlistId: playlist.id,
          userId: ref.read(currentUserProvider)!.userId,
          entryIds: song.id,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully added to playlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs =
        ref.watch(searchItemsProvider(ItemList.songs)).valueOrNull?.items ??
        const <ItemDTO>[];
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
          optionsBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _onAddToPlaylistPressed(song),
              child: const Text('Add to playlist'),
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
