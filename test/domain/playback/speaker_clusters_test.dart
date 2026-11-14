import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/speaker_clusters.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/upnp_quirks.dart';

import '../../fakes/fake_speaker_groups.dart';

class _MockAvTransport extends Mock implements AvTransport {}

void main() {
  final groups = FakeSpeakerGroups([]);

  UpnpRenderer renderer(SpeakerGroupMember member, {bool groupable = true}) =>
      UpnpRenderer(
        device: UpnpDevice(
          udn: member.id,
          friendlyName: member.name,
          deviceType: 'urn:schemas-upnp-org:device:ZonePlayer:1',
          location: member.location,
          services: const [],
          roomName: member.name,
        ),
        avTransport: _MockAvTransport(),
        groups: groupable ? groups : null,
      );

  final living = speaker('Living');
  final kitchen = speaker('Kitchen');
  final office = speaker('Office');
  final officeRight = speaker('OfficeR', visible: false);
  final topology = FakeSpeakerGroups([
    [living, kitchen],
    [office, officeRight],
  ]).current;

  test('- puts joined speakers in one cluster, coordinator first', () {
    final clusters = speakerClusters([
      renderer(kitchen),
      renderer(office),
      renderer(living),
    ], topology);

    expect(clusters, hasLength(2));
    final pair = clusters.first;
    expect(pair.name, 'Living');
    expect(pair.members.map((m) => m.name), ['Living', 'Kitchen']);
    expect(pair.coordinator?.id, living.id);
    expect(pair.playsTogether, isTrue);
    expect(pair.contains(kitchen.id), isTrue);
    expect(clusters.last.members.single.name, 'Office');
    expect(clusters.last.playsTogether, isFalse);
  });

  test('- hides the invisible half of a stereo pair', () {
    final clusters = speakerClusters([
      renderer(office),
      renderer(officeRight),
    ], topology);

    expect(clusters.single.members.map((m) => m.name), ['Office']);
  });

  test('- remembers where an undiscovered coordinator lives', () {
    final clusters = speakerClusters([renderer(kitchen)], topology);

    expect(clusters.single.coordinator, isNull);
    expect(clusters.single.coordinatorLocation, living.location);
    expect(clusters.single.name, 'Living');
  });

  test('- keeps speakers the topology does not know as singles', () {
    final clusters = speakerClusters([
      renderer(speaker('Attic')),
      renderer(living),
    ], topology);

    expect(clusters.map((c) => c.name), ['Attic', 'Living']);
    expect(clusters.first.group, isNull);
    expect(clusters.first.coordinator?.name, 'Attic');
  });

  test('- ignores renderers that cannot group at all', () {
    expect(
      speakerClusters([renderer(living, groupable: false)], topology),
      isEmpty,
    );
  });
}
