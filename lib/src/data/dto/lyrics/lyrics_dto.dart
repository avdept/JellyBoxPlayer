import 'package:freezed_annotation/freezed_annotation.dart';

part 'lyrics_dto.freezed.dart';
part 'lyrics_dto.g.dart';

/// Jellyfin reports lyric timings in ticks (1 tick = 100 nanoseconds).
Duration? _fromTicks(int? ticks) =>
    ticks == null ? null : Duration(microseconds: ticks ~/ 10);

@freezed
abstract class LyricsDTO with _$LyricsDTO {
  const factory LyricsDTO({
    @JsonKey(name: 'Metadata')
    @Default(LyricMetadataDTO())
    LyricMetadataDTO metadata,
    @JsonKey(name: 'Lyrics') @Default([]) List<LyricLineDTO> lyrics,
  }) = _LyricsDTO;

  const LyricsDTO._();

  factory LyricsDTO.fromJson(Map<String, dynamic> json) =>
      _$LyricsDTOFromJson(json);

  /// Whether the lines carry timestamps and can be followed along with
  /// playback. Servers that omit the flag are judged by their lines.
  bool get isSynced =>
      metadata.isSynced ?? lyrics.any((line) => line.start != null);

  /// Whether any line carries word level (ELRC) timings. Only servers
  /// running 10.11 or newer send these.
  bool get hasWordCues => lyrics.any((line) => line.cues?.isNotEmpty ?? false);

  /// Shift of the whole lyric track against the audio, to be added on top
  /// of every line's start time.
  Duration get offset => _fromTicks(metadata.offset) ?? Duration.zero;
}

@freezed
abstract class LyricLineDTO with _$LyricLineDTO {
  const factory LyricLineDTO({
    @JsonKey(name: 'Text') @Default('') String text,
    @JsonKey(name: 'Start') int? start,
    @JsonKey(name: 'Cues') List<LyricLineCueDTO>? cues,
  }) = _LyricLineDTO;

  const LyricLineDTO._();

  factory LyricLineDTO.fromJson(Map<String, dynamic> json) =>
      _$LyricLineDTOFromJson(json);

  /// Null on unsynced lyrics.
  Duration? get startTime => _fromTicks(start);
}

/// Timing of a single word within a [LyricLineDTO], as a character range
/// into that line's text.
@freezed
abstract class LyricLineCueDTO with _$LyricLineCueDTO {
  const factory LyricLineCueDTO({
    @JsonKey(name: 'Position') @Default(0) int position,
    @JsonKey(name: 'EndPosition') @Default(0) int endPosition,
    @JsonKey(name: 'Start') @Default(0) int start,
    @JsonKey(name: 'End') int? end,
  }) = _LyricLineCueDTO;

  const LyricLineCueDTO._();

  factory LyricLineCueDTO.fromJson(Map<String, dynamic> json) =>
      _$LyricLineCueDTOFromJson(json);

  Duration get startTime => _fromTicks(start)!;

  Duration? get endTime => _fromTicks(end);
}

@freezed
abstract class LyricMetadataDTO with _$LyricMetadataDTO {
  const factory LyricMetadataDTO({
    @JsonKey(name: 'Artist') String? artist,
    @JsonKey(name: 'Album') String? album,
    @JsonKey(name: 'Title') String? title,
    @JsonKey(name: 'Author') String? author,
    @JsonKey(name: 'Length') int? length,
    @JsonKey(name: 'By') String? by,
    @JsonKey(name: 'Offset') int? offset,
    @JsonKey(name: 'Creator') String? creator,
    @JsonKey(name: 'Version') String? version,
    @JsonKey(name: 'IsSynced') bool? isSynced,
  }) = _LyricMetadataDTO;

  const LyricMetadataDTO._();

  factory LyricMetadataDTO.fromJson(Map<String, dynamic> json) =>
      _$LyricMetadataDTOFromJson(json);

  Duration? get duration => _fromTicks(length);
}
