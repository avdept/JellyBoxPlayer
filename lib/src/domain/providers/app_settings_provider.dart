import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/platform/tv_mode.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSetting {
  sidebarCollapsed('sidebar_collapsed', defaultValue: true),
  studioModeFullscreen('studio_mode_fullscreen'),
  studioModeVideoCovers('studio_mode_video_covers', defaultValue: true),
  studioModePinnedControls('studio_mode_pinned_controls'),
  studioModeCoverOverVideo('studio_mode_cover_over_video'),
  studioModeLyricsPlacement(
    'studio_mode_lyrics_placement',
    defaultValue: 'right',
  ),
  studioModeRememberLyrics('studio_mode_remember_lyrics'),
  studioModeBackground('studio_mode_background', defaultValue: 'aurora'),
  studioModeLyrics('studio_mode_lyrics'),
  nowPlayingHalo('now_playing_halo'),
  albumArtTint('album_art_tint', defaultValue: true),
  artworkAccent('artwork_accent', defaultValue: true),
  animatedCovers('animated_covers', defaultValue: 'always'),
  desktopAnimatedCovers('desktop_animated_covers', defaultValue: true),
  animationSpeed('animation_speed', defaultValue: 'medium'),
  generatedPlaylistsDisabled('disable_generated_playlists'),
  favouritesHidden('hide_favourites'),
  recentlyPlayedHidden('hide_recently_played'),
  recentReleasesHidden('hide_recent_releases'),
  recentReleasesTinted('recent_releases_tinted', defaultValue: true),
  ratingsHidden('hide_ratings', syncs: true),
  defaultBrowseTab('default_browse_tab', defaultValue: 'albums', syncs: true),
  defaultStartPage('default_start_page', defaultValue: 'home', syncs: true),
  browseLayout('browse_layout', defaultValue: 'cards', syncs: true),
  browseSort('browse_sort', defaultValue: <String, Object>{}),
  homePlaylistSort('home_playlist_sort', defaultValue: 'dateLastContentAdded'),
  homePlaylistSortDescending(
    'home_playlist_sort_descending',
    defaultValue: true,
  ),
  letterRuler('letter_ruler', defaultValue: true, syncs: true),
  artistBrowseScope(
    'artist_browse_scope',
    defaultValue: 'allArtists',
    syncs: true,
  ),
  lyricsAlignment('lyrics_alignment', defaultValue: 'center'),
  lyricsBlur('lyrics_blur', defaultValue: 'medium'),
  lrclibLyrics('lrclib_lyrics', defaultValue: true, syncs: true),
  fanartArtistBackgrounds(
    'fanart_artist_backgrounds',
    defaultValue: true,
    syncs: true,
  ),
  catalogDiscovery('catalog_discovery', defaultValue: true, syncs: true),
  playerVolume('player_volume', defaultValue: 1.0),
  repeatMode('repeat_mode', defaultValue: 'off'),
  infinitePlayback('infinite_playback', defaultValue: true),
  playerTimeDisplay('player_time_display', defaultValue: 'remaining'),
  sleepTimerLast('sleep_timer_last', defaultValue: '', syncs: true),
  forwardCacheLimit('forward_cache_limit', defaultValue: 'off'),
  forwardCacheWindow('forward_cache_window', defaultValue: 'min30'),
  streamQualityWifi(
    'stream_quality_wifi',
    defaultValue: 'original',
  ),
  streamQualityCellular(
    'stream_quality_cellular',
    defaultValue: 'original',
  ),
  downloadQuality('download_quality', defaultValue: 'original'),
  downloadSyncOnCellular('download_sync_on_cellular'),
  offlineModeToggle('offline_mode_toggle'),
  manualOffline('manual_offline'),
  carTakesQueue('car_takes_queue'),
  hideContinuityInCastPicker('hide_continuity_in_cast_picker'),
  deviceName('device_name', defaultValue: ''),
  tvMiniPlayer('tv_mini_player', defaultValue: true),
  discordRichPresence('discord_rich_presence'),
  discordAlbumArt('discord_album_art', defaultValue: true),
  keepScreenOn('keep_screen_on', defaultValue: 'never'),
  contentUpdateInterval(
    'content_update_interval',
    defaultValue: 'min5',
    syncs: true,
  ),
  pinsEnabled('pins_enabled', defaultValue: true, syncs: true),
  pinLongevity('pin_longevity', defaultValue: 'days14', syncs: true),
  rendererVolumes(
    'renderer_volumes',
    defaultValue: <String, double>{},
    syncs: true,
  ),
  lidarrUrl('lidarr_url', defaultValue: ''),
  lidarrRootFolder('lidarr_root_folder', defaultValue: ''),
  lidarrQualityProfile(
    'lidarr_quality_profile',
    defaultValue: '',
  ),
  lidarrMetadataProfile(
    'lidarr_metadata_profile',
    defaultValue: '',
  ),
  lidarrSearchOnAdd('lidarr_search_on_add', defaultValue: true),
  lidarrHideAddButton('lidarr_hide_add_button'),
  lidarrMonitorArtistConfirmed(
    'lidarr_monitor_artist_confirmed',
  ),
  listenBrainzUser('listenbrainz_user', defaultValue: ''),
  listenBrainzApiUrl('listenbrainz_api_url', defaultValue: ''),
  lastFmUser('lastfm_user', defaultValue: ''),
  telemetryOptOut('telemetry_opt_out'),
  linkSync('link_sync', defaultValue: true);

  const AppSetting(this.key, {this.defaultValue = false, this.syncs = false});

  final String key;
  final Object defaultValue;
  final bool syncs;
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

final manualOfflineProvider = Provider<bool>(
  (ref) =>
      ref.watch(settingProvider(AppSetting.offlineModeToggle)) &&
      ref.watch(settingProvider(AppSetting.manualOffline)),
);

final defaultBrowseTabProvider = Provider<ItemList>(
  (ref) =>
      ItemList.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.defaultBrowseTab],
        AppSetting.defaultBrowseTab,
      )] ??
      ItemList.albums,
);

