import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MacTitleBarLayout { standard, floating }

abstract final class MacTitleBar {
  static const _channel = MethodChannel('jellybox/window_chrome');

  static MacTitleBarLayout? _applied;

  static double? windowCornerRadius;

  static Future<void> init() async {
    if (kIsWeb || !Platform.isMacOS) return;
    try {
      windowCornerRadius = await _channel
          .invokeMethod<double>('getWindowCornerRadius')
          .timeout(const Duration(seconds: 1));
    } on Object catch (error) {
      debugPrint('[MacTitleBar] corner radius unavailable: $error');
    }
  }

  static void sync(MacTitleBarLayout layout) {
    if (kIsWeb || !Platform.isMacOS || _applied == layout) return;
    _applied = layout;
    unawaited(_apply(layout));
  }

  static Future<void> _apply(MacTitleBarLayout layout) async {
    final args = switch (layout) {
      MacTitleBarLayout.standard => const {'toolbar': 'none'},
      MacTitleBarLayout.floating => const {
        'toolbar': 'unified',
        'inset': 20.0,
        'spacing': 8.0,
      },
    };
    try {
      await _channel.invokeMethod<void>('setTitleBar', args);
    } on PlatformException catch (error) {
      debugPrint('[MacTitleBar] $error');
    } on MissingPluginException {
      _applied = null;
    }
  }
}
