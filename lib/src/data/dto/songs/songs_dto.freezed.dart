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
  @JsonKey(name: 'RunTimeTicks')
  int get runTimeTicks => throw _privateConstructorUsedError;
  @JsonKey(name: 'IndexNumber')
  int get indexNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist => throw _privateConstructorUsedError;
  @JsonKey(name: 'UserData')
  SongUserData get songUserData => throw _privateConstructorUsedError;
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
      @JsonKey(name: 'RunTimeTicks') int runTimeTicks,
      @JsonKey(name: 'IndexNumber') int indexNumber,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'UserData') SongUserData songUserData,
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
    Object? name = null,
    Object? albumName = null,
    Object? runTimeTicks = null,
    Object? indexNumber = null,
    Object? albumArtist = null,
    Object? songUserData = null,
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
      runTimeTicks: null == runTimeTicks
          ? _value.runTimeTicks
          : runTimeTicks // ignore: cast_nullable_to_non_nullable
              as int,
      indexNumber: null == indexNumber
          ? _value.indexNumber
          : indexNumber // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtist: null == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String,
      songUserData: null == songUserData
          ? _value.songUserData
          : songUserData // ignore: cast_nullable_to_non_nullable
              as SongUserData,
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
      @JsonKey(name: 'RunTimeTicks') int runTimeTicks,
      @JsonKey(name: 'IndexNumber') int indexNumber,
      @JsonKey(name: 'AlbumArtist') String albumArtist,
      @JsonKey(name: 'UserData') SongUserData songUserData,
      @JsonKey(name: 'ImageTags') Map<String, String> imageTags});

  @override
  $SongUserDataCopyWith<$Res> get songUserData;
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
    Object? runTimeTicks = null,
    Object? indexNumber = null,
    Object? albumArtist = null,
    Object? songUserData = null,
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
      runTimeTicks: null == runTimeTicks
          ? _value.runTimeTicks
          : runTimeTicks // ignore: cast_nullable_to_non_nullable
              as int,
      indexNumber: null == indexNumber
          ? _value.indexNumber
          : indexNumber // ignore: cast_nullable_to_non_nullable
              as int,
      albumArtist: null == albumArtist
          ? _value.albumArtist
          : albumArtist // ignore: cast_nullable_to_non_nullable
              as String,
      songUserData: null == songUserData
          ? _value.songUserData
          : songUserData // ignore: cast_nullable_to_non_nullable
              as SongUserData,
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
      @JsonKey(name: 'RunTimeTicks') required this.runTimeTicks,
      @JsonKey(name: 'IndexNumber') required this.indexNumber,
      @JsonKey(name: 'AlbumArtist') required this.albumArtist,
      @JsonKey(name: 'UserData') required this.songUserData,
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
  @JsonKey(name: 'RunTimeTicks')
  final int runTimeTicks;
  @override
  @JsonKey(name: 'IndexNumber')
  final int indexNumber;
  @override
  @JsonKey(name: 'AlbumArtist')
  final String albumArtist;
  @override
  @JsonKey(name: 'UserData')
  final SongUserData songUserData;
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
    return 'SongDTO(id: $id, name: $name, albumName: $albumName, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, albumArtist: $albumArtist, songUserData: $songUserData, imageTags: $imageTags)';
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
            (identical(other.runTimeTicks, runTimeTicks) ||
                other.runTimeTicks == runTimeTicks) &&
            (identical(other.indexNumber, indexNumber) ||
                other.indexNumber == indexNumber) &&
            (identical(other.albumArtist, albumArtist) ||
                other.albumArtist == albumArtist) &&
            (identical(other.songUserData, songUserData) ||
                other.songUserData == songUserData) &&
            const DeepCollectionEquality()
                .equals(other._imageTags, _imageTags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      albumName,
      runTimeTicks,
      indexNumber,
      albumArtist,
      songUserData,
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
          @JsonKey(name: 'RunTimeTicks') required final int runTimeTicks,
          @JsonKey(name: 'IndexNumber') required final int indexNumber,
          @JsonKey(name: 'AlbumArtist') required final String albumArtist,
          @JsonKey(name: 'UserData') required final SongUserData songUserData,
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
  @JsonKey(name: 'RunTimeTicks')
  int get runTimeTicks;
  @override
  @JsonKey(name: 'IndexNumber')
  int get indexNumber;
  @override
  @JsonKey(name: 'AlbumArtist')
  String get albumArtist;
  @override
  @JsonKey(name: 'UserData')
  SongUserData get songUserData;
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
abstract class _$$_SongUserDataCopyWith<$Res>
    implements $SongUserDataCopyWith<$Res> {
  factory _$$_SongUserDataCopyWith(
          _$_SongUserData value, $Res Function(_$_SongUserData) then) =
      __$$_SongUserDataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,
      @JsonKey(name: 'PlayCount') int playCount,
      @JsonKey(name: 'IsFavorite') bool isFavorite,
      @JsonKey(name: 'Played') bool played});
}

/// @nodoc
class __$$_SongUserDataCopyWithImpl<$Res>
    extends _$SongUserDataCopyWithImpl<$Res, _$_SongUserData>
    implements _$$_SongUserDataCopyWith<$Res> {
  __$$_SongUserDataCopyWithImpl(
      _$_SongUserData _value, $Res Function(_$_SongUserData) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playbackPositionTicks = null,
    Object? playCount = null,
    Object? isFavorite = null,
    Object? played = null,
  }) {
    return _then(_$_SongUserData(
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
class _$_SongUserData implements _SongUserData {
  const _$_SongUserData(
      {@JsonKey(name: 'PlaybackPositionTicks')
      required this.playbackPositionTicks,
      @JsonKey(name: 'PlayCount') required this.playCount,
      @JsonKey(name: 'IsFavorite') required this.isFavorite,
      @JsonKey(name: 'Played') required this.played});

  factory _$_SongUserData.fromJson(Map<String, dynamic> json) =>
      _$$_SongUserDataFromJson(json);

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
            other is _$_SongUserData &&
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
  _$$_SongUserDataCopyWith<_$_SongUserData> get copyWith =>
      __$$_SongUserDataCopyWithImpl<_$_SongUserData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SongUserDataToJson(
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
      @JsonKey(name: 'Played') required final bool played}) = _$_SongUserData;

  factory _SongUserData.fromJson(Map<String, dynamic> json) =
      _$_SongUserData.fromJson;

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
  _$$_SongUserDataCopyWith<_$_SongUserData> get copyWith =>
      throw _privateConstructorUsedError;
}
