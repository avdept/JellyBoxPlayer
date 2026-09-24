import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/cloud_devices_sheet.dart';

class PlayingElsewhereStrip extends ConsumerWidget {
  const PlayingElsewhereStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderer = ref.watch(
      cloudProvider.select((state) => state.remoteRenderer),
    );
    final shown = renderer != null && ref.watch(playingElsewhereProvider);
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: !shown
          ? const SizedBox(width: double.infinity)
          : Material(
              color: theme.colorScheme.primary,
              child: InkWell(
                onTap: () => unawaited(CloudDevicesSheet.show(context)),
                child: SizedBox(
                  height: 26,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.speaker_group_outlined,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Playing on ${renderer.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
