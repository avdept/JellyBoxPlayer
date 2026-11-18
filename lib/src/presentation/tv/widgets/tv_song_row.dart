import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
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
    this.focusNode,
    this.cover,
    super.key,
  });

  final LibraryItem song;
  final int? position;
  final bool isPlaying;
  final bool showArtist;
  final VoidCallback? onSelect;
  final VoidCallback? onLongSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final ImageProvider? cover;

  static const _coverSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return TvFocusable(
      onSelect: onSelect,
      onLongSelect: onLongSelect,
      autofocus: autofocus,
      focusNode: focusNode,
      debugLabel: 'song:${song.name}',
      builder: (context, focused) {
        final muted = focused ? Colors.white70 : Colors.white60;
        final highlight = focused ? Colors.white : accent;
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: focused
                ? TvTokens.listFocus(context)
                : (isPlaying ? Colors.white10 : Colors.transparent),
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            children: [
              if (position != null) ...[
                SizedBox(
                  width: 28,
                  child: isPlaying
                      ? Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: highlight,
                        )
                      : Text(
                          position.toString(),
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                ),
                const SizedBox(width: 12),
              ],
              if (cover case final cover?) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Image(
                        image: cover,
                        width: _coverSize,
                        height: _coverSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              Images.album,
                              width: _coverSize,
                              height: _coverSize,
                              fit: BoxFit.cover,
                            ),
                      ),
                      if (isPlaying && position == null)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black54,
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ] else if (position == null && isPlaying) ...[
                Icon(Icons.graphic_eq_rounded, size: 18, color: highlight),
                const SizedBox(width: 12),
              ],
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
                        color: isPlaying && !focused ? accent : Colors.white,
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
                Icon(CupertinoIcons.heart_fill, size: 14, color: highlight),
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
