import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_button.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvMiniPlayer extends ConsumerWidget {
  const TvMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(barMediaItemProvider);
    if (item == null) return const SizedBox.shrink();

    final playing = ref.watch(barPlayingProvider);
    final progress = ref.watch(barProgressProvider);
    final controls = ref.read(barControlsProvider);
    final art = ref
        .read(imageServiceProvider)
        .artworkImage(item.artUri, size: 128);
    final fraction = progress.duration.inMilliseconds == 0
        ? 0.0
        : (progress.position.inMilliseconds / progress.duration.inMilliseconds)
              .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TvTokens.pagePaddingH,
        0,
        TvTokens.pagePaddingH,
        16,
      ),
      child: ClipRRect(
        borderRadius: TvTokens.panelRadius,
        child: ColoredBox(
          color: TvTokens.surface,
          child: SizedBox(
            height: TvTokens.miniPlayerHeight,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TvFocusable(
                          onSelect: () =>
                              context.pushNamed(Routes.nowPlaying.name),
                          scrollOnFocus: false,
                          debugLabel: 'mini-player',
                          builder: (context, focused) => AnimatedContainer(
                            duration: TvTokens.focusDuration,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: focused
                                  ? Colors.white12
                                  : Colors.transparent,
                              borderRadius: TvTokens.panelRadius,
                              border: Border.all(
                                color: focused
                                    ? TvTokens.focusRing
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: art,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.artist ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TvTokens.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_full_rounded,
                                  size: 18,
                                  color: focused
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            TvIconButton(
                              icon: Icons.skip_previous_rounded,
                              size: 40,
                              iconSize: 22,
                              onSelect: () => unawaited(controls.previous()),
                            ),
                            const SizedBox(width: 6),
                            TvIconButton(
                              icon: playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 44,
                              primary: true,
                              onSelect: () => unawaited(controls.togglePlay()),
                            ),
                            const SizedBox(width: 6),
                            TvIconButton(
                              icon: Icons.skip_next_rounded,
                              size: 40,
                              iconSize: 22,
                              onSelect: () => unawaited(controls.next()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: fraction,
                  minHeight: 3,
                  backgroundColor: Colors.white10,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
