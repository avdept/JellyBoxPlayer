import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/discord/discord_presence_handler.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';
import 'package:jplayer/src/domain/providers/conductor_provider.dart';
import 'package:jplayer/src/presentation/pages/handoff_bench_page.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Padding for the settings buttons so their hover/highlight state has
  /// breathing room (the global [TextButtonThemeData] uses zero padding).
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  static const Map<ItemList, String> _browseTabLabels = {
    ItemList.albums: 'Albums',
    ItemList.artists: 'Artists',
    ItemList.songs: 'Songs',
    ItemList.playlists: 'Playlists',
    ItemList.genres: 'Genres',
  };

  static const Map<KeepScreenOn, String> _keepScreenOnLabels = {
    KeepScreenOn.never: 'Never',
    KeepScreenOn.charging: 'While charging',
    KeepScreenOn.always: 'Always',
  };

  static const Map<AnimationSpeed, String> _animationSpeedLabels = {
    AnimationSpeed.none: 'None',
    AnimationSpeed.slow: 'Slow',
    AnimationSpeed.medium: 'Medium',
    AnimationSpeed.fast: 'Fast',
  };

  static const Map<StartPage, String> _startPageLabels = {
    StartPage.home: 'Home',
    StartPage.browse: 'Browse',
  };

  static const Map<ForwardCacheWindow, String> _forwardCacheWindowLabels = {
    ForwardCacheWindow.min10: '10 min',
    ForwardCacheWindow.min15: '15 min',
    ForwardCacheWindow.min30: '30 min',
    ForwardCacheWindow.min45: '45 min',
    ForwardCacheWindow.min60: '60 min',
  };

  static const Map<ContentUpdateInterval, String> _contentUpdateLabels = {
    ContentUpdateInterval.min1: '1 minute',
    ContentUpdateInterval.min5: '5 minutes',
    ContentUpdateInterval.min15: '15 minutes',
    ContentUpdateInterval.min30: '30 minutes',
    ContentUpdateInterval.never: 'Never',
  };

  static const Map<ForwardCacheLimit, String> _forwardCacheLabels = {
    ForwardCacheLimit.off: 'Off',
    ForwardCacheLimit.mb500: '500 MB',
    ForwardCacheLimit.gb1: '1 GB',
    ForwardCacheLimit.gb2: '2 GB',
    ForwardCacheLimit.gb4: '4 GB',
    ForwardCacheLimit.gb8: '8 GB',
  };

  ButtonStyle get _buttonStyle => TextButton.styleFrom(
    padding: _buttonPadding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _onLibrariesPressed(BuildContext context) =>
      context.pushNamed(Routes.library.name);

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
          title: changelogTitle,
        ),
      );
    } else {
      unawaited(
        showUpdatifyBottomSheet(
          context,
          projectId: updatifyProjectId,
          backgroundColor: Themes.changelogSurface,
          borderRadius: BorderRadius.circular(8),
          title: changelogTitle,
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
                  'Settings',
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
                    _librariesButton(context),
                    if (kDebugMode) _settingsButton(context),
                    if (kDebugMode) _queueCacheButton(context),
                    if (kDebugMode) _handoffBenchButton(context, ref),
                    _changelogButton(context, device),
                    _sectionHeader('Continuity'),
                    _conductorUrlField(ref),
                    _conductorStatus(context, ref),
                    _sectionHeader('Home Page'),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.generatedPlaylistsDisabled,
                      label: 'Disable auto-generated playlists',
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.favouritesHidden,
                      label: 'Hide favourites',
                    ),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.recentlyPlayedHidden,
                      label: 'Hide recently played',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _settingDropdown<ContentUpdateInterval>(
                          context: context,
                          label: 'Content update interval',
                          value: ref.watch(contentUpdateIntervalProvider),
                          options: _contentUpdateLabels,
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
                    _sectionHeader('UI'),
                    _settingDropdown<StartPage>(
                      context: context,
                      label: 'Default start page',
                      value: ref.watch(defaultStartPageProvider),
                      options: _startPageLabels,
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.defaultStartPage, value.name),
                    ),
                    if (!device.isMobile)
                      _settingDropdown<AnimationSpeed>(
                        context: context,
                        label: 'Animation speed',
                        value: ref.watch(animationSpeedProvider),
                        options: _animationSpeedLabels,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.animationSpeed, value.name),
                      ),
                    _settingDropdown<ItemList>(
                      context: context,
                      label: 'Default browse tab',
                      value: ref.watch(defaultBrowseTabProvider),
                      options: _browseTabLabels,
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.defaultBrowseTab, value.name),
                    ),
                    _sectionHeader('Cache'),
                    _settingDropdown<ForwardCacheLimit>(
                      context: context,
                      label: 'Cache limit',
                      value: ref.watch(forwardCacheLimitProvider),
                      options: _forwardCacheLabels,
                      onChanged: (value) => ref
                          .read(appSettingsProvider.notifier)
                          .setValue(AppSetting.forwardCacheLimit, value.name),
                      trailing: _purgeCacheButton(context, ref),
                    ),
                    if (ref.watch(forwardCacheLimitProvider).isEnabled)
                      _settingDropdown<ForwardCacheWindow>(
                        context: context,
                        label: 'Cache ahead',
                        value: ref.watch(forwardCacheWindowProvider),
                        options: _forwardCacheWindowLabels,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(
                              AppSetting.forwardCacheWindow,
                              value.name,
                            ),
                      ),
                    if (device.isMobile) ...[
                      _sectionHeader('Landscape player'),
                      _settingDropdown<KeepScreenOn>(
                        context: context,
                        label: 'Keep the screen on',
                        value: ref.watch(keepScreenOnProvider),
                        options: _keepScreenOnLabels,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.keepScreenOn, value.name),
                      ),
                      _settingDropdown<AnimationSpeed>(
                        context: context,
                        label: 'Animation speed',
                        value: ref.watch(animationSpeedProvider),
                        options: _animationSpeedLabels,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .setValue(AppSetting.animationSpeed, value.name),
                      ),
                    ],
                    if (!device.isMobile) ...[
                      _sectionHeader('Studio Mode'),
                      if (supportsWindowFullscreen)
                        _settingCheckbox(
                          ref: ref,
                          setting: AppSetting.studioModeFullscreen,
                          label:
                              'Make player full screen when Studio Mode enabled',
                        ),
                    ],
                    if (supportsDiscordPresence) ...[
                      _sectionHeader('Discord'),
                      _settingCheckbox(
                        ref: ref,
                        setting: AppSetting.discordRichPresence,
                        label: 'Share what I am listening to on Discord',
                      ),
                    ],
                    _sectionHeader('ListenBrainz'),
                    const ListenBrainzSettings(),
                    _sectionHeader('Privacy'),
                    _settingCheckbox(
                      ref: ref,
                      setting: AppSetting.telemetryOptOut,
                      label: 'Opt out of analytics and crash reports',
                    ),
                    _settingNote(
                      context,
                      'Jellybox counts app launches and sends crash reports to '
                      'help fix bugs. Nothing about your library or listening '
                      'is collected.',
                    ),
                    if (!device.isDesktop) _logOutButton(ref),
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
      tooltip: 'Empty cache',
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
    );
  }

  Future<void> _onPurgeCachePressed(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Empty the cache?', textAlign: TextAlign.center),
        content: const Text(
          'Tracks cached ahead for offline playback will be deleted.',
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(forwardCacheProvider.notifier).purge();
    messenger.showSnackBar(const SnackBar(content: Text('Cache emptied')));
  }

  Widget _queueCacheButton(BuildContext context) => TextButton.icon(
    onPressed: () => context.pushNamed(Routes.queueCache.name),
    style: _buttonStyle,
    icon: const Icon(JPlayer.download),
    label: const Text('Queue cache'),
  );

  Widget _settingsButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onPaletteSettingsPressed(context),
    style: _buttonStyle,
    icon: const Icon(JPlayer.music),
    label: const Text('Palette settings'),
  );

  Widget _librariesButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onLibrariesPressed(context),
    style: _buttonStyle,
    icon: const Icon(JPlayer.music),
    label: const Text('Music libraries'),
  );

  Widget _changelogButton(BuildContext context, DeviceType device) {
    return TextButton.icon(
      onPressed: () => _onChangelogPressed(context, device),
      style: _buttonStyle,
      icon: const Icon(Icons.history),
      label: const Text('Changelog'),
    );
  }

  Widget _refreshContentButton(BuildContext context, WidgetRef ref) =>
      IconButton(
        onPressed: () {
          ref.refreshHomeSections();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Home page refreshed')),
            );
        },
        tooltip: 'Refresh now',
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
            ? 'Version ${appInfo.version}'
            : 'Version ${appInfo.version} ($build)',
        style: TextStyle(
          fontSize: 12,
          height: 1.2,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _handoffBenchButton(BuildContext context, WidgetRef ref) =>
      TextButton.icon(
        onPressed: () {
          final album = ref.read(playbackProvider).album;
          if (album == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Play an album first — the bench hands off its queue.',
                ),
              ),
            );
            return;
          }
          unawaited(Navigator.of(context).push(HandoffBenchPage.route(album)));
        },
        style: _buttonStyle,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Handoff bench'),
      );

  Widget _conductorUrlField(WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
    child: SizedBox(
      width: 320,
      child: TextFormField(
        initialValue: ref.read(conductorUrlProvider),
        decoration: const InputDecoration(
          labelText: 'Conductor address',
          hintText: '192.168.1.10:4010',
          helperText: 'Leave empty to turn continuity off',
        ),
        onFieldSubmitted: (value) =>
            ref.read(conductorUrlProvider.notifier).url = value,
      ),
    ),
  );

  Widget _conductorStatus(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conductorProvider);
    final label = switch (state.status) {
      ConductorStatus.off => 'Off',
      ConductorStatus.connecting => 'Connecting...',
      ConductorStatus.reconnecting => 'Reconnecting...',
      ConductorStatus.error => state.error ?? 'Connection problem',
      ConductorStatus.listening => 'Connected — playing elsewhere',
      ConductorStatus.rendering => 'Connected — playing here',
    };

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label · ${state.devices.length} device'
            '${state.devices.length == 1 ? '' : 's'}',
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => unawaited(ConductorDevicesSheet.show(context)),
            style: _buttonStyle,
            icon: const Icon(Icons.devices),
            label: const Text('Play on...'),
          ),
        ],
      ),
    );
  }

  Widget _logOutButton(WidgetRef ref) => TextButton.icon(
    onPressed: ref.read(authProvider.notifier).logout,
    style: _buttonStyle,
    icon: const Icon(JPlayer.log_out),
    label: const Text('Log out'),
  );
}
