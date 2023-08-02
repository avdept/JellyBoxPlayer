// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Filter {
  Entities get orderBy => throw _privateConstructorUsedError;
  Order get order => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FilterCopyWith<Filter> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterCopyWith<$Res> {
  factory $FilterCopyWith(Filter value, $Res Function(Filter) then) =
      _$FilterCopyWithImpl<$Res, Filter>;
  @useResult
  $Res call({Entities orderBy, Order order});
}

/// @nodoc
class _$FilterCopyWithImpl<$Res, $Val extends Filter>
    implements $FilterCopyWith<$Res> {
  _$FilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderBy = null,
    Object? order = null,
  }) {
    return _then(_value.copyWith(
      orderBy: null == orderBy
          ? _value.orderBy
          : orderBy // ignore: cast_nullable_to_non_nullable
              as Entities,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as Order,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_FilterCopyWith<$Res> implements $FilterCopyWith<$Res> {
  factory _$$_FilterCopyWith(_$_Filter value, $Res Function(_$_Filter) then) =
      __$$_FilterCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Entities orderBy, Order order});
}

/// @nodoc
class __$$_FilterCopyWithImpl<$Res>
    extends _$FilterCopyWithImpl<$Res, _$_Filter>
    implements _$$_FilterCopyWith<$Res> {
  __$$_FilterCopyWithImpl(_$_Filter _value, $Res Function(_$_Filter) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderBy = null,
    Object? order = null,
  }) {
    return _then(_$_Filter(
      orderBy: null == orderBy
          ? _value.orderBy
          : orderBy // ignore: cast_nullable_to_non_nullable
              as Entities,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as Order,
    ));
  }
}

/// @nodoc

class _$_Filter implements _Filter {
  const _$_Filter({this.orderBy = Entities.albums, this.order = Order.asc});

  @override
  @JsonKey()
  final Entities orderBy;
  @override
  @JsonKey()
  final Order order;

  @override
  String toString() {
    return 'Filter(orderBy: $orderBy, order: $order)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Filter &&
            (identical(other.orderBy, orderBy) || other.orderBy == orderBy) &&
            (identical(other.order, order) || other.order == order));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderBy, order);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_FilterCopyWith<_$_Filter> get copyWith =>
      __$$_FilterCopyWithImpl<_$_Filter>(this, _$identity);
}

abstract class _Filter implements Filter {
  const factory _Filter({final Entities orderBy, final Order order}) =
      _$_Filter;

  @override
  Entities get orderBy;
  @override
  Order get order;
  @override
  @JsonKey(ignore: true)
  _$$_FilterCopyWith<_$_Filter> get copyWith =>
      throw _privateConstructorUsedError;
}
