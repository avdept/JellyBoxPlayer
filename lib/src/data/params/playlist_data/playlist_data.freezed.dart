// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaylistData {

@JsonKey(name: 'Name') String get name;@JsonKey(name: 'UserId') String get userId;@JsonKey(name: 'IsPublic') bool get isPublic;
/// Create a copy of PlaylistData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDataCopyWith<PlaylistData> get copyWith => _$PlaylistDataCopyWithImpl<PlaylistData>(this as PlaylistData, _$identity);

  /// Serializes this PlaylistData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistData&&(identical(other.name, name) || other.name == name)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,userId,isPublic);

@override
String toString() {
  return 'PlaylistData(name: $name, userId: $userId, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $PlaylistDataCopyWith<$Res>  {
  factory $PlaylistDataCopyWith(PlaylistData value, $Res Function(PlaylistData) _then) = _$PlaylistDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Name') String name,@JsonKey(name: 'UserId') String userId,@JsonKey(name: 'IsPublic') bool isPublic
});




}
/// @nodoc
class _$PlaylistDataCopyWithImpl<$Res>
    implements $PlaylistDataCopyWith<$Res> {
  _$PlaylistDataCopyWithImpl(this._self, this._then);

  final PlaylistData _self;
  final $Res Function(PlaylistData) _then;

/// Create a copy of PlaylistData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? userId = null,Object? isPublic = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistData].
extension PlaylistDataPatterns on PlaylistData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistData value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistData value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Name')  String name, @JsonKey(name: 'UserId')  String userId, @JsonKey(name: 'IsPublic')  bool isPublic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistData() when $default != null:
return $default(_that.name,_that.userId,_that.isPublic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Name')  String name, @JsonKey(name: 'UserId')  String userId, @JsonKey(name: 'IsPublic')  bool isPublic)  $default,) {final _that = this;
switch (_that) {
case _PlaylistData():
return $default(_that.name,_that.userId,_that.isPublic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Name')  String name, @JsonKey(name: 'UserId')  String userId, @JsonKey(name: 'IsPublic')  bool isPublic)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistData() when $default != null:
return $default(_that.name,_that.userId,_that.isPublic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistData implements PlaylistData {
  const _PlaylistData({@JsonKey(name: 'Name') required this.name, @JsonKey(name: 'UserId') required this.userId, @JsonKey(name: 'IsPublic') required this.isPublic});
  factory _PlaylistData.fromJson(Map<String, dynamic> json) => _$PlaylistDataFromJson(json);

@override@JsonKey(name: 'Name') final  String name;
@override@JsonKey(name: 'UserId') final  String userId;
@override@JsonKey(name: 'IsPublic') final  bool isPublic;

/// Create a copy of PlaylistData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistDataCopyWith<_PlaylistData> get copyWith => __$PlaylistDataCopyWithImpl<_PlaylistData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistData&&(identical(other.name, name) || other.name == name)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,userId,isPublic);

@override
String toString() {
  return 'PlaylistData(name: $name, userId: $userId, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class _$PlaylistDataCopyWith<$Res> implements $PlaylistDataCopyWith<$Res> {
  factory _$PlaylistDataCopyWith(_PlaylistData value, $Res Function(_PlaylistData) _then) = __$PlaylistDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Name') String name,@JsonKey(name: 'UserId') String userId,@JsonKey(name: 'IsPublic') bool isPublic
});




}
/// @nodoc
class __$PlaylistDataCopyWithImpl<$Res>
    implements _$PlaylistDataCopyWith<$Res> {
  __$PlaylistDataCopyWithImpl(this._self, this._then);

  final _PlaylistData _self;
  final $Res Function(_PlaylistData) _then;

/// Create a copy of PlaylistData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? userId = null,Object? isPublic = null,}) {
  return _then(_PlaylistData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
