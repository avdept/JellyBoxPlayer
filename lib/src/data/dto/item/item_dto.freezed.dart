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

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Name') String get name;@JsonKey(name: 'ServerId') String get serverId;@JsonKey(name: 'Type') String get type;@JsonKey(name: 'Overview') String? get overview;@JsonKey(name: 'RunTimeTicks') int? get durationInTicks;@JsonKey(name: 'ProductionYear') int? get productionYear;@JsonKey(name: 'AlbumArtist') String? get albumArtist;@JsonKey(name: 'AlbumArtists') List<ArtistDTO> get albumArtists;@JsonKey(name: 'BackdropImageTags') List<String> get backdropImageTags;@JsonKey(name: 'ImageTags') Map<String, String> get imageTags;
/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<ItemDTO> get copyWith => _$ItemDTOCopyWithImpl<ItemDTO>(this as ItemDTO, _$identity);

  /// Serializes this ItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.type, type) || other.type == type)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.durationInTicks, durationInTicks) || other.durationInTicks == durationInTicks)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other.albumArtists, albumArtists)&&const DeepCollectionEquality().equals(other.backdropImageTags, backdropImageTags)&&const DeepCollectionEquality().equals(other.imageTags, imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,serverId,type,overview,durationInTicks,productionYear,albumArtist,const DeepCollectionEquality().hash(albumArtists),const DeepCollectionEquality().hash(backdropImageTags),const DeepCollectionEquality().hash(imageTags));

@override
String toString() {
  return 'ItemDTO(id: $id, name: $name, serverId: $serverId, type: $type, overview: $overview, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, albumArtists: $albumArtists, backdropImageTags: $backdropImageTags, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class $ItemDTOCopyWith<$Res>  {
  factory $ItemDTOCopyWith(ItemDTO value, $Res Function(ItemDTO) _then) = _$ItemDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name,@JsonKey(name: 'ServerId') String serverId,@JsonKey(name: 'Type') String type,@JsonKey(name: 'Overview') String? overview,@JsonKey(name: 'RunTimeTicks') int? durationInTicks,@JsonKey(name: 'ProductionYear') int? productionYear,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'AlbumArtists') List<ArtistDTO> albumArtists,@JsonKey(name: 'BackdropImageTags') List<String> backdropImageTags,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});




}
/// @nodoc
class _$ItemDTOCopyWithImpl<$Res>
    implements $ItemDTOCopyWith<$Res> {
  _$ItemDTOCopyWithImpl(this._self, this._then);

  final ItemDTO _self;
  final $Res Function(ItemDTO) _then;

/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? serverId = null,Object? type = null,Object? overview = freezed,Object? durationInTicks = freezed,Object? productionYear = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? backdropImageTags = null,Object? imageTags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,durationInTicks: freezed == durationInTicks ? _self.durationInTicks : durationInTicks // ignore: cast_nullable_to_non_nullable
as int?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self.albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>,backdropImageTags: null == backdropImageTags ? _self.backdropImageTags : backdropImageTags // ignore: cast_nullable_to_non_nullable
as List<String>,imageTags: null == imageTags ? _self.imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
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
return $default(_that);}
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'ServerId')  String serverId, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'RunTimeTicks')  int? durationInTicks, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'ServerId')  String serverId, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'RunTimeTicks')  int? durationInTicks, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)  $default,) {final _that = this;
switch (_that) {
case _ItemDTO():
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name, @JsonKey(name: 'ServerId')  String serverId, @JsonKey(name: 'Type')  String type, @JsonKey(name: 'Overview')  String? overview, @JsonKey(name: 'RunTimeTicks')  int? durationInTicks, @JsonKey(name: 'ProductionYear')  int? productionYear, @JsonKey(name: 'AlbumArtist')  String? albumArtist, @JsonKey(name: 'AlbumArtists')  List<ArtistDTO> albumArtists, @JsonKey(name: 'BackdropImageTags')  List<String> backdropImageTags, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,) {final _that = this;
switch (_that) {
case _ItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.albumArtists,_that.backdropImageTags,_that.imageTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemDTO extends ItemDTO {
  const _ItemDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'Name') required this.name, @JsonKey(name: 'ServerId') required this.serverId, @JsonKey(name: 'Type') required this.type, @JsonKey(name: 'Overview') this.overview, @JsonKey(name: 'RunTimeTicks') required this.durationInTicks, @JsonKey(name: 'ProductionYear') this.productionYear, @JsonKey(name: 'AlbumArtist') this.albumArtist, @JsonKey(name: 'AlbumArtists') final  List<ArtistDTO> albumArtists = const [], @JsonKey(name: 'BackdropImageTags') final  List<String> backdropImageTags = const [], @JsonKey(name: 'ImageTags') final  Map<String, String> imageTags = const {}}): _albumArtists = albumArtists,_backdropImageTags = backdropImageTags,_imageTags = imageTags,super._();
  factory _ItemDTO.fromJson(Map<String, dynamic> json) => _$ItemDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'Name') final  String name;
@override@JsonKey(name: 'ServerId') final  String serverId;
@override@JsonKey(name: 'Type') final  String type;
@override@JsonKey(name: 'Overview') final  String? overview;
@override@JsonKey(name: 'RunTimeTicks') final  int? durationInTicks;
@override@JsonKey(name: 'ProductionYear') final  int? productionYear;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.type, type) || other.type == type)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.durationInTicks, durationInTicks) || other.durationInTicks == durationInTicks)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other._albumArtists, _albumArtists)&&const DeepCollectionEquality().equals(other._backdropImageTags, _backdropImageTags)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,serverId,type,overview,durationInTicks,productionYear,albumArtist,const DeepCollectionEquality().hash(_albumArtists),const DeepCollectionEquality().hash(_backdropImageTags),const DeepCollectionEquality().hash(_imageTags));

