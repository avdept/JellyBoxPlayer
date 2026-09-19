// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subsonic_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubsonicErrorDTO {

 int? get code; String? get message;
/// Create a copy of SubsonicErrorDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicErrorDTOCopyWith<SubsonicErrorDTO> get copyWith => _$SubsonicErrorDTOCopyWithImpl<SubsonicErrorDTO>(this as SubsonicErrorDTO, _$identity);

  /// Serializes this SubsonicErrorDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicErrorDTO&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'SubsonicErrorDTO(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $SubsonicErrorDTOCopyWith<$Res>  {
  factory $SubsonicErrorDTOCopyWith(SubsonicErrorDTO value, $Res Function(SubsonicErrorDTO) _then) = _$SubsonicErrorDTOCopyWithImpl;
@useResult
$Res call({
 int? code, String? message
});




}
/// @nodoc
class _$SubsonicErrorDTOCopyWithImpl<$Res>
    implements $SubsonicErrorDTOCopyWith<$Res> {
  _$SubsonicErrorDTOCopyWithImpl(this._self, this._then);

  final SubsonicErrorDTO _self;
  final $Res Function(SubsonicErrorDTO) _then;

/// Create a copy of SubsonicErrorDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicErrorDTO].
extension SubsonicErrorDTOPatterns on SubsonicErrorDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicErrorDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicErrorDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicErrorDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicErrorDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicErrorDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicErrorDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? code,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicErrorDTO() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? code,  String? message)  $default,) {final _that = this;
switch (_that) {
case _SubsonicErrorDTO():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? code,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicErrorDTO() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicErrorDTO implements SubsonicErrorDTO {
  const _SubsonicErrorDTO({this.code, this.message});
  factory _SubsonicErrorDTO.fromJson(Map<String, dynamic> json) => _$SubsonicErrorDTOFromJson(json);

@override final  int? code;
@override final  String? message;

/// Create a copy of SubsonicErrorDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicErrorDTOCopyWith<_SubsonicErrorDTO> get copyWith => __$SubsonicErrorDTOCopyWithImpl<_SubsonicErrorDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicErrorDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicErrorDTO&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'SubsonicErrorDTO(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$SubsonicErrorDTOCopyWith<$Res> implements $SubsonicErrorDTOCopyWith<$Res> {
  factory _$SubsonicErrorDTOCopyWith(_SubsonicErrorDTO value, $Res Function(_SubsonicErrorDTO) _then) = __$SubsonicErrorDTOCopyWithImpl;
@override @useResult
$Res call({
 int? code, String? message
});




}
/// @nodoc
class __$SubsonicErrorDTOCopyWithImpl<$Res>
    implements _$SubsonicErrorDTOCopyWith<$Res> {
  __$SubsonicErrorDTOCopyWithImpl(this._self, this._then);

  final _SubsonicErrorDTO _self;
  final $Res Function(_SubsonicErrorDTO) _then;

/// Create a copy of SubsonicErrorDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? message = freezed,}) {
  return _then(_SubsonicErrorDTO(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubsonicEnvelopeDTO {

 String get status; String? get version; String? get type; String? get serverVersion; bool? get openSubsonic; SubsonicErrorDTO? get error;
/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicEnvelopeDTOCopyWith<SubsonicEnvelopeDTO> get copyWith => _$SubsonicEnvelopeDTOCopyWithImpl<SubsonicEnvelopeDTO>(this as SubsonicEnvelopeDTO, _$identity);

  /// Serializes this SubsonicEnvelopeDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicEnvelopeDTO&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.openSubsonic, openSubsonic) || other.openSubsonic == openSubsonic)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,version,type,serverVersion,openSubsonic,error);

@override
String toString() {
  return 'SubsonicEnvelopeDTO(status: $status, version: $version, type: $type, serverVersion: $serverVersion, openSubsonic: $openSubsonic, error: $error)';
}


}

/// @nodoc
abstract mixin class $SubsonicEnvelopeDTOCopyWith<$Res>  {
  factory $SubsonicEnvelopeDTOCopyWith(SubsonicEnvelopeDTO value, $Res Function(SubsonicEnvelopeDTO) _then) = _$SubsonicEnvelopeDTOCopyWithImpl;
@useResult
$Res call({
 String status, String? version, String? type, String? serverVersion, bool? openSubsonic, SubsonicErrorDTO? error
});


$SubsonicErrorDTOCopyWith<$Res>? get error;

}
/// @nodoc
class _$SubsonicEnvelopeDTOCopyWithImpl<$Res>
    implements $SubsonicEnvelopeDTOCopyWith<$Res> {
  _$SubsonicEnvelopeDTOCopyWithImpl(this._self, this._then);

  final SubsonicEnvelopeDTO _self;
  final $Res Function(SubsonicEnvelopeDTO) _then;

/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? version = freezed,Object? type = freezed,Object? serverVersion = freezed,Object? openSubsonic = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,openSubsonic: freezed == openSubsonic ? _self.openSubsonic : openSubsonic // ignore: cast_nullable_to_non_nullable
as bool?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as SubsonicErrorDTO?,
  ));
}
/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubsonicErrorDTOCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $SubsonicErrorDTOCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubsonicEnvelopeDTO].
extension SubsonicEnvelopeDTOPatterns on SubsonicEnvelopeDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicEnvelopeDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicEnvelopeDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicEnvelopeDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? version,  String? type,  String? serverVersion,  bool? openSubsonic,  SubsonicErrorDTO? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO() when $default != null:
return $default(_that.status,_that.version,_that.type,_that.serverVersion,_that.openSubsonic,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? version,  String? type,  String? serverVersion,  bool? openSubsonic,  SubsonicErrorDTO? error)  $default,) {final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO():
return $default(_that.status,_that.version,_that.type,_that.serverVersion,_that.openSubsonic,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? version,  String? type,  String? serverVersion,  bool? openSubsonic,  SubsonicErrorDTO? error)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicEnvelopeDTO() when $default != null:
return $default(_that.status,_that.version,_that.type,_that.serverVersion,_that.openSubsonic,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicEnvelopeDTO extends SubsonicEnvelopeDTO {
  const _SubsonicEnvelopeDTO({this.status = '', this.version, this.type, this.serverVersion, this.openSubsonic, this.error}): super._();
  factory _SubsonicEnvelopeDTO.fromJson(Map<String, dynamic> json) => _$SubsonicEnvelopeDTOFromJson(json);

@override@JsonKey() final  String status;
@override final  String? version;
@override final  String? type;
@override final  String? serverVersion;
@override final  bool? openSubsonic;
@override final  SubsonicErrorDTO? error;

/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicEnvelopeDTOCopyWith<_SubsonicEnvelopeDTO> get copyWith => __$SubsonicEnvelopeDTOCopyWithImpl<_SubsonicEnvelopeDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicEnvelopeDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicEnvelopeDTO&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.openSubsonic, openSubsonic) || other.openSubsonic == openSubsonic)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,version,type,serverVersion,openSubsonic,error);

@override
String toString() {
  return 'SubsonicEnvelopeDTO(status: $status, version: $version, type: $type, serverVersion: $serverVersion, openSubsonic: $openSubsonic, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SubsonicEnvelopeDTOCopyWith<$Res> implements $SubsonicEnvelopeDTOCopyWith<$Res> {
  factory _$SubsonicEnvelopeDTOCopyWith(_SubsonicEnvelopeDTO value, $Res Function(_SubsonicEnvelopeDTO) _then) = __$SubsonicEnvelopeDTOCopyWithImpl;
@override @useResult
$Res call({
 String status, String? version, String? type, String? serverVersion, bool? openSubsonic, SubsonicErrorDTO? error
});


@override $SubsonicErrorDTOCopyWith<$Res>? get error;

}
/// @nodoc
class __$SubsonicEnvelopeDTOCopyWithImpl<$Res>
    implements _$SubsonicEnvelopeDTOCopyWith<$Res> {
  __$SubsonicEnvelopeDTOCopyWithImpl(this._self, this._then);

  final _SubsonicEnvelopeDTO _self;
  final $Res Function(_SubsonicEnvelopeDTO) _then;

/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? version = freezed,Object? type = freezed,Object? serverVersion = freezed,Object? openSubsonic = freezed,Object? error = freezed,}) {
  return _then(_SubsonicEnvelopeDTO(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,openSubsonic: freezed == openSubsonic ? _self.openSubsonic : openSubsonic // ignore: cast_nullable_to_non_nullable
as bool?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as SubsonicErrorDTO?,
  ));
}

/// Create a copy of SubsonicEnvelopeDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubsonicErrorDTOCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $SubsonicErrorDTOCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// @nodoc
mixin _$SubsonicNamedDTO {

 String get name;
/// Create a copy of SubsonicNamedDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicNamedDTOCopyWith<SubsonicNamedDTO> get copyWith => _$SubsonicNamedDTOCopyWithImpl<SubsonicNamedDTO>(this as SubsonicNamedDTO, _$identity);

  /// Serializes this SubsonicNamedDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicNamedDTO&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'SubsonicNamedDTO(name: $name)';
}


}

/// @nodoc
abstract mixin class $SubsonicNamedDTOCopyWith<$Res>  {
  factory $SubsonicNamedDTOCopyWith(SubsonicNamedDTO value, $Res Function(SubsonicNamedDTO) _then) = _$SubsonicNamedDTOCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$SubsonicNamedDTOCopyWithImpl<$Res>
    implements $SubsonicNamedDTOCopyWith<$Res> {
  _$SubsonicNamedDTOCopyWithImpl(this._self, this._then);

  final SubsonicNamedDTO _self;
  final $Res Function(SubsonicNamedDTO) _then;

/// Create a copy of SubsonicNamedDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicNamedDTO].
extension SubsonicNamedDTOPatterns on SubsonicNamedDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicNamedDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicNamedDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicNamedDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicNamedDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicNamedDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicNamedDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicNamedDTO() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _SubsonicNamedDTO():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicNamedDTO() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicNamedDTO implements SubsonicNamedDTO {
  const _SubsonicNamedDTO({this.name = ''});
  factory _SubsonicNamedDTO.fromJson(Map<String, dynamic> json) => _$SubsonicNamedDTOFromJson(json);

@override@JsonKey() final  String name;

/// Create a copy of SubsonicNamedDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicNamedDTOCopyWith<_SubsonicNamedDTO> get copyWith => __$SubsonicNamedDTOCopyWithImpl<_SubsonicNamedDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicNamedDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicNamedDTO&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'SubsonicNamedDTO(name: $name)';
}


}

/// @nodoc
abstract mixin class _$SubsonicNamedDTOCopyWith<$Res> implements $SubsonicNamedDTOCopyWith<$Res> {
  factory _$SubsonicNamedDTOCopyWith(_SubsonicNamedDTO value, $Res Function(_SubsonicNamedDTO) _then) = __$SubsonicNamedDTOCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$SubsonicNamedDTOCopyWithImpl<$Res>
    implements _$SubsonicNamedDTOCopyWith<$Res> {
  __$SubsonicNamedDTOCopyWithImpl(this._self, this._then);

  final _SubsonicNamedDTO _self;
  final $Res Function(_SubsonicNamedDTO) _then;

/// Create a copy of SubsonicNamedDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_SubsonicNamedDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubsonicArtistRefDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id; String get name;
/// Create a copy of SubsonicArtistRefDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicArtistRefDTOCopyWith<SubsonicArtistRefDTO> get copyWith => _$SubsonicArtistRefDTOCopyWithImpl<SubsonicArtistRefDTO>(this as SubsonicArtistRefDTO, _$identity);

  /// Serializes this SubsonicArtistRefDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicArtistRefDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SubsonicArtistRefDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $SubsonicArtistRefDTOCopyWith<$Res>  {
  factory $SubsonicArtistRefDTOCopyWith(SubsonicArtistRefDTO value, $Res Function(SubsonicArtistRefDTO) _then) = _$SubsonicArtistRefDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name
});




}
/// @nodoc
class _$SubsonicArtistRefDTOCopyWithImpl<$Res>
    implements $SubsonicArtistRefDTOCopyWith<$Res> {
  _$SubsonicArtistRefDTOCopyWithImpl(this._self, this._then);

  final SubsonicArtistRefDTO _self;
  final $Res Function(SubsonicArtistRefDTO) _then;

/// Create a copy of SubsonicArtistRefDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicArtistRefDTO].
extension SubsonicArtistRefDTOPatterns on SubsonicArtistRefDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicArtistRefDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicArtistRefDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicArtistRefDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistRefDTO() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicArtistRefDTO implements SubsonicArtistRefDTO {
  const _SubsonicArtistRefDTO({@JsonKey(fromJson: subsonicIdFromJson) this.id = '', this.name = ''});
  factory _SubsonicArtistRefDTO.fromJson(Map<String, dynamic> json) => _$SubsonicArtistRefDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey() final  String name;

/// Create a copy of SubsonicArtistRefDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicArtistRefDTOCopyWith<_SubsonicArtistRefDTO> get copyWith => __$SubsonicArtistRefDTOCopyWithImpl<_SubsonicArtistRefDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicArtistRefDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicArtistRefDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SubsonicArtistRefDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SubsonicArtistRefDTOCopyWith<$Res> implements $SubsonicArtistRefDTOCopyWith<$Res> {
  factory _$SubsonicArtistRefDTOCopyWith(_SubsonicArtistRefDTO value, $Res Function(_SubsonicArtistRefDTO) _then) = __$SubsonicArtistRefDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name
});




}
/// @nodoc
class __$SubsonicArtistRefDTOCopyWithImpl<$Res>
    implements _$SubsonicArtistRefDTOCopyWith<$Res> {
  __$SubsonicArtistRefDTOCopyWithImpl(this._self, this._then);

  final _SubsonicArtistRefDTO _self;
  final $Res Function(_SubsonicArtistRefDTO) _then;

/// Create a copy of SubsonicArtistRefDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_SubsonicArtistRefDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubsonicChildDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get parent; bool get isDir; String get title; String? get album; String? get artist; int? get track; int? get year; String? get genre;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get coverArt; int? get size; String? get contentType; String? get suffix; String? get transcodedContentType; String? get transcodedSuffix; int? get duration; int? get bitRate; int? get bitDepth; int? get samplingRate; int? get channelCount; String? get path; int? get discNumber; DateTime? get created;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get albumId;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get artistId; String? get type; String? get starred; int get playCount; String? get played; int? get userRating; String? get musicBrainzId; String? get displayArtist; String? get displayAlbumArtist; String? get sortName; List<SubsonicNamedDTO> get genres; List<SubsonicArtistRefDTO> get artists; List<SubsonicArtistRefDTO> get albumArtists;
/// Create a copy of SubsonicChildDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicChildDTOCopyWith<SubsonicChildDTO> get copyWith => _$SubsonicChildDTOCopyWithImpl<SubsonicChildDTO>(this as SubsonicChildDTO, _$identity);

  /// Serializes this SubsonicChildDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicChildDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.parent, parent) || other.parent == parent)&&(identical(other.isDir, isDir) || other.isDir == isDir)&&(identical(other.title, title) || other.title == title)&&(identical(other.album, album) || other.album == album)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.track, track) || other.track == track)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.size, size) || other.size == size)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.suffix, suffix) || other.suffix == suffix)&&(identical(other.transcodedContentType, transcodedContentType) || other.transcodedContentType == transcodedContentType)&&(identical(other.transcodedSuffix, transcodedSuffix) || other.transcodedSuffix == transcodedSuffix)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.samplingRate, samplingRate) || other.samplingRate == samplingRate)&&(identical(other.channelCount, channelCount) || other.channelCount == channelCount)&&(identical(other.path, path) || other.path == path)&&(identical(other.discNumber, discNumber) || other.discNumber == discNumber)&&(identical(other.created, created) || other.created == created)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.type, type) || other.type == type)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.played, played) || other.played == played)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.displayAlbumArtist, displayAlbumArtist) || other.displayAlbumArtist == displayAlbumArtist)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.artists, artists)&&const DeepCollectionEquality().equals(other.albumArtists, albumArtists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,parent,isDir,title,album,artist,track,year,genre,coverArt,size,contentType,suffix,transcodedContentType,transcodedSuffix,duration,bitRate,bitDepth,samplingRate,channelCount,path,discNumber,created,albumId,artistId,type,starred,playCount,played,userRating,musicBrainzId,displayArtist,displayAlbumArtist,sortName,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(artists),const DeepCollectionEquality().hash(albumArtists)]);

@override
String toString() {
  return 'SubsonicChildDTO(id: $id, parent: $parent, isDir: $isDir, title: $title, album: $album, artist: $artist, track: $track, year: $year, genre: $genre, coverArt: $coverArt, size: $size, contentType: $contentType, suffix: $suffix, transcodedContentType: $transcodedContentType, transcodedSuffix: $transcodedSuffix, duration: $duration, bitRate: $bitRate, bitDepth: $bitDepth, samplingRate: $samplingRate, channelCount: $channelCount, path: $path, discNumber: $discNumber, created: $created, albumId: $albumId, artistId: $artistId, type: $type, starred: $starred, playCount: $playCount, played: $played, userRating: $userRating, musicBrainzId: $musicBrainzId, displayArtist: $displayArtist, displayAlbumArtist: $displayAlbumArtist, sortName: $sortName, genres: $genres, artists: $artists, albumArtists: $albumArtists)';
}


}

