import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_source_info.freezed.dart';
part 'audio_source_info.g.dart';

@freezed
abstract class AudioSourceInfo with _$AudioSourceInfo {
  const factory AudioSourceInfo({
    String? id,
    String? container,
    String? codec,
    int? bitRate,
    int? sampleRate,
    int? bitDepth,
    int? channels,
    String? channelLayout,
  }) = _AudioSourceInfo;

  factory AudioSourceInfo.fromJson(Map<String, dynamic> json) =>
      _$AudioSourceInfoFromJson(json);
}
