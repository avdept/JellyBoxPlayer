import 'dart:io' show Platform;

import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/app.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(desktop: 1025, tablet: 600, watch: 200),
    customRefinedBreakpoints: const RefinedBreakpoints(),
  );

  if (Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  }

  if (kReleaseMode && (Platform.isAndroid || Platform.isIOS)) {
    await bugsnag.start(apiKey: '7572207d224c7e1f05ee19a07c32e937');
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

  runApp(const ProviderScope(child: App(screenFactory: ScreenFactory())));
}