final browseLayoutProvider = Provider<BrowseLayout>(
  (ref) =>
      BrowseLayout.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.browseLayout],
        AppSetting.browseLayout,
      )] ??
      BrowseLayout.cards,
);

final ProviderFamily<Filter, ItemList> browseSortProvider =
    Provider.family<Filter, ItemList>(
      (ref, view) =>
          _browseSortOf(
            ref.watch(appSettingsProvider)[AppSetting.browseSort],
            ref.watch(currentServerIdProvider),
            view,
          ) ??
          Filter(
            orderBy: view.defaultSortField,
            desc: view.defaultSortDescending,
          ),
    );

final homePlaylistSortProvider = Provider<Filter>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return Filter(
    orderBy:
        EntityFilter.values.asNameMap()[_asString(
          settings[AppSetting.homePlaylistSort],
          AppSetting.homePlaylistSort,
        )] ??
        EntityFilter.dateLastContentAdded,
    desc: _asBool(
      settings[AppSetting.homePlaylistSortDescending],
      AppSetting.homePlaylistSortDescending,
    ),
  );
});

final artistBrowseScopeProvider = Provider<ArtistScope>(
  (ref) =>
      ArtistScope.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.artistBrowseScope],
        AppSetting.artistBrowseScope,
      )] ??
      ArtistScope.allArtists,
);

final forwardCacheLimitProvider = Provider<ForwardCacheLimit>(
  (ref) =>
      ForwardCacheLimit.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.forwardCacheLimit],
        AppSetting.forwardCacheLimit,
      )] ??
      ForwardCacheLimit.off,
);

final forwardCacheWindowProvider = Provider<ForwardCacheWindow>(
  (ref) =>
      ForwardCacheWindow.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.forwardCacheWindow],
        AppSetting.forwardCacheWindow,
      )] ??
      ForwardCacheWindow.min30,
);

final streamQualityWifiProvider = Provider<StreamQuality>(
  (ref) => _streamQuality(ref, AppSetting.streamQualityWifi),
);

final streamQualityCellularProvider = Provider<StreamQuality>(
  (ref) => _streamQuality(ref, AppSetting.streamQualityCellular),
);

final downloadQualityProvider = Provider<StreamQuality>(
  (ref) => _streamQuality(ref, AppSetting.downloadQuality),
);

StreamQuality _streamQuality(Ref ref, AppSetting setting) =>
    StreamQuality.values.asNameMap()[_asString(
      ref.watch(appSettingsProvider)[setting],
      setting,
    )] ??
    StreamQuality.original;

