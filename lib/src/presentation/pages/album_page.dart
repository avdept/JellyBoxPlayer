import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackButton(),
            const SizedBox(height: 14),
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
                const SizedBox(width: 38),
                IconTheme(
                  data: IconTheme.of(context).copyWith(
                    size: isMobile ? 24 : 28,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Album name',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 46,
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
                                        fontSize: 16,
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Offstage(
                                  offstage: isMobile,
                                  child: const Icon(Icons.circle, size: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 32,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.download),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.question_mark),
                          ),
                          SizedBox.square(
                            dimension: isMobile ? 52 : 60,
                            child: FloatingActionButton(
                              onPressed: () {},
                              elevation: 0,
                              shape: const CircleBorder(),
                              child: const Icon(Icons.play_arrow_outlined),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) => Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.red,
                ),
                separatorBuilder: (context, index) => SizedBox(
                  height: isTablet ? 27 : 24,
                ),
                itemCount: 10,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(seconds: 1),
            ),
          ],
        ),
      ),
    );
  }

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
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.alarm),
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
            child: Icon(Icons.music_note_outlined),
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
}
