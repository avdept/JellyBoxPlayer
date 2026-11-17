import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvGenrePage extends ConsumerStatefulWidget {
  const TvGenrePage({required this.genre, super.key});

  final LibraryItem genre;

  @override
  ConsumerState<TvGenrePage> createState() => _TvGenrePageState();
}

class _TvGenrePageState extends ConsumerState<TvGenrePage> {
  int _requestedPage = 0;

  LibraryItem get genre => widget.genre;

  Future<void> _play() async {
    final SetPlaybackResult result;
    try {
      result = await ref.read(setPlaybackProvider.notifier).playGenre(genre);
    } on Object catch (_) {
      _notify('Could not start playing "${genre.name}"');
      return;
    }
    if (result == SetPlaybackResult.empty) {
      _notify('Nothing to play in "${genre.name}"');
      return;
    }
    if (result == SetPlaybackResult.started && mounted) {
      unawaited(context.pushNamed(Routes.nowPlaying.name));
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadMore(ItemsPage page) {
    final exhausted = page.items.length < page.currentPage * page.totalPerPage;
    if (exhausted || page.currentPage <= _requestedPage) return;
    _requestedPage = page.currentPage;
    unawaited(ref.read(genreAlbumsProvider(genre.id).notifier).loadMore());
  }

  void _openAlbum(LibraryItem album) => unawaited(
    context.pushNamed(
      branchAwareName(context, Routes.album),
      extra: {'album': album},
    ),
  );

  void _albumOptions(LibraryItem album) => unawaited(
    showTvItemOptions(
      context,
      ref,
      album,
      scope: ContextMenuScope.browse,
      onLike: (album) async {
        final updated = await toggleFavourite(ref, album);
        ref.read(genreAlbumsProvider(genre.id).notifier).updateItem(updated);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(genreAlbumsProvider(genre.id));
    final images = ref.read(imageServiceProvider);

    return Scaffold(
      backgroundColor: TvTokens.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.pagePaddingH,
              TvTokens.pagePaddingV,
              TvTokens.pagePaddingH,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    genre.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvTokens.title,
                  ),
                ),
                const SizedBox(width: 16),
                TvButton(
                  label: 'Play',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  autofocus: true,
                  busy: ref.watch(setPlaybackProvider) == genre.id,
                  onSelect: () => unawaited(_play()),
                ),
              ],
            ),
          ),
          Expanded(
            child: albums.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(TvTokens.pagePaddingH),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text('No albums', style: TvTokens.caption),
                    ),
                  );
                }
                return TvCardGrid(
                  itemCount: page.items.length,
                  itemAt: (index) => page.items[index],
                  imageFor: (item) => images.itemImage(item, size: 400),
                  subtitleFor: (item) => item.albumArtist,
                  onNearEnd: () => _loadMore(page),
                  onSelect: _openAlbum,
                  onLongSelect: _albumOptions,
                );
              },
              loading: () => const TvCardGrid.loading(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(TvTokens.pagePaddingH),
                child: ref.watch(isOfflineProvider)
                    ? const OfflineNotice(
                        message:
                            "You're offline. Your library will be back "
                            'once the server is reachable.',
                      )
                    : const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Could not load albums',
                          style: TvTokens.caption,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
