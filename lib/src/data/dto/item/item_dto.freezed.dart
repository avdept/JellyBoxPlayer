// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemDTO {

<<<<<<< HEAD
@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Name') String get name;@JsonKey(name: 'Type') String get type;@JsonKey(name: 'IndexNumber') int get indexNumber;@JsonKey(name: 'RunTimeTicks') int get runTimeTicks;@JsonKey(name: 'Path') String? get path;@JsonKey(name: 'CollectionType') String? get collectionType;@JsonKey(name: 'PlaylistItemId') String? get playlistItemId;@JsonKey(name: 'Overview') String? get overview;@JsonKey(name: 'ProductionYear') int? get productionYear;@JsonKey(name: 'AlbumId') String? get albumId;@JsonKey(name: 'Album') String? get albumName;@JsonKey(name: 'AlbumArtist') String? get albumArtist;@JsonKey(name: 'AlbumArtists') List<ArtistDTO> get albumArtists;@JsonKey(name: 'BackdropImageTags') List<String> get backdropImageTags;@JsonKey(name: 'ImageTags') Map<String, String> get imageTags;@JsonKey(name: 'UserData') UserData get userData;@JsonKey(name: 'MediaSources') List<MediaSourceDTO> get mediaSources;
=======
@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Name') String get name;@JsonKey(name: 'Type') String get type;@JsonKey(name: 'IndexNumber') int get indexNumber;@JsonKey(name: 'RunTimeTicks') int get runTimeTicks;@JsonKey(name: 'Path') String? get path;@JsonKey(name: 'CollectionType') String? get collectionType;@JsonKey(name: 'PlaylistItemId') String? get playlistItemId;@JsonKey(name: 'Overview') String? get overview;@JsonKey(name: 'ProductionYear') int? get productionYear;// @JsonKey(name: 'ArtistItems') @Default([]) List<ArtistDTO> artists,
@JsonKey(name: 'AlbumId') String? get albumId;@JsonKey(name: 'Album') String? get albumName;@JsonKey(name: 'AlbumArtist') String? get albumArtist;@JsonKey(name: 'AlbumArtists') List<ArtistDTO> get albumArtists;@JsonKey(name: 'BackdropImageTags') List<String> get backdropImageTags;@JsonKey(name: 'ImageTags') Map<String, String> get imageTags;@JsonKey(name: 'UserData') UserData get userData;
>>>>>>> e5a6e12 (Fix bottom player and ArtistPage layout, don't set initial window bounds manually for MacOS and Windows)
/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<ItemDTO> get copyWith => _$ItemDTOCopyWithImpl<ItemDTO>(this as ItemDTO, _$identity);

  /// Serializes this ItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.path, path) || other.path == path)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other.albumArtists, albumArtists)&&const DeepCollectionEquality().equals(other.backdropImageTags, backdropImageTags)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.userData, userData) || other.userData == userData)&&const DeepCollectionEquality().equals(other.mediaSources, mediaSources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,indexNumber,runTimeTicks,path,collectionType,playlistItemId,overview,productionYear,albumId,albumName,albumArtist,const DeepCollectionEquality().hash(albumArtists),const DeepCollectionEquality().hash(backdropImageTags),const DeepCollectionEquality().hash(imageTags),userData,const DeepCollectionEquality().hash(mediaSources));

@override
String toString() {
  return 'ItemDTO(id: $id, name: $name, type: $type, indexNumber: $indexNumber, runTimeTicks: $runTimeTicks, path: $path, collectionType: $collectionType, playlistItemId: $playlistItemId, overview: $overview, productionYear: $productionYear, albumId: $albumId, albumName: $albumName, albumArtist: $albumArtist, albumArtists: $albumArtists, backdropImageTags: $backdropImageTags, imageTags: $imageTags, userData: $userData, mediaSources: $mediaSources)';
}


}

