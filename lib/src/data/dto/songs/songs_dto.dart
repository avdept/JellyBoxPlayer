import 'package:freezed_annotation/freezed_annotation.dart';

part 'songs_dto.freezed.dart';
part 'songs_dto.g.dart';

@freezed
class SongDTO with _$SongDTO {
  const factory SongDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Album') required String albumName,
    @JsonKey(name: 'AlbumArtist') required String albumArtist,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _SongDTO;

  factory SongDTO.fromJson(Map<String, dynamic> json) => _$SongDTOFromJson(json);
}

@freezed
class SongsWrapper with _$SongsWrapper {
  const factory SongsWrapper({@JsonKey(name: 'Items') required List<SongDTO> items}) = _SongsWrapper;

  factory SongsWrapper.fromJson(Map<String, dynamic> json) => _$SongsWrapperFromJson(json);
}
