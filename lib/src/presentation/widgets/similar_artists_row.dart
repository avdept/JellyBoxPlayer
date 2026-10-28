import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/catalog_actions.dart';
import 'package:jplayer/src/presentation/widgets/catalog_source_badge.dart';
import 'package:jplayer/src/presentation/widgets/horizontal_scroll_region.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

void openSimilarArtist(BuildContext context, SimilarArtist artist) {
  final owned = artist.owned;
  if (owned != null) {
    unawaited(
      context.pushNamed(
        branchAwareName(context, Routes.artist),
        extra: {'artist': owned},
      ),
    );
  } else {
    unawaited(
      context.pushNamed(
        branchAwareName(context, Routes.catalogArtist),
        extra: {'artist': artist.artist},
      ),
    );
  }
}

class SimilarArtistsRow extends StatelessWidget {
  const SimilarArtistsRow({
    required this.artists,
    required this.device,
    this.horizontalPadding = 0,
    this.showPlaceholder = false,
    super.key,
  });

  final AsyncValue<List<SimilarArtist>> artists;
  final DeviceType device;
  final double horizontalPadding;
  final bool showPlaceholder;

  double get _avatarSize => AlbumCardMetrics.carouselWidth(device) * 0.8;

  @override
  Widget build(BuildContext context) {
    final list = artists.valueOrNull ?? const [];
    final loading = showPlaceholder && artists.isLoading;
    if (list.isEmpty && !loading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final spacing = AlbumCardMetrics.carouselSpacing(device);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            12,
          ),
          child: Text(
            'Similar artists',
            style: TextStyle(
              fontSize: device.isMobile ? 20 : 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (loading)
          ArtistCardsRowShimmer(
            size: _avatarSize,
            device: device,
            horizontalPadding: horizontalPadding,
          )
        else
          SizedBox(
            height: _avatarSize + 52,
            child: HorizontalScrollRegion(
              controlsHeight: _avatarSize,
              controlsInset: horizontalPadding / 2,
              builder: (context, controller) => ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: list.length,
                separatorBuilder: (context, index) => SizedBox(width: spacing),
                itemBuilder: (context, index) => _ArtistCard(
                  artist: list[index],
                  size: _avatarSize,
                  theme: theme,
                  onTap: () => openSimilarArtist(context, list[index]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({
    required this.artist,
    required this.size,
    required this.theme,
    required this.onTap,
  });

  final SimilarArtist artist;
  final double size;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picture = artist.artist.pictureUrl;
    return CatalogContextMenuRegion(
      onTap: onTap,
      enabled: artist.owned == null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: size,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: Image(
                      image: picture == null
                          ? const AssetImage(Images.artistSample)
                          : CachedNetworkImageProvider(picture),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        Images.artistSample,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (artist.owned == null)
                    Positioned(
                      top: size * 0.04,
                      right: size * 0.04,
                      child: CatalogSourceBadge(
                        source: artist.artist.source,
                        size: max(22, size * 0.22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                artist.artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (artist.owned != null)
                Text(
                  'In your library',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
