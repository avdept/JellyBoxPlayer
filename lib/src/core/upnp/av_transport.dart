import 'package:jplayer/src/core/upnp/upnp_duration.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';

enum AvTransportState {
  stopped,
  playing,
  pausedPlayback,
  pausedRecording,
  transitioning,
  noMediaPresent,
  recording,
  unknown;

  static AvTransportState parse(String? value) =>
      switch (value?.trim().toUpperCase()) {
        'STOPPED' => stopped,
        'PLAYING' => playing,
        'PAUSED_PLAYBACK' => pausedPlayback,
        'PAUSED_RECORDING' => pausedRecording,
        'TRANSITIONING' => transitioning,
        'NO_MEDIA_PRESENT' => noMediaPresent,
        'RECORDING' => recording,
        _ => unknown,
      };

  bool get isPlaying => this == playing;

  bool get isPaused => this == pausedPlayback || this == pausedRecording;

  bool get isIdle => this == stopped || this == noMediaPresent;
}

class AvTransportInfo {
  const AvTransportInfo({required this.state, this.status});

  final AvTransportState state;
  final String? status;
}

class AvPositionInfo {
  const AvPositionInfo({
    required this.position,
    this.trackDuration,
    this.trackUri,
    this.track = 0,
  });

  final Duration position;
  final Duration? trackDuration;
  final String? trackUri;
  final int track;
}

class AvTransport {
  AvTransport({
    required UpnpSoapClient soap,
    required this.controlUrl,
    this.actions = const <String>{},
  }) : _soap = soap;

  static const serviceType = 'urn:schemas-upnp-org:service:AVTransport:1';

  final UpnpSoapClient _soap;
  final Uri controlUrl;
  final Set<String> actions;

  bool get supportsNextUri => _supports('SetNextAVTransportURI');

  bool get supportsSeek => _supports('Seek');

  bool get supportsPause => _supports('Pause');

  bool _supports(String action) => actions.isEmpty || actions.contains(action);

  Future<Map<String, String>> _invoke(
    String action, [
    Map<String, String> arguments = const {},
  ]) => _soap.invoke(
    controlUrl: controlUrl,
    serviceType: serviceType,
    action: action,
    arguments: {'InstanceID': '0', ...arguments},
  );

  Future<void> setUri(Uri uri, {String metadata = ''}) => _invoke(
    'SetAVTransportURI',
    {'CurrentURI': '$uri', 'CurrentURIMetaData': metadata},
  );

  Future<void> setNextUri(Uri? uri, {String metadata = ''}) => _invoke(
    'SetNextAVTransportURI',
    {'NextURI': uri == null ? '' : '$uri', 'NextURIMetaData': metadata},
  );

  Future<void> play() => _invoke('Play', {'Speed': '1'});

  Future<void> pause() => _invoke('Pause');

  Future<void> stopTransport() => _invoke('Stop');

  Future<void> seek(Duration position, {String unit = 'REL_TIME'}) =>
      _invoke('Seek', {
        'Unit': unit,
        'Target': formatUpnpDuration(position),
      });

  Future<AvTransportInfo> transportInfo() async {
    final result = await _invoke('GetTransportInfo');
    return AvTransportInfo(
      state: AvTransportState.parse(result['CurrentTransportState']),
      status: result['CurrentTransportStatus'],
    );
  }

  Future<AvPositionInfo> positionInfo() async {
    final result = await _invoke('GetPositionInfo');
    final uri = result['TrackURI']?.trim();
    return AvPositionInfo(
      position:
          parseUpnpDuration(result['RelTime']) ??
          parseUpnpDuration(result['AbsTime']) ??
          Duration.zero,
      trackDuration: parseUpnpDuration(result['TrackDuration']),
      trackUri: (uri == null || uri.isEmpty) ? null : uri,
      track: int.tryParse(result['Track'] ?? '') ?? 0,
    );
  }

  Future<Set<String>> currentTransportActions() async {
    final result = await _invoke('GetCurrentTransportActions');
    final actions = result['Actions'] ?? '';
    return {
      for (final action in actions.split(','))
        if (action.trim().isNotEmpty) action.trim(),
    };
  }
}