/// @nodoc
abstract mixin class $ItemDTOCopyWith<$Res>  {
  factory $ItemDTOCopyWith(ItemDTO value, $Res Function(ItemDTO) _then) = _$ItemDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name,@JsonKey(name: 'Type') String type,@JsonKey(name: 'IndexNumber') int indexNumber,@JsonKey(name: 'RunTimeTicks') int runTimeTicks,@JsonKey(name: 'Path') String? path,@JsonKey(name: 'CollectionType') String? collectionType,@JsonKey(name: 'PlaylistItemId') String? playlistItemId,@JsonKey(name: 'Overview') String? overview,@JsonKey(name: 'ProductionYear') int? productionYear,@JsonKey(name: 'AlbumId') String? albumId,@JsonKey(name: 'Album') String? albumName,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'AlbumArtists') List<ArtistDTO> albumArtists,@JsonKey(name: 'BackdropImageTags') List<String> backdropImageTags,@JsonKey(name: 'ImageTags') Map<String, String> imageTags,@JsonKey(name: 'UserData') UserData userData,@JsonKey(name: 'MediaSources') List<MediaSourceDTO> mediaSources
});


$UserDataCopyWith<$Res> get userData;

}
/// @nodoc
class _$ItemDTOCopyWithImpl<$Res>
    implements $ItemDTOCopyWith<$Res> {
  _$ItemDTOCopyWithImpl(this._self, this._then);

  final ItemDTO _self;
  final $Res Function(ItemDTO) _then;

/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? indexNumber = null,Object? runTimeTicks = null,Object? path = freezed,Object? collectionType = freezed,Object? playlistItemId = freezed,Object? overview = freezed,Object? productionYear = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? backdropImageTags = null,Object? imageTags = null,Object? userData = null,Object? mediaSources = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,runTimeTicks: null == runTimeTicks ? _self.runTimeTicks : runTimeTicks // ignore: cast_nullable_to_non_nullable
as int,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self.albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>,backdropImageTags: null == backdropImageTags ? _self.backdropImageTags : backdropImageTags // ignore: cast_nullable_to_non_nullable
as List<String>,imageTags: null == imageTags ? _self.imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,userData: null == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as UserData,mediaSources: null == mediaSources ? _self.mediaSources : mediaSources // ignore: cast_nullable_to_non_nullable
as List<MediaSourceDTO>,
  ));
}
/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res> get userData {
  
  return $UserDataCopyWith<$Res>(_self.userData, (value) {
    return _then(_self.copyWith(userData: value));
  });
}
}


/// Adds pattern-matching-related methods to [ItemDTO].
extension ItemDTOPatterns on ItemDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemDTO value)  $default,){
final _that = this;
switch (_that) {
case _ItemDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemDTO value)?  $default,){
final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags, @JsonKey(name: 'UserData')  UserData userData, @JsonKey(name: 'MediaSources')  List<MediaSourceDTO> mediaSources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.indexNumber,_that.runTimeTicks,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags,_that.userData,_that.mediaSources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags, @JsonKey(name: 'UserData')  UserData userData, @JsonKey(name: 'MediaSources')  List<MediaSourceDTO> mediaSources)  $default,) {final _that = this;
switch (_that) {
case _ItemDTO():
return $default(_that.id,_that.name,_that.type,_that.indexNumber,_that.runTimeTicks,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags,_that.userData,_that.mediaSources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'IndexNumber')  int indexNumber, @JsonKey(name: 'RunTimeTicks')  int runTimeTicks, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'PlaylistItemId')  String? playlistItemId, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumId')  String? albumId, @JsonKey(name: 'Album')  String? albumName, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags, @JsonKey(name: 'UserData')  UserData userData, @JsonKey(name: 'MediaSources')  List<MediaSourceDTO> mediaSources)?  $default,) {final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.indexNumber,_that.runTimeTicks,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags,_that.userData,_that.mediaSources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemDTO extends ItemDTO {
  const _ItemDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'Name') required this.name, @JsonKey(name: 'Type') required this.type, @JsonKey(name: 'IndexNumber') this.indexNumber = 0, @JsonKey(name: 'RunTimeTicks') this.runTimeTicks = 0, @JsonKey(name: 'Path') this.path, @JsonKey(name: 'CollectionType') this.collectionType, @JsonKey(name: 'PlaylistItemId') this.playlistItemId, @JsonKey(name: 'Overview') this.overview, @JsonKey(name: 'ProductionYear') this.productionYear, @JsonKey(name: 'AlbumId') this.albumId, @JsonKey(name: 'Album') this.albumName, @JsonKey(name: 'AlbumArtist') this.albumArtist, @JsonKey(name: 'AlbumArtists') final  List<ArtistDTO> albumArtists = const [], @JsonKey(name: 'BackdropImageTags') final  List<String> backdropImageTags = const [], @JsonKey(name: 'ImageTags') final  Map<String, String> imageTags = const {}, @JsonKey(name: 'UserData') this.userData = const UserData(), @JsonKey(name: 'MediaSources') final  List<MediaSourceDTO> mediaSources = const []}): _albumArtists = albumArtists,_backdropImageTags = backdropImageTags,_imageTags = imageTags,_mediaSources = mediaSources,super._();
  factory _ItemDTO.fromJson(Map<String, dynamic> json) => _$ItemDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'Name') final  String name;
