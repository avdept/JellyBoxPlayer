import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvArtistPage extends ConsumerStatefulWidget {
  const TvArtistPage({required this.artist, super.key});

  final LibraryItem artist;

  @override
  ConsumerState<TvArtistPage> createState() => _TvArtistPageState();
}

class _TvArtistPageState extends ConsumerState<TvArtistPage> {
  late LibraryItem _artist = widget.artist;
  List<LibraryItem> _albums = const [];
  List<LibraryItem> _appearsOn = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final client = ref.read(mediaServerClientProvider);
    try {
      final albums = await client.getAlbums(
        LibraryQuery(
          sort: ItemSort.releaseDate,
          direction: SortDirection.descending,
          artistIds: [_artist.id],
        ),
      );
      final appearsOn = await client.getAlbums(
        LibraryQuery(
          sort: ItemSort.releaseDate,
          direction: SortDirection.descending,
          appearsOnArtistId: _artist.id,
        ),
      );
      if (!mounted) return;
      setState(() {
        _albums = albums.items;
        _appearsOn = appearsOn.items;
        _loading = false;
      });
    } on Object catch (error) {
      debugPrint('[TvArtistPage] could not load albums: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _play() async {
    final SetPlaybackResult result;
    try {
      result = await ref.read(setPlaybackProvider.notifier).playArtist(_artist);
    } on Object catch (_) {
      _notify('Could not start playing "${_artist.name}"');
      return;
    }
    if (result == SetPlaybackResult.empty) {
      _notify('Nothing to play for "${_artist.name}"');
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

  Future<void> _toggleLike() async {
    final updated = await toggleFavourite(ref, _artist);
    if (mounted) setState(() => _artist = updated);
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
        if (!mounted) return;
        LibraryItem replace(LibraryItem item) =>
            item.id == updated.id ? updated : item;
        setState(() {
          _albums = _albums.map(replace).toList();
          _appearsOn = _appearsOn.map(replace).toList();
        });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final images = ref.read(imageServiceProvider);
    final isFavorite = _artist.userData.isFavorite;
    return TvCollectionScaffold(
      cover: Image(
        image: images.itemImage(_artist, size: 480),
        fit: BoxFit.cover,
      ),
      title: _artist.name,
      circularCover: true,
      subtitle: _loading
          ? null
          : '${_albums.length} ${_albums.length == 1 ? 'album' : 'albums'}',
      actions: [
        TvButton(
          label: 'Play',
          icon: Icons.play_arrow_rounded,
          primary: true,
          autofocus: true,
          busy: ref.watch(setPlaybackProvider) == _artist.id,
          onSelect: () => unawaited(_play()),
        ),
        TvButton(
          label: isFavorite ? 'Liked' : 'Like',
          icon: isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          onSelect: () => unawaited(_toggleLike()),
        ),
      ],
      body: _body(images),
    );
  }

  Widget _body(ImageService images) {
    if (_loading) {
      return const TvCardGrid.loading(
        itemCount: 8,
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(16, 8, TvTokens.pagePaddingH, 16),
      );
    }
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('Could not load albums', style: TvTokens.caption),
            const SizedBox(width: 16),
            TvButton(
              label: 'Retry',
              icon: Icons.refresh,
              onSelect: () {
                setState(() {
                  _loading = true;
                  _failed = false;
                });
                unawaited(_load());
              },
            ),
          ],
        ),
      );
    }
    ImageProvider cover(LibraryItem item) => images.itemImage(item, size: 400);
    String? year(LibraryItem item) => item.productionYear?.toString();
    return ListView(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: TvTokens.pagePaddingV),
      children: [
        if (_albums.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No albums', style: TvTokens.caption),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Albums', style: TvTokens.sectionTitle),
          ),
          TvCardGrid(
            itemCount: _albums.length,
            itemAt: (index) => _albums[index],
            imageFor: cover,
            subtitleFor: year,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              TvTokens.pagePaddingH,
              16,
            ),
            onSelect: _openAlbum,
            onLongSelect: _albumOptions,
          ),
        ],
        if (_appearsOn.isNotEmpty)
          TvShelf(
            title: 'Appears on',
            items: AsyncData(_appearsOn),
            horizontalPadding: 16,
            imageFor: cover,
            subtitleFor: (item) => item.albumArtist,
            onSelect: _openAlbum,
            onLongSelect: _albumOptions,
          ),
      ],
    );
  }
}
