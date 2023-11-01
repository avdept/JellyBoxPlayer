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
  @JsonKey(name: 'RunTimeTicks')
  int get runTimeTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'IndexNumber')
  int get indexNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'UserData')
  SongUserData get songUserData => throw _privateConstructorUsedError;
  @JsonKey(name: 'Type')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'Album')
  String? get albumName => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String? get name => throw _privateConstructorUsedError;
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
      @JsonKey(name: 'RunTimeTicks') int runTimeTicks,
      @JsonKey(name: 'IndexNumber') int indexNumber,
      @JsonKey(name: 'UserData') SongUserData songUserData,
      @JsonKey(name: 'Type') String type,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'Album') String? albumName,
      @JsonKey(name: 'Name') String? name,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});

  $SongUserDataCopyWith<$Res> get songUserData;
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
    Object? runTimeTicks = null,
    Object? indexNumber = null,
    Object? songUserData = null,
    Object? type = null,
    Object? albumArtist = freezed,
    Object? albumName = freezed,
    Object? name = freezed,
    Object? imageTags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      runTimeTicks: null == runTimeTicks
          ? _value.runTimeTicks
          : runTimeTicks // ignore: cast_nullable_to_non_nullable
              as int,
      indexNumber: null == indexNumber
          ? _value.indexNumber
          : indexNumber // ignore: cast_nullable_to_non_nullable
              as int,
      songUserData: null == songUserData
          ? _value.songUserData
          : songUserData // ignore: cast_nullable_to_non_nullable
              as SongUserData,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      albumName: freezed == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      imageTags: null == imageTags
          ? _value.imageTags
          : imageTags // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SongUserDataCopyWith<$Res> get songUserData {
    return $SongUserDataCopyWith<$Res>(_value.songUserData, (value) {
      return _then(_value.copyWith(songUserData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SongDTOImplCopyWith<$Res> implements $SongDTOCopyWith<$Res> {
  factory _$$SongDTOImplCopyWith(
          _$SongDTOImpl value, $Res Function(_$SongDTOImpl) then) =
      __$$SongDTOImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Id') String id,
      @JsonKey(name: 'RunTimeTicks') int runTimeTicks,
      @JsonKey(name: 'IndexNumber') int indexNumber,
      @JsonKey(name: 'UserData') SongUserData songUserData,
      @JsonKey(name: 'Type') String type,
      @JsonKey(name: 'AlbumArtist') String? albumArtist,
      @JsonKey(name: 'Album') String? albumName,
      @JsonKey(name: 'Name') String? name,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});

  @override
  $SongUserDataCopyWith<$Res> get songUserData;
}

/// @nodoc
class __$$SongDTOImplCopyWithImpl<$Res>
    extends _$SongDTOCopyWithImpl<$Res, _$SongDTOImpl>
    implements _$$SongDTOImplCopyWith<$Res> {
  __$$SongDTOImplCopyWithImpl(
      _$SongDTOImpl _value, $Res Function(_$SongDTOImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? runTimeTicks = null,
    Object? indexNumber = null,
    Object? songUserData = null,
    Object? type = null,
    Object? albumArtist = freezed,
    Object? albumName = freezed,
    Object? name = freezed,
    Object? imageTags = null,
  }) {
    return _then(_$SongDTOImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      runTimeTicks: null == runTimeTicks
          ? _value.runTimeTicks
          : runTimeTicks // ignore: cast_nullable_to_non_nullable
              as int,
      indexNumber: null == indexNumber
          ? _value.indexNumber
          : indexNumber // ignore: cast_nullable_to_non_nullable
              as int,
      songUserData: null == songUserData
          ? _value.songUserData
          : songUserData // ignore: cast_nullable_to_non_nullable
              as SongUserData,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      albumArtist: freezed == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String?,
      albumName: freezed == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
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
class _$SongDTOImpl implements _SongDTO {
  const _$SongDTOImpl(
      {@JsonKey(name: 'Id') required this.id,
      @JsonKey(name: 'RunTimeTicks') required this.runTimeTicks,
      @JsonKey(name: 'IndexNumber') required this.indexNumber,
      @JsonKey(name: 'UserData') required this.songUserData,
      @JsonKey(name: 'Type') required this.type,
      @JsonKey(name: 'AlbumArtist') this.albumArtist,
      @JsonKey(name: 'Album') this.albumName,
      @JsonKey(name: 'Name') this.name,
      @JsonKey(name: 'ImageTags')
      final Map<String, String> imageTags = const {}})
      : _imageTags = imageTags;

  factory _$SongDTOImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongDTOImplFromJson(json);

  @override
  @JsonKey(name: 'Id')
  final String id;
  @override
  @JsonKey(name: 'RunTimeTicks')
  final int runTimeTicks;
  @override
  @JsonKey(name: 'IndexNumber')
  final int indexNumber;
  @override
  @JsonKey(name: 'UserData')
  final SongUserData songUserData;
  @override
  @JsonKey(name: 'Type')
  final String type;
  @override
  @JsonKey(name: 'AlbumArtist')
  final String? albumArtist;
  @override
  @JsonKey(name: 'Album')
  final String? albumName;
  @override
  @JsonKey(name: 'Name')
  final String? name;
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
    return 'SongDTO(id: $id, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, songUserData: $songUserData, type: $type, albumArtist: $albumArtist, albumName: $albumName, name: $name, imageTags: $imageTags)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongDTOImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.runTimeTicks, runTimeTicks) ||
                other.runTimeTicks == runTimeTicks) &&
            (identical(other.indexNumber, indexNumber) ||
                other.indexNumber == indexNumber) &&
            (identical(other.songUserData, songUserData) ||
                other.songUserData == songUserData) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            (identical(other.albumName, albumName) ||
                other.albumName == albumName) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._imageTags, _imageTags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      runTimeTicks,
      indexNumber,
      songUserData,
      type,
      albumArtist,
      albumName,
      name,
      const DeepCollectionEquality().hash(_imageTags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SongDTOImplCopyWith<_$SongDTOImpl> get copyWith =>
      __$$SongDTOImplCopyWithImpl<_$SongDTOImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongDTOImplToJson(
      this,
    );
  }
}

abstract class _SongDTO implements SongDTO {
  const factory _SongDTO(
          {@JsonKey(name: 'Id') required final String id,
          @JsonKey(name: 'RunTimeTicks') required final int runTimeTicks,
          @JsonKey(name: 'IndexNumber') required final int indexNumber,
          @JsonKey(name: 'UserData') required final SongUserData songUserData,
          @JsonKey(name: 'Type') required final String type,
          @JsonKey(name: 'AlbumArtist') final String? albumArtist,
          @JsonKey(name: 'Album') final String? albumName,
          @JsonKey(name: 'Name') final String? name,
          @JsonKey(name: 'ImageTags') final Map<String, String> imageTags}) =
      _$SongDTOImpl;

  factory _SongDTO.fromJson(Map<String, dynamic> json) = _$SongDTOImpl.fromJson;

  @override
  @JsonKey(name: 'Id')
  String get id;
  @override
  @JsonKey(name: 'RunTimeTicks')
  int get runTimeTicks;
  @override
  @JsonKey(name: 'IndexNumber')
  int get indexNumber;
  @override
  @JsonKey(name: 'UserData')
  SongUserData get songUserData;
  @override
  @JsonKey(name: 'Type')
  String get type;
  @override
  @JsonKey(name: 'AlbumArtist')
  String? get albumArtist;
  @override
  @JsonKey(name: 'Album')
  String? get albumName;
  @override
  @JsonKey(name: 'Name')
  String? get name;
  @override
  @JsonKey(name: 'ImageTags')
  Map<String, String> get imageTags;
  @override
  @JsonKey(ignore: true)
  _$$SongDTOImplCopyWith<_$SongDTOImpl> get copyWith =>
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
abstract class _$$SongsWrapperImplCopyWith<$Res>
    implements $SongsWrapperCopyWith<$Res> {
  factory _$$SongsWrapperImplCopyWith(
          _$SongsWrapperImpl value, $Res Function(_$SongsWrapperImpl) then) =
      __$$SongsWrapperImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Items') List<SongDTO> items});
}

/// @nodoc
class __$$SongsWrapperImplCopyWithImpl<$Res>
    extends _$SongsWrapperCopyWithImpl<$Res, _$SongsWrapperImpl>
    implements _$$SongsWrapperImplCopyWith<$Res> {
  __$$SongsWrapperImplCopyWithImpl(
      _$SongsWrapperImpl _value, $Res Function(_$SongsWrapperImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$SongsWrapperImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SongDTO>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SongsWrapperImpl implements _SongsWrapper {
  const _$SongsWrapperImpl(
      {@JsonKey(name: 'Items') required final List<SongDTO> items})
      : _items = items;

  factory _$SongsWrapperImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongsWrapperImplFromJson(json);

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
            other is _$SongsWrapperImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SongsWrapperImplCopyWith<_$SongsWrapperImpl> get copyWith =>
      __$$SongsWrapperImplCopyWithImpl<_$SongsWrapperImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongsWrapperImplToJson(
      this,
    );
  }
}

abstract class _SongsWrapper implements SongsWrapper {
  const factory _SongsWrapper(
          {@JsonKey(name: 'Items') required final List<SongDTO> items}) =
      _$SongsWrapperImpl;

  factory _SongsWrapper.fromJson(Map<String, dynamic> json) =
      _$SongsWrapperImpl.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<SongDTO> get items;
  @override
  @JsonKey(ignore: true)
  _$$SongsWrapperImplCopyWith<_$SongsWrapperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SongUserData _$SongUserDataFromJson(Map<String, dynamic> json) {
  return _SongUserData.fromJson(json);
}

/// @nodoc
mixin _$SongUserData {
  @JsonKey(name: 'PlaybackPositionTicks')
  int get playbackPositionTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'PlayCount')
  int get playCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'IsFavorite')
  bool get isFavorite => throw _privateConstructorUsedError;
  @JsonKey(name: 'Played')
  bool get played => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SongUserDataCopyWith<SongUserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongUserDataCopyWith<$Res> {
  factory $SongUserDataCopyWith(
          SongUserData value, $Res Function(SongUserData) then) =
      _$SongUserDataCopyWithImpl<$Res, SongUserData>;
  @useResult
  $Res call(
      {@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,
      @JsonKey(name: 'PlayCount') int playCount,
      @JsonKey(name: 'IsFavorite') bool isFavorite,
      @JsonKey(name: 'Played') bool played});
}

/// @nodoc
class _$SongUserDataCopyWithImpl<$Res, $Val extends SongUserData>
    implements $SongUserDataCopyWith<$Res> {
  _$SongUserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playbackPositionTicks = null,
    Object? playCount = null,
    Object? isFavorite = null,
    Object? played = null,
  }) {
    return _then(_value.copyWith(
      playbackPositionTicks: null == playbackPositionTicks
          ? _value.playbackPositionTicks
          : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
              as int,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      played: null == played
          ? _value.played
          : played // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SongUserDataImplCopyWith<$Res>
    implements $SongUserDataCopyWith<$Res> {
  factory _$$SongUserDataImplCopyWith(
          _$SongUserDataImpl value, $Res Function(_$SongUserDataImpl) then) =
      __$$SongUserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,
      @JsonKey(name: 'PlayCount') int playCount,
      @JsonKey(name: 'IsFavorite') bool isFavorite,
      @JsonKey(name: 'Played') bool played});
}

/// @nodoc
class __$$SongUserDataImplCopyWithImpl<$Res>
    extends _$SongUserDataCopyWithImpl<$Res, _$SongUserDataImpl>
    implements _$$SongUserDataImplCopyWith<$Res> {
  __$$SongUserDataImplCopyWithImpl(
      _$SongUserDataImpl _value, $Res Function(_$SongUserDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playbackPositionTicks = null,
    Object? playCount = null,
    Object? isFavorite = null,
    Object? played = null,
  }) {
    return _then(_$SongUserDataImpl(
      playbackPositionTicks: null == playbackPositionTicks
          ? _value.playbackPositionTicks
          : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
              as int,
      playCount: null == playCount
          ? _value.playCount
          : playCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      played: null == played
          ? _value.played
          : played // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SongUserDataImpl implements _SongUserData {
  const _$SongUserDataImpl(
      {@JsonKey(name: 'PlaybackPositionTicks')
      required this.playbackPositionTicks,
      @JsonKey(name: 'PlayCount') required this.playCount,
      @JsonKey(name: 'IsFavorite') required this.isFavorite,
      @JsonKey(name: 'Played') required this.played});

  factory _$SongUserDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongUserDataImplFromJson(json);

  @override
  @JsonKey(name: 'PlaybackPositionTicks')
  final int playbackPositionTicks;
  @override
  @JsonKey(name: 'PlayCount')
  final int playCount;
  @override
  @JsonKey(name: 'IsFavorite')
  final bool isFavorite;
  @override
  @JsonKey(name: 'Played')
  final bool played;

  @override
  String toString() {
    return 'SongUserData(playbackPositionTicks: $playbackPositionTicks, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongUserDataImpl &&
            (identical(other.playbackPositionTicks, playbackPositionTicks) ||
                other.playbackPositionTicks == playbackPositionTicks) &&
            (identical(other.playCount, playCount) ||
                other.playCount == playCount) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.played, played) || other.played == played));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, playbackPositionTicks, playCount, isFavorite, played);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SongUserDataImplCopyWith<_$SongUserDataImpl> get copyWith =>
      __$$SongUserDataImplCopyWithImpl<_$SongUserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongUserDataImplToJson(
      this,
    );
  }
}

abstract class _SongUserData implements SongUserData {
  const factory _SongUserData(
          {@JsonKey(name: 'PlaybackPositionTicks')
          required final int playbackPositionTicks,
          @JsonKey(name: 'PlayCount') required final int playCount,
          @JsonKey(name: 'IsFavorite') required final bool isFavorite,
          @JsonKey(name: 'Played') required final bool played}) =
      _$SongUserDataImpl;

  factory _SongUserData.fromJson(Map<String, dynamic> json) =
      _$SongUserDataImpl.fromJson;

  @override
  @JsonKey(name: 'PlaybackPositionTicks')
  int get playbackPositionTicks;
  @override
  @JsonKey(name: 'PlayCount')
  int get playCount;
  @override
  @JsonKey(name: 'IsFavorite')
  bool get isFavorite;
  @override
  @JsonKey(name: 'Played')
  bool get played;
  @override
  @JsonKey(ignore: true)
  _$$SongUserDataImplCopyWith<_$SongUserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
