import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/listen_tracker.dart';
import 'package:jplayer/src/core/scrobbling/scrobble_queue.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class _Slot {
  _Slot(this.scrobbler, this.queue);

  final Scrobbler scrobbler;
  final ScrobbleQueue queue;
  ScrobblerAvailability availability = ScrobblerAvailability.disabled;
  Timer? retryTimer;
  Duration retryDelay = ScrobbleHandler._minRetry;
  Future<void>? flushing;

  bool get enabled => availability == ScrobblerAvailability.enabled;

  void cancelRetry() {
    retryTimer?.cancel();
    retryTimer = null;
  }
}

class ScrobbleHandler {
  static const _minRetry = Duration(minutes: 1);
  static const _maxRetry = Duration(minutes: 10);
  static const _callTimeout = Duration(seconds: 60);

  static ProviderContainer? _container;
  static ListenTracker? _tracker;
  static final _slots = <_Slot>[];

  static void initialize(
    ProviderContainer container, {
    required List<Scrobbler> scrobblers,
    ScrobbleQueue Function(Scrobbler scrobbler)? queueFor,
    DateTime Function()? clock,
  }) {
    if (_container != null) return;
    _container = container;
    _tracker = ListenTracker(clock: clock);

    for (final scrobbler in scrobblers) {
      final slot = _Slot(
        scrobbler,
        queueFor?.call(scrobbler) ?? ScrobbleQueue(scrobbler.id),
      );
      _slots.add(slot);
      container.listen(
        scrobbler.availability,
        fireImmediately: true,
        (previous, next) => _onAvailability(slot, previous, next),
      );
    }

    container
      ..listen(playbackProvider, (previous, next) => _onPlayback(next))
      ..listen(isOfflineProvider, (previous, next) {
        if (previous != true || next) return;
        for (final slot in _slots.where((slot) => slot.enabled)) {
          unawaited(_flush(slot));
        }
      });
  }

  @visibleForTesting
  static Future<void> get idle => Future.wait([
    for (final slot in _slots) slot.flushing ?? Future<void>.value(),
  ]);

  @visibleForTesting
  static void reset() {
    for (final slot in _slots) {
      slot.cancelRetry();
    }
    _slots.clear();
    _container = null;
    _tracker = null;
  }

  static bool get _anyEnabled => _slots.any((slot) => slot.enabled);

  static void _onAvailability(
    _Slot slot,
    ScrobblerAvailability? previous,
    ScrobblerAvailability next,
  ) {
    final container = _container;
    final tracker = _tracker;
    if (container == null || tracker == null) return;
    slot.availability = next;

    switch (next) {
      case ScrobblerAvailability.enabled:
        if (previous == ScrobblerAvailability.enabled) return;
        unawaited(_flush(slot));
        final state = container.read(playbackProvider);
        final wasTracking = tracker.current != null;
        _onPlayback(state);
        if (wasTracking && state.status.isPlaying) {
          if (tracker.current case final listen?) {
            unawaited(_sendNowPlaying(slot, listen));
          }
        }
      case ScrobblerAvailability.disabled:
        slot.cancelRetry();
        if (previous != null && previous != ScrobblerAvailability.disabled) {
          unawaited(slot.queue.clear());
        }
        if (!_anyEnabled) tracker.reset();
      case ScrobblerAvailability.suspended:
        slot.cancelRetry();
        if (!_anyEnabled) tracker.reset();
    }
  }

  static void _onPlayback(PlaybackState state) {
    final tracker = _tracker;
    if (tracker == null) return;
    if (!_anyEnabled) {
      tracker.reset();
      return;
    }
    for (final event in tracker.update(state)) {
      for (final slot in _slots.where((slot) => slot.enabled)) {
        switch (event) {
          case NowPlayingEvent():
            unawaited(_sendNowPlaying(slot, event.listen));
          case ListenedEvent():
            unawaited(_enqueue(slot, event.listen));
        }
      }
    }
  }

  static Future<void> _sendNowPlaying(_Slot slot, Listen listen) async {
    if (!slot.enabled) return;
    try {
      await slot.scrobbler.updateNowPlaying(listen).timeout(_callTimeout);
    } on ScrobbleException catch (error) {
      if (error.isUnauthorized) {
        slot.scrobbler.onUnauthorized();
      } else {
        debugPrint(
          '[Scrobble] ${slot.scrobbler.id} now playing failed: $error',
        );
      }
    } on Object catch (error) {
      debugPrint('[Scrobble] ${slot.scrobbler.id} now playing failed: $error');
    }
  }

  static Future<void> _enqueue(_Slot slot, Listen listen) async {
    if (!slot.enabled) return;
    await slot.queue.add(listen);
    await _flush(slot);
  }

  static Future<void> _flush(_Slot slot) async {
    for (
      var inFlight = slot.flushing;
      inFlight != null;
      inFlight = slot.flushing
    ) {
      await inFlight;
    }
    final run = slot.flushing = _runFlush(slot);
    try {
      await run;
    } finally {
      if (identical(slot.flushing, run)) slot.flushing = null;
    }
  }

  static Future<void> _runFlush(_Slot slot) async {
    slot.cancelRetry();
    final scrobbler = slot.scrobbler;
    while (true) {
      if (!slot.enabled) return;
      final pending = await slot.queue.pending();
      if (pending.isEmpty) {
        slot.retryDelay = _minRetry;
        return;
      }
      final batch = pending.take(scrobbler.maxBatchSize).toList();
      try {
        await scrobbler.scrobble(batch).timeout(_callTimeout);
        await slot.queue.remove(batch);
        slot.retryDelay = _minRetry;
      } on ScrobbleException catch (error) {
        if (error.isUnauthorized) {
          scrobbler.onUnauthorized();
          return;
        }
        if (error.isRejected) {
          debugPrint(
            '[Scrobble] ${scrobbler.id} dropping ${batch.length} rejected listen(s): $error',
          );
          await slot.queue.remove(batch);
          continue;
        }
        debugPrint('[Scrobble] ${scrobbler.id} submit failed: $error');
        _scheduleRetry(slot, error.retryAfter);
        return;
      } on Object catch (error) {
        debugPrint('[Scrobble] ${scrobbler.id} submit failed: $error');
        _scheduleRetry(slot, null);
        return;
      }
    }
  }

  static void _scheduleRetry(_Slot slot, Duration? retryAfter) {
    slot.cancelRetry();
    final delay = retryAfter ?? slot.retryDelay;
    final doubled = slot.retryDelay * 2;
    slot
      ..retryDelay = doubled > _maxRetry ? _maxRetry : doubled
      ..retryTimer = Timer(delay, () {
        slot.retryTimer = null;
        unawaited(_flush(slot));
      });
  }
}
