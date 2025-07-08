// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserCredentials {

@JsonKey(name: 'Username') String get username;@JsonKey(name: 'Pw') String get pw;@JsonKey(includeFromJson: false) String get serverUrl;
/// Create a copy of UserCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCredentialsCopyWith<UserCredentials> get copyWith => _$UserCredentialsCopyWithImpl<UserCredentials>(this as UserCredentials, _$identity);

  /// Serializes this UserCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCredentials&&(identical(other.username, username) || other.username == username)&&(identical(other.pw, pw) || other.pw == pw)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,pw,serverUrl);

@override
String toString() {
  return 'UserCredentials(username: $username, pw: $pw, serverUrl: $serverUrl)';
}


}

/// @nodoc
abstract mixin class $UserCredentialsCopyWith<$Res>  {
  factory $UserCredentialsCopyWith(UserCredentials value, $Res Function(UserCredentials) _then) = _$UserCredentialsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Username') String username,@JsonKey(name: 'Pw') String pw,@JsonKey(includeFromJson: false) String serverUrl
});




}
/// @nodoc
class _$UserCredentialsCopyWithImpl<$Res>
    implements $UserCredentialsCopyWith<$Res> {
  _$UserCredentialsCopyWithImpl(this._self, this._then);

  final UserCredentials _self;
  final $Res Function(UserCredentials) _then;

/// Create a copy of UserCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? pw = null,Object? serverUrl = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,pw: null == pw ? _self.pw : pw // ignore: cast_nullable_to_non_nullable
as String,serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserCredentials].
extension UserCredentialsPatterns on UserCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCredentials value)  $default,){
final _that = this;
switch (_that) {
case _UserCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _UserCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Username')  String username, @JsonKey(name: 'Pw')  String pw, @JsonKey(includeFromJson: false)  String serverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCredentials() when $default != null:
return $default(_that.username,_that.pw,_that.serverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Username')  String username, @JsonKey(name: 'Pw')  String pw, @JsonKey(includeFromJson: false)  String serverUrl)  $default,) {final _that = this;
switch (_that) {
case _UserCredentials():
return $default(_that.username,_that.pw,_that.serverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Username')  String username, @JsonKey(name: 'Pw')  String pw, @JsonKey(includeFromJson: false)  String serverUrl)?  $default,) {final _that = this;
switch (_that) {
case _UserCredentials() when $default != null:
return $default(_that.username,_that.pw,_that.serverUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _UserCredentials implements UserCredentials {
  const _UserCredentials({@JsonKey(name: 'Username') required this.username, @JsonKey(name: 'Pw') required this.pw, @JsonKey(includeFromJson: false) required this.serverUrl});
  

@override@JsonKey(name: 'Username') final  String username;
@override@JsonKey(name: 'Pw') final  String pw;
@override@JsonKey(includeFromJson: false) final  String serverUrl;

/// Create a copy of UserCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCredentialsCopyWith<_UserCredentials> get copyWith => __$UserCredentialsCopyWithImpl<_UserCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCredentials&&(identical(other.username, username) || other.username == username)&&(identical(other.pw, pw) || other.pw == pw)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,pw,serverUrl);

@override
String toString() {
  return 'UserCredentials(username: $username, pw: $pw, serverUrl: $serverUrl)';
}


}

/// @nodoc
abstract mixin class _$UserCredentialsCopyWith<$Res> implements $UserCredentialsCopyWith<$Res> {
  factory _$UserCredentialsCopyWith(_UserCredentials value, $Res Function(_UserCredentials) _then) = __$UserCredentialsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Username') String username,@JsonKey(name: 'Pw') String pw,@JsonKey(includeFromJson: false) String serverUrl
});




}
/// @nodoc
class __$UserCredentialsCopyWithImpl<$Res>
    implements _$UserCredentialsCopyWith<$Res> {
  __$UserCredentialsCopyWithImpl(this._self, this._then);

  final _UserCredentials _self;
  final $Res Function(_UserCredentials) _then;

/// Create a copy of UserCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? pw = null,Object? serverUrl = null,}) {
  return _then(_UserCredentials(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,pw: null == pw ? _self.pw : pw // ignore: cast_nullable_to_non_nullable
as String,serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
