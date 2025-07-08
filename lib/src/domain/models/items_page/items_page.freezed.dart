// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'items_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemsPage {

 List<ItemDTO> get items; int get currentPage; int get totalPerPage;
/// Create a copy of ItemsPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemsPageCopyWith<ItemsPage> get copyWith => _$ItemsPageCopyWithImpl<ItemsPage>(this as ItemsPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemsPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalPerPage, totalPerPage) || other.totalPerPage == totalPerPage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),currentPage,totalPerPage);

@override
String toString() {
  return 'ItemsPage(items: $items, currentPage: $currentPage, totalPerPage: $totalPerPage)';
}


}

/// @nodoc
abstract mixin class $ItemsPageCopyWith<$Res>  {
  factory $ItemsPageCopyWith(ItemsPage value, $Res Function(ItemsPage) _then) = _$ItemsPageCopyWithImpl;
@useResult
$Res call({
 List<ItemDTO> items, int currentPage, int totalPerPage
});




}
/// @nodoc
class _$ItemsPageCopyWithImpl<$Res>
    implements $ItemsPageCopyWith<$Res> {
  _$ItemsPageCopyWithImpl(this._self, this._then);

  final ItemsPage _self;
  final $Res Function(ItemsPage) _then;

/// Create a copy of ItemsPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? currentPage = null,Object? totalPerPage = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalPerPage: null == totalPerPage ? _self.totalPerPage : totalPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemsPage].
extension ItemsPagePatterns on ItemsPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemsPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemsPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemsPage value)  $default,){
final _that = this;
switch (_that) {
case _ItemsPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemsPage value)?  $default,){
final _that = this;
switch (_that) {
case _ItemsPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ItemDTO> items,  int currentPage,  int totalPerPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemsPage() when $default != null:
return $default(_that.items,_that.currentPage,_that.totalPerPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ItemDTO> items,  int currentPage,  int totalPerPage)  $default,) {final _that = this;
switch (_that) {
case _ItemsPage():
return $default(_that.items,_that.currentPage,_that.totalPerPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ItemDTO> items,  int currentPage,  int totalPerPage)?  $default,) {final _that = this;
switch (_that) {
case _ItemsPage() when $default != null:
return $default(_that.items,_that.currentPage,_that.totalPerPage);case _:
  return null;

}
}

}

/// @nodoc


class _ItemsPage implements ItemsPage {
  const _ItemsPage({final  List<ItemDTO> items = const [], this.currentPage = 0, this.totalPerPage = 100}): _items = items;
  

 final  List<ItemDTO> _items;
@override@JsonKey() List<ItemDTO> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int totalPerPage;

/// Create a copy of ItemsPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemsPageCopyWith<_ItemsPage> get copyWith => __$ItemsPageCopyWithImpl<_ItemsPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemsPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.totalPerPage, totalPerPage) || other.totalPerPage == totalPerPage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),currentPage,totalPerPage);

@override
String toString() {
  return 'ItemsPage(items: $items, currentPage: $currentPage, totalPerPage: $totalPerPage)';
}


}

/// @nodoc
abstract mixin class _$ItemsPageCopyWith<$Res> implements $ItemsPageCopyWith<$Res> {
  factory _$ItemsPageCopyWith(_ItemsPage value, $Res Function(_ItemsPage) _then) = __$ItemsPageCopyWithImpl;
@override @useResult
$Res call({
 List<ItemDTO> items, int currentPage, int totalPerPage
});




}
/// @nodoc
class __$ItemsPageCopyWithImpl<$Res>
    implements _$ItemsPageCopyWith<$Res> {
  __$ItemsPageCopyWithImpl(this._self, this._then);

  final _ItemsPage _self;
  final $Res Function(_ItemsPage) _then;

/// Create a copy of ItemsPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? currentPage = null,Object? totalPerPage = null,}) {
  return _then(_ItemsPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ItemDTO>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,totalPerPage: null == totalPerPage ? _self.totalPerPage : totalPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
