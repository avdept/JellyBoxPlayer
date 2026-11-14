import 'package:optional_features/src/upnp_quirks/device_fingerprint.dart';
import 'package:optional_features/src/upnp_quirks/queue/device_queue.dart';

class SpeakerGroupMember {
  const SpeakerGroupMember({
    required this.id,
    required this.name,
    required this.location,
    this.visible = true,
  });

  final String id;
  final String name;
  final Uri location;
  final bool visible;
}

class SpeakerGroup {
  const SpeakerGroup({
    required this.id,
    required this.coordinatorId,
    required this.members,
  });

  final String id;
  final String coordinatorId;
  final List<SpeakerGroupMember> members;

  SpeakerGroupMember get coordinator =>
      members.firstWhere((member) => member.id == coordinatorId);

  List<SpeakerGroupMember> get visibleMembers => [
    for (final member in members)
      if (member.visible) member,
  ];

  bool get playsTogether => visibleMembers.length > 1;

  bool contains(String memberId) =>
      members.any((member) => member.id == memberId);
}

class SpeakerTopology {
  const SpeakerTopology(this.groups);

  static const empty = SpeakerTopology([]);

  final List<SpeakerGroup> groups;

  Iterable<SpeakerGroupMember> get members =>
      groups.expand((group) => group.members);

  SpeakerGroup? groupOf(String memberId) {
    for (final group in groups) {
      if (group.contains(memberId)) return group;
    }
    return null;
  }

  SpeakerGroupMember? member(String id) {
    for (final member in members) {
      if (member.id == id) return member;
    }
    return null;
  }

  String? coordinatorOf(String memberId) => groupOf(memberId)?.coordinatorId;

  bool isCoordinator(String id) => coordinatorOf(id) == id;

  bool isVisible(String id) => member(id)?.visible ?? true;

  bool knows(String id) => member(id) != null;
}

abstract class SpeakerGroups {
  Future<SpeakerTopology> topology();

  Future<void> join(String memberId, String coordinatorId);

  Future<void> leave(String memberId);

  Future<int?> groupVolume(String coordinatorId);

  Future<void> setGroupVolume(String coordinatorId, int volume);

  Future<int?> memberVolume(String memberId);

  Future<void> setMemberVolume(String memberId, int volume);
}

typedef SpeakerGroupsFactory =
    SpeakerGroups? Function(
      DeviceFingerprint fingerprint,
      DeviceQueueContext context,
    );
