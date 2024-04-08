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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Filter {
  EntityFilter get orderBy => throw _privateConstructorUsedError;
  bool get desc => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FilterCopyWith<Filter> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterCopyWith<$Res> {
  factory $FilterCopyWith(Filter value, $Res Function(Filter) then) =
      _$FilterCopyWithImpl<$Res, Filter>;
  @useResult
  $Res call({EntityFilter orderBy, bool desc});
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
    Object? desc = null,
  }) {
    return _then(_value.copyWith(
      orderBy: null == orderBy
          ? _value.orderBy
          : orderBy // ignore: cast_nullable_to_non_nullable
              as EntityFilter,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterImplCopyWith<$Res> implements $FilterCopyWith<$Res> {
  factory _$$FilterImplCopyWith(
          _$FilterImpl value, $Res Function(_$FilterImpl) then) =
      __$$FilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({EntityFilter orderBy, bool desc});
}

/// @nodoc
class __$$FilterImplCopyWithImpl<$Res>
    extends _$FilterCopyWithImpl<$Res, _$FilterImpl>
    implements _$$FilterImplCopyWith<$Res> {
  __$$FilterImplCopyWithImpl(
      _$FilterImpl _value, $Res Function(_$FilterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderBy = null,
    Object? desc = null,
  }) {
    return _then(_$FilterImpl(
      orderBy: null == orderBy
          ? _value.orderBy
          : orderBy // ignore: cast_nullable_to_non_nullable
              as EntityFilter,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FilterImpl implements _Filter {
  const _$FilterImpl({required this.orderBy, this.desc = false});

  @override
  final EntityFilter orderBy;
  @override
  @JsonKey()
  final bool desc;

  @override
  String toString() {
    return 'Filter(orderBy: $orderBy, desc: $desc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterImpl &&
            (identical(other.orderBy, orderBy) || other.orderBy == orderBy) &&
            (identical(other.desc, desc) || other.desc == desc));
  }

  @override
  int get hashCode => Object.hash(runtimeType, orderBy, desc);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterImplCopyWith<_$FilterImpl> get copyWith =>
      __$$FilterImplCopyWithImpl<_$FilterImpl>(this, _$identity);
}

abstract class _Filter implements Filter {
  const factory _Filter(
      {required final EntityFilter orderBy, final bool desc}) = _$FilterImpl;

  @override
  EntityFilter get orderBy;
  @override
  bool get desc;
  @override
  @JsonKey(ignore: true)
  _$$FilterImplCopyWith<_$FilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
