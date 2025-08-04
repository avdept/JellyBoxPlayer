// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SongDTO {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'RunTimeTicks') int get runTimeTicks;@JsonKey(name: 'IndexNumber') int get indexNumber;@JsonKey(name: 'UserData') SongUserData get songUserData;@JsonKey(name: 'Type') String get type;@JsonKey(name: 'AlbumArtist') String? get albumArtist;@JsonKey(name: 'PlaylistItemId') String? get playlistItemId;@JsonKey(name: 'AlbumArtists') List<ArtistDTO>? get albumArtists;@JsonKey(name: 'Album') String? get albumName;@JsonKey(name: 'AlbumId') String? get albumId;@JsonKey(name: 'Name') String? get name;@JsonKey(name: 'ImageTags') Map<String, String> get imageTags;
/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongDTOCopyWith<SongDTO> get copyWith => _$SongDTOCopyWithImpl<SongDTO>(this as SongDTO, _$identity);

  /// Serializes this SongDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.songUserData, songUserData) || other.songUserData == songUserData)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&const DeepCollectionEquality().equals(other.albumArtists, albumArtists)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.imageTags, imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runTimeTicks,indexNumber,songUserData,type,albumArtist,playlistItemId,const DeepCollectionEquality().hash(albumArtists),albumName,albumId,name,const DeepCollectionEquality().hash(imageTags));

@override
String toString() {
  return 'SongDTO(id: $id, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, songUserData: $songUserData, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumArtists: $albumArtists, albumName: $albumName, albumId: $albumId, name: $name, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class $SongDTOCopyWith<$Res>  {
  factory $SongDTOCopyWith(SongDTO value, $Res Function(SongDTO) _then) = _$SongDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'RunTimeTicks') int runTimeTicks,@JsonKey(name: 'IndexNumber') int indexNumber,@JsonKey(name: 'UserData') SongUserData songUserData,@JsonKey(name: 'Type') String type,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'PlaylistItemId') String? playlistItemId,@JsonKey(name: 'AlbumArtists') List<ArtistDTO>? albumArtists,@JsonKey(name: 'Album') String? albumName,@JsonKey(name: 'AlbumId') String? albumId,@JsonKey(name: 'Name') String? name,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});


$SongUserDataCopyWith<$Res> get songUserData;

}
/// @nodoc
class _$SongDTOCopyWithImpl<$Res>
    implements $SongDTOCopyWith<$Res> {
  _$SongDTOCopyWithImpl(this._self, this._then);

  final SongDTO _self;
  final $Res Function(SongDTO) _then;

/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? runTimeTicks = null,Object? indexNumber = null,Object? songUserData = null,Object? type = null,Object? albumArtist = freezed,Object? playlistItemId = freezed,Object? albumArtists = freezed,Object? albumName = freezed,Object? albumId = freezed,Object? name = freezed,Object? imageTags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runTimeTicks: null == runTimeTicks ? _self.runTimeTicks : runTimeTicks // ignore: cast_nullable_to_non_nullable
as int,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,songUserData: null == songUserData ? _self.songUserData : songUserData // ignore: cast_nullable_to_non_nullable
as SongUserData,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: freezed == albumArtists ? _self.albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self.imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SongUserDataCopyWith<$Res> get songUserData {
  
  return $SongUserDataCopyWith<$Res>(_self.songUserData, (value) {
    return _then(_self.copyWith(songUserData: value));
  });
}
}


