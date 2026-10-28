import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';

class AlbumDetailsRow extends StatelessWidget {
  const AlbumDetailsRow({
    required this.duration,
    required this.songCount,
    this.year,
    super.key,
  });

  final Duration duration;
  final int songCount;
  final int? year;

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.circle,
        size: 4,
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
      ),
    );
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.clock, size: 14),
          ),
          Text(
            [
              if (hours > 0) hours.toString().padLeft(2, '0'),
              minutes.toString().padLeft(2, '0'),
              seconds.toString().padLeft(2, '0'),
            ].join(':'),
          ),
          dot,
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music, size: 14),
          ),
          Text('$songCount'),
          if (year case final year?) ...[
            dot,
            Text(
              '$year',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }
}
