// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserCredentials {
  @JsonKey(name: 'Username')
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'Pw')
  String get pw => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false)
  String get serverUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserCredentialsCopyWith<UserCredentials> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCredentialsCopyWith<$Res> {
  factory $UserCredentialsCopyWith(
          UserCredentials value, $Res Function(UserCredentials) then) =
      _$UserCredentialsCopyWithImpl<$Res, UserCredentials>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Username') String username,
      @JsonKey(name: 'Pw') String pw,
      @JsonKey(includeFromJson: false) String serverUrl});
}

/// @nodoc
class _$UserCredentialsCopyWithImpl<$Res, $Val extends UserCredentials>
    implements $UserCredentialsCopyWith<$Res> {
  _$UserCredentialsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? pw = null,
    Object? serverUrl = null,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      pw: null == pw
          ? _value.pw
          : pw // ignore: cast_nullable_to_non_nullable
              as String,
      serverUrl: null == serverUrl
          ? _value.serverUrl
          : serverUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserCredentialsImplCopyWith<$Res>
    implements $UserCredentialsCopyWith<$Res> {
  factory _$$UserCredentialsImplCopyWith(_$UserCredentialsImpl value,
          $Res Function(_$UserCredentialsImpl) then) =
      __$$UserCredentialsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Username') String username,
      @JsonKey(name: 'Pw') String pw,
      @JsonKey(includeFromJson: false) String serverUrl});
}

/// @nodoc
class __$$UserCredentialsImplCopyWithImpl<$Res>
    extends _$UserCredentialsCopyWithImpl<$Res, _$UserCredentialsImpl>
    implements _$$UserCredentialsImplCopyWith<$Res> {
  __$$UserCredentialsImplCopyWithImpl(
      _$UserCredentialsImpl _value, $Res Function(_$UserCredentialsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? pw = null,
    Object? serverUrl = null,
  }) {
    return _then(_$UserCredentialsImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      pw: null == pw
          ? _value.pw
          : pw // ignore: cast_nullable_to_non_nullable
              as String,
      serverUrl: null == serverUrl
          ? _value.serverUrl
          : serverUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable(createFactory: false)
class _$UserCredentialsImpl implements _UserCredentials {
  const _$UserCredentialsImpl(
      {@JsonKey(name: 'Username') required this.username,
      @JsonKey(name: 'Pw') required this.pw,
      @JsonKey(includeFromJson: false) required this.serverUrl});

  @override
  @JsonKey(name: 'Username')
  final String username;
  @override
  @JsonKey(name: 'Pw')
  final String pw;
  @override
  @JsonKey(includeFromJson: false)
  final String serverUrl;

  @override
  String toString() {
    return 'UserCredentials(username: $username, pw: $pw, serverUrl: $serverUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCredentialsImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.pw, pw) || other.pw == pw) &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, username, pw, serverUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCredentialsImplCopyWith<_$UserCredentialsImpl> get copyWith =>
      __$$UserCredentialsImplCopyWithImpl<_$UserCredentialsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCredentialsImplToJson(
      this,
    );
  }
}

abstract class _UserCredentials implements UserCredentials {
  const factory _UserCredentials(
          {@JsonKey(name: 'Username') required final String username,
          @JsonKey(name: 'Pw') required final String pw,
          @JsonKey(includeFromJson: false) required final String serverUrl}) =
      _$UserCredentialsImpl;

  @override
  @JsonKey(name: 'Username')
  String get username;
  @override
  @JsonKey(name: 'Pw')
  String get pw;
  @override
  @JsonKey(includeFromJson: false)
  String get serverUrl;
  @override
  @JsonKey(ignore: true)
  _$$UserCredentialsImplCopyWith<_$UserCredentialsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
