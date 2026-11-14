// The XML below is built from adjacent fragments on purpose; whitespace
// between them would land inside the documents.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:async';
import 'dart:io';

import 'package:xml/xml.dart';

class FakeSonosModel {
  const FakeSonosModel(this.name, this.number);

  static const play5 = FakeSonosModel('Sonos Play:5', 'S12');

  final String name;
  final String number;
}

class FakeSonosPlayer {
  FakeSonosPlayer._(
    this.household,
    this.rincon,
    this.name, {
    required this.visible,
    required this.volume,
    required this.model,
  });

  static const trackLength = Duration(minutes: 3);

  final FakeSonosHousehold household;
  final String rincon;
  final String name;
  final bool visible;
  final FakeSonosModel model;
  int volume;
  String? transportUri;
  bool playing = false;
  final queue = <String>[];
  int queueIndex = 0;
  Duration _offset = Duration.zero;
  DateTime? _startedAt;
  late final HttpServer _server;
  late final String _host;

  String get udn => 'uuid:$rincon';

  Uri get location =>
      Uri.parse('http://$_host:${_server.port}/xml/device_description.xml');

  Duration get position {
    final started = _startedAt;
    if (!playing || started == null) return _offset;
    final elapsed = _offset + DateTime.now().difference(started);
    if (elapsed < trackLength || queue.isEmpty) return elapsed;
    _offset = Duration.zero;
    _startedAt = DateTime.now();
    if (queueIndex + 1 < queue.length) {
      queueIndex++;
    } else {
      playing = false;
      queueIndex = 0;
    }
    return _offset;
  }

  String get currentTrackUri {
    final uri = transportUri ?? '';
    if (!uri.startsWith('x-rincon-queue:')) return uri;
    return queue.isEmpty ? '' : queue[queueIndex.clamp(0, queue.length - 1)];
  }

  void _play() {
    position;
    playing = true;
    _startedAt = DateTime.now();
  }

  void _pause() {
    _offset = position;
    playing = false;
    _startedAt = null;
  }

  void _seekTo(Duration offset) {
    _offset = offset;
    if (playing) _startedAt = DateTime.now();
  }

  String get coordinator => household._coordinatorOf(rincon);

  bool get isCoordinator => coordinator == rincon;
}

class FakeSonosHousehold {
  FakeSonosHousehold({
    InternetAddress? bind,
    String? advertiseHost,
    this.icons = const {},
    this.onLog,
  }) : _bind = bind ?? InternetAddress.loopbackIPv4,
       _advertiseHost =
           advertiseHost ?? (bind ?? InternetAddress.loopbackIPv4).address;

  final InternetAddress _bind;
  final String _advertiseHost;
  final Map<String, List<int>> icons;
  final void Function(String line)? onLog;
  final _players = <String, FakeSonosPlayer>{};
  final _groups = <String, List<String>>{};
  final _snapshots = <String, Map<String, int>>{};
  final log = <String>[];
  var _serial = 0;

  Iterable<FakeSonosPlayer> get players => _players.values;

  FakeSonosPlayer player(String name) =>
      _players.values.firstWhere((player) => player.name == name);

  List<List<String>> get groups => [
    for (final entry in _groups.entries)
      [for (final rincon in entry.value) _players[rincon]!.name],
  ];

  Future<FakeSonosPlayer> addPlayer(
    String name, {
    String? rincon,
    bool visible = true,
    int volume = 30,
    FakeSonosModel model = FakeSonosModel.play5,
  }) async {
    final id = rincon ?? 'RINCON_${(++_serial).toString().padLeft(12, '0')}';
    final player = FakeSonosPlayer._(
      this,
      id,
      name,
      visible: visible,
      volume: volume,
      model: model,
    );
    final server = await HttpServer.bind(_bind, 0);
    server.listen((request) => _handle(player, request));
    player
      .._server = server
      .._host = _advertiseHost;
    _players[id] = player;
    _groups[id] = [id];
    return player;
  }

  void group(String coordinatorName, List<String> memberNames) {
    final coordinator = player(coordinatorName).rincon;
    for (final name in memberNames) {
      _join(player(name).rincon, coordinator);
    }
  }

  Future<void> close() async {
    for (final player in _players.values) {
      await player._server.close(force: true);
    }
  }

  String _coordinatorOf(String rincon) =>
      _groups.entries.firstWhere((entry) => entry.value.contains(rincon)).key;

