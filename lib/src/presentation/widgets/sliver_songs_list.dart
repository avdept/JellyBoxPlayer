import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playlists_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';

class SliverSongsList extends ConsumerWidget {
  const SliverSongsList(
    this.items, {
    this.selectedItem,
    this.onSelect,
    this.onListUpdated,
    super.key,
  });

  final List<SongDTO> items;
  final MediaItem? selectedItem;
  final ValueChanged<SongDTO>? onSelect;
  final VoidCallback? onListUpdated;

  Future<void> _onAddToPlaylistPressed(
    SongDTO song, {
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    ItemDTO? playlist;

    if (device.isDesktop) {
      playlist = await showAdaptiveDialog<ItemDTO>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'Choose a playlist',
            textAlign: TextAlign.center,
          ),
          content: _availablePlaylistsList(),
        ),
      );
    } else {
      playlist = await showModalBottomSheet<ItemDTO>(
        context: context,
        clipBehavior: Clip.antiAlias,
        builder: (context) => Scaffold(
          // backgroundColor: ,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
            automaticallyImplyLeading: false,
            title: const Text('Choose a playlist'),
            actions: const [
              CloseButton(),
            ],
          ),
          body: CustomScrollbar(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: _availablePlaylistsList(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (playlist != null) {
      await ref.read(jellyfinApiProvider).addPlaylistItems(
            playlistId: playlist.id,
            userId: ref.read(currentUserProvider)!.userId,
            entryIds: song.id,
          );
      const snackBar = SnackBar(
        backgroundColor: Colors.black87,
        content: Text(
          'Successfully added item to playlist',
          style: TextStyle(color: Colors.white),
        ),
      );
      onListUpdated?.call();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.builder(
      itemBuilder: (context, index) {
        final song = items[index];
        return PlayerSongView(
          song: song,
          isPlaying: song.id == selectedItem?.id,
          downloadProgress: null, // index == 2 ? 0.8 : null,
          onTap: onSelect,
          position: index + 1,
          onLikePressed: (song) async {
            final api = ref.read(jellyfinApiProvider);
            final callback = song.songUserData.isFavorite
                ? api.removeFavorite
                : api.saveFavorite;
            await callback.call(
              userId: ref.read(currentUserProvider)!.userId,
              itemId: song.id,
            );
            onListUpdated?.call();
          },
          optionsBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _onAddToPlaylistPressed(
                song,
                context: context,
                ref: ref,
              ),
              child: const Text('Add to playlist'),
            ),
          ],
        );
      },
      itemCount: items.length,
    );
  }

  Widget _availablePlaylistsList({EdgeInsets padding = EdgeInsets.zero}) {
    return Consumer(
      builder: (context, ref, child) {
        final data = ref.watch(playlistsProvider);

        if (data.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListBody(
          children: [
            SizedBox(height: padding.top),
            for (final playlist in data.value.items)
              SimpleListTile(
                onTap: () => Navigator.of(context).pop(playlist),
                padding: padding.copyWith(top: 6, bottom: 6),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: padding.bottom),
          ],
        );
      },
    );
  }
}
