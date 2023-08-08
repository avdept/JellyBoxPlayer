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
  late IconThemeData _iconTheme;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;

  Future<void> _onExpand() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        constraints: const BoxConstraints(minWidth: double.infinity),
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 518),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 30,
                top: _isMobile ? 0 : 40,
                right: 30,
                bottom: _isMobile ? 32 : 60,
              ),
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
                            child: Image.asset(
                              Images.songSample,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: _isMobile ? 6 : 18),
                        IconTheme(
                          data: _iconTheme.copyWith(size: _isMobile ? 28 : 24),
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
                  IconTheme(
                    data: _iconTheme.copyWith(size: _isMobile ? 64 : 86),
                    child: Wrap(
                      spacing: _isMobile ? 32 : 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _prevTrackButton(),
                        _playPauseButton(),
                        _nextTrackButton(),
                      ],
                    ),
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
    _iconTheme = IconTheme.of(context);
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
        Container(
          height: _isMobile ? 69 : 92,
          color: const Color(0xFF341010),
          padding: EdgeInsets.only(bottom: _viewPadding.bottom),
          child: GestureDetector(
            onTap: _onExpand,
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
                  if (!_isMobile) _randomQueueButton(),
                  IconTheme(
                    data: _iconTheme.copyWith(size: 45),
                    child: _prevTrackButton(),
                  ),
                  IconTheme(
                    data: _iconTheme.copyWith(size: 45),
                    child: _playPauseButton(),
                  ),
                  IconTheme(
                    data: _iconTheme.copyWith(size: 45),
                    child: _nextTrackButton(),
                  ),
                  if (!_isMobile) _repeatTrackButton(),
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

  Widget _playPauseButton() => IconButton(
        onPressed: () {},
        icon: Stack(
          children: [
            const Icon(Icons.circle),
            AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: const AlwaysStoppedAnimation(0),
              color: _theme.scaffoldBackgroundColor,
            ),
          ],
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
