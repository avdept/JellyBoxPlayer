import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LinuxKeyringStorage extends FlutterSecureStorage {
  LinuxKeyringStorage(this._inner);

  static const encodedPrefix = 'jbx-b64:';

  final FlutterSecureStorage _inner;
  final Map<String, String> _known = {};
  bool _loaded = false;
  Future<void> _queue = Future.value();

  static bool _needsEncoding(String value) =>
      value.startsWith(encodedPrefix) ||
      value.codeUnits.any(
        (unit) => unit < 0x20 || unit == 0x22 || unit == 0x5c,
      );

  static String encode(String value) => _needsEncoding(value)
      ? '$encodedPrefix${base64Url.encode(utf8.encode(value))}'
      : value;

  static String decode(String stored) => stored.startsWith(encodedPrefix)
      ? utf8.decode(base64Url.decode(stored.substring(encodedPrefix.length)))
      : stored;

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _queue.then((_) async {
      await _load();
      return operation();
    });
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _load() async {
    if (_loaded) return;
    final stored = await _inner.readAll();
    for (final MapEntry(:key, :value) in stored.entries) {
      final plain = decode(value);
      _known[key] = plain;
      if (encode(plain) != value) {
        await _inner.write(key: key, value: encode(plain));
      }
    }
    _loaded = true;
  }

  Future<void> _repair() async {
    final stored = await _inner.readAll();
    for (final MapEntry(:key, :value) in _known.entries) {
      if (stored.containsKey(key)) continue;
      log('Restoring "$key", missing from the keyring', name: 'SecureStorage');
      await _inner.write(key: key, value: encode(value));
    }
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (value == null) return delete(key: key, lOptions: lOptions);
    return _serial(() async {
      await _repair();
      await _inner.write(key: key, value: encode(value), lOptions: lOptions);
      _known[key] = value;
    });
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _serial(() async {
    _known.remove(key);
    await _repair();
    await _inner.delete(key: key, lOptions: lOptions);
  });

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _serial(() async => _known[key]);

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _serial(() async => _known.containsKey(key));

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _serial(() async => Map.of(_known));

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _serial(() async {
    _known.clear();
    await _inner.deleteAll(lOptions: lOptions);
  });
}