@override
String toString() {
  return 'ItemDTO(id: $id, name: $name, serverId: $serverId, type: $type, overview: $overview, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, albumArtists: $albumArtists, backdropImageTags: $backdropImageTags, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class _$ItemDTOCopyWith<$Res> implements $ItemDTOCopyWith<$Res> {
  factory _$ItemDTOCopyWith(_ItemDTO value, $Res Function(_ItemDTO) _then) = __$ItemDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name,@JsonKey(name: 'ServerId') String serverId,@JsonKey(name: 'Type') String type,@JsonKey(name: 'Overview') String? overview,@JsonKey(name: 'RunTimeTicks') int? durationInTicks,@JsonKey(name: 'ProductionYear') int? productionYear,@JsonKey(name: 'AlbumArtist') String? albumArtist,@JsonKey(name: 'AlbumArtists') List<ArtistDTO> albumArtists,@JsonKey(name: 'BackdropImageTags') List<String> backdropImageTags,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});




}
/// @nodoc
class __$ItemDTOCopyWithImpl<$Res>
    implements _$ItemDTOCopyWith<$Res> {
  __$ItemDTOCopyWithImpl(this._self, this._then);

  final _ItemDTO _self;
  final $Res Function(_ItemDTO) _then;

/// Create a copy of ItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? serverId = null,Object? type = null,Object? overview = freezed,Object? durationInTicks = freezed,Object? productionYear = freezed,Object? albumArtist = freezed,Object? albumArtists = null,Object? backdropImageTags = null,Object? imageTags = null,}) {
  return _then(_ItemDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,durationInTicks: freezed == durationInTicks ? _self.durationInTicks : durationInTicks // ignore: cast_nullable_to_non_nullable
as int?,productionYear: freezed == productionYear ? _self.productionYear : productionYear // ignore: cast_nullable_to_non_nullable
as int?,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,albumArtists: null == albumArtists ? _self._albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<ArtistDTO>,backdropImageTags: null == backdropImageTags ? _self._backdropImageTags : backdropImageTags // ignore: cast_nullable_to_non_nullable
as List<String>,imageTags: null == imageTags ? _self._imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$DownloadedAlbumDTO {

 List<String> get backdropImageTags; Map<String, String> get imageTags; DateTime get downloadDate; String get id; String get name; String get serverId; String get type; String? get overview; int? get durationInTicks; int? get productionYear; String? get albumArtist;@JsonKey(name: 'SizeInBytes') int get sizeInBytes;

  /// Serializes this DownloadedAlbumDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedAlbumDTO&&const DeepCollectionEquality().equals(other.backdropImageTags, backdropImageTags)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.type, type) || other.type == type)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.durationInTicks, durationInTicks) || other.durationInTicks == durationInTicks)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(backdropImageTags),const DeepCollectionEquality().hash(imageTags),downloadDate,id,name,serverId,type,overview,durationInTicks,productionYear,albumArtist,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(backdropImageTags: $backdropImageTags, imageTags: $imageTags, downloadDate: $downloadDate, id: $id, name: $name, serverId: $serverId, type: $type, overview: $overview, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, sizeInBytes: $sizeInBytes)';
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String serverId,  String type,  String? overview,  int? durationInTicks,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String serverId,  String type,  String? overview,  int? durationInTicks,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO():
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String serverId,  String type,  String? overview,  int? durationInTicks,  int? productionYear,  String? albumArtist,  List<String> backdropImageTags,  Map<String, String> imageTags,  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes')  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.serverId,_that.type,_that.overview,_that.durationInTicks,_that.productionYear,_that.albumArtist,_that.backdropImageTags,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedAlbumDTO extends DownloadedAlbumDTO {
   _DownloadedAlbumDTO({required final  String id, required final  String name, required final  String serverId, required final  String type, final  String? overview, required final  int? durationInTicks, final  int? productionYear, final  String? albumArtist, final  List<String> backdropImageTags = const [], final  Map<String, String> imageTags = const {}, final  DateTime? downloadDate, @JsonKey(name: 'SizeInBytes') required this.sizeInBytes}): super._(id: id, name: name, serverId: serverId, type: type, overview: overview, durationInTicks: durationInTicks, productionYear: productionYear, albumArtist: albumArtist, backdropImageTags: backdropImageTags, imageTags: imageTags, downloadDate: downloadDate);
  factory _DownloadedAlbumDTO.fromJson(Map<String, dynamic> json) => _$DownloadedAlbumDTOFromJson(json);

@override@JsonKey(name: 'SizeInBytes') final  int sizeInBytes;


@override
Map<String, dynamic> toJson() {
  return _$DownloadedAlbumDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.type, type) || other.type == type)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.durationInTicks, durationInTicks) || other.durationInTicks == durationInTicks)&&(identical(other.productionYear, productionYear) || other.productionYear == productionYear)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&const DeepCollectionEquality().equals(other._backdropImageTags, _backdropImageTags)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,serverId,type,overview,durationInTicks,productionYear,albumArtist,const DeepCollectionEquality().hash(_backdropImageTags),const DeepCollectionEquality().hash(_imageTags),downloadDate,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(id: $id, name: $name, serverId: $serverId, type: $type, overview: $overview, durationInTicks: $durationInTicks, productionYear: $productionYear, albumArtist: $albumArtist, backdropImageTags: $backdropImageTags, imageTags: $imageTags, downloadDate: $downloadDate, sizeInBytes: $sizeInBytes)';
}


}




// dart format on
