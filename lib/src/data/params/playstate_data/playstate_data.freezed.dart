// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playstate_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaystateData {

@JsonKey(name: 'PlaySessionId') String get playSessionId;@JsonKey(name: 'ItemId') String get itemId;@JsonKey(name: 'SessionId', includeIfNull: false) String? get sessionId;@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? get mediaSourceId;@JsonKey(name: 'PositionTicks', includeIfNull: false) int? get positionTicks;@JsonKey(name: 'IsPaused', includeIfNull: false) bool? get isPaused;@JsonKey(name: 'CanSeek', includeIfNull: false) bool? get canSeek;@JsonKey(name: 'NowPlayingQueue', includeIfNull: false) List<QueueItemData>? get nowPlayingQueue;
/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaystateDataCopyWith<PlaystateData> get copyWith => _$PlaystateDataCopyWithImpl<PlaystateData>(this as PlaystateData, _$identity);

  /// Serializes this PlaystateData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaystateData&&(identical(other.playSessionId, playSessionId) || other.playSessionId == playSessionId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaSourceId, mediaSourceId) || other.mediaSourceId == mediaSourceId)&&(identical(other.positionTicks, positionTicks) || other.positionTicks == positionTicks)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.canSeek, canSeek) || other.canSeek == canSeek)&&const DeepCollectionEquality().equals(other.nowPlayingQueue, nowPlayingQueue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playSessionId,itemId,sessionId,mediaSourceId,positionTicks,isPaused,canSeek,const DeepCollectionEquality().hash(nowPlayingQueue));

@override
String toString() {
  return 'PlaystateData(playSessionId: $playSessionId, itemId: $itemId, sessionId: $sessionId, mediaSourceId: $mediaSourceId, positionTicks: $positionTicks, isPaused: $isPaused, canSeek: $canSeek, nowPlayingQueue: $nowPlayingQueue)';
}


}

