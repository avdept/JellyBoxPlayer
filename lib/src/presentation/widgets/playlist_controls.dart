import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/playlist_song_order_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/presentation/widgets/play_button.dart';
import 'package:jplayer/src/presentation/widgets/sort_menu_button.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

Map<PlaylistSongSort, String> playlistSortOptions(
  String defaultLabel, {
  bool ratings = false,
}) => {
  PlaylistSongSort.playlistOrder: defaultLabel,
  PlaylistSongSort.title: 'Title',
  PlaylistSongSort.artist: 'Artist',
  PlaylistSongSort.album: 'Album',
  if (ratings) PlaylistSongSort.rating: 'Rating',
};

class PlaylistControls extends StatelessWidget {
  const PlaylistControls({
    required this.onPlay,
    required this.onShuffle,
    this.isPlayLoading = false,
    this.resume,
    this.download,
    this.sort,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final bool isPlayLoading;
  final Widget? resume;
  final Widget? download;
  final Widget? sort;

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return IconTheme.merge(
      data: IconThemeData(size: device.isTablet ? 28 : 24),
      child: Row(
        children: [
          HoverZoom(
            builder: (context, hovered) => SizedBox.square(
              dimension: device.isMobile ? 40 : 40,
              child: Consumer(
                builder: (context, ref, _) => PlayButton(
                  isLoading: isPlayLoading,
                  onPressed: onPlay,
                  color: hovered ? ref.watch(accentColorProvider) : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          HoverIconButton(
            iconSize: 20,
            icon: const Icon(JPlayer.mix),
            color: Theme.of(context).colorScheme.onPrimary,
            tooltip: 'Shuffle play',
            onPressed: isPlayLoading ? null : onShuffle,
          ),
          ?resume,
          ?download,
          const Spacer(),
          ?sort,
        ],
      ),
    );
  }
}

class PlaylistSortButton extends ConsumerWidget {
  const PlaylistSortButton({
    required this.order,
    required this.onChanged,
    this.defaultLabel = 'Playlist order',
    super.key,
  });

  final PlaylistSongOrder order;
  final ValueChanged<PlaylistSongOrder> onChanged;
  final String defaultLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SortMenuButton<PlaylistSongSort>(
        options: playlistSortOptions(
          defaultLabel,
          ratings: ref.watch(ratingsEnabledProvider),
        ),
        selected: order.sort,
        descending: order.descending,
        onSelected: (sort) => onChanged(order.select(sort)),
      );
}