final contentUpdateIntervalProvider = Provider<ContentUpdateInterval>(
  (ref) =>
      ContentUpdateInterval.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.contentUpdateInterval],
        AppSetting.contentUpdateInterval,
      )] ??
      ContentUpdateInterval.min5,
);

final pinLongevityProvider = Provider<PinLongevity>(
  (ref) =>
      PinLongevity.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.pinLongevity],
        AppSetting.pinLongevity,
      )] ??
      PinLongevity.days14,
);

final animatedCoversProvider = Provider<AnimatedCovers>((ref) {
  final raw = ref.watch(appSettingsProvider)[AppSetting.animatedCovers];
  if (raw is bool) return raw ? AnimatedCovers.wifi : AnimatedCovers.never;
  return AnimatedCovers.values.asNameMap()[_asString(
        raw,
        AppSetting.animatedCovers,
      )] ??
      AnimatedCovers.always;
});

final keepScreenOnProvider = Provider<KeepScreenOn>(
  (ref) =>
      KeepScreenOn.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.keepScreenOn],
        AppSetting.keepScreenOn,
      )] ??
      KeepScreenOn.never,
);

final animationSpeedProvider = Provider<AnimationSpeed>(
  (ref) =>
      AnimationSpeed.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.animationSpeed],
        AppSetting.animationSpeed,
      )] ??
      AnimationSpeed.medium,
);

final studioLyricsPlacementProvider = Provider<StudioLyricsPlacement>(
  (ref) =>
      StudioLyricsPlacement.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.studioModeLyricsPlacement],
        AppSetting.studioModeLyricsPlacement,
      )] ??
      StudioLyricsPlacement.right,
);

final studioBackgroundProvider = Provider<StudioBackground>(
  (ref) =>
      StudioBackground.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.studioModeBackground],
        AppSetting.studioModeBackground,
      )] ??
      StudioBackground.aurora,
);

final lyricsAlignmentProvider = Provider<LyricsAlignment>(
  (ref) =>
      LyricsAlignment.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.lyricsAlignment],
        AppSetting.lyricsAlignment,
      )] ??
      LyricsAlignment.center,
);

final lyricsBlurProvider = Provider<LyricsBlur>(
  (ref) => TvMode.isTv
      ? LyricsBlur.off
      : LyricsBlur.values.asNameMap()[_asString(
              ref.watch(appSettingsProvider)[AppSetting.lyricsBlur],
              AppSetting.lyricsBlur,
            )] ??
            LyricsBlur.medium,
);