/// @nodoc
abstract mixin class $PlaystateDataCopyWith<$Res>  {
  factory $PlaystateDataCopyWith(PlaystateData value, $Res Function(PlaystateData) _then) = _$PlaystateDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'PlaySessionId') String playSessionId,@JsonKey(name: 'ItemId') String itemId,@JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,@JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks,@JsonKey(name: 'IsPaused', includeIfNull: false) bool? isPaused,@JsonKey(name: 'CanSeek', includeIfNull: false) bool? canSeek,@JsonKey(name: 'NowPlayingQueue', includeIfNull: false) List<QueueItemData>? nowPlayingQueue
});




}
/// @nodoc
class _$PlaystateDataCopyWithImpl<$Res>
    implements $PlaystateDataCopyWith<$Res> {
  _$PlaystateDataCopyWithImpl(this._self, this._then);

  final PlaystateData _self;
  final $Res Function(PlaystateData) _then;

/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playSessionId = null,Object? itemId = null,Object? sessionId = freezed,Object? mediaSourceId = freezed,Object? positionTicks = freezed,Object? isPaused = freezed,Object? canSeek = freezed,Object? nowPlayingQueue = freezed,}) {
  return _then(_self.copyWith(
playSessionId: null == playSessionId ? _self.playSessionId : playSessionId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaSourceId: freezed == mediaSourceId ? _self.mediaSourceId : mediaSourceId // ignore: cast_nullable_to_non_nullable
as String?,positionTicks: freezed == positionTicks ? _self.positionTicks : positionTicks // ignore: cast_nullable_to_non_nullable
as int?,isPaused: freezed == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool?,canSeek: freezed == canSeek ? _self.canSeek : canSeek // ignore: cast_nullable_to_non_nullable
as bool?,nowPlayingQueue: freezed == nowPlayingQueue ? _self.nowPlayingQueue : nowPlayingQueue // ignore: cast_nullable_to_non_nullable
as List<QueueItemData>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaystateData].
extension PlaystateDataPatterns on PlaystateData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaystateData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaystateData value)  $default,){
final _that = this;
switch (_that) {
case _PlaystateData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaystateData value)?  $default,){
final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks, @JsonKey(name: 'IsPaused', includeIfNull: false)  bool? isPaused, @JsonKey(name: 'CanSeek', includeIfNull: false)  bool? canSeek, @JsonKey(name: 'NowPlayingQueue', includeIfNull: false)  List<QueueItemData>? nowPlayingQueue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
return $default(_that.playSessionId,_that.itemId,_that.sessionId,_that.mediaSourceId,_that.positionTicks,_that.isPaused,_that.canSeek,_that.nowPlayingQueue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks, @JsonKey(name: 'IsPaused', includeIfNull: false)  bool? isPaused, @JsonKey(name: 'CanSeek', includeIfNull: false)  bool? canSeek, @JsonKey(name: 'NowPlayingQueue', includeIfNull: false)  List<QueueItemData>? nowPlayingQueue)  $default,) {final _that = this;
switch (_that) {
case _PlaystateData():
return $default(_that.playSessionId,_that.itemId,_that.sessionId,_that.mediaSourceId,_that.positionTicks,_that.isPaused,_that.canSeek,_that.nowPlayingQueue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks, @JsonKey(name: 'IsPaused', includeIfNull: false)  bool? isPaused, @JsonKey(name: 'CanSeek', includeIfNull: false)  bool? canSeek, @JsonKey(name: 'NowPlayingQueue', includeIfNull: false)  List<QueueItemData>? nowPlayingQueue)?  $default,) {final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
return $default(_that.playSessionId,_that.itemId,_that.sessionId,_that.mediaSourceId,_that.positionTicks,_that.isPaused,_that.canSeek,_that.nowPlayingQueue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _PlaystateData implements PlaystateData {
  const _PlaystateData({@JsonKey(name: 'PlaySessionId') required this.playSessionId, @JsonKey(name: 'ItemId') required this.itemId, @JsonKey(name: 'SessionId', includeIfNull: false) this.sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false) this.mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false) this.positionTicks, @JsonKey(name: 'IsPaused', includeIfNull: false) this.isPaused, @JsonKey(name: 'CanSeek', includeIfNull: false) this.canSeek, @JsonKey(name: 'NowPlayingQueue', includeIfNull: false) final  List<QueueItemData>? nowPlayingQueue}): _nowPlayingQueue = nowPlayingQueue;
  

@override@JsonKey(name: 'PlaySessionId') final  String playSessionId;
@override@JsonKey(name: 'ItemId') final  String itemId;
@override@JsonKey(name: 'SessionId', includeIfNull: false) final  String? sessionId;
@override@JsonKey(name: 'MediaSourceId', includeIfNull: false) final  String? mediaSourceId;
@override@JsonKey(name: 'PositionTicks', includeIfNull: false) final  int? positionTicks;
@override@JsonKey(name: 'IsPaused', includeIfNull: false) final  bool? isPaused;
@override@JsonKey(name: 'CanSeek', includeIfNull: false) final  bool? canSeek;
 final  List<QueueItemData>? _nowPlayingQueue;
@override@JsonKey(name: 'NowPlayingQueue', includeIfNull: false) List<QueueItemData>? get nowPlayingQueue {
  final value = _nowPlayingQueue;
  if (value == null) return null;
  if (_nowPlayingQueue is EqualUnmodifiableListView) return _nowPlayingQueue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaystateDataCopyWith<_PlaystateData> get copyWith => __$PlaystateDataCopyWithImpl<_PlaystateData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaystateDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaystateData&&(identical(other.playSessionId, playSessionId) || other.playSessionId == playSessionId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaSourceId, mediaSourceId) || other.mediaSourceId == mediaSourceId)&&(identical(other.positionTicks, positionTicks) || other.positionTicks == positionTicks)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.canSeek, canSeek) || other.canSeek == canSeek)&&const DeepCollectionEquality().equals(other._nowPlayingQueue, _nowPlayingQueue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playSessionId,itemId,sessionId,mediaSourceId,positionTicks,isPaused,canSeek,const DeepCollectionEquality().hash(_nowPlayingQueue));

@override
String toString() {
  return 'PlaystateData(playSessionId: $playSessionId, itemId: $itemId, sessionId: $sessionId, mediaSourceId: $mediaSourceId, positionTicks: $positionTicks, isPaused: $isPaused, canSeek: $canSeek, nowPlayingQueue: $nowPlayingQueue)';
}


}

