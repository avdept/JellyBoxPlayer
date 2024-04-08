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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

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
  @JsonKey(name: 'Type')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'Overview')
  String? get overview => throw _privateConstructorUsedError;
  @JsonKey(name: 'RunTimeTicks')
  int? get durationInTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProductionYear')
  int? get productionYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'BackdropImageTags')
  List<String> get backgropImageTags => throw _privateConstructorUsedError;
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
      @JsonKey(name: 'Type') String type,
      @JsonKey(name: 'Overview') String? overview,
      @JsonKey(name: 'RunTimeTicks') int? durationInTicks,
      @JsonKey(name: 'ProductionYear') int? productionYear,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'BackdropImageTags') List<String> backgropImageTags,
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
    Object? type = null,
    Object? overview = freezed,
    Object? durationInTicks = freezed,
    Object? productionYear = freezed,
    Object? albumArtist = freezed,
    Object? backgropImageTags = null,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      overview: freezed == overview
          ? _value.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String?,
      durationInTicks: freezed == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int?,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      backgropImageTags: null == backgropImageTags
          ? _value.backgropImageTags
          : backgropImageTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageTags: null == imageTags
          ? _value.imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemDTOImplCopyWith<$Res> implements $ItemDTOCopyWith<$Res> {
  factory _$$ItemDTOImplCopyWith(
          _$ItemDTOImpl value, $Res Function(_$ItemDTOImpl) then) =
      __$$ItemDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'ServerId') String serverId,
      @JsonKey(name: 'Type') String type,
      @JsonKey(name: 'Overview') String? overview,
      @JsonKey(name: 'RunTimeTicks') int? durationInTicks,
      @JsonKey(name: 'ProductionYear') int? productionYear,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'BackdropImageTags') List<String> backgropImageTags,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class __$$ItemDTOImplCopyWithImpl<$Res>
    extends _$ItemDTOCopyWithImpl<$Res, _$ItemDTOImpl>
    implements _$$ItemDTOImplCopyWith<$Res> {
  __$$ItemDTOImplCopyWithImpl(
      _$ItemDTOImpl _value, $Res Function(_$ItemDTOImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? serverId = null,
    Object? type = null,
    Object? overview = freezed,
    Object? durationInTicks = freezed,
    Object? productionYear = freezed,
    Object? albumArtist = freezed,
    Object? backgropImageTags = null,
    Object? imageTags = null,
  }) {
    return _then(_$ItemDTOImpl(
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      overview: freezed == overview
          ? _value.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String?,
      durationInTicks: freezed == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int?,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      backgropImageTags: null == backgropImageTags
          ? _value._backgropImageTags
          : backgropImageTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageTags: null == imageTags
          ? _value._imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemDTOImpl extends _ItemDTO {
  const _$ItemDTOImpl(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'ServerId') required this.serverId,
      @JsonKey(name: 'Type') required this.type,
      @JsonKey(name: 'Overview') this.overview,
      @JsonKey(name: 'RunTimeTicks') required this.durationInTicks,
      @JsonKey(name: 'ProductionYear') this.productionYear,
      @JsonKey(name: 'AlbumArtist') this.albumArtist,
      @JsonKey(name: 'BackdropImageTags')
      final List<String> backgropImageTags = const [],
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags = const {}})
      : _backgropImageTags = backgropImageTags,
        _imageTags = imageTags,
        super._();

  factory _$ItemDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemDTOImplFromJson(json);

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
  @JsonKey(name: 'Type')
  final String type;
  @override
  @JsonKey(name: 'Overview')
  final String? overview;
  @override
  @JsonKey(name: 'RunTimeTicks')
  final int? durationInTicks;
  @override
  @JsonKey(name: 'ProductionYear')
  final int? productionYear;
  @override
  @JsonKey(name: 'AlbumArtist')
  final String? albumArtist;
  final List<String> _backgropImageTags;
  @override
  @JsonKey(name: 'BackdropImageTags')
  List<String> get backgropImageTags {
    if (_backgropImageTags is EqualUnmodifiableListView)
      return _backgropImageTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_backgropImageTags);
  }

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
    return 'ItemDTO(id: $id, name: $name, serverId: $serverId, type: $type, overview: $overview, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, backgropImageTags: $backgropImageTags, imageTags: $imageTags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemDTOImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.durationInTicks, durationInTicks) ||
                other.durationInTicks == durationInTicks) &&
            (identical(other.productionYear, productionYear) ||
                other.productionYear == productionYear) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            const DeepCollectionEquality()
                .equals(other._backgropImageTags, _backgropImageTags) &&
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
      type,
      overview,
      durationInTicks,
      productionYear,
      albumArtist,
      const DeepCollectionEquality().hash(_backgropImageTags),
      const DeepCollectionEquality().hash(_imageTags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemDTOImplCopyWith<_$ItemDTOImpl> get copyWith =>
      __$$ItemDTOImplCopyWithImpl<_$ItemDTOImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemDTOImplToJson(
      this,
    );
  }
}

abstract class _ItemDTO extends ItemDTO {
  const factory _ItemDTO(
      {@JsonKey(name: 'Id') required final String id,
      @JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'ServerId') required final String serverId,
      @JsonKey(name: 'Type') required final String type,
      @JsonKey(name: 'Overview') final String? overview,
      @JsonKey(name: 'RunTimeTicks') required final int? durationInTicks,
      @JsonKey(name: 'ProductionYear') final int? productionYear,
      @JsonKey(name: 'AlbumArtist') final String? albumArtist,
      @JsonKey(name: 'BackdropImageTags') final List<String> backgropImageTags,
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags}) = _$ItemDTOImpl;
  const _ItemDTO._() : super._();

  factory _ItemDTO.fromJson(Map<String, dynamic> json) = _$ItemDTOImpl.fromJson;

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
  @JsonKey(name: 'Type')
  String get type;
  @override
  @JsonKey(name: 'Overview')
  String? get overview;
  @override
  @JsonKey(name: 'RunTimeTicks')
  int? get durationInTicks;
  @override
  @JsonKey(name: 'ProductionYear')
  int? get productionYear;
  @override
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist;
  @override
  @JsonKey(name: 'BackdropImageTags')
  List<String> get backgropImageTags;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags;
  @override
  @JsonKey(ignore: true)
  _$$ItemDTOImplCopyWith<_$ItemDTOImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
