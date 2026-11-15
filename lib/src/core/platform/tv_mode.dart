import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class TvMode {
  static const _channel = MethodChannel('jellybox/platform');

  static const _forced = bool.fromEnvironment('JELLYBOX_FORCE_TV');

  static bool _isTv = _forced;

  static bool get isTv => _isTv;

  @visibleForTesting
  static set isTv(bool value) => _isTv = value;

  static Future<void> init() async {
    if (_forced || kIsWeb || !Platform.isAndroid) return;
    try {
      _isTv = await _channel.invokeMethod<bool>('isTelevision') ?? false;
    } on PlatformException catch (error) {
      debugPrint('[TvMode] detection failed: $error');
    } on MissingPluginException {
      _isTv = false;
    }
  }
}
