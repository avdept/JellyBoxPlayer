// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryDTO _$LibraryDTOFromJson(Map<String, dynamic> json) => _LibraryDTO(
  id: json['Id'] as String,
  name: json['Name'] as String?,
  path: json['Path'] as String?,
  type: json['Type'] as String?,
  collectionType: json['CollectionType'] as String?,
  imageTags:
      (json['ImageTags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$LibraryDTOToJson(_LibraryDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'Path': instance.path,
      'Type': instance.type,
      'CollectionType': instance.collectionType,
      'ImageTags': instance.imageTags,
    };

_Libraries _$LibrariesFromJson(Map<String, dynamic> json) => _Libraries(
  libraries:
      (json['Items'] as List<dynamic>)
          .map((e) => LibraryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$LibrariesToJson(_Libraries instance) =>
    <String, dynamic>{'Items': instance.libraries};
