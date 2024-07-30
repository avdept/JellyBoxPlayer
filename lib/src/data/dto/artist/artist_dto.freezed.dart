// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistDTO _$ArtistDTOFromJson(Map<String, dynamic> json) {
  return _ArtistDTO.fromJson(json);
}

/// @nodoc
mixin _$ArtistDTO {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistDTOCopyWith<ArtistDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistDTOCopyWith<$Res> {
  factory $ArtistDTOCopyWith(ArtistDTO value, $Res Function(ArtistDTO) then) =
      _$ArtistDTOCopyWithImpl<$Res, ArtistDTO>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id, @JsonKey(name: 'Name') String name});
}

/// @nodoc
class _$ArtistDTOCopyWithImpl<$Res, $Val extends ArtistDTO>
    implements $ArtistDTOCopyWith<$Res> {
  _$ArtistDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistDTOImplCopyWith<$Res>
    implements $ArtistDTOCopyWith<$Res> {
  factory _$$ArtistDTOImplCopyWith(
          _$ArtistDTOImpl value, $Res Function(_$ArtistDTOImpl) then) =
      __$$ArtistDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id, @JsonKey(name: 'Name') String name});
}

/// @nodoc
class __$$ArtistDTOImplCopyWithImpl<$Res>
    extends _$ArtistDTOCopyWithImpl<$Res, _$ArtistDTOImpl>
    implements _$$ArtistDTOImplCopyWith<$Res> {
  __$$ArtistDTOImplCopyWithImpl(
      _$ArtistDTOImpl _value, $Res Function(_$ArtistDTOImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$ArtistDTOImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistDTOImpl implements _ArtistDTO {
  const _$ArtistDTOImpl(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'Name') required this.name});

  factory _$ArtistDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistDTOImplFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;

  @override
  String toString() {
    return 'ArtistDTO(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistDTOImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistDTOImplCopyWith<_$ArtistDTOImpl> get copyWith =>
      __$$ArtistDTOImplCopyWithImpl<_$ArtistDTOImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistDTOImplToJson(
      this,
    );
  }
}

abstract class _ArtistDTO implements ArtistDTO {
  const factory _ArtistDTO(
      {@JsonKey(name: 'Id') required final String id,
      @JsonKey(name: 'Name') required final String name}) = _$ArtistDTOImpl;

  factory _ArtistDTO.fromJson(Map<String, dynamic> json) =
      _$ArtistDTOImpl.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$ArtistDTOImplCopyWith<_$ArtistDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