/// @nodoc
abstract mixin class $SubsonicChildDTOCopyWith<$Res>  {
  factory $SubsonicChildDTOCopyWith(SubsonicChildDTO value, $Res Function(SubsonicChildDTO) _then) = _$SubsonicChildDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? parent, bool isDir, String title, String? album, String? artist, int? track, int? year, String? genre,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, int? size, String? contentType, String? suffix, String? transcodedContentType, String? transcodedSuffix, int? duration, int? bitRate, int? bitDepth, int? samplingRate, int? channelCount, String? path, int? discNumber, DateTime? created,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? albumId,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId, String? type, String? starred, int playCount, String? played, int? userRating, String? musicBrainzId, String? displayArtist, String? displayAlbumArtist, String? sortName, List<SubsonicNamedDTO> genres, List<SubsonicArtistRefDTO> artists, List<SubsonicArtistRefDTO> albumArtists
});




}
/// @nodoc
class _$SubsonicChildDTOCopyWithImpl<$Res>
    implements $SubsonicChildDTOCopyWith<$Res> {
  _$SubsonicChildDTOCopyWithImpl(this._self, this._then);

  final SubsonicChildDTO _self;
  final $Res Function(SubsonicChildDTO) _then;

/// Create a copy of SubsonicChildDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parent = freezed,Object? isDir = null,Object? title = null,Object? album = freezed,Object? artist = freezed,Object? track = freezed,Object? year = freezed,Object? genre = freezed,Object? coverArt = freezed,Object? size = freezed,Object? contentType = freezed,Object? suffix = freezed,Object? transcodedContentType = freezed,Object? transcodedSuffix = freezed,Object? duration = freezed,Object? bitRate = freezed,Object? bitDepth = freezed,Object? samplingRate = freezed,Object? channelCount = freezed,Object? path = freezed,Object? discNumber = freezed,Object? created = freezed,Object? albumId = freezed,Object? artistId = freezed,Object? type = freezed,Object? starred = freezed,Object? playCount = null,Object? played = freezed,Object? userRating = freezed,Object? musicBrainzId = freezed,Object? displayArtist = freezed,Object? displayAlbumArtist = freezed,Object? sortName = freezed,Object? genres = null,Object? artists = null,Object? albumArtists = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,suffix: freezed == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String?,transcodedContentType: freezed == transcodedContentType ? _self.transcodedContentType : transcodedContentType // ignore: cast_nullable_to_non_nullable
as String?,transcodedSuffix: freezed == transcodedSuffix ? _self.transcodedSuffix : transcodedSuffix // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as int?,samplingRate: freezed == samplingRate ? _self.samplingRate : samplingRate // ignore: cast_nullable_to_non_nullable
as int?,channelCount: freezed == channelCount ? _self.channelCount : channelCount // ignore: cast_nullable_to_non_nullable
as int?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,played: freezed == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,displayAlbumArtist: freezed == displayAlbumArtist ? _self.displayAlbumArtist : displayAlbumArtist // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<SubsonicNamedDTO>,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,albumArtists: null == albumArtists ? _self.albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicChildDTO].
extension SubsonicChildDTOPatterns on SubsonicChildDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicChildDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicChildDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicChildDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicChildDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicChildDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicChildDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? parent,  bool isDir,  String title,  String? album,  String? artist,  int? track,  int? year,  String? genre, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int? size,  String? contentType,  String? suffix,  String? transcodedContentType,  String? transcodedSuffix,  int? duration,  int? bitRate,  int? bitDepth,  int? samplingRate,  int? channelCount,  String? path,  int? discNumber,  DateTime? created, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? albumId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId,  String? type,  String? starred,  int playCount,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? displayAlbumArtist,  String? sortName,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicArtistRefDTO> albumArtists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicChildDTO() when $default != null:
return $default(_that.id,_that.parent,_that.isDir,_that.title,_that.album,_that.artist,_that.track,_that.year,_that.genre,_that.coverArt,_that.size,_that.contentType,_that.suffix,_that.transcodedContentType,_that.transcodedSuffix,_that.duration,_that.bitRate,_that.bitDepth,_that.samplingRate,_that.channelCount,_that.path,_that.discNumber,_that.created,_that.albumId,_that.artistId,_that.type,_that.starred,_that.playCount,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.displayAlbumArtist,_that.sortName,_that.genres,_that.artists,_that.albumArtists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? parent,  bool isDir,  String title,  String? album,  String? artist,  int? track,  int? year,  String? genre, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int? size,  String? contentType,  String? suffix,  String? transcodedContentType,  String? transcodedSuffix,  int? duration,  int? bitRate,  int? bitDepth,  int? samplingRate,  int? channelCount,  String? path,  int? discNumber,  DateTime? created, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? albumId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId,  String? type,  String? starred,  int playCount,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? displayAlbumArtist,  String? sortName,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicArtistRefDTO> albumArtists)  $default,) {final _that = this;
switch (_that) {
case _SubsonicChildDTO():
return $default(_that.id,_that.parent,_that.isDir,_that.title,_that.album,_that.artist,_that.track,_that.year,_that.genre,_that.coverArt,_that.size,_that.contentType,_that.suffix,_that.transcodedContentType,_that.transcodedSuffix,_that.duration,_that.bitRate,_that.bitDepth,_that.samplingRate,_that.channelCount,_that.path,_that.discNumber,_that.created,_that.albumId,_that.artistId,_that.type,_that.starred,_that.playCount,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.displayAlbumArtist,_that.sortName,_that.genres,_that.artists,_that.albumArtists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? parent,  bool isDir,  String title,  String? album,  String? artist,  int? track,  int? year,  String? genre, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int? size,  String? contentType,  String? suffix,  String? transcodedContentType,  String? transcodedSuffix,  int? duration,  int? bitRate,  int? bitDepth,  int? samplingRate,  int? channelCount,  String? path,  int? discNumber,  DateTime? created, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? albumId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId,  String? type,  String? starred,  int playCount,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? displayAlbumArtist,  String? sortName,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicArtistRefDTO> albumArtists)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicChildDTO() when $default != null:
return $default(_that.id,_that.parent,_that.isDir,_that.title,_that.album,_that.artist,_that.track,_that.year,_that.genre,_that.coverArt,_that.size,_that.contentType,_that.suffix,_that.transcodedContentType,_that.transcodedSuffix,_that.duration,_that.bitRate,_that.bitDepth,_that.samplingRate,_that.channelCount,_that.path,_that.discNumber,_that.created,_that.albumId,_that.artistId,_that.type,_that.starred,_that.playCount,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.displayAlbumArtist,_that.sortName,_that.genres,_that.artists,_that.albumArtists);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicChildDTO implements SubsonicChildDTO {
  const _SubsonicChildDTO({@JsonKey(fromJson: subsonicIdFromJson) required this.id, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.parent, this.isDir = false, this.title = '', this.album, this.artist, this.track, this.year, this.genre, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.coverArt, this.size, this.contentType, this.suffix, this.transcodedContentType, this.transcodedSuffix, this.duration, this.bitRate, this.bitDepth, this.samplingRate, this.channelCount, this.path, this.discNumber, this.created, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.albumId, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.artistId, this.type, this.starred, this.playCount = 0, this.played, this.userRating, this.musicBrainzId, this.displayArtist, this.displayAlbumArtist, this.sortName, final  List<SubsonicNamedDTO> genres = const [], final  List<SubsonicArtistRefDTO> artists = const [], final  List<SubsonicArtistRefDTO> albumArtists = const []}): _genres = genres,_artists = artists,_albumArtists = albumArtists;
  factory _SubsonicChildDTO.fromJson(Map<String, dynamic> json) => _$SubsonicChildDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? parent;
@override@JsonKey() final  bool isDir;
@override@JsonKey() final  String title;
@override final  String? album;
@override final  String? artist;
@override final  int? track;
@override final  int? year;
@override final  String? genre;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? coverArt;
@override final  int? size;
@override final  String? contentType;
@override final  String? suffix;
@override final  String? transcodedContentType;
@override final  String? transcodedSuffix;
@override final  int? duration;
@override final  int? bitRate;
@override final  int? bitDepth;
@override final  int? samplingRate;
@override final  int? channelCount;
@override final  String? path;
@override final  int? discNumber;
@override final  DateTime? created;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? albumId;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? artistId;
@override final  String? type;
@override final  String? starred;
@override@JsonKey() final  int playCount;
@override final  String? played;
@override final  int? userRating;
@override final  String? musicBrainzId;
@override final  String? displayArtist;
@override final  String? displayAlbumArtist;
@override final  String? sortName;
 final  List<SubsonicNamedDTO> _genres;
@override@JsonKey() List<SubsonicNamedDTO> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  List<SubsonicArtistRefDTO> _artists;
@override@JsonKey() List<SubsonicArtistRefDTO> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

 final  List<SubsonicArtistRefDTO> _albumArtists;
@override@JsonKey() List<SubsonicArtistRefDTO> get albumArtists {
  if (_albumArtists is EqualUnmodifiableListView) return _albumArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albumArtists);
}


/// Create a copy of SubsonicChildDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicChildDTOCopyWith<_SubsonicChildDTO> get copyWith => __$SubsonicChildDTOCopyWithImpl<_SubsonicChildDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicChildDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicChildDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.parent, parent) || other.parent == parent)&&(identical(other.isDir, isDir) || other.isDir == isDir)&&(identical(other.title, title) || other.title == title)&&(identical(other.album, album) || other.album == album)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.track, track) || other.track == track)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.size, size) || other.size == size)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.suffix, suffix) || other.suffix == suffix)&&(identical(other.transcodedContentType, transcodedContentType) || other.transcodedContentType == transcodedContentType)&&(identical(other.transcodedSuffix, transcodedSuffix) || other.transcodedSuffix == transcodedSuffix)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.samplingRate, samplingRate) || other.samplingRate == samplingRate)&&(identical(other.channelCount, channelCount) || other.channelCount == channelCount)&&(identical(other.path, path) || other.path == path)&&(identical(other.discNumber, discNumber) || other.discNumber == discNumber)&&(identical(other.created, created) || other.created == created)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.type, type) || other.type == type)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.played, played) || other.played == played)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.displayAlbumArtist, displayAlbumArtist) || other.displayAlbumArtist == displayAlbumArtist)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._artists, _artists)&&const DeepCollectionEquality().equals(other._albumArtists, _albumArtists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,parent,isDir,title,album,artist,track,year,genre,coverArt,size,contentType,suffix,transcodedContentType,transcodedSuffix,duration,bitRate,bitDepth,samplingRate,channelCount,path,discNumber,created,albumId,artistId,type,starred,playCount,played,userRating,musicBrainzId,displayArtist,displayAlbumArtist,sortName,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_albumArtists)]);

@override
String toString() {
  return 'SubsonicChildDTO(id: $id, parent: $parent, isDir: $isDir, title: $title, album: $album, artist: $artist, track: $track, year: $year, genre: $genre, coverArt: $coverArt, size: $size, contentType: $contentType, suffix: $suffix, transcodedContentType: $transcodedContentType, transcodedSuffix: $transcodedSuffix, duration: $duration, bitRate: $bitRate, bitDepth: $bitDepth, samplingRate: $samplingRate, channelCount: $channelCount, path: $path, discNumber: $discNumber, created: $created, albumId: $albumId, artistId: $artistId, type: $type, starred: $starred, playCount: $playCount, played: $played, userRating: $userRating, musicBrainzId: $musicBrainzId, displayArtist: $displayArtist, displayAlbumArtist: $displayAlbumArtist, sortName: $sortName, genres: $genres, artists: $artists, albumArtists: $albumArtists)';
}


}

/// @nodoc
abstract mixin class _$SubsonicChildDTOCopyWith<$Res> implements $SubsonicChildDTOCopyWith<$Res> {
  factory _$SubsonicChildDTOCopyWith(_SubsonicChildDTO value, $Res Function(_SubsonicChildDTO) _then) = __$SubsonicChildDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? parent, bool isDir, String title, String? album, String? artist, int? track, int? year, String? genre,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, int? size, String? contentType, String? suffix, String? transcodedContentType, String? transcodedSuffix, int? duration, int? bitRate, int? bitDepth, int? samplingRate, int? channelCount, String? path, int? discNumber, DateTime? created,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? albumId,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId, String? type, String? starred, int playCount, String? played, int? userRating, String? musicBrainzId, String? displayArtist, String? displayAlbumArtist, String? sortName, List<SubsonicNamedDTO> genres, List<SubsonicArtistRefDTO> artists, List<SubsonicArtistRefDTO> albumArtists
});




}
/// @nodoc
class __$SubsonicChildDTOCopyWithImpl<$Res>
    implements _$SubsonicChildDTOCopyWith<$Res> {
  __$SubsonicChildDTOCopyWithImpl(this._self, this._then);

  final _SubsonicChildDTO _self;
  final $Res Function(_SubsonicChildDTO) _then;

/// Create a copy of SubsonicChildDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parent = freezed,Object? isDir = null,Object? title = null,Object? album = freezed,Object? artist = freezed,Object? track = freezed,Object? year = freezed,Object? genre = freezed,Object? coverArt = freezed,Object? size = freezed,Object? contentType = freezed,Object? suffix = freezed,Object? transcodedContentType = freezed,Object? transcodedSuffix = freezed,Object? duration = freezed,Object? bitRate = freezed,Object? bitDepth = freezed,Object? samplingRate = freezed,Object? channelCount = freezed,Object? path = freezed,Object? discNumber = freezed,Object? created = freezed,Object? albumId = freezed,Object? artistId = freezed,Object? type = freezed,Object? starred = freezed,Object? playCount = null,Object? played = freezed,Object? userRating = freezed,Object? musicBrainzId = freezed,Object? displayArtist = freezed,Object? displayAlbumArtist = freezed,Object? sortName = freezed,Object? genres = null,Object? artists = null,Object? albumArtists = null,}) {
  return _then(_SubsonicChildDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,suffix: freezed == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String?,transcodedContentType: freezed == transcodedContentType ? _self.transcodedContentType : transcodedContentType // ignore: cast_nullable_to_non_nullable
as String?,transcodedSuffix: freezed == transcodedSuffix ? _self.transcodedSuffix : transcodedSuffix // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as int?,samplingRate: freezed == samplingRate ? _self.samplingRate : samplingRate // ignore: cast_nullable_to_non_nullable
as int?,channelCount: freezed == channelCount ? _self.channelCount : channelCount // ignore: cast_nullable_to_non_nullable
as int?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,played: freezed == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,displayAlbumArtist: freezed == displayAlbumArtist ? _self.displayAlbumArtist : displayAlbumArtist // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<SubsonicNamedDTO>,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,albumArtists: null == albumArtists ? _self._albumArtists : albumArtists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicAlbumDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id; String get name; String? get artist;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get artistId;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get coverArt; int get songCount; int? get duration; int get playCount; DateTime? get created; String? get starred; int? get year; String? get genre; String? get played; int? get userRating; String? get musicBrainzId; String? get displayArtist; String? get sortName; bool? get isCompilation; List<SubsonicNamedDTO> get genres; List<SubsonicArtistRefDTO> get artists; List<SubsonicChildDTO> get song;
/// Create a copy of SubsonicAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicAlbumDTOCopyWith<SubsonicAlbumDTO> get copyWith => _$SubsonicAlbumDTOCopyWithImpl<SubsonicAlbumDTO>(this as SubsonicAlbumDTO, _$identity);

  /// Serializes this SubsonicAlbumDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.created, created) || other.created == created)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.played, played) || other.played == played)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&(identical(other.isCompilation, isCompilation) || other.isCompilation == isCompilation)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.artists, artists)&&const DeepCollectionEquality().equals(other.song, song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,artist,artistId,coverArt,songCount,duration,playCount,created,starred,year,genre,played,userRating,musicBrainzId,displayArtist,sortName,isCompilation,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(artists),const DeepCollectionEquality().hash(song)]);

@override
String toString() {
  return 'SubsonicAlbumDTO(id: $id, name: $name, artist: $artist, artistId: $artistId, coverArt: $coverArt, songCount: $songCount, duration: $duration, playCount: $playCount, created: $created, starred: $starred, year: $year, genre: $genre, played: $played, userRating: $userRating, musicBrainzId: $musicBrainzId, displayArtist: $displayArtist, sortName: $sortName, isCompilation: $isCompilation, genres: $genres, artists: $artists, song: $song)';
}


}

/// @nodoc
abstract mixin class $SubsonicAlbumDTOCopyWith<$Res>  {
  factory $SubsonicAlbumDTOCopyWith(SubsonicAlbumDTO value, $Res Function(SubsonicAlbumDTO) _then) = _$SubsonicAlbumDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name, String? artist,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, int songCount, int? duration, int playCount, DateTime? created, String? starred, int? year, String? genre, String? played, int? userRating, String? musicBrainzId, String? displayArtist, String? sortName, bool? isCompilation, List<SubsonicNamedDTO> genres, List<SubsonicArtistRefDTO> artists, List<SubsonicChildDTO> song
});




}
/// @nodoc
class _$SubsonicAlbumDTOCopyWithImpl<$Res>
    implements $SubsonicAlbumDTOCopyWith<$Res> {
  _$SubsonicAlbumDTOCopyWithImpl(this._self, this._then);

  final SubsonicAlbumDTO _self;
  final $Res Function(SubsonicAlbumDTO) _then;

/// Create a copy of SubsonicAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artist = freezed,Object? artistId = freezed,Object? coverArt = freezed,Object? songCount = null,Object? duration = freezed,Object? playCount = null,Object? created = freezed,Object? starred = freezed,Object? year = freezed,Object? genre = freezed,Object? played = freezed,Object? userRating = freezed,Object? musicBrainzId = freezed,Object? displayArtist = freezed,Object? sortName = freezed,Object? isCompilation = freezed,Object? genres = null,Object? artists = null,Object? song = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,played: freezed == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,isCompilation: freezed == isCompilation ? _self.isCompilation : isCompilation // ignore: cast_nullable_to_non_nullable
as bool?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<SubsonicNamedDTO>,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,song: null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicAlbumDTO].
extension SubsonicAlbumDTOPatterns on SubsonicAlbumDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicAlbumDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicAlbumDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicAlbumDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicAlbumDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicAlbumDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicAlbumDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? artist, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int songCount,  int? duration,  int playCount,  DateTime? created,  String? starred,  int? year,  String? genre,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? sortName,  bool? isCompilation,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicChildDTO> song)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.artist,_that.artistId,_that.coverArt,_that.songCount,_that.duration,_that.playCount,_that.created,_that.starred,_that.year,_that.genre,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.sortName,_that.isCompilation,_that.genres,_that.artists,_that.song);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? artist, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int songCount,  int? duration,  int playCount,  DateTime? created,  String? starred,  int? year,  String? genre,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? sortName,  bool? isCompilation,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicChildDTO> song)  $default,) {final _that = this;
switch (_that) {
case _SubsonicAlbumDTO():
return $default(_that.id,_that.name,_that.artist,_that.artistId,_that.coverArt,_that.songCount,_that.duration,_that.playCount,_that.created,_that.starred,_that.year,_that.genre,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.sortName,_that.isCompilation,_that.genres,_that.artists,_that.song);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? artist, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? artistId, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  int songCount,  int? duration,  int playCount,  DateTime? created,  String? starred,  int? year,  String? genre,  String? played,  int? userRating,  String? musicBrainzId,  String? displayArtist,  String? sortName,  bool? isCompilation,  List<SubsonicNamedDTO> genres,  List<SubsonicArtistRefDTO> artists,  List<SubsonicChildDTO> song)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicAlbumDTO() when $default != null:
return $default(_that.id,_that.name,_that.artist,_that.artistId,_that.coverArt,_that.songCount,_that.duration,_that.playCount,_that.created,_that.starred,_that.year,_that.genre,_that.played,_that.userRating,_that.musicBrainzId,_that.displayArtist,_that.sortName,_that.isCompilation,_that.genres,_that.artists,_that.song);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicAlbumDTO implements SubsonicAlbumDTO {
  const _SubsonicAlbumDTO({@JsonKey(fromJson: subsonicIdFromJson) required this.id, this.name = '', this.artist, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.artistId, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.coverArt, this.songCount = 0, this.duration, this.playCount = 0, this.created, this.starred, this.year, this.genre, this.played, this.userRating, this.musicBrainzId, this.displayArtist, this.sortName, this.isCompilation, final  List<SubsonicNamedDTO> genres = const [], final  List<SubsonicArtistRefDTO> artists = const [], final  List<SubsonicChildDTO> song = const []}): _genres = genres,_artists = artists,_song = song;
  factory _SubsonicAlbumDTO.fromJson(Map<String, dynamic> json) => _$SubsonicAlbumDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey() final  String name;
@override final  String? artist;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? artistId;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? coverArt;
@override@JsonKey() final  int songCount;
@override final  int? duration;
@override@JsonKey() final  int playCount;
@override final  DateTime? created;
@override final  String? starred;
@override final  int? year;
@override final  String? genre;
@override final  String? played;
@override final  int? userRating;
@override final  String? musicBrainzId;
@override final  String? displayArtist;
@override final  String? sortName;
@override final  bool? isCompilation;
 final  List<SubsonicNamedDTO> _genres;
@override@JsonKey() List<SubsonicNamedDTO> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  List<SubsonicArtistRefDTO> _artists;
@override@JsonKey() List<SubsonicArtistRefDTO> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

 final  List<SubsonicChildDTO> _song;
@override@JsonKey() List<SubsonicChildDTO> get song {
  if (_song is EqualUnmodifiableListView) return _song;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_song);
}


/// Create a copy of SubsonicAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicAlbumDTOCopyWith<_SubsonicAlbumDTO> get copyWith => __$SubsonicAlbumDTOCopyWithImpl<_SubsonicAlbumDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicAlbumDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicAlbumDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.created, created) || other.created == created)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.played, played) || other.played == played)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&(identical(other.isCompilation, isCompilation) || other.isCompilation == isCompilation)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._artists, _artists)&&const DeepCollectionEquality().equals(other._song, _song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,artist,artistId,coverArt,songCount,duration,playCount,created,starred,year,genre,played,userRating,musicBrainzId,displayArtist,sortName,isCompilation,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_song)]);

@override
String toString() {
  return 'SubsonicAlbumDTO(id: $id, name: $name, artist: $artist, artistId: $artistId, coverArt: $coverArt, songCount: $songCount, duration: $duration, playCount: $playCount, created: $created, starred: $starred, year: $year, genre: $genre, played: $played, userRating: $userRating, musicBrainzId: $musicBrainzId, displayArtist: $displayArtist, sortName: $sortName, isCompilation: $isCompilation, genres: $genres, artists: $artists, song: $song)';
}


}

