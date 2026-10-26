import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/discord/discord_presence_handler.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Padding for the settings buttons so their hover/highlight state has
  /// breathing room (the global [TextButtonThemeData] uses zero padding).
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  static Map<ItemList, String> _browseTabLabels(BuildContext context) => {
    ItemList.albums: S.of(context).albums,
    ItemList.artists: S.of(context).artists,
    ItemList.songs: S.of(context).songs,
    ItemList.playlists: S.of(context).playlists,
    ItemList.genres: S.of(context).genres,
  };

  static Map<KeepScreenOn, String> _keepScreenOnLabels(BuildContext context) =>
      {
        KeepScreenOn.never: S.of(context).never,
        KeepScreenOn.charging: S.of(context).whileCharging,
        KeepScreenOn.always: S.of(context).always,
      };

  static Map<AnimationSpeed, String> _animationSpeedLabels(
    BuildContext context,
  ) => {
    AnimationSpeed.none: S.of(context).none,
    AnimationSpeed.slow: S.of(context).slow,
    AnimationSpeed.medium: S.of(context).medium,
    AnimationSpeed.fast: S.of(context).fast,
  };

  static Map<LyricsAlignment, String> _lyricsAlignmentLabels(
    BuildContext context,
  ) => {
    LyricsAlignment.left: S.of(context).left,
    LyricsAlignment.center: S.of(context).middle,
    LyricsAlignment.right: S.of(context).right,
  };

  static Map<StartPage, String> _startPageLabels(BuildContext context) => {
    StartPage.home: S.of(context).home,
    StartPage.browse: S.of(context).browse,
  };

  static const Map<String, String> _languageEndonyms = {
    'en': 'English',
  };

  static Map<String, String> _languageLabels(BuildContext context) => {
    'system': S.of(context).system,
    for (final locale in S.delegate.supportedLocales)
      locale.toString():
          _languageEndonyms[locale.toString()] ?? locale.toString(),
  };

  static String _selectedLanguage(WidgetRef ref) {
    final value = ref.watch(appSettingsProvider)[AppSetting.appLanguage];
    final known = {
      'system',
      for (final locale in S.delegate.supportedLocales) locale.toString(),
    };
    return value is String && known.contains(value) ? value : 'system';
  }

  static Map<ForwardCacheWindow, String> _forwardCacheWindowLabels(
    BuildContext context,
  ) => {
    ForwardCacheWindow.min10: S.of(context).minutesAbbreviated(10),
    ForwardCacheWindow.min15: S.of(context).minutesAbbreviated(15),
    ForwardCacheWindow.min30: S.of(context).minutesAbbreviated(30),
    ForwardCacheWindow.min45: S.of(context).minutesAbbreviated(45),
    ForwardCacheWindow.min60: S.of(context).minutesAbbreviated(60),
  };

  static Map<StreamQuality, String> _streamQualityLabels(
    BuildContext context,
  ) => {
    StreamQuality.original: S.of(context).original,
    StreamQuality.kbps320: S.of(context).kbpsLabel(320),
    StreamQuality.kbps256: S.of(context).kbpsLabel(256),
    StreamQuality.kbps192: S.of(context).kbpsLabel(192),
    StreamQuality.kbps128: S.of(context).kbpsLabel(128),
    StreamQuality.kbps96: S.of(context).kbpsLabel(96),
    StreamQuality.kbps64: S.of(context).kbpsLabel(64),
  };

  static Map<ContentUpdateInterval, String> _contentUpdateLabels(
    BuildContext context,
  ) => {
    ContentUpdateInterval.min1: S.of(context).minutesCount(1),
    ContentUpdateInterval.min5: S.of(context).minutesCount(5),
    ContentUpdateInterval.min15: S.of(context).minutesCount(15),
    ContentUpdateInterval.min30: S.of(context).minutesCount(30),
    ContentUpdateInterval.never: S.of(context).never,
  };

  static Map<ForwardCacheLimit, String> _forwardCacheLabels(
    BuildContext context,
  ) => {
    ForwardCacheLimit.off: S.of(context).off,
    ForwardCacheLimit.mb500: S.of(context).megabytesLabel(500),
    ForwardCacheLimit.gb1: S.of(context).gigabytesLabel(1),
    ForwardCacheLimit.gb2: S.of(context).gigabytesLabel(2),
    ForwardCacheLimit.gb4: S.of(context).gigabytesLabel(4),
    ForwardCacheLimit.gb8: S.of(context).gigabytesLabel(8),
  };

  ButtonStyle get _buttonStyle => TextButton.styleFrom(
    padding: _buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _onPaletteSettingsPressed(BuildContext context) =>
      context.pushNamed(Routes.palette.name);

  void _onChangelogPressed(BuildContext context, DeviceType device) {
    if (device.isDesktop) {
      unawaited(
        showUpdatifyDialog(
          context,
          projectId: updatifyProjectId,
          backgroundColor: Themes.changelogSurface,
          borderRadius: BorderRadius.circular(8),
          width: MediaQuery.sizeOf(context).width / 2,
          title: S.of(context).whatsNew,
        ),
      );
    } else {
      unawaited(
        showUpdatifyBottomSheet(
          context,
          projectId: updatifyProjectId,
          backgroundColor: Themes.changelogSurface,
          borderRadius: BorderRadius.circular(8),
          title: S.of(context).whatsNew,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.paddingOf(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final contentPadding = EdgeInsets.only(
      left: padding.left + (device.isMobile ? 16 : 30),
      top: padding.top + (device.isMobile ? 16 : 30),
      right: padding.right + (device.isMobile ? 16 : 30),
      bottom: device.isMobile ? 22 : 26,
    );

    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientPanelDecoration(
              child: Padding(
                padding: EdgeInsets.only(
                  left: contentPadding.left,
                  top: contentPadding.top,
                  right: contentPadding.right,
                  bottom: 20,
                ),
                child: Text(
                  S.of(context).settings,
                  style: TextStyle(
                    fontSize: device.isMobile ? 24 : 36,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: contentPadding.left,
                  right: contentPadding.right,
                  bottom: contentPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    if (!device.isDesktop) ...[
                      const SizedBox(height: 4),
                      _supportButton(context),
                    ],
                    _sectionHeader(S.of(context).servers),
                    const ServerAccountList(),
                    _sectionHeader(S.of(context).connection),
                    const ServerAddressSettings(),
                    if (ref.watch(cloudAvailableProvider)) ...[
                      _sectionHeader('Jellybox Cloud'),
                      const JellyboxCloudSettings(),
                    ],
                    _sectionHeader(S.of(context).general),
                    if (kDebugMode) _settingsButton(context),
                    if (kDebugMode) _queueCacheButton(context),
                    _changelogButton(context, device),
                    _sectionHeader(S.of(context).homePage),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.generatedPlaylistsDisabled,
                      label: S.of(context).disableAutoGeneratedPlaylists,
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.favouritesHidden,
                      label: S.of(context).hideFavourites,
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.recentlyPlayedHidden,
                      label: S.of(context).hideRecentlyPlayed,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _settingDropdown<ContentUpdateInterval>(
                          context: context,
                          label: S.of(context).contentUpdateInterval,
                          value: ref.watch(contentUpdateIntervalProvider),
                          options: _contentUpdateLabels(context),
                          onChanged: (value) => ref
                              .read(appSettingsProvider.notifier)
                              .setValue(
                                AppSetting.contentUpdateInterval,
                                value.name,
                              ),
                        ),
                        _refreshContentButton(context, ref),
                      ],
                    ),
                    _settingNote(
                      context,
                      S.of(context).contentUpdateIntervalNote,
                    ),
                    _sectionHeader(S.of(context).ui),
                    _settingDropdown<String>(
                      context: context,
                      label: S.of(context).language,
                      value: _selectedLanguage(ref),
                      options: _languageLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.appLanguage, value),
                    ),
                    _settingDropdown<StartPage>(
                      context: context,
                      label: S.of(context).defaultStartPage,
                      value: ref.watch(defaultStartPageProvider),
                      options: _startPageLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.defaultStartPage, value.name),
                    ),
                    if (!device.isMobile) ...[
                      _settingDropdown<AnimationSpeed>(
                        context: context,
                        label: S.of(context).animationSpeed,
                        value: ref.watch(animationSpeedProvider),
                        options: _animationSpeedLabels(context),
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.animationSpeed, value.name),
                      ),
                      _settingNote(
                        context,
                        S.of(context).animationSpeedNote,
                      ),
                    ],
                    _settingDropdown<ItemList>(
                      context: context,
                      label: S.of(context).defaultBrowseTab,
                      value: ref.watch(defaultBrowseTabProvider),
                      options: _browseTabLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.defaultBrowseTab, value.name),
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.letterRuler,
                      label: S.of(context).letterRulerSetting,
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.artworkAccent,
                      label: S.of(context).artworkAccentSetting,
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.nowPlayingHalo,
                      label: S.of(context).nowPlayingHaloSetting,
                    ),
                    if (device.isMobile) ...[
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.albumArtTint,
                        label: S.of(context).albumArtTintSetting,
                      ),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.animatedCovers,
                        label: S.of(context).animatedAlbumCovers,
                      ),
                      _settingNote(
                        context,
                        S.of(context).animatedCoversNote,
                      ),
                    ],
                    _sectionHeader(S.of(context).streaming),
                    _settingDropdown<StreamQuality>(
                      context: context,
                      label: deviceHasCellular
                          ? S.of(context).wifi
                          : S.of(context).streamingQuality,
                      value: ref.watch(streamQualityWifiProvider),
                      options: _streamQualityLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.streamQualityWifi, value.name),
                    ),
                    if (deviceHasCellular)
                      _settingDropdown<StreamQuality>(
                        context: context,
                        label: S.of(context).cellular,
                        value: ref.watch(streamQualityCellularProvider),
                        options: _streamQualityLabels(context),
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(
                              AppSetting.streamQualityCellular,
                              value.name,
                            ),
                      ),
                    _settingNote(
                      context,
                      S.of(context).streamingQualityNote,
                    ),
                    if (deviceHasCellular) ...[
                      _sectionHeader(S.of(context).downloads),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.downloadSyncOnCellular,
                        label: S.of(context).downloadSyncOnCellularSetting,
                      ),
                      _settingNote(
                        context,
                        S.of(context).downloadSyncNote,
                      ),
                    ],
                    _sectionHeader(S.of(context).cache),
                    _settingDropdown<ForwardCacheLimit>(
                      context: context,
                      label: S.of(context).cacheLimit,
                      value: ref.watch(forwardCacheLimitProvider),
                      options: _forwardCacheLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.forwardCacheLimit, value.name),
                      trailing: _purgeCacheButton(context, ref),
                    ),
                    if (ref.watch(forwardCacheLimitProvider).isEnabled)
                      _settingDropdown<ForwardCacheWindow>(
                        context: context,
                        label: S.of(context).cacheAhead,
                        value: ref.watch(forwardCacheWindowProvider),
                        options: _forwardCacheWindowLabels(context),
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(
                              AppSetting.forwardCacheWindow,
                              value.name,
                            ),
                      ),
                    _clearImageCacheButton(context),
                    if (device.isMobile) ...[
                      _sectionHeader(S.of(context).landscapePlayer),
                      _settingDropdown<KeepScreenOn>(
                        context: context,
                        label: S.of(context).keepTheScreenOn,
                        value: ref.watch(keepScreenOnProvider),
                        options: _keepScreenOnLabels(context),
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.keepScreenOn, value.name),
                      ),
                      _settingDropdown<AnimationSpeed>(
                        context: context,
                        label: S.of(context).animationSpeed,
                        value: ref.watch(animationSpeedProvider),
                        options: _animationSpeedLabels(context),
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.animationSpeed, value.name),
                      ),
                      _settingNote(
                        context,
                        S.of(context).animationSpeedNote,
                      ),
                    ],
                    if (!device.isMobile) ...[
                      _sectionHeader(S.of(context).studioMode),
                      if (supportsWindowFullscreen)
                        _settingCheckbox(
                          ref: ref,
                          setting: AppSetting.studioModeFullscreen,
                          label: S.of(context).studioModeFullscreenSetting,
                        ),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.studioModeVideoCovers,
                        label: S.of(context).useVideoCoversSetting,
                      ),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.studioModePinnedControls,
                        label: S.of(context).alwaysShowControls,
                      ),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.studioModeCoverOverVideo,
                        label: S.of(context).coverOverVideoSetting,
                      ),
                    ],
                    if (supportsDiscordPresence) ...[
                      _sectionHeader('Discord'),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.discordRichPresence,
                        label: S.of(context).discordPresenceSetting,
                      ),
                    ],
                    _sectionHeader('ListenBrainz'),
                    const ListenBrainzSettings(),
                    _sectionHeader(S.of(context).lyrics),
                    _settingDropdown<LyricsAlignment>(
                      context: context,
                      label: S.of(context).lyricsTextAlignment,
                      value: ref.watch(lyricsAlignmentProvider),
                      options: _lyricsAlignmentLabels(context),
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.lyricsAlignment, value.name),
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.lrclibLyrics,
                      label: S.of(context).lrclibLyricsSetting,
                    ),
                    _settingNote(
                      context,
                      S.of(context).lrclibLyricsNote,
                    ),
                    _sectionHeader(S.of(context).privacy),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.telemetryOptOut,
                      label: S.of(context).telemetryOptOutSetting,
                    ),
                    _settingNote(
                      context,
                      S.of(context).telemetryNote,
                    ),
                    if (!device.isDesktop) _logOutButton(context, ref),
                    _versionLabel(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purgeCacheButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () => _onPurgeCachePressed(context, ref),
      icon: const Icon(Icons.delete_outline, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      visualDensity: VisualDensity.compact,
      tooltip: S.of(context).emptyCache,
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
    );
  }

  Future<void> _onPurgeCachePressed(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(S.of(context).emptyCacheQuestion, textAlign: TextAlign.center),
        content: Text(
          S.of(context).emptyCacheWarning,
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).no),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = S.of(context).cacheEmptied;
    await ref.read(forwardCacheProvider.notifier).purge();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _clearImageCacheButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onClearImageCachePressed(context),
    style: _buttonStyle,
    icon: const Icon(Icons.image_not_supported_outlined),
    label: Text(S.of(context).clearImageCache),
  );

  Future<void> _onClearImageCachePressed(BuildContext context) async {
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(
          S.of(context).clearImageCacheQuestion,
          textAlign: TextAlign.center,
        ),
        content: Text(
          S.of(context).clearImageCacheWarning,
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).no),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = S.of(context).imageCacheCleared;
    await ArtworkCache.instance.emptyCache();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _queueCacheButton(BuildContext context) => TextButton.icon(
    onPressed: () => context.pushNamed(Routes.queueCache.name),
    style: _buttonStyle,
    icon: const Icon(JPlayer.download),
    label: Text(S.of(context).queueCache),
  );

  Widget _settingsButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onPaletteSettingsPressed(context),
    style: _buttonStyle,
    icon: const Icon(JPlayer.music),
    label: Text(S.of(context).paletteSettings),
  );

  Widget _supportButton(BuildContext context) => TextButton.icon(
    onPressed: () => context.pushNamed(Routes.support.name),
    style: _buttonStyle,
    icon: const Icon(Icons.help_outline),
    label: Text(S.of(context).support),
  );

  Widget _changelogButton(BuildContext context, DeviceType device) {
    return TextButton.icon(
      onPressed: () => _onChangelogPressed(context, device),
      style: _buttonStyle,
      icon: const Icon(Icons.history),
      label: Text(S.of(context).changelog),
    );
  }

  Widget _refreshContentButton(BuildContext context, WidgetRef ref) =>
      IconButton(
        onPressed: () {
          ref.refreshHomeSections();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(S.of(context).homePageRefreshed)),
            );
        },
        tooltip: S.of(context).refreshNow,
        iconSize: 20,
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        icon: const Icon(Icons.refresh),
      );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 20, bottom: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  );

  Widget _settingDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                height: 1.2,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<T>(
                isExpanded: true,
                buttonStyleData: ButtonStyleData(
                  height: 30,
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                iconStyleData: const IconStyleData(iconSize: 20),
                menuItemStyleData: const MenuItemStyleData(
                  height: 34,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                dropdownStyleData: DropdownStyleData(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  offset: const Offset(0, -6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: [
                  for (final entry in options.entries)
                    DropdownMenuItem<T>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: (entry.key == value)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
                value: value,
                onChanged: (selected) {
                  if (selected != null) onChanged(selected);
                },
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _settingCheckbox({
    required WidgetRef ref,
    required AppSetting setting,
    required String label,
  }) {
    final enabled = ref.watch(settingProvider(setting));
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: enabled,
            onChanged: (value) => ref
                .read(appSettingsProvider.notifier)
                .setEnabled(setting, value: value ?? false),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _settingNote(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 2, right: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
      ),
    ),
  );

  Widget _versionLabel(BuildContext context) {
    final build = appInfo.buildNumber;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 20),
      child: Text(
        build.isEmpty
            ? S.of(context).versionLabel(appInfo.version)
            : S.of(context).versionBuildLabel(appInfo.version, build),
        style: TextStyle(
          fontSize: 12,
          height: 1.2,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _logOutButton(BuildContext context, WidgetRef ref) =>
      TextButton.icon(
        onPressed: ref.read(authProvider.notifier).logout,
        style: _buttonStyle,
        icon: const Icon(JPlayer.log_out),
        label: Text(
          ref.watch(accountsProvider).length > 1
              ? S.of(context).logOutOfAllServers
              : S.of(context).logOut,
        ),
      );
}
