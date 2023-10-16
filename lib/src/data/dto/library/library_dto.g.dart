// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_LibraryDTO _$$_LibraryDTOFromJson(Map<String, dynamic> json) =>
    _$_LibraryDTO(
      id: json['Id'] as String,
      name: json['Name'] as String?,
      path: json['Path'] as String?,
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$_LibraryDTOToJson(_$_LibraryDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'Path': instance.path,
      'ImageTags': instance.imageTags,
    };

_$_Libraries _$$_LibrariesFromJson(Map<String, dynamic> json) => _$_Libraries(
      libraries: (json['Items'] as List<dynamic>)
          .map((e) => LibraryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_LibrariesToJson(_$_Libraries instance) =>
    <String, dynamic>{
      'Items': instance.libraries,
    };
