import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/config/constants.dart';

/// Direct-download builds carry no provisioning profile, so they cannot use the
/// macOS Data Protection Keychain (which requires one). They use the legacy
/// keychain instead, which needs neither a profile nor entitlements. The App
/// Store build keeps the Data Protection Keychain.
///
/// flutter_secure_storage's delete still probes the Data Protection Keychain
/// (it retries every delete with kSecAttrSynchronizable=true), and that probe
/// fails with errSecMissingEntitlement (-34018) on entitlement-free builds
/// when the key is absent from the legacy keychain. The file-based delete has
/// already run by then, so [EntitlementTolerantSecureStorage] treats that one
/// error as success on those builds.
const AppleOptions _kMacOsOptions = kDirectDownloadBuild
    ? MacOsOptions(usesDataProtectionKeychain: false)
    : MacOsOptions.defaultOptions;

class EntitlementTolerantSecureStorage extends FlutterSecureStorage {
  const EntitlementTolerantSecureStorage({
    required this.ignoreMissingEntitlement,
    super.aOptions,
    super.iOptions,
    super.mOptions,
  });

  final bool ignoreMissingEntitlement;

  static const _missingEntitlementCode = -34018;

  bool _ignorable(PlatformException exception) =>
      ignoreMissingEntitlement &&
      exception.details == _missingEntitlementCode;

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    try {
      await super.delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (exception) {
      if (!_ignorable(exception)) rethrow;
    }
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    try {
      await super.deleteAll(
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (exception) {
      if (!_ignorable(exception)) rethrow;
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
  }) async {
    try {
      await super.write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (exception) {
      if (value != null || !_ignorable(exception)) rethrow;
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const EntitlementTolerantSecureStorage(
    ignoreMissingEntitlement: kDirectDownloadBuild,
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: _kMacOsOptions,
  ),
);
