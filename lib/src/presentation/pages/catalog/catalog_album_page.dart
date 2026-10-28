import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/providers/catalog_preview_provider.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/presentation/pages/catalog/catalog_artist_page.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class CatalogAlbumPage extends ConsumerWidget {
  const CatalogAlbumPage({required this.album, super.key});

  final CatalogAlbum album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final edgePadding = device.isMobile ? 16.0 : 30.0;
    final detail = ref.watch(catalogAlbumProvider(album.key));
    final preview = ref.watch(catalogPreviewProvider);
    final tracks = detail.valueOrNull?.tracks ?? const <CatalogTrack>[];
    final sections = _discSections(tracks);

    return Scaffold(
      body: ScrollablePageScaffold(
        useGradientBackground: true,
        navigationBar: CatalogNavigationBar(title: album.title, device: device),
        contentPadding: const EdgeInsets.only(bottom: 30),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              album: detail.valueOrNull?.album ?? album,
              tracks: tracks,
              device: device,
              theme: theme,
              edgePadding: edgePadding,
            ),
          ),
          if (detail.hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(edgePadding, 24, edgePadding, 0),
                child: Text(
                  'Could not load this album.',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else if (detail.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SongRowsShimmer(
                  device: device,
                  count: 6,
                  edgePadding: edgePadding,
                ),
              ),
            )
          else
            for (final section in sections) ...[
              if (sections.length > 1)
                SliverToBoxAdapter(
                  child: _DiscHeader(
                    disc: section.disc,
                    device: device,
                    theme: theme,
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
                    progress: ref
                        .read(catalogPreviewProvider.notifier)
                        .progress,
                    device: device,
                    theme: theme,
                    edgePadding: edgePadding,
                    onTap: track.hasPreview
                        ? () => unawaited(
                            ref
                                .read(catalogPreviewProvider.notifier)
                                .toggle(track),
                          )
                        : null,
                  );
                },
              ),
            ],
        ],
      ),
    );
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

class _Header extends StatelessWidget {
  const _Header({
    required this.album,
    required this.tracks,
    required this.device,
    required this.theme,
    required this.edgePadding,
  });

  final CatalogAlbum album;
  final List<CatalogTrack> tracks;
  final DeviceType device;
  final ThemeData theme;
  final double edgePadding;

  @override
  Widget build(BuildContext context) {
    final size = device.isDesktop ? 254.0 : (device.isMobile ? 140.0 : 200.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(edgePadding, 8, edgePadding, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _cover(size),
          SizedBox(width: device.isMobile ? 16 : 38),
          Expanded(child: _panel()),
        ],
      ),
    );
  }

  Widget _cover(double size) {
    final cover = album.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: cover == null
          ? Image.asset(Images.album, width: size, height: size)
          : Image(
              image: CachedNetworkImageProvider(cover),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(Images.album, width: size, height: size),
            ),
    );
  }

  Widget _panel() => IconTheme.merge(
    data: const IconThemeData(size: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          album.title,
          style: TextStyle(
            fontSize: device.isMobile ? 18 : 32,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        if (album.artistName case final artist?)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              artist,
              style: TextStyle(
                fontSize: device.isMobile ? 14 : 15,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        _details(),
        if (tracks.any((track) => track.hasPreview))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Tap a song to hear a 30-second preview',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Not in your library',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
            const AddToLidarrButton(),
          ],
        ),
        const SizedBox(height: 10),
        CatalogAttribution(source: album.source, url: album.url),
      ],
    ),
  );

  Widget _details() {
    final total = tracks.fold(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    final year = album.releaseDate?.year;
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tracks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(JPlayer.clock, size: 14),
            ),
            Text(
              [
                if (hours > 0) hours.toString().padLeft(2, '0'),
                minutes.toString().padLeft(2, '0'),
                seconds.toString().padLeft(2, '0'),
              ].join(':'),
            ),
            _dot(),
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(JPlayer.music, size: 14),
            ),
            Text('${tracks.length}'),
          ],
          if (year != null) ...[
            if (tracks.isNotEmpty) _dot(),
            Text(
              '$year',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.circle,
      size: 4,
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
    ),
  );
}

class _DiscHeader extends StatelessWidget {
  const _DiscHeader({
    required this.disc,
    required this.device,
    required this.theme,
    required this.edgePadding,
  });

  final int? disc;
  final DeviceType device;
  final ThemeData theme;
  final double edgePadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(edgePadding, 14, edgePadding, 2),
    child: Text(
      disc != null ? 'Disc $disc' : 'Other',
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: device.isMobile ? 16 : 18,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
      ),
    ),
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
          subtitle: artist == null
              ? null
              : Text(
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
