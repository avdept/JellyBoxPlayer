import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ListenPage extends StatefulWidget {
  const ListenPage({super.key});

  @override
  State<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends State<ListenPage> {
  final _currentView = ValueNotifier<ListenView>(ListenView.albums);

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;

  Set<(String, VoidCallback)> get _viewToggle => {
        ('Albums', () => _currentView.value = ListenView.albums),
        ('Artists', () => _currentView.value = ListenView.artists),
      };

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
        minimum: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 30),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: _isMobile ? 16 : 30),
              child: Row(
                children: [
                  _pageViewToggle(),
                  const Spacer(),
                  _settingsButton(),
                ],
              ),
            ),
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _isTablet ? 360 : 175,
                    mainAxisSpacing: _isMobile ? 15 : 24,
                    crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 24),
                    childAspectRatio: _isTablet ? 360 / 413 : 175 / 206.7,
                  ),
                  itemBuilder: (context, index) => _albumView(),
                  itemCount: 10,
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
    _currentView.dispose();
    super.dispose();
  }

  Widget _pageViewToggle() => ChipTheme(
        data: ChipTheme.of(context).copyWith(
          labelStyle: TextStyle(fontSize: _isMobile ? 14 : 24),
        ),
        child: Wrap(
          spacing: _isMobile ? 12 : 25,
          children: List.generate(
            _viewToggle.length,
            (index) => ValueListenableBuilder(
              valueListenable: _currentView,
              builder: (context, currentView, child) => ActionChip(
                label: Text(_viewToggle.elementAt(index).$1),
                backgroundColor: (index == currentView.index)
                    ? _theme.chipTheme.selectedColor
                    : _theme.chipTheme.backgroundColor,
                onPressed: _viewToggle.elementAt(index).$2,
              ),
            ),
          ),
        ),
      );

  Widget _settingsButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.equalizer),
      );

  Widget _albumView() => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage(Images.albumSample),
                  ),
                ),
              ),
            ),
            Text(
              'Album name',
              style: TextStyle(
                fontSize: _isTablet ? 24 : 16,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ],
        ),
      );
}
