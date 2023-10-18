// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SongDTO _$SongDTOFromJson(Map<String, dynamic> json) {
  return _SongDTO.fromJson(json);
}

/// @nodoc
mixin _$SongDTO {
  @JsonKey(name: 'Id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Album')
  String get albumName => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SongDTOCopyWith<SongDTO> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongDTOCopyWith<$Res> {
  factory $SongDTOCopyWith(SongDTO value, $Res Function(SongDTO) then) =
      _$SongDTOCopyWithImpl<$Res, SongDTO>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Album') String albumName,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class _$SongDTOCopyWithImpl<$Res, $Val extends SongDTO>
    implements $SongDTOCopyWith<$Res> {
  _$SongDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? albumName = null,
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
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$_SongDTOCopyWith<$Res> implements $SongDTOCopyWith<$Res> {
  factory _$$_SongDTOCopyWith(
          _$_SongDTO value, $Res Function(_$_SongDTO) then) =
      __$$_SongDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Album') String albumName,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});
}

/// @nodoc
class __$$_SongDTOCopyWithImpl<$Res>
    extends _$SongDTOCopyWithImpl<$Res, _$_SongDTO>
    implements _$$_SongDTOCopyWith<$Res> {
  __$$_SongDTOCopyWithImpl(_$_SongDTO _value, $Res Function(_$_SongDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? albumName = null,
    Object? albumArtist = null,
    Object? imageTags = null,
  }) {
    return _then(_$_SongDTO(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$_SongDTO implements _SongDTO {
  const _$_SongDTO(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'Album') required this.albumName,
      @JsonKey(name: 'AlbumArtist') required this.albumArtist,
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags = const {}})
      : _imageTags = imageTags;

  factory _$_SongDTO.fromJson(Map<String, dynamic> json) =>
      _$$_SongDTOFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Album')
  final String albumName;
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
    return 'SongDTO(id: $id, name: $name, albumName: $albumName, albumArtist: $albumArtist, imageTags: $imageTags)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SongDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.albumName, albumName) ||
                other.albumName == albumName) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            const DeepCollectionEquality()
                .equals(other._imageTags, _imageTags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, albumName, albumArtist,
      const DeepCollectionEquality().hash(_imageTags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SongDTOCopyWith<_$_SongDTO> get copyWith =>
      __$$_SongDTOCopyWithImpl<_$_SongDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SongDTOToJson(
      this,
    );
  }
}

abstract class _SongDTO implements SongDTO {
  const factory _SongDTO(
          {@JsonKey(name: 'Id') required final String id,
          @JsonKey(name: 'Name') required final String name,
          @JsonKey(name: 'Album') required final String albumName,
          @JsonKey(name: 'AlbumArtist') required final String albumArtist,
          @JsonKey(name: 'ImageTags') final Map<String, String> imageTags}) =
      _$_SongDTO;

  factory _SongDTO.fromJson(Map<String, dynamic> json) = _$_SongDTO.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Album')
  String get albumName;
  @override
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags;
  @override
  @JsonKey(ignore: true)
  _$$_SongDTOCopyWith<_$_SongDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

SongsWrapper _$SongsWrapperFromJson(Map<String, dynamic> json) {
  return _SongsWrapper.fromJson(json);
}

/// @nodoc
mixin _$SongsWrapper {
  @JsonKey(name: 'Items')
  List<SongDTO> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SongsWrapperCopyWith<SongsWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongsWrapperCopyWith<$Res> {
  factory $SongsWrapperCopyWith(
          SongsWrapper value, $Res Function(SongsWrapper) then) =
      _$SongsWrapperCopyWithImpl<$Res, SongsWrapper>;
  @useResult
  $Res call({@JsonKey(name: 'Items') List<SongDTO> items});
}

/// @nodoc
class _$SongsWrapperCopyWithImpl<$Res, $Val extends SongsWrapper>
    implements $SongsWrapperCopyWith<$Res> {
  _$SongsWrapperCopyWithImpl(this._value, this._then);

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
              as List<SongDTO>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SongsWrapperCopyWith<$Res>
    implements $SongsWrapperCopyWith<$Res> {
  factory _$$_SongsWrapperCopyWith(
          _$_SongsWrapper value, $Res Function(_$_SongsWrapper) then) =
      __$$_SongsWrapperCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Items') List<SongDTO> items});
}

/// @nodoc
class __$$_SongsWrapperCopyWithImpl<$Res>
    extends _$SongsWrapperCopyWithImpl<$Res, _$_SongsWrapper>
    implements _$$_SongsWrapperCopyWith<$Res> {
  __$$_SongsWrapperCopyWithImpl(
      _$_SongsWrapper _value, $Res Function(_$_SongsWrapper) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$_SongsWrapper(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SongDTO>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_SongsWrapper implements _SongsWrapper {
  const _$_SongsWrapper(
      {@JsonKey(name: 'Items') required final List<SongDTO> items})
      : _items = items;

  factory _$_SongsWrapper.fromJson(Map<String, dynamic> json) =>
      _$$_SongsWrapperFromJson(json);

  final List<SongDTO> _items;
  @override
  @JsonKey(name: 'Items')
  List<SongDTO> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'SongsWrapper(items: $items)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SongsWrapper &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SongsWrapperCopyWith<_$_SongsWrapper> get copyWith =>
      __$$_SongsWrapperCopyWithImpl<_$_SongsWrapper>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SongsWrapperToJson(
      this,
    );
  }
}

abstract class _SongsWrapper implements SongsWrapper {
  const factory _SongsWrapper(
          {@JsonKey(name: 'Items') required final List<SongDTO> items}) =
      _$_SongsWrapper;

  factory _SongsWrapper.fromJson(Map<String, dynamic> json) =
      _$_SongsWrapper.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<SongDTO> get items;
  @override
  @JsonKey(ignore: true)
  _$$_SongsWrapperCopyWith<_$_SongsWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}
