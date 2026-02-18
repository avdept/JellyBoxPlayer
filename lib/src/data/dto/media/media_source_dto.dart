import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/media/media_stream_dto.dart';

part 'media_source_dto.freezed.dart';
part 'media_source_dto.g.dart';

@freezed
abstract class MediaSourceDTO with _$MediaSourceDTO {
  const factory MediaSourceDTO({
    @JsonKey(name: 'Container') String? container,
    @JsonKey(name: 'MediaStreams') @Default([]) List<MediaStreamDTO> mediaStreams,
  }) = _MediaSourceDTO;

  factory MediaSourceDTO.fromJson(Map<String, dynamic> json) =>
      _$MediaSourceDTOFromJson(json);
}
