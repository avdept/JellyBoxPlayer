
import 'mediakeys_proxy_platform_interface.dart';

class MediakeysProxy {
  Future<String?> getPlatformVersion() {
    return MediakeysProxyPlatform.instance.getPlatformVersion();
  }
}
