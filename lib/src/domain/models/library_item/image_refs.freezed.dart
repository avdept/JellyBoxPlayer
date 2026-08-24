// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_refs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImageRefs {

 String? get primary; String? get primaryItemId; String? get albumPrimary; List<String> get backdrops;
/// Create a copy of ImageRefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageRefsCopyWith<ImageRefs> get copyWith => _$ImageRefsCopyWithImpl<ImageRefs>(this as ImageRefs, _$identity);

  /// Serializes this ImageRefs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageRefs&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.primaryItemId, primaryItemId) || other.primaryItemId == primaryItemId)&&(identical(other.albumPrimary, albumPrimary) || other.albumPrimary == albumPrimary)&&const DeepCollectionEquality().equals(other.backdrops, backdrops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primary,primaryItemId,albumPrimary,const DeepCollectionEquality().hash(backdrops));

@override
String toString() {
  return 'ImageRefs(primary: $primary, primaryItemId: $primaryItemId, albumPrimary: $albumPrimary, backdrops: $backdrops)';
}


}

/// @nodoc
abstract mixin class $ImageRefsCopyWith<$Res>  {
  factory $ImageRefsCopyWith(ImageRefs value, $Res Function(ImageRefs) _then) = _$ImageRefsCopyWithImpl;
@useResult
$Res call({
 String? primary, String? primaryItemId, String? albumPrimary, List<String> backdrops
});




}
/// @nodoc
class _$ImageRefsCopyWithImpl<$Res>
    implements $ImageRefsCopyWith<$Res> {
  _$ImageRefsCopyWithImpl(this._self, this._then);

  final ImageRefs _self;
  final $Res Function(ImageRefs) _then;

/// Create a copy of ImageRefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = freezed,Object? primaryItemId = freezed,Object? albumPrimary = freezed,Object? backdrops = null,}) {
  return _then(_self.copyWith(
primary: freezed == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as String?,primaryItemId: freezed == primaryItemId ? _self.primaryItemId : primaryItemId // ignore: cast_nullable_to_non_nullable
as String?,albumPrimary: freezed == albumPrimary ? _self.albumPrimary : albumPrimary // ignore: cast_nullable_to_non_nullable
as String?,backdrops: null == backdrops ? _self.backdrops : backdrops // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageRefs].
extension ImageRefsPatterns on ImageRefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageRefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageRefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageRefs value)  $default,){
final _that = this;
switch (_that) {
case _ImageRefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageRefs value)?  $default,){
final _that = this;
switch (_that) {
case _ImageRefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? primary,  String? primaryItemId,  String? albumPrimary,  List<String> backdrops)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageRefs() when $default != null:
return $default(_that.primary,_that.primaryItemId,_that.albumPrimary,_that.backdrops);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? primary,  String? primaryItemId,  String? albumPrimary,  List<String> backdrops)  $default,) {final _that = this;
switch (_that) {
case _ImageRefs():
return $default(_that.primary,_that.primaryItemId,_that.albumPrimary,_that.backdrops);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? primary,  String? primaryItemId,  String? albumPrimary,  List<String> backdrops)?  $default,) {final _that = this;
switch (_that) {
case _ImageRefs() when $default != null:
return $default(_that.primary,_that.primaryItemId,_that.albumPrimary,_that.backdrops);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageRefs extends ImageRefs {
  const _ImageRefs({this.primary, this.primaryItemId, this.albumPrimary, final  List<String> backdrops = const []}): _backdrops = backdrops,super._();
  factory _ImageRefs.fromJson(Map<String, dynamic> json) => _$ImageRefsFromJson(json);

@override final  String? primary;
@override final  String? primaryItemId;
@override final  String? albumPrimary;
 final  List<String> _backdrops;
@override@JsonKey() List<String> get backdrops {
  if (_backdrops is EqualUnmodifiableListView) return _backdrops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backdrops);
}


/// Create a copy of ImageRefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageRefsCopyWith<_ImageRefs> get copyWith => __$ImageRefsCopyWithImpl<_ImageRefs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageRefsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageRefs&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.primaryItemId, primaryItemId) || other.primaryItemId == primaryItemId)&&(identical(other.albumPrimary, albumPrimary) || other.albumPrimary == albumPrimary)&&const DeepCollectionEquality().equals(other._backdrops, _backdrops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primary,primaryItemId,albumPrimary,const DeepCollectionEquality().hash(_backdrops));

@override
String toString() {
  return 'ImageRefs(primary: $primary, primaryItemId: $primaryItemId, albumPrimary: $albumPrimary, backdrops: $backdrops)';
}


}

/// @nodoc
abstract mixin class _$ImageRefsCopyWith<$Res> implements $ImageRefsCopyWith<$Res> {
  factory _$ImageRefsCopyWith(_ImageRefs value, $Res Function(_ImageRefs) _then) = __$ImageRefsCopyWithImpl;
@override @useResult
$Res call({
 String? primary, String? primaryItemId, String? albumPrimary, List<String> backdrops
});




}
/// @nodoc
class __$ImageRefsCopyWithImpl<$Res>
    implements _$ImageRefsCopyWith<$Res> {
  __$ImageRefsCopyWithImpl(this._self, this._then);

  final _ImageRefs _self;
  final $Res Function(_ImageRefs) _then;

/// Create a copy of ImageRefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primary = freezed,Object? primaryItemId = freezed,Object? albumPrimary = freezed,Object? backdrops = null,}) {
  return _then(_ImageRefs(
primary: freezed == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as String?,primaryItemId: freezed == primaryItemId ? _self.primaryItemId : primaryItemId // ignore: cast_nullable_to_non_nullable
as String?,albumPrimary: freezed == albumPrimary ? _self.albumPrimary : albumPrimary // ignore: cast_nullable_to_non_nullable
as String?,backdrops: null == backdrops ? _self._backdrops : backdrops // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
