import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchFieldController = TextEditingController();

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  void _onArtistTap() {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.album}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isTablet = deviceType == DeviceScreenType.tablet;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: _isMobile ? 16 : 30,
                  top: _isMobile ? 0 : 3.5,
                  right: _isMobile ? 16 : 30,
                  bottom: _isMobile ? 22 : 32,
                ),
                child: Flex(
                  direction: _isMobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: _isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _titleText(),
                    SizedBox(
                      width: _isTablet ? 36 : 44,
                      height: 14,
                    ),
                    if (_isMobile)
                      _searchField()
                    else
                      Expanded(child: _searchField()),
                  ],
                ),
              ),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: CustomScrollView(
                    slivers: [
                      SliverList.separated(
                        itemBuilder: (context, index) => _artistView(),
                        separatorBuilder: (context, index) => SizedBox(
                          height: _isMobile ? 12 : 24,
                        ),
                        itemCount: 1,
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _isMobile ? 28 : (_isTablet ? 30 : 40),
                        ),
                      ),
                      SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              _isDesktop ? 360 : _screenSize.width,
                          mainAxisExtent: _isMobile ? 54 : 74,
                          crossAxisSpacing: 70,
                        ),
                        itemBuilder: (context, index) => _songView(),
                        itemCount: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    super.dispose();
  }

  Widget _titleText() => Text(
        'Search',
        style: TextStyle(
          fontSize: _isMobile ? 24 : 36,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  Widget _searchField() => TextField(
        controller: _searchFieldController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          height: 1.2,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.24),
          isDense: true,
          contentPadding: const EdgeInsets.all(9),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(40),
          ),
          prefixIcon: const Icon(JPlayer.search),
          suffixIcon: IconButton(
            onPressed: _searchFieldController.clear,
            padding: EdgeInsets.zero,
            icon: const Icon(JPlayer.close),
          ),
        ),
      );

  Widget _artistView() => GestureDetector(
        onTap: _onArtistTap,
        behavior: HitTestBehavior.opaque,
        child: SimpleListTile(
          padding: EdgeInsets.symmetric(
            // vertical: _isMobile ? 6 : 12,
            horizontal: _isMobile ? 16 : 30,
          ),
          leading: Ink.image(
            image: const AssetImage(Images.artistSample),
            width: _isMobile ? 42 : 80,
            height: _isMobile ? 42 : 80,
          ),
          title: Text(
            'Rihanna',
            style: TextStyle(
              fontSize: _isTablet ? 20 : 16,
              height: 1.2,
              color: _theme.colorScheme.onPrimary,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          subtitle: Text(
            'Artist',
            style: TextStyle(
              fontSize: _isTablet ? 16 : 12,
              height: 1.2,
              color: _theme.colorScheme.onPrimary.withOpacity(0.61),
            ),
          ),
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(JPlayer.chevron_right),
          ),
          leadingToTitle: _isMobile ? 6 : (_isTablet ? 16 : 20),
        ),
      );

  Widget _songView() => GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: SimpleListTile(
          padding: EdgeInsets.symmetric(
            vertical: _isMobile ? 6 : 12,
            horizontal: _isMobile ? 16 : 30,
          ),
          leading: Ink.image(
            image: const AssetImage(Images.songSample),
            width: _isMobile ? 42 : 50,
            height: _isMobile ? 42 : 50,
          ),
          title: Text(
            'Song name',
            style: TextStyle(
              fontSize: _isTablet ? 20 : 16,
              height: 1.2,
              color: _theme.colorScheme.onPrimary,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          subtitle: Text(
            'Song',
            style: TextStyle(
              fontSize: _isTablet ? 16 : 12,
              height: 1.2,
              color: _theme.colorScheme.onPrimary.withOpacity(0.61),
            ),
          ),
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(JPlayer.more_horizontal),
          ),
          leadingToTitle: _isMobile ? 6 : 16,
        ),
      );
}
