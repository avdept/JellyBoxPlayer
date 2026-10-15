import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/updates/release_checker.dart';
import 'package:jplayer/src/domain/providers/update_banner_provider.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
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
        child: InkWell(
          onTap: () => unawaited(
            launchUrl(update.url, mode: LaunchMode.externalApplication),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
            child: Row(
              children: [
                Expanded(
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
                        TextSpan(
                          text: 'JellyBox ${update.version} is available  ',
                        ),
                        TextSpan(
                          text: 'Download',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: foreground,
                          ),
                        ),
                      ],
                    ),
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                HoverIconButton(
                  tooltip: 'Dismiss',
                  iconSize: 16,
                  color: foreground,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => ref
                      .read(dismissedUpdateProvider.notifier)
                      .dismiss(update.version),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
