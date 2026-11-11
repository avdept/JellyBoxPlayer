import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/updates/release_checker.dart';
import 'package:jplayer/src/domain/providers/update_banner_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({required this.update, super.key});

  final AvailableUpdate update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;
    final style = TextStyle(fontSize: 13, color: foreground);

    return Material(
      color: const Color(0xFF383A3F),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.system_update_outlined,
                      size: 16,
                      color: foreground,
                    ),
                  ),
                ),
                TextSpan(text: 'JellyBox ${update.version} is available  '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _BannerLink(
                    label: 'Download',
                    style: style,
                    onTap: () => unawaited(
                      launchUrl(
                        update.url,
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '    '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _BannerLink(
                    label: 'Close',
                    style: style,
                    onTap: () => ref
                        .read(dismissedUpdateProvider.notifier)
                        .dismiss(update.version),
                  ),
                ),
              ],
            ),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _BannerLink extends StatelessWidget {
  const _BannerLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        label,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: style.color,
        ),
      ),
    ),
  );
}
