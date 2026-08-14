// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_source_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AudioSourceInfo {

 String? get container; String? get codec; int? get bitRate; int? get sampleRate; int? get bitDepth; int? get channels; String? get channelLayout;
/// Create a copy of AudioSourceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioSourceInfoCopyWith<AudioSourceInfo> get copyWith => _$AudioSourceInfoCopyWithImpl<AudioSourceInfo>(this as AudioSourceInfo, _$identity);

  /// Serializes this AudioSourceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioSourceInfo&&(identical(other.container, container) || other.container == container)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.channelLayout, channelLayout) || other.channelLayout == channelLayout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,container,codec,bitRate,sampleRate,bitDepth,channels,channelLayout);

@override
String toString() {
  return 'AudioSourceInfo(container: $container, codec: $codec, bitRate: $bitRate, sampleRate: $sampleRate, bitDepth: $bitDepth, channels: $channels, channelLayout: $channelLayout)';
}


}

/// @nodoc
abstract mixin class $AudioSourceInfoCopyWith<$Res>  {
  factory $AudioSourceInfoCopyWith(AudioSourceInfo value, $Res Function(AudioSourceInfo) _then) = _$AudioSourceInfoCopyWithImpl;
@useResult
$Res call({
 String? container, String? codec, int? bitRate, int? sampleRate, int? bitDepth, int? channels, String? channelLayout
});




}
/// @nodoc
class _$AudioSourceInfoCopyWithImpl<$Res>
    implements $AudioSourceInfoCopyWith<$Res> {
  _$AudioSourceInfoCopyWithImpl(this._self, this._then);

  final AudioSourceInfo _self;
  final $Res Function(AudioSourceInfo) _then;

/// Create a copy of AudioSourceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? container = freezed,Object? codec = freezed,Object? bitRate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? channels = freezed,Object? channelLayout = freezed,}) {
  return _then(_self.copyWith(
container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as int?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,channelLayout: freezed == channelLayout ? _self.channelLayout : channelLayout // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioSourceInfo].
extension AudioSourceInfoPatterns on AudioSourceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioSourceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioSourceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioSourceInfo value)  $default,){
final _that = this;
switch (_that) {
case _AudioSourceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioSourceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AudioSourceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? container,  String? codec,  int? bitRate,  int? sampleRate,  int? bitDepth,  int? channels,  String? channelLayout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioSourceInfo() when $default != null:
return $default(_that.container,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? container,  String? codec,  int? bitRate,  int? sampleRate,  int? bitDepth,  int? channels,  String? channelLayout)  $default,) {final _that = this;
switch (_that) {
case _AudioSourceInfo():
return $default(_that.container,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? container,  String? codec,  int? bitRate,  int? sampleRate,  int? bitDepth,  int? channels,  String? channelLayout)?  $default,) {final _that = this;
switch (_that) {
case _AudioSourceInfo() when $default != null:
return $default(_that.container,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioSourceInfo implements AudioSourceInfo {
  const _AudioSourceInfo({this.container, this.codec, this.bitRate, this.sampleRate, this.bitDepth, this.channels, this.channelLayout});
  factory _AudioSourceInfo.fromJson(Map<String, dynamic> json) => _$AudioSourceInfoFromJson(json);

@override final  String? container;
@override final  String? codec;
@override final  int? bitRate;
@override final  int? sampleRate;
@override final  int? bitDepth;
@override final  int? channels;
@override final  String? channelLayout;

/// Create a copy of AudioSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioSourceInfoCopyWith<_AudioSourceInfo> get copyWith => __$AudioSourceInfoCopyWithImpl<_AudioSourceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioSourceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioSourceInfo&&(identical(other.container, container) || other.container == container)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.channelLayout, channelLayout) || other.channelLayout == channelLayout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,container,codec,bitRate,sampleRate,bitDepth,channels,channelLayout);

@override
String toString() {
  return 'AudioSourceInfo(container: $container, codec: $codec, bitRate: $bitRate, sampleRate: $sampleRate, bitDepth: $bitDepth, channels: $channels, channelLayout: $channelLayout)';
}


}

/// @nodoc
abstract mixin class _$AudioSourceInfoCopyWith<$Res> implements $AudioSourceInfoCopyWith<$Res> {
  factory _$AudioSourceInfoCopyWith(_AudioSourceInfo value, $Res Function(_AudioSourceInfo) _then) = __$AudioSourceInfoCopyWithImpl;
@override @useResult
$Res call({
 String? container, String? codec, int? bitRate, int? sampleRate, int? bitDepth, int? channels, String? channelLayout
});




}
/// @nodoc
class __$AudioSourceInfoCopyWithImpl<$Res>
    implements _$AudioSourceInfoCopyWith<$Res> {
  __$AudioSourceInfoCopyWithImpl(this._self, this._then);

  final _AudioSourceInfo _self;
  final $Res Function(_AudioSourceInfo) _then;

/// Create a copy of AudioSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? container = freezed,Object? codec = freezed,Object? bitRate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? channels = freezed,Object? channelLayout = freezed,}) {
  return _then(_AudioSourceInfo(
container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,bitRate: freezed == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as int?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,channelLayout: freezed == channelLayout ? _self.channelLayout : channelLayout // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
