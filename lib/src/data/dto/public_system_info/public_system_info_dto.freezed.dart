// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_system_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PublicSystemInfoDTO {

@JsonKey(name: 'Id') String? get id;@JsonKey(name: 'ServerName') String? get serverName;@JsonKey(name: 'Version') String? get version;@JsonKey(name: 'ProductName') String? get productName;@JsonKey(name: 'OperatingSystem') String? get operatingSystem;@JsonKey(name: 'LocalAddress') String? get localAddress;@JsonKey(name: 'LocalAddresses') List<String>? get localAddresses;@JsonKey(name: 'RemoteAddresses') List<String>? get remoteAddresses;@JsonKey(name: 'StartupWizardCompleted') bool? get startupWizardCompleted;
/// Create a copy of PublicSystemInfoDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicSystemInfoDTOCopyWith<PublicSystemInfoDTO> get copyWith => _$PublicSystemInfoDTOCopyWithImpl<PublicSystemInfoDTO>(this as PublicSystemInfoDTO, _$identity);

  /// Serializes this PublicSystemInfoDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicSystemInfoDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.version, version) || other.version == version)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.operatingSystem, operatingSystem) || other.operatingSystem == operatingSystem)&&(identical(other.localAddress, localAddress) || other.localAddress == localAddress)&&const DeepCollectionEquality().equals(other.localAddresses, localAddresses)&&const DeepCollectionEquality().equals(other.remoteAddresses, remoteAddresses)&&(identical(other.startupWizardCompleted, startupWizardCompleted) || other.startupWizardCompleted == startupWizardCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serverName,version,productName,operatingSystem,localAddress,const DeepCollectionEquality().hash(localAddresses),const DeepCollectionEquality().hash(remoteAddresses),startupWizardCompleted);

@override
String toString() {
  return 'PublicSystemInfoDTO(id: $id, serverName: $serverName, version: $version, productName: $productName, operatingSystem: $operatingSystem, localAddress: $localAddress, localAddresses: $localAddresses, remoteAddresses: $remoteAddresses, startupWizardCompleted: $startupWizardCompleted)';
}


}

