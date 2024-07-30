import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_dto.freezed.dart';
part 'artist_dto.g.dart';

@freezed
class ArtistDTO with _$ArtistDTO {
  const factory ArtistDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
  }) = _ArtistDTO;

  factory ArtistDTO.fromJson(Map<String, dynamic> json) =>
      _$ArtistDTOFromJson(json);
}
