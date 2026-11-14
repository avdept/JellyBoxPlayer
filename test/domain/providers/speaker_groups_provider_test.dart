import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/speaker_groups_provider.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/upnp_quirks.dart';

import '../../fakes/fake_speaker_groups.dart';

class _MockControlPoint extends Mock implements UpnpControlPoint {}

class _MockAvTransport extends Mock implements AvTransport {}

class _Renderers extends UpnpRenderersNotifier {
  _Renderers(List<UpnpRenderer> renderers) : super(_MockControlPoint()) {
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
  setUpAll(() => registerFallbackValue(Uri.parse('http://example.org')));

  final living = speaker('Living');
  final kitchen = speaker('Kitchen');
  final office = speaker('Office');

  late FakeSpeakerGroups groups;
  late _MockControlPoint controlPoint;

  UpnpRenderer renderer(SpeakerGroupMember member) => UpnpRenderer(
    device: UpnpDevice(
      udn: member.id,
      friendlyName: member.name,
      deviceType: 'urn:schemas-upnp-org:device:ZonePlayer:1',
      location: member.location,
      services: const [],
      roomName: member.name,
    ),
    avTransport: _MockAvTransport(),
    groups: groups,
  );

  ProviderContainer container(List<UpnpRenderer> renderers) {
    final created = ProviderContainer(
      overrides: [
        upnpRenderersProvider.overrideWith((ref) => _Renderers(renderers)),
        upnpControlPointProvider.overrideWithValue(controlPoint),
        localPlaybackTargetProvider.overrideWithValue(_Local()),
        speakerGroupsProvider.overrideWith(
          (ref) => SpeakerGroupsNotifier(
            ref,
            pickerInterval: const Duration(milliseconds: 40),
            backgroundInterval: const Duration(milliseconds: 60),
            settleTimeout: const Duration(milliseconds: 400),
            settlePollInterval: const Duration(milliseconds: 10),
            volumeSendInterval: const Duration(milliseconds: 10),
            volumeHoldFor: const Duration(milliseconds: 80),
            diagnostics: const Diagnostics(),
          ),
        ),
      ],
    );
    addTearDown(created.dispose);
    return created..read(speakerGroupsProvider);
  }

  Future<void> settle([int ms = 30]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    groups = FakeSpeakerGroups(
      [
        [living, kitchen],
        [office],
      ],
      volumes: {living.id: 40, kitchen.id: 20, office.id: 60},
    );
    controlPoint = _MockControlPoint();
    when(() => controlPoint.describe(any())).thenAnswer((_) async => null);
  });

  test('- loads nothing until someone watches or casts', () async {
    final ref = container([renderer(living)]);
    await settle();

    expect(groups.log, isEmpty);
    expect(ref.read(speakerGroupsProvider).loaded, isFalse);
  });

  test('- reads the household and every speaker volume when watched', () async {
    final ref = container([renderer(living), renderer(office)]);

    ref.read(speakerGroupsProvider.notifier).watch();
    await settle();

    final state = ref.read(speakerGroupsProvider);
    expect(state.loaded, isTrue);
    expect(state.topology.coordinatorOf(kitchen.id), living.id);
    expect(state.volumes, {living.id: 40, kitchen.id: 20, office.id: 60});
  });

  test('- keeps polling while watched and stops after', () async {
    final ref = container([renderer(living)]);
    final notifier = ref.read(speakerGroupsProvider.notifier)..watch();
    await settle(100);
    final whileWatched = groups.log.where((e) => e == 'topology').length;
    notifier.unwatch();
    await settle(100);
    final afterwards = groups.log.where((e) => e == 'topology').length;

    expect(whileWatched, greaterThanOrEqualTo(2));
    expect(afterwards, whileWatched);
  });

  test('- describes household members SSDP missed', () async {
    final ref = container([renderer(living)]);
    when(
      () => controlPoint.describe(office.location),
    ).thenAnswer((_) async => renderer(office));

    ref.read(speakerGroupsProvider.notifier).watch();
    await settle();

    expect(
      ref.read(upnpRenderersProvider).renderers.map((r) => r.id),
      containsAll([living.id, office.id]),
    );
    verify(() => controlPoint.describe(kitchen.location)).called(1);
    verify(() => controlPoint.describe(office.location)).called(1);
    await settle(60);
    verifyNever(() => controlPoint.describe(living.location));
  });

