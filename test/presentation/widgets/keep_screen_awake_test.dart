import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/presentation/widgets/keep_screen_awake.dart';
import 'package:jplayer/src/providers/battery_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import '../../provider_container.dart';

class FakeWakelock extends WakelockPlusPlatformInterface
    with MockPlatformInterfaceMixin {
  final toggles = <bool>[];
  var _enabled = false;

  @override
  Future<void> toggle({required bool enable}) async {
    toggles.add(enable);
    _enabled = enable;
  }

  @override
  Future<bool> get enabled async => _enabled;
}

Iterable<ProviderBase<Object?>> _liveProviders(ProviderContainer container) =>
    container.getAllProviderElements().map((element) => element.origin);

void main() {
  late FakeWakelock wakelock;
  late List<bool> toggles;

  setUp(() {
    wakelock = FakeWakelock();
    toggles = wakelock.toggles;
    wakelockPlusPlatformInstance = wakelock;
  });

  Future<void> pumpAwake(
    WidgetTester tester, {
    required KeepScreenOn mode,
    required BatteryState battery,
  }) async {
    final container = createProviderContainer(
      overrides: [
        keepScreenOnProvider.overrideWithValue(mode),
        batteryStateProvider.overrideWith((_) => Stream.value(battery)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KeepScreenAwake()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('KeepScreenAwake', () {
    testWidgets('- holds the screen awake while charging', (tester) async {
      await pumpAwake(
        tester,
        mode: KeepScreenOn.charging,
        battery: BatteryState.charging,
      );

      expect(toggles, [true]);
    });

    testWidgets('- stays out of the way on battery', (tester) async {
      await pumpAwake(
        tester,
        mode: KeepScreenOn.charging,
        battery: BatteryState.discharging,
      );

      expect(toggles, isEmpty);
    });

    testWidgets('- holds the screen awake on battery when set to always', (
      tester,
    ) async {
      await pumpAwake(
        tester,
        mode: KeepScreenOn.always,
        battery: BatteryState.discharging,
      );

      expect(toggles, [true]);
    });

    testWidgets('- does nothing when set to never', (tester) async {
      await pumpAwake(
        tester,
        mode: KeepScreenOn.never,
        battery: BatteryState.charging,
      );

      expect(toggles, isEmpty);
    });

    testWidgets('- only reads the battery while it is on screen', (
      tester,
    ) async {
      final container = createProviderContainer(
        overrides: [
          keepScreenOnProvider.overrideWithValue(KeepScreenOn.charging),
          batteryStateProvider.overrideWith(
            (_) => Stream.value(BatteryState.charging),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KeepScreenAwake()),
        ),
      );
      await tester.pumpAndSettle();
      expect(_liveProviders(container), contains(batteryStateProvider));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(_liveProviders(container), isNot(contains(batteryStateProvider)));
    });

    testWidgets('- never reads the battery unless the mode asks for it', (
      tester,
    ) async {
      final container = createProviderContainer(
        overrides: [
          keepScreenOnProvider.overrideWithValue(KeepScreenOn.always),
          batteryStateProvider.overrideWith(
            (_) => Stream.value(BatteryState.charging),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KeepScreenAwake()),
        ),
      );
      await tester.pumpAndSettle();

      expect(toggles, [true]);
      expect(_liveProviders(container), isNot(contains(batteryStateProvider)));
    });

    testWidgets('- releases the screen when it goes away', (tester) async {
      await pumpAwake(
        tester,
        mode: KeepScreenOn.charging,
        battery: BatteryState.charging,
      );
      expect(toggles, [true]);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(toggles, [true, false]);
    });
  });
}
