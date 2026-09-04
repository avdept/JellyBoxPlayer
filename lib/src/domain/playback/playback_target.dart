import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';

enum PlaybackTargetKind { local, upnp }

class TargetTrack {
  const TargetTrack({
    required this.itemId,
    required this.uri,
    required this.mimeType,
    required this.isHls,
    required this.title,
    required this.duration,
    this.artist,
    this.album,
    this.artUri,
    this.extras = const <String, dynamic>{},
  });

  final String itemId;
  final Uri uri;
  final String mimeType;
  final bool isHls;
  final String title;
  final Duration duration;
  final String? artist;
  final String? album;
  final Uri? artUri;
  final Map<String, dynamic> extras;

  bool get isLocalFile => uri.isScheme('file');
}

class TargetPlaybackState {
  const TargetPlaybackState({
    required this.status,
    required this.position,
    this.currentIndex,
    this.duration,
    this.canSeek = true,
    this.completed = false,
  });

  static const idle = TargetPlaybackState(
    status: PlaybackStatus.stopped,
    position: Duration.zero,
  );

  final PlaybackStatus status;
  final Duration position;
  final int? currentIndex;
  final Duration? duration;
  final bool canSeek;
  final bool completed;

  TargetPlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    int? currentIndex,
    Duration? duration,
    bool? canSeek,
    bool? completed,
  }) => TargetPlaybackState(
    status: status ?? this.status,
    position: position ?? this.position,
    currentIndex: currentIndex ?? this.currentIndex,
    duration: duration ?? this.duration,
    canSeek: canSeek ?? this.canSeek,
    completed: completed ?? this.completed,
  );
}

abstract class PlaybackTarget {
  String get id;

  String get name;

  PlaybackTargetKind get kind;

  StreamTargetProfile get streamProfile;

  bool get supportsLocalFiles;

  TargetPlaybackState get state;

  Stream<TargetPlaybackState> get stateStream;

  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> skipTo(int index);

  Future<void> seekToNext();

  Future<void> seekToPrevious();

  Future<void> setVolume(double level);

  Future<double?> currentVolume();

  Future<void> dispose();
}
