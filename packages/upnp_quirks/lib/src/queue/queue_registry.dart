import 'package:upnp_quirks/src/device_queue.dart';
import 'package:upnp_quirks/src/queue/device_queue.dart';

const deviceQueueFactories = <DeviceQueueFactory>[];

DeviceQueue? buildDeviceQueue(
  DeviceQueueKind kind,
  DeviceQueueContext context,
) {
  if (!kind.holdsQueue) return null;
  for (final factory in deviceQueueFactories) {
    if (factory.kind != kind) continue;
    final queue = factory.create(context);
    if (queue != null) return queue;
  }
  return null;
}

Set<DeviceQueueKind> get drivableQueueKinds => {
  for (final factory in deviceQueueFactories) factory.kind,
};
