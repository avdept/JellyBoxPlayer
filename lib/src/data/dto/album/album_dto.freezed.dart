// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

AlbumDTO _$AlbumDTOFromJson(Map<String, dynamic> json) {
  return _AlbumDTO.fromJson(json);
}

/// @nodoc
mixin _$AlbumDTO {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'ServerId')
  String get serverId => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProductionYear')
  int get productionYear => throw _privateConstructorUsedError;
  @JsonKey(name: 'RunTimeTicks')
  int get durationInTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumDTOCopyWith<AlbumDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumDTOCopyWith<$Res> {
  factory $AlbumDTOCopyWith(AlbumDTO value, $Res Function(AlbumDTO) then) =
      _$AlbumDTOCopyWithImpl<$Res, AlbumDTO>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'ServerId') String serverId,
      @JsonKey(name: 'ProductionYear') int productionYear,
      @JsonKey(name: 'RunTimeTicks') int durationInTicks,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class _$AlbumDTOCopyWithImpl<$Res, $Val extends AlbumDTO>
    implements $AlbumDTOCopyWith<$Res> {
  _$AlbumDTOCopyWithImpl(this._value, this._then);

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
    Object? productionYear = null,
    Object? durationInTicks = null,
    Object? albumArtist = null,
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
      productionYear: null == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int,
      durationInTicks: null == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtist: null == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String,
      imageTags: null == imageTags
          ? _value.imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AlbumDTOCopyWith<$Res> implements $AlbumDTOCopyWith<$Res> {
  factory _$$_AlbumDTOCopyWith(
          _$_AlbumDTO value, $Res Function(_$_AlbumDTO) then) =
      __$$_AlbumDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'ServerId') String serverId,
      @JsonKey(name: 'ProductionYear') int productionYear,
      @JsonKey(name: 'RunTimeTicks') int durationInTicks,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class __$$_AlbumDTOCopyWithImpl<$Res>
    extends _$AlbumDTOCopyWithImpl<$Res, _$_AlbumDTO>
    implements _$$_AlbumDTOCopyWith<$Res> {
  __$$_AlbumDTOCopyWithImpl(
      _$_AlbumDTO _value, $Res Function(_$_AlbumDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? serverId = null,
    Object? productionYear = null,
    Object? durationInTicks = null,
    Object? albumArtist = null,
    Object? imageTags = null,
  }) {
    return _then(_$_AlbumDTO(
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
      productionYear: null == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int,
      durationInTicks: null == durationInTicks
          ? _value.durationInTicks
          : durationInTicks // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtist: null == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String,
      imageTags: null == imageTags
          ? _value._imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_AlbumDTO extends _AlbumDTO {
  const _$_AlbumDTO(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'ServerId') required this.serverId,
      @JsonKey(name: 'ProductionYear') required this.productionYear,
      @JsonKey(name: 'RunTimeTicks') required this.durationInTicks,
      @JsonKey(name: 'AlbumArtist') required this.albumArtist,
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags = const {}})
      : _imageTags = imageTags,
        super._();

  factory _$_AlbumDTO.fromJson(Map<String, dynamic> json) =>
      _$$_AlbumDTOFromJson(json);

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
  @JsonKey(name: 'ProductionYear')
  final int productionYear;
  @override
  @JsonKey(name: 'RunTimeTicks')
  final int durationInTicks;
  @override
  @JsonKey(name: 'AlbumArtist')
  final String albumArtist;
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
    return 'AlbumDTO(id: $id, name: $name, serverId: $serverId, productionYear: $productionYear, durationInTicks: $durationInTicks, albumArtist: $albumArtist, imageTags: $imageTags)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AlbumDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.productionYear, productionYear) ||
                other.productionYear == productionYear) &&
            (identical(other.durationInTicks, durationInTicks) ||
                other.durationInTicks == durationInTicks) &&
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
      productionYear,
      durationInTicks,
      albumArtist,
      const DeepCollectionEquality().hash(_imageTags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AlbumDTOCopyWith<_$_AlbumDTO> get copyWith =>
      __$$_AlbumDTOCopyWithImpl<_$_AlbumDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_AlbumDTOToJson(
      this,
    );
  }
}

abstract class _AlbumDTO extends AlbumDTO {
  const factory _AlbumDTO(
          {@JsonKey(name: 'Id') required final String id,
          @JsonKey(name: 'Name') required final String name,
          @JsonKey(name: 'ServerId') required final String serverId,
          @JsonKey(name: 'ProductionYear') required final int productionYear,
          @JsonKey(name: 'RunTimeTicks') required final int durationInTicks,
          @JsonKey(name: 'AlbumArtist') required final String albumArtist,
          @JsonKey(name: 'ImageTags') final Map<String, String> imageTags}) =
      _$_AlbumDTO;
  const _AlbumDTO._() : super._();

  factory _AlbumDTO.fromJson(Map<String, dynamic> json) = _$_AlbumDTO.fromJson;

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
  @JsonKey(name: 'ProductionYear')
  int get productionYear;
  @override
  @JsonKey(name: 'RunTimeTicks')
  int get durationInTicks;
  @override
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags;
  @override
  @JsonKey(ignore: true)
  _$$_AlbumDTOCopyWith<_$_AlbumDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

AlbumsWrapper _$AlbumsWrapperFromJson(Map<String, dynamic> json) {
  return _AlbumsWrapper.fromJson(json);
}

/// @nodoc
mixin _$AlbumsWrapper {
  @JsonKey(name: 'Items')
  List<AlbumDTO> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumsWrapperCopyWith<AlbumsWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumsWrapperCopyWith<$Res> {
  factory $AlbumsWrapperCopyWith(
          AlbumsWrapper value, $Res Function(AlbumsWrapper) then) =
      _$AlbumsWrapperCopyWithImpl<$Res, AlbumsWrapper>;
  @useResult
  $Res call({@JsonKey(name: 'Items') List<AlbumDTO> items});
}

/// @nodoc
class _$AlbumsWrapperCopyWithImpl<$Res, $Val extends AlbumsWrapper>
    implements $AlbumsWrapperCopyWith<$Res> {
  _$AlbumsWrapperCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<AlbumDTO>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AlbumsWrapperCopyWith<$Res>
    implements $AlbumsWrapperCopyWith<$Res> {
  factory _$$_AlbumsWrapperCopyWith(
          _$_AlbumsWrapper value, $Res Function(_$_AlbumsWrapper) then) =
      __$$_AlbumsWrapperCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Items') List<AlbumDTO> items});
}

/// @nodoc
class __$$_AlbumsWrapperCopyWithImpl<$Res>
    extends _$AlbumsWrapperCopyWithImpl<$Res, _$_AlbumsWrapper>
    implements _$$_AlbumsWrapperCopyWith<$Res> {
  __$$_AlbumsWrapperCopyWithImpl(
      _$_AlbumsWrapper _value, $Res Function(_$_AlbumsWrapper) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$_AlbumsWrapper(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<AlbumDTO>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_AlbumsWrapper implements _AlbumsWrapper {
  const _$_AlbumsWrapper(
      {@JsonKey(name: 'Items') required final List<AlbumDTO> items})
      : _items = items;

  factory _$_AlbumsWrapper.fromJson(Map<String, dynamic> json) =>
      _$$_AlbumsWrapperFromJson(json);

  final List<AlbumDTO> _items;
  @override
  @JsonKey(name: 'Items')
  List<AlbumDTO> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'AlbumsWrapper(items: $items)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AlbumsWrapper &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AlbumsWrapperCopyWith<_$_AlbumsWrapper> get copyWith =>
      __$$_AlbumsWrapperCopyWithImpl<_$_AlbumsWrapper>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_AlbumsWrapperToJson(
      this,
    );
  }
}

abstract class _AlbumsWrapper implements AlbumsWrapper {
  const factory _AlbumsWrapper(
          {@JsonKey(name: 'Items') required final List<AlbumDTO> items}) =
      _$_AlbumsWrapper;

  factory _AlbumsWrapper.fromJson(Map<String, dynamic> json) =
      _$_AlbumsWrapper.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<AlbumDTO> get items;
  @override
  @JsonKey(ignore: true)
  _$$_AlbumsWrapperCopyWith<_$_AlbumsWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}
