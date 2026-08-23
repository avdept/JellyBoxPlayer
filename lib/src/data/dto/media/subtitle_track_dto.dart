import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle_track_dto.freezed.dart';
part 'subtitle_track_dto.g.dart';

@freezed
abstract class SubtitleTrackDTO with _$SubtitleTrackDTO {
  const factory SubtitleTrackDTO({
    @JsonKey(name: 'TrackEvents') @Default([]) List<TrackEventDTO> trackEvents,
  }) = _SubtitleTrackDTO;

  factory SubtitleTrackDTO.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackDTOFromJson(json);
}

@freezed
abstract class TrackEventDTO with _$TrackEventDTO {
  const factory TrackEventDTO({
    @JsonKey(name: 'Text') @Default('') String text,
    @JsonKey(name: 'StartPositionTicks') int? startPositionTicks,
    @JsonKey(name: 'EndPositionTicks') int? endPositionTicks,
  }) = _TrackEventDTO;

  factory TrackEventDTO.fromJson(Map<String, dynamic> json) =>
      _$TrackEventDTOFromJson(json);
}
