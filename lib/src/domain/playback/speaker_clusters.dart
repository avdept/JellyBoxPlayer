import 'package:collection/collection.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:optional_features/upnp_quirks.dart';

class SpeakerCluster {
  const SpeakerCluster({
    required this.members,
    this.group,
    this.coordinatorLocation,
  });

  final SpeakerGroup? group;
  final List<UpnpRenderer> members;
  final Uri? coordinatorLocation;

  UpnpRenderer? get coordinator {
    final group = this.group;
    if (group == null) return members.first;
    return members.firstWhereOrNull(
      (member) => member.id == group.coordinatorId,
    );
  }

  String get name => group?.coordinator.name ?? members.first.name;

  bool get playsTogether => group?.playsTogether ?? false;

  bool contains(String id) =>
      group?.contains(id) ?? members.any((member) => member.id == id);
}

List<SpeakerCluster> speakerClusters(
  Iterable<UpnpRenderer> renderers,
  SpeakerTopology topology,
) {
  final grouped = <String, List<UpnpRenderer>>{};
  final loose = <UpnpRenderer>[];
  final groupsById = {for (final group in topology.groups) group.id: group};

  for (final renderer in renderers) {
    if (!renderer.isGroupable) continue;
    final group = topology.groupOf(renderer.id);
    if (group == null) {
      loose.add(renderer);
      continue;
    }
    if (!topology.isVisible(renderer.id)) continue;
    grouped.putIfAbsent(group.id, () => []).add(renderer);
  }

  final clusters = <SpeakerCluster>[
    for (final entry in grouped.entries)
      _cluster(groupsById[entry.key]!, entry.value),
    for (final renderer in loose) SpeakerCluster(members: [renderer]),
  ];
  return clusters..sort(_byName);
}

SpeakerCluster _cluster(SpeakerGroup group, List<UpnpRenderer> members) {
  final sorted = members.sorted((a, b) {
    if (a.id == group.coordinatorId) return -1;
    if (b.id == group.coordinatorId) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  final hasCoordinator = sorted.any(
    (member) => member.id == group.coordinatorId,
  );
  return SpeakerCluster(
    group: group,
    members: sorted,
    coordinatorLocation: hasCoordinator ? null : group.coordinator.location,
  );
}

int _byName(SpeakerCluster a, SpeakerCluster b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.members.first.host.compareTo(b.members.first.host);
}
