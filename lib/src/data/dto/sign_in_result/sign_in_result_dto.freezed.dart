// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_in_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignInResultDTO {

@JsonKey(name: 'User') UserDTO get user;@JsonKey(name: 'SessionInfo') SessionInfoDTO get sessionInfo;@JsonKey(name: 'AccessToken') String get accessToken;@JsonKey(name: 'ServerId') String get serverId;
/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignInResultDTOCopyWith<SignInResultDTO> get copyWith => _$SignInResultDTOCopyWithImpl<SignInResultDTO>(this as SignInResultDTO, _$identity);

  /// Serializes this SignInResultDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInResultDTO&&(identical(other.user, user) || other.user == user)&&(identical(other.sessionInfo, sessionInfo) || other.sessionInfo == sessionInfo)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.serverId, serverId) || other.serverId == serverId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,sessionInfo,accessToken,serverId);

@override
String toString() {
  return 'SignInResultDTO(user: $user, sessionInfo: $sessionInfo, accessToken: $accessToken, serverId: $serverId)';
}


}

/// @nodoc
abstract mixin class $SignInResultDTOCopyWith<$Res>  {
  factory $SignInResultDTOCopyWith(SignInResultDTO value, $Res Function(SignInResultDTO) _then) = _$SignInResultDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'User') UserDTO user,@JsonKey(name: 'SessionInfo') SessionInfoDTO sessionInfo,@JsonKey(name: 'AccessToken') String accessToken,@JsonKey(name: 'ServerId') String serverId
});


$UserDTOCopyWith<$Res> get user;$SessionInfoDTOCopyWith<$Res> get sessionInfo;

}
/// @nodoc
class _$SignInResultDTOCopyWithImpl<$Res>
    implements $SignInResultDTOCopyWith<$Res> {
  _$SignInResultDTOCopyWithImpl(this._self, this._then);

  final SignInResultDTO _self;
  final $Res Function(SignInResultDTO) _then;

/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? sessionInfo = null,Object? accessToken = null,Object? serverId = null,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserDTO,sessionInfo: null == sessionInfo ? _self.sessionInfo : sessionInfo // ignore: cast_nullable_to_non_nullable
as SessionInfoDTO,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDTOCopyWith<$Res> get user {
  
  return $UserDTOCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionInfoDTOCopyWith<$Res> get sessionInfo {
  
  return $SessionInfoDTOCopyWith<$Res>(_self.sessionInfo, (value) {
    return _then(_self.copyWith(sessionInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [SignInResultDTO].
extension SignInResultDTOPatterns on SignInResultDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignInResultDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignInResultDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignInResultDTO value)  $default,){
final _that = this;
switch (_that) {
case _SignInResultDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignInResultDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SignInResultDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'User')  UserDTO user, @JsonKey(name: 'SessionInfo')  SessionInfoDTO sessionInfo, @JsonKey(name: 'AccessToken')  String accessToken, @JsonKey(name: 'ServerId')  String serverId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignInResultDTO() when $default != null:
return $default(_that.user,_that.sessionInfo,_that.accessToken,_that.serverId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'User')  UserDTO user, @JsonKey(name: 'SessionInfo')  SessionInfoDTO sessionInfo, @JsonKey(name: 'AccessToken')  String accessToken, @JsonKey(name: 'ServerId')  String serverId)  $default,) {final _that = this;
switch (_that) {
case _SignInResultDTO():
return $default(_that.user,_that.sessionInfo,_that.accessToken,_that.serverId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'User')  UserDTO user, @JsonKey(name: 'SessionInfo')  SessionInfoDTO sessionInfo, @JsonKey(name: 'AccessToken')  String accessToken, @JsonKey(name: 'ServerId')  String serverId)?  $default,) {final _that = this;
switch (_that) {
case _SignInResultDTO() when $default != null:
return $default(_that.user,_that.sessionInfo,_that.accessToken,_that.serverId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignInResultDTO implements SignInResultDTO {
  const _SignInResultDTO({@JsonKey(name: 'User') required this.user, @JsonKey(name: 'SessionInfo') required this.sessionInfo, @JsonKey(name: 'AccessToken') required this.accessToken, @JsonKey(name: 'ServerId') required this.serverId});
  factory _SignInResultDTO.fromJson(Map<String, dynamic> json) => _$SignInResultDTOFromJson(json);

@override@JsonKey(name: 'User') final  UserDTO user;
@override@JsonKey(name: 'SessionInfo') final  SessionInfoDTO sessionInfo;
@override@JsonKey(name: 'AccessToken') final  String accessToken;
@override@JsonKey(name: 'ServerId') final  String serverId;

/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignInResultDTOCopyWith<_SignInResultDTO> get copyWith => __$SignInResultDTOCopyWithImpl<_SignInResultDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignInResultDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInResultDTO&&(identical(other.user, user) || other.user == user)&&(identical(other.sessionInfo, sessionInfo) || other.sessionInfo == sessionInfo)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.serverId, serverId) || other.serverId == serverId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,sessionInfo,accessToken,serverId);

@override
String toString() {
  return 'SignInResultDTO(user: $user, sessionInfo: $sessionInfo, accessToken: $accessToken, serverId: $serverId)';
}


}

/// @nodoc
abstract mixin class _$SignInResultDTOCopyWith<$Res> implements $SignInResultDTOCopyWith<$Res> {
  factory _$SignInResultDTOCopyWith(_SignInResultDTO value, $Res Function(_SignInResultDTO) _then) = __$SignInResultDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'User') UserDTO user,@JsonKey(name: 'SessionInfo') SessionInfoDTO sessionInfo,@JsonKey(name: 'AccessToken') String accessToken,@JsonKey(name: 'ServerId') String serverId
});


@override $UserDTOCopyWith<$Res> get user;@override $SessionInfoDTOCopyWith<$Res> get sessionInfo;

}
/// @nodoc
class __$SignInResultDTOCopyWithImpl<$Res>
    implements _$SignInResultDTOCopyWith<$Res> {
  __$SignInResultDTOCopyWithImpl(this._self, this._then);

  final _SignInResultDTO _self;
  final $Res Function(_SignInResultDTO) _then;

/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? sessionInfo = null,Object? accessToken = null,Object? serverId = null,}) {
  return _then(_SignInResultDTO(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserDTO,sessionInfo: null == sessionInfo ? _self.sessionInfo : sessionInfo // ignore: cast_nullable_to_non_nullable
as SessionInfoDTO,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,serverId: null == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDTOCopyWith<$Res> get user {
  
  return $UserDTOCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SignInResultDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionInfoDTOCopyWith<$Res> get sessionInfo {
  
  return $SessionInfoDTOCopyWith<$Res>(_self.sessionInfo, (value) {
    return _then(_self.copyWith(sessionInfo: value));
  });
}
}

// dart format on
