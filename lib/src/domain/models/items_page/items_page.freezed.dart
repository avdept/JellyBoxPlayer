// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'items_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ItemsPage {
  List<ItemDTO> get items => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get totalPerPage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ItemsPageCopyWith<ItemsPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsPageCopyWith<$Res> {
  factory $ItemsPageCopyWith(ItemsPage value, $Res Function(ItemsPage) then) =
      _$ItemsPageCopyWithImpl<$Res, ItemsPage>;
  @useResult
  $Res call({List<ItemDTO> items, int currentPage, int totalPerPage});
}

/// @nodoc
class _$ItemsPageCopyWithImpl<$Res, $Val extends ItemsPage>
    implements $ItemsPageCopyWith<$Res> {
  _$ItemsPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentPage = null,
    Object? totalPerPage = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemDTO>,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      totalPerPage: null == totalPerPage
          ? _value.totalPerPage
          : totalPerPage // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemsPageImplCopyWith<$Res>
    implements $ItemsPageCopyWith<$Res> {
  factory _$$ItemsPageImplCopyWith(
          _$ItemsPageImpl value, $Res Function(_$ItemsPageImpl) then) =
      __$$ItemsPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ItemDTO> items, int currentPage, int totalPerPage});
}

/// @nodoc
class __$$ItemsPageImplCopyWithImpl<$Res>
    extends _$ItemsPageCopyWithImpl<$Res, _$ItemsPageImpl>
    implements _$$ItemsPageImplCopyWith<$Res> {
  __$$ItemsPageImplCopyWithImpl(
      _$ItemsPageImpl _value, $Res Function(_$ItemsPageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? currentPage = null,
    Object? totalPerPage = null,
  }) {
    return _then(_$ItemsPageImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemDTO>,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      totalPerPage: null == totalPerPage
          ? _value.totalPerPage
          : totalPerPage // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ItemsPageImpl implements _ItemsPage {
  const _$ItemsPageImpl(
      {final List<ItemDTO> items = const [],
      this.currentPage = 0,
      this.totalPerPage = 100})
      : _items = items;

  final List<ItemDTO> _items;
  @override
  @JsonKey()
  List<ItemDTO> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int totalPerPage;

  @override
  String toString() {
    return 'ItemsPage(items: $items, currentPage: $currentPage, totalPerPage: $totalPerPage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemsPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.totalPerPage, totalPerPage) ||
                other.totalPerPage == totalPerPage));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), currentPage, totalPerPage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemsPageImplCopyWith<_$ItemsPageImpl> get copyWith =>
      __$$ItemsPageImplCopyWithImpl<_$ItemsPageImpl>(this, _$identity);
}

abstract class _ItemsPage implements ItemsPage {
  const factory _ItemsPage(
      {final List<ItemDTO> items,
      final int currentPage,
      final int totalPerPage}) = _$ItemsPageImpl;

  @override
  List<ItemDTO> get items;
  @override
  int get currentPage;
  @override
  int get totalPerPage;
  @override
  @JsonKey(ignore: true)
  _$$ItemsPageImplCopyWith<_$ItemsPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
