import 'package:flutter_test/flutter_test.dart';
import 'package:mediakeys_proxy/mediakeys_proxy.dart';
import 'package:mediakeys_proxy/mediakeys_proxy_platform_interface.dart';
import 'package:mediakeys_proxy/mediakeys_proxy_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediakeysProxyPlatform
    with MockPlatformInterfaceMixin
    implements MediakeysProxyPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MediakeysProxyPlatform initialPlatform = MediakeysProxyPlatform.instance;

  test('$MethodChannelMediakeysProxy is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediakeysProxy>());
  });

  test('getPlatformVersion', () async {
    MediakeysProxy mediakeysProxyPlugin = MediakeysProxy();
    MockMediakeysProxyPlatform fakePlatform = MockMediakeysProxyPlatform();
    MediakeysProxyPlatform.instance = fakePlatform;

    expect(await mediakeysProxyPlugin.getPlatformVersion(), '42');
  });
}
