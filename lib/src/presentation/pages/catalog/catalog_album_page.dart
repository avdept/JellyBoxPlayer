import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/providers/catalog_preview_provider.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class CatalogAlbumPage extends ConsumerStatefulWidget {
  const CatalogAlbumPage({required this.album, super.key});

  final CatalogAlbum album;

  @override
  ConsumerState<CatalogAlbumPage> createState() => _CatalogAlbumPageState();
}

class _CatalogAlbumPageState extends ConsumerState<CatalogAlbumPage> {
  final _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey(debugLabel: 'catalog-album-title');

  late ThemeData _theme;
  late DeviceType _device;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  CatalogAlbum get _album => widget.album;

  ImageProvider get _cover => switch (_album.coverUrl) {
    final url? => CachedNetworkImageProvider(url),
    null => const AssetImage(Images.album),
  };

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(catalogAlbumProvider(_album.key));
    final album = detail.valueOrNull?.album ?? _album;
    final tracks = detail.valueOrNull?.tracks ?? const <CatalogTrack>[];
    final edgePadding = _device.isMobile ? 16.0 : 30.0;
    final content = [
      ..._contentSlivers(detail, tracks, edgePadding),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ];

    if (_device.isMobile) {
      return MobileCoverScaffold(
        controller: _scrollController,
        titleKey: _titleKey,
        title: album.title,
        previousPageTitle: album.artistName ?? 'Back',
        cover: _cover,
        panel: _MobilePanel(album: album, tracks: tracks, titleKey: _titleKey),
        slivers: content,
      );
    }

    return DesktopPageColumn(
      controller: _scrollController,
      titleKey: _titleKey,
      title: album.title,
      previousPageTitle: album.artistName ?? 'Back',
      edgePadding: edgePadding,
      slivers: [
        SliverToBoxAdapter(
          child: _DesktopHeader(
            album: album,
            tracks: tracks,
            cover: _cover,
            titleKey: _titleKey,
            device: _device,
            edgePadding: edgePadding,
          ),
        ),
        ...content,
      ],
    );
  }

  List<Widget> _contentSlivers(
    AsyncValue<CatalogAlbumDetail?> detail,
    List<CatalogTrack> tracks,
    double edgePadding,
  ) {
    if (detail.hasError) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(edgePadding, 24, edgePadding, 0),
            child: Text(
              'Could not load this album.',
              style: TextStyle(
                color: _theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ];
    }
    if (detail.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SongRowsShimmer(
              device: _device,
              count: 6,
              edgePadding: edgePadding,
            ),
          ),
        ),
      ];
    }

    final preview = ref.watch(catalogPreviewProvider);
    final sections = _discSections(tracks);
    return [
      for (final section in sections) ...[
        if (sections.length > 1)
          SliverToBoxAdapter(
            child: DiscHeader(
              title: section.disc != null ? 'Disc ${section.disc}' : 'Other',
              fontSize: _device.isMobile ? 16 : 18,
              edgePadding: edgePadding,
            ),
          ),
        SliverList.builder(
          itemCount: section.tracks.length,
          itemBuilder: (context, index) {
            final track = section.tracks[index];
            final active = preview.track == track.key;
            return _TrackRow(
              track: track,
              position: track.trackNumber ?? index + 1,
              status: !active
                  ? _PreviewStatus.idle
                  : (preview.loading
                        ? _PreviewStatus.loading
                        : _PreviewStatus.playing),
              progress: ref.read(catalogPreviewProvider.notifier).progress,
              device: _device,
              theme: _theme,
              edgePadding: edgePadding,
              onTap: track.hasPreview
                  ? () => unawaited(
                      ref.read(catalogPreviewProvider.notifier).toggle(track),
                    )
                  : null,
            );
          },
        ),
      ],
    ];
  }

  static List<({int? disc, List<CatalogTrack> tracks})> _discSections(
    List<CatalogTrack> tracks,
  ) {
    final byDisc = <int?, List<CatalogTrack>>{};
    for (final track in tracks) {
      byDisc.putIfAbsent(track.discNumber, () => []).add(track);
    }
    return [
      for (final entry in byDisc.entries)
        (disc: entry.key, tracks: entry.value),
    ];
  }
}

class _MobilePanel extends StatelessWidget {
  const _MobilePanel({
    required this.album,
    required this.tracks,
    required this.titleKey,
  });

  final CatalogAlbum album;
  final List<CatalogTrack> tracks;
  final GlobalKey titleKey;

