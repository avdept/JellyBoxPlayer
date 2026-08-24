// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_system_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PublicSystemInfoDTO _$PublicSystemInfoDTOFromJson(Map<String, dynamic> json) =>
    _PublicSystemInfoDTO(
      id: json['Id'] as String?,
      serverName: json['ServerName'] as String?,
      version: json['Version'] as String?,
      productName: json['ProductName'] as String?,
      operatingSystem: json['OperatingSystem'] as String?,
      localAddress: json['LocalAddress'] as String?,
      localAddresses: (json['LocalAddresses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      remoteAddresses: (json['RemoteAddresses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      startupWizardCompleted: json['StartupWizardCompleted'] as bool?,
    );

Map<String, dynamic> _$PublicSystemInfoDTOToJson(
  _PublicSystemInfoDTO instance,
) => <String, dynamic>{
  'Id': instance.id,
  'ServerName': instance.serverName,
  'Version': instance.version,
  'ProductName': instance.productName,
  'OperatingSystem': instance.operatingSystem,
  'LocalAddress': instance.localAddress,
  'LocalAddresses': instance.localAddresses,
  'RemoteAddresses': instance.remoteAddresses,
  'StartupWizardCompleted': instance.startupWizardCompleted,
};