/// @nodoc
abstract mixin class $PublicSystemInfoDTOCopyWith<$Res>  {
  factory $PublicSystemInfoDTOCopyWith(PublicSystemInfoDTO value, $Res Function(PublicSystemInfoDTO) _then) = _$PublicSystemInfoDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String? id,@JsonKey(name: 'ServerName') String? serverName,@JsonKey(name: 'Version') String? version,@JsonKey(name: 'ProductName') String? productName,@JsonKey(name: 'OperatingSystem') String? operatingSystem,@JsonKey(name: 'LocalAddress') String? localAddress,@JsonKey(name: 'LocalAddresses') List<String>? localAddresses,@JsonKey(name: 'RemoteAddresses') List<String>? remoteAddresses,@JsonKey(name: 'StartupWizardCompleted') bool? startupWizardCompleted
});




}
/// @nodoc
class _$PublicSystemInfoDTOCopyWithImpl<$Res>
    implements $PublicSystemInfoDTOCopyWith<$Res> {
  _$PublicSystemInfoDTOCopyWithImpl(this._self, this._then);

  final PublicSystemInfoDTO _self;
  final $Res Function(PublicSystemInfoDTO) _then;

/// Create a copy of PublicSystemInfoDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? serverName = freezed,Object? version = freezed,Object? productName = freezed,Object? operatingSystem = freezed,Object? localAddress = freezed,Object? localAddresses = freezed,Object? remoteAddresses = freezed,Object? startupWizardCompleted = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,operatingSystem: freezed == operatingSystem ? _self.operatingSystem : operatingSystem // ignore: cast_nullable_to_non_nullable
as String?,localAddress: freezed == localAddress ? _self.localAddress : localAddress // ignore: cast_nullable_to_non_nullable
as String?,localAddresses: freezed == localAddresses ? _self.localAddresses : localAddresses // ignore: cast_nullable_to_non_nullable
as List<String>?,remoteAddresses: freezed == remoteAddresses ? _self.remoteAddresses : remoteAddresses // ignore: cast_nullable_to_non_nullable
as List<String>?,startupWizardCompleted: freezed == startupWizardCompleted ? _self.startupWizardCompleted : startupWizardCompleted // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicSystemInfoDTO].
extension PublicSystemInfoDTOPatterns on PublicSystemInfoDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicSystemInfoDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicSystemInfoDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicSystemInfoDTO value)  $default,){
final _that = this;
switch (_that) {
case _PublicSystemInfoDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicSystemInfoDTO value)?  $default,){
final _that = this;
switch (_that) {
case _PublicSystemInfoDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String? id, @JsonKey(name: 'ServerName')  String? serverName, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'ProductName')  String? productName, @JsonKey(name: 'OperatingSystem')  String? operatingSystem, @JsonKey(name: 'LocalAddress')  String? localAddress, @JsonKey(name: 'LocalAddresses')  List<String>? localAddresses, @JsonKey(name: 'RemoteAddresses')  List<String>? remoteAddresses, @JsonKey(name: 'StartupWizardCompleted')  bool? startupWizardCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicSystemInfoDTO() when $default != null:
return $default(_that.id,_that.serverName,_that.version,_that.productName,_that.operatingSystem,_that.localAddress,_that.localAddresses,_that.remoteAddresses,_that.startupWizardCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String? id, @JsonKey(name: 'ServerName')  String? serverName, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'ProductName')  String? productName, @JsonKey(name: 'OperatingSystem')  String? operatingSystem, @JsonKey(name: 'LocalAddress')  String? localAddress, @JsonKey(name: 'LocalAddresses')  List<String>? localAddresses, @JsonKey(name: 'RemoteAddresses')  List<String>? remoteAddresses, @JsonKey(name: 'StartupWizardCompleted')  bool? startupWizardCompleted)  $default,) {final _that = this;
switch (_that) {
case _PublicSystemInfoDTO():
return $default(_that.id,_that.serverName,_that.version,_that.productName,_that.operatingSystem,_that.localAddress,_that.localAddresses,_that.remoteAddresses,_that.startupWizardCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String? id, @JsonKey(name: 'ServerName')  String? serverName, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'ProductName')  String? productName, @JsonKey(name: 'OperatingSystem')  String? operatingSystem, @JsonKey(name: 'LocalAddress')  String? localAddress, @JsonKey(name: 'LocalAddresses')  List<String>? localAddresses, @JsonKey(name: 'RemoteAddresses')  List<String>? remoteAddresses, @JsonKey(name: 'StartupWizardCompleted')  bool? startupWizardCompleted)?  $default,) {final _that = this;
switch (_that) {
case _PublicSystemInfoDTO() when $default != null:
return $default(_that.id,_that.serverName,_that.version,_that.productName,_that.operatingSystem,_that.localAddress,_that.localAddresses,_that.remoteAddresses,_that.startupWizardCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicSystemInfoDTO implements PublicSystemInfoDTO {
  const _PublicSystemInfoDTO({@JsonKey(name: 'Id') this.id, @JsonKey(name: 'ServerName') this.serverName, @JsonKey(name: 'Version') this.version, @JsonKey(name: 'ProductName') this.productName, @JsonKey(name: 'OperatingSystem') this.operatingSystem, @JsonKey(name: 'LocalAddress') this.localAddress, @JsonKey(name: 'LocalAddresses') final  List<String>? localAddresses, @JsonKey(name: 'RemoteAddresses') final  List<String>? remoteAddresses, @JsonKey(name: 'StartupWizardCompleted') this.startupWizardCompleted}): _localAddresses = localAddresses,_remoteAddresses = remoteAddresses;
  factory _PublicSystemInfoDTO.fromJson(Map<String, dynamic> json) => _$PublicSystemInfoDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String? id;
@override@JsonKey(name: 'ServerName') final  String? serverName;
@override@JsonKey(name: 'Version') final  String? version;
@override@JsonKey(name: 'ProductName') final  String? productName;
@override@JsonKey(name: 'OperatingSystem') final  String? operatingSystem;
@override@JsonKey(name: 'LocalAddress') final  String? localAddress;
 final  List<String>? _localAddresses;
@override@JsonKey(name: 'LocalAddresses') List<String>? get localAddresses {
  final value = _localAddresses;
  if (value == null) return null;
  if (_localAddresses is EqualUnmodifiableListView) return _localAddresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _remoteAddresses;
@override@JsonKey(name: 'RemoteAddresses') List<String>? get remoteAddresses {
  final value = _remoteAddresses;
  if (value == null) return null;
  if (_remoteAddresses is EqualUnmodifiableListView) return _remoteAddresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'StartupWizardCompleted') final  bool? startupWizardCompleted;

/// Create a copy of PublicSystemInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicSystemInfoDTOCopyWith<_PublicSystemInfoDTO> get copyWith => __$PublicSystemInfoDTOCopyWithImpl<_PublicSystemInfoDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicSystemInfoDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicSystemInfoDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.version, version) || other.version == version)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.operatingSystem, operatingSystem) || other.operatingSystem == operatingSystem)&&(identical(other.localAddress, localAddress) || other.localAddress == localAddress)&&const DeepCollectionEquality().equals(other._localAddresses, _localAddresses)&&const DeepCollectionEquality().equals(other._remoteAddresses, _remoteAddresses)&&(identical(other.startupWizardCompleted, startupWizardCompleted) || other.startupWizardCompleted == startupWizardCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,serverName,version,productName,operatingSystem,localAddress,const DeepCollectionEquality().hash(_localAddresses),const DeepCollectionEquality().hash(_remoteAddresses),startupWizardCompleted);

@override
String toString() {
  return 'PublicSystemInfoDTO(id: $id, serverName: $serverName, version: $version, productName: $productName, operatingSystem: $operatingSystem, localAddress: $localAddress, localAddresses: $localAddresses, remoteAddresses: $remoteAddresses, startupWizardCompleted: $startupWizardCompleted)';
}


}

/// @nodoc
abstract mixin class _$PublicSystemInfoDTOCopyWith<$Res> implements $PublicSystemInfoDTOCopyWith<$Res> {
  factory _$PublicSystemInfoDTOCopyWith(_PublicSystemInfoDTO value, $Res Function(_PublicSystemInfoDTO) _then) = __$PublicSystemInfoDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String? id,@JsonKey(name: 'ServerName') String? serverName,@JsonKey(name: 'Version') String? version,@JsonKey(name: 'ProductName') String? productName,@JsonKey(name: 'OperatingSystem') String? operatingSystem,@JsonKey(name: 'LocalAddress') String? localAddress,@JsonKey(name: 'LocalAddresses') List<String>? localAddresses,@JsonKey(name: 'RemoteAddresses') List<String>? remoteAddresses,@JsonKey(name: 'StartupWizardCompleted') bool? startupWizardCompleted
});




}
/// @nodoc
class __$PublicSystemInfoDTOCopyWithImpl<$Res>
    implements _$PublicSystemInfoDTOCopyWith<$Res> {
  __$PublicSystemInfoDTOCopyWithImpl(this._self, this._then);

  final _PublicSystemInfoDTO _self;
  final $Res Function(_PublicSystemInfoDTO) _then;

/// Create a copy of PublicSystemInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? serverName = freezed,Object? version = freezed,Object? productName = freezed,Object? operatingSystem = freezed,Object? localAddress = freezed,Object? localAddresses = freezed,Object? remoteAddresses = freezed,Object? startupWizardCompleted = freezed,}) {
  return _then(_PublicSystemInfoDTO(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,productName: freezed == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String?,operatingSystem: freezed == operatingSystem ? _self.operatingSystem : operatingSystem // ignore: cast_nullable_to_non_nullable
as String?,localAddress: freezed == localAddress ? _self.localAddress : localAddress // ignore: cast_nullable_to_non_nullable
as String?,localAddresses: freezed == localAddresses ? _self._localAddresses : localAddresses // ignore: cast_nullable_to_non_nullable
as List<String>?,remoteAddresses: freezed == remoteAddresses ? _self._remoteAddresses : remoteAddresses // ignore: cast_nullable_to_non_nullable
as List<String>?,startupWizardCompleted: freezed == startupWizardCompleted ? _self.startupWizardCompleted : startupWizardCompleted // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
