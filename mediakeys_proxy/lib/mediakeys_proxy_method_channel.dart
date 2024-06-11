import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mediakeys_proxy_platform_interface.dart';

/// An implementation of [MediakeysProxyPlatform] that uses method channels.
class MethodChannelMediakeysProxy extends MediakeysProxyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mediakeys_proxy');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