  @override
  Widget build(BuildContext context) => IconTheme.merge(
    data: const IconThemeData(size: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          album.title,
          key: titleKey,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        if (album.artistName case final artist?) Text(artist),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _AlbumDetails(album: album, tracks: tracks),
            ),
            const SizedBox(width: 12),
            const AddToLidarrButton(),
          ],
        ),
        const SizedBox(height: 8),
        _Attribution(album: album),
      ],
    ),
  );
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.album,
    required this.tracks,
    required this.cover,
    required this.titleKey,
    required this.device,
    required this.edgePadding,
  });

  final CatalogAlbum album;
  final List<CatalogTrack> tracks;
  final ImageProvider cover;
  final GlobalKey titleKey;
  final DeviceType device;
  final double edgePadding;

  @override
  Widget build(BuildContext context) {
    final size = device.isDesktop ? 254.0 : 200.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(edgePadding, 8, edgePadding, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: cover,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(Images.album, width: size, height: size),
            ),
          ),
          const SizedBox(width: 38),
          Expanded(
            child: IconTheme.merge(
              data: const IconThemeData(size: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    key: titleKey,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (album.artistName case final artist?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        artist,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _AlbumDetails(album: album, tracks: tracks),
                      const AddToLidarrButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Attribution(album: album),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumDetails extends StatelessWidget {
  const _AlbumDetails({required this.album, required this.tracks});

  final CatalogAlbum album;
  final List<CatalogTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final year = album.releaseDate?.year;
    if (tracks.isEmpty) {
      return year == null
          ? const SizedBox.shrink()
          : Text('$year', style: const TextStyle(fontSize: 14, height: 1.2));
    }
    return AlbumDetailsRow(
      duration: tracks.fold(
        Duration.zero,
        (sum, track) => sum + track.duration,
      ),
      songCount: tracks.length,
      year: year,
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.album});

  final CatalogAlbum album;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      CatalogAttribution(source: album.source, url: album.url),
      MusicBrainzLink(barcode: album.upc, artistName: album.artistName),
    ],
  );
}

enum _PreviewStatus { idle, loading, playing }

class _TrackRow extends StatefulWidget {
  const _TrackRow({
    required this.track,
    required this.position,
    required this.status,
    required this.progress,
    required this.device,
    required this.theme,
    required this.edgePadding,
    this.onTap,
  });

  final CatalogTrack track;
  final int position;
  final _PreviewStatus status;
  final ValueListenable<double> progress;
  final DeviceType device;
  final ThemeData theme;
  final double edgePadding;
  final VoidCallback? onTap;

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isTablet = widget.device.isTablet;
    final playable = widget.onTap != null;
    final active = widget.status != _PreviewStatus.idle;
    final onPrimary = theme.colorScheme.onPrimary;
    final secondary = onPrimary.withValues(alpha: 0.6);
    final artist = widget.track.artistName;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: CatalogContextMenuRegion(
        child: SimpleListTile(
          onTap: widget.onTap,
          hoverColor: onPrimary.withValues(alpha: 0.06),
          backgroundColor: active
              ? theme.bottomSheetTheme.backgroundColor?.withValues(alpha: 0.75)
              : Colors.transparent,
          padding: EdgeInsets.fromLTRB(widget.edgePadding, 8, 4, 8),
          leading: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(width: 22, child: _leading(secondary, playable)),
          ),
          leadingToTitle: widget.device.isMobile ? 12 : 16,
          title: Text(
            widget.track.title,
            maxLines: 1,
            style: TextStyle(
              fontSize: isTablet ? 18 : 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
              overflow: TextOverflow.ellipsis,
              color: playable ? onPrimary : onPrimary.withValues(alpha: 0.45),
            ),
          ),
          subtitle: artist == null && !playable
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (artist != null)
                      Flexible(
                        child: Text(
                          artist,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: secondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (playable) ...[
                      if (artist != null) const SizedBox(width: 6),
                      AudioQualityBadge(
                        label: 'Preview',
                        fontSize: isTablet ? 11 : 9,
                        textColor: onPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
          trailing: Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _duration(widget.track.duration),
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: secondary,
                ),
              ),
              const ContextMenuButton(actionsBuilder: catalogItemActions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading(Color faded, bool playable) {
    const size = 22.0;
    return switch (widget.status) {
      _PreviewStatus.loading => const SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      _PreviewStatus.playing => SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: widget.progress,
              builder: (context, value, child) =>
                  CircularProgressIndicator(value: value, strokeWidth: 2),
            ),
            const Icon(Icons.stop_rounded, size: 14),
          ],
        ),
      ),
      _PreviewStatus.idle when playable && _hovered => const Icon(
        Icons.play_arrow_rounded,
        size: size,
      ),
      _PreviewStatus.idle => Text(
        '${widget.position}',
        style: TextStyle(color: playable ? null : faded),
      ),
    };
  }

  static String _duration(Duration value) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(value.inMinutes.remainder(60));
    final seconds = twoDigits(value.inSeconds.remainder(60));
    final hours = value.inHours > 0 ? '${twoDigits(value.inHours)}:' : '';
    return '$hours$minutes:$seconds';
  }
}
