import 'package:freezed_annotation/freezed_annotation.dart';

part 'album_dto.freezed.dart';
part 'album_dto.g.dart';

@freezed
class AlbumDTO with _$AlbumDTO {
  const AlbumDTO._();

  const factory AlbumDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'ServerId') required String serverId,
    @JsonKey(name: 'ProductionYear') required int productionYear,
    @JsonKey(name: 'RunTimeTicks') required int durationInTicks,
    @JsonKey(name: 'AlbumArtist') required String albumArtist,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _AlbumDTO;

  factory AlbumDTO.fromJson(Map<String, dynamic> json) => _$AlbumDTOFromJson(json);

  Duration get duration => Duration(seconds: (durationInTicks / 10000000).ceil());
}

@freezed
class AlbumsWrapper with _$AlbumsWrapper {
  const factory AlbumsWrapper({@JsonKey(name: 'Items') required List<AlbumDTO> items}) = _AlbumsWrapper;

  factory AlbumsWrapper.fromJson(Map<String, dynamic> json) => _$AlbumsWrapperFromJson(json);
}
