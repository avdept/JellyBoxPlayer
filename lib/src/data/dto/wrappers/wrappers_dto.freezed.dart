// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wrappers_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

AlbumsWrapper _$AlbumsWrapperFromJson(Map<String, dynamic> json) {
  return _AlbumsWrapper.fromJson(json);
}

/// @nodoc
mixin _$AlbumsWrapper {
  @JsonKey(name: 'Items')
  List<ItemDTO> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'TotalRecordCount')
  int get totalRecordCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AlbumsWrapperCopyWith<AlbumsWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumsWrapperCopyWith<$Res> {
  factory $AlbumsWrapperCopyWith(
          AlbumsWrapper value, $Res Function(AlbumsWrapper) then) =
      _$AlbumsWrapperCopyWithImpl<$Res, AlbumsWrapper>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Items') List<ItemDTO> items,
      @JsonKey(name: 'TotalRecordCount') int totalRecordCount});
}

/// @nodoc
class _$AlbumsWrapperCopyWithImpl<$Res, $Val extends AlbumsWrapper>
    implements $AlbumsWrapperCopyWith<$Res> {
  _$AlbumsWrapperCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalRecordCount = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemDTO>,
      totalRecordCount: null == totalRecordCount
          ? _value.totalRecordCount
          : totalRecordCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumsWrapperImplCopyWith<$Res>
    implements $AlbumsWrapperCopyWith<$Res> {
  factory _$$AlbumsWrapperImplCopyWith(
          _$AlbumsWrapperImpl value, $Res Function(_$AlbumsWrapperImpl) then) =
      __$$AlbumsWrapperImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Items') List<ItemDTO> items,
      @JsonKey(name: 'TotalRecordCount') int totalRecordCount});
}

/// @nodoc
class __$$AlbumsWrapperImplCopyWithImpl<$Res>
    extends _$AlbumsWrapperCopyWithImpl<$Res, _$AlbumsWrapperImpl>
    implements _$$AlbumsWrapperImplCopyWith<$Res> {
  __$$AlbumsWrapperImplCopyWithImpl(
      _$AlbumsWrapperImpl _value, $Res Function(_$AlbumsWrapperImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalRecordCount = null,
  }) {
    return _then(_$AlbumsWrapperImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItemDTO>,
      totalRecordCount: null == totalRecordCount
          ? _value.totalRecordCount
          : totalRecordCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumsWrapperImpl implements _AlbumsWrapper {
  const _$AlbumsWrapperImpl(
      {@JsonKey(name: 'Items') required final List<ItemDTO> items,
      @JsonKey(name: 'TotalRecordCount') required this.totalRecordCount})
      : _items = items;

  factory _$AlbumsWrapperImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumsWrapperImplFromJson(json);

  final List<ItemDTO> _items;
  @override
  @JsonKey(name: 'Items')
  List<ItemDTO> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'TotalRecordCount')
  final int totalRecordCount;

  @override
  String toString() {
    return 'AlbumsWrapper(items: $items, totalRecordCount: $totalRecordCount)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumsWrapperImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalRecordCount, totalRecordCount) ||
                other.totalRecordCount == totalRecordCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), totalRecordCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumsWrapperImplCopyWith<_$AlbumsWrapperImpl> get copyWith =>
      __$$AlbumsWrapperImplCopyWithImpl<_$AlbumsWrapperImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumsWrapperImplToJson(
      this,
    );
  }
}

abstract class _AlbumsWrapper implements AlbumsWrapper {
  const factory _AlbumsWrapper(
      {@JsonKey(name: 'Items') required final List<ItemDTO> items,
      @JsonKey(name: 'TotalRecordCount')
      required final int totalRecordCount}) = _$AlbumsWrapperImpl;

  factory _AlbumsWrapper.fromJson(Map<String, dynamic> json) =
      _$AlbumsWrapperImpl.fromJson;

  @override
  @JsonKey(name: 'Items')
  List<ItemDTO> get items;
  @override
  @JsonKey(name: 'TotalRecordCount')
  int get totalRecordCount;
  @override
  @JsonKey(ignore: true)
  _$$AlbumsWrapperImplCopyWith<_$AlbumsWrapperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