  test('- joins a speaker to the group that is playing', () async {
    final ref = container([renderer(living), renderer(office)]);
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer(living)));
    await settle();
    groups.settleAfterPolls = 2;

    final joined = await ref
        .read(speakerGroupsProvider.notifier)
        .join(office.id);

    expect(joined, isTrue);
    expect(groups.log, contains('join ${office.id} -> ${living.id}'));
    final topology = ref.read(speakerGroupsProvider).topology;
    expect(topology.coordinatorOf(office.id), living.id);
    expect(ref.read(speakerGroupsProvider).busy, isEmpty);
  });

  test('- joins into the coordinator even when a member is active', () async {
    final ref = container([renderer(kitchen), renderer(office)]);
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer(kitchen)));
    await settle();

    await ref.read(speakerGroupsProvider.notifier).join(office.id);

    expect(groups.log, contains('join ${office.id} -> ${living.id}'));
  });

  test('- refuses to join without an active speaker', () async {
    final ref = container([renderer(living), renderer(office)]);
    ref.read(speakerGroupsProvider.notifier).watch();
    await settle();

    expect(
      await ref.read(speakerGroupsProvider.notifier).join(office.id),
      isFalse,
    );
    expect(groups.log.where((e) => e.startsWith('join')), isEmpty);
  });

  test('- reports a join the device never applied', () async {
    final ref = container([renderer(living), renderer(office)]);
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer(living)));
    await settle();
    groups.settleAfterPolls = 1000;

    expect(
      await ref.read(speakerGroupsProvider.notifier).join(office.id),
      isFalse,
    );
    expect(ref.read(speakerGroupsProvider).busy, isEmpty);
  });

  test('- swallows a refused join and clears the busy mark', () async {
    final ref = container([renderer(living), renderer(office)]);
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer(living)));
    await settle();
    groups.joinError = Exception('800');

    expect(
      await ref.read(speakerGroupsProvider.notifier).join(office.id),
      isFalse,
    );
    expect(ref.read(speakerGroupsProvider).busy, isEmpty);
  });

  test('- lets a member leave but never the active coordinator', () async {
    final ref = container([renderer(living), renderer(kitchen)]);
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer(living)));
    await settle();
    final notifier = ref.read(speakerGroupsProvider.notifier);

    expect(await notifier.leave(living.id), isFalse);
    expect(await notifier.leave(kitchen.id), isTrue);
    expect(
      ref.read(speakerGroupsProvider).topology.isCoordinator(kitchen.id),
      isTrue,
    );
  });

  test(
    '- routes the active target volume to the group only when grouped',
    () async {
      final target = UpnpPlaybackTarget(renderer(living));
      final ref = container([renderer(living), renderer(kitchen)]);
      ref.read(playbackTargetProvider.notifier).select(target);
      await settle();

      expect(target.playsToGroup, isTrue);

      await ref.read(speakerGroupsProvider.notifier).leave(kitchen.id);

      expect(target.playsToGroup, isFalse);
    },
  );

  test('- forgets the group flag when playback moves elsewhere', () async {
    final target = UpnpPlaybackTarget(renderer(living));
    final ref = container([renderer(living)]);
    final targets = ref.read(playbackTargetProvider.notifier)..select(target);
    await settle();
    expect(target.playsToGroup, isTrue);

    targets.useLocal();

    expect(target.playsToGroup, isFalse);
  });

  test('- throttles slider drags and holds the value against polls', () async {
    final ref = container([renderer(living), renderer(kitchen)]);
    final notifier = ref.read(speakerGroupsProvider.notifier)..watch();
    await settle();

    for (final level in [0.5, 0.6, 0.7]) {
      await notifier.setMemberVolume(kitchen.id, level, settle: false);
    }
    await notifier.setMemberVolume(kitchen.id, 0.8);

    final sends = groups.log.where((e) => e.startsWith('setMemberVolume'));
    expect(sends.last, 'setMemberVolume ${kitchen.id} 80');
    expect(sends.length, lessThan(4));
    expect(ref.read(speakerGroupsProvider).volumes[kitchen.id], 80);
  });
}
