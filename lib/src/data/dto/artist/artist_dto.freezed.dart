// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistDTO {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Name') String get name;
/// Create a copy of ArtistDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistDTOCopyWith<ArtistDTO> get copyWith => _$ArtistDTOCopyWithImpl<ArtistDTO>(this as ArtistDTO, _$identity);

  /// Serializes this ArtistDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ArtistDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ArtistDTOCopyWith<$Res>  {
  factory $ArtistDTOCopyWith(ArtistDTO value, $Res Function(ArtistDTO) _then) = _$ArtistDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name
});




}
/// @nodoc
class _$ArtistDTOCopyWithImpl<$Res>
    implements $ArtistDTOCopyWith<$Res> {
  _$ArtistDTOCopyWithImpl(this._self, this._then);

  final ArtistDTO _self;
  final $Res Function(ArtistDTO) _then;

/// Create a copy of ArtistDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistDTO].
extension ArtistDTOPatterns on ArtistDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistDTO value)  $default,){
final _that = this;
switch (_that) {
case _ArtistDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistDTO value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistDTO() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name)  $default,) {final _that = this;
switch (_that) {
case _ArtistDTO():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String name)?  $default,) {final _that = this;
switch (_that) {
case _ArtistDTO() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistDTO implements ArtistDTO {
  const _ArtistDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'Name') required this.name});
  factory _ArtistDTO.fromJson(Map<String, dynamic> json) => _$ArtistDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'Name') final  String name;

/// Create a copy of ArtistDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistDTOCopyWith<_ArtistDTO> get copyWith => __$ArtistDTOCopyWithImpl<_ArtistDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ArtistDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ArtistDTOCopyWith<$Res> implements $ArtistDTOCopyWith<$Res> {
  factory _$ArtistDTOCopyWith(_ArtistDTO value, $Res Function(_ArtistDTO) _then) = __$ArtistDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String name
});




}
/// @nodoc
class __$ArtistDTOCopyWithImpl<$Res>
    implements _$ArtistDTOCopyWith<$Res> {
  __$ArtistDTOCopyWithImpl(this._self, this._then);

  final _ArtistDTO _self;
  final $Res Function(_ArtistDTO) _then;

/// Create a copy of ArtistDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ArtistDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
