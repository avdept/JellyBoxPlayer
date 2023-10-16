import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_credentials.freezed.dart';
part 'user_credentials.g.dart';

@Freezed(toJson: true)
class UserCredentials with _$UserCredentials {
  const factory UserCredentials({
    @JsonKey(name: 'Username') required String username,
    @JsonKey(name: 'Pw') required String pw,
    @JsonKey(includeFromJson: false) required String serverUrl,
  }) = _UserCredentials;

  // @override
  // Map<String, dynamic> toJson() {
  //   return {'pw': password, 'username': email};
  // }
}
