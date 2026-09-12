import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/battery_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class KeepScreenAwake extends ConsumerStatefulWidget {
  const KeepScreenAwake({super.key});

  @override
  ConsumerState<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends ConsumerState<KeepScreenAwake> {
  bool _held = false;

  void _hold({required bool awake}) {
    if (_held == awake) return;
    _held = awake;
    unawaited(awake ? WakelockPlus.enable() : WakelockPlus.disable());
  }

  @override
  void dispose() {
    if (_held) unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wanted = switch (ref.watch(keepScreenOnProvider)) {
      KeepScreenOn.never => false,
      KeepScreenOn.charging => ref.watch(isChargingProvider),
      KeepScreenOn.always => true,
    };
    _hold(awake: wanted);
    return const SizedBox.shrink();
  }
}
