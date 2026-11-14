import 'package:optional_features/src/upnp_quirks/device_fingerprint.dart';
import 'package:optional_features/src/upnp_quirks/groups/speaker_groups.dart';
import 'package:optional_features/src/upnp_quirks/queue/device_queue.dart';

const speakerGroupsFactories = <SpeakerGroupsFactory>[];

SpeakerGroups? buildSpeakerGroups(
  DeviceFingerprint fingerprint,
  DeviceQueueContext context,
) {
  for (final factory in speakerGroupsFactories) {
    final groups = factory(fingerprint, context);
    if (groups != null) return groups;
  }
  return null;
}
