import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_stream_dto.freezed.dart';
part 'media_stream_dto.g.dart';

@freezed
abstract class MediaStreamDTO with _$MediaStreamDTO {
  const factory MediaStreamDTO({
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'Codec') String? codec,
    @JsonKey(name: 'BitRate') int? bitRate,
    @JsonKey(name: 'SampleRate') int? sampleRate,
    @JsonKey(name: 'BitDepth') int? bitDepth,
    @JsonKey(name: 'Channels') int? channels,
    @JsonKey(name: 'ChannelLayout') String? channelLayout,
  }) = _MediaStreamDTO;

  factory MediaStreamDTO.fromJson(Map<String, dynamic> json) =>
      _$MediaStreamDTOFromJson(json);
}
