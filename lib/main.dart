import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/data/storages/window_size_storage.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

late String deviceId;

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  deviceId = (await FlutterUdid.udid).trim();

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

  final prefs = await SharedPreferences.getInstance();
  final lastWindowSize = await WindowSizeStorage(prefs).getWindowSize();
  final initialWindowSize = lastWindowSize ?? const Size(1440, 1000);

  // Window settings
  const minWindowSize = Size(1280, 800);

  // Use window_manager package for MacOS & Windows
  if (Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      size: initialWindowSize,
      minimumSize: minWindowSize,
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

  if (Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(windows: false);
  }

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = 'https://37200398250012a53c6390d1bd05b60c@o4505940301840384.ingest.sentry.io/4506644062732288'
        ..tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: App(screenFactory: ScreenFactory()),
      ),
    ),
  );

  // Use bitsdojo_window for Linux
  if (Platform.isLinux) {
    final prefs = await SharedPreferences.getInstance();
    final lastWindowSize = await WindowSizeStorage(prefs).getWindowSize();
    final initialWindowSize = lastWindowSize ?? const Size(1440, 1000);

    doWhenWindowReady(() {
      appWindow
        ..size = initialWindowSize
        ..minSize = minWindowSize
        ..alignment = Alignment.center
        ..show();
    });
  }
}