/// @nodoc
abstract mixin class _$SubsonicAlbumDTOCopyWith<$Res> implements $SubsonicAlbumDTOCopyWith<$Res> {
  factory _$SubsonicAlbumDTOCopyWith(_SubsonicAlbumDTO value, $Res Function(_SubsonicAlbumDTO) _then) = __$SubsonicAlbumDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name, String? artist,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, int songCount, int? duration, int playCount, DateTime? created, String? starred, int? year, String? genre, String? played, int? userRating, String? musicBrainzId, String? displayArtist, String? sortName, bool? isCompilation, List<SubsonicNamedDTO> genres, List<SubsonicArtistRefDTO> artists, List<SubsonicChildDTO> song
});




}
/// @nodoc
class __$SubsonicAlbumDTOCopyWithImpl<$Res>
    implements _$SubsonicAlbumDTOCopyWith<$Res> {
  __$SubsonicAlbumDTOCopyWithImpl(this._self, this._then);

  final _SubsonicAlbumDTO _self;
  final $Res Function(_SubsonicAlbumDTO) _then;

/// Create a copy of SubsonicAlbumDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artist = freezed,Object? artistId = freezed,Object? coverArt = freezed,Object? songCount = null,Object? duration = freezed,Object? playCount = null,Object? created = freezed,Object? starred = freezed,Object? year = freezed,Object? genre = freezed,Object? played = freezed,Object? userRating = freezed,Object? musicBrainzId = freezed,Object? displayArtist = freezed,Object? sortName = freezed,Object? isCompilation = freezed,Object? genres = null,Object? artists = null,Object? song = null,}) {
  return _then(_SubsonicAlbumDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,played: freezed == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,isCompilation: freezed == isCompilation ? _self.isCompilation : isCompilation // ignore: cast_nullable_to_non_nullable
as bool?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<SubsonicNamedDTO>,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistRefDTO>,song: null == song ? _self._song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicArtistDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id; String get name;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get coverArt; String? get artistImageUrl; int get albumCount; String? get starred; String? get musicBrainzId; String? get sortName; int? get userRating; List<SubsonicAlbumDTO> get album;
/// Create a copy of SubsonicArtistDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicArtistDTOCopyWith<SubsonicArtistDTO> get copyWith => _$SubsonicArtistDTOCopyWithImpl<SubsonicArtistDTO>(this as SubsonicArtistDTO, _$identity);

  /// Serializes this SubsonicArtistDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicArtistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.artistImageUrl, artistImageUrl) || other.artistImageUrl == artistImageUrl)&&(identical(other.albumCount, albumCount) || other.albumCount == albumCount)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&const DeepCollectionEquality().equals(other.album, album));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,coverArt,artistImageUrl,albumCount,starred,musicBrainzId,sortName,userRating,const DeepCollectionEquality().hash(album));

@override
String toString() {
  return 'SubsonicArtistDTO(id: $id, name: $name, coverArt: $coverArt, artistImageUrl: $artistImageUrl, albumCount: $albumCount, starred: $starred, musicBrainzId: $musicBrainzId, sortName: $sortName, userRating: $userRating, album: $album)';
}


}

/// @nodoc
abstract mixin class $SubsonicArtistDTOCopyWith<$Res>  {
  factory $SubsonicArtistDTOCopyWith(SubsonicArtistDTO value, $Res Function(SubsonicArtistDTO) _then) = _$SubsonicArtistDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, String? artistImageUrl, int albumCount, String? starred, String? musicBrainzId, String? sortName, int? userRating, List<SubsonicAlbumDTO> album
});




}
/// @nodoc
class _$SubsonicArtistDTOCopyWithImpl<$Res>
    implements $SubsonicArtistDTOCopyWith<$Res> {
  _$SubsonicArtistDTOCopyWithImpl(this._self, this._then);

  final SubsonicArtistDTO _self;
  final $Res Function(SubsonicArtistDTO) _then;

/// Create a copy of SubsonicArtistDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? coverArt = freezed,Object? artistImageUrl = freezed,Object? albumCount = null,Object? starred = freezed,Object? musicBrainzId = freezed,Object? sortName = freezed,Object? userRating = freezed,Object? album = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,artistImageUrl: freezed == artistImageUrl ? _self.artistImageUrl : artistImageUrl // ignore: cast_nullable_to_non_nullable
as String?,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicArtistDTO].
extension SubsonicArtistDTOPatterns on SubsonicArtistDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicArtistDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicArtistDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicArtistDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicArtistDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  String? artistImageUrl,  int albumCount,  String? starred,  String? musicBrainzId,  String? sortName,  int? userRating,  List<SubsonicAlbumDTO> album)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicArtistDTO() when $default != null:
return $default(_that.id,_that.name,_that.coverArt,_that.artistImageUrl,_that.albumCount,_that.starred,_that.musicBrainzId,_that.sortName,_that.userRating,_that.album);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  String? artistImageUrl,  int albumCount,  String? starred,  String? musicBrainzId,  String? sortName,  int? userRating,  List<SubsonicAlbumDTO> album)  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistDTO():
return $default(_that.id,_that.name,_that.coverArt,_that.artistImageUrl,_that.albumCount,_that.starred,_that.musicBrainzId,_that.sortName,_that.userRating,_that.album);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  String? artistImageUrl,  int albumCount,  String? starred,  String? musicBrainzId,  String? sortName,  int? userRating,  List<SubsonicAlbumDTO> album)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistDTO() when $default != null:
return $default(_that.id,_that.name,_that.coverArt,_that.artistImageUrl,_that.albumCount,_that.starred,_that.musicBrainzId,_that.sortName,_that.userRating,_that.album);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicArtistDTO implements SubsonicArtistDTO {
  const _SubsonicArtistDTO({@JsonKey(fromJson: subsonicIdFromJson) required this.id, this.name = '', @JsonKey(fromJson: subsonicOptionalIdFromJson) this.coverArt, this.artistImageUrl, this.albumCount = 0, this.starred, this.musicBrainzId, this.sortName, this.userRating, final  List<SubsonicAlbumDTO> album = const []}): _album = album;
  factory _SubsonicArtistDTO.fromJson(Map<String, dynamic> json) => _$SubsonicArtistDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? coverArt;
@override final  String? artistImageUrl;
@override@JsonKey() final  int albumCount;
@override final  String? starred;
@override final  String? musicBrainzId;
@override final  String? sortName;
@override final  int? userRating;
 final  List<SubsonicAlbumDTO> _album;
@override@JsonKey() List<SubsonicAlbumDTO> get album {
  if (_album is EqualUnmodifiableListView) return _album;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_album);
}


/// Create a copy of SubsonicArtistDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicArtistDTOCopyWith<_SubsonicArtistDTO> get copyWith => __$SubsonicArtistDTOCopyWithImpl<_SubsonicArtistDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicArtistDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicArtistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.artistImageUrl, artistImageUrl) || other.artistImageUrl == artistImageUrl)&&(identical(other.albumCount, albumCount) || other.albumCount == albumCount)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.sortName, sortName) || other.sortName == sortName)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&const DeepCollectionEquality().equals(other._album, _album));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,coverArt,artistImageUrl,albumCount,starred,musicBrainzId,sortName,userRating,const DeepCollectionEquality().hash(_album));

@override
String toString() {
  return 'SubsonicArtistDTO(id: $id, name: $name, coverArt: $coverArt, artistImageUrl: $artistImageUrl, albumCount: $albumCount, starred: $starred, musicBrainzId: $musicBrainzId, sortName: $sortName, userRating: $userRating, album: $album)';
}


}

