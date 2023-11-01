import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final _scrollController = ScrollController();

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;

  static final _testItems = List.generate(
    40,
    (index) => ItemDTO(
      id: index.toString(),
      name: 'Album ${index + 1}',
      albumArtist: 'Artist',
      serverId: '',
      durationInTicks: 0,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: 346,
              child: Stack(
                alignment: Alignment.centerRight,
                clipBehavior: Clip.none,
                children: [
                  Transform.scale(
                    scale: _isMobile ? 1.55 : 1,
                    child: _headerImage(),
                  ),
                  Positioned(
                    left: _isMobile ? 20 : (_isTablet ? 64 : 40),
                    bottom: _isMobile ? -60 : (_isTablet ? -140 : -238),
                    width: _isMobile ? 211 : (_isTablet ? 313 : 423),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _mainImage(),
                    ),
                  ),
                  Positioned.fill(
                    left: _isMobile ? 20 : (_isTablet ? 392 : 480),
                    right: _isMobile ? 13 : (_isTablet ? 18 : 50),
                    bottom: _isMobile ? 187 : (_isTablet ? 25 : 36),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: DefaultTextStyle(
                        style: TextStyle(fontSize: _isMobile ? 14 : 16),
                        child: _infoText(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: _isMobile ? -8 : 16,
                    bottom: _isMobile ? 16 : null,
                    height: _isMobile ? 40 : 60,
                    child: _playButton(),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 4,
              top: 2,
              child: BackButton(),
            ),
            Positioned.fill(
              left: _isMobile ? 16 : (_isTablet ? 64 : 480),
              top: _isMobile ? 412 : (_isTablet ? 496 : 358),
              child: _albumsList(),
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.artistLargeSample),
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

  Widget _mainImage() => Image.asset(Images.artistLargeSample);

  Widget _infoText() => const Text(
        'Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut alUt enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut alUt enim ad minima veniam, quis nostrum exercitationem ullam corporis ',
      );

  Widget _playButton() => PlayButton(
        onPressed: () {},
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
            SliverToBoxAdapter(
              child: Text(
                'Albums',
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
                  maxCrossAxisExtent: _isMobile ? 175 : 120,
                  mainAxisSpacing: _isTablet ? 24 : 12,
                  crossAxisSpacing: _isMobile ? 8 : 16,
                  childAspectRatio: _isMobile ? 175 / 225 : 120 / 163,
                ),
                itemBuilder: (context, index) => AlbumView(
                  album: _testItems[index],
                  mainTextStyle: TextStyle(fontSize: _isMobile ? 16 : 14),
                  subTextStyle: const TextStyle(fontSize: 14),
                ),
                itemCount: _testItems.length,
              ),
            ),
          ],
        ),
      );
}
