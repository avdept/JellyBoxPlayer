import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/smart_previous.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(this._ref) : super(PlaybackState.initial()) {
    _audioPlayer = _ref.watch(playerProvider)
      ..currentIndexStream.listen((index) {
        if (_preparingQueue || index == _reportedIndex) return;
        _reportTrackChange(index);
        final nextSong = index != null
            ? state.songs.elementAtOrNull(index)
            : null;
        if (nextSong != null && state.album != null) {
          unawaited(_saveToStorage(songId: nextSong.id, positionMs: 0));
        }
      })
      ..positionStream.listen((position) {
        if (!_preparingQueue &&
            _audioPlayer.currentIndex == _reportedIndex &&
            position > Duration.zero) {
          _reportedPositionMs = position.inMilliseconds;
        }
        state = state.copyWith(
          position: position,
          totalDuration: _durationFor(_audioPlayer.currentIndex),
          currentMediaIndex: _audioPlayer.currentIndex,
        );

        final now = DateTime.now();
        if (state.status.isPlaying &&
            (_lastPositionSave == null ||
                now.difference(_lastPositionSave!).inSeconds >= 5)) {
          _lastPositionSave = now;
          final currentIndex = _audioPlayer.currentIndex;
          final currentSong = currentIndex != null
              ? state.songs.elementAtOrNull(currentIndex)
              : null;
          if (currentSong != null) {
            unawaited(
              _saveToStorage(
                songId: currentSong.id,
                positionMs: position.inMilliseconds,
              ),
            );
          }
        }
      })
      // Handle other player states as needed
      ..playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed &&
            state.status.isPlaying) {
          _reportStopped();
          _stopProgressReports();
          state = PlaybackState.initial();
        } else if (playerState.playing && !state.status.isPlaying) {
          state = state.copyWith(status: PlaybackStatus.playing);
        } else if (!playerState.playing &&
            state.status.isPlaying &&
            playerState.processingState == ProcessingState.ready) {
          state = state.copyWith(
            status: PlaybackStatus.paused,
            position: _audioPlayer.position,
          );
        }
      });
  }

  static const _progressInterval = Duration(seconds: 10);

  final Ref _ref;
  late AudioPlayer _audioPlayer;
  final _playSessionIds = <String, String>{};
  DateTime? _lastPositionSave;
  int? _reportedIndex;
  var _reportedPositionMs = 0;
  var _startReported = false;
  var _preparingQueue = false;
  Timer? _progressTimer;

  LibraryItem? get _reportedSong {
    final index = _reportedIndex;
    return index != null ? state.songs.elementAtOrNull(index) : null;
  }

  Duration? _durationFor(int? index, {List<LibraryItem>? songs}) {
    final song = index != null
        ? (songs ?? state.songs).elementAtOrNull(index)
        : null;
    if (song != null && song.duration > Duration.zero) {
      return song.duration;
    }
    return _audioPlayer.duration;
  }

  PlaybackReport _playbackReport(
    LibraryItem song, {
    required int positionMs,
    bool? isPaused,
  }) => PlaybackReport(
    itemId: song.id,
    playSessionId: _playSessionIds[song.id] ?? '',
    mediaSourceId: song.id,
    position: Duration(milliseconds: positionMs),
    isPaused: isPaused,
    canSeek: true,
    queueItemIds: [for (final queued in state.songs) queued.id],
  );

  void _reportStarted(LibraryItem song, {required int positionMs, bool? isPaused}) {
    _startReported = true;
    _report(
      (client) => client.reportPlaybackStarted(
        _playbackReport(song, positionMs: positionMs, isPaused: isPaused),
      ),
    );
  }

  void _reportStopped() {
    if (!_startReported) return;
    final song = _reportedSong;
    if (song == null) return;
    _startReported = false;
    _report(
      (client) => client.reportPlaybackStopped(
        _playbackReport(song, positionMs: _reportedPositionMs),
      ),
    );
  }

  void _reportProgress() {
    if (!_startReported) return;
    final song = _reportedSong;
    if (song == null) return;
    _report(
      (client) => client.reportPlaybackProgress(
        _playbackReport(
          song,
          positionMs: _audioPlayer.position.inMilliseconds,
          isPaused: !state.status.isPlaying,
        ),
      ),
    );
  }

  void _reportTrackChange(int? index) {
    _reportStopped();
    _reportedIndex = index;
    _reportedPositionMs = 0;
    final song = _reportedSong;
    if (song != null) {
      _reportStarted(song, positionMs: 0, isPaused: false);
      _startProgressReports();
    } else {
      _stopProgressReports();
    }
  }

  void _startProgressReports() {
    _progressTimer ??= Timer.periodic(
      _progressInterval,
      (_) => _reportProgress(),
    );
  }

  void _stopProgressReports() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _report(Future<void> Function(MediaServerClient client) call) {
    if (_ref.read(isOfflineProvider)) return;
    unawaited(_runReport(call));
  }

  Future<void> _runReport(
    Future<void> Function(MediaServerClient client) call,
  ) async {
    try {
      await call(_ref.read(mediaServerClientProvider));
    } on DioException catch (error) {
      debugPrint(
        '[Playback] report ${error.requestOptions.path} failed: '
        '${error.response?.statusCode} ${error.response?.data}',
      );
    } on Object catch (error) {
      debugPrint('[Playback] report failed: $error');
    }
  }

  Future<void> play(
    LibraryItem playSong,
    List<LibraryItem> songs,
    LibraryItem album, {
    Duration? initialPosition,
    bool autoPlay = true,
  }) async {
    try {
      final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final sessionIds = {
        for (final song in songs) song.id: '$deviceId-$stamp-${song.id}',
      };

      final resolved = await Future.wait(
        songs.map((song) => _resolveSource(song, album, sessionIds[song.id]!)),
      );

      final playableSongs = <LibraryItem>[];
      final audioSources = <AudioSource>[];
      for (final entry in resolved) {
        if (entry == null) continue;
        playableSongs.add(entry.song);
        audioSources.add(entry.source);
      }

      if (audioSources.isEmpty) {
        debugPrint('[Playback] nothing in this queue can be played offline');
        state = state.copyWith(status: PlaybackStatus.error);
        return;
      }

      _reportStopped();
      _playSessionIds
        ..clear()
        ..addAll(sessionIds);
      _preparingQueue = true;
      _reportedIndex = null;

      final startIndex = playableSongs.indexWhere((s) => s.id == playSong.id);
      final effectiveIndex = startIndex >= 0 ? startIndex : 0;
      final startPosition = initialPosition ?? Duration.zero;

      await _setAudioSources(
        audioSources,
        initialIndex: effectiveIndex,
        initialPosition: startPosition,
      );

      state = state.copyWith(
        songs: playableSongs,
        album: album,
        status: autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused,
        position: startPosition,
        totalDuration: _durationFor(effectiveIndex, songs: playableSongs),
        currentMediaIndex: effectiveIndex,
      );

      _preparingQueue = false;
      _reportedIndex = effectiveIndex;
      _reportedPositionMs = startPosition.inMilliseconds;
      if (autoPlay) {
        _reportStarted(
          playableSongs[effectiveIndex],
          positionMs: startPosition.inMilliseconds,
          isPaused: false,
        );
        _startProgressReports();
      }

      unawaited(
        _saveToStorage(
          songId: playableSongs[effectiveIndex].id,
          positionMs: startPosition.inMilliseconds,
          songs: playableSongs,
          album: album,
        ),
      );
      if (autoPlay) unawaited(_audioPlayer.play());
    } catch (e, st) {
      _preparingQueue = false;
      print('Error in play(): type=${e.runtimeType}, message=$e\n$st');
      if (e.toString().indexOf('setPitch') > 0) {
        // This is hack to avoid playback state being error on ios*`

        state = state.copyWith(
          status: PlaybackStatus.playing,
          position: Duration.zero,
          totalDuration: _durationFor(_audioPlayer.currentIndex),
        );
      } else {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }
  }

  Future<({LibraryItem song, AudioSource source})?> _resolveSource(
    LibraryItem song,
    LibraryItem album,
    String playSessionId,
  ) async {
    final isDownloaded = await _ref
        .read(downloadManagerProvider.notifier)
        .isSongDownloaded(song.id);
    final downloadedPath = isDownloaded
        ? await _ref
              .read(downloadDatabaseProvider)
              .getDownloadedSongPath(song.id)
        : null;

    if (downloadedPath == null && _ref.read(isOfflineProvider)) return null;

    final Uri audioSourceUri;
    var useHls = false;
    if (downloadedPath != null) {
      audioSourceUri = Uri.file(downloadedPath);
    } else {
      final resolved = await _ref
          .read(mediaServerClientProvider)
          .resolveStreamSource(song, playSessionId: playSessionId);
      audioSourceUri = resolved.uri;
      useHls = resolved.isHls;
    }

    final audioSource = song.audioSources.firstOrNull;

    final extras = <String, dynamic>{
      if (audioSource?.codec != null) 'codec': audioSource!.codec,
      if (audioSource?.bitRate != null) 'bitRate': audioSource!.bitRate,
      if (audioSource?.sampleRate != null)
        'sampleRate': audioSource!.sampleRate,
      if (song.albumArtists.isNotEmpty)
        'artistId': song.albumArtists.first.id
      else if (album.albumArtists.isNotEmpty)
        'artistId': album.albumArtists.first.id,
    };

    final tag = MediaItem(
      id: song.id,
      album: song.albumName,
      artist: song.albumArtist ?? album.albumArtist,
      duration: song.duration,
      title: song.name,
      extras: extras,
      artUri: _artUri(song, album, isDownloaded: downloadedPath != null),
    );

    return (
      song: song,
      source: useHls
          ? HlsAudioSource(audioSourceUri, tag: tag)
          : AudioSource.uri(audioSourceUri, tag: tag),
    );
  }

  Uri? _artUri(LibraryItem song, LibraryItem album, {required bool isDownloaded}) {
    final localCover =
        DownloadPaths.coverFile(song.albumId) ??
        DownloadPaths.coverFile(album.id);
    if (isDownloaded && localCover != null) return localCover.uri;

    final imageService = _ref.read(imageServiceProvider);
    final songImageTag = song.images.primary;
    if (songImageTag != null) {
      return Uri.parse(
        imageService.imagePath(tagId: songImageTag, id: song.id),
      );
    }
    if (song.albumId != null && song.images.albumPrimary != null) {
      return Uri.parse(
        imageService.imagePath(
          tagId: song.images.albumPrimary!,
          id: song.albumId!,
        ),
      );
    }
    final albumImageTag = album.images.primary;
    if (albumImageTag != null) {
      return Uri.parse(
        imageService.imagePath(tagId: albumImageTag, id: album.id),
      );
    }
    return null;
  }

  Future<void> _setAudioSources(
    List<AudioSource> sources, {
    required int initialIndex,
    required Duration initialPosition,
  }) async {
    try {
      await _audioPlayer.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: true,
      );
    } on Object catch (error) {
      debugPrint('[Playback] retrying after failed load: $error');
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: true,
      );
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    state = state.copyWith(position: position);
    _reportedPositionMs = position.inMilliseconds;
    _reportProgress();
    final currentIndex = _audioPlayer.currentIndex;
    final currentSong = currentIndex != null
        ? state.songs.elementAtOrNull(currentIndex)
        : null;
    if (currentSong != null) {
      unawaited(
        _saveToStorage(
          songId: currentSong.id,
          positionMs: position.inMilliseconds,
        ),
      );
    }
  }

  Future<void> playPause() => switch (state.status.isPlaying) {
    true => pause(),
    false => resume(),
  };

  Future<void> pause() async {
    await _audioPlayer.pause();
    state = state.copyWith(
      status: PlaybackStatus.paused,
      position: _audioPlayer.position,
    );
    _stopProgressReports();
    _reportProgress();
  }

  Future<void> resume() async {
    if (state.status.isStopped && state.totalDuration?.inSeconds == 0) {
      final queue = _ref.read(audioQueueProvider.notifier);
      // Case when song has finished but user clicks on play(resume) button. In this case we want to restart playback from first song.
      if (queue.state.songs.isNotEmpty) {
        await play(
          queue.state.songs.first,
          queue.state.songs,
          queue.state.album!,
        );
      }

      return;
    }

    unawaited(_audioPlayer.play());
    state = state.copyWith(
      status: PlaybackStatus.playing,
      position: _audioPlayer.position,
    );

    final song = _reportedSong;
    if (song != null && !_startReported) {
      _reportStarted(
        song,
        positionMs: _audioPlayer.position.inMilliseconds,
        isPaused: false,
      );
    } else {
      _reportProgress();
    }
    _startProgressReports();
  }

  Future<void> next() async {
    await _audioPlayer.seekToNext();
    if (!_audioPlayer.playing) await _audioPlayer.play();
    // await play(_ref.read(audioQueueProvider.notifier).nextSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> prev() => _audioPlayer.smartSeekToPrevious();

  Future<void> stop() async {
    await _audioPlayer.stop();
    _stopProgressReports();
    _reportStopped();
    state = state.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
      totalDuration: Duration.zero,
    );
  }

  void toggleRepeat() {
    state = state.copyWith();
  }

  Future<void> _saveToStorage({
    required String songId,
    required int positionMs,
    List<LibraryItem>? songs,
    LibraryItem? album,
  }) async {
    final effectiveSongs = songs ?? state.songs;
    final effectiveAlbum = album ?? state.album;
    if (effectiveSongs.isEmpty || effectiveAlbum == null) {
      return;
    }
    await PlaybackStorage().save(
      songs: effectiveSongs,
      album: effectiveAlbum,
      songId: songId,
      positionMs: positionMs,
    );
  }

  Future<bool> tryRestore() async {
    final snapshot = await PlaybackStorage().load();
    if (snapshot == null) {
      return false;
    }

    final song = snapshot.songs.firstWhere(
      (s) => s.id == snapshot.songId,
      orElse: () => snapshot.songs.first,
    );

    await play(
      song,
      snapshot.songs,
      snapshot.album,
      initialPosition: Duration(milliseconds: snapshot.positionMs),
      autoPlay: false,
    );
    return true;
  }

  @override
  void dispose() {
    _stopProgressReports();
    _reportStopped();
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playbackProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>(
  PlaybackNotifier.new,
);

final currentSongProvider = Provider<LibraryItem?>(
  (ref) => ref.watch(
    playbackProvider.select((state) {
      final index = state.currentMediaIndex;
      return index != null ? state.songs.elementAtOrNull(index) : null;
    }),
  ),
);
