import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchFieldController = TextEditingController();
  final _scrollController = ScrollController();

  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                  top: _isDesktop ? 30 : (_isMobile ? 0 : 3.5),
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
                child: CustomScrollbar(
                  controller: _scrollController,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isMobile ? 16 : 30,
                        ),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) => SingerView(
                            name: 'Rihanna',
                            onTap: () {},
                          ),
                          separatorBuilder: (context, index) => SizedBox(
                            height: _isMobile ? 12 : 24,
                          ),
                          itemCount: 1,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: _isMobile ? 16 : 30,
                          top: _isDesktop ? 40 : (_isMobile ? 28 : 30),
                          right: _isMobile ? 16 : 30,
                          bottom: _isDesktop ? 30 : 16,
                        ),
                        sliver: SliverGrid.builder(
                          gridDelegate: _isDesktop
                              ? const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 360,
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 70,
                                  mainAxisExtent: 50,
                                )
                              : SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisSpacing: _isMobile ? 12 : 24,
                                  mainAxisExtent: _isMobile ? 42 : 50,
                                ),
                          itemBuilder: (context, index) => SongView(
                            name: 'Song name',
                            onTap: () {},
                            onOptionsPressed: () {},
                          ),
                          itemCount: 50,
                        ),
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
    _scrollController.dispose();
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
}
