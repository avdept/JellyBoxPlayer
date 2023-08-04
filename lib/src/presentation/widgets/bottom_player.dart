import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  final _playProgress = ValueNotifier<double>(0.6);

  late ThemeData _theme;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;

  Future<void> _onExpand() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: false,
        constraints: const BoxConstraints(minWidth: double.infinity),
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 518),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: _isMobile ? 24 : 30,
                top: _isMobile ? 12 : 40,
                right: _isMobile ? 24 : 30,
                bottom: _isMobile ? 32 : 60,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      Images.songSample,
                      width: _isMobile ? 335 : 444,
                      height: _isMobile ? 333 : 441,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: _isMobile ? 6 : 18),
                  SizedBox(
                    width: _isMobile ? 335 : 444,
                    child: IconTheme(
                      data: IconTheme.of(context).copyWith(
                        size: _isMobile ? 28 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _openListButton(),
                          _randomQueueButton(),
                          _repeatTrackButton(),
                          _downloadTrackButton(),
                          _likeTrackButton(),
                        ],
                      ),
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
                      color: const Color(0xFF9FAEC5),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: _isMobile ? 15 : 21),
                  Container(
                    width: double.infinity,
                    height: _isMobile ? 78 : 120,
                    color: Colors.red,
                  ),
                  SizedBox(height: _isMobile ? 23 : 56),
                  Wrap(
                    spacing: _isMobile ? 32 : 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconTheme(
                        data: IconTheme.of(context)
                            .copyWith(size: _isMobile ? 64 : 86),
                        child: _prevTrackButton(),
                      ),
                      SizedBox.square(
                        dimension: _isMobile ? 56 : 72,
                        child: _playPauseButton(),
                      ),
                      IconTheme(
                        data: IconTheme.of(context)
                            .copyWith(size: _isMobile ? 64 : 86),
                        child: _nextTrackButton(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _viewPadding = MediaQuery.viewPaddingOf(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(
          color: const Color(0xFF341010),
          child: Padding(
            padding: EdgeInsets.only(bottom: _viewPadding.bottom),
            child: GestureDetector(
              onTap: _onExpand,
              child: SimpleListTile(
                padding: const EdgeInsets.only(right: 8),
                leading: Image.asset(
                  Images.songSample,
                  width: _isMobile ? 69 : 92,
                  height: _isMobile ? 66 : 88,
                  fit: BoxFit.cover,
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
                    if (!_isMobile) _randomQueueButton(),
                    IconTheme(
                      data: IconTheme.of(context).copyWith(size: 45),
                      child: _prevTrackButton(),
                    ),
                    SizedBox.square(
                      dimension: 45,
                      child: _playPauseButton(),
                    ),
                    IconTheme(
                      data: IconTheme.of(context).copyWith(size: 45),
                      child: _nextTrackButton(),
                    ),
                    if (!_isMobile) _repeatTrackButton(),
                  ],
                ),
                leadingToTitle: 15,
              ),
            ),
          ),
        ),
        Positioned(
          left: -25,
          top: -22,
          right: -25,
          child: ValueListenableBuilder(
            valueListenable: _playProgress,
            builder: (context, value, child) => Slider.adaptive(
              value: value,
              onChanged: (value) => _playProgress.value = value,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _playProgress.dispose();
    super.dispose();
  }

  Widget _playPauseButton() => FloatingActionButton(
        onPressed: () {},
        foregroundColor: _theme.scaffoldBackgroundColor,
        backgroundColor: _theme.iconTheme.color,
        elevation: 0,
        shape: const CircleBorder(),
        child: const AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: AlwaysStoppedAnimation(0),
        ),
      );

  Widget _openListButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.list),
      );

  Widget _randomQueueButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.question_mark),
      );

  Widget _prevTrackButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.skip_previous),
      );

  Widget _nextTrackButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.skip_next),
      );

  Widget _repeatTrackButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.repeat),
      );

  Widget _downloadTrackButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.download),
      );

  Widget _likeTrackButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.favorite),
      );
}
