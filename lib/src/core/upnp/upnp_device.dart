import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

class UpnpService {
  const UpnpService({
    required this.type,
    required this.controlUrl,
    this.scpdUrl,
    this.eventSubUrl,
  });

  final String type;
  final Uri controlUrl;
  final Uri? scpdUrl;
  final Uri? eventSubUrl;

  String get shortType {
    final parts = type.split(':');
    return parts.length >= 2 ? parts[parts.length - 2] : type;
  }
}

class UpnpDevice {
  const UpnpDevice({
    required this.udn,
    required this.friendlyName,
    required this.deviceType,
    required this.location,
    required this.services,
    this.manufacturer,
    this.modelName,
    this.modelNumber,
    this.roomName,
  });

  static UpnpDevice? parse(String xml, {required Uri location}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      return null;
    }

    final device = document.descendantElements.firstWhereOrNull(
      (element) => element.localName == 'device',
    );
    if (device == null) return null;

    final base = _text(document.rootElement, 'URLBase');
    final baseUri = base != null ? Uri.tryParse(base) ?? location : location;

    final services = <UpnpService>[];
    for (final element in device.descendantElements) {
      if (element.localName != 'service') continue;
      final type = _text(element, 'serviceType');
      final control = _text(element, 'controlURL');
      if (type == null || control == null) continue;
      services.add(
        UpnpService(
          type: type,
          controlUrl: baseUri.resolve(control),
          scpdUrl: _resolve(baseUri, _text(element, 'SCPDURL')),
          eventSubUrl: _resolve(baseUri, _text(element, 'eventSubURL')),
        ),
      );
    }

    final udn = _text(device, 'UDN');
    final name = _text(device, 'friendlyName');
    if (udn == null && name == null) return null;

    return UpnpDevice(
      udn: udn ?? '$location',
      friendlyName: name ?? udn ?? '$location',
      deviceType: _text(device, 'deviceType') ?? '',
      location: location,
      services: services,
      manufacturer: _text(device, 'manufacturer'),
      modelName: _text(device, 'modelName'),
      modelNumber: _text(device, 'modelNumber'),
      roomName: _text(device, 'roomName'),
    );
  }

  final String udn;
  final String friendlyName;
  final String deviceType;
  final Uri location;
  final List<UpnpService> services;
  final String? manufacturer;
  final String? modelName;
  final String? modelNumber;
  final String? roomName;

  String get host => location.host;

  String get displayName => _tidyName(roomName ?? friendlyName, host);

  bool get isMediaRenderer => serviceOfType('AVTransport') != null;

  UpnpService? serviceOfType(String shortType) =>
      services.firstWhereOrNull((service) => service.shortType == shortType);
}

Set<String> parseScpdActions(String xml) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xml);
  } on XmlException {
    return const {};
  }

  return {
    for (final action in document.descendantElements)
      if (action.localName == 'action')
        ?action.childElements
            .firstWhereOrNull((child) => child.localName == 'name')
            ?.innerText
            .trim(),
  }..removeWhere((name) => name.isEmpty);
}

final _addressPrefix = RegExp(
  r'^\s*(\d{1,3}(?:\.\d{1,3}){3}|\[[0-9a-fA-F:]+\])(:\d+)?\s*[-:|]*\s*',
);

final _ownHostLeftovers = RegExp(r'^(:\d+)?[\s\-:|]*');

final _rendererSuffix = RegExp(
  r'\s*[(\[]?\s*(media|upnp|av|dlna)?\s*(renderer|dmr)\s*[)\]]?\s*$',
  caseSensitive: false,
);

String _tidyName(String name, String host) {
  var tidy = name.trim();

  if (host.isNotEmpty && tidy.toLowerCase().startsWith(host.toLowerCase())) {
    tidy = tidy.substring(host.length).replaceFirst(_ownHostLeftovers, '');
  }

  tidy = tidy
      .replaceFirst(_addressPrefix, '')
      .replaceFirst(_rendererSuffix, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return tidy.isEmpty ? name.trim() : tidy;
}

Uri? _resolve(Uri base, String? path) {
  if (path == null || path.isEmpty) return null;
  return base.resolve(path);
}

String? _text(XmlElement parent, String localName) {
  final element = parent.descendantElements.firstWhereOrNull(
    (child) => child.localName == localName,
  );
  final text = element?.innerText.trim();
  return (text == null || text.isEmpty) ? null : text;
}