/// Adds pattern-matching-related methods to [SongDTO].
extension SongDTOPatterns on SongDTO {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongDTO() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongDTO value)  $default,){
final _that = this;
switch (_that) {
case _SongDTO():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SongDTO() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'UserData')  SongUserData songUserData, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO>? albumArtists, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongDTO() when $default != null:
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumArtists,_that.albumName,_that.albumId,_that.name,_that.imageTags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'UserData')  SongUserData songUserData, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO>? albumArtists, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)  $default,) {final _that = this;
switch (_that) {
case _SongDTO():
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumArtists,_that.albumName,_that.albumId,_that.name,_that.imageTags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'UserData')  SongUserData songUserData, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO>? albumArtists, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,) {final _that = this;
switch (_that) {
case _SongDTO() when $default != null:
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumArtists,_that.albumName,_that.albumId,_that.name,_that.imageTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongDTO implements SongDTO {
  const _SongDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'RunTimeTicks') required this.runTimeTicks, @JsonKey(name: 'IndexNumber') this.indexNumber = 0, @JsonKey(name: 'UserData') required this.songUserData, @JsonKey(name: 'Type') required this.type, @JsonKey(name: 'AlbumArtist') this.albumArtist, @JsonKey(name: 'PlaylistItemId') this.playlistItemId, @JsonKey(name: 'AlbumArtists') final  List<ArtistDTO>? albumArtists, @JsonKey(name: 'Album') this.albumName, @JsonKey(name: 'AlbumId') this.albumId, @JsonKey(name: 'Name') this.name, @JsonKey(name: 'ImageTags') final  Map<String, String> imageTags = const {}}): _albumArtists = albumArtists,_imageTags = imageTags;
  factory _SongDTO.fromJson(Map<String, dynamic> json) => _$SongDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'RunTimeTicks') final  int runTimeTicks;
@override@JsonKey(name: 'IndexNumber') final  int indexNumber;
@override@JsonKey(name: 'UserData') final  SongUserData songUserData;
@override@JsonKey(name: 'Type') final  String type;
@override@JsonKey(name: 'AlbumArtist') final  String? albumArtist;
@override@JsonKey(name: 'PlaylistItemId') final  String? playlistItemId;
 final  List<ArtistDTO>? _albumArtists;
@override@JsonKey(name: 'AlbumArtists') List<ArtistDTO>? get albumArtists {
  final value = _albumArtists;
  if (value == null) return null;
  if (_albumArtists is EqualUnmodifiableListView) return _albumArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'Album') final  String? albumName;
@override@JsonKey(name: 'AlbumId') final  String? albumId;
@override@JsonKey(name: 'Name') final  String? name;
 final  Map<String, String> _imageTags;
@override@JsonKey(name: 'ImageTags') Map<String, String> get imageTags {
  if (_imageTags is EqualUnmodifiableMapView) return _imageTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_imageTags);
}


/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongDTOCopyWith<_SongDTO> get copyWith => __$SongDTOCopyWithImpl<_SongDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.songUserData, songUserData) || other.songUserData == songUserData)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&const DeepCollectionEquality().equals(other._albumArtists, _albumArtists)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runTimeTicks,indexNumber,songUserData,type,albumArtist,playlistItemId,const DeepCollectionEquality().hash(_albumArtists),albumName,albumId,name,const DeepCollectionEquality().hash(_imageTags));

@override
String toString() {
  return 'SongDTO(id: $id, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, songUserData: $songUserData, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumArtists: $albumArtists, albumName: $albumName, albumId: $albumId, name: $name, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class _$SongDTOCopyWith<$Res> implements $SongDTOCopyWith<$Res> {
  factory _$SongDTOCopyWith(_SongDTO value, $Res Function(_SongDTO) _then) = __$SongDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'RunTimeTicks') int runTimeTicks,@JsonKey(name: 'IndexNumber') int indexNumber,@JsonKey(name: 'UserData') SongUserData songUserData,@JsonKey(name: 'Type') String type,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'PlaylistItemId') String? playlistItemId,@JsonKey(name: 'AlbumArtists') List<ArtistDTO>? albumArtists,@JsonKey(name: 'Album') String? albumName,@JsonKey(name: 'AlbumId') String? albumId,@JsonKey(name: 'Name') String? name,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});


