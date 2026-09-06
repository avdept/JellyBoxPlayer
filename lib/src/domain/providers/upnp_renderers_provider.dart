import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';

class UpnpDiscoveryState {
  const UpnpDiscoveryState({this.renderers = const [], this.scanning = false});

  final List<UpnpRenderer> renderers;
  final bool scanning;
}

class UpnpRenderersNotifier extends StateNotifier<UpnpDiscoveryState> {
  UpnpRenderersNotifier(this._controlPoint) : super(const UpnpDiscoveryState());

  final UpnpControlPoint _controlPoint;
  StreamSubscription<UpnpRenderer>? _subscription;

  Future<void> refresh({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await _subscription?.cancel();
    if (!mounted) return;

    final found = <String, UpnpRenderer>{
      for (final renderer in state.renderers) renderer.id: renderer,
    };
    state = UpnpDiscoveryState(renderers: state.renderers, scanning: true);

    final done = Completer<void>();
    void finish() {
      if (done.isCompleted) return;
      if (mounted) {
        state = UpnpDiscoveryState(renderers: _sorted(found.values));
      }
      done.complete();
    }

    _subscription = _controlPoint
        .discoverRenderers(timeout: timeout)
        .listen(
          (renderer) {
            found[renderer.id] = renderer;
            if (!mounted) return;
            state = UpnpDiscoveryState(
              renderers: _sorted(found.values),
              scanning: true,
            );
          },
          onDone: finish,
          onError: (Object _) => finish(),
          cancelOnError: true,
        );

    await done.future;
  }

  List<UpnpRenderer> _sorted(Iterable<UpnpRenderer> renderers) =>
      renderers.toList()..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.host.compareTo(b.host);
      });

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final upnpControlPointProvider = Provider<UpnpControlPoint>(
  (ref) => UpnpControlPoint(),
);

final upnpRenderersProvider =
    StateNotifierProvider<UpnpRenderersNotifier, UpnpDiscoveryState>(
      (ref) => UpnpRenderersNotifier(ref.watch(upnpControlPointProvider)),
    );
