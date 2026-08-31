import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSetting {
  sidebarCollapsed('sidebar_collapsed'),
  studioModeFullscreen('studio_mode_fullscreen'),
  studioModeAnimation('studio_mode_animation', defaultValue: true),
  generatedPlaylistsDisabled('disable_generated_playlists'),
  defaultBrowseTab('default_browse_tab', defaultValue: 'albums'),
  defaultStartPage('default_start_page', defaultValue: 'home'),
  playerVolume('player_volume', defaultValue: 1.0);

  const AppSetting(this.key, {this.defaultValue = false});

  final String key;
  final Object defaultValue;
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, Map<AppSetting, Object>>(
      (ref) => AppSettingsNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
      ),
    );

final ProviderFamily<bool, AppSetting> settingProvider =
    Provider.family<bool, AppSetting>(
      (ref, setting) =>
          _asBool(ref.watch(appSettingsProvider)[setting], setting),
    );

final defaultBrowseTabProvider = Provider<ItemList>(
  (ref) =>
      ItemList.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.defaultBrowseTab],
        AppSetting.defaultBrowseTab,
      )] ??
      ItemList.albums,
);

final defaultStartPageProvider = Provider<StartPage>(
  (ref) =>
      StartPage.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.defaultStartPage],
        AppSetting.defaultStartPage,
      )] ??
      StartPage.home,
);

bool _asBool(Object? value, AppSetting setting) {
  final resolved = value ?? setting.defaultValue;
  return resolved is bool && resolved;
}

String _asString(Object? value, AppSetting setting) {
  final resolved = value ?? setting.defaultValue;
  return resolved is String ? resolved : '';
}

double _asDouble(Object? value, AppSetting setting) {
  final resolved = value ?? setting.defaultValue;
  return resolved is num ? resolved.toDouble() : 0;
}

class AppSettingsNotifier extends StateNotifier<Map<AppSetting, Object>> {
  AppSettingsNotifier(this._prefs) : super(_read(_prefs));

  static const _storageKey = 'app_settings';

  final SharedPreferences? _prefs;

  static Map<AppSetting, Object> _read(SharedPreferences? prefs) {
    if (prefs == null) return const {};
    final stored = prefs.getString(_storageKey);
    final decoded = stored != null
        ? jsonDecode(stored) as Map<String, dynamic>
        : const <String, dynamic>{};

    return {
      for (final setting in AppSetting.values)
        if (decoded[setting.key] case final bool value)
          setting: value
        else if (decoded[setting.key] case final String value)
          setting: value
        else if (decoded[setting.key] case final num value)
          setting: value.toDouble()
        else if (prefs.getBool(setting.key) case final bool legacy)
          setting: legacy,
    };
  }

  bool isEnabled(AppSetting setting) => _asBool(state[setting], setting);

  String valueOf(AppSetting setting) => _asString(state[setting], setting);

  double numberOf(AppSetting setting) => _asDouble(state[setting], setting);

  void setEnabled(AppSetting setting, {required bool value}) =>
      _store(setting, value);

  void setValue(AppSetting setting, String value) => _store(setting, value);

  void setNumber(AppSetting setting, double value) => _store(setting, value);

  void toggle(AppSetting setting) =>
      setEnabled(setting, value: !isEnabled(setting));

  void _store(AppSetting setting, Object value) {
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
}
