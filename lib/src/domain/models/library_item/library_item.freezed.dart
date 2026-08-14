// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryItem {

 String get id; String get name; ItemKind get kind; int get indexNumber; Duration get duration; String? get path; String? get collectionType; String? get playlistItemId; String? get overview; int? get productionYear; String? get albumId; String? get albumName; String? get albumArtist; List<ArtistRef> get albumArtists; ImageRefs get images; bool get hasLyrics; PlaybackUserData get userData; List<AudioSourceInfo> get audioSources;
/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryItemCopyWith<LibraryItem> get copyWith => _$LibraryItemCopyWithImpl<LibraryItem>(this as LibraryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.path, path) || other.path == path)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other.albumArtists, albumArtists)&&(identical(other.images, images) || other.images == images)&&(identical(other.hasLyrics, hasLyrics) || other.hasLyrics == hasLyrics)&&(identical(other.userData, userData) || other.userData == userData)&&const DeepCollectionEquality().equals(other.audioSources, audioSources));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,kind,indexNumber,duration,path,collectionType,playlistItemId,overview,productionYear,albumId,albumName,albumArtist,const DeepCollectionEquality().hash(albumArtists),images,hasLyrics,userData,const DeepCollectionEquality().hash(audioSources));

@override
String toString() {
  return 'LibraryItem(id: $id, name: $name, kind: $kind, indexNumber: $indexNumber, duration: $duration, path: $path, collectionType: $collectionType, playlistItemId: $playlistItemId, overview: $overview, productionYear: $productionYear, albumId: $albumId, albumName: $albumName, albumArtist: $albumArtist, albumArtists: $albumArtists, images: $images, hasLyrics: $hasLyrics, userData: $userData, audioSources: $audioSources)';
}


}

/// @nodoc
abstract mixin class $LibraryItemCopyWith<$Res>  {
  factory $LibraryItemCopyWith(LibraryItem value, $Res Function(LibraryItem) _then) = _$LibraryItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, ItemKind kind, int indexNumber, Duration duration, String? path, String? collectionType, String? playlistItemId, String? overview, int? productionYear, String? albumId, String? albumName, String? albumArtist, List<ArtistRef> albumArtists, ImageRefs images, bool hasLyrics, PlaybackUserData userData, List<AudioSourceInfo> audioSources
});


$ImageRefsCopyWith<$Res> get images;$PlaybackUserDataCopyWith<$Res> get userData;

}
/// @nodoc
class _$LibraryItemCopyWithImpl<$Res>
    implements $LibraryItemCopyWith<$Res> {
  _$LibraryItemCopyWithImpl(this._self, this._then);

  final LibraryItem _self;
  final $Res Function(LibraryItem) _then;

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? indexNumber = null,Object? duration = null,Object? path = freezed,Object? collectionType = freezed,Object? playlistItemId = freezed,Object? overview = freezed,Object? productionYear = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? images = null,Object? hasLyrics = null,Object? userData = null,Object? audioSources = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ItemKind,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self.albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistRef>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as ImageRefs,hasLyrics: null == hasLyrics ? _self.hasLyrics : hasLyrics // ignore: cast_nullable_to_non_nullable
as bool,userData: null == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as PlaybackUserData,audioSources: null == audioSources ? _self.audioSources : audioSources // ignore: cast_nullable_to_non_nullable
as List<AudioSourceInfo>,
  ));
}
/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageRefsCopyWith<$Res> get images {
  
  return $ImageRefsCopyWith<$Res>(_self.images, (value) {
    return _then(_self.copyWith(images: value));
  });
}/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackUserDataCopyWith<$Res> get userData {
  
  return $PlaybackUserDataCopyWith<$Res>(_self.userData, (value) {
    return _then(_self.copyWith(userData: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryItem].
extension LibraryItemPatterns on LibraryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryItem value)  $default,){
final _that = this;
switch (_that) {
case _LibraryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryItem value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ItemKind kind,  int indexNumber,  Duration duration,  String? path,  String? collectionType,  String? playlistItemId,  String? overview,  int? productionYear,  String? albumId,  String? albumName,  String? albumArtist,  List<ArtistRef> albumArtists,  ImageRefs images,  bool hasLyrics,  PlaybackUserData userData,  List<AudioSourceInfo> audioSources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.indexNumber,_that.duration,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.images,_that.hasLyrics,_that.userData,_that.audioSources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ItemKind kind,  int indexNumber,  Duration duration,  String? path,  String? collectionType,  String? playlistItemId,  String? overview,  int? productionYear,  String? albumId,  String? albumName,  String? albumArtist,  List<ArtistRef> albumArtists,  ImageRefs images,  bool hasLyrics,  PlaybackUserData userData,  List<AudioSourceInfo> audioSources)  $default,) {final _that = this;
switch (_that) {
case _LibraryItem():
return $default(_that.id,_that.name,_that.kind,_that.indexNumber,_that.duration,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.images,_that.hasLyrics,_that.userData,_that.audioSources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ItemKind kind,  int indexNumber,  Duration duration,  String? path,  String? collectionType,  String? playlistItemId,  String? overview,  int? productionYear,  String? albumId,  String? albumName,  String? albumArtist,  List<ArtistRef> albumArtists,  ImageRefs images,  bool hasLyrics,  PlaybackUserData userData,  List<AudioSourceInfo> audioSources)?  $default,) {final _that = this;
switch (_that) {
case _LibraryItem() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.indexNumber,_that.duration,_that.path,_that.collectionType,_that.playlistItemId,_that.overview,_that.productionYear,_that.albumId,_that.albumName,_that.albumArtist,_that.albumArtists,_that.images,_that.hasLyrics,_that.userData,_that.audioSources);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryItem implements LibraryItem {
  const _LibraryItem({required this.id, required this.name, required this.kind, this.indexNumber = 0, this.duration = Duration.zero, this.path, this.collectionType, this.playlistItemId, this.overview, this.productionYear, this.albumId, this.albumName, this.albumArtist, final  List<ArtistRef> albumArtists = const [], this.images = const ImageRefs(), this.hasLyrics = false, this.userData = const PlaybackUserData(), final  List<AudioSourceInfo> audioSources = const []}): _albumArtists = albumArtists,_audioSources = audioSources;
  

@override final  String id;
@override final  String name;
@override final  ItemKind kind;
@override@JsonKey() final  int indexNumber;
@override@JsonKey() final  Duration duration;
@override final  String? path;
@override final  String? collectionType;
@override final  String? playlistItemId;
@override final  String? overview;
@override final  int? productionYear;
@override final  String? albumId;
@override final  String? albumName;
@override final  String? albumArtist;
 final  List<ArtistRef> _albumArtists;
@override@JsonKey() List<ArtistRef> get albumArtists {
  if (_albumArtists is EqualUnmodifiableListView) return _albumArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albumArtists);
}

@override@JsonKey() final  ImageRefs images;
@override@JsonKey() final  bool hasLyrics;
@override@JsonKey() final  PlaybackUserData userData;
 final  List<AudioSourceInfo> _audioSources;
@override@JsonKey() List<AudioSourceInfo> get audioSources {
  if (_audioSources is EqualUnmodifiableListView) return _audioSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioSources);
}


/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryItemCopyWith<_LibraryItem> get copyWith => __$LibraryItemCopyWithImpl<_LibraryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.indexNumber, indexNumber) || other.indexNumber == indexNumber)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.path, path) || other.path == path)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other._albumArtists, _albumArtists)&&(identical(other.images, images) || other.images == images)&&(identical(other.hasLyrics, hasLyrics) || other.hasLyrics == hasLyrics)&&(identical(other.userData, userData) || other.userData == userData)&&const DeepCollectionEquality().equals(other._audioSources, _audioSources));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,kind,indexNumber,duration,path,collectionType,playlistItemId,overview,productionYear,albumId,albumName,albumArtist,const DeepCollectionEquality().hash(_albumArtists),images,hasLyrics,userData,const DeepCollectionEquality().hash(_audioSources));

