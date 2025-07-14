import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ArtistPage extends ConsumerStatefulWidget {
  const ArtistPage({required this.artist, super.key});
  final ItemDTO artist;

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  final _titleKey = GlobalKey(debugLabel: 'title');
  List<ItemDTO> _albums = [];
  List<ItemDTO> _appearsOn = [];

  late ThemeData _theme;
  late DeviceType _device;

  void _onScroll() {
    final titleContext = _titleKey.currentContext;

    if (titleContext?.mounted ?? false) {
      final scrollPosition = _scrollController.position;
      final scrollableContext = scrollPosition.context.notificationContext!;
      final scrollableRenderBox = scrollableContext.findRenderObject()! as RenderBox;
      final titleRenderBox = titleContext!.findRenderObject()! as RenderBox;
      final titlePosition = titleRenderBox.localToGlobal(
        Offset.zero,
        ancestor: scrollableRenderBox,
      );
      final titleHeight = titleContext.size!.height;
      final visibleFraction = (titlePosition.dy + titleHeight) / titleHeight;
      _titleOpacity.value = 1 - min(max(visibleFraction, 0), 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _getAlbums();
    _getAppearsOn();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _getAppearsOn() async {
    final resp = await ref.read(jellyfinApiProvider).getAlbums(
          userId: ref.read(currentUserProvider)!.userId,
          libraryId: '',
          contributingArtistIds: widget.artist.id,
        );
    setState(() {
      _appearsOn = resp.data.items;
    });
  }

  Future<void> _getAlbums() async {
    final resp = await ref.read(jellyfinApiProvider).getAlbums(
      userId: ref.read(currentUserProvider)!.userId,
      libraryId: '',
      artistIds: [widget.artist.id],
    );
    setState(() {
      _albums = resp.data.items;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  Widget get mobileView {
    return ScrollablePageScaffold(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          title: ValueListenableBuilder(
            valueListenable: _titleOpacity,
            builder: (context, opacity, child) => Transform.translate(
              offset: Offset(0, 8 - 8 * opacity),
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            ),
            child: Text(
              widget.artist.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          floating: true,
          pinned: true,
          // snap: true,
          expandedHeight: 250,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (widget.artist.backgropImageTags.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -60,
                    height: 340,
                    child: _headerImage(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 60),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          key: _titleKey,
                                          widget.artist.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      _playButton(),
                                    ],
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(fontSize: 14),
                                    child: _infoText(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._albumsWidgets(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_device.isMobile) {
      return mobileView;
    }
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
                top: _device.isMobile ? -60 : 0,
                height: 340,
                child: _headerImage(),
              ),
            const Positioned(top: 4, left: 10, child: BackButton()),
            Padding(
              padding: EdgeInsets.only(
                left: _device.isMobile ? 20 : (_device.isTablet ? 64 : 40),
                top: _device.isMobile ? 60 : (_device.isTablet ? 140 : 238),
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height - 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            padding: EdgeInsets.symmetric(
                              horizontal: _device.isMobile ? 16 : (_device.isTablet ? 64 : 40),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.artist.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _playButton(),
                                  ],
                                ),
                                DefaultTextStyle(
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: _theme.textTheme.bodySmall?.color,
                                    fontSize: _device.isMobile ? 14 : 16,
                                  ),
                                  child: _infoText(),
                                ),
                                if (!_device.isMobile)
                                  SizedBox(
                                    height: MediaQuery.sizeOf(context).height - 323,
                                    child: SizedBox(height: double.infinity, child: _albumsList()),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
            image: ref.read(imageServiceProvider).backdropIp(
                  tagId: widget.artist.backgropImageTags.firstOrNull,
                  id: widget.artist.id,
                ),
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

  Widget _mainImage() => Image(
        image: ref.read(imageServiceProvider).albumIP(
              tagId: widget.artist.imageTags['Primary'],
              id: widget.artist.id,
            ),
        width: 500,
      );

  Widget _infoText() => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          widget.artist.overview ?? 'This artist does not have any information.',
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: _theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            height: 1.2,
          ),
        ),
      );

  Widget _playButton() => SizedBox(
        height: 48,
        child: PlayButton(onPressed: () {}),
      );

  List<Widget> _albumsWidgets() {
    return [
      if (_albums.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Text(
              'Albums',
              style: TextStyle(
                fontSize: _device.isMobile ? 20 : 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16,
            right: _device.isMobile ? 16 : 0,
            left: _device.isMobile ? 16 : 0,
            bottom: 16,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _device.isMobile ? 200 : 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: _device.isMobile ? 8 : 16,
              childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
            ),
            itemBuilder: (context, index) => AlbumView(
              showArtist: false,
              album: _albums[index],
              onTap: (album) {
                final location = GoRouterState.of(context).fullPath;
                context.go(
                  '$location${Routes.album}',
                  extra: {
                    'album': album,
                    'artist': widget.artist,
                  },
                );
              },
              mainTextStyle: TextStyle(fontSize: _device.isMobile ? 16 : 14),
              subTextStyle: const TextStyle(fontSize: 14),
            ),
            itemCount: _albums.length,
          ),
        ),
      ],
      if (_appearsOn.isNotEmpty)
        SliverToBoxAdapter(
          child: Text(
            'Appears On',
            style: TextStyle(
              fontSize: _device.isMobile ? 20 : 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.only(
          top: 16,
          right: _device.isMobile ? 16 : (_device.isTablet ? 64 : 60),
          bottom: 16,
        ),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _device.isMobile ? 175 : 220,
            mainAxisSpacing: _device.isTablet ? 24 : 12,
            crossAxisSpacing: _device.isMobile ? 8 : 16,
            childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
          ),
          itemBuilder: (context, index) => AlbumView(
            showArtist: false,
            album: _appearsOn[index],
            onTap: (album) {
              final location = GoRouterState.of(context).fullPath;
              context.go(
                '$location${Routes.album}',
                extra: {
                  'album': album,
                  'artist': widget.artist,
                },
              );
            },
            mainTextStyle: TextStyle(fontSize: _device.isMobile ? 16 : 14),
            subTextStyle: const TextStyle(fontSize: 14),
          ),
          itemCount: _appearsOn.length,
        ),
      ),
    ];
  }

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
            ..._albumsWidgets()
          ],
        ),
      );
}