/// @nodoc
abstract mixin class _$SubsonicArtistDTOCopyWith<$Res> implements $SubsonicArtistDTOCopyWith<$Res> {
  factory _$SubsonicArtistDTOCopyWith(_SubsonicArtistDTO value, $Res Function(_SubsonicArtistDTO) _then) = __$SubsonicArtistDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, String? artistImageUrl, int albumCount, String? starred, String? musicBrainzId, String? sortName, int? userRating, List<SubsonicAlbumDTO> album
});




}
/// @nodoc
class __$SubsonicArtistDTOCopyWithImpl<$Res>
    implements _$SubsonicArtistDTOCopyWith<$Res> {
  __$SubsonicArtistDTOCopyWithImpl(this._self, this._then);

  final _SubsonicArtistDTO _self;
  final $Res Function(_SubsonicArtistDTO) _then;

/// Create a copy of SubsonicArtistDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? coverArt = freezed,Object? artistImageUrl = freezed,Object? albumCount = null,Object? starred = freezed,Object? musicBrainzId = freezed,Object? sortName = freezed,Object? userRating = freezed,Object? album = null,}) {
  return _then(_SubsonicArtistDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,artistImageUrl: freezed == artistImageUrl ? _self.artistImageUrl : artistImageUrl // ignore: cast_nullable_to_non_nullable
as String?,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,starred: freezed == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as String?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,sortName: freezed == sortName ? _self.sortName : sortName // ignore: cast_nullable_to_non_nullable
as String?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,album: null == album ? _self._album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicArtistInfoDTO {

 String? get biography; String? get musicBrainzId; String? get lastFmUrl; String? get smallImageUrl; String? get mediumImageUrl; String? get largeImageUrl; List<SubsonicArtistDTO> get similarArtist;
/// Create a copy of SubsonicArtistInfoDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicArtistInfoDTOCopyWith<SubsonicArtistInfoDTO> get copyWith => _$SubsonicArtistInfoDTOCopyWithImpl<SubsonicArtistInfoDTO>(this as SubsonicArtistInfoDTO, _$identity);

  /// Serializes this SubsonicArtistInfoDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicArtistInfoDTO&&(identical(other.biography, biography) || other.biography == biography)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.lastFmUrl, lastFmUrl) || other.lastFmUrl == lastFmUrl)&&(identical(other.smallImageUrl, smallImageUrl) || other.smallImageUrl == smallImageUrl)&&(identical(other.mediumImageUrl, mediumImageUrl) || other.mediumImageUrl == mediumImageUrl)&&(identical(other.largeImageUrl, largeImageUrl) || other.largeImageUrl == largeImageUrl)&&const DeepCollectionEquality().equals(other.similarArtist, similarArtist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biography,musicBrainzId,lastFmUrl,smallImageUrl,mediumImageUrl,largeImageUrl,const DeepCollectionEquality().hash(similarArtist));

@override
String toString() {
  return 'SubsonicArtistInfoDTO(biography: $biography, musicBrainzId: $musicBrainzId, lastFmUrl: $lastFmUrl, smallImageUrl: $smallImageUrl, mediumImageUrl: $mediumImageUrl, largeImageUrl: $largeImageUrl, similarArtist: $similarArtist)';
}


}

/// @nodoc
abstract mixin class $SubsonicArtistInfoDTOCopyWith<$Res>  {
  factory $SubsonicArtistInfoDTOCopyWith(SubsonicArtistInfoDTO value, $Res Function(SubsonicArtistInfoDTO) _then) = _$SubsonicArtistInfoDTOCopyWithImpl;
@useResult
$Res call({
 String? biography, String? musicBrainzId, String? lastFmUrl, String? smallImageUrl, String? mediumImageUrl, String? largeImageUrl, List<SubsonicArtistDTO> similarArtist
});




}
/// @nodoc
class _$SubsonicArtistInfoDTOCopyWithImpl<$Res>
    implements $SubsonicArtistInfoDTOCopyWith<$Res> {
  _$SubsonicArtistInfoDTOCopyWithImpl(this._self, this._then);

  final SubsonicArtistInfoDTO _self;
  final $Res Function(SubsonicArtistInfoDTO) _then;

/// Create a copy of SubsonicArtistInfoDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? biography = freezed,Object? musicBrainzId = freezed,Object? lastFmUrl = freezed,Object? smallImageUrl = freezed,Object? mediumImageUrl = freezed,Object? largeImageUrl = freezed,Object? similarArtist = null,}) {
  return _then(_self.copyWith(
biography: freezed == biography ? _self.biography : biography // ignore: cast_nullable_to_non_nullable
as String?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,lastFmUrl: freezed == lastFmUrl ? _self.lastFmUrl : lastFmUrl // ignore: cast_nullable_to_non_nullable
as String?,smallImageUrl: freezed == smallImageUrl ? _self.smallImageUrl : smallImageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediumImageUrl: freezed == mediumImageUrl ? _self.mediumImageUrl : mediumImageUrl // ignore: cast_nullable_to_non_nullable
as String?,largeImageUrl: freezed == largeImageUrl ? _self.largeImageUrl : largeImageUrl // ignore: cast_nullable_to_non_nullable
as String?,similarArtist: null == similarArtist ? _self.similarArtist : similarArtist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicArtistInfoDTO].
extension SubsonicArtistInfoDTOPatterns on SubsonicArtistInfoDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicArtistInfoDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicArtistInfoDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicArtistInfoDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? biography,  String? musicBrainzId,  String? lastFmUrl,  String? smallImageUrl,  String? mediumImageUrl,  String? largeImageUrl,  List<SubsonicArtistDTO> similarArtist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO() when $default != null:
return $default(_that.biography,_that.musicBrainzId,_that.lastFmUrl,_that.smallImageUrl,_that.mediumImageUrl,_that.largeImageUrl,_that.similarArtist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? biography,  String? musicBrainzId,  String? lastFmUrl,  String? smallImageUrl,  String? mediumImageUrl,  String? largeImageUrl,  List<SubsonicArtistDTO> similarArtist)  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO():
return $default(_that.biography,_that.musicBrainzId,_that.lastFmUrl,_that.smallImageUrl,_that.mediumImageUrl,_that.largeImageUrl,_that.similarArtist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? biography,  String? musicBrainzId,  String? lastFmUrl,  String? smallImageUrl,  String? mediumImageUrl,  String? largeImageUrl,  List<SubsonicArtistDTO> similarArtist)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistInfoDTO() when $default != null:
return $default(_that.biography,_that.musicBrainzId,_that.lastFmUrl,_that.smallImageUrl,_that.mediumImageUrl,_that.largeImageUrl,_that.similarArtist);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicArtistInfoDTO implements SubsonicArtistInfoDTO {
  const _SubsonicArtistInfoDTO({this.biography, this.musicBrainzId, this.lastFmUrl, this.smallImageUrl, this.mediumImageUrl, this.largeImageUrl, final  List<SubsonicArtistDTO> similarArtist = const []}): _similarArtist = similarArtist;
  factory _SubsonicArtistInfoDTO.fromJson(Map<String, dynamic> json) => _$SubsonicArtistInfoDTOFromJson(json);

@override final  String? biography;
@override final  String? musicBrainzId;
@override final  String? lastFmUrl;
@override final  String? smallImageUrl;
@override final  String? mediumImageUrl;
@override final  String? largeImageUrl;
 final  List<SubsonicArtistDTO> _similarArtist;
@override@JsonKey() List<SubsonicArtistDTO> get similarArtist {
  if (_similarArtist is EqualUnmodifiableListView) return _similarArtist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_similarArtist);
}


/// Create a copy of SubsonicArtistInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicArtistInfoDTOCopyWith<_SubsonicArtistInfoDTO> get copyWith => __$SubsonicArtistInfoDTOCopyWithImpl<_SubsonicArtistInfoDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicArtistInfoDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicArtistInfoDTO&&(identical(other.biography, biography) || other.biography == biography)&&(identical(other.musicBrainzId, musicBrainzId) || other.musicBrainzId == musicBrainzId)&&(identical(other.lastFmUrl, lastFmUrl) || other.lastFmUrl == lastFmUrl)&&(identical(other.smallImageUrl, smallImageUrl) || other.smallImageUrl == smallImageUrl)&&(identical(other.mediumImageUrl, mediumImageUrl) || other.mediumImageUrl == mediumImageUrl)&&(identical(other.largeImageUrl, largeImageUrl) || other.largeImageUrl == largeImageUrl)&&const DeepCollectionEquality().equals(other._similarArtist, _similarArtist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biography,musicBrainzId,lastFmUrl,smallImageUrl,mediumImageUrl,largeImageUrl,const DeepCollectionEquality().hash(_similarArtist));

@override
String toString() {
  return 'SubsonicArtistInfoDTO(biography: $biography, musicBrainzId: $musicBrainzId, lastFmUrl: $lastFmUrl, smallImageUrl: $smallImageUrl, mediumImageUrl: $mediumImageUrl, largeImageUrl: $largeImageUrl, similarArtist: $similarArtist)';
}


}

/// @nodoc
abstract mixin class _$SubsonicArtistInfoDTOCopyWith<$Res> implements $SubsonicArtistInfoDTOCopyWith<$Res> {
  factory _$SubsonicArtistInfoDTOCopyWith(_SubsonicArtistInfoDTO value, $Res Function(_SubsonicArtistInfoDTO) _then) = __$SubsonicArtistInfoDTOCopyWithImpl;
@override @useResult
$Res call({
 String? biography, String? musicBrainzId, String? lastFmUrl, String? smallImageUrl, String? mediumImageUrl, String? largeImageUrl, List<SubsonicArtistDTO> similarArtist
});




}
/// @nodoc
class __$SubsonicArtistInfoDTOCopyWithImpl<$Res>
    implements _$SubsonicArtistInfoDTOCopyWith<$Res> {
  __$SubsonicArtistInfoDTOCopyWithImpl(this._self, this._then);

  final _SubsonicArtistInfoDTO _self;
  final $Res Function(_SubsonicArtistInfoDTO) _then;

/// Create a copy of SubsonicArtistInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? biography = freezed,Object? musicBrainzId = freezed,Object? lastFmUrl = freezed,Object? smallImageUrl = freezed,Object? mediumImageUrl = freezed,Object? largeImageUrl = freezed,Object? similarArtist = null,}) {
  return _then(_SubsonicArtistInfoDTO(
biography: freezed == biography ? _self.biography : biography // ignore: cast_nullable_to_non_nullable
as String?,musicBrainzId: freezed == musicBrainzId ? _self.musicBrainzId : musicBrainzId // ignore: cast_nullable_to_non_nullable
as String?,lastFmUrl: freezed == lastFmUrl ? _self.lastFmUrl : lastFmUrl // ignore: cast_nullable_to_non_nullable
as String?,smallImageUrl: freezed == smallImageUrl ? _self.smallImageUrl : smallImageUrl // ignore: cast_nullable_to_non_nullable
as String?,mediumImageUrl: freezed == mediumImageUrl ? _self.mediumImageUrl : mediumImageUrl // ignore: cast_nullable_to_non_nullable
as String?,largeImageUrl: freezed == largeImageUrl ? _self.largeImageUrl : largeImageUrl // ignore: cast_nullable_to_non_nullable
as String?,similarArtist: null == similarArtist ? _self._similarArtist : similarArtist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicIndexDTO {

 String get name; List<SubsonicArtistDTO> get artist;
/// Create a copy of SubsonicIndexDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicIndexDTOCopyWith<SubsonicIndexDTO> get copyWith => _$SubsonicIndexDTOCopyWithImpl<SubsonicIndexDTO>(this as SubsonicIndexDTO, _$identity);

  /// Serializes this SubsonicIndexDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicIndexDTO&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.artist, artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(artist));

@override
String toString() {
  return 'SubsonicIndexDTO(name: $name, artist: $artist)';
}


}

/// @nodoc
abstract mixin class $SubsonicIndexDTOCopyWith<$Res>  {
  factory $SubsonicIndexDTOCopyWith(SubsonicIndexDTO value, $Res Function(SubsonicIndexDTO) _then) = _$SubsonicIndexDTOCopyWithImpl;
@useResult
$Res call({
 String name, List<SubsonicArtistDTO> artist
});




}
/// @nodoc
class _$SubsonicIndexDTOCopyWithImpl<$Res>
    implements $SubsonicIndexDTOCopyWith<$Res> {
  _$SubsonicIndexDTOCopyWithImpl(this._self, this._then);

  final SubsonicIndexDTO _self;
  final $Res Function(SubsonicIndexDTO) _then;

/// Create a copy of SubsonicIndexDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? artist = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicIndexDTO].
extension SubsonicIndexDTOPatterns on SubsonicIndexDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicIndexDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicIndexDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicIndexDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicIndexDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicIndexDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicIndexDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<SubsonicArtistDTO> artist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicIndexDTO() when $default != null:
return $default(_that.name,_that.artist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<SubsonicArtistDTO> artist)  $default,) {final _that = this;
switch (_that) {
case _SubsonicIndexDTO():
return $default(_that.name,_that.artist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<SubsonicArtistDTO> artist)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicIndexDTO() when $default != null:
return $default(_that.name,_that.artist);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicIndexDTO implements SubsonicIndexDTO {
  const _SubsonicIndexDTO({this.name = '', final  List<SubsonicArtistDTO> artist = const []}): _artist = artist;
  factory _SubsonicIndexDTO.fromJson(Map<String, dynamic> json) => _$SubsonicIndexDTOFromJson(json);

@override@JsonKey() final  String name;
 final  List<SubsonicArtistDTO> _artist;
@override@JsonKey() List<SubsonicArtistDTO> get artist {
  if (_artist is EqualUnmodifiableListView) return _artist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artist);
}


/// Create a copy of SubsonicIndexDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicIndexDTOCopyWith<_SubsonicIndexDTO> get copyWith => __$SubsonicIndexDTOCopyWithImpl<_SubsonicIndexDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicIndexDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicIndexDTO&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._artist, _artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_artist));

@override
String toString() {
  return 'SubsonicIndexDTO(name: $name, artist: $artist)';
}


}

/// @nodoc
abstract mixin class _$SubsonicIndexDTOCopyWith<$Res> implements $SubsonicIndexDTOCopyWith<$Res> {
  factory _$SubsonicIndexDTOCopyWith(_SubsonicIndexDTO value, $Res Function(_SubsonicIndexDTO) _then) = __$SubsonicIndexDTOCopyWithImpl;
@override @useResult
$Res call({
 String name, List<SubsonicArtistDTO> artist
});




}
/// @nodoc
class __$SubsonicIndexDTOCopyWithImpl<$Res>
    implements _$SubsonicIndexDTOCopyWith<$Res> {
  __$SubsonicIndexDTOCopyWithImpl(this._self, this._then);

  final _SubsonicIndexDTO _self;
  final $Res Function(_SubsonicIndexDTO) _then;

/// Create a copy of SubsonicIndexDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? artist = null,}) {
  return _then(_SubsonicIndexDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self._artist : artist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicArtistsDTO {

 String? get ignoredArticles; List<SubsonicIndexDTO> get index;
/// Create a copy of SubsonicArtistsDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicArtistsDTOCopyWith<SubsonicArtistsDTO> get copyWith => _$SubsonicArtistsDTOCopyWithImpl<SubsonicArtistsDTO>(this as SubsonicArtistsDTO, _$identity);

  /// Serializes this SubsonicArtistsDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicArtistsDTO&&(identical(other.ignoredArticles, ignoredArticles) || other.ignoredArticles == ignoredArticles)&&const DeepCollectionEquality().equals(other.index, index));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ignoredArticles,const DeepCollectionEquality().hash(index));

@override
String toString() {
  return 'SubsonicArtistsDTO(ignoredArticles: $ignoredArticles, index: $index)';
}


}

/// @nodoc
abstract mixin class $SubsonicArtistsDTOCopyWith<$Res>  {
  factory $SubsonicArtistsDTOCopyWith(SubsonicArtistsDTO value, $Res Function(SubsonicArtistsDTO) _then) = _$SubsonicArtistsDTOCopyWithImpl;
@useResult
$Res call({
 String? ignoredArticles, List<SubsonicIndexDTO> index
});




}
/// @nodoc
class _$SubsonicArtistsDTOCopyWithImpl<$Res>
    implements $SubsonicArtistsDTOCopyWith<$Res> {
  _$SubsonicArtistsDTOCopyWithImpl(this._self, this._then);

  final SubsonicArtistsDTO _self;
  final $Res Function(SubsonicArtistsDTO) _then;

/// Create a copy of SubsonicArtistsDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ignoredArticles = freezed,Object? index = null,}) {
  return _then(_self.copyWith(
ignoredArticles: freezed == ignoredArticles ? _self.ignoredArticles : ignoredArticles // ignore: cast_nullable_to_non_nullable
as String?,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as List<SubsonicIndexDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicArtistsDTO].
extension SubsonicArtistsDTOPatterns on SubsonicArtistsDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicArtistsDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicArtistsDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicArtistsDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistsDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicArtistsDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicArtistsDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ignoredArticles,  List<SubsonicIndexDTO> index)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicArtistsDTO() when $default != null:
return $default(_that.ignoredArticles,_that.index);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ignoredArticles,  List<SubsonicIndexDTO> index)  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistsDTO():
return $default(_that.ignoredArticles,_that.index);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ignoredArticles,  List<SubsonicIndexDTO> index)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicArtistsDTO() when $default != null:
return $default(_that.ignoredArticles,_that.index);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicArtistsDTO implements SubsonicArtistsDTO {
  const _SubsonicArtistsDTO({this.ignoredArticles, final  List<SubsonicIndexDTO> index = const []}): _index = index;
  factory _SubsonicArtistsDTO.fromJson(Map<String, dynamic> json) => _$SubsonicArtistsDTOFromJson(json);

@override final  String? ignoredArticles;
 final  List<SubsonicIndexDTO> _index;
@override@JsonKey() List<SubsonicIndexDTO> get index {
  if (_index is EqualUnmodifiableListView) return _index;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_index);
}


/// Create a copy of SubsonicArtistsDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicArtistsDTOCopyWith<_SubsonicArtistsDTO> get copyWith => __$SubsonicArtistsDTOCopyWithImpl<_SubsonicArtistsDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicArtistsDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicArtistsDTO&&(identical(other.ignoredArticles, ignoredArticles) || other.ignoredArticles == ignoredArticles)&&const DeepCollectionEquality().equals(other._index, _index));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ignoredArticles,const DeepCollectionEquality().hash(_index));

@override
String toString() {
  return 'SubsonicArtistsDTO(ignoredArticles: $ignoredArticles, index: $index)';
}


}

/// @nodoc
abstract mixin class _$SubsonicArtistsDTOCopyWith<$Res> implements $SubsonicArtistsDTOCopyWith<$Res> {
  factory _$SubsonicArtistsDTOCopyWith(_SubsonicArtistsDTO value, $Res Function(_SubsonicArtistsDTO) _then) = __$SubsonicArtistsDTOCopyWithImpl;
@override @useResult
$Res call({
 String? ignoredArticles, List<SubsonicIndexDTO> index
});




}
/// @nodoc
class __$SubsonicArtistsDTOCopyWithImpl<$Res>
    implements _$SubsonicArtistsDTOCopyWith<$Res> {
  __$SubsonicArtistsDTOCopyWithImpl(this._self, this._then);

  final _SubsonicArtistsDTO _self;
  final $Res Function(_SubsonicArtistsDTO) _then;

/// Create a copy of SubsonicArtistsDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ignoredArticles = freezed,Object? index = null,}) {
  return _then(_SubsonicArtistsDTO(
ignoredArticles: freezed == ignoredArticles ? _self.ignoredArticles : ignoredArticles // ignore: cast_nullable_to_non_nullable
as String?,index: null == index ? _self._index : index // ignore: cast_nullable_to_non_nullable
as List<SubsonicIndexDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicPlaylistDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id; String get name; String? get comment; String? get owner; bool get public; int get songCount; int? get duration; DateTime? get created; DateTime? get changed;@JsonKey(fromJson: subsonicOptionalIdFromJson) String? get coverArt; List<SubsonicChildDTO> get entry;
/// Create a copy of SubsonicPlaylistDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicPlaylistDTOCopyWith<SubsonicPlaylistDTO> get copyWith => _$SubsonicPlaylistDTOCopyWithImpl<SubsonicPlaylistDTO>(this as SubsonicPlaylistDTO, _$identity);

  /// Serializes this SubsonicPlaylistDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicPlaylistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.public, public) || other.public == public)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.created, created) || other.created == created)&&(identical(other.changed, changed) || other.changed == changed)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&const DeepCollectionEquality().equals(other.entry, entry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,comment,owner,public,songCount,duration,created,changed,coverArt,const DeepCollectionEquality().hash(entry));

@override
String toString() {
  return 'SubsonicPlaylistDTO(id: $id, name: $name, comment: $comment, owner: $owner, public: $public, songCount: $songCount, duration: $duration, created: $created, changed: $changed, coverArt: $coverArt, entry: $entry)';
}


}

/// @nodoc
abstract mixin class $SubsonicPlaylistDTOCopyWith<$Res>  {
  factory $SubsonicPlaylistDTOCopyWith(SubsonicPlaylistDTO value, $Res Function(SubsonicPlaylistDTO) _then) = _$SubsonicPlaylistDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name, String? comment, String? owner, bool public, int songCount, int? duration, DateTime? created, DateTime? changed,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, List<SubsonicChildDTO> entry
});




}
/// @nodoc
class _$SubsonicPlaylistDTOCopyWithImpl<$Res>
    implements $SubsonicPlaylistDTOCopyWith<$Res> {
  _$SubsonicPlaylistDTOCopyWithImpl(this._self, this._then);

  final SubsonicPlaylistDTO _self;
  final $Res Function(SubsonicPlaylistDTO) _then;

/// Create a copy of SubsonicPlaylistDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? comment = freezed,Object? owner = freezed,Object? public = null,Object? songCount = null,Object? duration = freezed,Object? created = freezed,Object? changed = freezed,Object? coverArt = freezed,Object? entry = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,public: null == public ? _self.public : public // ignore: cast_nullable_to_non_nullable
as bool,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,changed: freezed == changed ? _self.changed : changed // ignore: cast_nullable_to_non_nullable
as DateTime?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicPlaylistDTO].
extension SubsonicPlaylistDTOPatterns on SubsonicPlaylistDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicPlaylistDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicPlaylistDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicPlaylistDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? comment,  String? owner,  bool public,  int songCount,  int? duration,  DateTime? created,  DateTime? changed, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  List<SubsonicChildDTO> entry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO() when $default != null:
return $default(_that.id,_that.name,_that.comment,_that.owner,_that.public,_that.songCount,_that.duration,_that.created,_that.changed,_that.coverArt,_that.entry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? comment,  String? owner,  bool public,  int songCount,  int? duration,  DateTime? created,  DateTime? changed, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  List<SubsonicChildDTO> entry)  $default,) {final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO():
return $default(_that.id,_that.name,_that.comment,_that.owner,_that.public,_that.songCount,_that.duration,_that.created,_that.changed,_that.coverArt,_that.entry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name,  String? comment,  String? owner,  bool public,  int songCount,  int? duration,  DateTime? created,  DateTime? changed, @JsonKey(fromJson: subsonicOptionalIdFromJson)  String? coverArt,  List<SubsonicChildDTO> entry)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicPlaylistDTO() when $default != null:
return $default(_that.id,_that.name,_that.comment,_that.owner,_that.public,_that.songCount,_that.duration,_that.created,_that.changed,_that.coverArt,_that.entry);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicPlaylistDTO implements SubsonicPlaylistDTO {
  const _SubsonicPlaylistDTO({@JsonKey(fromJson: subsonicIdFromJson) required this.id, this.name = '', this.comment, this.owner, this.public = false, this.songCount = 0, this.duration, this.created, this.changed, @JsonKey(fromJson: subsonicOptionalIdFromJson) this.coverArt, final  List<SubsonicChildDTO> entry = const []}): _entry = entry;
  factory _SubsonicPlaylistDTO.fromJson(Map<String, dynamic> json) => _$SubsonicPlaylistDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey() final  String name;
@override final  String? comment;
@override final  String? owner;
@override@JsonKey() final  bool public;
@override@JsonKey() final  int songCount;
@override final  int? duration;
@override final  DateTime? created;
@override final  DateTime? changed;
@override@JsonKey(fromJson: subsonicOptionalIdFromJson) final  String? coverArt;
 final  List<SubsonicChildDTO> _entry;
@override@JsonKey() List<SubsonicChildDTO> get entry {
  if (_entry is EqualUnmodifiableListView) return _entry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entry);
}


/// Create a copy of SubsonicPlaylistDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicPlaylistDTOCopyWith<_SubsonicPlaylistDTO> get copyWith => __$SubsonicPlaylistDTOCopyWithImpl<_SubsonicPlaylistDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicPlaylistDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicPlaylistDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.public, public) || other.public == public)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.created, created) || other.created == created)&&(identical(other.changed, changed) || other.changed == changed)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&const DeepCollectionEquality().equals(other._entry, _entry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,comment,owner,public,songCount,duration,created,changed,coverArt,const DeepCollectionEquality().hash(_entry));

@override
String toString() {
  return 'SubsonicPlaylistDTO(id: $id, name: $name, comment: $comment, owner: $owner, public: $public, songCount: $songCount, duration: $duration, created: $created, changed: $changed, coverArt: $coverArt, entry: $entry)';
}


}

/// @nodoc
abstract mixin class _$SubsonicPlaylistDTOCopyWith<$Res> implements $SubsonicPlaylistDTOCopyWith<$Res> {
  factory _$SubsonicPlaylistDTOCopyWith(_SubsonicPlaylistDTO value, $Res Function(_SubsonicPlaylistDTO) _then) = __$SubsonicPlaylistDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name, String? comment, String? owner, bool public, int songCount, int? duration, DateTime? created, DateTime? changed,@JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt, List<SubsonicChildDTO> entry
});




}
/// @nodoc
class __$SubsonicPlaylistDTOCopyWithImpl<$Res>
    implements _$SubsonicPlaylistDTOCopyWith<$Res> {
  __$SubsonicPlaylistDTOCopyWithImpl(this._self, this._then);

  final _SubsonicPlaylistDTO _self;
  final $Res Function(_SubsonicPlaylistDTO) _then;

/// Create a copy of SubsonicPlaylistDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? comment = freezed,Object? owner = freezed,Object? public = null,Object? songCount = null,Object? duration = freezed,Object? created = freezed,Object? changed = freezed,Object? coverArt = freezed,Object? entry = null,}) {
  return _then(_SubsonicPlaylistDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,public: null == public ? _self.public : public // ignore: cast_nullable_to_non_nullable
as bool,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime?,changed: freezed == changed ? _self.changed : changed // ignore: cast_nullable_to_non_nullable
as DateTime?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,entry: null == entry ? _self._entry : entry // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicPlaylistsDTO {

 List<SubsonicPlaylistDTO> get playlist;
/// Create a copy of SubsonicPlaylistsDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicPlaylistsDTOCopyWith<SubsonicPlaylistsDTO> get copyWith => _$SubsonicPlaylistsDTOCopyWithImpl<SubsonicPlaylistsDTO>(this as SubsonicPlaylistsDTO, _$identity);

  /// Serializes this SubsonicPlaylistsDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicPlaylistsDTO&&const DeepCollectionEquality().equals(other.playlist, playlist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(playlist));

@override
String toString() {
  return 'SubsonicPlaylistsDTO(playlist: $playlist)';
}


}

/// @nodoc
abstract mixin class $SubsonicPlaylistsDTOCopyWith<$Res>  {
  factory $SubsonicPlaylistsDTOCopyWith(SubsonicPlaylistsDTO value, $Res Function(SubsonicPlaylistsDTO) _then) = _$SubsonicPlaylistsDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicPlaylistDTO> playlist
});




}
/// @nodoc
class _$SubsonicPlaylistsDTOCopyWithImpl<$Res>
    implements $SubsonicPlaylistsDTOCopyWith<$Res> {
  _$SubsonicPlaylistsDTOCopyWithImpl(this._self, this._then);

  final SubsonicPlaylistsDTO _self;
  final $Res Function(SubsonicPlaylistsDTO) _then;

/// Create a copy of SubsonicPlaylistsDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playlist = null,}) {
  return _then(_self.copyWith(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as List<SubsonicPlaylistDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicPlaylistsDTO].
extension SubsonicPlaylistsDTOPatterns on SubsonicPlaylistsDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicPlaylistsDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicPlaylistsDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicPlaylistsDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicPlaylistDTO> playlist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO() when $default != null:
return $default(_that.playlist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicPlaylistDTO> playlist)  $default,) {final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO():
return $default(_that.playlist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicPlaylistDTO> playlist)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicPlaylistsDTO() when $default != null:
return $default(_that.playlist);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicPlaylistsDTO implements SubsonicPlaylistsDTO {
  const _SubsonicPlaylistsDTO({final  List<SubsonicPlaylistDTO> playlist = const []}): _playlist = playlist;
  factory _SubsonicPlaylistsDTO.fromJson(Map<String, dynamic> json) => _$SubsonicPlaylistsDTOFromJson(json);

 final  List<SubsonicPlaylistDTO> _playlist;
@override@JsonKey() List<SubsonicPlaylistDTO> get playlist {
  if (_playlist is EqualUnmodifiableListView) return _playlist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlist);
}


/// Create a copy of SubsonicPlaylistsDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicPlaylistsDTOCopyWith<_SubsonicPlaylistsDTO> get copyWith => __$SubsonicPlaylistsDTOCopyWithImpl<_SubsonicPlaylistsDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicPlaylistsDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicPlaylistsDTO&&const DeepCollectionEquality().equals(other._playlist, _playlist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlist));

@override
String toString() {
  return 'SubsonicPlaylistsDTO(playlist: $playlist)';
}


}

/// @nodoc
abstract mixin class _$SubsonicPlaylistsDTOCopyWith<$Res> implements $SubsonicPlaylistsDTOCopyWith<$Res> {
  factory _$SubsonicPlaylistsDTOCopyWith(_SubsonicPlaylistsDTO value, $Res Function(_SubsonicPlaylistsDTO) _then) = __$SubsonicPlaylistsDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicPlaylistDTO> playlist
});




}
/// @nodoc
class __$SubsonicPlaylistsDTOCopyWithImpl<$Res>
    implements _$SubsonicPlaylistsDTOCopyWith<$Res> {
  __$SubsonicPlaylistsDTOCopyWithImpl(this._self, this._then);

  final _SubsonicPlaylistsDTO _self;
  final $Res Function(_SubsonicPlaylistsDTO) _then;

/// Create a copy of SubsonicPlaylistsDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playlist = null,}) {
  return _then(_SubsonicPlaylistsDTO(
playlist: null == playlist ? _self._playlist : playlist // ignore: cast_nullable_to_non_nullable
as List<SubsonicPlaylistDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicGenreDTO {

 String get value; int get songCount; int get albumCount;
/// Create a copy of SubsonicGenreDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicGenreDTOCopyWith<SubsonicGenreDTO> get copyWith => _$SubsonicGenreDTOCopyWithImpl<SubsonicGenreDTO>(this as SubsonicGenreDTO, _$identity);

  /// Serializes this SubsonicGenreDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicGenreDTO&&(identical(other.value, value) || other.value == value)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.albumCount, albumCount) || other.albumCount == albumCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,songCount,albumCount);

@override
String toString() {
  return 'SubsonicGenreDTO(value: $value, songCount: $songCount, albumCount: $albumCount)';
}


}

/// @nodoc
abstract mixin class $SubsonicGenreDTOCopyWith<$Res>  {
  factory $SubsonicGenreDTOCopyWith(SubsonicGenreDTO value, $Res Function(SubsonicGenreDTO) _then) = _$SubsonicGenreDTOCopyWithImpl;
@useResult
$Res call({
 String value, int songCount, int albumCount
});




}
/// @nodoc
class _$SubsonicGenreDTOCopyWithImpl<$Res>
    implements $SubsonicGenreDTOCopyWith<$Res> {
  _$SubsonicGenreDTOCopyWithImpl(this._self, this._then);

  final SubsonicGenreDTO _self;
  final $Res Function(SubsonicGenreDTO) _then;

/// Create a copy of SubsonicGenreDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? songCount = null,Object? albumCount = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicGenreDTO].
extension SubsonicGenreDTOPatterns on SubsonicGenreDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicGenreDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicGenreDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicGenreDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicGenreDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicGenreDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicGenreDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  int songCount,  int albumCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicGenreDTO() when $default != null:
return $default(_that.value,_that.songCount,_that.albumCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  int songCount,  int albumCount)  $default,) {final _that = this;
switch (_that) {
case _SubsonicGenreDTO():
return $default(_that.value,_that.songCount,_that.albumCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  int songCount,  int albumCount)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicGenreDTO() when $default != null:
return $default(_that.value,_that.songCount,_that.albumCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicGenreDTO implements SubsonicGenreDTO {
  const _SubsonicGenreDTO({this.value = '', this.songCount = 0, this.albumCount = 0});
  factory _SubsonicGenreDTO.fromJson(Map<String, dynamic> json) => _$SubsonicGenreDTOFromJson(json);

@override@JsonKey() final  String value;
@override@JsonKey() final  int songCount;
@override@JsonKey() final  int albumCount;

/// Create a copy of SubsonicGenreDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicGenreDTOCopyWith<_SubsonicGenreDTO> get copyWith => __$SubsonicGenreDTOCopyWithImpl<_SubsonicGenreDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicGenreDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicGenreDTO&&(identical(other.value, value) || other.value == value)&&(identical(other.songCount, songCount) || other.songCount == songCount)&&(identical(other.albumCount, albumCount) || other.albumCount == albumCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,songCount,albumCount);

@override
String toString() {
  return 'SubsonicGenreDTO(value: $value, songCount: $songCount, albumCount: $albumCount)';
}


}

/// @nodoc
abstract mixin class _$SubsonicGenreDTOCopyWith<$Res> implements $SubsonicGenreDTOCopyWith<$Res> {
  factory _$SubsonicGenreDTOCopyWith(_SubsonicGenreDTO value, $Res Function(_SubsonicGenreDTO) _then) = __$SubsonicGenreDTOCopyWithImpl;
@override @useResult
$Res call({
 String value, int songCount, int albumCount
});




}
/// @nodoc
class __$SubsonicGenreDTOCopyWithImpl<$Res>
    implements _$SubsonicGenreDTOCopyWith<$Res> {
  __$SubsonicGenreDTOCopyWithImpl(this._self, this._then);

  final _SubsonicGenreDTO _self;
  final $Res Function(_SubsonicGenreDTO) _then;

/// Create a copy of SubsonicGenreDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? songCount = null,Object? albumCount = null,}) {
  return _then(_SubsonicGenreDTO(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,songCount: null == songCount ? _self.songCount : songCount // ignore: cast_nullable_to_non_nullable
as int,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SubsonicGenresDTO {

 List<SubsonicGenreDTO> get genre;
/// Create a copy of SubsonicGenresDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicGenresDTOCopyWith<SubsonicGenresDTO> get copyWith => _$SubsonicGenresDTOCopyWithImpl<SubsonicGenresDTO>(this as SubsonicGenresDTO, _$identity);

  /// Serializes this SubsonicGenresDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicGenresDTO&&const DeepCollectionEquality().equals(other.genre, genre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(genre));

@override
String toString() {
  return 'SubsonicGenresDTO(genre: $genre)';
}


}

/// @nodoc
abstract mixin class $SubsonicGenresDTOCopyWith<$Res>  {
  factory $SubsonicGenresDTOCopyWith(SubsonicGenresDTO value, $Res Function(SubsonicGenresDTO) _then) = _$SubsonicGenresDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicGenreDTO> genre
});




}
/// @nodoc
class _$SubsonicGenresDTOCopyWithImpl<$Res>
    implements $SubsonicGenresDTOCopyWith<$Res> {
  _$SubsonicGenresDTOCopyWithImpl(this._self, this._then);

  final SubsonicGenresDTO _self;
  final $Res Function(SubsonicGenresDTO) _then;

/// Create a copy of SubsonicGenresDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? genre = null,}) {
  return _then(_self.copyWith(
genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as List<SubsonicGenreDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicGenresDTO].
extension SubsonicGenresDTOPatterns on SubsonicGenresDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicGenresDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicGenresDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicGenresDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicGenresDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicGenresDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicGenresDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicGenreDTO> genre)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicGenresDTO() when $default != null:
return $default(_that.genre);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicGenreDTO> genre)  $default,) {final _that = this;
switch (_that) {
case _SubsonicGenresDTO():
return $default(_that.genre);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicGenreDTO> genre)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicGenresDTO() when $default != null:
return $default(_that.genre);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicGenresDTO implements SubsonicGenresDTO {
  const _SubsonicGenresDTO({final  List<SubsonicGenreDTO> genre = const []}): _genre = genre;
  factory _SubsonicGenresDTO.fromJson(Map<String, dynamic> json) => _$SubsonicGenresDTOFromJson(json);

 final  List<SubsonicGenreDTO> _genre;
@override@JsonKey() List<SubsonicGenreDTO> get genre {
  if (_genre is EqualUnmodifiableListView) return _genre;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genre);
}


/// Create a copy of SubsonicGenresDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicGenresDTOCopyWith<_SubsonicGenresDTO> get copyWith => __$SubsonicGenresDTOCopyWithImpl<_SubsonicGenresDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicGenresDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicGenresDTO&&const DeepCollectionEquality().equals(other._genre, _genre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_genre));

@override
String toString() {
  return 'SubsonicGenresDTO(genre: $genre)';
}


}

/// @nodoc
abstract mixin class _$SubsonicGenresDTOCopyWith<$Res> implements $SubsonicGenresDTOCopyWith<$Res> {
  factory _$SubsonicGenresDTOCopyWith(_SubsonicGenresDTO value, $Res Function(_SubsonicGenresDTO) _then) = __$SubsonicGenresDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicGenreDTO> genre
});




}
/// @nodoc
class __$SubsonicGenresDTOCopyWithImpl<$Res>
    implements _$SubsonicGenresDTOCopyWith<$Res> {
  __$SubsonicGenresDTOCopyWithImpl(this._self, this._then);

  final _SubsonicGenresDTO _self;
  final $Res Function(_SubsonicGenresDTO) _then;

/// Create a copy of SubsonicGenresDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? genre = null,}) {
  return _then(_SubsonicGenresDTO(
genre: null == genre ? _self._genre : genre // ignore: cast_nullable_to_non_nullable
as List<SubsonicGenreDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicMusicFolderDTO {

@JsonKey(fromJson: subsonicIdFromJson) String get id; String get name;
/// Create a copy of SubsonicMusicFolderDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicMusicFolderDTOCopyWith<SubsonicMusicFolderDTO> get copyWith => _$SubsonicMusicFolderDTOCopyWithImpl<SubsonicMusicFolderDTO>(this as SubsonicMusicFolderDTO, _$identity);

  /// Serializes this SubsonicMusicFolderDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicMusicFolderDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SubsonicMusicFolderDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $SubsonicMusicFolderDTOCopyWith<$Res>  {
  factory $SubsonicMusicFolderDTOCopyWith(SubsonicMusicFolderDTO value, $Res Function(SubsonicMusicFolderDTO) _then) = _$SubsonicMusicFolderDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name
});




}
/// @nodoc
class _$SubsonicMusicFolderDTOCopyWithImpl<$Res>
    implements $SubsonicMusicFolderDTOCopyWith<$Res> {
  _$SubsonicMusicFolderDTOCopyWithImpl(this._self, this._then);

  final SubsonicMusicFolderDTO _self;
  final $Res Function(SubsonicMusicFolderDTO) _then;

/// Create a copy of SubsonicMusicFolderDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicMusicFolderDTO].
extension SubsonicMusicFolderDTOPatterns on SubsonicMusicFolderDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicMusicFolderDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicMusicFolderDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicMusicFolderDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: subsonicIdFromJson)  String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicMusicFolderDTO() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicMusicFolderDTO implements SubsonicMusicFolderDTO {
  const _SubsonicMusicFolderDTO({@JsonKey(fromJson: subsonicIdFromJson) required this.id, this.name = ''});
  factory _SubsonicMusicFolderDTO.fromJson(Map<String, dynamic> json) => _$SubsonicMusicFolderDTOFromJson(json);

@override@JsonKey(fromJson: subsonicIdFromJson) final  String id;
@override@JsonKey() final  String name;

/// Create a copy of SubsonicMusicFolderDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicMusicFolderDTOCopyWith<_SubsonicMusicFolderDTO> get copyWith => __$SubsonicMusicFolderDTOCopyWithImpl<_SubsonicMusicFolderDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicMusicFolderDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicMusicFolderDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SubsonicMusicFolderDTO(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SubsonicMusicFolderDTOCopyWith<$Res> implements $SubsonicMusicFolderDTOCopyWith<$Res> {
  factory _$SubsonicMusicFolderDTOCopyWith(_SubsonicMusicFolderDTO value, $Res Function(_SubsonicMusicFolderDTO) _then) = __$SubsonicMusicFolderDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: subsonicIdFromJson) String id, String name
});




}
/// @nodoc
class __$SubsonicMusicFolderDTOCopyWithImpl<$Res>
    implements _$SubsonicMusicFolderDTOCopyWith<$Res> {
  __$SubsonicMusicFolderDTOCopyWithImpl(this._self, this._then);

  final _SubsonicMusicFolderDTO _self;
  final $Res Function(_SubsonicMusicFolderDTO) _then;

/// Create a copy of SubsonicMusicFolderDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_SubsonicMusicFolderDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubsonicMusicFoldersDTO {

 List<SubsonicMusicFolderDTO> get musicFolder;
/// Create a copy of SubsonicMusicFoldersDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicMusicFoldersDTOCopyWith<SubsonicMusicFoldersDTO> get copyWith => _$SubsonicMusicFoldersDTOCopyWithImpl<SubsonicMusicFoldersDTO>(this as SubsonicMusicFoldersDTO, _$identity);

  /// Serializes this SubsonicMusicFoldersDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicMusicFoldersDTO&&const DeepCollectionEquality().equals(other.musicFolder, musicFolder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(musicFolder));

@override
String toString() {
  return 'SubsonicMusicFoldersDTO(musicFolder: $musicFolder)';
}


}

/// @nodoc
abstract mixin class $SubsonicMusicFoldersDTOCopyWith<$Res>  {
  factory $SubsonicMusicFoldersDTOCopyWith(SubsonicMusicFoldersDTO value, $Res Function(SubsonicMusicFoldersDTO) _then) = _$SubsonicMusicFoldersDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicMusicFolderDTO> musicFolder
});




}
/// @nodoc
class _$SubsonicMusicFoldersDTOCopyWithImpl<$Res>
    implements $SubsonicMusicFoldersDTOCopyWith<$Res> {
  _$SubsonicMusicFoldersDTOCopyWithImpl(this._self, this._then);

  final SubsonicMusicFoldersDTO _self;
  final $Res Function(SubsonicMusicFoldersDTO) _then;

/// Create a copy of SubsonicMusicFoldersDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? musicFolder = null,}) {
  return _then(_self.copyWith(
musicFolder: null == musicFolder ? _self.musicFolder : musicFolder // ignore: cast_nullable_to_non_nullable
as List<SubsonicMusicFolderDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicMusicFoldersDTO].
extension SubsonicMusicFoldersDTOPatterns on SubsonicMusicFoldersDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicMusicFoldersDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicMusicFoldersDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicMusicFoldersDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicMusicFolderDTO> musicFolder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO() when $default != null:
return $default(_that.musicFolder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicMusicFolderDTO> musicFolder)  $default,) {final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO():
return $default(_that.musicFolder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicMusicFolderDTO> musicFolder)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicMusicFoldersDTO() when $default != null:
return $default(_that.musicFolder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicMusicFoldersDTO implements SubsonicMusicFoldersDTO {
  const _SubsonicMusicFoldersDTO({final  List<SubsonicMusicFolderDTO> musicFolder = const []}): _musicFolder = musicFolder;
  factory _SubsonicMusicFoldersDTO.fromJson(Map<String, dynamic> json) => _$SubsonicMusicFoldersDTOFromJson(json);

 final  List<SubsonicMusicFolderDTO> _musicFolder;
@override@JsonKey() List<SubsonicMusicFolderDTO> get musicFolder {
  if (_musicFolder is EqualUnmodifiableListView) return _musicFolder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_musicFolder);
}


/// Create a copy of SubsonicMusicFoldersDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicMusicFoldersDTOCopyWith<_SubsonicMusicFoldersDTO> get copyWith => __$SubsonicMusicFoldersDTOCopyWithImpl<_SubsonicMusicFoldersDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicMusicFoldersDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicMusicFoldersDTO&&const DeepCollectionEquality().equals(other._musicFolder, _musicFolder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_musicFolder));

@override
String toString() {
  return 'SubsonicMusicFoldersDTO(musicFolder: $musicFolder)';
}


}

/// @nodoc
abstract mixin class _$SubsonicMusicFoldersDTOCopyWith<$Res> implements $SubsonicMusicFoldersDTOCopyWith<$Res> {
  factory _$SubsonicMusicFoldersDTOCopyWith(_SubsonicMusicFoldersDTO value, $Res Function(_SubsonicMusicFoldersDTO) _then) = __$SubsonicMusicFoldersDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicMusicFolderDTO> musicFolder
});




}
/// @nodoc
class __$SubsonicMusicFoldersDTOCopyWithImpl<$Res>
    implements _$SubsonicMusicFoldersDTOCopyWith<$Res> {
  __$SubsonicMusicFoldersDTOCopyWithImpl(this._self, this._then);

  final _SubsonicMusicFoldersDTO _self;
  final $Res Function(_SubsonicMusicFoldersDTO) _then;

/// Create a copy of SubsonicMusicFoldersDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? musicFolder = null,}) {
  return _then(_SubsonicMusicFoldersDTO(
musicFolder: null == musicFolder ? _self._musicFolder : musicFolder // ignore: cast_nullable_to_non_nullable
as List<SubsonicMusicFolderDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicItemSetDTO {

 List<SubsonicArtistDTO> get artist; List<SubsonicAlbumDTO> get album; List<SubsonicChildDTO> get song;
/// Create a copy of SubsonicItemSetDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicItemSetDTOCopyWith<SubsonicItemSetDTO> get copyWith => _$SubsonicItemSetDTOCopyWithImpl<SubsonicItemSetDTO>(this as SubsonicItemSetDTO, _$identity);

  /// Serializes this SubsonicItemSetDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicItemSetDTO&&const DeepCollectionEquality().equals(other.artist, artist)&&const DeepCollectionEquality().equals(other.album, album)&&const DeepCollectionEquality().equals(other.song, song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(artist),const DeepCollectionEquality().hash(album),const DeepCollectionEquality().hash(song));

@override
String toString() {
  return 'SubsonicItemSetDTO(artist: $artist, album: $album, song: $song)';
}


}

/// @nodoc
abstract mixin class $SubsonicItemSetDTOCopyWith<$Res>  {
  factory $SubsonicItemSetDTOCopyWith(SubsonicItemSetDTO value, $Res Function(SubsonicItemSetDTO) _then) = _$SubsonicItemSetDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicArtistDTO> artist, List<SubsonicAlbumDTO> album, List<SubsonicChildDTO> song
});




}
/// @nodoc
class _$SubsonicItemSetDTOCopyWithImpl<$Res>
    implements $SubsonicItemSetDTOCopyWith<$Res> {
  _$SubsonicItemSetDTOCopyWithImpl(this._self, this._then);

  final SubsonicItemSetDTO _self;
  final $Res Function(SubsonicItemSetDTO) _then;

/// Create a copy of SubsonicItemSetDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? album = null,Object? song = null,}) {
  return _then(_self.copyWith(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,song: null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicItemSetDTO].
extension SubsonicItemSetDTOPatterns on SubsonicItemSetDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicItemSetDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicItemSetDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicItemSetDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicItemSetDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicItemSetDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicItemSetDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicArtistDTO> artist,  List<SubsonicAlbumDTO> album,  List<SubsonicChildDTO> song)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicItemSetDTO() when $default != null:
return $default(_that.artist,_that.album,_that.song);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicArtistDTO> artist,  List<SubsonicAlbumDTO> album,  List<SubsonicChildDTO> song)  $default,) {final _that = this;
switch (_that) {
case _SubsonicItemSetDTO():
return $default(_that.artist,_that.album,_that.song);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicArtistDTO> artist,  List<SubsonicAlbumDTO> album,  List<SubsonicChildDTO> song)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicItemSetDTO() when $default != null:
return $default(_that.artist,_that.album,_that.song);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicItemSetDTO implements SubsonicItemSetDTO {
  const _SubsonicItemSetDTO({final  List<SubsonicArtistDTO> artist = const [], final  List<SubsonicAlbumDTO> album = const [], final  List<SubsonicChildDTO> song = const []}): _artist = artist,_album = album,_song = song;
  factory _SubsonicItemSetDTO.fromJson(Map<String, dynamic> json) => _$SubsonicItemSetDTOFromJson(json);

 final  List<SubsonicArtistDTO> _artist;
@override@JsonKey() List<SubsonicArtistDTO> get artist {
  if (_artist is EqualUnmodifiableListView) return _artist;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artist);
}

 final  List<SubsonicAlbumDTO> _album;
@override@JsonKey() List<SubsonicAlbumDTO> get album {
  if (_album is EqualUnmodifiableListView) return _album;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_album);
}

 final  List<SubsonicChildDTO> _song;
@override@JsonKey() List<SubsonicChildDTO> get song {
  if (_song is EqualUnmodifiableListView) return _song;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_song);
}


/// Create a copy of SubsonicItemSetDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicItemSetDTOCopyWith<_SubsonicItemSetDTO> get copyWith => __$SubsonicItemSetDTOCopyWithImpl<_SubsonicItemSetDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicItemSetDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicItemSetDTO&&const DeepCollectionEquality().equals(other._artist, _artist)&&const DeepCollectionEquality().equals(other._album, _album)&&const DeepCollectionEquality().equals(other._song, _song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_artist),const DeepCollectionEquality().hash(_album),const DeepCollectionEquality().hash(_song));

@override
String toString() {
  return 'SubsonicItemSetDTO(artist: $artist, album: $album, song: $song)';
}


}

