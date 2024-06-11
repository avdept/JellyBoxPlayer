import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mediakeys_proxy_method_channel.dart';

abstract class MediakeysProxyPlatform extends PlatformInterface {
  /// Constructs a MediakeysProxyPlatform.
  MediakeysProxyPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediakeysProxyPlatform _instance = MethodChannelMediakeysProxy();

  /// The default instance of [MediakeysProxyPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediakeysProxy].
  static MediakeysProxyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediakeysProxyPlatform] when
  /// they register themselves.
  static set instance(MediakeysProxyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
