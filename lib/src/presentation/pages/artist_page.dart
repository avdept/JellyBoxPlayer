import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ArtistPage extends ConsumerStatefulWidget {
  const ArtistPage({required this.artist, super.key});
  final ItemDTO artist;

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final _scrollController = ScrollController();

  late ModalRoute<dynamic>? _parentRoute;
  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  List<ItemDTO> _albums = [];
  List<ItemDTO> _appearsOn = [];

  @override
  void initState() {
    super.initState();
    _getAlbums();
    _getAppearsOn();
  }

  Future<void> _getAppearsOn() async {
    final resp =
        await ref.read(jellyfinApiProvider).getAlbums(userId: ref.read(currentUserProvider)!.userId, libraryId: '', contributingArtistIds: widget.artist.id);
    setState(() {
      _appearsOn = resp.data.items;
    });
  }

  Future<void> _getAlbums() async {
    final resp = await ref.read(jellyfinApiProvider).getAlbums(userId: ref.read(currentUserProvider)!.userId, libraryId: '', artistIds: [widget.artist.id]);
    setState(() {
      _albums = resp.data.items;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parentRoute = ModalRoute.of(context);
    _theme = Theme.of(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isTablet = deviceType == DeviceScreenType.tablet;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        left: false,
        right: false,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            if (widget.artist.backgropImageTags.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: _isMobile ? -60 : 0,
                height: 340,
                child: _headerImage(),
              ),
            const Positioned(top: 4, left: 10, child: BackButton()),
            Padding(
              padding: EdgeInsets.only(left: _isMobile ? 20 : (_isTablet ? 64 : 40), top: _isMobile ? 60 : (_isTablet ? 140 : 238)),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _mainImage(),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _isMobile ? 16 : (_isTablet ? 64 : 40),
                            right: _isMobile ? 16 : (_isTablet ? 64 : 40),
                          ),
                          child: SizedBox(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.artist.name,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                    ),
                                    _playButton(),
                                  ],
                                ),
                                DefaultTextStyle(
                                  style: TextStyle(fontSize: _isMobile ? 14 : 16),
                                  child: _infoText(),
                                ),
                                if (!_isMobile) SizedBox(height: MediaQuery.of(context).size.height - 400, child: _albumsList())
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  if (_isMobile) Expanded(child: _albumsList()),
                ],

              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _headerImage() => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ref
                .read(imageProvider)
                .backdropIp(tagId: widget.artist.backgropImageTags.isNotEmpty ? widget.artist.backgropImageTags.first : null, id: widget.artist.id),
            fit: BoxFit.fitWidth,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _theme.scaffoldBackgroundColor.withOpacity(0),
              _theme.scaffoldBackgroundColor.withOpacity(1),
            ],
          ),
        ),
      );

  Widget _mainImage() => Image(image: ref.read(imageProvider).albumIP(tagId: widget.artist.imageTags["Primary"], id: widget.artist.id), width: 500);

  Widget _infoText() => Padding(
        padding: EdgeInsets.only(top: widget.artist.overview != null && widget.artist.overview!.isNotEmpty ? 20 : 0),
        child: Text(widget.artist.overview ?? '',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: _isMobile ? 14 : 14,
                  height: 1.2,
                )),
      );

  Widget _playButton() => SizedBox(
        height: 48,
        child: PlayButton(
          onPressed: () {},
        ),
      );

  Widget _albumsList() => CustomScrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPinnedHeader(
              child: SizedBox.fromSize(
                size: const Size.fromHeight(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _theme.scaffoldBackgroundColor.withOpacity(1),
                        _theme.scaffoldBackgroundColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_albums.isNotEmpty)
            SliverToBoxAdapter(
              child: Text(
                'Albums',
                style: TextStyle(
                  fontSize: _isMobile ? 20 : 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_albums.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 16,
                  right: _isMobile ? 16 : (_isTablet ? 64 : 60),
                  bottom: 16,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _isMobile ? 200 : 220,
                    mainAxisSpacing: _isTablet ? 24 : 12,
                    crossAxisSpacing: _isMobile ? 8 : 16,
                    childAspectRatio: _isMobile ? 175 / 225 : 120 / 163,
                  ),
                  itemBuilder: (context, index) => AlbumView(
                    showArtist: false,
                    album: _albums[index],
                    onTap: () {
                      final location = GoRouterState.of(context).fullPath;
                      context.go('$location${Routes.album}', extra: {'album': _albums[index], 'artist': widget.artist});
                    },
                    mainTextStyle: TextStyle(fontSize: _isMobile ? 16 : 14),
                    subTextStyle: const TextStyle(fontSize: 14),
                  ),
                  itemCount: _albums.length,
                ),
              ),
            if (_appearsOn.isNotEmpty)
              SliverToBoxAdapter(
                child: Text(
                  'Appears On',
                  style: TextStyle(
                    fontSize: _isMobile ? 20 : 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                top: 16,
                right: _isMobile ? 16 : (_isTablet ? 64 : 60),
                bottom: 16,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isMobile ? 175 : 220,
                  mainAxisSpacing: _isTablet ? 24 : 12,
                  crossAxisSpacing: _isMobile ? 8 : 16,
                  childAspectRatio: _isMobile ? 175 / 225 : 120 / 163,
                ),
                itemBuilder: (context, index) => AlbumView(
                  showArtist: false,
                  album: _appearsOn[index],
                  onTap: () {
                    final location = GoRouterState.of(context).fullPath;
                    context.go('$location${Routes.album}', extra: {'album': _appearsOn[index], 'artist': widget.artist});
                  },
                  mainTextStyle: TextStyle(fontSize: _isMobile ? 16 : 14),
                  subTextStyle: const TextStyle(fontSize: 14),
                ),
                itemCount: _appearsOn.length,
              ),
            ),
          ],
        ),
      );
}
