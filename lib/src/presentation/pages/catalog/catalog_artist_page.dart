import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class CatalogArtistPage extends ConsumerWidget {
  const CatalogArtistPage({required this.artist, super.key});

  final CatalogArtist artist;

  static const Map<CatalogReleaseType, String> _sectionLabels = {
    CatalogReleaseType.album: 'Albums',
    CatalogReleaseType.ep: 'EPs',
    CatalogReleaseType.single: 'Singles',
    CatalogReleaseType.compilation: 'Compilations',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final padding = device.isMobile ? 16.0 : 30.0;
    final albums = ref.watch(catalogAlbumsProvider(artist.key));
    final gridDelegate = AlbumCardMetrics.gridDelegate(device);

    return Scaffold(
      body: ScrollablePageScaffold(
        useGradientBackground: true,
        navigationBar: CatalogNavigationBar(title: artist.name, device: device),
        contentPadding: EdgeInsets.only(
          left: padding,
          right: padding,
          bottom: 30,
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(artist: artist, device: device, theme: theme),
          ),
          ...albums.when(
            data: (list) => [
              for (final type in CatalogReleaseType.values)
                ..._section(
                  type,
                  [
                    for (final album in list)
                      if (album.releaseType == type) album,
                  ],
                  device,
                  gridDelegate,
                ),
            ],
            error: (error, stackTrace) => [
              SliverToBoxAdapter(
                child: _message('Could not load albums.', theme),
              ),
            ],
            loading: () => [
              AlbumCardsGridShimmer(device: device, gridDelegate: gridDelegate),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SimilarArtistsRow(
                artists: ref.watch(catalogRelatedArtistsProvider(artist.key)),
                device: device,
                showPlaceholder: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
    CatalogReleaseType type,
    List<CatalogAlbum> albums,
    DeviceType device,
    SliverGridDelegate gridDelegate,
  ) {
    if (albums.isEmpty) return const [];
    return [
      _heading(_sectionLabels[type]!, device),
      SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: albums.length,
        itemBuilder: (context, index) => CatalogAlbumCard(
          album: albums[index],
          onTap: () => context.pushNamed(
            branchAwareName(context, Routes.catalogAlbum),
            extra: {'album': albums[index]},
          ),
        ),
      ),
    ];
  }

  Widget _heading(String label, DeviceType device) => SliverPadding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    sliver: SliverToBoxAdapter(
      child: Text(
        label,
        style: TextStyle(
          fontSize: device.isMobile ? 20 : 24,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _message(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Text(
      text,
      style: TextStyle(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.artist,
    required this.device,
    required this.theme,
  });

  final CatalogArtist artist;
  final DeviceType device;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final size = device.isMobile ? 120.0 : 180.0;
    final picture = artist.pictureUrl;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ClipOval(
            child: picture == null
                ? Image.asset(Images.artistSample, width: size, height: size)
                : Image(
                    image: CachedNetworkImageProvider(picture),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      Images.artistSample,
                      width: size,
                      height: size,
                    ),
                  ),
          ),
          SizedBox(width: device.isMobile ? 16 : 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: TextStyle(
                    fontSize: device.isMobile ? 22 : 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      [
                        if (artist.fans > 0) '${_formatFans(artist.fans)} fans',
                        'Not in your library',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const AddToLidarrButton(),
                  ],
                ),
                const SizedBox(height: 10),
                CatalogAttribution(source: artist.source, url: artist.url),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CatalogNavigationBar({
    required this.title,
    required this.device,
    super.key,
  });

  final String title;
  final DeviceType device;

  @override
  Size get preferredSize => Size.fromHeight(device.isMobile ? 60 : 100);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: device.isMobile ? 16 : 30),
      child: Row(
        children: [
          CupertinoNavigationBarBackButton(
            color: theme.colorScheme.onPrimary,
            onPressed: () => context.pop(),
          ),
          SizedBox(width: device.isMobile ? 12 : 20),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: device.isMobile ? 18 : 24,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatFans(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return '$value';
}
