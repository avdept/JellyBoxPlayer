// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_connect_state_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuickConnectStateDTO {

@JsonKey(name: 'Secret') String get secret;@JsonKey(name: 'Code') String get code;@JsonKey(name: 'Authenticated') bool get authenticated;
/// Create a copy of QuickConnectStateDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickConnectStateDTOCopyWith<QuickConnectStateDTO> get copyWith => _$QuickConnectStateDTOCopyWithImpl<QuickConnectStateDTO>(this as QuickConnectStateDTO, _$identity);

  /// Serializes this QuickConnectStateDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickConnectStateDTO&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.code, code) || other.code == code)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,code,authenticated);

@override
String toString() {
  return 'QuickConnectStateDTO(secret: $secret, code: $code, authenticated: $authenticated)';
}


}

/// @nodoc
abstract mixin class $QuickConnectStateDTOCopyWith<$Res>  {
  factory $QuickConnectStateDTOCopyWith(QuickConnectStateDTO value, $Res Function(QuickConnectStateDTO) _then) = _$QuickConnectStateDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Secret') String secret,@JsonKey(name: 'Code') String code,@JsonKey(name: 'Authenticated') bool authenticated
});




}
/// @nodoc
class _$QuickConnectStateDTOCopyWithImpl<$Res>
    implements $QuickConnectStateDTOCopyWith<$Res> {
  _$QuickConnectStateDTOCopyWithImpl(this._self, this._then);

  final QuickConnectStateDTO _self;
  final $Res Function(QuickConnectStateDTO) _then;

/// Create a copy of QuickConnectStateDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? secret = null,Object? code = null,Object? authenticated = null,}) {
  return _then(_self.copyWith(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickConnectStateDTO].
extension QuickConnectStateDTOPatterns on QuickConnectStateDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickConnectStateDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickConnectStateDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickConnectStateDTO value)  $default,){
final _that = this;
switch (_that) {
case _QuickConnectStateDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickConnectStateDTO value)?  $default,){
final _that = this;
switch (_that) {
case _QuickConnectStateDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Secret')  String secret, @JsonKey(name: 'Code')  String code, @JsonKey(name: 'Authenticated')  bool authenticated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickConnectStateDTO() when $default != null:
return $default(_that.secret,_that.code,_that.authenticated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Secret')  String secret, @JsonKey(name: 'Code')  String code, @JsonKey(name: 'Authenticated')  bool authenticated)  $default,) {final _that = this;
switch (_that) {
case _QuickConnectStateDTO():
return $default(_that.secret,_that.code,_that.authenticated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Secret')  String secret, @JsonKey(name: 'Code')  String code, @JsonKey(name: 'Authenticated')  bool authenticated)?  $default,) {final _that = this;
switch (_that) {
case _QuickConnectStateDTO() when $default != null:
return $default(_that.secret,_that.code,_that.authenticated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuickConnectStateDTO implements QuickConnectStateDTO {
  const _QuickConnectStateDTO({@JsonKey(name: 'Secret') required this.secret, @JsonKey(name: 'Code') required this.code, @JsonKey(name: 'Authenticated') this.authenticated = false});
  factory _QuickConnectStateDTO.fromJson(Map<String, dynamic> json) => _$QuickConnectStateDTOFromJson(json);

@override@JsonKey(name: 'Secret') final  String secret;
@override@JsonKey(name: 'Code') final  String code;
@override@JsonKey(name: 'Authenticated') final  bool authenticated;

/// Create a copy of QuickConnectStateDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickConnectStateDTOCopyWith<_QuickConnectStateDTO> get copyWith => __$QuickConnectStateDTOCopyWithImpl<_QuickConnectStateDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuickConnectStateDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickConnectStateDTO&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.code, code) || other.code == code)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,code,authenticated);

@override
String toString() {
  return 'QuickConnectStateDTO(secret: $secret, code: $code, authenticated: $authenticated)';
}


}

/// @nodoc
abstract mixin class _$QuickConnectStateDTOCopyWith<$Res> implements $QuickConnectStateDTOCopyWith<$Res> {
  factory _$QuickConnectStateDTOCopyWith(_QuickConnectStateDTO value, $Res Function(_QuickConnectStateDTO) _then) = __$QuickConnectStateDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Secret') String secret,@JsonKey(name: 'Code') String code,@JsonKey(name: 'Authenticated') bool authenticated
});




}
/// @nodoc
class __$QuickConnectStateDTOCopyWithImpl<$Res>
    implements _$QuickConnectStateDTOCopyWith<$Res> {
  __$QuickConnectStateDTOCopyWithImpl(this._self, this._then);

  final _QuickConnectStateDTO _self;
  final $Res Function(_QuickConnectStateDTO) _then;

/// Create a copy of QuickConnectStateDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? secret = null,Object? code = null,Object? authenticated = null,}) {
  return _then(_QuickConnectStateDTO(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
