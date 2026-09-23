import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/cloud_devices_sheet.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class RemoteNowPlayingBar extends ConsumerStatefulWidget {
  const RemoteNowPlayingBar({super.key});

  @override
  ConsumerState<RemoteNowPlayingBar> createState() =>
      _RemoteNowPlayingBarState();
}

class _RemoteNowPlayingBarState extends ConsumerState<RemoteNowPlayingBar> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker({required bool playing}) {
    if (playing == (_ticker != null)) return;
    _ticker?.cancel();
    _ticker = playing
        ? Timer.periodic(
            const Duration(milliseconds: 500),
            (_) => setState(() {}),
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final conductor = ref.watch(cloudProvider);
    final renderer = conductor.remoteRenderer;
    final remote = conductor.remote;

    if (renderer == null || remote == null || remote.doc.isEmpty) {
      _syncTicker(playing: false);
      return const SizedBox.shrink();
    }
    _syncTicker(playing: remote.doc.playing);

    final theme = Theme.of(context);
    final song = ref.watch(remoteNowPlayingProvider).valueOrNull;
    final isMobile =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.mobile;

    final position = remote.positionAt(DateTime.now());
    final duration = song?.duration;
    final progress = duration == null || duration.inMilliseconds <= 0
        ? null
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    final image = song == null
        ? null
        : ref.read(imageServiceProvider).itemImageOrNull(song, size: 128);

    return Material(
      color: theme.bottomSheetTheme.backgroundColor?.withValues(alpha: 0.75),
      child: InkWell(
        onTap: () => unawaited(CloudDevicesSheet.show(context)),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: isMobile ? 69 : 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox.square(
                          dimension: isMobile ? 44 : 60,
                          child: image == null
                              ? Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : Image(image: image, fit: BoxFit.cover),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song?.name ?? 'Playing on another device',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              [
                                ?song?.albumArtist,
                                'on ${renderer.name}',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          remote.doc.playing
                              ? Icons.volume_up
                              : Icons.pause_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: progress ?? 0,
                  minHeight: 2,
                  backgroundColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
