import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ListenPage extends StatefulWidget {
  const ListenPage({super.key});

  @override
  State<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends State<ListenPage> {
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isTablet ? 360 : 175,
                  mainAxisSpacing: _isMobile ? 15 : 24,
                  crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 24),
                  childAspectRatio: _isTablet ? 360 / 413 : 175 / 206,
                ),
                itemBuilder: (context, index) => _albumView(),
                itemCount: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageViewToggle() => ChipTheme(
        data: ChipTheme.of(context).copyWith(
          labelStyle: TextStyle(fontSize: _isMobile ? 14 : 24),
        ),
        child: Wrap(
          spacing: _isMobile ? 12 : 25,
          children: const [
            Chip(label: Text('Albums')),
            Chip(label: Text('Artists')),
          ],
        ),
      );

  Widget _settingsButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.equalizer),
      );

  Widget _albumView() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red,
              ),
            ),
          ),
          Text(
            'Album name',
            style: TextStyle(
              fontSize: _isTablet ? 24 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
