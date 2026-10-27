import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/providers/secure_storage_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  PlatformException missingEntitlement() => PlatformException(
    code: 'Unexpected security result code',
    message: "A required entitlement isn't present.",
    details: -34018,
  );

  final calls = <String>[];

  void mockChannel({required Object? Function(MethodCall call) handler}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return handler(call);
        });
  }

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('EntitlementTolerantSecureStorage', () {
    test(
      '- swallows the missing-entitlement error on delete when tolerant',
      () async {
        mockChannel(handler: (call) => throw missingEntitlement());
        const storage = EntitlementTolerantSecureStorage(
          ignoreMissingEntitlement: true,
        );

        await storage.delete(key: 'remote_url');
        await storage.deleteAll();
        await storage.write(key: 'remote_url', value: null);

        expect(calls, ['delete', 'deleteAll', 'delete']);
      },
    );

    test('- rethrows the missing-entitlement error when not tolerant', () {
      mockChannel(handler: (call) => throw missingEntitlement());
      const storage = EntitlementTolerantSecureStorage(
        ignoreMissingEntitlement: false,
      );

      expect(storage.delete(key: 'remote_url'), throwsA(isA<PlatformException>()));
    });

    test('- rethrows other platform errors even when tolerant', () {
      mockChannel(
        handler: (call) => throw PlatformException(
          code: 'Unexpected security result code',
          details: -25308,
        ),
      );
      const storage = EntitlementTolerantSecureStorage(
        ignoreMissingEntitlement: true,
      );

      expect(storage.delete(key: 'remote_url'), throwsA(isA<PlatformException>()));
    });

    test('- never swallows errors from a real write', () {
      mockChannel(handler: (call) => throw missingEntitlement());
      const storage = EntitlementTolerantSecureStorage(
        ignoreMissingEntitlement: true,
      );

      expect(
        storage.write(key: 'remote_url', value: 'https://a'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('- still deletes normally when the platform succeeds', () async {
      mockChannel(handler: (call) => null);
      const storage = EntitlementTolerantSecureStorage(
        ignoreMissingEntitlement: true,
      );

      await storage.delete(key: 'remote_url');

      expect(calls, ['delete']);
    });
  });
}
