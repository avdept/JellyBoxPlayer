// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserDataCopyWith<UserData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataCopyWith<$Res> {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) then) =
      _$UserDataCopyWithImpl<$Res, UserData>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$UserDataCopyWithImpl<$Res, $Val extends UserData>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserDataImplCopyWith<$Res>
    implements $UserDataCopyWith<$Res> {
  factory _$$UserDataImplCopyWith(
          _$UserDataImpl value, $Res Function(_$UserDataImpl) then) =
      __$$UserDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$UserDataImplCopyWithImpl<$Res>
    extends _$UserDataCopyWithImpl<$Res, _$UserDataImpl>
    implements _$$UserDataImplCopyWith<$Res> {
  __$$UserDataImplCopyWithImpl(
      _$UserDataImpl _value, $Res Function(_$UserDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$UserDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable(createFactory: false)
class _$UserDataImpl implements _UserData {
  const _$UserDataImpl({required this.id, required this.name});

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'UserData(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      __$$UserDataImplCopyWithImpl<_$UserDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataImplToJson(
      this,
    );
  }
}

abstract class _UserData implements UserData {
  const factory _UserData(
      {required final String id, required final String name}) = _$UserDataImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$UserDataImplCopyWith<_$UserDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$UserDataWrapper {
  UserData get user => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserDataWrapperCopyWith<UserDataWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDataWrapperCopyWith<$Res> {
  factory $UserDataWrapperCopyWith(
          UserDataWrapper value, $Res Function(UserDataWrapper) then) =
      _$UserDataWrapperCopyWithImpl<$Res, UserDataWrapper>;
  @useResult
  $Res call({UserData user});

  $UserDataCopyWith<$Res> get user;
}

/// @nodoc
class _$UserDataWrapperCopyWithImpl<$Res, $Val extends UserDataWrapper>
    implements $UserDataWrapperCopyWith<$Res> {
  _$UserDataWrapperCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
  }) {
    return _then(_value.copyWith(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserData,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserDataCopyWith<$Res> get user {
    return $UserDataCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserDataWrapperImplCopyWith<$Res>
    implements $UserDataWrapperCopyWith<$Res> {
  factory _$$UserDataWrapperImplCopyWith(_$UserDataWrapperImpl value,
          $Res Function(_$UserDataWrapperImpl) then) =
      __$$UserDataWrapperImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UserData user});

  @override
  $UserDataCopyWith<$Res> get user;
}

/// @nodoc
class __$$UserDataWrapperImplCopyWithImpl<$Res>
    extends _$UserDataWrapperCopyWithImpl<$Res, _$UserDataWrapperImpl>
    implements _$$UserDataWrapperImplCopyWith<$Res> {
  __$$UserDataWrapperImplCopyWithImpl(
      _$UserDataWrapperImpl _value, $Res Function(_$UserDataWrapperImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
  }) {
    return _then(_$UserDataWrapperImpl(
      null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserData,
    ));
  }
}

/// @nodoc
@JsonSerializable(createFactory: false)
class _$UserDataWrapperImpl implements _UserDataWrapper {
  const _$UserDataWrapperImpl(this.user);

  @override
  final UserData user;

  @override
  String toString() {
    return 'UserDataWrapper(user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDataWrapperImpl &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDataWrapperImplCopyWith<_$UserDataWrapperImpl> get copyWith =>
      __$$UserDataWrapperImplCopyWithImpl<_$UserDataWrapperImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDataWrapperImplToJson(
      this,
    );
  }
}

abstract class _UserDataWrapper implements UserDataWrapper {
  const factory _UserDataWrapper(final UserData user) = _$UserDataWrapperImpl;

  @override
  UserData get user;
  @override
  @JsonKey(ignore: true)
  _$$UserDataWrapperImplCopyWith<_$UserDataWrapperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
