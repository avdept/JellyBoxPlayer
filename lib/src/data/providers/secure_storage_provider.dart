import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// True for the direct-download (Developer ID / notarized DMG) build, set via
/// `--dart-define=JELLYBOX_DIRECT_DOWNLOAD=true` in the macOS DMG workflow.
///
/// Those builds are not sandboxed and carry no provisioning profile, so they
/// cannot use the macOS Data Protection Keychain (which requires one). They use
/// the legacy keychain instead, which needs neither a profile nor entitlements.
/// The App Store build leaves this false and keeps the Data Protection Keychain.
const bool _kDirectDownload = bool.fromEnvironment('JELLYBOX_DIRECT_DOWNLOAD');

const AppleOptions _kMacOsOptions = _kDirectDownload
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
