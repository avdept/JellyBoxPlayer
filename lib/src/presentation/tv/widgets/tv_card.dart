import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';

class TvCard extends StatelessWidget {
  const TvCard({
    required this.title,
    this.image,
    this.cover,
    this.subtitle,
    this.onSelect,
    this.onLongSelect,
    this.autofocus = false,
    this.width = TvTokens.cardWidth,
    this.playsOnSelect = false,
    this.circular = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final ImageProvider? image;

  final Widget? cover;
  final VoidCallback? onSelect;
  final VoidCallback? onLongSelect;
  final bool autofocus;
  final double width;

  final bool playsOnSelect;
  final bool circular;

  static const _circle = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TvFocusable(
        onSelect: onSelect,
        onLongSelect: onLongSelect,
        autofocus: autofocus,
        debugLabel: 'card:$title',
        builder: (context, focused) => Column(
          crossAxisAlignment: circular
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            TvFocusFrame(
              focused: focused,
              borderRadius: circular ? _circle : TvTokens.cardRadius,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    cover ??
                        (image != null
                            ? Image(image: image!, fit: BoxFit.cover)
                            : ColoredBox(
                                color: TvTokens.surfaceRaised(context),
                              )),
                    if (playsOnSelect)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: _PlayBadge(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circular ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: focused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: circular ? TextAlign.center : TextAlign.start,
                style: TvTokens.caption,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}
