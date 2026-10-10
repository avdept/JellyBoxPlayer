import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/album/album_page.dart';
import 'package:jplayer/src/presentation/pages/album/album_page_state.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvAlbumPage extends ConsumerStatefulWidget {
  const TvAlbumPage({required this.album, super.key});

  final LibraryItem album;

  @override
  ConsumerState<TvAlbumPage> createState() => _TvAlbumPageState();
}

class _TvAlbumPageState extends ConsumerState<TvAlbumPage> with AlbumPageState {
  @override
  LibraryItem get album => widget.album;

  @override
  AlbumPageKeys? get testKeys => null;

  @override
  double get edgePadding => TvTokens.pagePaddingH;

  @override
  double get navTitleFontSize => 16;

  @override
  double get discHeaderFontSize => 15;

  @override
  double get sectionTitleFontSize => 18;

  void _playSong(LibraryItem song) => unawaited(
    ref
        .read(playbackProvider.notifier)
        .play(song, songs, album, sourceId: album.id),
  );

  void _songOptions(LibraryItem song) => unawaited(
    showTvItemOptions(
      context,
      ref,
      song,
      scope: ContextMenuScope.albumPage,
      onLike: onSongLikePressed,
    ),
  );

  void _openAlbum(LibraryItem other) {
    ref.read(currentAlbumProvider.notifier).setAlbum(other);
    unawaited(
      context.pushNamed(
        branchAwareName(context, Routes.album),
        extra: {'album': other},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(setPlaybackProvider) == album.id;
    return TvCollectionScaffold(
      backdrop: albumCover,
      cover: Image(image: albumCover, fit: BoxFit.cover),
      title: album.name,
      subtitle: album.artistLabel,
      details: albumDetails(),
      actions: [
        TvButton(
          label: 'Play',
          icon: Icons.play_arrow_rounded,
          primary: true,
          autofocus: true,
          busy: busy,
          onSelect: () => unawaited(onPlayAlbumPressed()),
        ),
        TvButton(
          label: isFavorite ? 'Liked' : 'Like',
          icon: isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          onSelect: () => unawaited(onLikeAlbumPressed()),
        ),
      ],
      body: _tracks(),
    );
  }

  Widget _tracks() {
    if (songs.isEmpty) return _placeholder();

    final sections = discSections(songs);
    final showHeaders = sections.length > 1;
    final images = ref.read(imageServiceProvider);

    return ValueListenableBuilder(
      valueListenable: currentSong,
      builder: (context, playing, _) => FocusTraversalGroup(
        child: ListView(
          padding: const EdgeInsets.only(bottom: TvTokens.pagePaddingV),
          children: [
            for (final section in sections) ...[
              if (showHeaders)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    section.discNumber != null
                        ? 'Disc ${section.discNumber}'
                        : 'Other',
                    style: TextStyle(
                      fontSize: discHeaderFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              for (final (index, song) in section.songs.indexed)
                Padding(
                  padding: const EdgeInsets.only(
                    right: TvTokens.pagePaddingH,
                  ),
                  child: TvSongRow(
                    song: song,
                    position: index + 1,
                    isPlaying: playing != null && playing.id == song.id,
                    onSelect: () => _playSong(song),
                    onLongSelect: () => _songOptions(song),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            ..._relatedShelves(images),
          ],
        ),
      ),
    );
  }

  List<Widget> _relatedShelves(dynamic images) {
    final shelves = <Widget>[];
    final artist = album.albumArtists.firstOrNull;
    if (artist != null) {
      final more = ref
          .watch(
            moreFromArtistProvider((artistId: artist.id, albumId: album.id)),
          )
          .valueOrNull;
      if (more != null && more.isNotEmpty) {
        shelves.add(
          TvShelf(
            title: 'More from ${artist.name}',
            items: AsyncData(more),
            horizontalPadding: 16,
            imageFor: (item) =>
                ref.read(imageServiceProvider).itemImage(item, size: 400),
            subtitleFor: (item) => item.productionYear?.toString(),
            onSelect: _openAlbum,
          ),
        );
      }
    }
    final similar = ref.watch(similarAlbumsProvider(album.id)).valueOrNull;
    if (similar != null && similar.isNotEmpty) {
      shelves.add(
        TvShelf(
          title: 'You may also like',
          items: AsyncData(similar),
          horizontalPadding: 16,
          imageFor: (item) =>
              ref.read(imageServiceProvider).itemImage(item, size: 400),
          subtitleFor: (item) => item.artistLabel,
          onSelect: _openAlbum,
        ),
      );
    }
    return shelves;
  }

  Widget _placeholder() {
    if (isLoadingSongs) {
      return Padding(
        padding: const EdgeInsets.only(right: TvTokens.pagePaddingH),
        child: Column(
          children: [
            for (var i = 0; i < 8; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ShimmerBox(height: 34, radius: 8),
              ),
          ],
        ),
      );
    }
    if (!loadFailed && !ref.watch(isOfflineProvider)) {
      return const Center(
        child: Text('No songs in this album', style: TvTokens.body),
      );
    }
    return Center(
      child: OfflineNotice(
        message: ref.watch(isOfflineProvider)
            ? "You're offline and this album isn't downloaded."
            : 'Could not load this album.',
        onRetry: retryLoad,
      ),
    );
  }
}
