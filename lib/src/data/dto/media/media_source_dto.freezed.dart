// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_source_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaSourceDTO {

@JsonKey(name: 'Container') String? get container;@JsonKey(name: 'MediaStreams') List<MediaStreamDTO> get mediaStreams;
/// Create a copy of MediaSourceDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaSourceDTOCopyWith<MediaSourceDTO> get copyWith => _$MediaSourceDTOCopyWithImpl<MediaSourceDTO>(this as MediaSourceDTO, _$identity);

  /// Serializes this MediaSourceDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaSourceDTO&&(identical(other.container, container) || other.container == container)&&const DeepCollectionEquality().equals(other.mediaStreams, mediaStreams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,container,const DeepCollectionEquality().hash(mediaStreams));

@override
String toString() {
  return 'MediaSourceDTO(container: $container, mediaStreams: $mediaStreams)';
}


}

/// @nodoc
abstract mixin class $MediaSourceDTOCopyWith<$Res>  {
  factory $MediaSourceDTOCopyWith(MediaSourceDTO value, $Res Function(MediaSourceDTO) _then) = _$MediaSourceDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Container') String? container,@JsonKey(name: 'MediaStreams') List<MediaStreamDTO> mediaStreams
});




}
/// @nodoc
class _$MediaSourceDTOCopyWithImpl<$Res>
    implements $MediaSourceDTOCopyWith<$Res> {
  _$MediaSourceDTOCopyWithImpl(this._self, this._then);

  final MediaSourceDTO _self;
  final $Res Function(MediaSourceDTO) _then;

/// Create a copy of MediaSourceDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? container = freezed,Object? mediaStreams = null,}) {
  return _then(_self.copyWith(
container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,mediaStreams: null == mediaStreams ? _self.mediaStreams : mediaStreams // ignore: cast_nullable_to_non_nullable
as List<MediaStreamDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaSourceDTO].
extension MediaSourceDTOPatterns on MediaSourceDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaSourceDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaSourceDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaSourceDTO value)  $default,){
final _that = this;
switch (_that) {
case _MediaSourceDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaSourceDTO value)?  $default,){
final _that = this;
switch (_that) {
case _MediaSourceDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Container')  String? container, @JsonKey(name: 'MediaStreams')  List<MediaStreamDTO> mediaStreams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaSourceDTO() when $default != null:
return $default(_that.container,_that.mediaStreams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Container')  String? container, @JsonKey(name: 'MediaStreams')  List<MediaStreamDTO> mediaStreams)  $default,) {final _that = this;
switch (_that) {
case _MediaSourceDTO():
return $default(_that.container,_that.mediaStreams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Container')  String? container, @JsonKey(name: 'MediaStreams')  List<MediaStreamDTO> mediaStreams)?  $default,) {final _that = this;
switch (_that) {
case _MediaSourceDTO() when $default != null:
return $default(_that.container,_that.mediaStreams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaSourceDTO implements MediaSourceDTO {
  const _MediaSourceDTO({@JsonKey(name: 'Container') this.container, @JsonKey(name: 'MediaStreams') final  List<MediaStreamDTO> mediaStreams = const []}): _mediaStreams = mediaStreams;
  factory _MediaSourceDTO.fromJson(Map<String, dynamic> json) => _$MediaSourceDTOFromJson(json);

@override@JsonKey(name: 'Container') final  String? container;
 final  List<MediaStreamDTO> _mediaStreams;
@override@JsonKey(name: 'MediaStreams') List<MediaStreamDTO> get mediaStreams {
  if (_mediaStreams is EqualUnmodifiableListView) return _mediaStreams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaStreams);
}


/// Create a copy of MediaSourceDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaSourceDTOCopyWith<_MediaSourceDTO> get copyWith => __$MediaSourceDTOCopyWithImpl<_MediaSourceDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaSourceDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaSourceDTO&&(identical(other.container, container) || other.container == container)&&const DeepCollectionEquality().equals(other._mediaStreams, _mediaStreams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,container,const DeepCollectionEquality().hash(_mediaStreams));

@override
String toString() {
  return 'MediaSourceDTO(container: $container, mediaStreams: $mediaStreams)';
}


}

/// @nodoc
abstract mixin class _$MediaSourceDTOCopyWith<$Res> implements $MediaSourceDTOCopyWith<$Res> {
  factory _$MediaSourceDTOCopyWith(_MediaSourceDTO value, $Res Function(_MediaSourceDTO) _then) = __$MediaSourceDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Container') String? container,@JsonKey(name: 'MediaStreams') List<MediaStreamDTO> mediaStreams
});




}
/// @nodoc
class __$MediaSourceDTOCopyWithImpl<$Res>
    implements _$MediaSourceDTOCopyWith<$Res> {
  __$MediaSourceDTOCopyWithImpl(this._self, this._then);

  final _MediaSourceDTO _self;
  final $Res Function(_MediaSourceDTO) _then;

/// Create a copy of MediaSourceDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? container = freezed,Object? mediaStreams = null,}) {
  return _then(_MediaSourceDTO(
container: freezed == container ? _self.container : container // ignore: cast_nullable_to_non_nullable
as String?,mediaStreams: null == mediaStreams ? _self._mediaStreams : mediaStreams // ignore: cast_nullable_to_non_nullable
as List<MediaStreamDTO>,
  ));
}


}

// dart format on
