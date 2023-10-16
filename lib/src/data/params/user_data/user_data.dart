import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

@Freezed(toJson: true, fromJson: false)
class UserData with _$UserData {
  const factory UserData({
    required String id,
    required String name,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) {
    final userJson = json["User"] as Map<String, dynamic>;
    return UserData(name: userJson['Name'].toString(), id: userJson["UserId"].toString());
  }
}

@Freezed(toJson: true)
class UserDataWrapper with _$UserDataWrapper {
  const factory UserDataWrapper(UserData user) = _UserDataWrapper;
}
