import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(desktop: 1025, tablet: 600, watch: 200),
    customRefinedBreakpoints: const RefinedBreakpoints(),
  );

  if (Platform.isIOS || Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  }

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1440, 1000),
      minimumSize: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  await SentryFlutter.init(
    (options) {
      options..dsn = 'https://37200398250012a53c6390d1bd05b60c@o4505940301840384.ingest.sentry.io/4506644062732288'
      ..tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const ProviderScope(child: App(screenFactory: ScreenFactory()))),
  );


}
