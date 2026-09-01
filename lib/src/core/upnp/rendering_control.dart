import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';

class RenderingControl {
  RenderingControl({required UpnpSoapClient soap, required this.controlUrl})
    : _soap = soap;

  static const serviceType = 'urn:schemas-upnp-org:service:RenderingControl:1';

  final UpnpSoapClient _soap;
  final Uri controlUrl;

  Future<Map<String, String>> _invoke(
    String action, [
    Map<String, String> arguments = const {},
  ]) => _soap.invoke(
    controlUrl: controlUrl,
    serviceType: serviceType,
    action: action,
    arguments: {'InstanceID': '0', 'Channel': 'Master', ...arguments},
  );

  Future<double?> volume() async {
    final result = await _invoke('GetVolume');
    final value = int.tryParse(result['CurrentVolume'] ?? '');
    return value == null ? null : (value / 100).clamp(0.0, 1.0);
  }

  Future<void> setVolume(double level) => _invoke('SetVolume', {
    'DesiredVolume': '${(level.clamp(0.0, 1.0) * 100).round()}',
  });

  Future<void> setMute({required bool muted}) =>
      _invoke('SetMute', {'DesiredMute': muted ? '1' : '0'});
}
