import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

abstract final class QualityExtras {
  static const _codec = 'codec';
  static const _bitRate = 'bitRate';
  static const _sampleRate = 'sampleRate';
  static const _streamCodec = 'streamCodec';
  static const _streamBitRate = 'streamBitRate';
  static const _streamSampleRate = 'streamSampleRate';

  static Map<String, Object> of({
    AudioSourceInfo? original,
    AudioSourceInfo? streamed,
  }) => {
    _codec: ?original?.codec,
    _bitRate: ?original?.bitRate,
    _sampleRate: ?original?.sampleRate,
    _streamCodec: ?streamed?.codec,
    _streamBitRate: ?streamed?.bitRate,
    _streamSampleRate: ?streamed?.sampleRate,
  };

  static AudioSourceInfo original(Map<String, dynamic>? extras) =>
      AudioSourceInfo(
        codec: extras?[_codec] as String?,
        bitRate: extras?[_bitRate] as int?,
        sampleRate: extras?[_sampleRate] as int?,
      );

  static AudioSourceInfo? streamed(Map<String, dynamic>? extras) {
    if (extras == null ||
        !(extras.containsKey(_streamCodec) ||
            extras.containsKey(_streamBitRate) ||
            extras.containsKey(_streamSampleRate))) {
      return null;
    }
    return AudioSourceInfo(
      codec: extras[_streamCodec] as String?,
      bitRate: extras[_streamBitRate] as int?,
      sampleRate: extras[_streamSampleRate] as int?,
    );
  }

  static AudioSourceInfo heard(Map<String, dynamic>? extras) =>
      streamed(extras) ?? original(extras);
}