  void _detach(String rincon) {
    final coordinator = _coordinatorOf(rincon);
    if (coordinator == rincon) {
      final rest = _groups.remove(rincon)!..remove(rincon);
      if (rest.isNotEmpty) _groups[rest.first] = rest;
    } else {
      _groups[coordinator]!.remove(rincon);
    }
    _groups[rincon] = [rincon];
  }

  void _join(String rincon, String coordinator) {
    if (!_groups.containsKey(coordinator)) {
      throw const _Fault('800');
    }
    _detach(rincon);
    _groups.remove(rincon);
    _groups[coordinator]!.add(rincon);
  }

  void _log(String line) {
    log.add(line);
    onLog?.call(line);
  }

  Future<void> _handle(FakeSonosPlayer player, HttpRequest request) async {
    final path = request.uri.path;
    try {
      if (request.method == 'GET') {
        final icon = icons[player.model.number];
        if (icon != null && path == _iconPath(player)) {
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(icon);
          unawaited(request.response.close());
          return;
        }
        _serveXml(request.response, _document(player, path));
        return;
      }
      final body = await utf8Body(request);
      final envelope = XmlDocument.parse(body);
      final action = envelope.rootElement
          .findAllElements('Body', namespace: '*')
          .first
          .childElements
          .first;
      final args = {
        for (final child in action.childElements)
          child.localName: child.innerText,
      };
      _log('${player.name} ${action.localName}');
      final service = action.name.namespaceUri ?? '';
      final out = _dispatch(player, path, action.localName, args);
      _serveXml(
        request.response,
        '<?xml version="1.0"?><s:Envelope '
        'xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
        '<s:Body><u:${action.localName}Response xmlns:u="$service">'
        '${_outArgs(out)}'
        '</u:${action.localName}Response></s:Body></s:Envelope>',
      );
    } on _Fault catch (fault) {
      request.response.statusCode = 500;
      _serveXml(
        request.response,
        '<?xml version="1.0"?><s:Envelope '
        'xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>'
        '<s:Fault><faultcode>s:Client</faultcode>'
        '<faultstring>UPnPError</faultstring><detail>'
        '<UPnPError xmlns="urn:schemas-upnp-org:control-1-0">'
        '<errorCode>${fault.code}</errorCode></UPnPError>'
        '</detail></s:Fault></s:Body></s:Envelope>',
      );
    } on Object {
      request.response.statusCode = 404;
      await request.response.close();
    }
  }

  Map<String, String> _dispatch(
    FakeSonosPlayer player,
    String path,
    String action,
    Map<String, String> args,
  ) {
    switch (path) {
      case '/ZoneGroupTopology/Control':
        if (action == 'GetZoneGroupState') {
          return {'ZoneGroupState': _zoneGroupState()};
        }
      case '/MediaRenderer/AVTransport/Control':
        return _transport(player, action, args);
      case '/MediaRenderer/RenderingControl/Control':
        if (action == 'GetVolume') return {'CurrentVolume': '${player.volume}'};
        if (action == 'SetVolume') {
          player.volume = int.parse(args['DesiredVolume']!);
          return const {};
        }
      case '/MediaRenderer/GroupRenderingControl/Control':
        return _groupRendering(player, action, args);
      case '/MediaRenderer/ConnectionManager/Control':
        if (action == 'GetProtocolInfo') {
          return const {
            'Source': '',
            'Sink': 'http-get:*:audio/mpeg:*,http-get:*:audio/flac:*',
          };
        }
    }
    throw const _Fault('401');
  }

