import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/updates/release_checker.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const updateCheckInterval = Duration(hours: 12);

DownloadPlatform? currentDownloadPlatform() {
  if (Platform.isAndroid) return DownloadPlatform.android;
  if (Platform.isMacOS) return DownloadPlatform.macos;
  if (Platform.isWindows) return DownloadPlatform.windows;
  if (Platform.isLinux) return DownloadPlatform.linux;
  return null;
}

final releaseCheckerProvider = Provider<ReleaseChecker>(
  (ref) => ReleaseChecker(),
);

final availableUpdateProvider = FutureProvider<AvailableUpdate?>((ref) async {
  if (!kSideloadBuild) return null;
  final platform = currentDownloadPlatform();
  if (platform == null) return null;
  if (ref.watch(isOfflineProvider)) return null;

  final timer = Timer(updateCheckInterval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final info = await PackageInfo.fromPlatform();
  try {
    return await ref
        .read(releaseCheckerProvider)
        .check(currentVersion: info.version, platform: platform);
  } on Object catch (error) {
    debugPrint('Update check failed: $error');
    return null;
  }
});

class DismissedUpdateNotifier extends StateNotifier<String?> {
  DismissedUpdateNotifier(this._prefs) : super(_prefs?.getString(_key));

  static const _key = 'update_banner_dismissed_version';

  final SharedPreferences? _prefs;

  void dismiss(String version) {
    state = version;
    unawaited(_prefs?.setString(_key, version));
  }
}

final dismissedUpdateProvider =
    StateNotifierProvider<DismissedUpdateNotifier, String?>(
      (ref) => DismissedUpdateNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
      ),
    );

final visibleUpdateProvider = Provider<AvailableUpdate?>((ref) {
  final update = ref.watch(availableUpdateProvider).valueOrNull;
  if (update == null) return null;
  final dismissed = ref.watch(dismissedUpdateProvider);
  return update.version == dismissed ? null : update;
});
