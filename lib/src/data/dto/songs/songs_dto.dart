import 'package:freezed_annotation/freezed_annotation.dart';

part 'songs_dto.freezed.dart';
part 'songs_dto.g.dart';

@freezed
class SongDTO with _$SongDTO {

  const factory SongDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Album') required String albumName,
    @JsonKey(name: 'RunTimeTicks') required int runTimeTicks,
    @JsonKey(name: 'IndexNumber') required int indexNumber,
    @JsonKey(name: 'AlbumArtist') required String albumArtist,
    @JsonKey(name: 'UserData') required SongUserData songUserData,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _SongDTO;

  factory SongDTO.fromJson(Map<String, dynamic> json) => _$SongDTOFromJson(json);
}

@freezed
class SongsWrapper with _$SongsWrapper {
  const factory SongsWrapper({@JsonKey(name: 'Items') required List<SongDTO> items}) = _SongsWrapper;

  factory SongsWrapper.fromJson(Map<String, dynamic> json) => _$SongsWrapperFromJson(json);
}


@freezed
class SongUserData with _$SongUserData {
  const factory SongUserData({
    @JsonKey(name: 'PlaybackPositionTicks') required int playbackPositionTicks,
    @JsonKey(name: 'PlayCount') required int playCount,
    @JsonKey(name: 'IsFavorite') required bool isFavorite,
    @JsonKey(name: 'Played') required bool played,
  }) = _SongUserData;

  factory SongUserData.fromJson(Map<String, dynamic> json) => _$SongUserDataFromJson(json);
}
