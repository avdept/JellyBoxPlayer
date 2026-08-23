import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_system_info_dto.freezed.dart';
part 'public_system_info_dto.g.dart';

@freezed
abstract class PublicSystemInfoDTO with _$PublicSystemInfoDTO {
  const factory PublicSystemInfoDTO({
    @JsonKey(name: 'Id') String? id,
    @JsonKey(name: 'ServerName') String? serverName,
    @JsonKey(name: 'Version') String? version,
    @JsonKey(name: 'ProductName') String? productName,
    @JsonKey(name: 'OperatingSystem') String? operatingSystem,
    @JsonKey(name: 'LocalAddress') String? localAddress,
    @JsonKey(name: 'LocalAddresses') List<String>? localAddresses,
    @JsonKey(name: 'RemoteAddresses') List<String>? remoteAddresses,
    @JsonKey(name: 'StartupWizardCompleted') bool? startupWizardCompleted,
  }) = _PublicSystemInfoDTO;

  factory PublicSystemInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$PublicSystemInfoDTOFromJson(json);
}