@override $SongUserDataCopyWith<$Res> get songUserData;

}
/// @nodoc
class __$SongDTOCopyWithImpl<$Res>
    implements _$SongDTOCopyWith<$Res> {
  __$SongDTOCopyWithImpl(this._self, this._then);

  final _SongDTO _self;
  final $Res Function(_SongDTO) _then;

/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? runTimeTicks = null,Object? indexNumber = null,Object? songUserData = null,Object? type = null,Object? albumArtist = freezed,Object? playlistItemId = freezed,Object? albumArtists = freezed,Object? albumName = freezed,Object? albumId = freezed,Object? name = freezed,Object? imageTags = null,}) {
  return _then(_SongDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runTimeTicks: null == runTimeTicks ? _self.runTimeTicks : runTimeTicks // ignore: cast_nullable_to_non_nullable
as int,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,songUserData: null == songUserData ? _self.songUserData : songUserData // ignore: cast_nullable_to_non_nullable
as SongUserData,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: freezed == albumArtists ? _self._albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self._imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of SongDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SongUserDataCopyWith<$Res> get songUserData {
  
  return $SongUserDataCopyWith<$Res>(_self.songUserData, (value) {
    return _then(_self.copyWith(songUserData: value));
  });
}
}


/// @nodoc
mixin _$SongsWrapper {

@JsonKey(name: 'Items') List<SongDTO> get items;
/// Create a copy of SongsWrapper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongsWrapperCopyWith<SongsWrapper> get copyWith => _$SongsWrapperCopyWithImpl<SongsWrapper>(this as SongsWrapper, _$identity);

  /// Serializes this SongsWrapper to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongsWrapper&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'SongsWrapper(items: $items)';
}


}

/// @nodoc
abstract mixin class $SongsWrapperCopyWith<$Res>  {
  factory $SongsWrapperCopyWith(SongsWrapper value, $Res Function(SongsWrapper) _then) = _$SongsWrapperCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Items') List<SongDTO> items
});




}
/// @nodoc
class _$SongsWrapperCopyWithImpl<$Res>
    implements $SongsWrapperCopyWith<$Res> {
  _$SongsWrapperCopyWithImpl(this._self, this._then);

  final SongsWrapper _self;
  final $Res Function(SongsWrapper) _then;

/// Create a copy of SongsWrapper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SongDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SongsWrapper].
extension SongsWrapperPatterns on SongsWrapper {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongsWrapper value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongsWrapper() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongsWrapper value)  $default,){
final _that = this;
switch (_that) {
case _SongsWrapper():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongsWrapper value)?  $default,){
final _that = this;
switch (_that) {
case _SongsWrapper() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<SongDTO> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongsWrapper() when $default != null:
return $default(_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<SongDTO> items)  $default,) {final _that = this;
switch (_that) {
case _SongsWrapper():
return $default(_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Items')  List<SongDTO> items)?  $default,) {final _that = this;
switch (_that) {
case _SongsWrapper() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongsWrapper implements SongsWrapper {
  const _SongsWrapper({@JsonKey(name: 'Items') required final  List<SongDTO> items}): _items = items;
  factory _SongsWrapper.fromJson(Map<String, dynamic> json) => _$SongsWrapperFromJson(json);

 final  List<SongDTO> _items;
@override@JsonKey(name: 'Items') List<SongDTO> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of SongsWrapper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongsWrapperCopyWith<_SongsWrapper> get copyWith => __$SongsWrapperCopyWithImpl<_SongsWrapper>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongsWrapperToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongsWrapper&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'SongsWrapper(items: $items)';
}


}

/// @nodoc
abstract mixin class _$SongsWrapperCopyWith<$Res> implements $SongsWrapperCopyWith<$Res> {
  factory _$SongsWrapperCopyWith(_SongsWrapper value, $Res Function(_SongsWrapper) _then) = __$SongsWrapperCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Items') List<SongDTO> items
});




}
/// @nodoc
class __$SongsWrapperCopyWithImpl<$Res>
    implements _$SongsWrapperCopyWith<$Res> {
  __$SongsWrapperCopyWithImpl(this._self, this._then);

  final _SongsWrapper _self;
  final $Res Function(_SongsWrapper) _then;

/// Create a copy of SongsWrapper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_SongsWrapper(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SongDTO>,
  ));
}


}