/// @nodoc
abstract mixin class _$PlaystateDataCopyWith<$Res> implements $PlaystateDataCopyWith<$Res> {
  factory _$PlaystateDataCopyWith(_PlaystateData value, $Res Function(_PlaystateData) _then) = __$PlaystateDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'PlaySessionId') String playSessionId,@JsonKey(name: 'ItemId') String itemId,@JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,@JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks,@JsonKey(name: 'IsPaused', includeIfNull: false) bool? isPaused,@JsonKey(name: 'CanSeek', includeIfNull: false) bool? canSeek,@JsonKey(name: 'NowPlayingQueue', includeIfNull: false) List<QueueItemData>? nowPlayingQueue
});




}
/// @nodoc
class __$PlaystateDataCopyWithImpl<$Res>
    implements _$PlaystateDataCopyWith<$Res> {
  __$PlaystateDataCopyWithImpl(this._self, this._then);

  final _PlaystateData _self;
  final $Res Function(_PlaystateData) _then;

/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playSessionId = null,Object? itemId = null,Object? sessionId = freezed,Object? mediaSourceId = freezed,Object? positionTicks = freezed,Object? isPaused = freezed,Object? canSeek = freezed,Object? nowPlayingQueue = freezed,}) {
  return _then(_PlaystateData(
playSessionId: null == playSessionId ? _self.playSessionId : playSessionId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaSourceId: freezed == mediaSourceId ? _self.mediaSourceId : mediaSourceId // ignore: cast_nullable_to_non_nullable
as String?,positionTicks: freezed == positionTicks ? _self.positionTicks : positionTicks // ignore: cast_nullable_to_non_nullable
as int?,isPaused: freezed == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool?,canSeek: freezed == canSeek ? _self.canSeek : canSeek // ignore: cast_nullable_to_non_nullable
as bool?,nowPlayingQueue: freezed == nowPlayingQueue ? _self._nowPlayingQueue : nowPlayingQueue // ignore: cast_nullable_to_non_nullable
as List<QueueItemData>?,
  ));
}


}

/// @nodoc
mixin _$QueueItemData {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'PlaylistItemId', includeIfNull: false) String? get playlistItemId;
/// Create a copy of QueueItemData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueItemDataCopyWith<QueueItemData> get copyWith => _$QueueItemDataCopyWithImpl<QueueItemData>(this as QueueItemData, _$identity);

  /// Serializes this QueueItemData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueItemData&&(identical(other.id, id) || other.id == id)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,playlistItemId);

@override
String toString() {
  return 'QueueItemData(id: $id, playlistItemId: $playlistItemId)';
}


}

/// @nodoc
abstract mixin class $QueueItemDataCopyWith<$Res>  {
  factory $QueueItemDataCopyWith(QueueItemData value, $Res Function(QueueItemData) _then) = _$QueueItemDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'PlaylistItemId', includeIfNull: false) String? playlistItemId
});




}
/// @nodoc
class _$QueueItemDataCopyWithImpl<$Res>
    implements $QueueItemDataCopyWith<$Res> {
  _$QueueItemDataCopyWithImpl(this._self, this._then);

  final QueueItemData _self;
  final $Res Function(QueueItemData) _then;

/// Create a copy of QueueItemData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? playlistItemId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueItemData].
extension QueueItemDataPatterns on QueueItemData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueItemData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueItemData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueItemData value)  $default,){
final _that = this;
switch (_that) {
case _QueueItemData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueItemData value)?  $default,){
final _that = this;
switch (_that) {
case _QueueItemData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlaylistItemId', includeIfNull: false)  String? playlistItemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueItemData() when $default != null:
return $default(_that.id,_that.playlistItemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlaylistItemId', includeIfNull: false)  String? playlistItemId)  $default,) {final _that = this;
switch (_that) {
case _QueueItemData():
return $default(_that.id,_that.playlistItemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'PlaylistItemId', includeIfNull: false)  String? playlistItemId)?  $default,) {final _that = this;
switch (_that) {
case _QueueItemData() when $default != null:
return $default(_that.id,_that.playlistItemId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _QueueItemData implements QueueItemData {
  const _QueueItemData({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'PlaylistItemId', includeIfNull: false) this.playlistItemId});
  

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'PlaylistItemId', includeIfNull: false) final  String? playlistItemId;

/// Create a copy of QueueItemData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueItemDataCopyWith<_QueueItemData> get copyWith => __$QueueItemDataCopyWithImpl<_QueueItemData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueItemDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueItemData&&(identical(other.id, id) || other.id == id)&&(identical(other.playlistItemId, playlistItemId) || other.playlistItemId == playlistItemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,playlistItemId);

@override
String toString() {
  return 'QueueItemData(id: $id, playlistItemId: $playlistItemId)';
}


}

/// @nodoc
abstract mixin class _$QueueItemDataCopyWith<$Res> implements $QueueItemDataCopyWith<$Res> {
  factory _$QueueItemDataCopyWith(_QueueItemData value, $Res Function(_QueueItemData) _then) = __$QueueItemDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'PlaylistItemId', includeIfNull: false) String? playlistItemId
});




}
/// @nodoc
class __$QueueItemDataCopyWithImpl<$Res>
    implements _$QueueItemDataCopyWith<$Res> {
  __$QueueItemDataCopyWithImpl(this._self, this._then);

  final _QueueItemData _self;
  final $Res Function(_QueueItemData) _then;

/// Create a copy of QueueItemData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? playlistItemId = freezed,}) {
  return _then(_QueueItemData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