/// @nodoc
abstract mixin class _$SubsonicItemSetDTOCopyWith<$Res> implements $SubsonicItemSetDTOCopyWith<$Res> {
  factory _$SubsonicItemSetDTOCopyWith(_SubsonicItemSetDTO value, $Res Function(_SubsonicItemSetDTO) _then) = __$SubsonicItemSetDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicArtistDTO> artist, List<SubsonicAlbumDTO> album, List<SubsonicChildDTO> song
});




}
/// @nodoc
class __$SubsonicItemSetDTOCopyWithImpl<$Res>
    implements _$SubsonicItemSetDTOCopyWith<$Res> {
  __$SubsonicItemSetDTOCopyWithImpl(this._self, this._then);

  final _SubsonicItemSetDTO _self;
  final $Res Function(_SubsonicItemSetDTO) _then;

/// Create a copy of SubsonicItemSetDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artist = null,Object? album = null,Object? song = null,}) {
  return _then(_SubsonicItemSetDTO(
artist: null == artist ? _self._artist : artist // ignore: cast_nullable_to_non_nullable
as List<SubsonicArtistDTO>,album: null == album ? _self._album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,song: null == song ? _self._song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicAlbumListDTO {

 List<SubsonicAlbumDTO> get album;
/// Create a copy of SubsonicAlbumListDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicAlbumListDTOCopyWith<SubsonicAlbumListDTO> get copyWith => _$SubsonicAlbumListDTOCopyWithImpl<SubsonicAlbumListDTO>(this as SubsonicAlbumListDTO, _$identity);

  /// Serializes this SubsonicAlbumListDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicAlbumListDTO&&const DeepCollectionEquality().equals(other.album, album));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(album));

@override
String toString() {
  return 'SubsonicAlbumListDTO(album: $album)';
}


}

/// @nodoc
abstract mixin class $SubsonicAlbumListDTOCopyWith<$Res>  {
  factory $SubsonicAlbumListDTOCopyWith(SubsonicAlbumListDTO value, $Res Function(SubsonicAlbumListDTO) _then) = _$SubsonicAlbumListDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicAlbumDTO> album
});




}
/// @nodoc
class _$SubsonicAlbumListDTOCopyWithImpl<$Res>
    implements $SubsonicAlbumListDTOCopyWith<$Res> {
  _$SubsonicAlbumListDTOCopyWithImpl(this._self, this._then);

  final SubsonicAlbumListDTO _self;
  final $Res Function(SubsonicAlbumListDTO) _then;

/// Create a copy of SubsonicAlbumListDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,}) {
  return _then(_self.copyWith(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicAlbumListDTO].
extension SubsonicAlbumListDTOPatterns on SubsonicAlbumListDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicAlbumListDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicAlbumListDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicAlbumListDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicAlbumDTO> album)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO() when $default != null:
return $default(_that.album);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicAlbumDTO> album)  $default,) {final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO():
return $default(_that.album);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicAlbumDTO> album)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicAlbumListDTO() when $default != null:
return $default(_that.album);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicAlbumListDTO implements SubsonicAlbumListDTO {
  const _SubsonicAlbumListDTO({final  List<SubsonicAlbumDTO> album = const []}): _album = album;
  factory _SubsonicAlbumListDTO.fromJson(Map<String, dynamic> json) => _$SubsonicAlbumListDTOFromJson(json);

 final  List<SubsonicAlbumDTO> _album;
@override@JsonKey() List<SubsonicAlbumDTO> get album {
  if (_album is EqualUnmodifiableListView) return _album;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_album);
}


