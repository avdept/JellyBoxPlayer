import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ListenPage extends StatefulWidget {
  const ListenPage({super.key});

  @override
  State<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends State<ListenPage> {
  late final ValueNotifier<ListenView> _currentView;
  late final Map<Entities, bool> _availableFilters;
  late final ValueNotifier<Filter> _appliedFilter;
  final _filterOpened = ValueNotifier<bool>(false);

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;

  Map<ListenView, String> get _viewLabels => {
        ListenView.albums: 'Albums',
        ListenView.artists: 'Artists',
      };

  Map<Entities, String> get _filtersLabels => {
        Entities.albums: 'Albums',
        Entities.artists: 'Artists',
        Entities.playlists: 'Playlists',
        Entities.songs: 'Songs',
        Entities.genres: 'Genres',
      };

  void _onAlbumTap() {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.album}');
  }

  @override
  void initState() {
    super.initState();
    _currentView = ValueNotifier(ListenView.values.first);
    _availableFilters = {
      for (final value in Entities.values) value: false,
    };
    _appliedFilter = ValueNotifier(Filter(orderBy: Entities.values.first));
  }

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
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(_isMobile ? 16 : 30),
                child: Row(
                  children: [
                    _pageViewToggle(),
                    const Spacer(),
                    _filterButton(),
                  ],
                ),
              ),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ValueListenableBuilder(
                    valueListenable: _currentView,
                    builder: (context, currentView, child) => GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isMobile ? 16 : 30,
                      ),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: _isTablet ? 360 : 175,
                        mainAxisSpacing: _isMobile ? 15 : 24,
                        crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 24),
                        childAspectRatio: _isTablet ? 360 / 413 : 175 / 206.7,
                      ),
                      itemBuilder: (context, index) => AlbumView(
                        name: 'Album name',
                        onTap: _onAlbumTap,
                      ),
                      itemCount: 20,
                    ),
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
    _currentView.dispose();
    _appliedFilter.dispose();
    _filterOpened.dispose();
    super.dispose();
  }

  Widget _pageViewToggle() => ChipTheme(
        data: ChipTheme.of(context).copyWith(
          labelStyle: TextStyle(fontSize: _isMobile ? 14 : 24),
        ),
        child: Wrap(
          spacing: _isMobile ? 12 : 25,
          children: [
            for (final value in ListenView.values)
              ValueListenableBuilder(
                valueListenable: _currentView,
                builder: (context, currentView, child) => ActionChip(
                  label: Text(_viewLabels[value] ?? '???'),
                  backgroundColor: (value == currentView)
                      ? _theme.chipTheme.selectedColor
                      : _theme.chipTheme.backgroundColor,
                  onPressed: () => _currentView.value = value,
                ),
              ),
          ],
        ),
      );

  Widget _filterButton() => DropdownButtonHideUnderline(
        child: ValueListenableBuilder(
          valueListenable: _appliedFilter,
          builder: (context, filter, child) => DropdownButton2<Entities>(
            customButton: Padding(
              padding: const EdgeInsets.all(8),
              child: ValueListenableBuilder(
                valueListenable: _filterOpened,
                builder: (context, isOpened, child) => Icon(
                  JPlayer.sliders,
                  color: isOpened
                      ? _theme.colorScheme.primary
                      : _theme.iconTheme.color,
                ),
              ),
            ),
            buttonStyleData: const ButtonStyleData(
              overlayColor: MaterialStatePropertyAll(Colors.transparent),
            ),
            dropdownStyleData: DropdownStyleData(
              width: 150,
              padding: const EdgeInsets.all(8),
              offset: const Offset(0, -8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            items: [
              for (final value in Entities.values)
                DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _filtersLabels[value] ?? '???',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: (filter.orderBy == value)
                                ? _theme.colorScheme.primary
                                : _theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        _availableFilters[value]!
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: (filter.orderBy == value)
                            ? _theme.colorScheme.primary
                            : _theme.colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
            ],
            value: filter.orderBy,
            onChanged: (value) {
              if (filter.orderBy == value) {
                final desc = !filter.desc;
                _appliedFilter.value = filter.copyWith(desc: desc);
                _availableFilters[value!] = desc;
              } else {
                _appliedFilter.value = Filter(
                  orderBy: value!,
                  desc: _availableFilters[value]!,
                );
              }
            },
            onMenuStateChange: (value) => _filterOpened.value = value,
          ),
        ),
      );
}
