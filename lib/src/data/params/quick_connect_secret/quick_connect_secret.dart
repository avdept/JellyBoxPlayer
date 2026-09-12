import 'package:freezed_annotation/freezed_annotation.dart';

part 'quick_connect_secret.freezed.dart';
part 'quick_connect_secret.g.dart';

@Freezed(toJson: true)
abstract class QuickConnectSecret with _$QuickConnectSecret {
  const factory QuickConnectSecret({
    @JsonKey(name: 'Secret') required String secret,
  }) = _QuickConnectSecret;
}
