import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/platform/volume_keys.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/device_volume_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';
import 'package:jplayer/src/domain/providers/volume_keys_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeKeys implements HardwareVolumeKeys {
  final _presses = StreamController<VolumeKey>.broadcast();
  final captured = <bool>[];

  void press(VolumeKey key) => _presses.add(key);

  @override
  Stream<VolumeKey> get presses => _presses.stream;

  @override
  Future<void> setCapture(bool enabled) async => captured.add(enabled);
}

class _FakeTarget implements PlaybackTarget {
  _FakeTarget({required this.id, required this.kind});

  @override
  final String id;
  @override
  final PlaybackTargetKind kind;

  final applied = <double>[];
  double reported = 0.7;

  @override
  Future<void> setVolume(double level) async => applied.add(level);

  @override
  Future<double?> currentVolume() async => reported;

  @override
  String get name => 'Speaker';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeKeys keys;
  late _FakeTarget speaker;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    keys = _FakeKeys();
    speaker = _FakeTarget(id: 'speaker', kind: PlaybackTargetKind.upnp);
    container = ProviderContainer(
      overrides: [
        remoteRendererProvider.overrideWithValue(null),
        usesSystemVolumeProvider.overrideWithValue(true),
        appSettingsProvider.overrideWith((_) => AppSettingsNotifier(prefs)),
        playbackTargetProvider.overrideWith(
          (_) => PlaybackTargetNotifier(
            _FakeTarget(id: 'phone', kind: PlaybackTargetKind.local),
          ),
        ),
        hardwareVolumeKeysProvider.overrideWithValue(keys),
      ],
    );
    addTearDown(container.dispose);
  });

  const tick = Duration(milliseconds: 1);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('captures the buttons while a speaker plays, frees them for the phone',
      () async {
    container.read(volumeKeysProvider);
    expect(keys.captured, isEmpty);

    container.read(playbackTargetProvider.notifier).select(speaker);
    await settle();
    expect(keys.captured, [true]);

    container.read(playbackTargetProvider.notifier).useLocal();
    await settle();
    expect(keys.captured, [true, false]);
  });

  test('ignores presses while the phone plays locally', () async {
    container.read(volumeKeysProvider);

    keys.press(VolumeKey.up);
    await settle();

    expect(container.read(volumeKeysProvider), isFalse);
  });

  testWidgets('a press steps the speaker volume and shows the hud', (
    tester,
  ) async {
    container.read(volumeKeysProvider);
    container.read(playbackTargetProvider.notifier).select(speaker);
    await tester.pump(tick);
    expect(container.read(deviceVolumeProvider).level, 0.1);
    expect(keys.captured, [true]);

    keys.press(VolumeKey.up);
    await tester.pump(tick);

    expect(container.read(deviceVolumeProvider).level, 0.15);
    expect(speaker.applied.last, 0.15);
    expect(container.read(volumeKeysProvider), isTrue);

    await tester.pump(VolumeKeysNotifier.showFor);
    expect(container.read(volumeKeysProvider), isFalse);
  });

  testWidgets('steps stop at silence and at full', (tester) async {
    container.read(volumeKeysProvider);
    container.read(playbackTargetProvider.notifier).select(speaker);
    await tester.pump(tick);

    keys
      ..press(VolumeKey.down)
      ..press(VolumeKey.down)
      ..press(VolumeKey.down);
    await tester.pump(tick);
    expect(container.read(deviceVolumeProvider).level, 0);

    for (var i = 0; i < 25; i++) {
      keys.press(VolumeKey.up);
    }
    await tester.pump(tick);
    expect(container.read(deviceVolumeProvider).level, 1);
    await tester.pump(VolumeKeysNotifier.showFor);
  });

  testWidgets('a press while muted unmutes one step up from silence', (
    tester,
  ) async {
    container.read(volumeKeysProvider);
    container.read(playbackTargetProvider.notifier).select(speaker);
    await tester.pump(tick);
    await container.read(deviceVolumeProvider.notifier).toggleMute();
    expect(container.read(deviceVolumeProvider).isSilent, isTrue);

    keys.press(VolumeKey.up);
    await tester.pump(tick);

    expect(container.read(deviceVolumeProvider).effectiveLevel, 0.05);
    await tester.pump(VolumeKeysNotifier.showFor);
  });

  testWidgets('remembers the level once the presses stop', (tester) async {
    container.read(volumeKeysProvider);
    container.read(playbackTargetProvider.notifier).select(speaker);
    await tester.pump(tick);

    keys
      ..press(VolumeKey.up)
      ..press(VolumeKey.up);
    await tester.pump(tick);
    expect(
      container.read(appSettingsProvider.notifier).rendererVolume('speaker'),
      isNot(0.2),
    );

    await tester.pump(VolumeKeysNotifier.settleAfter);
    expect(
      container.read(appSettingsProvider.notifier).rendererVolume('speaker'),
      0.2,
    );
    await tester.pump(VolumeKeysNotifier.showFor);
  });

  test('syncFromTarget takes the level the speaker reports', () async {
    container.read(playbackTargetProvider.notifier).select(speaker);
    speaker.reported = 0.6;

    await container.read(volumeProvider.notifier).syncFromTarget();

    expect(container.read(volumeProvider).level, 0.6);
    expect(
      container.read(appSettingsProvider.notifier).rendererVolume('speaker'),
      isNull,
    );
  });
}
