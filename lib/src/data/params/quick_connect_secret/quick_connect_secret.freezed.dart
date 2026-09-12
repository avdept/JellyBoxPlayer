// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_connect_secret.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickConnectSecret {

@JsonKey(name: 'Secret') String get secret;
/// Create a copy of QuickConnectSecret
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickConnectSecretCopyWith<QuickConnectSecret> get copyWith => _$QuickConnectSecretCopyWithImpl<QuickConnectSecret>(this as QuickConnectSecret, _$identity);

  /// Serializes this QuickConnectSecret to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickConnectSecret&&(identical(other.secret, secret) || other.secret == secret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret);

@override
String toString() {
  return 'QuickConnectSecret(secret: $secret)';
}


}

/// @nodoc
abstract mixin class $QuickConnectSecretCopyWith<$Res>  {
  factory $QuickConnectSecretCopyWith(QuickConnectSecret value, $Res Function(QuickConnectSecret) _then) = _$QuickConnectSecretCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Secret') String secret
});




}
/// @nodoc
class _$QuickConnectSecretCopyWithImpl<$Res>
    implements $QuickConnectSecretCopyWith<$Res> {
  _$QuickConnectSecretCopyWithImpl(this._self, this._then);

  final QuickConnectSecret _self;
  final $Res Function(QuickConnectSecret) _then;

/// Create a copy of QuickConnectSecret
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? secret = null,}) {
  return _then(_self.copyWith(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickConnectSecret].
extension QuickConnectSecretPatterns on QuickConnectSecret {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickConnectSecret value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickConnectSecret() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickConnectSecret value)  $default,){
final _that = this;
switch (_that) {
case _QuickConnectSecret():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickConnectSecret value)?  $default,){
final _that = this;
switch (_that) {
case _QuickConnectSecret() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Secret')  String secret)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickConnectSecret() when $default != null:
return $default(_that.secret);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Secret')  String secret)  $default,) {final _that = this;
switch (_that) {
case _QuickConnectSecret():
return $default(_that.secret);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Secret')  String secret)?  $default,) {final _that = this;
switch (_that) {
case _QuickConnectSecret() when $default != null:
return $default(_that.secret);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _QuickConnectSecret implements QuickConnectSecret {
  const _QuickConnectSecret({@JsonKey(name: 'Secret') required this.secret});
  

@override@JsonKey(name: 'Secret') final  String secret;

/// Create a copy of QuickConnectSecret
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickConnectSecretCopyWith<_QuickConnectSecret> get copyWith => __$QuickConnectSecretCopyWithImpl<_QuickConnectSecret>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuickConnectSecretToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickConnectSecret&&(identical(other.secret, secret) || other.secret == secret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret);

@override
String toString() {
  return 'QuickConnectSecret(secret: $secret)';
}


}

/// @nodoc
abstract mixin class _$QuickConnectSecretCopyWith<$Res> implements $QuickConnectSecretCopyWith<$Res> {
  factory _$QuickConnectSecretCopyWith(_QuickConnectSecret value, $Res Function(_QuickConnectSecret) _then) = __$QuickConnectSecretCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Secret') String secret
});




}
/// @nodoc
class __$QuickConnectSecretCopyWithImpl<$Res>
    implements _$QuickConnectSecretCopyWith<$Res> {
  __$QuickConnectSecretCopyWithImpl(this._self, this._then);

  final _QuickConnectSecret _self;
  final $Res Function(_QuickConnectSecret) _then;

/// Create a copy of QuickConnectSecret
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? secret = null,}) {
  return _then(_QuickConnectSecret(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