@override
String toString() {
  return 'LibraryItem(id: $id, name: $name, kind: $kind, indexNumber: $indexNumber, duration: $duration, path: $path, collectionType: $collectionType, playlistItemId: $playlistItemId, overview: $overview, productionYear: $productionYear, albumId: $albumId, albumName: $albumName, albumArtist: $albumArtist, albumArtists: $albumArtists, images: $images, hasLyrics: $hasLyrics, userData: $userData, audioSources: $audioSources)';
}


}

/// @nodoc
abstract mixin class _$LibraryItemCopyWith<$Res> implements $LibraryItemCopyWith<$Res> {
  factory _$LibraryItemCopyWith(_LibraryItem value, $Res Function(_LibraryItem) _then) = __$LibraryItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ItemKind kind, int indexNumber, Duration duration, String? path, String? collectionType, String? playlistItemId, String? overview, int? productionYear, String? albumId, String? albumName, String? albumArtist, List<ArtistRef> albumArtists, ImageRefs images, bool hasLyrics, PlaybackUserData userData, List<AudioSourceInfo> audioSources
});


@override $ImageRefsCopyWith<$Res> get images;@override $PlaybackUserDataCopyWith<$Res> get userData;

}
/// @nodoc
class __$LibraryItemCopyWithImpl<$Res>
    implements _$LibraryItemCopyWith<$Res> {
  __$LibraryItemCopyWithImpl(this._self, this._then);

  final _LibraryItem _self;
  final $Res Function(_LibraryItem) _then;

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? indexNumber = null,Object? duration = null,Object? path = freezed,Object? collectionType = freezed,Object? playlistItemId = freezed,Object? overview = freezed,Object? productionYear = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? images = null,Object? hasLyrics = null,Object? userData = null,Object? audioSources = null,}) {
  return _then(_LibraryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ItemKind,indexNumber: null == indexNumber ? _self.indexNumber : indexNumber // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self._albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistRef>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as ImageRefs,hasLyrics: null == hasLyrics ? _self.hasLyrics : hasLyrics // ignore: cast_nullable_to_non_nullable
as bool,userData: null == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as PlaybackUserData,audioSources: null == audioSources ? _self._audioSources : audioSources // ignore: cast_nullable_to_non_nullable
as List<AudioSourceInfo>,
  ));
}

/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageRefsCopyWith<$Res> get images {
  
  return $ImageRefsCopyWith<$Res>(_self.images, (value) {
    return _then(_self.copyWith(images: value));
  });
}/// Create a copy of LibraryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackUserDataCopyWith<$Res> get userData {
  
  return $PlaybackUserDataCopyWith<$Res>(_self.userData, (value) {
    return _then(_self.copyWith(userData: value));
  });
}
}

// dart format on
