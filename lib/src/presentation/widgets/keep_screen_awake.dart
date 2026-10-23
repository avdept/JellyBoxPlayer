import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/battery_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class KeepScreenAwake extends ConsumerStatefulWidget {
  const KeepScreenAwake({this.force = false, super.key});

  final bool force;

  @override
  ConsumerState<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends ConsumerState<KeepScreenAwake> {
  static int _holders = 0;

  bool _held = false;

  void _hold({required bool awake}) {
    if (_held == awake) return;
    _held = awake;
    if (awake) {
      if (_holders++ == 0) unawaited(WakelockPlus.enable());
    } else {
      if (--_holders == 0) unawaited(WakelockPlus.disable());
    }
  }

  @override
  void dispose() {
    _hold(awake: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wanted =
        widget.force ||
        switch (ref.watch(keepScreenOnProvider)) {
          KeepScreenOn.never => false,
          KeepScreenOn.charging => ref.watch(isChargingProvider),
          KeepScreenOn.always => true,
        };
    _hold(awake: wanted);
    return const SizedBox.shrink();
  }
}
