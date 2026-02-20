// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackState {

 ItemDTO? get album; List<ItemDTO> get songs; PlaybackStatus get status; Duration get position; Duration get cacheProgress; Duration? get totalDuration; int? get currentMediaIndex;
/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackStateCopyWith<PlaybackState> get copyWith => _$PlaybackStateCopyWithImpl<PlaybackState>(this as PlaybackState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackState&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other.songs, songs)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.cacheProgress, cacheProgress) || other.cacheProgress == cacheProgress)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.currentMediaIndex, currentMediaIndex) || other.currentMediaIndex == currentMediaIndex));
}


@override
int get hashCode => Object.hash(runtimeType,album,const DeepCollectionEquality().hash(songs),status,position,cacheProgress,totalDuration,currentMediaIndex);

@override
String toString() {
  return 'PlaybackState(album: $album, songs: $songs, status: $status, position: $position, cacheProgress: $cacheProgress, totalDuration: $totalDuration, currentMediaIndex: $currentMediaIndex)';
}


}

/// @nodoc
abstract mixin class $PlaybackStateCopyWith<$Res>  {
  factory $PlaybackStateCopyWith(PlaybackState value, $Res Function(PlaybackState) _then) = _$PlaybackStateCopyWithImpl;
@useResult
$Res call({
 ItemDTO? album, List<ItemDTO> songs, PlaybackStatus status, Duration position, Duration cacheProgress, Duration? totalDuration, int? currentMediaIndex
});


$ItemDTOCopyWith<$Res>? get album;

}
/// @nodoc
class _$PlaybackStateCopyWithImpl<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  _$PlaybackStateCopyWithImpl(this._self, this._then);

  final PlaybackState _self;
  final $Res Function(PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = freezed,Object? songs = null,Object? status = null,Object? position = null,Object? cacheProgress = null,Object? totalDuration = freezed,Object? currentMediaIndex = freezed,}) {
  return _then(_self.copyWith(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as ItemDTO?,songs: null == songs ? _self.songs : songs // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaybackStatus,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,cacheProgress: null == cacheProgress ? _self.cacheProgress : cacheProgress // ignore: cast_nullable_to_non_nullable
as Duration,totalDuration: freezed == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration?,currentMediaIndex: freezed == currentMediaIndex ? _self.currentMediaIndex : currentMediaIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $ItemDTOCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaybackState].
extension PlaybackStatePatterns on PlaybackState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackState value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackState value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ItemDTO? album,  List<ItemDTO> songs,  PlaybackStatus status,  Duration position,  Duration cacheProgress,  Duration? totalDuration,  int? currentMediaIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
return $default(_that.album,_that.songs,_that.status,_that.position,_that.cacheProgress,_that.totalDuration,_that.currentMediaIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ItemDTO? album,  List<ItemDTO> songs,  PlaybackStatus status,  Duration position,  Duration cacheProgress,  Duration? totalDuration,  int? currentMediaIndex)  $default,) {final _that = this;
switch (_that) {
case _PlaybackState():
return $default(_that.album,_that.songs,_that.status,_that.position,_that.cacheProgress,_that.totalDuration,_that.currentMediaIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ItemDTO? album,  List<ItemDTO> songs,  PlaybackStatus status,  Duration position,  Duration cacheProgress,  Duration? totalDuration,  int? currentMediaIndex)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackState() when $default != null:
return $default(_that.album,_that.songs,_that.status,_that.position,_that.cacheProgress,_that.totalDuration,_that.currentMediaIndex);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackState implements PlaybackState {
  const _PlaybackState({required this.album, required final  List<ItemDTO> songs, required this.status, required this.position, required this.cacheProgress, this.totalDuration, this.currentMediaIndex}): _songs = songs;
  

@override final  ItemDTO? album;
 final  List<ItemDTO> _songs;
@override List<ItemDTO> get songs {
  if (_songs is EqualUnmodifiableListView) return _songs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_songs);
}

@override final  PlaybackStatus status;
@override final  Duration position;
@override final  Duration cacheProgress;
@override final  Duration? totalDuration;
@override final  int? currentMediaIndex;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackStateCopyWith<_PlaybackState> get copyWith => __$PlaybackStateCopyWithImpl<_PlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackState&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other._songs, _songs)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.cacheProgress, cacheProgress) || other.cacheProgress == cacheProgress)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.currentMediaIndex, currentMediaIndex) || other.currentMediaIndex == currentMediaIndex));
}


@override
int get hashCode => Object.hash(runtimeType,album,const DeepCollectionEquality().hash(_songs),status,position,cacheProgress,totalDuration,currentMediaIndex);

@override
String toString() {
  return 'PlaybackState(album: $album, songs: $songs, status: $status, position: $position, cacheProgress: $cacheProgress, totalDuration: $totalDuration, currentMediaIndex: $currentMediaIndex)';
}


}

/// @nodoc
abstract mixin class _$PlaybackStateCopyWith<$Res> implements $PlaybackStateCopyWith<$Res> {
  factory _$PlaybackStateCopyWith(_PlaybackState value, $Res Function(_PlaybackState) _then) = __$PlaybackStateCopyWithImpl;
@override @useResult
$Res call({
 ItemDTO? album, List<ItemDTO> songs, PlaybackStatus status, Duration position, Duration cacheProgress, Duration? totalDuration, int? currentMediaIndex
});


@override $ItemDTOCopyWith<$Res>? get album;

}
/// @nodoc
class __$PlaybackStateCopyWithImpl<$Res>
    implements _$PlaybackStateCopyWith<$Res> {
  __$PlaybackStateCopyWithImpl(this._self, this._then);

  final _PlaybackState _self;
  final $Res Function(_PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? album = freezed,Object? songs = null,Object? status = null,Object? position = null,Object? cacheProgress = null,Object? totalDuration = freezed,Object? currentMediaIndex = freezed,}) {
  return _then(_PlaybackState(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as ItemDTO?,songs: null == songs ? _self._songs : songs // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlaybackStatus,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,cacheProgress: null == cacheProgress ? _self.cacheProgress : cacheProgress // ignore: cast_nullable_to_non_nullable
as Duration,totalDuration: freezed == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration?,currentMediaIndex: freezed == currentMediaIndex ? _self.currentMediaIndex : currentMediaIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $ItemDTOCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}

// dart format on