final playerTimeDisplayProvider = Provider<PlayerTimeDisplay>(
  (ref) =>
      PlayerTimeDisplay.values.asNameMap()[_asString(
        ref.watch(appSettingsProvider)[AppSetting.playerTimeDisplay],
        AppSetting.playerTimeDisplay,
      )] ??
      PlayerTimeDisplay.remaining,
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

Map<String, Object?> _stringKeyed(Object? raw) {
  if (raw case final Map<Object?, Object?> map) {
    return {
      for (final entry in map.entries)
        if (entry.key case final String key) key: entry.value,
    };
  }
  return const {};
}

Filter? _browseSortOf(Object? raw, String? serverId, ItemList view) {
  if (serverId == null) return null;
  if (_stringKeyed(_stringKeyed(raw)[serverId])[view.name] case {
    'field': final String field,
    'desc': final bool desc,
  }) {
    if (EntityFilter.values.asNameMap()[field] case final orderBy?) {
      return Filter(orderBy: orderBy, desc: desc);
    }
  }
  return null;
}

double _asDouble(Object? value, AppSetting setting) {
  final resolved = value ?? setting.defaultValue;
  return resolved is num ? resolved.toDouble() : 0;
}

class AppSettingsNotifier extends StateNotifier<Map<AppSetting, Object>> {
  AppSettingsNotifier(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _stamps = _readStamps(_prefs),
      super(_read(_prefs));

  static const _storageKey = 'app_settings';
  static const _stampsKey = 'app_settings_updated';

  final SharedPreferences? _prefs;
  final DateTime Function() _now;
  final Map<String, int> _stamps;

  static const _legacyStamp = 1;

  static Map<String, int> _readStamps(SharedPreferences? prefs) {
    final stored = prefs?.getString(_stampsKey);
    if (stored == null) {
      return {
        for (final setting in _read(prefs).keys) setting.key: _legacyStamp,
      };
    }
    return {
      for (final entry in (jsonDecode(stored) as Map<String, dynamic>).entries)
        if (entry.value case final num stamp) entry.key: stamp.toInt(),
    };
  }

  static Object? _coerce(Object? raw) => switch (raw) {
    final bool value => value,
    final String value => value,
    final num value => value.toDouble(),
    final Map<String, dynamic> value => value,
    _ => null,
  };

  Map<String, Object?> get syncedValues => {
    for (final setting in AppSetting.values)
      if (setting.syncs && state[setting] != null) setting.key: state[setting],
  };

  Map<String, int> get syncStamps => {
    for (final setting in AppSetting.values)
      if (setting.syncs && _stamps[setting.key] != null)
        setting.key: _stamps[setting.key]!,
  };

  void applyRemote(Map<String, Object?> values, Map<String, int> stamps) {
    final changed = <AppSetting, Object>{};
    for (final setting in AppSetting.values) {
      if (!setting.syncs || !values.containsKey(setting.key)) continue;
      final value = _coerce(values[setting.key]);
      final stamp = stamps[setting.key];
      if (value == null || stamp == null) continue;
      _stamps[setting.key] = stamp;
      if (state[setting] != value) changed[setting] = value;
    }
    if (changed.isNotEmpty) state = {...state, ...changed};
    _persist();
  }

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
        else if (decoded[setting.key] case final Map<String, dynamic> value)
          setting: value
        else if (prefs.getBool(setting.key) case final bool legacy)
          setting: legacy,
    };
  }

  static bool isEnabledIn(SharedPreferences? prefs, AppSetting setting) =>
      _asBool(_read(prefs)[setting], setting);

  static String valueIn(SharedPreferences? prefs, AppSetting setting) =>
      _asString(_read(prefs)[setting], setting);

  bool isEnabled(AppSetting setting) => _asBool(state[setting], setting);

  double? rendererVolume(String deviceId) {
    final level = _rendererVolumes()[deviceId];
    return level == null ? null : level.clamp(0.0, 1.0);
  }

  void setRendererVolume(String deviceId, double level) => _store(
    AppSetting.rendererVolumes,
    {..._rendererVolumes(), deviceId: level.clamp(0.0, 1.0)},
  );

  Map<String, double> _rendererVolumes() {
    if (state[AppSetting.rendererVolumes]
        case final Map<Object?, Object?> raw) {
      return {
        for (final entry in raw.entries)
          if (entry.key case final String key)
            if (entry.value case final num level) key: level.toDouble(),
      };
    }
    return const {};
  }

  void setHomePlaylistSort(Filter filter) => _storeAll({
    AppSetting.homePlaylistSort: filter.orderBy.name,
    AppSetting.homePlaylistSortDescending: filter.desc,
  });

  void setBrowseSort(String serverId, ItemList view, Filter filter) {
    final all = _stringKeyed(state[AppSetting.browseSort]);
    _store(AppSetting.browseSort, {
      ...all,
      serverId: {
        ..._stringKeyed(all[serverId]),
        view.name: {'field': filter.orderBy.name, 'desc': filter.desc},
      },
    });
  }

  String valueOf(AppSetting setting) => _asString(state[setting], setting);

  double numberOf(AppSetting setting) => _asDouble(state[setting], setting);

  void setEnabled(AppSetting setting, {required bool value}) =>
      _store(setting, value);

  void setValue(AppSetting setting, String value) => _store(setting, value);

  void setNumber(AppSetting setting, double value) => _store(setting, value);

  void toggle(AppSetting setting) =>
      setEnabled(setting, value: !isEnabled(setting));

  void _store(AppSetting setting, Object value) => _storeAll({setting: value});

  void _storeAll(Map<AppSetting, Object> values) {
    final changed = {
      for (final entry in values.entries)
        if (state[entry.key] != entry.value) entry.key: entry.value,
    };
    if (changed.isEmpty) return;
    state = {...state, ...changed};
    final stamp = _now().toUtc().millisecondsSinceEpoch;
    for (final setting in changed.keys) {
      _stamps[setting.key] = stamp;
    }
    _persist();
  }

  void _persist() {
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
    unawaited(prefs.setString(_stampsKey, jsonEncode(_stamps)));
  }
}
