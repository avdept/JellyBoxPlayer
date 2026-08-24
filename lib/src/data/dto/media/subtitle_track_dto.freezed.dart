// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_track_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleTrackDTO {

@JsonKey(name: 'TrackEvents') List<TrackEventDTO> get trackEvents;
/// Create a copy of SubtitleTrackDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackDTOCopyWith<SubtitleTrackDTO> get copyWith => _$SubtitleTrackDTOCopyWithImpl<SubtitleTrackDTO>(this as SubtitleTrackDTO, _$identity);

  /// Serializes this SubtitleTrackDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrackDTO&&const DeepCollectionEquality().equals(other.trackEvents, trackEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(trackEvents));

@override
String toString() {
  return 'SubtitleTrackDTO(trackEvents: $trackEvents)';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackDTOCopyWith<$Res>  {
  factory $SubtitleTrackDTOCopyWith(SubtitleTrackDTO value, $Res Function(SubtitleTrackDTO) _then) = _$SubtitleTrackDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'TrackEvents') List<TrackEventDTO> trackEvents
});




}
/// @nodoc
class _$SubtitleTrackDTOCopyWithImpl<$Res>
    implements $SubtitleTrackDTOCopyWith<$Res> {
  _$SubtitleTrackDTOCopyWithImpl(this._self, this._then);

  final SubtitleTrackDTO _self;
  final $Res Function(SubtitleTrackDTO) _then;

/// Create a copy of SubtitleTrackDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackEvents = null,}) {
  return _then(_self.copyWith(
trackEvents: null == trackEvents ? _self.trackEvents : trackEvents // ignore: cast_nullable_to_non_nullable
as List<TrackEventDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrackDTO].
extension SubtitleTrackDTOPatterns on SubtitleTrackDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrackDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrackDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrackDTO value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrackDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrackDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrackDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'TrackEvents')  List<TrackEventDTO> trackEvents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrackDTO() when $default != null:
return $default(_that.trackEvents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'TrackEvents')  List<TrackEventDTO> trackEvents)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrackDTO():
return $default(_that.trackEvents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'TrackEvents')  List<TrackEventDTO> trackEvents)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrackDTO() when $default != null:
return $default(_that.trackEvents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleTrackDTO implements SubtitleTrackDTO {
  const _SubtitleTrackDTO({@JsonKey(name: 'TrackEvents') final  List<TrackEventDTO> trackEvents = const []}): _trackEvents = trackEvents;
  factory _SubtitleTrackDTO.fromJson(Map<String, dynamic> json) => _$SubtitleTrackDTOFromJson(json);

 final  List<TrackEventDTO> _trackEvents;
@override@JsonKey(name: 'TrackEvents') List<TrackEventDTO> get trackEvents {
  if (_trackEvents is EqualUnmodifiableListView) return _trackEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trackEvents);
}


/// Create a copy of SubtitleTrackDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackDTOCopyWith<_SubtitleTrackDTO> get copyWith => __$SubtitleTrackDTOCopyWithImpl<_SubtitleTrackDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleTrackDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrackDTO&&const DeepCollectionEquality().equals(other._trackEvents, _trackEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_trackEvents));

@override
String toString() {
  return 'SubtitleTrackDTO(trackEvents: $trackEvents)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackDTOCopyWith<$Res> implements $SubtitleTrackDTOCopyWith<$Res> {
  factory _$SubtitleTrackDTOCopyWith(_SubtitleTrackDTO value, $Res Function(_SubtitleTrackDTO) _then) = __$SubtitleTrackDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'TrackEvents') List<TrackEventDTO> trackEvents
});




}
/// @nodoc
class __$SubtitleTrackDTOCopyWithImpl<$Res>
    implements _$SubtitleTrackDTOCopyWith<$Res> {
  __$SubtitleTrackDTOCopyWithImpl(this._self, this._then);

  final _SubtitleTrackDTO _self;
  final $Res Function(_SubtitleTrackDTO) _then;

/// Create a copy of SubtitleTrackDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackEvents = null,}) {
  return _then(_SubtitleTrackDTO(
trackEvents: null == trackEvents ? _self._trackEvents : trackEvents // ignore: cast_nullable_to_non_nullable
as List<TrackEventDTO>,
  ));
}


}


/// @nodoc
mixin _$TrackEventDTO {

@JsonKey(name: 'Text') String get text;@JsonKey(name: 'StartPositionTicks') int? get startPositionTicks;@JsonKey(name: 'EndPositionTicks') int? get endPositionTicks;
/// Create a copy of TrackEventDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackEventDTOCopyWith<TrackEventDTO> get copyWith => _$TrackEventDTOCopyWithImpl<TrackEventDTO>(this as TrackEventDTO, _$identity);

  /// Serializes this TrackEventDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackEventDTO&&(identical(other.text, text) || other.text == text)&&(identical(other.startPositionTicks, startPositionTicks) || other.startPositionTicks == startPositionTicks)&&(identical(other.endPositionTicks, endPositionTicks) || other.endPositionTicks == endPositionTicks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,startPositionTicks,endPositionTicks);

@override
String toString() {
  return 'TrackEventDTO(text: $text, startPositionTicks: $startPositionTicks, endPositionTicks: $endPositionTicks)';
}


}

