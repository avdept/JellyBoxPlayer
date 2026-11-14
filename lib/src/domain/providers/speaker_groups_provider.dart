import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:jplayer/src/providers/diagnostics_provider.dart';
import 'package:optional_features/upnp_quirks.dart';

class SpeakerGroupsState {
  const SpeakerGroupsState({
    this.topology = SpeakerTopology.empty,
    this.volumes = const {},
    this.busy = const {},
    this.loaded = false,
  });

  final SpeakerTopology topology;
  final Map<String, int> volumes;
  final Set<String> busy;
  final bool loaded;

  SpeakerGroupsState copyWith({
    SpeakerTopology? topology,
    Map<String, int>? volumes,
    Set<String>? busy,
    bool? loaded,
  }) => SpeakerGroupsState(
    topology: topology ?? this.topology,
    volumes: volumes ?? this.volumes,
    busy: busy ?? this.busy,
    loaded: loaded ?? this.loaded,
  );
}

class SpeakerGroupsNotifier extends StateNotifier<SpeakerGroupsState> {
  SpeakerGroupsNotifier(
    this._ref, {
    this.pickerInterval = const Duration(seconds: 5),
    this.backgroundInterval = const Duration(seconds: 15),
    this.settleTimeout = const Duration(seconds: 6),
    this.settlePollInterval = const Duration(seconds: 1),
    this.volumeSendInterval = const Duration(milliseconds: 150),
    this.volumeHoldFor = const Duration(seconds: 2),
    Diagnostics? diagnostics,
  }) : _diagnostics = diagnostics ?? _ref.read(diagnosticsProvider),
       super(const SpeakerGroupsState()) {
    _ref.listen<List<UpnpRenderer>>(
      upnpRenderersProvider.select((discovery) => discovery.renderers),
      (_, renderers) => _adopt(renderers),
      fireImmediately: true,
    );
    _ref.listen<PlaybackTarget>(
      playbackTargetProvider,
      (_, target) => _targetChanged(target),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final Duration pickerInterval;
  final Duration backgroundInterval;
  final Duration settleTimeout;
  final Duration settlePollInterval;
  final Duration volumeSendInterval;
  final Duration volumeHoldFor;
  final Diagnostics _diagnostics;

  SpeakerGroups? _driver;
  String? _driverId;
  UpnpPlaybackTarget? _active;
  var _watchers = 0;
  Timer? _poll;
  Future<void>? _refreshing;
  final _described = <String>{};
  final _pendingVolumes = <String, int>{};
  final _volumeTimers = <String, Timer>{};
  final _holdUntil = <String, DateTime>{};

  bool get available => _driver != null;

  String? get activeCoordinatorId {
    final active = _active;
    if (active == null) return null;
    return state.topology.coordinatorOf(active.id) ?? active.id;
  }

  SpeakerGroup? get activeGroup {
    final active = _active;
    return active == null ? null : state.topology.groupOf(active.id);
  }

  void watch() {
    _watchers++;
    if (_watchers == 1) {
      unawaited(refresh());
      _schedule();
    }
  }

  void unwatch() {
    _watchers = (_watchers - 1).clamp(0, 1 << 30);
    if (_watchers == 0) _schedule();
  }

  Future<void> refresh() {
    final running = _refreshing;
    if (running != null) return running;
    final work = _refresh().whenComplete(() => _refreshing = null);
    _refreshing = work;
    return work;
  }

  Future<bool> join(String memberId) async {
    if (!state.loaded) await refresh();
    final coordinatorId = activeCoordinatorId;
    final driver = _driver;
    if (coordinatorId == null || driver == null || memberId == coordinatorId) {
      return false;
    }
    return _change(
      memberId,
      'join',
      () => driver.join(memberId, coordinatorId),
      settled: (topology) => topology.coordinatorOf(memberId) == coordinatorId,
    );
  }

  Future<bool> leave(String memberId) async {
    if (!state.loaded) await refresh();
    final driver = _driver;
    if (driver == null || memberId == activeCoordinatorId) return false;
    return _change(
      memberId,
      'leave',
      () => driver.leave(memberId),
      settled: (topology) => topology.isCoordinator(memberId),
    );
  }

  Future<void> setMemberVolume(
    String memberId,
    double level, {
    bool settle = true,
  }) async {
    final volume = (level.clamp(0.0, 1.0) * 100).round();
    _holdUntil[memberId] = DateTime.now().add(volumeHoldFor);
    state = state.copyWith(volumes: {...state.volumes, memberId: volume});
    _pendingVolumes[memberId] = volume;

    if (settle) {
      _volumeTimers.remove(memberId)?.cancel();
      await _flushVolume(memberId);
      return;
    }
    _volumeTimers[memberId] ??= Timer(volumeSendInterval, () {
      _volumeTimers.remove(memberId);
      unawaited(_flushVolume(memberId));
    });
  }

  Future<void> _flushVolume(String memberId) async {
    final driver = _driver;
    final volume = _pendingVolumes.remove(memberId);
    if (driver == null || volume == null || !mounted) return;
    try {
      await driver.setMemberVolume(memberId, volume);
    } on Object catch (error) {
      _diagnostics.trail(
        'speaker volume failed: $error',
        category: 'upnp',
        data: {'error': '$error'},
      );
    }
  }

  Future<bool> _change(
    String memberId,
    String what,
    Future<void> Function() action, {
    required bool Function(SpeakerTopology topology) settled,
  }) async {
    if (state.busy.contains(memberId)) return false;
    state = state.copyWith(busy: {...state.busy, memberId});
    try {
      await action();
      final ok = await _settle(settled);
      if (!ok) {
        _diagnostics.trail(
          'speaker $what did not settle',
          category: 'upnp',
          data: {'member': memberId},
        );
      }
      return ok;
    } on Object catch (error, stackTrace) {
      unawaited(
        _diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.group.$what',
        ),
      );
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(busy: {...state.busy}..remove(memberId));
      }
    }
  }

