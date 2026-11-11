import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/artist_avatar_card.dart';
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
    this.title = 'Similar artists',
    this.titleFontSize,
    this.horizontalPadding = 0,
    this.showPlaceholder = false,
    super.key,
  });

  final AsyncValue<List<SimilarArtist>> artists;
  final DeviceType device;
  final String title;
  final double? titleFontSize;
  final double horizontalPadding;
  final bool showPlaceholder;

  double get _avatarSize => ArtistAvatarCard.avatarSize(device);

  @override
  Widget build(BuildContext context) {
    final list = artists.valueOrNull ?? const [];
    final loading = showPlaceholder && artists.isLoading;
    if (list.isEmpty && !loading) return const SizedBox.shrink();

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
            title,
            style: TextStyle(
              fontSize: titleFontSize ?? (device.isMobile ? 20 : 24),
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
            height: ArtistAvatarCard.cardHeight(_avatarSize),
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

class _ArtistCard extends ConsumerWidget {
  const _ArtistCard({
    required this.artist,
    required this.size,
    required this.onTap,
  });

  final SimilarArtist artist;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picture = artist.artist.pictureUrl;
    final owned = artist.owned;
    final target = owned == null ? LidarrArtistTarget(artist.artist) : null;
    final lidarr = target != null && ref.watch(lidarrAvailableProvider);
    return ArtistAvatarCard(
      name: artist.artist.name,
      size: size,
      image: picture == null ? null : CachedNetworkImageProvider(picture),
      subtitle: owned != null ? 'In your library' : null,
      badge: owned == null
          ? CatalogSourceBadge(
              source: artist.artist.source,
              size: max(22, size * 0.22),
            )
          : null,
      onTap: onTap,
      optionsBuilder: lidarr
          ? (context) => catalogItemActions(context, target)
          : null,
    );
  }
}
