// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paged_items.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PagedItems {

 Map<int, List<LibraryItem>> get pages; int? get totalCount; int get pageSize;
/// Create a copy of PagedItems
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedItemsCopyWith<PagedItems> get copyWith => _$PagedItemsCopyWithImpl<PagedItems>(this as PagedItems, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedItems&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pages),totalCount,pageSize);

@override
String toString() {
  return 'PagedItems(pages: $pages, totalCount: $totalCount, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class $PagedItemsCopyWith<$Res>  {
  factory $PagedItemsCopyWith(PagedItems value, $Res Function(PagedItems) _then) = _$PagedItemsCopyWithImpl;
@useResult
$Res call({
 Map<int, List<LibraryItem>> pages, int? totalCount, int pageSize
});




}
/// @nodoc
class _$PagedItemsCopyWithImpl<$Res>
    implements $PagedItemsCopyWith<$Res> {
  _$PagedItemsCopyWithImpl(this._self, this._then);

  final PagedItems _self;
  final $Res Function(PagedItems) _then;

/// Create a copy of PagedItems
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? totalCount = freezed,Object? pageSize = null,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Map<int, List<LibraryItem>>,totalCount: freezed == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int?,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PagedItems].
extension PagedItemsPatterns on PagedItems {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagedItems value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagedItems() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagedItems value)  $default,){
final _that = this;
switch (_that) {
case _PagedItems():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagedItems value)?  $default,){
final _that = this;
switch (_that) {
case _PagedItems() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, List<LibraryItem>> pages,  int? totalCount,  int pageSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagedItems() when $default != null:
return $default(_that.pages,_that.totalCount,_that.pageSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, List<LibraryItem>> pages,  int? totalCount,  int pageSize)  $default,) {final _that = this;
switch (_that) {
case _PagedItems():
return $default(_that.pages,_that.totalCount,_that.pageSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, List<LibraryItem>> pages,  int? totalCount,  int pageSize)?  $default,) {final _that = this;
switch (_that) {
case _PagedItems() when $default != null:
return $default(_that.pages,_that.totalCount,_that.pageSize);case _:
  return null;

}
}

}

/// @nodoc


class _PagedItems extends PagedItems {
  const _PagedItems({final  Map<int, List<LibraryItem>> pages = const {}, this.totalCount, this.pageSize = 100}): _pages = pages,super._();
  

 final  Map<int, List<LibraryItem>> _pages;
@override@JsonKey() Map<int, List<LibraryItem>> get pages {
  if (_pages is EqualUnmodifiableMapView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pages);
}

@override final  int? totalCount;
@override@JsonKey() final  int pageSize;

/// Create a copy of PagedItems
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagedItemsCopyWith<_PagedItems> get copyWith => __$PagedItemsCopyWithImpl<_PagedItems>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagedItems&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pages),totalCount,pageSize);

@override
String toString() {
  return 'PagedItems(pages: $pages, totalCount: $totalCount, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class _$PagedItemsCopyWith<$Res> implements $PagedItemsCopyWith<$Res> {
  factory _$PagedItemsCopyWith(_PagedItems value, $Res Function(_PagedItems) _then) = __$PagedItemsCopyWithImpl;
@override @useResult
$Res call({
 Map<int, List<LibraryItem>> pages, int? totalCount, int pageSize
});




}
/// @nodoc
class __$PagedItemsCopyWithImpl<$Res>
    implements _$PagedItemsCopyWith<$Res> {
  __$PagedItemsCopyWithImpl(this._self, this._then);

  final _PagedItems _self;
  final $Res Function(_PagedItems) _then;

/// Create a copy of PagedItems
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? totalCount = freezed,Object? pageSize = null,}) {
  return _then(_PagedItems(
pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as Map<int, List<LibraryItem>>,totalCount: freezed == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int?,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