/// Create a copy of SubsonicAlbumListDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicAlbumListDTOCopyWith<_SubsonicAlbumListDTO> get copyWith => __$SubsonicAlbumListDTOCopyWithImpl<_SubsonicAlbumListDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicAlbumListDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicAlbumListDTO&&const DeepCollectionEquality().equals(other._album, _album));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_album));

@override
String toString() {
  return 'SubsonicAlbumListDTO(album: $album)';
}


}

/// @nodoc
abstract mixin class _$SubsonicAlbumListDTOCopyWith<$Res> implements $SubsonicAlbumListDTOCopyWith<$Res> {
  factory _$SubsonicAlbumListDTOCopyWith(_SubsonicAlbumListDTO value, $Res Function(_SubsonicAlbumListDTO) _then) = __$SubsonicAlbumListDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicAlbumDTO> album
});




}
/// @nodoc
class __$SubsonicAlbumListDTOCopyWithImpl<$Res>
    implements _$SubsonicAlbumListDTOCopyWith<$Res> {
  __$SubsonicAlbumListDTOCopyWithImpl(this._self, this._then);

  final _SubsonicAlbumListDTO _self;
  final $Res Function(_SubsonicAlbumListDTO) _then;

/// Create a copy of SubsonicAlbumListDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? album = null,}) {
  return _then(_SubsonicAlbumListDTO(
album: null == album ? _self._album : album // ignore: cast_nullable_to_non_nullable
as List<SubsonicAlbumDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicSongListDTO {

 List<SubsonicChildDTO> get song;
/// Create a copy of SubsonicSongListDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicSongListDTOCopyWith<SubsonicSongListDTO> get copyWith => _$SubsonicSongListDTOCopyWithImpl<SubsonicSongListDTO>(this as SubsonicSongListDTO, _$identity);

  /// Serializes this SubsonicSongListDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicSongListDTO&&const DeepCollectionEquality().equals(other.song, song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(song));

@override
String toString() {
  return 'SubsonicSongListDTO(song: $song)';
}


}

/// @nodoc
abstract mixin class $SubsonicSongListDTOCopyWith<$Res>  {
  factory $SubsonicSongListDTOCopyWith(SubsonicSongListDTO value, $Res Function(SubsonicSongListDTO) _then) = _$SubsonicSongListDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicChildDTO> song
});




}
/// @nodoc
class _$SubsonicSongListDTOCopyWithImpl<$Res>
    implements $SubsonicSongListDTOCopyWith<$Res> {
  _$SubsonicSongListDTOCopyWithImpl(this._self, this._then);

  final SubsonicSongListDTO _self;
  final $Res Function(SubsonicSongListDTO) _then;

/// Create a copy of SubsonicSongListDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? song = null,}) {
  return _then(_self.copyWith(
song: null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicSongListDTO].
extension SubsonicSongListDTOPatterns on SubsonicSongListDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicSongListDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicSongListDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicSongListDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicSongListDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicSongListDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicSongListDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicChildDTO> song)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicSongListDTO() when $default != null:
return $default(_that.song);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicChildDTO> song)  $default,) {final _that = this;
switch (_that) {
case _SubsonicSongListDTO():
return $default(_that.song);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicChildDTO> song)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicSongListDTO() when $default != null:
return $default(_that.song);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicSongListDTO implements SubsonicSongListDTO {
  const _SubsonicSongListDTO({final  List<SubsonicChildDTO> song = const []}): _song = song;
  factory _SubsonicSongListDTO.fromJson(Map<String, dynamic> json) => _$SubsonicSongListDTOFromJson(json);

 final  List<SubsonicChildDTO> _song;
@override@JsonKey() List<SubsonicChildDTO> get song {
  if (_song is EqualUnmodifiableListView) return _song;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_song);
}


/// Create a copy of SubsonicSongListDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicSongListDTOCopyWith<_SubsonicSongListDTO> get copyWith => __$SubsonicSongListDTOCopyWithImpl<_SubsonicSongListDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicSongListDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicSongListDTO&&const DeepCollectionEquality().equals(other._song, _song));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_song));

@override
String toString() {
  return 'SubsonicSongListDTO(song: $song)';
}


}

