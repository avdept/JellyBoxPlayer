// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_data_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserData {

@JsonKey(name: 'PlaybackPositionTicks') int get playbackPositionTicks;@JsonKey(name: 'PlayCount') int get playCount;@JsonKey(name: 'IsFavorite') bool get isFavorite;@JsonKey(name: 'Played') bool get played;
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataCopyWith<UserData> get copyWith => _$UserDataCopyWithImpl<UserData>(this as UserData, _$identity);

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserData&&(identical(other.playbackPositionTicks, playbackPositionTicks) || other.playbackPositionTicks == playbackPositionTicks)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playbackPositionTicks,playCount,isFavorite,played);

@override
String toString() {
  return 'UserData(playbackPositionTicks: $playbackPositionTicks, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class $UserDataCopyWith<$Res>  {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) _then) = _$UserDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,@JsonKey(name: 'PlayCount') int playCount,@JsonKey(name: 'IsFavorite') bool isFavorite,@JsonKey(name: 'Played') bool played
});




}
/// @nodoc
class _$UserDataCopyWithImpl<$Res>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._self, this._then);

  final UserData _self;
  final $Res Function(UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackPositionTicks = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_self.copyWith(
playbackPositionTicks: null == playbackPositionTicks ? _self.playbackPositionTicks : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserData].
extension UserDataPatterns on UserData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserData value)  $default,){
final _that = this;
switch (_that) {
case _UserData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserData value)?  $default,){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)  $default,) {final _that = this;
switch (_that) {
case _UserData():
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'PlaybackPositionTicks')  int playbackPositionTicks, @JsonKey(name: 'PlayCount')  int playCount, @JsonKey(name: 'IsFavorite')  bool isFavorite, @JsonKey(name: 'Played')  bool played)?  $default,) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.playbackPositionTicks,_that.playCount,_that.isFavorite,_that.played);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserData implements UserData {
  const _UserData({@JsonKey(name: 'PlaybackPositionTicks') this.playbackPositionTicks = 0, @JsonKey(name: 'PlayCount') this.playCount = 0, @JsonKey(name: 'IsFavorite') this.isFavorite = false, @JsonKey(name: 'Played') this.played = false});
  factory _UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

@override@JsonKey(name: 'PlaybackPositionTicks') final  int playbackPositionTicks;
@override@JsonKey(name: 'PlayCount') final  int playCount;
@override@JsonKey(name: 'IsFavorite') final  bool isFavorite;
@override@JsonKey(name: 'Played') final  bool played;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataCopyWith<_UserData> get copyWith => __$UserDataCopyWithImpl<_UserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserData&&(identical(other.playbackPositionTicks, playbackPositionTicks) || other.playbackPositionTicks == playbackPositionTicks)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playbackPositionTicks,playCount,isFavorite,played);

@override
String toString() {
  return 'UserData(playbackPositionTicks: $playbackPositionTicks, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class _$UserDataCopyWith<$Res> implements $UserDataCopyWith<$Res> {
  factory _$UserDataCopyWith(_UserData value, $Res Function(_UserData) _then) = __$UserDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'PlaybackPositionTicks') int playbackPositionTicks,@JsonKey(name: 'PlayCount') int playCount,@JsonKey(name: 'IsFavorite') bool isFavorite,@JsonKey(name: 'Played') bool played
});




}
/// @nodoc
class __$UserDataCopyWithImpl<$Res>
    implements _$UserDataCopyWith<$Res> {
  __$UserDataCopyWithImpl(this._self, this._then);

  final _UserData _self;
  final $Res Function(_UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackPositionTicks = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_UserData(
playbackPositionTicks: null == playbackPositionTicks ? _self.playbackPositionTicks : playbackPositionTicks // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
