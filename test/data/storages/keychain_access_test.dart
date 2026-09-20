import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late KeychainAccess keychain;

  setUpAll(() {
    registerFallbackValue(IOSOptions.defaultOptions);
  });

  setUp(() {
    storage = MockSecureStorage();
    keychain = KeychainAccess(storage, isIOS: true);
    when(
      () => storage.isCupertinoProtectedDataAvailable(),
    ).thenAnswer((_) async => true);
    when(
      () => storage.readAll(iOptions: any(named: 'iOptions')),
    ).thenAnswer((_) async => const {});
    when(
      () => storage.delete(
        key: any(named: 'key'),
        iOptions: any(named: 'iOptions'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  test('returns a readable value without touching legacy items', () async {
    when(
      () => storage.read(key: 'serverUrl'),
    ).thenAnswer((_) async => 'https://jf');

    expect(await keychain.readSessionKey('serverUrl'), 'https://jf');
    verifyNever(() => storage.readAll(iOptions: any(named: 'iOptions')));
    verifyNever(() => storage.isCupertinoProtectedDataAvailable());
  });

  test('migrates legacy items when the new class has nothing', () async {
    var migrated = false;
    when(
      () => storage.read(key: 'serverUrl'),
    ).thenAnswer((_) async => migrated ? 'https://jf' : null);
    when(() => storage.readAll(iOptions: any(named: 'iOptions'))).thenAnswer(
      (_) async => const {'serverUrl': 'https://jf', 'authToken': 't'},
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => migrated = true);

    expect(await keychain.readSessionKey('serverUrl'), 'https://jf');

    verifyInOrder([
      () => storage.delete(
        key: 'serverUrl',
        iOptions: KeychainAccess.legacyIosOptions,
      ),
      () => storage.write(key: 'serverUrl', value: 'https://jf'),
      () => storage.delete(
        key: 'authToken',
        iOptions: KeychainAccess.legacyIosOptions,
      ),
      () => storage.write(key: 'authToken', value: 't'),
    ]);
  });

  test('waits for the keychain to unlock after a locked read fails', () async {
    final unlock = StreamController<bool>();
    var unlocked = false;
    when(
      () => storage.isCupertinoProtectedDataAvailable(),
    ).thenAnswer((_) async => unlocked);
    when(
      () => storage.onCupertinoProtectedDataAvailabilityChanged,
    ).thenAnswer((_) => unlock.stream);
    when(() => storage.read(key: 'serverUrl')).thenAnswer((_) async {
      if (!unlocked) {
        throw PlatformException(code: 'Unexpected security result code');
      }
      return 'https://jf';
    });

    final pending = keychain.readSessionKey('serverUrl');
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => storage.readAll(iOptions: any(named: 'iOptions')));

    unlocked = true;
    unlock.add(true);

    expect(await pending, 'https://jf');
    verify(() => storage.readAll(iOptions: any(named: 'iOptions'))).called(1);
    await unlock.close();
  });

  test('skips the whole dance off iOS', () async {
    final plain = KeychainAccess(storage, isIOS: false);
    when(() => storage.read(key: 'serverUrl')).thenAnswer((_) async => null);

    expect(await plain.readSessionKey('serverUrl'), isNull);
    verifyNever(() => storage.isCupertinoProtectedDataAvailable());
    verifyNever(() => storage.readAll(iOptions: any(named: 'iOptions')));
  });
}
