// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ItemDTO _$ItemDTOFromJson(Map<String, dynamic> json) {
  return _ItemDTO.fromJson(json);
}

/// @nodoc
mixin _$ItemDTO {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'ServerId')
  String get serverId => throw _privateConstructorUsedError;
  @JsonKey(name: 'RunTimeTicks')
  int get durationInTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProductionYear')
  int? get productionYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemDTOCopyWith<ItemDTO> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemDTOCopyWith<$Res> {
  factory $ItemDTOCopyWith(ItemDTO value, $Res Function(ItemDTO) then) =
      _$ItemDTOCopyWithImpl<$Res, ItemDTO>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'ServerId') String serverId,
      @JsonKey(name: 'RunTimeTicks') int durationInTicks,
      @JsonKey(name: 'ProductionYear') int? productionYear,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class _$ItemDTOCopyWithImpl<$Res, $Val extends ItemDTO>
    implements $ItemDTOCopyWith<$Res> {
  _$ItemDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? serverId = null,
    Object? durationInTicks = null,
    Object? productionYear = freezed,
    Object? albumArtist = freezed,
    Object? imageTags = null,
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
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      durationInTicks: null == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      imageTags: null == imageTags
          ? _value.imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemDTOCopyWith<$Res> implements $ItemDTOCopyWith<$Res> {
  factory _$$_ItemDTOCopyWith(
          _$_ItemDTO value, $Res Function(_$_ItemDTO) then) =
      __$$_ItemDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'ServerId') String serverId,
      @JsonKey(name: 'RunTimeTicks') int durationInTicks,
      @JsonKey(name: 'ProductionYear') int? productionYear,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class __$$_ItemDTOCopyWithImpl<$Res>
    extends _$ItemDTOCopyWithImpl<$Res, _$_ItemDTO>
    implements _$$_ItemDTOCopyWith<$Res> {
  __$$_ItemDTOCopyWithImpl(_$_ItemDTO _value, $Res Function(_$_ItemDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? serverId = null,
    Object? durationInTicks = null,
    Object? productionYear = freezed,
    Object? albumArtist = freezed,
    Object? imageTags = null,
  }) {
    return _then(_$_ItemDTO(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      durationInTicks: null == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      imageTags: null == imageTags
          ? _value._imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemDTO extends _ItemDTO {
  const _$_ItemDTO(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'ServerId') required this.serverId,
      @JsonKey(name: 'RunTimeTicks') required this.durationInTicks,
      @JsonKey(name: 'ProductionYear') this.productionYear,
      @JsonKey(name: 'AlbumArtist') this.albumArtist,
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags = const {}})
      : _imageTags = imageTags,
        super._();

  factory _$_ItemDTO.fromJson(Map<String, dynamic> json) =>
      _$$_ItemDTOFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'ServerId')
  final String serverId;
  @override
  @JsonKey(name: 'RunTimeTicks')
  final int durationInTicks;
  @override
  @JsonKey(name: 'ProductionYear')
  final int? productionYear;
  @override
  @JsonKey(name: 'AlbumArtist')
  final String? albumArtist;
  final Map<String, String> _imageTags;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags {
    if (_imageTags is EqualUnmodifiableMapView) return _imageTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_imageTags);
  }

  @override
  String toString() {
    return 'ItemDTO(id: $id, name: $name, serverId: $serverId, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, imageTags: $imageTags)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.durationInTicks, durationInTicks) ||
                other.durationInTicks == durationInTicks) &&
            (identical(other.productionYear, productionYear) ||
                other.productionYear == productionYear) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            const DeepCollectionEquality()
                .equals(other._imageTags, _imageTags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      serverId,
      durationInTicks,
      productionYear,
      albumArtist,
      const DeepCollectionEquality().hash(_imageTags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemDTOCopyWith<_$_ItemDTO> get copyWith =>
      __$$_ItemDTOCopyWithImpl<_$_ItemDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemDTOToJson(
      this,
    );
  }
}

abstract class _ItemDTO extends ItemDTO {
  const factory _ItemDTO(
          {@JsonKey(name: 'Id') required final String id,
          @JsonKey(name: 'Name') required final String name,
          @JsonKey(name: 'ServerId') required final String serverId,
          @JsonKey(name: 'RunTimeTicks') required final int durationInTicks,
          @JsonKey(name: 'ProductionYear') final int? productionYear,
          @JsonKey(name: 'AlbumArtist') final String? albumArtist,
          @JsonKey(name: 'ImageTags') final Map<String, String> imageTags}) =
      _$_ItemDTO;
  const _ItemDTO._() : super._();

  factory _ItemDTO.fromJson(Map<String, dynamic> json) = _$_ItemDTO.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'ServerId')
  String get serverId;
  @override
  @JsonKey(name: 'RunTimeTicks')
  int get durationInTicks;
  @override
  @JsonKey(name: 'ProductionYear')
  int? get productionYear;
  @override
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags;
  @override
  @JsonKey(ignore: true)
  _$$_ItemDTOCopyWith<_$_ItemDTO> get copyWith =>
      throw _privateConstructorUsedError;
}
