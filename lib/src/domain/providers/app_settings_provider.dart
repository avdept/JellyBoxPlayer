import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSetting {
  sidebarCollapsed('sidebar_collapsed'),
  studioModeFullscreen('studio_mode_fullscreen'),
  studioModeAnimation('studio_mode_animation', defaultValue: true),
  generatedPlaylistsDisabled('disable_generated_playlists');

  const AppSetting(this.key, {this.defaultValue = false});

  final String key;
  final bool defaultValue;
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, Map<AppSetting, bool>>(
      (ref) => AppSettingsNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
      ),
    );

final ProviderFamily<bool, AppSetting> settingProvider =
    Provider.family<bool, AppSetting>(
      (ref, setting) =>
          ref.watch(appSettingsProvider)[setting] ?? setting.defaultValue,
    );

class AppSettingsNotifier extends StateNotifier<Map<AppSetting, bool>> {
  AppSettingsNotifier(this._prefs) : super(_read(_prefs));

  static const _storageKey = 'app_settings';

  final SharedPreferences? _prefs;

  static Map<AppSetting, bool> _read(SharedPreferences? prefs) {
    if (prefs == null) return const {};
    final stored = prefs.getString(_storageKey);
    final decoded = stored != null
        ? jsonDecode(stored) as Map<String, dynamic>
        : const <String, dynamic>{};

    return {
      for (final setting in AppSetting.values)
        if (decoded[setting.key] case final bool value)
          setting: value
        else if (prefs.getBool(setting.key) case final bool legacy)
          setting: legacy,
    };
  }

  bool isEnabled(AppSetting setting) => state[setting] ?? setting.defaultValue;

  void setEnabled(AppSetting setting, {required bool value}) {
    state = {...state, setting: value};
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(
      prefs.setString(
        _storageKey,
        jsonEncode({
          for (final entry in state.entries) entry.key.key: entry.value,
        }),
      ),
    );
  }

  void toggle(AppSetting setting) =>
      setEnabled(setting, value: !isEnabled(setting));
}
