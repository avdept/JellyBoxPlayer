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

@JsonKey(name: 'PlaySessionId') String get playSessionId;@JsonKey(name: 'ItemId') String get itemId;@JsonKey(name: 'Item', includeIfNull: false) ItemDTO? get item;@JsonKey(name: 'SessionId', includeIfNull: false) String? get sessionId;@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? get mediaSourceId;@JsonKey(name: 'PositionTicks', includeIfNull: false) int? get positionTicks;
/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaystateDataCopyWith<PlaystateData> get copyWith => _$PlaystateDataCopyWithImpl<PlaystateData>(this as PlaystateData, _$identity);

  /// Serializes this PlaystateData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaystateData&&(identical(other.playSessionId, playSessionId) || other.playSessionId == playSessionId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.item, item) || other.item == item)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaSourceId, mediaSourceId) || other.mediaSourceId == mediaSourceId)&&(identical(other.positionTicks, positionTicks) || other.positionTicks == positionTicks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playSessionId,itemId,item,sessionId,mediaSourceId,positionTicks);

@override
String toString() {
  return 'PlaystateData(playSessionId: $playSessionId, itemId: $itemId, item: $item, sessionId: $sessionId, mediaSourceId: $mediaSourceId, positionTicks: $positionTicks)';
}


}

/// @nodoc
abstract mixin class $PlaystateDataCopyWith<$Res>  {
  factory $PlaystateDataCopyWith(PlaystateData value, $Res Function(PlaystateData) _then) = _$PlaystateDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'PlaySessionId') String playSessionId,@JsonKey(name: 'ItemId') String itemId,@JsonKey(name: 'Item', includeIfNull: false) ItemDTO? item,@JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,@JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks
});


$ItemDTOCopyWith<$Res>? get item;

}
/// @nodoc
class _$PlaystateDataCopyWithImpl<$Res>
    implements $PlaystateDataCopyWith<$Res> {
  _$PlaystateDataCopyWithImpl(this._self, this._then);

  final PlaystateData _self;
  final $Res Function(PlaystateData) _then;

/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playSessionId = null,Object? itemId = null,Object? item = freezed,Object? sessionId = freezed,Object? mediaSourceId = freezed,Object? positionTicks = freezed,}) {
  return _then(_self.copyWith(
playSessionId: null == playSessionId ? _self.playSessionId : playSessionId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ItemDTO?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaSourceId: freezed == mediaSourceId ? _self.mediaSourceId : mediaSourceId // ignore: cast_nullable_to_non_nullable
as String?,positionTicks: freezed == positionTicks ? _self.positionTicks : positionTicks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $ItemDTOCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'Item', includeIfNull: false)  ItemDTO? item, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
return $default(_that.playSessionId,_that.itemId,_that.item,_that.sessionId,_that.mediaSourceId,_that.positionTicks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'Item', includeIfNull: false)  ItemDTO? item, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks)  $default,) {final _that = this;
switch (_that) {
case _PlaystateData():
return $default(_that.playSessionId,_that.itemId,_that.item,_that.sessionId,_that.mediaSourceId,_that.positionTicks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'PlaySessionId')  String playSessionId, @JsonKey(name: 'ItemId')  String itemId, @JsonKey(name: 'Item', includeIfNull: false)  ItemDTO? item, @JsonKey(name: 'SessionId', includeIfNull: false)  String? sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false)  String? mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false)  int? positionTicks)?  $default,) {final _that = this;
switch (_that) {
case _PlaystateData() when $default != null:
return $default(_that.playSessionId,_that.itemId,_that.item,_that.sessionId,_that.mediaSourceId,_that.positionTicks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _PlaystateData implements PlaystateData {
  const _PlaystateData({@JsonKey(name: 'PlaySessionId') required this.playSessionId, @JsonKey(name: 'ItemId') required this.itemId, @JsonKey(name: 'Item', includeIfNull: false) this.item, @JsonKey(name: 'SessionId', includeIfNull: false) this.sessionId, @JsonKey(name: 'MediaSourceId', includeIfNull: false) this.mediaSourceId, @JsonKey(name: 'PositionTicks', includeIfNull: false) this.positionTicks});
  

@override@JsonKey(name: 'PlaySessionId') final  String playSessionId;
@override@JsonKey(name: 'ItemId') final  String itemId;
@override@JsonKey(name: 'Item', includeIfNull: false) final  ItemDTO? item;
@override@JsonKey(name: 'SessionId', includeIfNull: false) final  String? sessionId;
@override@JsonKey(name: 'MediaSourceId', includeIfNull: false) final  String? mediaSourceId;
@override@JsonKey(name: 'PositionTicks', includeIfNull: false) final  int? positionTicks;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaystateData&&(identical(other.playSessionId, playSessionId) || other.playSessionId == playSessionId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.item, item) || other.item == item)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaSourceId, mediaSourceId) || other.mediaSourceId == mediaSourceId)&&(identical(other.positionTicks, positionTicks) || other.positionTicks == positionTicks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playSessionId,itemId,item,sessionId,mediaSourceId,positionTicks);

@override
String toString() {
  return 'PlaystateData(playSessionId: $playSessionId, itemId: $itemId, item: $item, sessionId: $sessionId, mediaSourceId: $mediaSourceId, positionTicks: $positionTicks)';
}


}

/// @nodoc
abstract mixin class _$PlaystateDataCopyWith<$Res> implements $PlaystateDataCopyWith<$Res> {
  factory _$PlaystateDataCopyWith(_PlaystateData value, $Res Function(_PlaystateData) _then) = __$PlaystateDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'PlaySessionId') String playSessionId,@JsonKey(name: 'ItemId') String itemId,@JsonKey(name: 'Item', includeIfNull: false) ItemDTO? item,@JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,@JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,@JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks
});


@override $ItemDTOCopyWith<$Res>? get item;

}
/// @nodoc
class __$PlaystateDataCopyWithImpl<$Res>
    implements _$PlaystateDataCopyWith<$Res> {
  __$PlaystateDataCopyWithImpl(this._self, this._then);

  final _PlaystateData _self;
  final $Res Function(_PlaystateData) _then;

/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playSessionId = null,Object? itemId = null,Object? item = freezed,Object? sessionId = freezed,Object? mediaSourceId = freezed,Object? positionTicks = freezed,}) {
  return _then(_PlaystateData(
playSessionId: null == playSessionId ? _self.playSessionId : playSessionId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ItemDTO?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaSourceId: freezed == mediaSourceId ? _self.mediaSourceId : mediaSourceId // ignore: cast_nullable_to_non_nullable
as String?,positionTicks: freezed == positionTicks ? _self.positionTicks : positionTicks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PlaystateData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemDTOCopyWith<$Res>? get item {
    if (_self.item == null) {
    return null;
  }

  return $ItemDTOCopyWith<$Res>(_self.item!, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

// dart format on
