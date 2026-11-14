import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/speaker_clusters.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/speaker_groups_provider.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:optional_features/upnp_quirks.dart';

import '../../fakes/fake_sonos_household.dart';

class _Renderers extends UpnpRenderersNotifier {
  _Renderers(List<UpnpRenderer> renderers) : super(UpnpControlPoint()) {
    state = UpnpDiscoveryState(renderers: renderers);
  }
}

class _Local implements PlaybackTarget {
  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final skip = speakerGroupsFactories.isEmpty
      ? 'needs the private optional_features package'
      : null;
  late FakeSonosHousehold household;
  late UpnpControlPoint controlPoint;

  setUp(() async {
    household = FakeSonosHousehold();
    controlPoint = UpnpControlPoint();
    await household.addPlayer('Living room', volume: 40);
    await household.addPlayer('Kitchen', volume: 20);
    await household.addPlayer('Office', volume: 60);
    await household.addPlayer('Office R', visible: false, rincon: 'RINCON_R');
    household
      ..group('Living room', ['Kitchen'])
      ..group('Office', ['Office R']);
  });

  tearDown(() => household.close());

  Future<void> settle([int ms = 60]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  ProviderContainer container(List<UpnpRenderer> renderers) {
    final created = ProviderContainer(
      overrides: [
        upnpRenderersProvider.overrideWith((ref) => _Renderers(renderers)),
        upnpControlPointProvider.overrideWithValue(controlPoint),
        localPlaybackTargetProvider.overrideWithValue(_Local()),
        speakerGroupsProvider.overrideWith(
          (ref) => SpeakerGroupsNotifier(
            ref,
            pickerInterval: const Duration(seconds: 30),
            backgroundInterval: const Duration(seconds: 30),
            settleTimeout: const Duration(seconds: 2),
            settlePollInterval: const Duration(milliseconds: 20),
            diagnostics: const Diagnostics(),
          ),
        ),
      ],
    );
    addTearDown(created.dispose);
    return created..read(speakerGroupsProvider);
  }

  group('over SOAP', () {
    test('- describes a Sonos as a groupable renderer with its icon', () async {
      final living = household.player('Living room');

      final renderer = await controlPoint.describe(living.location);

      expect(renderer, isNotNull);
      expect(renderer!.name, 'Living room');
      expect(renderer.isGroupable, isTrue);
      expect(renderer.holdsQueue, isTrue);
      expect(
        renderer.iconUrl,
        living.location.replace(path: '/img/icon-S12.png'),
      );
    });

    test('- finds the whole household from one speaker', () async {
      final renderer = (await controlPoint.describe(
        household.player('Kitchen').location,
      ))!;
      final ref = container([renderer]);

      ref.read(speakerGroupsProvider.notifier).watch();
      await settle(200);

      final state = ref.read(speakerGroupsProvider);
      final rooms = ref.read(upnpRenderersProvider).renderers;
      expect(rooms.map((r) => r.name).toSet(), {
        'Living room',
        'Kitchen',
        'Office',
      });
      final clusters = speakerClusters(rooms, state.topology);
      expect(clusters.map((c) => c.name), ['Living room', 'Office']);
      expect(clusters.first.members.map((m) => m.name), [
        'Living room',
        'Kitchen',
      ]);
      expect(
        clusters.first.coordinator!.id,
        'uuid:${household.player('Living room').rincon}',
      );
      expect(state.volumes.values, containsAll([40, 20, 60]));
      expect(state.volumes.containsKey('uuid:RINCON_R'), isFalse);
    });

    test('- joins, leaves and scales the group volume over SOAP', () async {
      final living = (await controlPoint.describe(
        household.player('Living room').location,
      ))!;
      final ref = container([living]);
      final target = UpnpPlaybackTarget(living);
      ref.read(playbackTargetProvider.notifier).select(target);
      await settle(200);
      final notifier = ref.read(speakerGroupsProvider.notifier);
      final office = household.player('Office');

      expect(await notifier.join(office.udn), isTrue);
      expect(
        household.groups,
        contains(equals(['Living room', 'Kitchen', 'Office'])),
      );
      expect(household.log, contains('Office SetAVTransportURI'));

      await target.setVolume(0.6);
      expect(
        household.log,
        containsAllInOrder([
          'Living room SnapshotGroupVolume',
          'Living room SetGroupVolume',
        ]),
      );
      expect(household.player('Living room').volume, 60);
      expect(household.player('Kitchen').volume, 30);
      expect(household.player('Office').volume, 90);
      expect(await target.currentVolume(), closeTo(0.6, 0.01));

      expect(await notifier.leave(office.udn), isTrue);
      expect(household.groups, contains(equals(['Office'])));
      expect(
        household.log,
        contains('Office BecomeCoordinatorOfStandaloneGroup'),
      );
      expect(household.player('Living room').playing, isFalse);
    });

    test(
      '- a plain volume change on one member stays on that member',
      () async {
        final living = (await controlPoint.describe(
          household.player('Living room').location,
        ))!;
        final ref = container([living]);
        ref
            .read(playbackTargetProvider.notifier)
            .select(UpnpPlaybackTarget(living));
        await settle(200);

        await ref
            .read(speakerGroupsProvider.notifier)
            .setMemberVolume(household.player('Kitchen').udn, 0.55);

        expect(household.player('Kitchen').volume, 55);
        expect(household.player('Living room').volume, 40);
      },
    );
  }, skip: skip);
}
