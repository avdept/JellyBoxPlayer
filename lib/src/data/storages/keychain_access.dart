import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeychainAccess {
  KeychainAccess(this._storage, {bool? isIOS})
    : _isIOS = isIOS ?? Platform.isIOS;

  static const IOSOptions legacyIosOptions = IOSOptions.defaultOptions;

  final FlutterSecureStorage _storage;
  final bool _isIOS;

  Future<String?> readSessionKey(String key) async {
    if (!_isIOS) return _storage.read(key: key);
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } on PlatformException catch (e) {
      log(
        'Keychain read failed, waiting for unlock: ${e.message}',
        name: 'Auth',
      );
    }
    await waitForProtectedData();
    await migrateLegacyItems();
    return _storage.read(key: key);
  }

  Future<void> waitForProtectedData() async {
    if (await _storage.isCupertinoProtectedDataAvailable() ?? true) return;
    final changes = _storage.onCupertinoProtectedDataAvailabilityChanged;
    if (changes == null) return;
    await changes.firstWhere((available) => available);
  }

  Future<void> migrateLegacyItems() async {
    try {
      final legacy = await _storage.readAll(iOptions: legacyIosOptions);
      for (final entry in legacy.entries) {
        await _storage.delete(key: entry.key, iOptions: legacyIosOptions);
        await _storage.write(key: entry.key, value: entry.value);
      }
    } on PlatformException catch (e) {
      log('Keychain migration failed: ${e.message}', name: 'Auth');
    }
  }
}
