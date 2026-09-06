import 'package:test/test.dart';
import 'package:upnp_quirks/upnp_quirks.dart';

void main() {
  DeviceQueueContext context() => DeviceQueueContext(
    udn: 'uuid:device',
    transportControlUrl: Uri.parse('http://10.0.0.5:1400/ctl'),
    controlUrls: {'PlayQueue': Uri.parse('http://10.0.0.5:49152/queue')},
    invoke: (url, service, action, args) async => const {},
  );

  test('- lets a desktop drive a queueless renderer', () {
    expect(
      castingSupported(
        deviceHoldsQueue: false,
        host: ControlPointHost.sustained,
      ),
      isTrue,
    );
    expect(
      castingBlockedReason(
        deviceHoldsQueue: false,
        host: ControlPointHost.sustained,
      ),
      isNull,
    );
  });

  test('- blocks a queueless renderer on a host that suspends', () {
    expect(
      castingSupported(
        deviceHoldsQueue: false,
        host: ControlPointHost.suspending,
      ),
      isFalse,
    );
    expect(
      castingBlockedReason(
        deviceHoldsQueue: false,
        host: ControlPointHost.suspending,
      ),
      isNotNull,
    );
  });

  test('- allows a queue-holding renderer on any host', () {
    for (final host in ControlPointHost.values) {
      expect(
        castingSupported(deviceHoldsQueue: true, host: host),
        isTrue,
        reason: host.name,
      );
    }
  });

  test('- drives nothing without the private table', () {
    expect(deviceQueueFactories, isEmpty);
    expect(drivableQueueKinds, isEmpty);

    for (final kind in DeviceQueueKind.values) {
      expect(buildDeviceQueue(kind, context()), isNull, reason: kind.name);
    }
  });
}