/// @nodoc
mixin _$SongUserData {

@JsonKey(name: 'PlaybackPositionTicks') int get playbackPositionTicks;@JsonKey(name: 'PlayCount') int get playCount;@JsonKey(name: 'IsFavorite') bool get isFavorite;@JsonKey(name: 'Played') bool get played;
/// Create a copy of SongUserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongUserDataCopyWith<SongUserData> get copyWith => _$SongUserDataCopyWithImpl<SongUserData>(this as SongUserData, _$identity);

  /// Serializes this SongUserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongUserData&&(identical(other.playbackPositionTicks, playbackPositionTicks) || other.playbackPositionTicks == playbackPositionTicks)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playbackPositionTicks,playCount,isFavorite,played);

@override
String toString() {
  return 'SongUserData(playbackPositionTicks: $playbackPositionTicks, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class $SongUserDataCopyWith<$Res>  {
  factory $SongUserDataCopyWith(SongUserData value, $Res Function(SongUserData) _then) = _$SongUserDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,@JsonKey(name: 'PlayCount') int playCount,@JsonKey(name: 'IsFavorite') bool isFavorite,@JsonKey(name: 'Played') bool played
});




}
/// @nodoc
class _$SongUserDataCopyWithImpl<$Res>
    implements $SongUserDataCopyWith<$Res> {
  _$SongUserDataCopyWithImpl(this._self, this._then);

  final SongUserData _self;
  final $Res Function(SongUserData) _then;

/// Create a copy of SongUserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackPositionTicks = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_self.copyWith(
playbackPositionTicks: null == playbackPositionTicks ? _self.playbackPositionTicks : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SongUserData].
extension SongUserDataPatterns on SongUserData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongUserData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongUserData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongUserData value)  $default,){
final _that = this;
switch (_that) {
case _SongUserData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongUserData value)?  $default,){
final _that = this;
switch (_that) {
case _SongUserData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongUserData() when $default != null:
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)  $default,) {final _that = this;
switch (_that) {
case _SongUserData():
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)?  $default,) {final _that = this;
switch (_that) {
case _SongUserData() when $default != null:
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongUserData implements SongUserData {
  const _SongUserData({@JsonKey(name: 'PlaybackPositionTicks') required this.playbackPositionTicks, @JsonKey(name: 'PlayCount') required this.playCount, @JsonKey(name: 'IsFavorite') required this.isFavorite, @JsonKey(name: 'Played') required this.played});
  factory _SongUserData.fromJson(Map<String, dynamic> json) => _$SongUserDataFromJson(json);

@override@JsonKey(name: 'PlaybackPositionTicks') final  int playbackPositionTicks;
@override@JsonKey(name: 'PlayCount') final  int playCount;
@override@JsonKey(name: 'IsFavorite') final  bool isFavorite;
@override@JsonKey(name: 'Played') final  bool played;

/// Create a copy of SongUserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongUserDataCopyWith<_SongUserData> get copyWith => __$SongUserDataCopyWithImpl<_SongUserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongUserDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongUserData&&(identical(other.playbackPositionTicks, playbackPositionTicks) || other.playbackPositionTicks == playbackPositionTicks)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playbackPositionTicks,playCount,isFavorite,played);

@override
String toString() {
  return 'SongUserData(playbackPositionTicks: $playbackPositionTicks, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class _$SongUserDataCopyWith<$Res> implements $SongUserDataCopyWith<$Res> {
  factory _$SongUserDataCopyWith(_SongUserData value, $Res Function(_SongUserData) _then) = __$SongUserDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,@JsonKey(name: 'PlayCount') int playCount,@JsonKey(name: 'IsFavorite') bool isFavorite,@JsonKey(name: 'Played') bool played
});




}
/// @nodoc
class __$SongUserDataCopyWithImpl<$Res>
    implements _$SongUserDataCopyWith<$Res> {
  __$SongUserDataCopyWithImpl(this._self, this._then);

  final _SongUserData _self;
  final $Res Function(_SongUserData) _then;

/// Create a copy of SongUserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackPositionTicks = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_SongUserData(
playbackPositionTicks: null == playbackPositionTicks ? _self.playbackPositionTicks : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DownloadedSongDTO {

 SongUserData get songUserData; Map<String, String> get imageTags; DateTime get downloadDate; String get id; int get runTimeTicks; int get indexNumber; String get type; String? get albumArtist; String? get playlistItemId;// @Default([]) List<ArtistDTO> albumArtists,
 String? get albumName; String? get albumId; String? get name;@JsonKey(name: 'FilePath') String get filePath;@JsonKey(name: 'SizeInBytes') int get sizeInBytes;

  /// Serializes this DownloadedSongDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedSongDTO&&(identical(other.songUserData, songUserData) || other.songUserData == songUserData)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.id, id) || other.id == id)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,songUserData,const DeepCollectionEquality().hash(imageTags),downloadDate,id,runTimeTicks,indexNumber,type,albumArtist,playlistItemId,albumName,albumId,name,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedSongDTO(songUserData: $songUserData, imageTags: $imageTags, downloadDate: $downloadDate, id: $id, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumName: $albumName, albumId: $albumId, name: $name, filePath: $filePath, sizeInBytes: $sizeInBytes)';
}


}




/// Adds pattern-matching-related methods to [DownloadedSongDTO].
extension DownloadedSongDTOPatterns on DownloadedSongDTO {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedSongDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedSongDTO value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedSongDTO():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedSongDTO value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int runTimeTicks,  int indexNumber,  SongUserData songUserData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  String? name,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.name,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int runTimeTicks,  int indexNumber,  SongUserData songUserData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  String? name,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedSongDTO():
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.name,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int runTimeTicks,  int indexNumber,  SongUserData songUserData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  String? name,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that.id,_that.runTimeTicks,_that.indexNumber,_that.songUserData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.name,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedSongDTO extends DownloadedSongDTO {
   _DownloadedSongDTO({required final  String id, required final  int runTimeTicks, final  int indexNumber = 0, required final  SongUserData songUserData, required final  String type, final  String? albumArtist, final  String? playlistItemId, final  String? albumName, final  String? albumId, final  String? name, final  Map<String, String> imageTags = const {}, final  DateTime? downloadDate, @JsonKey(name: 'FilePath') required this.filePath, @JsonKey(name: 'SizeInBytes') required this.sizeInBytes}): super._(id: id, runTimeTicks: runTimeTicks, indexNumber: indexNumber, type: type, albumArtist: albumArtist, playlistItemId: playlistItemId, albumName: albumName, albumId: albumId, name: name, songUserData: songUserData, imageTags: imageTags, downloadDate: downloadDate);
  factory _DownloadedSongDTO.fromJson(Map<String, dynamic> json) => _$DownloadedSongDTOFromJson(json);

@override@JsonKey(name: 'FilePath') final  String filePath;
@override@JsonKey(name: 'SizeInBytes') final  int sizeInBytes;


@override
Map<String, dynamic> toJson() {
  return _$DownloadedSongDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedSongDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.songUserData, songUserData) || other.songUserData == songUserData)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runTimeTicks,indexNumber,songUserData,type,albumArtist,playlistItemId,albumName,albumId,name,const DeepCollectionEquality().hash(_imageTags),downloadDate,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedSongDTO(id: $id, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, songUserData: $songUserData, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumName: $albumName, albumId: $albumId, name: $name, imageTags: $imageTags, downloadDate: $downloadDate, filePath: $filePath, sizeInBytes: $sizeInBytes)';
}


}




// dart format on