@override@JsonKey(name: 'Type') final  String type;
@override@JsonKey(name: 'IndexNumber') final  int indexNumber;
@override@JsonKey(name: 'RunTimeTicks') final  int runTimeTicks;
@override@JsonKey(name: 'Path') final  String? path;
@override@JsonKey(name: 'CollectionType') final  String? collectionType;
@override@JsonKey(name: 'PlaylistItemId') final  String? playlistItemId;
@override@JsonKey(name: 'Overview') final  String? overview;
@override@JsonKey(name: 'ProductionYear') final  int? productionYear;
// @JsonKey(name: 'ArtistItems') @Default([]) List<ArtistDTO> artists,
@override@JsonKey(name: 'AlbumId') final  String? albumId;
@override@JsonKey(name: 'Album') final  String? albumName;
@override@JsonKey(name: 'AlbumArtist') final  String? albumArtist;
 final  List<ArtistDTO> _albumArtists;
@override@JsonKey(name: 'AlbumArtists') List<ArtistDTO> get albumArtists {
  if (_albumArtists is EqualUnmodifiableListView) return _albumArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albumArtists);
}

 final  List<String> _backdropImageTags;
@override@JsonKey(name: 'BackdropImageTags') List<String> get backdropImageTags {
  if (_backdropImageTags is EqualUnmodifiableListView) return _backdropImageTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backdropImageTags);
}

 final  Map<String, String> _imageTags;
@override@JsonKey(name: 'ImageTags') Map<String, String> get imageTags {
  if (_imageTags is EqualUnmodifiableMapView) return _imageTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_imageTags);
}

@override@JsonKey(name: 'UserData') final  UserData userData;
 final  List<MediaSourceDTO> _mediaSources;
@override@JsonKey(name: 'MediaSources') List<MediaSourceDTO> get mediaSources {
  if (_mediaSources is EqualUnmodifiableListView) return _mediaSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaSources);
}


/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemDTOCopyWith<_ItemDTO> get copyWith => __$ItemDTOCopyWithImpl<_ItemDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.path, path) || other.path == path)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other._albumArtists, _albumArtists)&&const DeepCollectionEquality().equals(other._backdropImageTags, _backdropImageTags)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.userData, userData) || other.userData == userData)&&const DeepCollectionEquality().equals(other._mediaSources, _mediaSources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,indexNumber,runTimeTicks,path,collectionType,playlistItemId,overview,productionYear,albumId,albumName,albumArtist,const DeepCollectionEquality().hash(_albumArtists),const DeepCollectionEquality().hash(_backdropImageTags),const DeepCollectionEquality().hash(_imageTags),userData,const DeepCollectionEquality().hash(_mediaSources));

@override
String toString() {
  return 'ItemDTO(id: $id, name: $name, type: $type, indexNumber: $indexNumber, runTimeTicks: $runTimeTicks, path: $path, collectionType: $collectionType, playlistItemId: $playlistItemId, overview: $overview, productionYear: $productionYear, albumId: $albumId, albumName: $albumName, albumArtist: $albumArtist, albumArtists: $albumArtists, backdropImageTags: $backdropImageTags, imageTags: $imageTags, userData: $userData, mediaSources: $mediaSources)';
}


}

/// @nodoc
abstract mixin class _$ItemDTOCopyWith<$Res> implements $ItemDTOCopyWith<$Res> {
  factory _$ItemDTOCopyWith(_ItemDTO value, $Res Function(_ItemDTO) _then) = __$ItemDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name,@JsonKey(name: 'Type') String type,@JsonKey(name: 'IndexNumber') int indexNumber,@JsonKey(name: 'RunTimeTicks') int runTimeTicks,@JsonKey(name: 'Path') String? path,@JsonKey(name: 'CollectionType') String? collectionType,@JsonKey(name: 'PlaylistItemId') String? playlistItemId,@JsonKey(name: 'Overview') String? overview,@JsonKey(name: 'ProductionYear') int? productionYear,@JsonKey(name: 'AlbumId') String? albumId,@JsonKey(name: 'Album') String? albumName,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'AlbumArtists') List<ArtistDTO> albumArtists,@JsonKey(name: 'BackdropImageTags') List<String> backdropImageTags,@JsonKey(name: 'ImageTags') Map<String, String> imageTags,@JsonKey(name: 'UserData') UserData userData,@JsonKey(name: 'MediaSources') List<MediaSourceDTO> mediaSources
});


