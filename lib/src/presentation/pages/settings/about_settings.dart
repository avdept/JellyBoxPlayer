import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class AboutSettings extends ConsumerWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        const SettingsGroupHeader('Privacy'),
        const SettingCheckbox(
          setting: AppSetting.telemetryOptOut,
          label: 'Opt out of analytics and crash reports',
        ),
        const SettingNote(
          'Jellybox counts app launches and sends crash reports to '
          'help fix bugs. Nothing about your library or listening '
          'is collected.',
        ),
        const SettingsGroupHeader('App'),
        TextButton.icon(
          onPressed: () => _onChangelogPressed(context, device),
          style: settingsButtonStyle(),
          icon: const Icon(Icons.history),
          label: const Text('Changelog'),
        ),
        if (kDebugMode) ...[
          TextButton.icon(
            onPressed: () => context.pushNamed(Routes.palette.name),
            style: settingsButtonStyle(),
            icon: const Icon(JPlayer.music),
            label: const Text('Palette settings'),
          ),
          TextButton.icon(
            onPressed: () => context.pushNamed(Routes.queueCache.name),
            style: settingsButtonStyle(),
            icon: const Icon(JPlayer.download),
            label: const Text('Queue cache'),
          ),
        ],
        _versionLabel(context),
      ],
    );
  }

  void _onChangelogPressed(BuildContext context, DeviceType device) {
    if (device.isDesktop) {
      unawaited(
        showUpdatifyDialog(
          context,
          projectId: updatifyProjectId,
          backgroundColor: AppColors.from(context).surface,
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
          backgroundColor: AppColors.from(context).surface,
          borderRadius: BorderRadius.circular(8),
          title: changelogTitle,
        ),
      );
    }
  }

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
}
