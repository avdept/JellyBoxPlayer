import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';

@immutable
class StreamPreference {
  const StreamPreference({this.maxBitRate, this.codec});

  static const original = StreamPreference();

  final int? maxBitRate;
  final TranscodeTarget? codec;

  @override
  bool operator ==(Object other) =>
      other is StreamPreference &&
      other.maxBitRate == maxBitRate &&
      other.codec == codec;

  @override
  int get hashCode => Object.hash(maxBitRate, codec);
}
