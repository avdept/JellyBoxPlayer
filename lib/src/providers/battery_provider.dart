import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AutoDisposeProvider<Battery> batteryProvider =
    Provider.autoDispose<Battery>((ref) => Battery());

final AutoDisposeStreamProvider<BatteryState> batteryStateProvider =
    StreamProvider.autoDispose<BatteryState>((
      ref,
    ) async* {
      final battery = ref.watch(batteryProvider);
      yield await battery.batteryState.onError<Object>(
        (_, _) => BatteryState.unknown,
      );
      yield* battery.onBatteryStateChanged;
    });

final AutoDisposeProvider<bool> isChargingProvider = Provider.autoDispose<bool>(
  (ref) {
    final state = ref.watch(batteryStateProvider).valueOrNull;
    return state == BatteryState.charging || state == BatteryState.full;
  },
);
