import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_dto.freezed.dart';
part 'library_dto.g.dart';

@freezed
abstract class LibraryDTO with _$LibraryDTO {
  const factory LibraryDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') String? name,
    @JsonKey(name: 'Path') String? path,
    @JsonKey(name: 'Type') String? type,
    @JsonKey(name: 'CollectionType') String? collectionType,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _LibraryDTO;

  factory LibraryDTO.fromJson(Map<String, dynamic> json) => _$LibraryDTOFromJson(json);
}

@freezed
abstract class Libraries with _$Libraries {
  const factory Libraries({@JsonKey(name: 'Items') required List<LibraryDTO> libraries}) = _Libraries;

  factory Libraries.fromJson(Map<String, dynamic> json) => _$LibrariesFromJson(json);

}
