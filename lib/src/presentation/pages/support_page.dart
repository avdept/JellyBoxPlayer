import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _email = 'jellybox@prodigytech.dev';
  static final Uri _discordUri = Uri.parse('https://discord.gg/vttezPMvKh');
  static final Uri _issuesUri = Uri.parse(
    'https://github.com/avdept/JellyBoxPlayer/issues',
  );
  static final Uri _donateUri = Uri.parse(
    'https://www.buymeacoffee.com/avdept',
  );

  static Uri _emailUri() {
    final build = appInfo.buildNumber;
    final version = build.isEmpty
        ? appInfo.version
        : '${appInfo.version} ($build)';
    final subject = Uri.encodeComponent(S.current.supportEmailSubject);
    final body = Uri.encodeComponent('\n\n${S.current.appVersionLabel(version)}');
    return Uri.parse('mailto:$_email?subject=$subject&body=$body');
  }

  void _open(Uri uri) =>
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final horizontalPadding = device.isMobile ? 16.0 : 30.0;
    final navigationBarHeight = device.isMobile ? 56.0 : 64.0;

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(navigationBarHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              const BackButton(),
              const SizedBox(width: 4),
              Text(
                S.of(context).support,
                style: TextStyle(
                  fontSize: device.isMobile ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 30,
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).supportIntro,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _tile(
                    theme: theme,
                    icon: Icons.mail_outline,
                    title: S.of(context).emailMe,
                    subtitle: _email,
                    onTap: () => _open(_emailUri()),
                  ),
                  _tile(
                    theme: theme,
                    icon: Icons.discord,
                    title: S.of(context).joinDiscord,
                    subtitle: S.of(context).joinDiscordSubtitle,
                    onTap: () => _open(_discordUri),
                  ),
                  _tile(
                    theme: theme,
                    icon: Icons.bug_report_outlined,
                    title: S.of(context).createGithubIssue,
                    subtitle: S.of(context).createGithubIssueSubtitle,
                    onTap: () => _open(_issuesUri),
                  ),
                  _tile(
                    theme: theme,
                    icon: Icons.coffee_outlined,
                    title: S.of(context).donate,
                    subtitle: S.of(context).donateSubtitle,
                    onTap: () => _open(_donateUri),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 26, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
