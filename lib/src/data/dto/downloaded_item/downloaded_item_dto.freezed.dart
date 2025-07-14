// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloaded_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadedItemDTO {

 String get id; String? get name; String? get albumId; String? get albumName; String? get artistName; DateTime get downloadDate; String get filePath; int get sizeInBytes;
/// Create a copy of DownloadedItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadedItemDTOCopyWith<DownloadedItemDTO> get copyWith => _$DownloadedItemDTOCopyWithImpl<DownloadedItemDTO>(this as DownloadedItemDTO, _$identity);

  /// Serializes this DownloadedItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadedItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,albumId,albumName,artistName,downloadDate,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedItemDTO(id: $id, name: $name, albumId: $albumId, albumName: $albumName, artistName: $artistName, downloadDate: $downloadDate, filePath: $filePath, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class $DownloadedItemDTOCopyWith<$Res>  {
  factory $DownloadedItemDTOCopyWith(DownloadedItemDTO value, $Res Function(DownloadedItemDTO) _then) = _$DownloadedItemDTOCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? albumId, String? albumName, String? artistName, DateTime downloadDate, String filePath, int sizeInBytes
});




}
/// @nodoc
class _$DownloadedItemDTOCopyWithImpl<$Res>
    implements $DownloadedItemDTOCopyWith<$Res> {
  _$DownloadedItemDTOCopyWithImpl(this._self, this._then);

  final DownloadedItemDTO _self;
  final $Res Function(DownloadedItemDTO) _then;

/// Create a copy of DownloadedItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? artistName = freezed,Object? downloadDate = null,Object? filePath = null,Object? sizeInBytes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,downloadDate: null == downloadDate ? _self.downloadDate : downloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadedItemDTO].
extension DownloadedItemDTOPatterns on DownloadedItemDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadedItemDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadedItemDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadedItemDTO value)  $default,){
final _that = this;
switch (_that) {
case _DownloadedItemDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadedItemDTO value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadedItemDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? albumId,  String? albumName,  String? artistName,  DateTime downloadDate,  String filePath,  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadedItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.albumId,_that.albumName,_that.artistName,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? albumId,  String? albumName,  String? artistName,  DateTime downloadDate,  String filePath,  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _DownloadedItemDTO():
return $default(_that.id,_that.name,_that.albumId,_that.albumName,_that.artistName,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? albumId,  String? albumName,  String? artistName,  DateTime downloadDate,  String filePath,  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _DownloadedItemDTO() when $default != null:
return $default(_that.id,_that.name,_that.albumId,_that.albumName,_that.artistName,_that.downloadDate,_that.filePath,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadedItemDTO implements DownloadedItemDTO {
  const _DownloadedItemDTO({required this.id, required this.name, required this.albumId, required this.albumName, required this.artistName, required this.downloadDate, required this.filePath, required this.sizeInBytes});
  factory _DownloadedItemDTO.fromJson(Map<String, dynamic> json) => _$DownloadedItemDTOFromJson(json);

@override final  String id;
@override final  String? name;
@override final  String? albumId;
@override final  String? albumName;
@override final  String? artistName;
@override final  DateTime downloadDate;
@override final  String filePath;
@override final  int sizeInBytes;

/// Create a copy of DownloadedItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadedItemDTOCopyWith<_DownloadedItemDTO> get copyWith => __$DownloadedItemDTOCopyWithImpl<_DownloadedItemDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadedItemDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadedItemDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.albumName, albumName) || other.albumName == albumName)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.downloadDate, downloadDate) || other.downloadDate == downloadDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,albumId,albumName,artistName,downloadDate,filePath,sizeInBytes);

@override
String toString() {
  return 'DownloadedItemDTO(id: $id, name: $name, albumId: $albumId, albumName: $albumName, artistName: $artistName, downloadDate: $downloadDate, filePath: $filePath, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class _$DownloadedItemDTOCopyWith<$Res> implements $DownloadedItemDTOCopyWith<$Res> {
  factory _$DownloadedItemDTOCopyWith(_DownloadedItemDTO value, $Res Function(_DownloadedItemDTO) _then) = __$DownloadedItemDTOCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? albumId, String? albumName, String? artistName, DateTime downloadDate, String filePath, int sizeInBytes
});




}
/// @nodoc
class __$DownloadedItemDTOCopyWithImpl<$Res>
    implements _$DownloadedItemDTOCopyWith<$Res> {
  __$DownloadedItemDTOCopyWithImpl(this._self, this._then);

  final _DownloadedItemDTO _self;
  final $Res Function(_DownloadedItemDTO) _then;

/// Create a copy of DownloadedItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? albumId = freezed,Object? albumName = freezed,Object? artistName = freezed,Object? downloadDate = null,Object? filePath = null,Object? sizeInBytes = null,}) {
  return _then(_DownloadedItemDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumName: freezed == albumName ? _self.albumName : albumName // ignore: cast_nullable_to_non_nullable
as String?,artistName: freezed == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String?,downloadDate: null == downloadDate ? _self.downloadDate : downloadDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