  Future<bool> _settle(bool Function(SpeakerTopology topology) settled) async {
    final deadline = DateTime.now().add(settleTimeout);
    while (mounted) {
      await refresh();
      if (!mounted) return false;
      if (settled(state.topology)) return true;
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(settlePollInterval);
    }
    return false;
  }

  Future<void> _refresh() async {
    final driver = _driver;
    if (driver == null) return;
    final SpeakerTopology topology;
    try {
      topology = await driver.topology();
    } on Object catch (error) {
      _diagnostics.trail(
        'speaker topology failed: $error',
        category: 'upnp',
        data: {'error': '$error'},
      );
      return;
    }
    if (!mounted) return;

    final volumes = Map<String, int>.of(state.volumes);
    final now = DateTime.now();
    await Future.wait([
      for (final member in topology.members)
        if (member.visible && !(_holdUntil[member.id]?.isAfter(now) ?? false))
          driver
              .memberVolume(member.id)
              .then((volume) {
                if (volume != null) volumes[member.id] = volume;
              })
              .catchError((Object _) {}),
    ]);
    if (!mounted) return;

    state = state.copyWith(
      topology: topology,
      volumes: volumes,
      loaded: true,
    );
    _syncActive();
    unawaited(_describeMissing(topology));
  }

  Future<void> _describeMissing(SpeakerTopology topology) async {
    final renderers = _ref.read(upnpRenderersProvider.notifier);
    final known = {
      for (final renderer in _ref.read(upnpRenderersProvider).renderers)
        renderer.id,
    };
    final missing = [
      for (final member in topology.members)
        if (member.visible &&
            !known.contains(member.id) &&
            _described.add(member.id))
          member,
    ];
    if (missing.isEmpty) return;
    final controlPoint = _ref.read(upnpControlPointProvider);
    await Future.wait([
      for (final member in missing)
        controlPoint
            .describe(member.location)
            .then((renderer) {
              if (renderer != null && mounted) renderers.adopt(renderer);
            })
            .catchError((Object _) {}),
    ]);
  }

  void _adopt(List<UpnpRenderer> renderers) {
    final active = _active;
    final candidates = [
      if (active != null && active.renderer.isGroupable) active.renderer,
      for (final renderer in renderers)
        if (renderer.isGroupable) renderer,
    ];
    if (candidates.isEmpty) return;
    final chosen = candidates.firstWhere(
      (renderer) => renderer.id == _driverId,
      orElse: () => candidates.first,
    );
    final changed = _driverId != chosen.id;
    if (changed) _described.clear();
    _driver = chosen.groups;
    _driverId = chosen.id;
    if (changed && (_watchers > 0 || active != null)) {
      unawaited(refresh());
      _schedule();
    }
  }

  void _targetChanged(PlaybackTarget target) {
    final previous = _active;
    _active = target is UpnpPlaybackTarget && target.renderer.isGroupable
        ? target
        : null;
    if (_active?.id == previous?.id) return;
    previous?.playsToGroup = false;
    if (_active != null) {
      _adopt(_ref.read(upnpRenderersProvider).renderers);
      unawaited(refresh());
    }
    _schedule();
  }

  void _syncActive() {
    final active = _active;
    if (active == null) return;
    active.playsToGroup =
        state.topology.groupOf(active.id)?.playsTogether ?? false;
  }

  void _schedule() {
    _poll?.cancel();
    _poll = null;
    if (_driver == null) return;
    final interval = _watchers > 0
        ? pickerInterval
        : _active != null
        ? backgroundInterval
        : null;
    if (interval == null) return;
    _poll = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final timer in _volumeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}

final speakerGroupsProvider =
    StateNotifierProvider<SpeakerGroupsNotifier, SpeakerGroupsState>(
      SpeakerGroupsNotifier.new,
    );
