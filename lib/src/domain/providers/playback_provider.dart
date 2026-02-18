// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum PlaybackStatus { stopped, paused, playing, buffering, error }

class PlaybackState {
  PlaybackState({
    required this.status,
    required this.position,
    required this.cacheProgress,
    this.totalDuration,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration cacheProgress;
  final Duration? totalDuration;
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(this._ref)
    : super(
        PlaybackState(
          status: PlaybackStatus.stopped,
          position: Duration.zero,
          cacheProgress: Duration.zero,
        ),
      ) {
    _audioPlayer = _ref.watch(playerProvider)
      // Listen for song completion
      ..positionStream.listen((position) {
        state = PlaybackState(
          status: state.status,
          position: position,
          cacheProgress: state.cacheProgress,
          totalDuration: _audioPlayer.duration,
        );
      })
      // Handle other player states as needed
      ..playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          state = PlaybackState(
            status: PlaybackStatus.stopped,
            position: Duration.zero,
            cacheProgress: Duration.zero,
            totalDuration: Duration.zero,
          );
          _audioPlayer
            ..stop()
            ..setAudioSource(_audioPlayer.audioSource!, initialIndex: 0);
        }
      });
  }

  final Ref _ref;
  late AudioPlayer _audioPlayer;

  Future<void> play(
    ItemDTO playSong,
    List<ItemDTO> songs,
    ItemDTO album,
  ) async {
    try {
      final domainUri = Uri.parse(_ref.read(baseUrlProvider)!);
      final downloadManager = _ref.read(downloadManagerProvider.notifier);

      final playlist = ConcatenatingAudioSource(
        children: await Future.wait(
          songs.map((song) async {
            // Check if song is downloaded*
            final isDownloaded = await downloadManager.isSongDownloaded(
              song.id,
            );
            final downloadedPath = isDownloaded
                ? await _ref
                      .read(downloadDatabaseProvider)
                      .getDownloadedSongPath(song.id)
                : null;

            // If downloaded, use local file, otherwise stream from server*
            final audioStream = song.mediaSources.firstOrNull?.mediaStreams
                .where((s) => s.type == 'Audio')
                .firstOrNull;
            final extras = <String, dynamic>{
              if (audioStream?.codec != null) 'codec': audioStream!.codec,
              if (audioStream?.bitRate != null) 'bitRate': audioStream!.bitRate,
              if (audioStream?.sampleRate != null)
                'sampleRate': audioStream!.sampleRate,
            };

            final audioSource = downloadedPath != null
                ? AudioSource.uri(
                    Uri.file(downloadedPath),
                    tag: MediaItem(
                      id: song.id,
                      album: song.albumName,
                      artist: album.albumArtist,
                      duration: Duration(
                        milliseconds: (song.runTimeTicks / 10000).ceil(),
                      ),
                      title: song.name ?? 'Untitled',
                      extras: extras.isNotEmpty ? extras : null,
                      artUri: song.imageTags['Primary'] != null
                          ? Uri.parse(
                              _ref
                                  .read(imageServiceProvider)
                                  .imagePath(
                                    tagId: song.imageTags['Primary']!,
                                    id: song.id,
                                  ),
                            )
                          : album.imageTags['Primary'] != null
                          ? Uri.parse(
                              _ref
                                  .read(imageServiceProvider)
                                  .imagePath(
                                    tagId: album.imageTags['Primary']!,
                                    id: album.id,
                                  ),
                            )
                          : null,
                    ),
                  )
                : AudioSource.uri(
                    Uri(
                      scheme: domainUri.scheme,
                      host: domainUri.host,
                      port: domainUri.port,
                      path: 'Audio/${song.id}/universal',
                      queryParameters: {
                        'UserId': _ref.read(currentUserProvider)!.userId,
                        'api_key': _ref.read(currentUserProvider)!.token,
                        'DeviceId': '12345',
                        'TranscodingProtocol': 'http',
                        'TranscodingContainer': 'm4a',
                        'AudioCodec': 'm4a',
                        'Container':
                            'mp3,aac,m4a|aac,m4b|aac,flac,alac,m4a|alac,m4b|alac,wav,m4a,aiff,aif',
                      },
                    ),
                    tag: MediaItem(
                      id: song.id,
                      album: song.albumName,
                      artist: album.albumArtist,
                      duration: Duration(
                        milliseconds: (song.runTimeTicks / 10000).ceil(),
                      ),
                      title: song.name,
                      extras: extras.isNotEmpty ? extras : null,
                      artUri: song.imageTags['Primary'] != null
                          ? Uri.parse(
                              _ref
                                  .read(imageServiceProvider)
                                  .imagePath(
                                    tagId: song.imageTags['Primary']!,
                                    id: song.id,
                                  ),
                            )
                          : album.imageTags['Primary'] != null
                          ? Uri.parse(
                              _ref
                                  .read(imageServiceProvider)
                                  .imagePath(
                                    tagId: album.imageTags['Primary']!,
                                    id: album.id,
                                  ),
                            )
                          : null,
                    ),
                  );

            return audioSource;
          }),
        ),
      );

      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: songs.indexOf(playSong),
        preload: false,
      );
      unawaited(_audioPlayer.play());
      state = PlaybackState(
        status: PlaybackStatus.playing,
        position: Duration.zero,
        totalDuration: _audioPlayer.duration,
        cacheProgress: state.cacheProgress,
      );
    } catch (e) {
      if (e.toString().indexOf('setPitch') > 0) {
        // This is hack to avoid playback state being error on ios*`

        state = PlaybackState(
          status: PlaybackStatus.playing,
          position: Duration.zero,
          totalDuration: _audioPlayer.duration,
          cacheProgress: state.cacheProgress,
        );
      } else {
        state = PlaybackState(
          status: PlaybackStatus.error,
          position: state.position,
          totalDuration: state.totalDuration,
          cacheProgress: state.cacheProgress,
        );
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    state = PlaybackState(
      status: state.status,
      position: position,
      cacheProgress: state.cacheProgress,
      totalDuration: state.totalDuration,
    );
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    state = PlaybackState(
      status: PlaybackStatus.paused,
      position: _audioPlayer.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
    );
  }

  Future<void> playPause() async {
    if (state.status == PlaybackStatus.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> resume() async {
    if ((state.status == PlaybackStatus.stopped) &&
        state.totalDuration?.inSeconds == 0) {
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

    // }
    unawaited(_audioPlayer.play());
    state = PlaybackState(
      status: PlaybackStatus.playing,
      position: _audioPlayer.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
    );
  }

  Future<void> next() async {
    return _audioPlayer.seekToNext();
    // await play(_ref.read(audioQueueProvider.notifier).nextSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> prev() async {
    return _audioPlayer.seekToPrevious();
    // await play(_ref.read(audioQueueProvider.notifier).prevSong, _ref.read(audioQueueProvider).songs, _ref.read(audioQueueProvider).album!);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = PlaybackState(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
      totalDuration: Duration.zero,
      cacheProgress: state.cacheProgress,
    );
  }

  void toggleRepeat() {
    state = PlaybackState(
      status: state.status,
      position: state.position,
      totalDuration: state.totalDuration,
      cacheProgress: state.cacheProgress,
    );
  }

  Future<void> _handleSongCompletion() async {
    final queueState = _ref.read(audioQueueProvider);
    state = PlaybackState(
      status: PlaybackStatus.paused,
      position: Duration.zero,
      cacheProgress: state.cacheProgress,
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
      state = PlaybackState(
        status: PlaybackStatus.stopped,
        cacheProgress: state.cacheProgress,
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
