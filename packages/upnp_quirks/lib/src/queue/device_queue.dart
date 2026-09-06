import 'package:upnp_quirks/src/device_queue.dart';

typedef QueueInvoke =
    Future<Map<String, String>> Function(
      Uri controlUrl,
      String serviceType,
      String action,
      Map<String, String> arguments,
    );

class QueuedTrack {
  const QueuedTrack({
    required this.uri,
    required this.mimeType,
    required this.title,
    required this.duration,
    this.artist,
    this.album,
  });

  final Uri uri;
  final String mimeType;
  final String title;
  final Duration duration;
  final String? artist;
  final String? album;
}

class DeviceQueueContext {
  const DeviceQueueContext({
    required this.udn,
    required this.transportControlUrl,
    required this.invoke,
    this.controlUrls = const {},
  });

  final String udn;
  final Uri transportControlUrl;
  final QueueInvoke invoke;
  final Map<String, Uri> controlUrls;

  Uri? controlUrlFor(String shortServiceType) => controlUrls[shortServiceType];
}

abstract class DeviceQueue {
  Future<void> load(
    List<QueuedTrack> tracks, {
    required int startIndex,
    required bool autoPlay,
  });

  Future<void> skipTo(int index);

  Future<int?> currentIndex();

  Future<void> clear();
}

abstract class DeviceQueueFactory {
  const DeviceQueueFactory();

  DeviceQueueKind get kind;

  DeviceQueue? create(DeviceQueueContext context);
}
