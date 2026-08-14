// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_user_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaybackUserData {

@DurationMillisConverter() Duration get position; int get playCount; bool get isFavorite; bool get played;
/// Create a copy of PlaybackUserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackUserDataCopyWith<PlaybackUserData> get copyWith => _$PlaybackUserDataCopyWithImpl<PlaybackUserData>(this as PlaybackUserData, _$identity);

  /// Serializes this PlaybackUserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackUserData&&(identical(other.position, position) || other.position == position)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,playCount,isFavorite,played);

@override
String toString() {
  return 'PlaybackUserData(position: $position, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class $PlaybackUserDataCopyWith<$Res>  {
  factory $PlaybackUserDataCopyWith(PlaybackUserData value, $Res Function(PlaybackUserData) _then) = _$PlaybackUserDataCopyWithImpl;
@useResult
$Res call({
@DurationMillisConverter() Duration position, int playCount, bool isFavorite, bool played
});




}
/// @nodoc
class _$PlaybackUserDataCopyWithImpl<$Res>
    implements $PlaybackUserDataCopyWith<$Res> {
  _$PlaybackUserDataCopyWithImpl(this._self, this._then);

  final PlaybackUserData _self;
  final $Res Function(PlaybackUserData) _then;

/// Create a copy of PlaybackUserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackUserData].
extension PlaybackUserDataPatterns on PlaybackUserData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackUserData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackUserData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackUserData value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackUserData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackUserData value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackUserData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DurationMillisConverter()  Duration position,  int playCount,  bool isFavorite,  bool played)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackUserData() when $default != null:
return $default(_that.position,_that.playCount,_that.isFavorite,_that.played);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DurationMillisConverter()  Duration position,  int playCount,  bool isFavorite,  bool played)  $default,) {final _that = this;
switch (_that) {
case _PlaybackUserData():
return $default(_that.position,_that.playCount,_that.isFavorite,_that.played);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DurationMillisConverter()  Duration position,  int playCount,  bool isFavorite,  bool played)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackUserData() when $default != null:
return $default(_that.position,_that.playCount,_that.isFavorite,_that.played);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaybackUserData implements PlaybackUserData {
  const _PlaybackUserData({@DurationMillisConverter() this.position = Duration.zero, this.playCount = 0, this.isFavorite = false, this.played = false});
  factory _PlaybackUserData.fromJson(Map<String, dynamic> json) => _$PlaybackUserDataFromJson(json);

@override@JsonKey()@DurationMillisConverter() final  Duration position;
@override@JsonKey() final  int playCount;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool played;

/// Create a copy of PlaybackUserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackUserDataCopyWith<_PlaybackUserData> get copyWith => __$PlaybackUserDataCopyWithImpl<_PlaybackUserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaybackUserDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackUserData&&(identical(other.position, position) || other.position == position)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.played, played) || other.played == played));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,playCount,isFavorite,played);

@override
String toString() {
  return 'PlaybackUserData(position: $position, playCount: $playCount, isFavorite: $isFavorite, played: $played)';
}


}

/// @nodoc
abstract mixin class _$PlaybackUserDataCopyWith<$Res> implements $PlaybackUserDataCopyWith<$Res> {
  factory _$PlaybackUserDataCopyWith(_PlaybackUserData value, $Res Function(_PlaybackUserData) _then) = __$PlaybackUserDataCopyWithImpl;
@override @useResult
$Res call({
@DurationMillisConverter() Duration position, int playCount, bool isFavorite, bool played
});




}
/// @nodoc
class __$PlaybackUserDataCopyWithImpl<$Res>
    implements _$PlaybackUserDataCopyWith<$Res> {
  __$PlaybackUserDataCopyWithImpl(this._self, this._then);

  final _PlaybackUserData _self;
  final $Res Function(_PlaybackUserData) _then;

/// Create a copy of PlaybackUserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? playCount = null,Object? isFavorite = null,Object? played = null,}) {
  return _then(_PlaybackUserData(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
