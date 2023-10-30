// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum PlaybackStatus { stopped, paused, playing, buffering, error }

class PlaybackState {
  PlaybackState({
    required this.status,
    required this.position,
    required this.repeat,
    required this.cacheProgress,
    this.totalDuration,
  });

  final bool repeat;
  final PlaybackStatus status;
  final Duration position;
  final Duration cacheProgress;
  final Duration? totalDuration;
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(
    this._ref,
    this._audioPlayer,
  ) : super(PlaybackState(status: PlaybackStatus.stopped, position: Duration.zero, repeat: false, cacheProgress: Duration.zero)) {
    // Listen for song completion
    _audioPlayer.positionStream.listen((position) {
      state = PlaybackState(
        status: state.status,
        repeat: state.repeat,
        position: position,
        cacheProgress: state.cacheProgress,
        totalDuration: _audioPlayer.duration,
      );
    });

    // _audioPlayer.bufferedPositionStream.listen((buffering) {
    //   state = PlaybackState(
    //     status: state.status,
    //     repeat: state.repeat,
    //     position: state.position,
    //     cacheProgress: buffering,
    //     totalDuration: _audioPlayer.duration,
    //   );
    // });

    _audioPlayer.positionDiscontinuityStream.listen((discontinuity) {
      if (discontinuity.reason == PositionDiscontinuityReason.autoAdvance) {
        print(discontinuity.reason);
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        print('PlayerState: Completed');
        _handleSongCompletion();
      }
      // Handle other player states as needed
    });
  }
  final AudioPlayer _audioPlayer;
  final StateNotifierProviderRef<PlaybackNotifier, PlaybackState> _ref;

  Future<void> play(SongDTO playSong, List<SongDTO> songs, ItemDTO album) async {
    _ref.read(audioQueueProvider.notifier).setNewQueue(songs, playSong, album);
    try {
      final domainUri = Uri.parse(_ref.read(baseUrlProvider)!);

      final fileUri = Uri(
        scheme: domainUri.scheme,
        host: domainUri.host,
        port: domainUri.port,
        path: 'Audio/${playSong.id}/universal',
        queryParameters: {
          'UserId': _ref.read(currentUserProvider)!.userId,
          'api_key': _ref.read(currentUserProvider)!.token,
          'DeviceId': '12345',
          'TranscodingProtocol': 'http',
          'TranscodingContainer': 'm4a',
          'AudioCodec': 'm4a',
          'Container': 'mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,wav,m4a,aiff,aif',
        },
      );

      final uri = AudioSource.uri(
        fileUri,
        tag: MediaItem(
          id: playSong.id,
          album: playSong.albumName,
          artist: album.albumArtist,
          duration: Duration(milliseconds: (playSong.runTimeTicks / 10000).ceil()),
          title: playSong.name ?? 'Untitled',
          artUri: playSong.imageTags['Primary'] != null
              ? Uri.parse(_ref.read(imageProvider).imagePath(tagId: playSong.imageTags['Primary']!, id: playSong.id))
              : null,
        ),
      );
      await _audioPlayer.setAudioSource(uri);
      unawaited(_audioPlayer.play());
      state = PlaybackState(
        status: PlaybackStatus.playing,
        position: Duration.zero,
        totalDuration: _audioPlayer.duration,
        cacheProgress: state.cacheProgress,
        repeat: state.repeat,
      );
    } catch (e) {
      if (e.toString().indexOf('setPitch') > 0) {
        // This is hack to avoid playback state being error on ios. This error always throws
        return;
      }
      state = PlaybackState(
        status: PlaybackStatus.error,
        position: Duration.zero,
        repeat: state.repeat,
        cacheProgress: state.cacheProgress,
      );
      // Handle the error as needed
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    state = PlaybackState(
      status: state.status,
      position: position,
      cacheProgress: state.cacheProgress,
      totalDuration: state.totalDuration,
      repeat: state.repeat,
    );
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    state = PlaybackState(
      status: PlaybackStatus.paused,
      position: _audioPlayer.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
      repeat: state.repeat,
    );
  }

  Future<void> resume() async {
    if ((state.status == PlaybackStatus.stopped) && state.totalDuration?.inSeconds == 0) {
      final queue = _ref.read(audioQueueProvider.notifier);
      // Case when song has finished but user clicks on play(resume) button. In this case we want to restart playback from first song.
      if (queue.state.songs.isNotEmpty) {
        await play(queue.state.songs.first, queue.state.songs, queue.state.album!);
      }

      return;
    }

    // }
    unawaited(_audioPlayer.play());
    state = PlaybackState(
      status: PlaybackStatus.playing,
      position: _audioPlayer.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
      repeat: state.repeat,
    );
  }

  Future<void> next() async {
    await play(_ref.read(audioQueueProvider.notifier).nextSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> prev() async {
    await play(_ref.read(audioQueueProvider.notifier).prevSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = PlaybackState(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
      totalDuration: Duration.zero,
      cacheProgress: state.cacheProgress,
      repeat: state.repeat,
    );
  }

  void toggleRepeat() {
    state = PlaybackState(
      status: state.status,
      position: state.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
      repeat: !state.repeat,
    );
  }

  Future<void> _handleSongCompletion() async {
    final queueState = _ref.read(audioQueueProvider);
    state = PlaybackState(
      status: PlaybackStatus.paused,
      position: Duration.zero,
      cacheProgress: state.cacheProgress,
      totalDuration: Duration.zero,
      repeat: state.repeat,
    );
    final currentSong = queueState.currentSong;
    final songs = queueState.songs;

    if (currentSong == null) return;

    final currentIndex = songs.indexOf(songs.firstWhere((element) => element == currentSong));
    if (currentIndex != -1 && currentIndex + 1 < songs.length) {
      // There's a next song in the queue
      final nextSong = songs[currentIndex + 1];
      _ref.read(audioQueueProvider.notifier).setCurrentSong(nextSong);
      unawaited(play(nextSong, songs, queueState.album!)); // Start playing the next song
    } else {
      if (state.repeat) {
        final nextSong = songs.first;
        _ref.read(audioQueueProvider.notifier).setCurrentSong(nextSong);
        unawaited(
          play(
            nextSong,
            songs,
            queueState.album!,
          ),
        );
      } else {
        await _ref.read(playerProvider).stop();
        state = PlaybackState(
          status: PlaybackStatus.stopped,
          cacheProgress: state.cacheProgress,
          position: Duration.zero,
          totalDuration: Duration.zero,
          repeat: state.repeat,
        );
      }
      // Handle the end of the queue (e.g., loop, stop playback, etc.)
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playbackProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) => PlaybackNotifier(ref, ref.read(playerProvider)));
