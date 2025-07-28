// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wrappers_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemsWrapper {

@JsonKey(name: 'Items') List<ItemDTO> get items;@JsonKey(name: 'TotalRecordCount') int get totalRecordCount;
/// Create a copy of ItemsWrapper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemsWrapperCopyWith<ItemsWrapper> get copyWith => _$ItemsWrapperCopyWithImpl<ItemsWrapper>(this as ItemsWrapper, _$identity);

  /// Serializes this ItemsWrapper to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemsWrapper&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalRecordCount, totalRecordCount) || other.totalRecordCount == totalRecordCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalRecordCount);

@override
String toString() {
  return 'ItemsWrapper(items: $items, totalRecordCount: $totalRecordCount)';
}


}

/// @nodoc
abstract mixin class $ItemsWrapperCopyWith<$Res>  {
  factory $ItemsWrapperCopyWith(ItemsWrapper value, $Res Function(ItemsWrapper) _then) = _$ItemsWrapperCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Items') List<ItemDTO> items,@JsonKey(name: 'TotalRecordCount') int totalRecordCount
});




}
/// @nodoc
class _$ItemsWrapperCopyWithImpl<$Res>
    implements $ItemsWrapperCopyWith<$Res> {
  _$ItemsWrapperCopyWithImpl(this._self, this._then);

  final ItemsWrapper _self;
  final $Res Function(ItemsWrapper) _then;

/// Create a copy of ItemsWrapper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalRecordCount = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,totalRecordCount: null == totalRecordCount ? _self.totalRecordCount : totalRecordCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemsWrapper].
extension ItemsWrapperPatterns on ItemsWrapper {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemsWrapper value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemsWrapper() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemsWrapper value)  $default,){
final _that = this;
switch (_that) {
case _ItemsWrapper():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemsWrapper value)?  $default,){
final _that = this;
switch (_that) {
case _ItemsWrapper() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<ItemDTO> items, @JsonKey(name: 'TotalRecordCount')  int totalRecordCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemsWrapper() when $default != null:
return $default(_that.items,_that.totalRecordCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<ItemDTO> items, @JsonKey(name: 'TotalRecordCount')  int totalRecordCount)  $default,) {final _that = this;
switch (_that) {
case _ItemsWrapper():
return $default(_that.items,_that.totalRecordCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Items')  List<ItemDTO> items, @JsonKey(name: 'TotalRecordCount')  int totalRecordCount)?  $default,) {final _that = this;
switch (_that) {
case _ItemsWrapper() when $default != null:
return $default(_that.items,_that.totalRecordCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemsWrapper implements ItemsWrapper {
  const _ItemsWrapper({@JsonKey(name: 'Items') required final  List<ItemDTO> items, @JsonKey(name: 'TotalRecordCount') this.totalRecordCount = 0}): _items = items;
  factory _ItemsWrapper.fromJson(Map<String, dynamic> json) => _$ItemsWrapperFromJson(json);

 final  List<ItemDTO> _items;
@override@JsonKey(name: 'Items') List<ItemDTO> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'TotalRecordCount') final  int totalRecordCount;

/// Create a copy of ItemsWrapper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemsWrapperCopyWith<_ItemsWrapper> get copyWith => __$ItemsWrapperCopyWithImpl<_ItemsWrapper>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemsWrapperToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemsWrapper&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalRecordCount, totalRecordCount) || other.totalRecordCount == totalRecordCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalRecordCount);

@override
String toString() {
  return 'ItemsWrapper(items: $items, totalRecordCount: $totalRecordCount)';
}


}

/// @nodoc
abstract mixin class _$ItemsWrapperCopyWith<$Res> implements $ItemsWrapperCopyWith<$Res> {
  factory _$ItemsWrapperCopyWith(_ItemsWrapper value, $Res Function(_ItemsWrapper) _then) = __$ItemsWrapperCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Items') List<ItemDTO> items,@JsonKey(name: 'TotalRecordCount') int totalRecordCount
});




}
/// @nodoc
class __$ItemsWrapperCopyWithImpl<$Res>
    implements _$ItemsWrapperCopyWith<$Res> {
  __$ItemsWrapperCopyWithImpl(this._self, this._then);

  final _ItemsWrapper _self;
  final $Res Function(_ItemsWrapper) _then;

/// Create a copy of ItemsWrapper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalRecordCount = null,}) {
  return _then(_ItemsWrapper(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,totalRecordCount: null == totalRecordCount ? _self.totalRecordCount : totalRecordCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
