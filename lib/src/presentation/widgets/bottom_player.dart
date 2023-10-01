import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:responsive_builder/responsive_builder.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final _imageProvider = ValueNotifier<ImageProvider?>(null);
  final _dynamicColors = ValueNotifier<ColorScheme?>(null);
  final _playProgress = ValueNotifier<double>(0.6);
  final _isPlaying = ValueNotifier<bool>(false);
  final _randomQueue = ValueNotifier<bool>(false);
  final _repeatTrack = ValueNotifier<bool>(false);
  final _likeTrack = ValueNotifier<bool>(false);
  final _sliderKey = GlobalKey(debugLabel: 'slider');

  late ThemeData _theme;
  late MaterialLocalizations _localizations;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  Future<void> _onExpand() => Navigator.of(context, rootNavigator: true).push(
        ModalSheetRoute(
          builder: (context) => SafeArea(
            top: false,
            minimum: EdgeInsets.only(
              left: 30,
              top: _isMobile ? 0 : 20,
              right: 30,
              bottom: _isMobile ? 20 : 60,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 518),
              child: ValueListenableBuilder(
                valueListenable: _dynamicColors,
                builder: (context, colorScheme, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: colorScheme),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 444),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ValueListenableBuilder(
                                  valueListenable: _imageProvider,
                                  builder: (context, image, child) =>
                                      (image == null)
                                          ? const SizedBox.shrink()
                                          : Image(
                                              image: image,
                                              fit: BoxFit.cover,
                                            ),
                                ),
                              ),
                            ),
                            SizedBox(height: _isMobile ? 6 : 18),
                            IconTheme(
                              data: _theme.iconTheme.copyWith(
                                size: _isMobile ? 28 : 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _openListButton(),
                                  _randomQueueButton(),
                                  _repeatTrackButton(),
                                  _downloadTrackButton(),
                                  _likeTrackButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _isMobile ? 30 : 26),
                      Text(
                        'Song Title',
                        style: TextStyle(
                          fontSize: _isMobile ? 30 : 40,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        'Artist',
                        style: TextStyle(
                          fontSize: _isMobile ? 18 : 24,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: _isMobile ? 17 : 0),
                      Text(
                        'FLAC 44.1Khz/1080Kbps',
                        style: TextStyle(
                          fontSize: _isMobile ? 14 : 18,
                          color: colorScheme?.onPrimary,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: _isMobile ? 15 : 21),
                      Container(
                        width: double.infinity,
                        height: _isMobile ? 78 : 120,
                        color: colorScheme?.primary,
                      ),
                      SizedBox(height: _isMobile ? 23 : 56),
                      IconTheme(
                        data: _theme.iconTheme.copyWith(
                          size: _isMobile ? 37 : 46,
                        ),
                        child: Wrap(
                          spacing: _isMobile ? 40 : 24,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _prevTrackButton(),
                            SizedBox.square(
                              dimension: _isMobile ? 68 : 84,
                              child: _playPauseButton(),
                            ),
                            _nextTrackButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          containerBuilder: (context, animation, child) => LayoutBuilder(
            builder: (context, constraints) => ValueListenableBuilder(
              valueListenable: _dynamicColors,
              builder: (context, colorScheme, child) => BottomSheet(
                animationController: _animationController,
                onClosing: () {},
                enableDrag: false,
                showDragHandle: true,
                dragHandleSize: const Size(113, 10),
                backgroundColor: colorScheme?.background,
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.92,
                  minWidth: constraints.maxWidth,
                ),
                builder: (context) => child!,
              ),
              child: child,
            ),
          ),
          bounce: true,
          expanded: false,
          barrierLabel: _localizations.modalBarrierDismissLabel,
          duration: const Duration(milliseconds: 300),
        ),
      );

  Future<void> _onImageProviderChanged() async {
    final imageProvider = _imageProvider.value;

    if (imageProvider != null && mounted) {
      _dynamicColors.value = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: _theme.brightness,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = BottomSheet.createAnimationController(this);
    _imageProvider.addListener(_onImageProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _imageProvider.value = const AssetImage(Images.songSample),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _localizations = MaterialLocalizations.of(context);
    _viewPadding = MediaQuery.viewPaddingOf(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: (_isMobile ? 69 : 92) + _viewPadding.bottom,
          color: _theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75),
          padding: EdgeInsets.only(bottom: _viewPadding.bottom),
          child: GestureDetector(
            onTap: !_isDesktop ? _onExpand : null,
            behavior: HitTestBehavior.opaque,
            child: SimpleListTile(
              padding: const EdgeInsets.only(right: 8),
              leading: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  Images.songSample,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                'Chaff & Dust',
                style: TextStyle(
                  fontSize: _isMobile ? 18 : 24,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              subtitle: Text(
                'HYONNA',
                style: TextStyle(
                  fontSize: _isMobile ? 10 : 18,
                  height: 1.2,
                ),
              ),
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_isDesktop) _randomQueueButton(),
                  _prevTrackButton(),
                  SizedBox.square(
                    dimension: 45,
                    child: _playPauseButton(),
                  ),
                  _nextTrackButton(),
                  if (_isDesktop) _repeatTrackButton(),
                ],
              ),
              leadingToTitle: 15,
            ),
          ),
        ),
        Positioned(
          left: -25,
          top: -22,
          right: -25,
          child: GestureDetector(
            onHorizontalDragDown: (details) {
              final sliderWidth = _sliderKey.currentContext?.size?.width;
              if (sliderWidth == null) return;
              _playProgress.value = details.localPosition.dx / sliderWidth;
            },
            onHorizontalDragUpdate: (details) {
              final sliderWidth = _sliderKey.currentContext?.size?.width;
              if (sliderWidth == null) return;
              _playProgress.value = details.localPosition.dx / sliderWidth;
            },
            behavior: HitTestBehavior.opaque,
            child: ValueListenableBuilder(
              valueListenable: _playProgress,
              builder: (context, value, child) => Slider(
                key: _sliderKey,
                value: value,
                onChanged: (value) => _playProgress.value = value,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageProvider.dispose();
    _dynamicColors.dispose();
    _playProgress.dispose();
    _isPlaying.dispose();
    _randomQueue.dispose();
    _repeatTrack.dispose();
    _likeTrack.dispose();
    super.dispose();
  }

  Widget _playPauseButton() => PlayPauseButton(
        onPressed: () => _isPlaying.value = !_isPlaying.value,
        background: _theme.colorScheme.onPrimary,
        foreground: _theme.scaffoldBackgroundColor,
        stateNotifier: _isPlaying,
      );

  Widget _prevTrackButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(Entypo.fast_backward),
      );

  Widget _nextTrackButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(Entypo.fast_forward),
      );

  Widget _openListButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(CupertinoIcons.list_bullet),
      );

  Widget _randomQueueButton() => ValueListenableBuilder(
        valueListenable: _randomQueue,
        builder: (context, isRandom, child) => IconButton(
          onPressed: () => _randomQueue.value = !isRandom,
          icon: Icon(
            JPlayer.mix,
            color: _theme.colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            JPlayer.mix,
            color: _theme.colorScheme.primary,
          ),
          isSelected: isRandom,
        ),
      );

  Widget _repeatTrackButton() => ValueListenableBuilder(
        valueListenable: _repeatTrack,
        builder: (context, isRepeated, child) => IconButton(
          onPressed: () => _repeatTrack.value = !isRepeated,
          icon: Icon(
            JPlayer.repeat,
            color: _theme.colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            JPlayer.repeat,
            color: _theme.colorScheme.primary,
          ),
          isSelected: isRepeated,
        ),
      );

  Widget _downloadTrackButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(JPlayer.download),
      );

  Widget _likeTrackButton() => ValueListenableBuilder(
        valueListenable: _likeTrack,
        builder: (context, isLiked, child) => IconButton(
          onPressed: () => _likeTrack.value = !isLiked,
          icon: Icon(
            CupertinoIcons.heart,
            color: _theme.colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            CupertinoIcons.heart_fill,
            color: _theme.colorScheme.primary,
          ),
          isSelected: isLiked,
        ),
      );
}
