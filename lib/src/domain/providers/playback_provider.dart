import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(this._ref) : super(PlaybackState.initial()) {
    _target = _ref.read(playbackTargetProvider);
    _listenToTarget();
    _ref.listen<PlaybackTarget>(playbackTargetProvider, (previous, next) {
      if (previous == null || previous.id == next.id) return;
      unawaited(_handoff(from: previous, to: next));
    });
  }

  static const _progressInterval = Duration(seconds: 10);

  final Ref _ref;
  final _playSessionIds = <String, String>{};
  late PlaybackTarget _target;
  StreamSubscription<TargetPlaybackState>? _targetSubscription;
  TargetPlaybackState _targetState = TargetPlaybackState.idle;
  DateTime? _lastPositionSave;
  int? _reportedIndex;
  var _reportedPositionMs = 0;
  var _startReported = false;
  var _preparingQueue = false;
  Timer? _progressTimer;

  PlaybackTarget get target => _target;

  LibraryItem? get _reportedSong {
    final index = _reportedIndex;
    return index != null ? state.songs.elementAtOrNull(index) : null;
  }

  void _listenToTarget() {
    _targetSubscription = _target.stateStream.listen(_onTargetState);
  }

  void _onTargetState(TargetPlaybackState targetState) {
    _targetState = targetState;
    final index = targetState.currentIndex;

    if (!_preparingQueue && index != _reportedIndex) {
      _reportTrackChange(index);
      final nextSong = index != null
          ? state.songs.elementAtOrNull(index)
          : null;
      if (nextSong != null && state.album != null) {
        unawaited(_saveToStorage(songId: nextSong.id, positionMs: 0));
      }
    }

    if (!_preparingQueue &&
        index == _reportedIndex &&
        targetState.position > Duration.zero) {
      _reportedPositionMs = targetState.position.inMilliseconds;
    }

    state = state.copyWith(
      position: targetState.position,
      totalDuration: _durationFor(index),
      currentMediaIndex: index,
    );

    final now = DateTime.now();
    if (state.status.isPlaying &&
        (_lastPositionSave == null ||
            now.difference(_lastPositionSave!).inSeconds >= 5)) {
      _lastPositionSave = now;
      final currentSong = index != null
          ? state.songs.elementAtOrNull(index)
          : null;
      if (currentSong != null) {
        unawaited(
          _saveToStorage(
            songId: currentSong.id,
            positionMs: targetState.position.inMilliseconds,
          ),
        );
      }
    }

    if (targetState.completed && state.status.isPlaying) {
      _reportStopped();
      _stopProgressReports();
      state = PlaybackState.initial();
    } else if (targetState.status.isPlaying && !state.status.isPlaying) {
      state = state.copyWith(status: PlaybackStatus.playing);
    } else if (targetState.status.isPaused && state.status.isPlaying) {
      state = state.copyWith(
        status: PlaybackStatus.paused,
        position: targetState.position,
      );
    }
  }

  Future<void> _handoff({
    required PlaybackTarget from,
    required PlaybackTarget to,
  }) async {
    final songs = state.songs;
    final album = state.album;
    final wasPlaying = state.status.isPlaying;
    final index = state.currentMediaIndex ?? 0;
    final position = state.position;

    await _targetSubscription?.cancel();
    _targetSubscription = null;

    _reportStopped();
    _stopProgressReports();
    try {
      await from.stop();
    } on Object catch (error) {
      debugPrint('[Playback] stopping ${from.name} failed: $error');
    }
    if (from.kind != PlaybackTargetKind.local) await from.dispose();

    _target = to;
    _targetState = TargetPlaybackState.idle;
    _listenToTarget();

    if (songs.isEmpty || album == null) return;

    final startSong = songs.elementAtOrNull(index) ?? songs.first;
    await play(
      startSong,
      songs,
      album,
      initialPosition: position,
      autoPlay: wasPlaying,
    );
  }

  Duration? _durationFor(int? index, {List<LibraryItem>? songs}) {
    final song = index != null
        ? (songs ?? state.songs).elementAtOrNull(index)
        : null;
    if (song != null && song.duration > Duration.zero) {
      return song.duration;
    }
    return _targetState.duration;
  }

  PlaybackReport _playbackReport(
    LibraryItem song, {
    required int positionMs,
    bool? isPaused,
  }) => PlaybackReport(
    itemId: song.id,
    playSessionId: _playSessionIds[song.id] ?? '',
    mediaSourceId: song.audioSources.firstOrNull?.id ?? song.id,
    position: Duration(milliseconds: positionMs),
    isPaused: isPaused,
    canSeek: _targetState.canSeek,
    queueItemIds: [for (final queued in state.songs) queued.id],
  );

  void _reportStarted(
    LibraryItem song, {
    required int positionMs,
    bool? isPaused,
  }) {
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
          positionMs: _targetState.position.inMilliseconds,
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
        songs.map((song) => _resolveTrack(song, album, sessionIds[song.id]!)),
      );

      final playableSongs = <LibraryItem>[];
      final tracks = <TargetTrack>[];
      for (final entry in resolved) {
        if (entry == null) continue;
        playableSongs.add(entry.song);
        tracks.add(entry.track);
      }

      if (tracks.isEmpty) {
        debugPrint(
          '[Playback] nothing in this queue can be played on '
          '${_target.name}',
        );
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

      await _target.load(
        tracks,
        initialIndex: effectiveIndex,
        initialPosition: startPosition,
        autoPlay: autoPlay,
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
    } catch (e, st) {
      _preparingQueue = false;
      debugPrint('Error in play(): type=${e.runtimeType}, message=$e\n$st');
      if (e.toString().indexOf('setPitch') > 0) {
        // This is hack to avoid playback state being error on ios*`

        state = state.copyWith(
          status: PlaybackStatus.playing,
          position: Duration.zero,
          totalDuration: _durationFor(_targetState.currentIndex),
        );
      } else {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }
  }

  Future<({LibraryItem song, TargetTrack track})?> _resolveTrack(
    LibraryItem song,
    LibraryItem album,
    String playSessionId,
  ) async {
    final isDownloaded = await _ref
        .read(downloadManagerProvider.notifier)
        .isSongDownloaded(song.id);
    final downloadedPath = isDownloaded && _target.supportsLocalFiles
        ? await _ref
              .read(downloadDatabaseProvider)
              .getDownloadedSongPath(song.id)
        : null;

    if (downloadedPath == null && _ref.read(isOfflineProvider)) return null;

    final Uri uri;
    var isHls = false;
    var mimeType = 'application/octet-stream';
    if (downloadedPath != null) {
      uri = Uri.file(downloadedPath);
    } else {
      final resolved = await _ref
          .read(mediaServerClientProvider)
          .resolveStreamSource(
            song,
            playSessionId: playSessionId,
            target: _target.streamProfile,
          );
      uri = resolved.uri;
      isHls = resolved.isHls;
      mimeType = resolved.mimeType;
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

    return (
      song: song,
      track: TargetTrack(
        itemId: song.id,
        uri: uri,
        mimeType: mimeType,
        isHls: isHls,
        title: song.name,
        duration: song.duration,
        artist: song.albumArtist ?? album.albumArtist,
        album: song.albumName,
        artUri: _artUri(song, album),
        extras: extras,
      ),
    );
  }

  Uri? _artUri(LibraryItem song, LibraryItem album) {
    final imageService = _ref.read(imageServiceProvider);
    return imageService.itemUri(song) ?? imageService.itemUri(album);
  }

  Future<void> seek(Duration position) async {
    await _target.seek(position);
    state = state.copyWith(position: position);
    _reportedPositionMs = position.inMilliseconds;
    _reportProgress();
    final currentIndex = _targetState.currentIndex;
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
    await _target.pause();
    state = state.copyWith(
      status: PlaybackStatus.paused,
      position: _targetState.position,
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

    unawaited(_target.play());
    state = state.copyWith(
      status: PlaybackStatus.playing,
      position: _targetState.position,
    );

    final song = _reportedSong;
    if (song != null && !_startReported) {
      _reportStarted(
        song,
        positionMs: _targetState.position.inMilliseconds,
        isPaused: false,
      );
    } else {
      _reportProgress();
    }
    _startProgressReports();
  }

  Future<void> next() async {
    await _target.seekToNext();
    if (!_targetState.status.isPlaying) await _target.play();
  }

  Future<void> prev() => _target.seekToPrevious();

  Future<void> skipTo(int index, {bool autoPlay = false}) async {
    await _target.skipTo(index);
    if (autoPlay && !_targetState.status.isPlaying) await _target.play();
  }

  Future<void> stop() async {
    await _target.stop();
    _stopProgressReports();
    _reportStopped();
    state = state.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
      totalDuration: Duration.zero,
    );
  }

  Future<void> clear() async {
    await stop();
    state = PlaybackState.initial();
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
    unawaited(_targetSubscription?.cancel());
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
