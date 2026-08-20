import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/scrollable_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class GeneratedPlaylistPage extends ConsumerStatefulWidget {
  const GeneratedPlaylistPage({required this.playlist, super.key});

  final LibraryItem playlist;

  @override
  ConsumerState<GeneratedPlaylistPage> createState() =>
      _GeneratedPlaylistPageState();
}

class _GeneratedPlaylistPageState extends ConsumerState<GeneratedPlaylistPage> {
  late ThemeData _theme;
  late DeviceType _device;

  double get _horizontalPadding => _device.isMobile ? 16 : 30;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final songs = ref.watch(todaysPlaylistSongsProvider(widget.playlist.id));

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              CupertinoNavigationBarBackButton(
                color: _theme.colorScheme.onPrimary,
                onPressed: () => context.pop(),
              ),
              SizedBox(width: _device.isMobile ? 12 : 20),
              Expanded(
                child: Text(
                  widget.playlist.name,
                  style: TextStyle(
                    fontSize: _device.isMobile ? 20 : 26,
                    fontWeight: FontWeight.w600,
                    color: _theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: const EdgeInsets.only(bottom: 30),
      slivers: [
        if (isOffline)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: OfflineNotice(
                message: "You're offline, so playlists need a connection.",
                onRetry: () => ref.invalidate(
                  todaysPlaylistSongsProvider(widget.playlist.id),
                ),
                showDownloadsLink: true,
              ),
            ),
          )
        else
          ...songs.when(
            data: (items) => [
              SongListSliver(
                songs: items,
                edgePadding: _horizontalPadding,
                onItemUpdated: ref
                    .read(
                      todaysPlaylistSongsProvider(widget.playlist.id).notifier,
                    )
                    .updateItem,
              ),
            ],
            error: (error, stackTrace) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(error.toString())),
                ),
              ),
            ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
