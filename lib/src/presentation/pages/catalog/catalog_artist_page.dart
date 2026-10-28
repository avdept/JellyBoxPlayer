import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class CatalogArtistPage extends ConsumerStatefulWidget {
  const CatalogArtistPage({required this.artist, super.key});

  final CatalogArtist artist;

  @override
  ConsumerState<CatalogArtistPage> createState() => _CatalogArtistPageState();
}

class _CatalogArtistPageState extends ConsumerState<CatalogArtistPage> {
  static const Map<CatalogReleaseType, String> _sectionLabels = {
    CatalogReleaseType.album: 'Albums',
    CatalogReleaseType.ep: 'EPs',
    CatalogReleaseType.single: 'Singles',
    CatalogReleaseType.compilation: 'Compilations',
  };

  final _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey(debugLabel: 'catalog-artist-title');

  late Size _screenSize;
  late ThemeData _theme;
  late DeviceType _device;

  CatalogArtist get _artist => widget.artist;

  ImageProvider get _picture => switch (_artist.pictureUrl) {
    final url? => CachedNetworkImageProvider(url),
    null => const AssetImage(Images.artistSample),
  };

  double get _horizontalPadding =>
      _device.isMobile ? 16 : (_device.isTablet ? 64 : 40);

  double get _headerHeight =>
      _device.isMobile ? 250 : (_device.isTablet ? 340 : 360);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(_screenSize);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(catalogAlbumsProvider(_artist.key));
    return ScrollablePageScaffold(
      controller: _scrollController,
      slivers: [
        ArtistHeaderAppBar(
          controller: _scrollController,
          titleKey: _titleKey,
          name: _artist.name,
          titleImage: _picture,
          image: ClipOval(
            child: Image(image: _picture, fit: BoxFit.cover),
          ),
          backdrop: _artist.pictureUrl == null
              ? null
              : Opacity(
                  opacity: 0.35,
                  child: BlurredCoverArt(
                    image: _picture,
                    width: _screenSize.width,
                    height: _device.isMobile ? 340 : _headerHeight,
                    blurStart: 0,
                  ),
                ),
          headerHeight: _headerHeight,
          horizontalPadding: _horizontalPadding,
          isMobile: _device.isMobile,
          panel: _headerPanel(),
        ),
        ...albums.when(
          data: (list) => [
            for (final type in CatalogReleaseType.values)
              ..._section(
                type,
                [
                  for (final album in list)
                    if (album.releaseType == type) album,
                ]..sort(newestCatalogAlbumFirst),
              ),
          ],
          error: (error, stackTrace) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  24,
                  _horizontalPadding,
                  0,
                ),
                child: Text(
                  'Could not load albums.',
                  style: TextStyle(
                    color: _theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
          loading: () => [
            SliverToBoxAdapter(
              child: Padding(
                padding: _headingPadding,
                child: SectionHeaderShimmer(
                  height: _device.isMobile ? 20 : 24,
                ),
              ),
            ),
            SliverPadding(
              padding: _gridPadding,
              sliver: AlbumCardsGridShimmer(
                device: _device,
                gridDelegate: _gridDelegate,
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SimilarArtistsRow(
            artists: ref.watch(catalogRelatedArtistsProvider(_artist.key)),
            device: _device,
            horizontalPadding: _horizontalPadding,
            showPlaceholder: true,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _headerPanel() {
    final faded = _theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _artist.name,
                key: _titleKey,
                style: TextStyle(
                  fontSize: _device.isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const AddToLidarrButton(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          [
            if (_artist.fans > 0) '${_formatFans(_artist.fans)} fans',
            'Not in your library',
          ].join(' · '),
          style: TextStyle(fontSize: _device.isMobile ? 14 : 16, color: faded),
        ),
        const SizedBox(height: 10),
        CatalogAttribution(source: _artist.source, url: _artist.url),
      ],
    );
  }

  EdgeInsets get _headingPadding => EdgeInsets.only(
    left: _device.isMobile ? 8 : _horizontalPadding,
    top: 8,
  );

  EdgeInsets get _gridPadding => EdgeInsets.only(
    top: 16,
    right: _device.isMobile ? 16 : _horizontalPadding,
    left: _device.isMobile ? 16 : _horizontalPadding,
    bottom: 16,
  );

  SliverGridDelegate get _gridDelegate =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _device.isMobile ? 200 : 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: _device.isMobile ? 8 : 16,
        childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
      );

  List<Widget> _section(CatalogReleaseType type, List<CatalogAlbum> albums) {
    if (albums.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SectionHeading(
          label: _sectionLabels[type]!,
          fontSize: _device.isMobile ? 20 : 24,
          padding: _headingPadding,
        ),
      ),
      SliverPadding(
        padding: _gridPadding,
        sliver: SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: albums.length,
          itemBuilder: (context, index) => CatalogAlbumCard(
            album: albums[index],
            onTap: () => context.pushNamed(
              branchAwareName(context, Routes.catalogAlbum),
              extra: {'album': albums[index]},
            ),
          ),
        ),
      ),
    ];
  }
}

String _formatFans(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return '$value';
}
