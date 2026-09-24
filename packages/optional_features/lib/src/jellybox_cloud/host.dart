import 'package:meta/meta.dart';

@immutable
class CloudPlayback {
  const CloudPlayback({
    required this.itemIds,
    required this.index,
    required this.position,
    required this.playing,
    this.albumId,
    this.shuffle = false,
    this.repeat = 'off',
    this.volume = 1,
  });

  final List<String> itemIds;
  final String? albumId;
  final int index;
  final Duration position;
  final bool playing;
  final bool shuffle;
  final String repeat;
  final double volume;

  bool get isEmpty => itemIds.isEmpty;
}

abstract class CloudHost<S> {
  String get deviceId;

  String get deviceName;

  String get platform;

  String? get backendRef;

  String? get benchUserId;

  CloudPlayback? get playback;

  Stream<CloudPlayback?> get playbackChanges;

  Future<List<S>> itemsByIds(List<String> ids);

  Future<S?> albumById(String id);

  S placeholderAlbumFor(S song);

  Future<void> play({
    required List<S> songs,
    required int index,
    required S? album,
    required Duration position,
    required bool autoPlay,
    required bool shuffle,
  });

  Future<void> pause();

  Future<void> resume();

  Future<void> skipNext();

  Future<void> skipPrevious();

  Future<void> seek(Duration position);

  Future<void> setShuffle({required bool enabled});

  Future<void> setRepeat(String mode);

  Future<void> setVolume(double level);

  Future<void> skipTo(int index);

  bool get rendersLocally;

  Future<int?> millisUntilAudible(Duration from);

  Duration get bufferedPosition;

  Future<String?> readSecret(String key);

  Future<void> writeSecret(String key, String value);

  Future<void> deleteSecret(String key);
}
