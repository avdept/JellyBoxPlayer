// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/core/audio/smart_previous.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(this._ref) : super(PlaybackState.initial()) {
    _audioPlayer = _ref.watch(playerProvider)
      ..currentIndexStream.listen((index) {
        final currentIndex = state.currentMediaIndex;
        final nextIndex = index;
        if (nextIndex != currentIndex) {
          if (currentIndex != null) {
            final currentSong = state.songs.elementAtOrNull(currentIndex);
            if (currentSong != null) {
              _report(
                (api) => api.playbackStopped(
                  values: PlaystateData(
                    playSessionId: _playSessionId,
                    itemId: currentSong.id,
                    item: currentSong,
                    mediaSourceId: state.album?.id,
                  ),
                ),
              );
            }
          }
          if (nextIndex != null) {
            final nextSong = state.songs.elementAtOrNull(nextIndex);
            if (nextSong != null) {
              _report(
                (api) => api.playbackStarted(
                  values: PlaystateData(
                    playSessionId: _playSessionId,
                    itemId: nextSong.id,
                    item: nextSong,
                    mediaSourceId: state.album?.id,
                  ),
                ),
              );
              final album = state.album;
              if (album != null) {
                unawaited(_saveToStorage(songId: nextSong.id, positionMs: 0));
              }
            }
          }
        }
      })
      ..positionStream.listen((position) {
        state = state.copyWith(
          position: position,
          totalDuration: _audioPlayer.duration,
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
        if (playerState.processingState == ProcessingState.completed) {
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

  final Ref _ref;
  late AudioPlayer _audioPlayer;
  var _playSessionId = '';
  DateTime? _lastPositionSave;

  void _report(Future<void> Function(JellyfinApi api) call) {
    if (_ref.read(isOfflineProvider)) return;
    try {
      call(_ref.read(jellyfinApiProvider)).ignore();
    } on Object catch (error) {
      print('Playback report failed: $error');
    }
  }

  Future<void> play(
    ItemDTO playSong,
    List<ItemDTO> songs,
    ItemDTO album, {
    Duration? initialPosition,
    bool autoPlay = true,
  }) async {
    try {
      final resolved = await Future.wait(
        songs.map((song) => _resolveSource(song, album)),
      );

      final playableSongs = <ItemDTO>[];
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

      _playSessionId = DateTime.now().toIso8601String(); // Any unique ID
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
        totalDuration: _audioPlayer.duration,
        currentMediaIndex: effectiveIndex,
      );

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
      print('Error in play(): type=${e.runtimeType}, message=$e\n$st');
      if (e.toString().indexOf('setPitch') > 0) {
        // This is hack to avoid playback state being error on ios*`

        state = state.copyWith(
          status: PlaybackStatus.playing,
          position: Duration.zero,
          totalDuration: _audioPlayer.duration,
        );
      } else {
        state = state.copyWith(status: PlaybackStatus.error);
      }
    }
  }

  Future<({ItemDTO song, AudioSource source})?> _resolveSource(
    ItemDTO song,
    ItemDTO album,
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

    final mediaSource = song.mediaSources.firstOrNull;
    final audioStream = mediaSource?.mediaStreams
        .where((s) => s.type == 'Audio')
        .firstOrNull;

    // Resolve platform-correct direct-play/transcode params so codecs the
    // player can't decode (notably ALAC on Android's ExoPlayer) transcode
    // to a lossless FLAC stream instead of silently failing. See
    // [AudioStreamProfile].
    final streamProfile = AudioStreamProfile.forSource(
      sourceContainer: mediaSource?.container,
      sourceCodec: audioStream?.codec,
    );

    final audioSourceUri = (downloadedPath != null)
        ? Uri.file(downloadedPath)
        : Uri.parse(_ref.read(baseUrlProvider)!).replace(
            path: 'Audio/${song.id}/universal',
            queryParameters: {
              'UserId': _ref.read(currentUserProvider)!.userId,
              'api_key': _ref.read(currentUserProvider)!.token,
              'DeviceId': deviceId,
              'TranscodingProtocol': 'http',
              'TranscodingContainer': streamProfile.transcodingContainer,
              'AudioCodec': streamProfile.transcodingAudioCodec,
              'Container': streamProfile.directPlayContainers,
            },
          );

    final extras = <String, dynamic>{
      if (audioStream?.codec != null) 'codec': audioStream!.codec,
      if (audioStream?.bitRate != null) 'bitRate': audioStream!.bitRate,
      if (audioStream?.sampleRate != null)
        'sampleRate': audioStream!.sampleRate,
      if (song.albumArtists.isNotEmpty)
        'artistId': song.albumArtists.first.id
      else if (album.albumArtists.isNotEmpty)
        'artistId': album.albumArtists.first.id,
    };

    return (
      song: song,
      source: AudioSource.uri(
        audioSourceUri,
        tag: MediaItem(
          id: song.id,
          album: song.albumName,
          artist: song.albumArtist ?? album.albumArtist,
          duration: Duration(milliseconds: (song.runTimeTicks / 10000).ceil()),
          title: song.name,
          extras: extras,
          artUri: _artUri(song, album, isDownloaded: downloadedPath != null),
        ),
      ),
    );
  }

  Uri? _artUri(ItemDTO song, ItemDTO album, {required bool isDownloaded}) {
    final localCover =
        DownloadPaths.coverFile(song.albumId) ??
        DownloadPaths.coverFile(album.id);
    if (isDownloaded && localCover != null) return localCover.uri;

    final imageService = _ref.read(imageServiceProvider);
    final songImageTag = song.imageTags['Primary'];
    if (songImageTag != null) {
      return Uri.parse(
        imageService.imagePath(tagId: songImageTag, id: song.id),
      );
    }
    if (song.albumId != null && song.albumPrimaryImageTag != null) {
      return Uri.parse(
        imageService.imagePath(
          tagId: song.albumPrimaryImageTag!,
          id: song.albumId!,
        ),
      );
    }
    final albumImageTag = album.imageTags['Primary'];
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
  }

  Future<void> next() async {
    await _audioPlayer.seekToNext();
    if (!_audioPlayer.playing) await _audioPlayer.play();
    // await play(_ref.read(audioQueueProvider.notifier).nextSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> prev() => _audioPlayer.smartSeekToPrevious();

  Future<void> stop() async {
    await _audioPlayer.stop();
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
    List<ItemDTO>? songs,
    ItemDTO? album,
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
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playbackProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>(
  PlaybackNotifier.new,
);
