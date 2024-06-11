import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediakeys_proxy/mediakeys_proxy_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMediakeysProxy platform = MethodChannelMediakeysProxy();
  const MethodChannel channel = MethodChannel('mediakeys_proxy');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