  Map<String, String> _transport(
    FakeSonosPlayer player,
    String action,
    Map<String, String> args,
  ) {
    final members = _groups[player.rincon];
    switch (action) {
      case 'SetAVTransportURI':
        final uri = args['CurrentURI'] ?? '';
        if (uri.startsWith('x-rincon:')) {
          _join(player.rincon, uri.substring('x-rincon:'.length));
          return const {};
        }
        if (!player.isCoordinator) _detach(player.rincon);
        player.transportUri = uri;
        return const {};
      case 'BecomeCoordinatorOfStandaloneGroup':
        _detach(player.rincon);
        return {'DelegatedGroupCoordinatorID': '', 'NewGroupID': ''};
      case 'Play':
        player._play();
        return const {};
      case 'Pause':
        player._pause();
        return const {};
      case 'Stop':
        player
          .._pause()
          .._seekTo(Duration.zero);
        return const {};
      case 'Seek':
        final target = args['Target'] ?? '';
        if (args['Unit'] == 'TRACK_NR') {
          final track = int.tryParse(target) ?? 1;
          player
            ..queueIndex = (track - 1).clamp(0, player.queue.length)
            .._seekTo(Duration.zero);
        } else {
          player._seekTo(_parseDuration(target));
        }
        return const {};
      case 'Next':
        if (player.queueIndex + 1 < player.queue.length) player.queueIndex++;
        player._seekTo(Duration.zero);
        return const {};
      case 'Previous':
        if (player.queueIndex > 0) player.queueIndex--;
        player._seekTo(Duration.zero);
        return const {};
      case 'GetTransportInfo':
        final state = !player.isCoordinator || player.playing
            ? 'PLAYING'
            : player.position > Duration.zero
            ? 'PAUSED_PLAYBACK'
            : 'STOPPED';
        return {
          'CurrentTransportState': state,
          'CurrentTransportStatus': 'OK',
          'CurrentSpeed': '1',
        };
      case 'GetPositionInfo':
        return {
          'Track': player.queue.isEmpty ? '0' : '${player.queueIndex + 1}',
          'TrackDuration': _formatDuration(FakeSonosPlayer.trackLength),
          'TrackURI': player.currentTrackUri,
          'RelTime': _formatDuration(player.position),
          'AbsTime': 'NOT_IMPLEMENTED',
        };
      case 'GetMediaInfo':
        return {
          'CurrentURI': player.isCoordinator
              ? player.transportUri ?? ''
              : 'x-rincon:${player.coordinator}',
        };
      case 'AddURIToQueue':
        if (members == null) throw const _Fault('800');
        player.queue.add(args['EnqueuedURI']!);
        return {
          'FirstTrackNumberEnqueued': '${player.queue.length}',
          'NumTracksAdded': '1',
          'NewQueueLength': '${player.queue.length}',
        };
      case 'RemoveAllTracksFromQueue':
        if (members == null) throw const _Fault('800');
        player
          ..queue.clear()
          ..queueIndex = 0;
        return const {};
      case 'GetCurrentTransportActions':
        return const {'Actions': 'Play, Pause, Stop, Seek, Next, Previous'};
    }
    throw const _Fault('401');
  }

  Map<String, String> _groupRendering(
    FakeSonosPlayer player,
    String action,
    Map<String, String> args,
  ) {
    final members = _groups[player.rincon];
    if (members == null) throw const _Fault('701');
    int average(Map<String, int> volumes) =>
        (volumes.values.fold<int>(0, (sum, v) => sum + v) / volumes.length)
            .round();
    Map<String, int> current() => {
      for (final member in members) member: _players[member]!.volume,
    };
    switch (action) {
      case 'SnapshotGroupVolume':
        _snapshots[player.rincon] = current();
        return const {};
      case 'GetGroupVolume':
        return {'CurrentVolume': '${average(current())}'};
      case 'SetGroupVolume':
        final desired = int.parse(args['DesiredVolume']!);
        final snapshot = _snapshots[player.rincon] ?? current();
        final base = average(snapshot);
        for (final member in members) {
          final before = snapshot[member] ?? desired;
          _players[member]!.volume = base == 0
              ? desired
              : (before * desired / base).round().clamp(0, 100);
        }
        return const {};
    }
    throw const _Fault('401');
  }

  String _zoneGroupState() {
    final buffer = StringBuffer('<ZoneGroupState><ZoneGroups>');
    for (final entry in _groups.entries) {
      buffer.write(
        '<ZoneGroup Coordinator="${entry.key}" ID="${entry.key}:1">',
      );
      for (final rincon in entry.value) {
        final player = _players[rincon]!;
        buffer.write(
          '<ZoneGroupMember UUID="$rincon" Location="${player.location}" '
          'ZoneName="${player.name}" Configuration="1" '
          'Invisible="${player.visible ? 0 : 1}" SWGen="2"/>',
        );
      }
      buffer.write('</ZoneGroup>');
    }
    buffer.write('</ZoneGroups><VanishedDevices/></ZoneGroupState>');
    return buffer.toString();
  }

