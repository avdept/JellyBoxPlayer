import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class TvSongRow extends StatelessWidget {
  const TvSongRow({
    required this.song,
    this.position,
    this.isPlaying = false,
    this.showArtist = true,
    this.onSelect,
    this.onLongSelect,
    this.autofocus = false,
    super.key,
  });

  final LibraryItem song;
  final int? position;
  final bool isPlaying;
  final bool showArtist;
  final VoidCallback? onSelect;
  final VoidCallback? onLongSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return TvFocusable(
      onSelect: onSelect,
      onLongSelect: onLongSelect,
      autofocus: autofocus,
      debugLabel: 'song:${song.name}',
      builder: (context, focused) {
        final foreground = focused ? Colors.black : Colors.white;
        final muted = focused ? Colors.black54 : Colors.white60;
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: focused
                ? Colors.white
                : (isPlaying ? Colors.white10 : Colors.transparent),
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: isPlaying
                    ? Icon(Icons.graphic_eq_rounded, size: 18, color: accent)
                    : Text(
                        position?.toString() ?? '',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPlaying && !focused ? accent : foreground,
                      ),
                    ),
                    if (showArtist && song.artistLabel.isNotEmpty)
                      Text(
                        song.artistLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
              ),
              if (song.userData.isFavorite) ...[
                const SizedBox(width: 12),
                Icon(CupertinoIcons.heart_fill, size: 14, color: accent),
              ],
              const SizedBox(width: 16),
              Text(
                formatPlaybackTime(song.duration),
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
        );
      },
    );
  }
}