/// @nodoc
abstract mixin class $TrackEventDTOCopyWith<$Res>  {
  factory $TrackEventDTOCopyWith(TrackEventDTO value, $Res Function(TrackEventDTO) _then) = _$TrackEventDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Text') String text,@JsonKey(name: 'StartPositionTicks') int? startPositionTicks,@JsonKey(name: 'EndPositionTicks') int? endPositionTicks
});




}
/// @nodoc
class _$TrackEventDTOCopyWithImpl<$Res>
    implements $TrackEventDTOCopyWith<$Res> {
  _$TrackEventDTOCopyWithImpl(this._self, this._then);

  final TrackEventDTO _self;
  final $Res Function(TrackEventDTO) _then;

/// Create a copy of TrackEventDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? startPositionTicks = freezed,Object? endPositionTicks = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startPositionTicks: freezed == startPositionTicks ? _self.startPositionTicks : startPositionTicks // ignore: cast_nullable_to_non_nullable
as int?,endPositionTicks: freezed == endPositionTicks ? _self.endPositionTicks : endPositionTicks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackEventDTO].
extension TrackEventDTOPatterns on TrackEventDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackEventDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackEventDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackEventDTO value)  $default,){
final _that = this;
switch (_that) {
case _TrackEventDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackEventDTO value)?  $default,){
final _that = this;
switch (_that) {
case _TrackEventDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'StartPositionTicks')  int? startPositionTicks, @JsonKey(name: 'EndPositionTicks')  int? endPositionTicks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackEventDTO() when $default != null:
return $default(_that.text,_that.startPositionTicks,_that.endPositionTicks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'StartPositionTicks')  int? startPositionTicks, @JsonKey(name: 'EndPositionTicks')  int? endPositionTicks)  $default,) {final _that = this;
switch (_that) {
case _TrackEventDTO():
return $default(_that.text,_that.startPositionTicks,_that.endPositionTicks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'StartPositionTicks')  int? startPositionTicks, @JsonKey(name: 'EndPositionTicks')  int? endPositionTicks)?  $default,) {final _that = this;
switch (_that) {
case _TrackEventDTO() when $default != null:
return $default(_that.text,_that.startPositionTicks,_that.endPositionTicks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackEventDTO implements TrackEventDTO {
  const _TrackEventDTO({@JsonKey(name: 'Text') this.text = '', @JsonKey(name: 'StartPositionTicks') this.startPositionTicks, @JsonKey(name: 'EndPositionTicks') this.endPositionTicks});
  factory _TrackEventDTO.fromJson(Map<String, dynamic> json) => _$TrackEventDTOFromJson(json);

@override@JsonKey(name: 'Text') final  String text;
@override@JsonKey(name: 'StartPositionTicks') final  int? startPositionTicks;
@override@JsonKey(name: 'EndPositionTicks') final  int? endPositionTicks;

/// Create a copy of TrackEventDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackEventDTOCopyWith<_TrackEventDTO> get copyWith => __$TrackEventDTOCopyWithImpl<_TrackEventDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackEventDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackEventDTO&&(identical(other.text, text) || other.text == text)&&(identical(other.startPositionTicks, startPositionTicks) || other.startPositionTicks == startPositionTicks)&&(identical(other.endPositionTicks, endPositionTicks) || other.endPositionTicks == endPositionTicks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,startPositionTicks,endPositionTicks);

@override
String toString() {
  return 'TrackEventDTO(text: $text, startPositionTicks: $startPositionTicks, endPositionTicks: $endPositionTicks)';
}


}

/// @nodoc
abstract mixin class _$TrackEventDTOCopyWith<$Res> implements $TrackEventDTOCopyWith<$Res> {
  factory _$TrackEventDTOCopyWith(_TrackEventDTO value, $Res Function(_TrackEventDTO) _then) = __$TrackEventDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Text') String text,@JsonKey(name: 'StartPositionTicks') int? startPositionTicks,@JsonKey(name: 'EndPositionTicks') int? endPositionTicks
});




}
/// @nodoc
class __$TrackEventDTOCopyWithImpl<$Res>
    implements _$TrackEventDTOCopyWith<$Res> {
  __$TrackEventDTOCopyWithImpl(this._self, this._then);

  final _TrackEventDTO _self;
  final $Res Function(_TrackEventDTO) _then;

/// Create a copy of TrackEventDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? startPositionTicks = freezed,Object? endPositionTicks = freezed,}) {
  return _then(_TrackEventDTO(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startPositionTicks: freezed == startPositionTicks ? _self.startPositionTicks : startPositionTicks // ignore: cast_nullable_to_non_nullable
as int?,endPositionTicks: freezed == endPositionTicks ? _self.endPositionTicks : endPositionTicks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
