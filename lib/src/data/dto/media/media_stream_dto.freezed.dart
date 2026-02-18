// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_stream_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaStreamDTO {

@JsonKey(name: 'Type') String? get type;@JsonKey(name: 'Codec') String? get codec;@JsonKey(name: 'BitRate') int? get bitRate;@JsonKey(name: 'SampleRate') int? get sampleRate;@JsonKey(name: 'BitDepth') int? get bitDepth;@JsonKey(name: 'Channels') int? get channels;@JsonKey(name: 'ChannelLayout') String? get channelLayout;
/// Create a copy of MediaStreamDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaStreamDTOCopyWith<MediaStreamDTO> get copyWith => _$MediaStreamDTOCopyWithImpl<MediaStreamDTO>(this as MediaStreamDTO, _$identity);

  /// Serializes this MediaStreamDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaStreamDTO&&(identical(other.type, type) || other.type == type)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.channelLayout, channelLayout) || other.channelLayout == channelLayout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,codec,bitRate,sampleRate,bitDepth,channels,channelLayout);

@override
String toString() {
  return 'MediaStreamDTO(type: $type, codec: $codec, bitRate: $bitRate, sampleRate: $sampleRate, bitDepth: $bitDepth, channels: $channels, channelLayout: $channelLayout)';
}


}

/// @nodoc
abstract mixin class $MediaStreamDTOCopyWith<$Res>  {
  factory $MediaStreamDTOCopyWith(MediaStreamDTO value, $Res Function(MediaStreamDTO) _then) = _$MediaStreamDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Type') String? type,@JsonKey(name: 'Codec') String? codec,@JsonKey(name: 'BitRate') int? bitRate,@JsonKey(name: 'SampleRate') int? sampleRate,@JsonKey(name: 'BitDepth') int? bitDepth,@JsonKey(name: 'Channels') int? channels,@JsonKey(name: 'ChannelLayout') String? channelLayout
});




}
/// @nodoc
class _$MediaStreamDTOCopyWithImpl<$Res>
    implements $MediaStreamDTOCopyWith<$Res> {
  _$MediaStreamDTOCopyWithImpl(this._self, this._then);

  final MediaStreamDTO _self;
  final $Res Function(MediaStreamDTO) _then;

/// Create a copy of MediaStreamDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = freezed,Object? codec = freezed,Object? bitRate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? channels = freezed,Object? channelLayout = freezed,}) {
  return _then(_self.copyWith(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [MediaStreamDTO].
extension MediaStreamDTOPatterns on MediaStreamDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaStreamDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaStreamDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaStreamDTO value)  $default,){
final _that = this;
switch (_that) {
case _MediaStreamDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaStreamDTO value)?  $default,){
final _that = this;
switch (_that) {
case _MediaStreamDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Type')  String? type, @JsonKey(name: 'Codec')  String? codec, @JsonKey(name: 'BitRate')  int? bitRate, @JsonKey(name: 'SampleRate')  int? sampleRate, @JsonKey(name: 'BitDepth')  int? bitDepth, @JsonKey(name: 'Channels')  int? channels, @JsonKey(name: 'ChannelLayout')  String? channelLayout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaStreamDTO() when $default != null:
return $default(_that.type,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Type')  String? type, @JsonKey(name: 'Codec')  String? codec, @JsonKey(name: 'BitRate')  int? bitRate, @JsonKey(name: 'SampleRate')  int? sampleRate, @JsonKey(name: 'BitDepth')  int? bitDepth, @JsonKey(name: 'Channels')  int? channels, @JsonKey(name: 'ChannelLayout')  String? channelLayout)  $default,) {final _that = this;
switch (_that) {
case _MediaStreamDTO():
return $default(_that.type,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Type')  String? type, @JsonKey(name: 'Codec')  String? codec, @JsonKey(name: 'BitRate')  int? bitRate, @JsonKey(name: 'SampleRate')  int? sampleRate, @JsonKey(name: 'BitDepth')  int? bitDepth, @JsonKey(name: 'Channels')  int? channels, @JsonKey(name: 'ChannelLayout')  String? channelLayout)?  $default,) {final _that = this;
switch (_that) {
case _MediaStreamDTO() when $default != null:
return $default(_that.type,_that.codec,_that.bitRate,_that.sampleRate,_that.bitDepth,_that.channels,_that.channelLayout);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaStreamDTO implements MediaStreamDTO {
  const _MediaStreamDTO({@JsonKey(name: 'Type') this.type, @JsonKey(name: 'Codec') this.codec, @JsonKey(name: 'BitRate') this.bitRate, @JsonKey(name: 'SampleRate') this.sampleRate, @JsonKey(name: 'BitDepth') this.bitDepth, @JsonKey(name: 'Channels') this.channels, @JsonKey(name: 'ChannelLayout') this.channelLayout});
  factory _MediaStreamDTO.fromJson(Map<String, dynamic> json) => _$MediaStreamDTOFromJson(json);

@override@JsonKey(name: 'Type') final  String? type;
@override@JsonKey(name: 'Codec') final  String? codec;
@override@JsonKey(name: 'BitRate') final  int? bitRate;
@override@JsonKey(name: 'SampleRate') final  int? sampleRate;
@override@JsonKey(name: 'BitDepth') final  int? bitDepth;
@override@JsonKey(name: 'Channels') final  int? channels;
@override@JsonKey(name: 'ChannelLayout') final  String? channelLayout;

/// Create a copy of MediaStreamDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaStreamDTOCopyWith<_MediaStreamDTO> get copyWith => __$MediaStreamDTOCopyWithImpl<_MediaStreamDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaStreamDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaStreamDTO&&(identical(other.type, type) || other.type == type)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.channelLayout, channelLayout) || other.channelLayout == channelLayout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,codec,bitRate,sampleRate,bitDepth,channels,channelLayout);

@override
String toString() {
  return 'MediaStreamDTO(type: $type, codec: $codec, bitRate: $bitRate, sampleRate: $sampleRate, bitDepth: $bitDepth, channels: $channels, channelLayout: $channelLayout)';
}


}

/// @nodoc
abstract mixin class _$MediaStreamDTOCopyWith<$Res> implements $MediaStreamDTOCopyWith<$Res> {
  factory _$MediaStreamDTOCopyWith(_MediaStreamDTO value, $Res Function(_MediaStreamDTO) _then) = __$MediaStreamDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Type') String? type,@JsonKey(name: 'Codec') String? codec,@JsonKey(name: 'BitRate') int? bitRate,@JsonKey(name: 'SampleRate') int? sampleRate,@JsonKey(name: 'BitDepth') int? bitDepth,@JsonKey(name: 'Channels') int? channels,@JsonKey(name: 'ChannelLayout') String? channelLayout
});




}
/// @nodoc
class __$MediaStreamDTOCopyWithImpl<$Res>
    implements _$MediaStreamDTOCopyWith<$Res> {
  __$MediaStreamDTOCopyWithImpl(this._self, this._then);

  final _MediaStreamDTO _self;
  final $Res Function(_MediaStreamDTO) _then;

/// Create a copy of MediaStreamDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = freezed,Object? codec = freezed,Object? bitRate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? channels = freezed,Object? channelLayout = freezed,}) {
  return _then(_MediaStreamDTO(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
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