  String _document(FakeSonosPlayer player, String path) => switch (path) {
    '/xml/device_description.xml' => _description(player),
    '/xml/AVTransport1.xml' => _scpd(const [
      'SetAVTransportURI',
      'Play',
      'Pause',
      'Stop',
      'Seek',
      'Next',
      'Previous',
      'GetTransportInfo',
      'GetPositionInfo',
      'GetMediaInfo',
      'GetCurrentTransportActions',
      'AddURIToQueue',
      'RemoveAllTracksFromQueue',
      'BecomeCoordinatorOfStandaloneGroup',
    ]),
    '/xml/RenderingControl1.xml' => _scpd(const ['GetVolume', 'SetVolume']),
    '/xml/GroupRenderingControl1.xml' => _scpd(const [
      'GetGroupVolume',
      'SetGroupVolume',
      'SnapshotGroupVolume',
    ]),
    '/xml/ZoneGroupTopology1.xml' => _scpd(const ['GetZoneGroupState']),
    '/xml/ConnectionManager1.xml' => _scpd(const ['GetProtocolInfo']),
    _ => throw const FormatException('not served'),
  };

  String _iconPath(FakeSonosPlayer player) =>
      '/img/icon-${player.model.number}.png';

  static Duration _parseDuration(String value) {
    final parts = value.split(':');
    if (parts.length != 3) return Duration.zero;
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: double.tryParse(parts[2])?.floor() ?? 0,
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }

  String _description(FakeSonosPlayer player) =>
      '<?xml version="1.0" encoding="utf-8"?>'
      '<root xmlns="urn:schemas-upnp-org:device-1-0">'
      '<specVersion><major>1</major><minor>0</minor></specVersion>'
      '<device>'
      '<deviceType>urn:schemas-upnp-org:device:ZonePlayer:1</deviceType>'
      '<friendlyName>${player._host} - ${player.model.name}</friendlyName>'
      '<manufacturer>Sonos, Inc.</manufacturer>'
      '<modelNumber>${player.model.number}</modelNumber>'
      '<modelName>${player.model.name}</modelName>'
      '<UDN>${player.udn}</UDN>'
      '<iconList><icon><id>0</id><mimetype>image/png</mimetype>'
      '<width>48</width><height>48</height><depth>24</depth>'
      '<url>${_iconPath(player)}</url></icon></iconList>'
      '<roomName>${player.name}</roomName>'
      '<serviceList>'
      '${_service('ZoneGroupTopology', '/ZoneGroupTopology')}'
      '</serviceList>'
      '<deviceList><device>'
      '<deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>'
      '<friendlyName>${player.name} - ${player.model.name} Media Renderer</friendlyName>'
      '<manufacturer>Sonos, Inc.</manufacturer>'
      '<modelName>${player.model.name}</modelName>'
      '<UDN>${player.udn}_MR</UDN>'
      '<serviceList>'
      '${_service('RenderingControl', '/MediaRenderer/RenderingControl')}'
      '${_service('ConnectionManager', '/MediaRenderer/ConnectionManager')}'
      '${_service('AVTransport', '/MediaRenderer/AVTransport')}'
      '${_service('GroupRenderingControl', '/MediaRenderer/GroupRenderingControl')}'
      '</serviceList></device></deviceList>'
      '</device></root>';

  String _service(String name, String base) =>
      '<service>'
      '<serviceType>urn:schemas-upnp-org:service:$name:1</serviceType>'
      '<serviceId>urn:upnp-org:serviceId:$name</serviceId>'
      '<controlURL>$base/Control</controlURL>'
      '<eventSubURL>$base/Event</eventSubURL>'
      '<SCPDURL>/xml/${name}1.xml</SCPDURL>'
      '</service>';

  String _scpd(List<String> actions) =>
      '<?xml version="1.0" encoding="utf-8"?>'
      '<scpd xmlns="urn:schemas-upnp-org:service-1-0">'
      '<actionList>'
      '${actions.map((action) => '<action><name>$action</name></action>').join()}'
      '</actionList></scpd>';

  String _outArgs(Map<String, String> out) => out.entries
      .map((entry) => '<${entry.key}>${_escape(entry.value)}</${entry.key}>')
      .join();

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  void _serveXml(HttpResponse response, String body) {
    response.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
    response.write(body);
    unawaited(response.close());
  }

  static Future<String> utf8Body(HttpRequest request) => request
      .cast<List<int>>()
      .transform(const SystemEncoding().decoder)
      .join();
}

class _Fault implements Exception {
  const _Fault(this.code);

  final String code;
}
