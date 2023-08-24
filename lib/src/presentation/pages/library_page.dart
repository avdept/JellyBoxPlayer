import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _scrollController = ScrollController();

  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  void _onLibraryTap() => context.go(Routes.listen);

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: _isMobile ? 12 : 30,
                horizontal: _isMobile ? 16 : 30,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: _isDesktop ? 22.5 : 13,
                  ),
                  const SizedBox(width: 10),
                  _titleText(),
                  const Spacer(),
                  _searchButton(),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollbar(
                controller: _scrollController,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: _isMobile ? 16 : 30,
                    right: _isMobile ? 16 : 30,
                    bottom: _isMobile ? 8 : 20,
                  ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _isTablet ? 370 : 358,
                    mainAxisSpacing: _isMobile ? 13 : 34,
                    crossAxisSpacing: _isDesktop ? 24 : (_isMobile ? 16 : 34),
                    childAspectRatio: 370 / 255,
                  ),
                  itemBuilder: (context, index) => LibraryView(
                    name: 'Library name',
                    onTap: _onLibraryTap,
                  ),
                  itemCount: 20,
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

  Widget _titleText() => const Text(
        'Your library',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  Widget _searchButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.search),
      );
}
