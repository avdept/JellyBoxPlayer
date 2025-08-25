// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
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
              _ref
                  .read(jellyfinApiProvider)
                  .playbackStopped(
                    values: PlaystateData(
                      playSessionId: _playSessionId,
                      itemId: currentSong.id,
                      item: currentSong,
                      mediaSourceId: state.album?.id,
                    ),
                  );
            }
          }
          if (nextIndex != null) {
            final nextSong = state.songs.elementAtOrNull(nextIndex);
            if (nextSong != null) {
              _ref
                  .read(jellyfinApiProvider)
                  .playbackStarted(
                    values: PlaystateData(
                      playSessionId: _playSessionId,
                      itemId: nextSong.id,
                      item: nextSong,
                      mediaSourceId: state.album?.id,
                    ),
                  );
            }
          }
        }
      })
      // Listen for song completion
      ..positionStream.listen((position) {
        state = state.copyWith(
          position: position,
          totalDuration: _audioPlayer.duration,
          currentMediaIndex: _audioPlayer.currentIndex,
        );
      })
      // Handle other player states as needed
      ..playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          state = PlaybackState.initial();
          // _audioPlayer
          //   ..stop()
          //   ..setAudioSource(_audioPlayer.audioSource!, initialIndex: 0);
        }
      });
  }

  final Ref _ref;
  late AudioPlayer _audioPlayer;
  var _playSessionId = '';

  Future<void> play(
    ItemDTO playSong,
    List<ItemDTO> songs,
    ItemDTO album,
  ) async {
    try {
      final audioSources = await Future.wait(
        songs.map((song) async {
          // Check if song is downloaded*
          final isDownloaded = await _ref.read(downloadManagerProvider.notifier).isSongDownloaded(song.id);
          final downloadedPath = isDownloaded ? await _ref.read(downloadDatabaseProvider).getDownloadedSongPath(song.id) : null;
          final audioSourceUri = (downloadedPath != null)
              ? Uri.file(downloadedPath)
              : Uri.parse(_ref.read(baseUrlProvider)!).replace(
                  path: 'Audio/${song.id}/universal',
                  queryParameters: {
                    'UserId': _ref.read(currentUserProvider)!.userId,
                    'api_key': _ref.read(currentUserProvider)!.token,
                    'DeviceId': deviceId,
                    'TranscodingProtocol': 'http',
                    'TranscodingContainer': 'm4a',
                    'AudioCodec': 'm4a',
                    'Container': [
                      'mp3,aac,m4a',
                      'aac,m4b',
                      'aac,flac,alac,m4a',
                      'alac,m4b',
                      'alac,wav,m4a,aiff,aif',
                    ].join('|'),
                  },
                );
          final imagePath = song.imageTags['Primary'] ?? album.imageTags['Primary'];

          final audioStream = song.mediaSources.firstOrNull?.mediaStreams.where((s) => s.type == 'Audio').firstOrNull;
          final extras = <String, dynamic>{
            if (audioStream?.codec != null) 'codec': audioStream!.codec,
            if (audioStream?.bitRate != null) 'bitRate': audioStream!.bitRate,
            if (audioStream?.sampleRate != null) 'sampleRate': audioStream!.sampleRate,
          };

          // If downloaded, use local file, otherwise stream from server*
          final audioSource = AudioSource.uri(
            audioSourceUri,
            tag: MediaItem(
              id: song.id,
              album: song.albumName,
              artist: album.albumArtist,
              duration: Duration(
                milliseconds: (song.runTimeTicks / 10000).ceil(),
              ),
              title: song.name,
              extras: extras,
              artUri: (imagePath == null)
                  ? null
                  : Uri.parse(
                      _ref.read(imageServiceProvider).imagePath(tagId: imagePath, id: song.id),
                    ),
            ),
          );

          return audioSource;
        }),
      );

      _playSessionId = DateTime.now().toIso8601String(); // Any unique ID
      await _audioPlayer.setAudioSources(
        audioSources,
        initialIndex: songs.indexOf(playSong),
        preload: false,
      );
      state = state.copyWith(
        songs: songs,
        album: album,
        status: PlaybackStatus.playing,
        position: Duration.zero,
        totalDuration: _audioPlayer.duration,
      );
      unawaited(_audioPlayer.play());
    } catch (e) {
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

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    state = state.copyWith(position: position);
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

  Future<void> prev() async {
    await _audioPlayer.seekToPrevious();
    if (!_audioPlayer.playing) await _audioPlayer.play();
    // await play(_ref.read(audioQueueProvider.notifier).prevSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

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

  Future<void> _handleSongCompletion() async {
    final queueState = _ref.read(audioQueueProvider);
    state = state.copyWith(
      status: PlaybackStatus.paused,
      position: Duration.zero,
      totalDuration: Duration.zero,
    );
    final currentSong = queueState.currentSong;
    final songs = queueState.songs;

    if (currentSong == null) return;

    final currentIndex = songs.indexOf(
      songs.firstWhere((element) => element == currentSong),
    );
    if (currentIndex != -1 && currentIndex + 1 < songs.length) {
      // There's a next song in the queue
      final nextSong = songs[currentIndex + 1];
      _ref.read(audioQueueProvider.notifier).setCurrentSong(nextSong);
      unawaited(
        play(nextSong, songs, queueState.album!),
      ); // Start playing the next song
    } else {
      await _ref.read(playerProvider).stop();
      state = state.copyWith(
        status: PlaybackStatus.stopped,
        position: Duration.zero,
        totalDuration: Duration.zero,
      );

      // Handle the end of the queue (e.g., loop, stop playback, etc.)
    }
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