/// @nodoc
abstract mixin class _$SubsonicSongListDTOCopyWith<$Res> implements $SubsonicSongListDTOCopyWith<$Res> {
  factory _$SubsonicSongListDTOCopyWith(_SubsonicSongListDTO value, $Res Function(_SubsonicSongListDTO) _then) = __$SubsonicSongListDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicChildDTO> song
});




}
/// @nodoc
class __$SubsonicSongListDTOCopyWithImpl<$Res>
    implements _$SubsonicSongListDTOCopyWith<$Res> {
  __$SubsonicSongListDTOCopyWithImpl(this._self, this._then);

  final _SubsonicSongListDTO _self;
  final $Res Function(_SubsonicSongListDTO) _then;

/// Create a copy of SubsonicSongListDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? song = null,}) {
  return _then(_SubsonicSongListDTO(
song: null == song ? _self._song : song // ignore: cast_nullable_to_non_nullable
as List<SubsonicChildDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicLyricLineDTO {

 int? get start; String get value;
/// Create a copy of SubsonicLyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicLyricLineDTOCopyWith<SubsonicLyricLineDTO> get copyWith => _$SubsonicLyricLineDTOCopyWithImpl<SubsonicLyricLineDTO>(this as SubsonicLyricLineDTO, _$identity);

  /// Serializes this SubsonicLyricLineDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicLyricLineDTO&&(identical(other.start, start) || other.start == start)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,value);

@override
String toString() {
  return 'SubsonicLyricLineDTO(start: $start, value: $value)';
}


}

/// @nodoc
abstract mixin class $SubsonicLyricLineDTOCopyWith<$Res>  {
  factory $SubsonicLyricLineDTOCopyWith(SubsonicLyricLineDTO value, $Res Function(SubsonicLyricLineDTO) _then) = _$SubsonicLyricLineDTOCopyWithImpl;
@useResult
$Res call({
 int? start, String value
});




}
/// @nodoc
class _$SubsonicLyricLineDTOCopyWithImpl<$Res>
    implements $SubsonicLyricLineDTOCopyWith<$Res> {
  _$SubsonicLyricLineDTOCopyWithImpl(this._self, this._then);

  final SubsonicLyricLineDTO _self;
  final $Res Function(SubsonicLyricLineDTO) _then;

/// Create a copy of SubsonicLyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = freezed,Object? value = null,}) {
  return _then(_self.copyWith(
start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicLyricLineDTO].
extension SubsonicLyricLineDTOPatterns on SubsonicLyricLineDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicLyricLineDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicLyricLineDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicLyricLineDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? start,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO() when $default != null:
return $default(_that.start,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? start,  String value)  $default,) {final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO():
return $default(_that.start,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? start,  String value)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicLyricLineDTO() when $default != null:
return $default(_that.start,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicLyricLineDTO implements SubsonicLyricLineDTO {
  const _SubsonicLyricLineDTO({this.start, this.value = ''});
  factory _SubsonicLyricLineDTO.fromJson(Map<String, dynamic> json) => _$SubsonicLyricLineDTOFromJson(json);

@override final  int? start;
@override@JsonKey() final  String value;

/// Create a copy of SubsonicLyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicLyricLineDTOCopyWith<_SubsonicLyricLineDTO> get copyWith => __$SubsonicLyricLineDTOCopyWithImpl<_SubsonicLyricLineDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicLyricLineDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicLyricLineDTO&&(identical(other.start, start) || other.start == start)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,value);

@override
String toString() {
  return 'SubsonicLyricLineDTO(start: $start, value: $value)';
}


}

/// @nodoc
abstract mixin class _$SubsonicLyricLineDTOCopyWith<$Res> implements $SubsonicLyricLineDTOCopyWith<$Res> {
  factory _$SubsonicLyricLineDTOCopyWith(_SubsonicLyricLineDTO value, $Res Function(_SubsonicLyricLineDTO) _then) = __$SubsonicLyricLineDTOCopyWithImpl;
@override @useResult
$Res call({
 int? start, String value
});




}
/// @nodoc
class __$SubsonicLyricLineDTOCopyWithImpl<$Res>
    implements _$SubsonicLyricLineDTOCopyWith<$Res> {
  __$SubsonicLyricLineDTOCopyWithImpl(this._self, this._then);

  final _SubsonicLyricLineDTO _self;
  final $Res Function(_SubsonicLyricLineDTO) _then;

/// Create a copy of SubsonicLyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = freezed,Object? value = null,}) {
  return _then(_SubsonicLyricLineDTO(
start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubsonicStructuredLyricsDTO {

 String? get lang; bool get synced; int? get offset; String? get displayArtist; String? get displayTitle; List<SubsonicLyricLineDTO> get line;
/// Create a copy of SubsonicStructuredLyricsDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicStructuredLyricsDTOCopyWith<SubsonicStructuredLyricsDTO> get copyWith => _$SubsonicStructuredLyricsDTOCopyWithImpl<SubsonicStructuredLyricsDTO>(this as SubsonicStructuredLyricsDTO, _$identity);

  /// Serializes this SubsonicStructuredLyricsDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicStructuredLyricsDTO&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.displayTitle, displayTitle) || other.displayTitle == displayTitle)&&const DeepCollectionEquality().equals(other.line, line));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lang,synced,offset,displayArtist,displayTitle,const DeepCollectionEquality().hash(line));

@override
String toString() {
  return 'SubsonicStructuredLyricsDTO(lang: $lang, synced: $synced, offset: $offset, displayArtist: $displayArtist, displayTitle: $displayTitle, line: $line)';
}


}

/// @nodoc
abstract mixin class $SubsonicStructuredLyricsDTOCopyWith<$Res>  {
  factory $SubsonicStructuredLyricsDTOCopyWith(SubsonicStructuredLyricsDTO value, $Res Function(SubsonicStructuredLyricsDTO) _then) = _$SubsonicStructuredLyricsDTOCopyWithImpl;
@useResult
$Res call({
 String? lang, bool synced, int? offset, String? displayArtist, String? displayTitle, List<SubsonicLyricLineDTO> line
});




}
/// @nodoc
class _$SubsonicStructuredLyricsDTOCopyWithImpl<$Res>
    implements $SubsonicStructuredLyricsDTOCopyWith<$Res> {
  _$SubsonicStructuredLyricsDTOCopyWithImpl(this._self, this._then);

  final SubsonicStructuredLyricsDTO _self;
  final $Res Function(SubsonicStructuredLyricsDTO) _then;

/// Create a copy of SubsonicStructuredLyricsDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lang = freezed,Object? synced = null,Object? offset = freezed,Object? displayArtist = freezed,Object? displayTitle = freezed,Object? line = null,}) {
  return _then(_self.copyWith(
lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,displayTitle: freezed == displayTitle ? _self.displayTitle : displayTitle // ignore: cast_nullable_to_non_nullable
as String?,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as List<SubsonicLyricLineDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicStructuredLyricsDTO].
extension SubsonicStructuredLyricsDTOPatterns on SubsonicStructuredLyricsDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicStructuredLyricsDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicStructuredLyricsDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicStructuredLyricsDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? lang,  bool synced,  int? offset,  String? displayArtist,  String? displayTitle,  List<SubsonicLyricLineDTO> line)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO() when $default != null:
return $default(_that.lang,_that.synced,_that.offset,_that.displayArtist,_that.displayTitle,_that.line);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? lang,  bool synced,  int? offset,  String? displayArtist,  String? displayTitle,  List<SubsonicLyricLineDTO> line)  $default,) {final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO():
return $default(_that.lang,_that.synced,_that.offset,_that.displayArtist,_that.displayTitle,_that.line);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? lang,  bool synced,  int? offset,  String? displayArtist,  String? displayTitle,  List<SubsonicLyricLineDTO> line)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicStructuredLyricsDTO() when $default != null:
return $default(_that.lang,_that.synced,_that.offset,_that.displayArtist,_that.displayTitle,_that.line);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicStructuredLyricsDTO implements SubsonicStructuredLyricsDTO {
  const _SubsonicStructuredLyricsDTO({this.lang, this.synced = false, this.offset, this.displayArtist, this.displayTitle, final  List<SubsonicLyricLineDTO> line = const []}): _line = line;
  factory _SubsonicStructuredLyricsDTO.fromJson(Map<String, dynamic> json) => _$SubsonicStructuredLyricsDTOFromJson(json);

@override final  String? lang;
@override@JsonKey() final  bool synced;
@override final  int? offset;
@override final  String? displayArtist;
@override final  String? displayTitle;
 final  List<SubsonicLyricLineDTO> _line;
@override@JsonKey() List<SubsonicLyricLineDTO> get line {
  if (_line is EqualUnmodifiableListView) return _line;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_line);
}


/// Create a copy of SubsonicStructuredLyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicStructuredLyricsDTOCopyWith<_SubsonicStructuredLyricsDTO> get copyWith => __$SubsonicStructuredLyricsDTOCopyWithImpl<_SubsonicStructuredLyricsDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicStructuredLyricsDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicStructuredLyricsDTO&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.displayArtist, displayArtist) || other.displayArtist == displayArtist)&&(identical(other.displayTitle, displayTitle) || other.displayTitle == displayTitle)&&const DeepCollectionEquality().equals(other._line, _line));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lang,synced,offset,displayArtist,displayTitle,const DeepCollectionEquality().hash(_line));

@override
String toString() {
  return 'SubsonicStructuredLyricsDTO(lang: $lang, synced: $synced, offset: $offset, displayArtist: $displayArtist, displayTitle: $displayTitle, line: $line)';
}


}

/// @nodoc
abstract mixin class _$SubsonicStructuredLyricsDTOCopyWith<$Res> implements $SubsonicStructuredLyricsDTOCopyWith<$Res> {
  factory _$SubsonicStructuredLyricsDTOCopyWith(_SubsonicStructuredLyricsDTO value, $Res Function(_SubsonicStructuredLyricsDTO) _then) = __$SubsonicStructuredLyricsDTOCopyWithImpl;
@override @useResult
$Res call({
 String? lang, bool synced, int? offset, String? displayArtist, String? displayTitle, List<SubsonicLyricLineDTO> line
});




}
/// @nodoc
class __$SubsonicStructuredLyricsDTOCopyWithImpl<$Res>
    implements _$SubsonicStructuredLyricsDTOCopyWith<$Res> {
  __$SubsonicStructuredLyricsDTOCopyWithImpl(this._self, this._then);

  final _SubsonicStructuredLyricsDTO _self;
  final $Res Function(_SubsonicStructuredLyricsDTO) _then;

/// Create a copy of SubsonicStructuredLyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lang = freezed,Object? synced = null,Object? offset = freezed,Object? displayArtist = freezed,Object? displayTitle = freezed,Object? line = null,}) {
  return _then(_SubsonicStructuredLyricsDTO(
lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,displayArtist: freezed == displayArtist ? _self.displayArtist : displayArtist // ignore: cast_nullable_to_non_nullable
as String?,displayTitle: freezed == displayTitle ? _self.displayTitle : displayTitle // ignore: cast_nullable_to_non_nullable
as String?,line: null == line ? _self._line : line // ignore: cast_nullable_to_non_nullable
as List<SubsonicLyricLineDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicLyricsListDTO {

 List<SubsonicStructuredLyricsDTO> get structuredLyrics;
/// Create a copy of SubsonicLyricsListDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicLyricsListDTOCopyWith<SubsonicLyricsListDTO> get copyWith => _$SubsonicLyricsListDTOCopyWithImpl<SubsonicLyricsListDTO>(this as SubsonicLyricsListDTO, _$identity);

  /// Serializes this SubsonicLyricsListDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicLyricsListDTO&&const DeepCollectionEquality().equals(other.structuredLyrics, structuredLyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(structuredLyrics));

@override
String toString() {
  return 'SubsonicLyricsListDTO(structuredLyrics: $structuredLyrics)';
}


}

/// @nodoc
abstract mixin class $SubsonicLyricsListDTOCopyWith<$Res>  {
  factory $SubsonicLyricsListDTOCopyWith(SubsonicLyricsListDTO value, $Res Function(SubsonicLyricsListDTO) _then) = _$SubsonicLyricsListDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicStructuredLyricsDTO> structuredLyrics
});




}
/// @nodoc
class _$SubsonicLyricsListDTOCopyWithImpl<$Res>
    implements $SubsonicLyricsListDTOCopyWith<$Res> {
  _$SubsonicLyricsListDTOCopyWithImpl(this._self, this._then);

  final SubsonicLyricsListDTO _self;
  final $Res Function(SubsonicLyricsListDTO) _then;

/// Create a copy of SubsonicLyricsListDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? structuredLyrics = null,}) {
  return _then(_self.copyWith(
structuredLyrics: null == structuredLyrics ? _self.structuredLyrics : structuredLyrics // ignore: cast_nullable_to_non_nullable
as List<SubsonicStructuredLyricsDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicLyricsListDTO].
extension SubsonicLyricsListDTOPatterns on SubsonicLyricsListDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicLyricsListDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicLyricsListDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicLyricsListDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicStructuredLyricsDTO> structuredLyrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO() when $default != null:
return $default(_that.structuredLyrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicStructuredLyricsDTO> structuredLyrics)  $default,) {final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO():
return $default(_that.structuredLyrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicStructuredLyricsDTO> structuredLyrics)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicLyricsListDTO() when $default != null:
return $default(_that.structuredLyrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicLyricsListDTO implements SubsonicLyricsListDTO {
  const _SubsonicLyricsListDTO({final  List<SubsonicStructuredLyricsDTO> structuredLyrics = const []}): _structuredLyrics = structuredLyrics;
  factory _SubsonicLyricsListDTO.fromJson(Map<String, dynamic> json) => _$SubsonicLyricsListDTOFromJson(json);

 final  List<SubsonicStructuredLyricsDTO> _structuredLyrics;
@override@JsonKey() List<SubsonicStructuredLyricsDTO> get structuredLyrics {
  if (_structuredLyrics is EqualUnmodifiableListView) return _structuredLyrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_structuredLyrics);
}


/// Create a copy of SubsonicLyricsListDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicLyricsListDTOCopyWith<_SubsonicLyricsListDTO> get copyWith => __$SubsonicLyricsListDTOCopyWithImpl<_SubsonicLyricsListDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicLyricsListDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicLyricsListDTO&&const DeepCollectionEquality().equals(other._structuredLyrics, _structuredLyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_structuredLyrics));

@override
String toString() {
  return 'SubsonicLyricsListDTO(structuredLyrics: $structuredLyrics)';
}


}

/// @nodoc
abstract mixin class _$SubsonicLyricsListDTOCopyWith<$Res> implements $SubsonicLyricsListDTOCopyWith<$Res> {
  factory _$SubsonicLyricsListDTOCopyWith(_SubsonicLyricsListDTO value, $Res Function(_SubsonicLyricsListDTO) _then) = __$SubsonicLyricsListDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicStructuredLyricsDTO> structuredLyrics
});




}
/// @nodoc
class __$SubsonicLyricsListDTOCopyWithImpl<$Res>
    implements _$SubsonicLyricsListDTOCopyWith<$Res> {
  __$SubsonicLyricsListDTOCopyWithImpl(this._self, this._then);

  final _SubsonicLyricsListDTO _self;
  final $Res Function(_SubsonicLyricsListDTO) _then;

/// Create a copy of SubsonicLyricsListDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? structuredLyrics = null,}) {
  return _then(_SubsonicLyricsListDTO(
structuredLyrics: null == structuredLyrics ? _self._structuredLyrics : structuredLyrics // ignore: cast_nullable_to_non_nullable
as List<SubsonicStructuredLyricsDTO>,
  ));
}


}


/// @nodoc
mixin _$SubsonicExtensionDTO {

 String get name; List<int> get versions;
/// Create a copy of SubsonicExtensionDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicExtensionDTOCopyWith<SubsonicExtensionDTO> get copyWith => _$SubsonicExtensionDTOCopyWithImpl<SubsonicExtensionDTO>(this as SubsonicExtensionDTO, _$identity);

  /// Serializes this SubsonicExtensionDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicExtensionDTO&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.versions, versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(versions));

@override
String toString() {
  return 'SubsonicExtensionDTO(name: $name, versions: $versions)';
}


}

/// @nodoc
abstract mixin class $SubsonicExtensionDTOCopyWith<$Res>  {
  factory $SubsonicExtensionDTOCopyWith(SubsonicExtensionDTO value, $Res Function(SubsonicExtensionDTO) _then) = _$SubsonicExtensionDTOCopyWithImpl;
@useResult
$Res call({
 String name, List<int> versions
});




}
/// @nodoc
class _$SubsonicExtensionDTOCopyWithImpl<$Res>
    implements $SubsonicExtensionDTOCopyWith<$Res> {
  _$SubsonicExtensionDTOCopyWithImpl(this._self, this._then);

  final SubsonicExtensionDTO _self;
  final $Res Function(SubsonicExtensionDTO) _then;

/// Create a copy of SubsonicExtensionDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? versions = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicExtensionDTO].
extension SubsonicExtensionDTOPatterns on SubsonicExtensionDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicExtensionDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicExtensionDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicExtensionDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicExtensionDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicExtensionDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicExtensionDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<int> versions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicExtensionDTO() when $default != null:
return $default(_that.name,_that.versions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<int> versions)  $default,) {final _that = this;
switch (_that) {
case _SubsonicExtensionDTO():
return $default(_that.name,_that.versions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<int> versions)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicExtensionDTO() when $default != null:
return $default(_that.name,_that.versions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicExtensionDTO implements SubsonicExtensionDTO {
  const _SubsonicExtensionDTO({this.name = '', final  List<int> versions = const []}): _versions = versions;
  factory _SubsonicExtensionDTO.fromJson(Map<String, dynamic> json) => _$SubsonicExtensionDTOFromJson(json);

@override@JsonKey() final  String name;
 final  List<int> _versions;
@override@JsonKey() List<int> get versions {
  if (_versions is EqualUnmodifiableListView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_versions);
}


/// Create a copy of SubsonicExtensionDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicExtensionDTOCopyWith<_SubsonicExtensionDTO> get copyWith => __$SubsonicExtensionDTOCopyWithImpl<_SubsonicExtensionDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicExtensionDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicExtensionDTO&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._versions, _versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_versions));

@override
String toString() {
  return 'SubsonicExtensionDTO(name: $name, versions: $versions)';
}


}

/// @nodoc
abstract mixin class _$SubsonicExtensionDTOCopyWith<$Res> implements $SubsonicExtensionDTOCopyWith<$Res> {
  factory _$SubsonicExtensionDTOCopyWith(_SubsonicExtensionDTO value, $Res Function(_SubsonicExtensionDTO) _then) = __$SubsonicExtensionDTOCopyWithImpl;
@override @useResult
$Res call({
 String name, List<int> versions
});




}
/// @nodoc
class __$SubsonicExtensionDTOCopyWithImpl<$Res>
    implements _$SubsonicExtensionDTOCopyWith<$Res> {
  __$SubsonicExtensionDTOCopyWithImpl(this._self, this._then);

  final _SubsonicExtensionDTO _self;
  final $Res Function(_SubsonicExtensionDTO) _then;

/// Create a copy of SubsonicExtensionDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? versions = null,}) {
  return _then(_SubsonicExtensionDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}


/// @nodoc
mixin _$SubsonicExtensionsDTO {

 List<SubsonicExtensionDTO> get openSubsonicExtensions;
/// Create a copy of SubsonicExtensionsDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubsonicExtensionsDTOCopyWith<SubsonicExtensionsDTO> get copyWith => _$SubsonicExtensionsDTOCopyWithImpl<SubsonicExtensionsDTO>(this as SubsonicExtensionsDTO, _$identity);

  /// Serializes this SubsonicExtensionsDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubsonicExtensionsDTO&&const DeepCollectionEquality().equals(other.openSubsonicExtensions, openSubsonicExtensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(openSubsonicExtensions));

@override
String toString() {
  return 'SubsonicExtensionsDTO(openSubsonicExtensions: $openSubsonicExtensions)';
}


}

/// @nodoc
abstract mixin class $SubsonicExtensionsDTOCopyWith<$Res>  {
  factory $SubsonicExtensionsDTOCopyWith(SubsonicExtensionsDTO value, $Res Function(SubsonicExtensionsDTO) _then) = _$SubsonicExtensionsDTOCopyWithImpl;
@useResult
$Res call({
 List<SubsonicExtensionDTO> openSubsonicExtensions
});




}
/// @nodoc
class _$SubsonicExtensionsDTOCopyWithImpl<$Res>
    implements $SubsonicExtensionsDTOCopyWith<$Res> {
  _$SubsonicExtensionsDTOCopyWithImpl(this._self, this._then);

  final SubsonicExtensionsDTO _self;
  final $Res Function(SubsonicExtensionsDTO) _then;

/// Create a copy of SubsonicExtensionsDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? openSubsonicExtensions = null,}) {
  return _then(_self.copyWith(
openSubsonicExtensions: null == openSubsonicExtensions ? _self.openSubsonicExtensions : openSubsonicExtensions // ignore: cast_nullable_to_non_nullable
as List<SubsonicExtensionDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubsonicExtensionsDTO].
extension SubsonicExtensionsDTOPatterns on SubsonicExtensionsDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubsonicExtensionsDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubsonicExtensionsDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubsonicExtensionsDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubsonicExtensionDTO> openSubsonicExtensions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO() when $default != null:
return $default(_that.openSubsonicExtensions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubsonicExtensionDTO> openSubsonicExtensions)  $default,) {final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO():
return $default(_that.openSubsonicExtensions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubsonicExtensionDTO> openSubsonicExtensions)?  $default,) {final _that = this;
switch (_that) {
case _SubsonicExtensionsDTO() when $default != null:
return $default(_that.openSubsonicExtensions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubsonicExtensionsDTO implements SubsonicExtensionsDTO {
  const _SubsonicExtensionsDTO({final  List<SubsonicExtensionDTO> openSubsonicExtensions = const []}): _openSubsonicExtensions = openSubsonicExtensions;
  factory _SubsonicExtensionsDTO.fromJson(Map<String, dynamic> json) => _$SubsonicExtensionsDTOFromJson(json);

 final  List<SubsonicExtensionDTO> _openSubsonicExtensions;
@override@JsonKey() List<SubsonicExtensionDTO> get openSubsonicExtensions {
  if (_openSubsonicExtensions is EqualUnmodifiableListView) return _openSubsonicExtensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openSubsonicExtensions);
}


/// Create a copy of SubsonicExtensionsDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubsonicExtensionsDTOCopyWith<_SubsonicExtensionsDTO> get copyWith => __$SubsonicExtensionsDTOCopyWithImpl<_SubsonicExtensionsDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubsonicExtensionsDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubsonicExtensionsDTO&&const DeepCollectionEquality().equals(other._openSubsonicExtensions, _openSubsonicExtensions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_openSubsonicExtensions));

@override
String toString() {
  return 'SubsonicExtensionsDTO(openSubsonicExtensions: $openSubsonicExtensions)';
}


}

/// @nodoc
abstract mixin class _$SubsonicExtensionsDTOCopyWith<$Res> implements $SubsonicExtensionsDTOCopyWith<$Res> {
  factory _$SubsonicExtensionsDTOCopyWith(_SubsonicExtensionsDTO value, $Res Function(_SubsonicExtensionsDTO) _then) = __$SubsonicExtensionsDTOCopyWithImpl;
@override @useResult
$Res call({
 List<SubsonicExtensionDTO> openSubsonicExtensions
});




}
/// @nodoc
class __$SubsonicExtensionsDTOCopyWithImpl<$Res>
    implements _$SubsonicExtensionsDTOCopyWith<$Res> {
  __$SubsonicExtensionsDTOCopyWithImpl(this._self, this._then);

  final _SubsonicExtensionsDTO _self;
  final $Res Function(_SubsonicExtensionsDTO) _then;

/// Create a copy of SubsonicExtensionsDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? openSubsonicExtensions = null,}) {
  return _then(_SubsonicExtensionsDTO(
openSubsonicExtensions: null == openSubsonicExtensions ? _self._openSubsonicExtensions : openSubsonicExtensions // ignore: cast_nullable_to_non_nullable
as List<SubsonicExtensionDTO>,
  ));
}


}

// dart format on
