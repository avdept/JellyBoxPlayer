// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LyricsDTO {

@JsonKey(name: 'Metadata') LyricMetadataDTO get metadata;@JsonKey(name: 'Lyrics') List<LyricLineDTO> get lyrics;
/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsDTOCopyWith<LyricsDTO> get copyWith => _$LyricsDTOCopyWithImpl<LyricsDTO>(this as LyricsDTO, _$identity);

  /// Serializes this LyricsDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricsDTO&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.lyrics, lyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(lyrics));

@override
String toString() {
  return 'LyricsDTO(metadata: $metadata, lyrics: $lyrics)';
}


}

/// @nodoc
abstract mixin class $LyricsDTOCopyWith<$Res>  {
  factory $LyricsDTOCopyWith(LyricsDTO value, $Res Function(LyricsDTO) _then) = _$LyricsDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Metadata') LyricMetadataDTO metadata,@JsonKey(name: 'Lyrics') List<LyricLineDTO> lyrics
});


$LyricMetadataDTOCopyWith<$Res> get metadata;

}
/// @nodoc
class _$LyricsDTOCopyWithImpl<$Res>
    implements $LyricsDTOCopyWith<$Res> {
  _$LyricsDTOCopyWithImpl(this._self, this._then);

  final LyricsDTO _self;
  final $Res Function(LyricsDTO) _then;

/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = null,Object? lyrics = null,}) {
  return _then(_self.copyWith(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as LyricMetadataDTO,lyrics: null == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as List<LyricLineDTO>,
  ));
}
/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LyricMetadataDTOCopyWith<$Res> get metadata {
  
  return $LyricMetadataDTOCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [LyricsDTO].
extension LyricsDTOPatterns on LyricsDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricsDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricsDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricsDTO value)  $default,){
final _that = this;
switch (_that) {
case _LyricsDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricsDTO value)?  $default,){
final _that = this;
switch (_that) {
case _LyricsDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Metadata')  LyricMetadataDTO metadata, @JsonKey(name: 'Lyrics')  List<LyricLineDTO> lyrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricsDTO() when $default != null:
return $default(_that.metadata,_that.lyrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Metadata')  LyricMetadataDTO metadata, @JsonKey(name: 'Lyrics')  List<LyricLineDTO> lyrics)  $default,) {final _that = this;
switch (_that) {
case _LyricsDTO():
return $default(_that.metadata,_that.lyrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Metadata')  LyricMetadataDTO metadata, @JsonKey(name: 'Lyrics')  List<LyricLineDTO> lyrics)?  $default,) {final _that = this;
switch (_that) {
case _LyricsDTO() when $default != null:
return $default(_that.metadata,_that.lyrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricsDTO extends LyricsDTO {
  const _LyricsDTO({@JsonKey(name: 'Metadata') this.metadata = const LyricMetadataDTO(), @JsonKey(name: 'Lyrics') final  List<LyricLineDTO> lyrics = const []}): _lyrics = lyrics,super._();
  factory _LyricsDTO.fromJson(Map<String, dynamic> json) => _$LyricsDTOFromJson(json);

@override@JsonKey(name: 'Metadata') final  LyricMetadataDTO metadata;
 final  List<LyricLineDTO> _lyrics;
@override@JsonKey(name: 'Lyrics') List<LyricLineDTO> get lyrics {
  if (_lyrics is EqualUnmodifiableListView) return _lyrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lyrics);
}


/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricsDTOCopyWith<_LyricsDTO> get copyWith => __$LyricsDTOCopyWithImpl<_LyricsDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricsDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricsDTO&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._lyrics, _lyrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(_lyrics));

@override
String toString() {
  return 'LyricsDTO(metadata: $metadata, lyrics: $lyrics)';
}


}

/// @nodoc
abstract mixin class _$LyricsDTOCopyWith<$Res> implements $LyricsDTOCopyWith<$Res> {
  factory _$LyricsDTOCopyWith(_LyricsDTO value, $Res Function(_LyricsDTO) _then) = __$LyricsDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Metadata') LyricMetadataDTO metadata,@JsonKey(name: 'Lyrics') List<LyricLineDTO> lyrics
});


@override $LyricMetadataDTOCopyWith<$Res> get metadata;

}
/// @nodoc
class __$LyricsDTOCopyWithImpl<$Res>
    implements _$LyricsDTOCopyWith<$Res> {
  __$LyricsDTOCopyWithImpl(this._self, this._then);

  final _LyricsDTO _self;
  final $Res Function(_LyricsDTO) _then;

/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = null,Object? lyrics = null,}) {
  return _then(_LyricsDTO(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as LyricMetadataDTO,lyrics: null == lyrics ? _self._lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as List<LyricLineDTO>,
  ));
}

/// Create a copy of LyricsDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LyricMetadataDTOCopyWith<$Res> get metadata {
  
  return $LyricMetadataDTOCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$LyricLineDTO {

@JsonKey(name: 'Text') String get text;@JsonKey(name: 'Start') int? get start;@JsonKey(name: 'Cues') List<LyricLineCueDTO>? get cues;
/// Create a copy of LyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricLineDTOCopyWith<LyricLineDTO> get copyWith => _$LyricLineDTOCopyWithImpl<LyricLineDTO>(this as LyricLineDTO, _$identity);

  /// Serializes this LyricLineDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricLineDTO&&(identical(other.text, text) || other.text == text)&&(identical(other.start, start) || other.start == start)&&const DeepCollectionEquality().equals(other.cues, cues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,start,const DeepCollectionEquality().hash(cues));

@override
String toString() {
  return 'LyricLineDTO(text: $text, start: $start, cues: $cues)';
}


}

/// @nodoc
abstract mixin class $LyricLineDTOCopyWith<$Res>  {
  factory $LyricLineDTOCopyWith(LyricLineDTO value, $Res Function(LyricLineDTO) _then) = _$LyricLineDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Text') String text,@JsonKey(name: 'Start') int? start,@JsonKey(name: 'Cues') List<LyricLineCueDTO>? cues
});




}
/// @nodoc
class _$LyricLineDTOCopyWithImpl<$Res>
    implements $LyricLineDTOCopyWith<$Res> {
  _$LyricLineDTOCopyWithImpl(this._self, this._then);

  final LyricLineDTO _self;
  final $Res Function(LyricLineDTO) _then;

/// Create a copy of LyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? start = freezed,Object? cues = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,cues: freezed == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as List<LyricLineCueDTO>?,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricLineDTO].
extension LyricLineDTOPatterns on LyricLineDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricLineDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricLineDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricLineDTO value)  $default,){
final _that = this;
switch (_that) {
case _LyricLineDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricLineDTO value)?  $default,){
final _that = this;
switch (_that) {
case _LyricLineDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'Start')  int? start, @JsonKey(name: 'Cues')  List<LyricLineCueDTO>? cues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricLineDTO() when $default != null:
return $default(_that.text,_that.start,_that.cues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'Start')  int? start, @JsonKey(name: 'Cues')  List<LyricLineCueDTO>? cues)  $default,) {final _that = this;
switch (_that) {
case _LyricLineDTO():
return $default(_that.text,_that.start,_that.cues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Text')  String text, @JsonKey(name: 'Start')  int? start, @JsonKey(name: 'Cues')  List<LyricLineCueDTO>? cues)?  $default,) {final _that = this;
switch (_that) {
case _LyricLineDTO() when $default != null:
return $default(_that.text,_that.start,_that.cues);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricLineDTO extends LyricLineDTO {
  const _LyricLineDTO({@JsonKey(name: 'Text') this.text = '', @JsonKey(name: 'Start') this.start, @JsonKey(name: 'Cues') final  List<LyricLineCueDTO>? cues}): _cues = cues,super._();
  factory _LyricLineDTO.fromJson(Map<String, dynamic> json) => _$LyricLineDTOFromJson(json);

@override@JsonKey(name: 'Text') final  String text;
@override@JsonKey(name: 'Start') final  int? start;
 final  List<LyricLineCueDTO>? _cues;
@override@JsonKey(name: 'Cues') List<LyricLineCueDTO>? get cues {
  final value = _cues;
  if (value == null) return null;
  if (_cues is EqualUnmodifiableListView) return _cues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of LyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricLineDTOCopyWith<_LyricLineDTO> get copyWith => __$LyricLineDTOCopyWithImpl<_LyricLineDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricLineDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricLineDTO&&(identical(other.text, text) || other.text == text)&&(identical(other.start, start) || other.start == start)&&const DeepCollectionEquality().equals(other._cues, _cues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,start,const DeepCollectionEquality().hash(_cues));

@override
String toString() {
  return 'LyricLineDTO(text: $text, start: $start, cues: $cues)';
}


}

/// @nodoc
abstract mixin class _$LyricLineDTOCopyWith<$Res> implements $LyricLineDTOCopyWith<$Res> {
  factory _$LyricLineDTOCopyWith(_LyricLineDTO value, $Res Function(_LyricLineDTO) _then) = __$LyricLineDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Text') String text,@JsonKey(name: 'Start') int? start,@JsonKey(name: 'Cues') List<LyricLineCueDTO>? cues
});




}
/// @nodoc
class __$LyricLineDTOCopyWithImpl<$Res>
    implements _$LyricLineDTOCopyWith<$Res> {
  __$LyricLineDTOCopyWithImpl(this._self, this._then);

  final _LyricLineDTO _self;
  final $Res Function(_LyricLineDTO) _then;

/// Create a copy of LyricLineDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? start = freezed,Object? cues = freezed,}) {
  return _then(_LyricLineDTO(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,cues: freezed == cues ? _self._cues : cues // ignore: cast_nullable_to_non_nullable
as List<LyricLineCueDTO>?,
  ));
}


}


/// @nodoc
mixin _$LyricLineCueDTO {

@JsonKey(name: 'Position') int get position;@JsonKey(name: 'EndPosition') int get endPosition;@JsonKey(name: 'Start') int get start;@JsonKey(name: 'End') int? get end;
/// Create a copy of LyricLineCueDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricLineCueDTOCopyWith<LyricLineCueDTO> get copyWith => _$LyricLineCueDTOCopyWithImpl<LyricLineCueDTO>(this as LyricLineCueDTO, _$identity);

  /// Serializes this LyricLineCueDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricLineCueDTO&&(identical(other.position, position) || other.position == position)&&(identical(other.endPosition, endPosition) || other.endPosition == endPosition)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,endPosition,start,end);

@override
String toString() {
  return 'LyricLineCueDTO(position: $position, endPosition: $endPosition, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $LyricLineCueDTOCopyWith<$Res>  {
  factory $LyricLineCueDTOCopyWith(LyricLineCueDTO value, $Res Function(LyricLineCueDTO) _then) = _$LyricLineCueDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Position') int position,@JsonKey(name: 'EndPosition') int endPosition,@JsonKey(name: 'Start') int start,@JsonKey(name: 'End') int? end
});




}
/// @nodoc
class _$LyricLineCueDTOCopyWithImpl<$Res>
    implements $LyricLineCueDTOCopyWith<$Res> {
  _$LyricLineCueDTOCopyWithImpl(this._self, this._then);

  final LyricLineCueDTO _self;
  final $Res Function(LyricLineCueDTO) _then;

/// Create a copy of LyricLineCueDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? endPosition = null,Object? start = null,Object? end = freezed,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,endPosition: null == endPosition ? _self.endPosition : endPosition // ignore: cast_nullable_to_non_nullable
as int,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricLineCueDTO].
extension LyricLineCueDTOPatterns on LyricLineCueDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricLineCueDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricLineCueDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricLineCueDTO value)  $default,){
final _that = this;
switch (_that) {
case _LyricLineCueDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricLineCueDTO value)?  $default,){
final _that = this;
switch (_that) {
case _LyricLineCueDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Position')  int position, @JsonKey(name: 'EndPosition')  int endPosition, @JsonKey(name: 'Start')  int start, @JsonKey(name: 'End')  int? end)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricLineCueDTO() when $default != null:
return $default(_that.position,_that.endPosition,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Position')  int position, @JsonKey(name: 'EndPosition')  int endPosition, @JsonKey(name: 'Start')  int start, @JsonKey(name: 'End')  int? end)  $default,) {final _that = this;
switch (_that) {
case _LyricLineCueDTO():
return $default(_that.position,_that.endPosition,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Position')  int position, @JsonKey(name: 'EndPosition')  int endPosition, @JsonKey(name: 'Start')  int start, @JsonKey(name: 'End')  int? end)?  $default,) {final _that = this;
switch (_that) {
case _LyricLineCueDTO() when $default != null:
return $default(_that.position,_that.endPosition,_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricLineCueDTO extends LyricLineCueDTO {
  const _LyricLineCueDTO({@JsonKey(name: 'Position') this.position = 0, @JsonKey(name: 'EndPosition') this.endPosition = 0, @JsonKey(name: 'Start') this.start = 0, @JsonKey(name: 'End') this.end}): super._();
  factory _LyricLineCueDTO.fromJson(Map<String, dynamic> json) => _$LyricLineCueDTOFromJson(json);

@override@JsonKey(name: 'Position') final  int position;
@override@JsonKey(name: 'EndPosition') final  int endPosition;
@override@JsonKey(name: 'Start') final  int start;
@override@JsonKey(name: 'End') final  int? end;

/// Create a copy of LyricLineCueDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricLineCueDTOCopyWith<_LyricLineCueDTO> get copyWith => __$LyricLineCueDTOCopyWithImpl<_LyricLineCueDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricLineCueDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricLineCueDTO&&(identical(other.position, position) || other.position == position)&&(identical(other.endPosition, endPosition) || other.endPosition == endPosition)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,endPosition,start,end);

@override
String toString() {
  return 'LyricLineCueDTO(position: $position, endPosition: $endPosition, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class _$LyricLineCueDTOCopyWith<$Res> implements $LyricLineCueDTOCopyWith<$Res> {
  factory _$LyricLineCueDTOCopyWith(_LyricLineCueDTO value, $Res Function(_LyricLineCueDTO) _then) = __$LyricLineCueDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Position') int position,@JsonKey(name: 'EndPosition') int endPosition,@JsonKey(name: 'Start') int start,@JsonKey(name: 'End') int? end
});




}
/// @nodoc
class __$LyricLineCueDTOCopyWithImpl<$Res>
    implements _$LyricLineCueDTOCopyWith<$Res> {
  __$LyricLineCueDTOCopyWithImpl(this._self, this._then);

  final _LyricLineCueDTO _self;
  final $Res Function(_LyricLineCueDTO) _then;

/// Create a copy of LyricLineCueDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? endPosition = null,Object? start = null,Object? end = freezed,}) {
  return _then(_LyricLineCueDTO(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,endPosition: null == endPosition ? _self.endPosition : endPosition // ignore: cast_nullable_to_non_nullable
as int,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$LyricMetadataDTO {

@JsonKey(name: 'Artist') String? get artist;@JsonKey(name: 'Album') String? get album;@JsonKey(name: 'Title') String? get title;@JsonKey(name: 'Author') String? get author;@JsonKey(name: 'Length') int? get length;@JsonKey(name: 'By') String? get by;@JsonKey(name: 'Offset') int? get offset;@JsonKey(name: 'Creator') String? get creator;@JsonKey(name: 'Version') String? get version;@JsonKey(name: 'IsSynced') bool? get isSynced;
/// Create a copy of LyricMetadataDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricMetadataDTOCopyWith<LyricMetadataDTO> get copyWith => _$LyricMetadataDTOCopyWithImpl<LyricMetadataDTO>(this as LyricMetadataDTO, _$identity);

  /// Serializes this LyricMetadataDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricMetadataDTO&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.length, length) || other.length == length)&&(identical(other.by, by) || other.by == by)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.version, version) || other.version == version)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artist,album,title,author,length,by,offset,creator,version,isSynced);

@override
String toString() {
  return 'LyricMetadataDTO(artist: $artist, album: $album, title: $title, author: $author, length: $length, by: $by, offset: $offset, creator: $creator, version: $version, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $LyricMetadataDTOCopyWith<$Res>  {
  factory $LyricMetadataDTOCopyWith(LyricMetadataDTO value, $Res Function(LyricMetadataDTO) _then) = _$LyricMetadataDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Artist') String? artist,@JsonKey(name: 'Album') String? album,@JsonKey(name: 'Title') String? title,@JsonKey(name: 'Author') String? author,@JsonKey(name: 'Length') int? length,@JsonKey(name: 'By') String? by,@JsonKey(name: 'Offset') int? offset,@JsonKey(name: 'Creator') String? creator,@JsonKey(name: 'Version') String? version,@JsonKey(name: 'IsSynced') bool? isSynced
});




}
/// @nodoc
class _$LyricMetadataDTOCopyWithImpl<$Res>
    implements $LyricMetadataDTOCopyWith<$Res> {
  _$LyricMetadataDTOCopyWithImpl(this._self, this._then);

  final LyricMetadataDTO _self;
  final $Res Function(LyricMetadataDTO) _then;

/// Create a copy of LyricMetadataDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = freezed,Object? album = freezed,Object? title = freezed,Object? author = freezed,Object? length = freezed,Object? by = freezed,Object? offset = freezed,Object? creator = freezed,Object? version = freezed,Object? isSynced = freezed,}) {
  return _then(_self.copyWith(
artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int?,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String?,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,isSynced: freezed == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricMetadataDTO].
extension LyricMetadataDTOPatterns on LyricMetadataDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricMetadataDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricMetadataDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricMetadataDTO value)  $default,){
final _that = this;
switch (_that) {
case _LyricMetadataDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricMetadataDTO value)?  $default,){
final _that = this;
switch (_that) {
case _LyricMetadataDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Artist')  String? artist, @JsonKey(name: 'Album')  String? album, @JsonKey(name: 'Title')  String? title, @JsonKey(name: 'Author')  String? author, @JsonKey(name: 'Length')  int? length, @JsonKey(name: 'By')  String? by, @JsonKey(name: 'Offset')  int? offset, @JsonKey(name: 'Creator')  String? creator, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'IsSynced')  bool? isSynced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricMetadataDTO() when $default != null:
return $default(_that.artist,_that.album,_that.title,_that.author,_that.length,_that.by,_that.offset,_that.creator,_that.version,_that.isSynced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Artist')  String? artist, @JsonKey(name: 'Album')  String? album, @JsonKey(name: 'Title')  String? title, @JsonKey(name: 'Author')  String? author, @JsonKey(name: 'Length')  int? length, @JsonKey(name: 'By')  String? by, @JsonKey(name: 'Offset')  int? offset, @JsonKey(name: 'Creator')  String? creator, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'IsSynced')  bool? isSynced)  $default,) {final _that = this;
switch (_that) {
case _LyricMetadataDTO():
return $default(_that.artist,_that.album,_that.title,_that.author,_that.length,_that.by,_that.offset,_that.creator,_that.version,_that.isSynced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Artist')  String? artist, @JsonKey(name: 'Album')  String? album, @JsonKey(name: 'Title')  String? title, @JsonKey(name: 'Author')  String? author, @JsonKey(name: 'Length')  int? length, @JsonKey(name: 'By')  String? by, @JsonKey(name: 'Offset')  int? offset, @JsonKey(name: 'Creator')  String? creator, @JsonKey(name: 'Version')  String? version, @JsonKey(name: 'IsSynced')  bool? isSynced)?  $default,) {final _that = this;
switch (_that) {
case _LyricMetadataDTO() when $default != null:
return $default(_that.artist,_that.album,_that.title,_that.author,_that.length,_that.by,_that.offset,_that.creator,_that.version,_that.isSynced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricMetadataDTO extends LyricMetadataDTO {
  const _LyricMetadataDTO({@JsonKey(name: 'Artist') this.artist, @JsonKey(name: 'Album') this.album, @JsonKey(name: 'Title') this.title, @JsonKey(name: 'Author') this.author, @JsonKey(name: 'Length') this.length, @JsonKey(name: 'By') this.by, @JsonKey(name: 'Offset') this.offset, @JsonKey(name: 'Creator') this.creator, @JsonKey(name: 'Version') this.version, @JsonKey(name: 'IsSynced') this.isSynced}): super._();
  factory _LyricMetadataDTO.fromJson(Map<String, dynamic> json) => _$LyricMetadataDTOFromJson(json);

@override@JsonKey(name: 'Artist') final  String? artist;
@override@JsonKey(name: 'Album') final  String? album;
@override@JsonKey(name: 'Title') final  String? title;
@override@JsonKey(name: 'Author') final  String? author;
@override@JsonKey(name: 'Length') final  int? length;
@override@JsonKey(name: 'By') final  String? by;
@override@JsonKey(name: 'Offset') final  int? offset;
@override@JsonKey(name: 'Creator') final  String? creator;
@override@JsonKey(name: 'Version') final  String? version;
@override@JsonKey(name: 'IsSynced') final  bool? isSynced;

/// Create a copy of LyricMetadataDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricMetadataDTOCopyWith<_LyricMetadataDTO> get copyWith => __$LyricMetadataDTOCopyWithImpl<_LyricMetadataDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricMetadataDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricMetadataDTO&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.length, length) || other.length == length)&&(identical(other.by, by) || other.by == by)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.version, version) || other.version == version)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,artist,album,title,author,length,by,offset,creator,version,isSynced);

@override
String toString() {
  return 'LyricMetadataDTO(artist: $artist, album: $album, title: $title, author: $author, length: $length, by: $by, offset: $offset, creator: $creator, version: $version, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$LyricMetadataDTOCopyWith<$Res> implements $LyricMetadataDTOCopyWith<$Res> {
  factory _$LyricMetadataDTOCopyWith(_LyricMetadataDTO value, $Res Function(_LyricMetadataDTO) _then) = __$LyricMetadataDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Artist') String? artist,@JsonKey(name: 'Album') String? album,@JsonKey(name: 'Title') String? title,@JsonKey(name: 'Author') String? author,@JsonKey(name: 'Length') int? length,@JsonKey(name: 'By') String? by,@JsonKey(name: 'Offset') int? offset,@JsonKey(name: 'Creator') String? creator,@JsonKey(name: 'Version') String? version,@JsonKey(name: 'IsSynced') bool? isSynced
});




}
/// @nodoc
class __$LyricMetadataDTOCopyWithImpl<$Res>
    implements _$LyricMetadataDTOCopyWith<$Res> {
  __$LyricMetadataDTOCopyWithImpl(this._self, this._then);

  final _LyricMetadataDTO _self;
  final $Res Function(_LyricMetadataDTO) _then;

/// Create a copy of LyricMetadataDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artist = freezed,Object? album = freezed,Object? title = freezed,Object? author = freezed,Object? length = freezed,Object? by = freezed,Object? offset = freezed,Object? creator = freezed,Object? version = freezed,Object? isSynced = freezed,}) {
  return _then(_LyricMetadataDTO(
artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int?,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String?,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,isSynced: freezed == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
