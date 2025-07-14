// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloaded_album_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadedAlbumDTO {

 String get id; String get name; String? get artistName; Map<String, String> get imageTags; DateTime get downloadDate; int get sizeInBytes;
/// Create a copy of DownloadedAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadedAlbumDTOCopyWith<DownloadedAlbumDTO> get copyWith => _$DownloadedAlbumDTOCopyWithImpl<DownloadedAlbumDTO>(this as DownloadedAlbumDTO, _$identity);

  /// Serializes this DownloadedAlbumDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&const DeepCollectionEquality().equals(other.imageTags, imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,artistName,const DeepCollectionEquality().hash(imageTags),downloadDate,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(id: $id, name: $name, artistName: $artistName, imageTags: $imageTags, downloadDate: $downloadDate, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class $DownloadedAlbumDTOCopyWith<$Res>  {
  factory $DownloadedAlbumDTOCopyWith(DownloadedAlbumDTO value, $Res Function(DownloadedAlbumDTO) _then) = _$DownloadedAlbumDTOCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? artistName, Map<String, String> imageTags, DateTime downloadDate, int sizeInBytes
});




}
/// @nodoc
class _$DownloadedAlbumDTOCopyWithImpl<$Res>
    implements $DownloadedAlbumDTOCopyWith<$Res> {
  _$DownloadedAlbumDTOCopyWithImpl(this._self, this._then);

  final DownloadedAlbumDTO _self;
  final $Res Function(DownloadedAlbumDTO) _then;

/// Create a copy of DownloadedAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artistName = freezed,Object? imageTags = null,Object? downloadDate = null,Object? sizeInBytes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self.imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,downloadDate: null == downloadDate ? _self.downloadDate : downloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? artistName,  Map<String, String> imageTags,  DateTime downloadDate,  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.artistName,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? artistName,  Map<String, String> imageTags,  DateTime downloadDate,  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO():
return $default(_that.id,_that.name,_that.artistName,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? artistName,  Map<String, String> imageTags,  DateTime downloadDate,  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.artistName,_that.imageTags,_that.downloadDate,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedAlbumDTO implements DownloadedAlbumDTO {
  const _DownloadedAlbumDTO({required this.id, required this.name, required this.artistName, required final  Map<String, String> imageTags, required this.downloadDate, required this.sizeInBytes}): _imageTags = imageTags;
  factory _DownloadedAlbumDTO.fromJson(Map<String, dynamic> json) => _$DownloadedAlbumDTOFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? artistName;
 final  Map<String, String> _imageTags;
@override Map<String, String> get imageTags {
  if (_imageTags is EqualUnmodifiableMapView) return _imageTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_imageTags);
}

@override final  DateTime downloadDate;
@override final  int sizeInBytes;

/// Create a copy of DownloadedAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadedAlbumDTOCopyWith<_DownloadedAlbumDTO> get copyWith => __$DownloadedAlbumDTOCopyWithImpl<_DownloadedAlbumDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadedAlbumDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,artistName,const DeepCollectionEquality().hash(_imageTags),downloadDate,sizeInBytes);

@override
String toString() {
  return 'DownloadedAlbumDTO(id: $id, name: $name, artistName: $artistName, imageTags: $imageTags, downloadDate: $downloadDate, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class _$DownloadedAlbumDTOCopyWith<$Res> implements $DownloadedAlbumDTOCopyWith<$Res> {
  factory _$DownloadedAlbumDTOCopyWith(_DownloadedAlbumDTO value, $Res Function(_DownloadedAlbumDTO) _then) = __$DownloadedAlbumDTOCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? artistName, Map<String, String> imageTags, DateTime downloadDate, int sizeInBytes
});




}
/// @nodoc
class __$DownloadedAlbumDTOCopyWithImpl<$Res>
    implements _$DownloadedAlbumDTOCopyWith<$Res> {
  __$DownloadedAlbumDTOCopyWithImpl(this._self, this._then);

  final _DownloadedAlbumDTO _self;
  final $Res Function(_DownloadedAlbumDTO) _then;

/// Create a copy of DownloadedAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artistName = freezed,Object? imageTags = null,Object? downloadDate = null,Object? sizeInBytes = null,}) {
  return _then(_DownloadedAlbumDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self._imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,downloadDate: null == downloadDate ? _self.downloadDate : downloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
