import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/cover_mosaic.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum TvPlaylistSource { playlist, likedSongs, generated }

class TvPlaylistPage extends ConsumerStatefulWidget {
  const TvPlaylistPage({
    required this.playlist,
    required this.source,
    super.key,
  });

  final LibraryItem playlist;
  final TvPlaylistSource source;

  @override
  ConsumerState<TvPlaylistPage> createState() => _TvPlaylistPageState();
}

class _TvPlaylistPageState extends ConsumerState<TvPlaylistPage> {
  List<LibraryItem> _songs = const [];
  bool _loading = true;
  bool _failed = false;
  MediaItem? _current;

  LibraryItem get playlist => widget.playlist;

  @override
  void initState() {
    super.initState();
    _current = ref.read(nowPlayingProvider);
    ref.listenManual<MediaItem?>(nowPlayingProvider, (_, song) {
      if (mounted) setState(() => _current = song);
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final songs = await switch (widget.source) {
        TvPlaylistSource.playlist => _loadPlaylistSongs(),
        TvPlaylistSource.likedSongs =>
          ref.read(favouriteSongsProvider.future).then((page) => page.items),
        TvPlaylistSource.generated => ref.read(
          todaysPlaylistSongsProvider(playlist.id).future,
        ),
      };
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } on Object catch (error) {
      debugPrint('[TvPlaylistPage] could not load songs: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<List<LibraryItem>> _loadPlaylistSongs() async {
    final page = await ref
        .read(mediaServerClientProvider)
        .getPlaylistSongs(playlist.id);
    return [...page.items]
      ..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));
  }

  Future<void> _playAll() async {
    final notifier = ref.read(setPlaybackProvider.notifier);
    final result = await switch (widget.source) {
      TvPlaylistSource.playlist => notifier.playPlaylist(playlist),
      TvPlaylistSource.likedSongs => notifier.playFavouriteSongs(playlist),
      TvPlaylistSource.generated => notifier.playGeneratedPlaylist(playlist),
    };
    if (result == SetPlaybackResult.empty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing to play in "${playlist.name}"')),
      );
    }
  }

  Future<void> _shuffleAll() async {
    if (_songs.isEmpty) return;
    final playback = ref.read(playbackProvider.notifier);
    await playback.setShuffle(enabled: true);
    await playback.play(_songs.first, _songs, playlist, sourceId: playlist.id);
  }

  void _playSong(LibraryItem song) => unawaited(
    ref
        .read(playbackProvider.notifier)
        .play(song, _songs, playlist, sourceId: playlist.id),
  );

  Future<void> _toggleLike(LibraryItem song) async {
    final updated = await toggleFavourite(ref, song);
    if (!mounted) return;
    setState(() {
      _songs = [
        for (final s in _songs)
          if (s.id == updated.id) updated else s,
      ];
    });
  }

  void _songOptions(LibraryItem song) => unawaited(
    showTvItemOptions(
      context,
      ref,
      song,
      scope: ContextMenuScope.playlistPage,
      onLike: _toggleLike,
    ),
  );

  Duration get _totalDuration =>
      _songs.fold(Duration.zero, (sum, song) => sum + song.duration);

  @override
  Widget build(BuildContext context) {
    final images = ref.read(imageServiceProvider);
    final hasCover = playlist.images.hasCover;
    final coverSongs = _songs.take(4).toList();
    final backdrop = hasCover
        ? images.itemImage(playlist, size: 800)
        : (coverSongs.isEmpty
              ? images.itemImage(playlist)
              : images.itemImage(coverSongs.first, size: 800));
    final busy = ref.watch(setPlaybackProvider) == playlist.id;

    return TvCollectionScaffold(
      backdrop: backdrop,
      cover: hasCover || coverSongs.isEmpty
          ? Image(
              image: images.itemImage(playlist, size: 600),
              fit: BoxFit.cover,
            )
          : CoverMosaic(
              images: [for (final song in coverSongs) images.itemImage(song)],
              borderRadius: 0,
            ),
      title: playlist.name,
      subtitle: switch (widget.source) {
        TvPlaylistSource.playlist => 'Playlist',
        TvPlaylistSource.likedSongs => 'Your liked songs',
        TvPlaylistSource.generated => 'Made for you',
      },
      details: _details(),
      actions: [
        TvButton(
          label: 'Play',
          icon: Icons.play_arrow_rounded,
          primary: true,
          autofocus: true,
          busy: busy,
          onSelect: () => unawaited(_playAll()),
        ),
        TvButton(
          label: 'Shuffle',
          icon: Icons.shuffle_rounded,
          onSelect: _songs.isEmpty ? null : () => unawaited(_shuffleAll()),
        ),
      ],
      body: _tracks(),
    );
  }

  Widget _details() {
    if (_songs.isEmpty) return const SizedBox.shrink();
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
          Text(formatPlaybackTime(_totalDuration)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.circle, size: 4, color: Colors.white60),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music, size: 14),
          ),
          Text('${_songs.length}'),
        ],
      ),
    );
  }

  Widget _tracks() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(right: TvTokens.pagePaddingH),
        child: Column(
          children: [
            for (var i = 0; i < 8; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ShimmerBox(height: 34, radius: 8),
              ),
          ],
        ),
      );
    }
    if (_failed) {
      return Center(
        child: OfflineNotice(
          message: ref.watch(isOfflineProvider)
              ? "You're offline, so this playlist can't be loaded."
              : 'Could not load this playlist.',
          onRetry: () => unawaited(_load()),
        ),
      );
    }
    if (_songs.isEmpty) {
      return const Center(
        child: Text("There's no songs yet.", style: TvTokens.body),
      );
    }
    return FocusTraversalGroup(
      child: ListView.builder(
        padding: const EdgeInsets.only(
          right: TvTokens.pagePaddingH,
          bottom: TvTokens.pagePaddingV,
        ),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return TvSongRow(
            song: song,
            position: index + 1,
            isPlaying: _current != null && _current!.id == song.id,
            onSelect: () => _playSong(song),
            onLongSelect: () => _songOptions(song),
          );
        },
      ),
    );
  }
}