@override $UserDataCopyWith<$Res> get userData;

}
/// @nodoc
class __$ItemDTOCopyWithImpl<$Res>
    implements _$ItemDTOCopyWith<$Res> {
  __$ItemDTOCopyWithImpl(this._self, this._then);

  final _ItemDTO _self;
  final $Res Function(_ItemDTO) _then;

/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? indexNumber = null,Object? runTimeTicks = null,Object? path = freezed,Object? collectionType = freezed,Object? playlistItemId = freezed,Object? overview = freezed,Object? productionYear = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? backdropImageTags = null,Object? imageTags = null,Object? userData = null,Object? mediaSources = null,}) {
  return _then(_ItemDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,runTimeTicks: null == runTimeTicks ? _self.runTimeTicks : runTimeTicks // ignore: cast_nullable_to_non_nullable
as int,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self._albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>,backdropImageTags: null == backdropImageTags ? _self._backdropImageTags : backdropImageTags // ignore: cast_nullable_to_non_nullable
as List<String>,imageTags: null == imageTags ? _self._imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,userData: null == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as UserData,mediaSources: null == mediaSources ? _self._mediaSources : mediaSources // ignore: cast_nullable_to_non_nullable
as List<MediaSourceDTO>,
  ));
}

/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res> get userData {
  
  return $UserDataCopyWith<$Res>(_self.userData, (value) {
    return _then(_self.copyWith(userData: value));
  });
}
}


/// @nodoc
mixin _$DownloadedAlbumDTO {

 List<String> get backdropImageTags; Map<String, String> get imageTags; DateTime get downloadDate; String get id; String get name; String get type; int get runTimeTicks; String? get overview; int? get productionYear; String? get albumArtist;@JsonKey(name: 'SizeInBytes') int get sizeInBytes;

  /// Serializes this DownloadedAlbumDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedAlbumDTO&&const DeepCollectionEquality().equals(other.backdropImageTags, backdropImageTags)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(backdropImageTags),const DeepCollectionEquality().hash(imageTags),downloadDate,id,name,type,runTimeTicks,overview,productionYear,albumArtist,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(backdropImageTags: $backdropImageTags, imageTags: $imageTags, downloadDate: $downloadDate, id: $id, name: $name, type: $type, runTimeTicks: $runTimeTicks, overview: $overview, productionYear: $productionYear, albumArtist: $albumArtist, sizeInBytes: $sizeInBytes)';
}


}




