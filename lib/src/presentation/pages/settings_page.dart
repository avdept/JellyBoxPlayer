import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';
import 'package:jplayer/src/domain/providers/conductor_provider.dart';
import 'package:jplayer/src/presentation/pages/handoff_bench_page.dart';
import 'package:jplayer/src/presentation/widgets/conductor_devices_sheet.dart';
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

  ButtonStyle get _buttonStyle => TextButton.styleFrom(
    padding: _buttonPadding,
    // Match the 8px corner radius used by the sidebar navigation rail items.
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Padding(
              padding: EdgeInsets.only(
                left: contentPadding.left,
                right: contentPadding.right,
              ),
              child: Wrap(
                direction: Axis.vertical,
                spacing: 4,
                children: [
                  _librariesButton(context),
                  if (kDebugMode) _settingsButton(context),
                  if (kDebugMode) _handoffBenchButton(context, ref),
                  _conductorHeader(),
                  _conductorUrlField(ref),
                  _conductorStatus(context, ref),
                  _changelogButton(context, device),
                  _settingCheckbox(
                    ref: ref,
                    provider: generatedPlaylistsDisabledProvider,
                    label: 'Disable auto-generated playlists',
                  ),
                  if (!device.isMobile) ...[
                    _studioModeHeader(),
                    if (supportsWindowFullscreen)
                      _settingCheckbox(
                        ref: ref,
                        provider: studioModeFullscreenProvider,
                        label:
                            'Make player full screen when Studio Mode enabled',
                      ),
                    _settingCheckbox(
                      ref: ref,
                      provider: studioModeAnimationProvider,
                      label: 'Enable Studio Mode animation',
                    ),
                  ],
                  if (!device.isDesktop) _logOutButton(ref),
                ],
              ),
            ),
            SizedBox(height: contentPadding.bottom),
          ],
        ),
      ),
    );
  }

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

  Widget _studioModeHeader() => const Padding(
    padding: EdgeInsets.only(left: 12, top: 20, bottom: 4),
    child: Text(
      'Studio Mode',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  );

  Widget _settingCheckbox({
    required WidgetRef ref,
    required StateNotifierProvider<BoolPrefNotifier, bool> provider,
    required String label,
  }) {
    final enabled = ref.watch(provider);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: enabled,
            onChanged: (value) =>
                ref.read(provider.notifier).enabled = value ?? false,
          ),
          Text(label),
        ],
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

  Widget _conductorHeader() => const Padding(
    padding: EdgeInsets.only(left: 12, top: 20, bottom: 4),
    child: Text(
      'Continuity',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.2),
    ),
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
