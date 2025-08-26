// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_info_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionInfoDTO {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'PlayState') Map<String, dynamic> get playState;@JsonKey(name: 'NowPlayingItem') Map<String, dynamic>? get nowPlayingItem;
/// Create a copy of SessionInfoDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionInfoDTOCopyWith<SessionInfoDTO> get copyWith => _$SessionInfoDTOCopyWithImpl<SessionInfoDTO>(this as SessionInfoDTO, _$identity);

  /// Serializes this SessionInfoDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionInfoDTO&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.playState, playState)&&const DeepCollectionEquality().equals(other.nowPlayingItem, nowPlayingItem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(playState),const DeepCollectionEquality().hash(nowPlayingItem));

@override
String toString() {
  return 'SessionInfoDTO(id: $id, playState: $playState, nowPlayingItem: $nowPlayingItem)';
}


}

/// @nodoc
abstract mixin class $SessionInfoDTOCopyWith<$Res>  {
  factory $SessionInfoDTOCopyWith(SessionInfoDTO value, $Res Function(SessionInfoDTO) _then) = _$SessionInfoDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'PlayState') Map<String, dynamic> playState,@JsonKey(name: 'NowPlayingItem') Map<String, dynamic>? nowPlayingItem
});




}
/// @nodoc
class _$SessionInfoDTOCopyWithImpl<$Res>
    implements $SessionInfoDTOCopyWith<$Res> {
  _$SessionInfoDTOCopyWithImpl(this._self, this._then);

  final SessionInfoDTO _self;
  final $Res Function(SessionInfoDTO) _then;

/// Create a copy of SessionInfoDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? playState = null,Object? nowPlayingItem = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playState: null == playState ? _self.playState : playState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,nowPlayingItem: freezed == nowPlayingItem ? _self.nowPlayingItem : nowPlayingItem // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionInfoDTO].
extension SessionInfoDTOPatterns on SessionInfoDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionInfoDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionInfoDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionInfoDTO value)  $default,){
final _that = this;
switch (_that) {
case _SessionInfoDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionInfoDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SessionInfoDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlayState')  Map<String, dynamic> playState, @JsonKey(name: 'NowPlayingItem')  Map<String, dynamic>? nowPlayingItem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionInfoDTO() when $default != null:
return $default(_that.id,_that.playState,_that.nowPlayingItem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlayState')  Map<String, dynamic> playState, @JsonKey(name: 'NowPlayingItem')  Map<String, dynamic>? nowPlayingItem)  $default,) {final _that = this;
switch (_that) {
case _SessionInfoDTO():
return $default(_that.id,_that.playState,_that.nowPlayingItem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlayState')  Map<String, dynamic> playState, @JsonKey(name: 'NowPlayingItem')  Map<String, dynamic>? nowPlayingItem)?  $default,) {final _that = this;
switch (_that) {
case _SessionInfoDTO() when $default != null:
return $default(_that.id,_that.playState,_that.nowPlayingItem);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionInfoDTO implements SessionInfoDTO {
  const _SessionInfoDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'PlayState') required final  Map<String, dynamic> playState, @JsonKey(name: 'NowPlayingItem') final  Map<String, dynamic>? nowPlayingItem}): _playState = playState,_nowPlayingItem = nowPlayingItem;
  factory _SessionInfoDTO.fromJson(Map<String, dynamic> json) => _$SessionInfoDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
 final  Map<String, dynamic> _playState;
@override@JsonKey(name: 'PlayState') Map<String, dynamic> get playState {
  if (_playState is EqualUnmodifiableMapView) return _playState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playState);
}

 final  Map<String, dynamic>? _nowPlayingItem;
@override@JsonKey(name: 'NowPlayingItem') Map<String, dynamic>? get nowPlayingItem {
  final value = _nowPlayingItem;
  if (value == null) return null;
  if (_nowPlayingItem is EqualUnmodifiableMapView) return _nowPlayingItem;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SessionInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionInfoDTOCopyWith<_SessionInfoDTO> get copyWith => __$SessionInfoDTOCopyWithImpl<_SessionInfoDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionInfoDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionInfoDTO&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._playState, _playState)&&const DeepCollectionEquality().equals(other._nowPlayingItem, _nowPlayingItem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_playState),const DeepCollectionEquality().hash(_nowPlayingItem));

@override
String toString() {
  return 'SessionInfoDTO(id: $id, playState: $playState, nowPlayingItem: $nowPlayingItem)';
}


}

/// @nodoc
abstract mixin class _$SessionInfoDTOCopyWith<$Res> implements $SessionInfoDTOCopyWith<$Res> {
  factory _$SessionInfoDTOCopyWith(_SessionInfoDTO value, $Res Function(_SessionInfoDTO) _then) = __$SessionInfoDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'PlayState') Map<String, dynamic> playState,@JsonKey(name: 'NowPlayingItem') Map<String, dynamic>? nowPlayingItem
});




}
/// @nodoc
class __$SessionInfoDTOCopyWithImpl<$Res>
    implements _$SessionInfoDTOCopyWith<$Res> {
  __$SessionInfoDTOCopyWithImpl(this._self, this._then);

  final _SessionInfoDTO _self;
  final $Res Function(_SessionInfoDTO) _then;

/// Create a copy of SessionInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? playState = null,Object? nowPlayingItem = freezed,}) {
  return _then(_SessionInfoDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playState: null == playState ? _self._playState : playState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,nowPlayingItem: freezed == nowPlayingItem ? _self._nowPlayingItem : nowPlayingItem // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
