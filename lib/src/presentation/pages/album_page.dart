import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _backButton(),
                    SizedBox(height: isDesktop ? 30 : 14),
                    Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: isDesktop
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          Images.albumSample,
                          height: isDesktop ? 254 : (isMobile ? 182 : 299),
                        ),
                        SizedBox(
                          width: 38,
                          height: isMobile ? 15 : (isDesktop ? 24 : 35),
                        ),
                        if (isDesktop)
                          Expanded(child: _albumPanel())
                        else
                          _albumPanel(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 12 : 18),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: ListView.builder(
                    itemBuilder: (context, index) => _albumView(),
                    itemCount: 10,
                  ),
                ),
              ),
              const BottomPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() => Builder(
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          final deviceType = getDeviceType(screenSize);
          final isMobile = deviceType == DeviceScreenType.mobile;

          return TextButton.icon(
            onPressed: context.pop,
            icon: const BackButtonIcon(),
            label: Text(
              'Albums',
              style: TextStyle(
                fontSize: isMobile ? 16 : 24,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          );
        },
      );

  Widget _albumPanel() => Builder(
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          final deviceType = getDeviceType(screenSize);
          final isMobile = deviceType == DeviceScreenType.mobile;
          final isDesktop = deviceType == DeviceScreenType.desktop;

          return IconTheme(
            data: IconTheme.of(context).copyWith(
              size: isMobile ? 24 : 28,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Album name',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 42,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Offstage(
                            offstage: !isMobile,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 18),
                              child: Text(
                                '2023',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _albumDetails(
                        duration: const Duration(
                          minutes: 42,
                          seconds: 12,
                        ),
                        soundsCount: 13,
                        year: isMobile ? null : 2023,
                        divider: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Offstage(
                            offstage: isMobile,
                            child: const Icon(Icons.circle, size: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 35 : 32),
                if (isDesktop)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox.square(
                          dimension: 65,
                          child: _playAlbumButton(),
                        ),
                        _downloadAlbumButton(),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: isMobile ? 6 : 32,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _downloadAlbumButton(),
                      _randomQueueButton(),
                      SizedBox.square(
                        dimension: isMobile ? 40 : 48,
                        child: _playAlbumButton(),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      );

  Widget _playAlbumButton() => MaterialButton(
        onPressed: () {},
        color: const Color(0xFF0066FF),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.play_arrow_outlined),
      );

  Widget _downloadAlbumButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.download),
      );

  Widget _randomQueueButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.mix),
      );

  Widget _albumDetails({
    required Duration duration,
    required int soundsCount,
    int? year,
    Widget divider = const SizedBox.shrink(),
  }) {
    final durationInSeconds = duration.inSeconds;
    final hours = durationInSeconds ~/ Duration.secondsPerHour;
    final minutes = durationInSeconds ~/ Duration.secondsPerMinute;
    final seconds = durationInSeconds % Duration.secondsPerMinute;

    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.clock),
          ),
          Text(
            [
              if (hours > 0) hours,
              minutes,
              seconds.toString().padLeft(2, '0'),
            ].join(':'),
          ),
          divider,
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music),
          ),
          Text('$soundsCount songs'),
          if (year != null) ...[
            divider,
            Text(
              year.toString(),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _albumView() => Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final screenSize = MediaQuery.sizeOf(context);
          final deviceType = getDeviceType(screenSize);
          final isMobile = deviceType == DeviceScreenType.mobile;

          return GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: SimpleListTile(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: isMobile ? 16 : 30,
              ),
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  Ink(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(Images.songSample),
                        fit: BoxFit.scaleDown,
                      ),
                      shape: BoxShape.circle,
                    ),
                    width: 52,
                    height: 52,
                    child: const CircularProgressIndicator(value: 0.6),
                  ),
                  const AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: AlwaysStoppedAnimation(1),
                  ),
                ],
              ),
              title: const Text(
                'Chi Shenidi? (feat. Hichkas)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              subtitle: const Text(
                'Fadaei',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
              ),
              trailing: SizedBox.square(
                dimension: 30,
                child: CircularProgressIndicator(
                  value: 0.8,
                  color: const Color(0xFF0066FF),
                  backgroundColor: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              ),
              leadingToTitle: 22,
            ),
          );
        },
      );
}
