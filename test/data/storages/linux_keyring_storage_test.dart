import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/linux_keyring_storage.dart';

/// Mirrors flutter_secure_storage_linux: every key lives in one JSON blob that
/// each call reads, edits and stores back whole, and a blank blob reads as an
/// empty bundle.
class _FakeKeyring extends FlutterSecureStorage {
  String blob = '';

  Map<String, String> get _bundle => blob.isEmpty
      ? {}
      : (jsonDecode(blob) as Map<String, dynamic>).cast<String, String>();

  /// What an unencrypted gnome-keyring does to a secret holding a backslash
  /// when it reloads its file.
  void reload() {
    if (blob.contains(r'\')) blob = '';
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _bundle;

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
  }) async => blob = jsonEncode({..._bundle, key: value});

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => blob = jsonEncode(_bundle..remove(key));

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => blob = '{}';
}

void main() {
  late _FakeKeyring keyring;
  late LinuxKeyringStorage storage;

  final accounts = jsonEncode([
    {'serverId': 'abc', 'url': 'http://jelly.local', 'token': 't0k3n'},
  ]);

  setUp(() {
    keyring = _FakeKeyring();
    storage = LinuxKeyringStorage(keyring);
  });

  test('- keeps backslashes out of the bundle', () async {
    await storage.write(key: 'accounts', value: accounts);
    await storage.write(key: 'note', value: 'line one\nline "two" \\ end');

    expect(keyring.blob, isNot(contains(r'\')));
  });

  test('- stores plain values as they are', () async {
    await storage.write(key: 'serverUrl', value: 'http://jelly.local:8096');

    expect(
      jsonDecode(keyring.blob),
      containsPair('serverUrl', 'http://jelly.local:8096'),
    );
  });

  test('- round-trips encoded values through a fresh instance', () async {
    await storage.write(key: 'accounts', value: accounts);
    await storage.write(key: 'authToken', value: 'secret');

    final relaunched = LinuxKeyringStorage(keyring);
    expect(await relaunched.read(key: 'accounts'), accounts);
    expect(await relaunched.read(key: 'authToken'), 'secret');
    expect(await relaunched.readAll(), {
      'accounts': accounts,
      'authToken': 'secret',
    });
  });

  test('- survives the keyring reload that blanked escaped JSON', () async {
    await storage.write(key: 'authToken', value: 'secret');
    await storage.write(key: 'accounts', value: accounts);
    keyring.reload();

    final relaunched = LinuxKeyringStorage(keyring);
    expect(await relaunched.read(key: 'authToken'), 'secret');
    expect(await relaunched.read(key: 'accounts'), accounts);
  });

  test('- migrates a raw escaped value it finds on first access', () async {
    keyring.blob = jsonEncode({'accounts': accounts, 'authToken': 'secret'});

    expect(await storage.read(key: 'accounts'), accounts);
    expect(keyring.blob, isNot(contains(r'\')));
    expect(await LinuxKeyringStorage(keyring).read(key: 'accounts'), accounts);
  });

  test('- puts back keys a blanked keyring lost before writing', () async {
    await storage.write(key: 'authToken', value: 'secret');
    await storage.write(key: 'userId', value: 'user-1');
    keyring.blob = '';

    await storage.write(key: 'lastServerUrl', value: 'http://jelly.local');

    expect(jsonDecode(keyring.blob), {
      'authToken': 'secret',
      'userId': 'user-1',
      'lastServerUrl': 'http://jelly.local',
    });
  });

  test('- does not bring back a deleted key', () async {
    await storage.write(key: 'authToken', value: 'secret');
    await storage.write(key: 'userId', value: 'user-1');
    keyring.blob = '';

    await storage.delete(key: 'authToken');

    expect(jsonDecode(keyring.blob), {'userId': 'user-1'});
    expect(await storage.read(key: 'authToken'), isNull);
  });

  test('- treats writing null as a delete', () async {
    await storage.write(key: 'relayUrl', value: 'https://relay');
    await storage.write(key: 'relayUrl', value: null);

    expect(await storage.containsKey(key: 'relayUrl'), isFalse);
    expect(jsonDecode(keyring.blob), isEmpty);
  });

  test('- forgets everything on deleteAll', () async {
    await storage.write(key: 'authToken', value: 'secret');
    await storage.deleteAll();
    await storage.write(key: 'userId', value: 'user-1');

    expect(jsonDecode(keyring.blob), {'userId': 'user-1'});
    expect(await storage.readAll(), {'userId': 'user-1'});
  });

  test('- keeps a value that merely starts with the prefix intact', () async {
    const tricky = '${LinuxKeyringStorage.encodedPrefix}not-base64';
    await storage.write(key: 'odd', value: tricky);

    expect(await LinuxKeyringStorage(keyring).read(key: 'odd'), tricky);
  });

  test('- runs concurrent calls in order', () async {
    await Future.wait([
      storage.write(key: 'a', value: '1'),
      storage.delete(key: 'a'),
      storage.write(key: 'b', value: '2'),
    ]);

    expect(jsonDecode(keyring.blob), {'b': '2'});
  });
}
