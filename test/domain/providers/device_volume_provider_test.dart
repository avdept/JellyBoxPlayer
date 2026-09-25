import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/device_volume_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/jellybox_cloud.dart';

class FakeCloudNotifier extends StateNotifier<CloudState>
    with Mock
    implements CloudNotifier {
  FakeCloudNotifier() : super(const CloudState());

  final sent = <Object?>[];

  @override
  Future<void> sendCommand(PlayerCommand command, {Object? value}) async =>
      sent.add(value);
}

class FakeSystemVolume implements SystemVolume {
  final _changes = StreamController<double>.broadcast();
  final written = <double>[];

  void press(double level) => _changes.add(level);

  @override
  Stream<double> get changes => _changes.stream;

  @override
  Future<void> write(double level) async => written.add(level);
}

class _LocalTarget implements PlaybackTarget {
  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _phone = ConductorDevice(
  id: 'phone',
  name: 'Phone',
  platform: 'android',
  isRenderer: true,
);

void main() {
  group('another device playing', () {
    late FakeCloudNotifier cloud;
    late StateController<RemoteSession?> session;
    late ProviderContainer container;

    RemoteSession reporting(double volume) => RemoteSession(
      doc: SessionDoc(itemIds: const ['a'], volume: volume),
      ageMs: 0,
      receivedAt: DateTime(2026),
    );

    setUp(() {
      cloud = FakeCloudNotifier();
      final sessionState = StateProvider<RemoteSession?>(
        (_) => reporting(0.8),
      );
      container = ProviderContainer(
        overrides: [
          cloudProvider.overrideWith((_) => cloud),
          remoteRendererProvider.overrideWithValue(_phone),
          remoteSessionProvider.overrideWith(
            (ref) => ref.watch(sessionState),
          ),
        ],
      );
      session = container.read(sessionState.notifier);
      addTearDown(container.dispose);
    });

    test('shows the level the playing device reports', () {
      expect(container.read(volumeScopeProvider), VolumeScope.remote);
      expect(container.read(deviceVolumeProvider).level, 0.8);

      session.state = reporting(0.3);

      expect(container.read(deviceVolumeProvider).level, 0.3);
    });

    testWidgets('sends one command per interval while dragging', (
      tester,
    ) async {
      final volume = container.read(deviceVolumeProvider.notifier);

      unawaited(volume.setLevel(0.6, settle: false));
      unawaited(volume.setLevel(0.5, settle: false));
      unawaited(volume.setLevel(0.4, settle: false));
      await tester.pump(DeviceVolumeNotifier.sendInterval);

      expect(cloud.sent, [0.4]);
      await tester.pump(DeviceVolumeNotifier.holdFor);
    });

    testWidgets('holds the dragged level until the device catches up', (
      tester,
    ) async {
      final volume = container.read(deviceVolumeProvider.notifier);

      await volume.setLevel(0.2);
      session.state = reporting(0.8);
      expect(container.read(deviceVolumeProvider).level, 0.2);

      session.state = reporting(0.25);
      await tester.pump(DeviceVolumeNotifier.holdFor);
      expect(container.read(deviceVolumeProvider).level, 0.25);
    });

    test('mute sends zero, unmute restores the last level', () async {
      final volume = container.read(deviceVolumeProvider.notifier);

      await volume.toggleMute();
      await volume.toggleMute();

      expect(cloud.sent, [0.0, 0.8]);
    });
  });

  group('this phone playing', () {
    late FakeSystemVolume system;
    late ProviderContainer container;

    setUp(() {
      system = FakeSystemVolume();
      container = ProviderContainer(
        overrides: [
          remoteRendererProvider.overrideWithValue(null),
          usesSystemVolumeProvider.overrideWithValue(true),
          playbackTargetProvider.overrideWith(
            (_) => PlaybackTargetNotifier(_LocalTarget()),
          ),
          systemVolumeSourceProvider.overrideWithValue(system),
        ],
      );
      addTearDown(container.dispose);
    });

    test('sets the system volume, the one the buttons change', () async {
      expect(container.read(volumeScopeProvider), VolumeScope.system);

      await container.read(deviceVolumeProvider.notifier).setLevel(0.3);

      expect(system.written, [0.3]);
    });

    test('follows the hardware buttons', () async {
      container.read(deviceVolumeProvider);

      system.press(0.7);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(deviceVolumeProvider).level, 0.7);
    });
  });
}