/// Adds pattern-matching-related methods to [DownloadedAlbumDTO].
extension DownloadedAlbumDTOPatterns on DownloadedAlbumDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedAlbumDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedAlbumDTO value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedAlbumDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedAlbumDTO value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  int runTimeTicks,  String? overview,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.runTimeTicks,_that.overview,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  int runTimeTicks,  String? overview,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO():
return $default(_that.id,_that.name,_that.type,_that.runTimeTicks,_that.overview,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  int runTimeTicks,  String? overview,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.runTimeTicks,_that.overview,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedAlbumDTO extends DownloadedAlbumDTO {
   _DownloadedAlbumDTO({required final  String id, required final  String name, required final  String type, required final  int runTimeTicks, final  String? overview, final  int? productionYear, final  String? albumArtist, final  List<String> backdropImageTags = const [], final  Map<String, String> imageTags = const {}, final  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes') required this.sizeInBytes}): super._(id: id, name: name, runTimeTicks: runTimeTicks, type: type, overview: overview, productionYear: productionYear, albumArtist: albumArtist, backdropImageTags: backdropImageTags, imageTags: imageTags, downloadDate: downloadDate);
  factory _DownloadedAlbumDTO.fromJson(Map<String, dynamic> json) => _$DownloadedAlbumDTOFromJson(json);

@override@JsonKey(name: 'SizeInBytes') final  int sizeInBytes;


@override
Map<String, dynamic> toJson() {
  return _$DownloadedAlbumDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other._backdropImageTags, _backdropImageTags)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,runTimeTicks,overview,productionYear,albumArtist,const DeepCollectionEquality().hash(_backdropImageTags),const DeepCollectionEquality().hash(_imageTags),downloadDate,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(id: $id, name: $name, type: $type, runTimeTicks: $runTimeTicks, overview: $overview, productionYear: $productionYear, albumArtist: $albumArtist, backdropImageTags: $backdropImageTags, imageTags: $imageTags, downloadDate: $downloadDate, sizeInBytes: $sizeInBytes)';
}


}





/// @nodoc
mixin _$DownloadedSongDTO {

 UserData get userData; Map<String, String> get imageTags; DateTime get downloadDate; String get id; String get name; int get runTimeTicks; int get indexNumber; String get type; String? get albumArtist; String? get playlistItemId;// @Default([]) List<ArtistDTO> albumArtists,
 String? get albumName; String? get albumId;@JsonKey(name: 'FilePath') String get filePath;@JsonKey(name: 'SizeInBytes') int get sizeInBytes;

  /// Serializes this DownloadedSongDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedSongDTO&&(identical(other.userData, userData) || other.userData == userData)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userData,const DeepCollectionEquality().hash(imageTags),downloadDate,id,name,runTimeTicks,indexNumber,type,albumArtist,playlistItemId,albumName,albumId,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedSongDTO(userData: $userData, imageTags: $imageTags, downloadDate: $downloadDate, id: $id, name: $name, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumName: $albumName, albumId: $albumId, filePath: $filePath, sizeInBytes: $sizeInBytes)';
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int runTimeTicks,  int indexNumber,  UserData userData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that.id,_that.name,_that.runTimeTicks,_that.indexNumber,_that.userData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int runTimeTicks,  int indexNumber,  UserData userData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedSongDTO():
return $default(_that.id,_that.name,_that.runTimeTicks,_that.indexNumber,_that.userData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int runTimeTicks,  int indexNumber,  UserData userData,  String type,  String? albumArtist,  String? playlistItemId,  String? albumName,  String? albumId,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'FilePath')  String filePath, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedSongDTO() when $default != null:
return $default(_that.id,_that.name,_that.runTimeTicks,_that.indexNumber,_that.userData,_that.type,_that.albumArtist,_that.playlistItemId,_that.albumName,_that.albumId,_that.imageTags,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedSongDTO extends DownloadedSongDTO {
   _DownloadedSongDTO({required final  String id, required final  String name, required final  int runTimeTicks, final  int indexNumber = 0, required final  UserData userData, required final  String type, final  String? albumArtist, final  String? playlistItemId, final  String? albumName, final  String? albumId, final  Map<String, String> imageTags = const {}, final  DateTime? downloadDate, @JsonKey(name: 'FilePath') required this.filePath, @JsonKey(name: 'SizeInBytes') required this.sizeInBytes}): super._(id: id, runTimeTicks: runTimeTicks, indexNumber: indexNumber, type: type, albumArtist: albumArtist, playlistItemId: playlistItemId, albumName: albumName, albumId: albumId, name: name, userData: userData, imageTags: imageTags, downloadDate: downloadDate);
  factory _DownloadedSongDTO.fromJson(Map<String, dynamic> json) => _$DownloadedSongDTOFromJson(json);

@override@JsonKey(name: 'FilePath') final  String filePath;
@override@JsonKey(name: 'SizeInBytes') final  int sizeInBytes;


@override
Map<String, dynamic> toJson() {
  return _$DownloadedSongDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedSongDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.runTimeTicks, runTimeTicks) || other.runTimeTicks == runTimeTicks)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.userData, userData) || other.userData == userData)&&(identical(other.type, type) || other.type == type)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,runTimeTicks,indexNumber,userData,type,albumArtist,playlistItemId,albumName,albumId,const DeepCollectionEquality().hash(_imageTags),downloadDate,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedSongDTO(id: $id, name: $name, runTimeTicks: $runTimeTicks, indexNumber: $indexNumber, userData: $userData, type: $type, albumArtist: $albumArtist, playlistItemId: $playlistItemId, albumName: $albumName, albumId: $albumId, imageTags: $imageTags, downloadDate: $downloadDate, filePath: $filePath, sizeInBytes: $sizeInBytes)';
}


}




// dart format on
