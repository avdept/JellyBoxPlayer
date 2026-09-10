import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/config/constants.dart';

/// Direct-download builds carry no provisioning profile, so they cannot use the
/// macOS Data Protection Keychain (which requires one). They use the legacy
/// keychain instead, which needs neither a profile nor entitlements. The App
/// Store build keeps the Data Protection Keychain.
const AppleOptions _kMacOsOptions = kDirectDownloadBuild
    ? MacOsOptions(usesDataProtectionKeychain: false)
    : MacOsOptions.defaultOptions;

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    mOptions: _kMacOsOptions,
  ),
);
