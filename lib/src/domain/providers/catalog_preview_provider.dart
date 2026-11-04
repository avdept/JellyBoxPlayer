import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/catalog.dart';
import 'package:jplayer/src/core/catalog/preview_audio.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

abstract class PreviewHost {
  bool get isPlaying;

  Future<void> pause();

  Future<void> resume();
}

class CatalogPreviewState {
  const CatalogPreviewState({this.track, this.loading = false});

  final CatalogKey? track;
  final bool loading;
}

class CatalogPreviewNotifier extends StateNotifier<CatalogPreviewState> {
  CatalogPreviewNotifier({
    required PreviewAudio audio,
    required PreviewHost host,
    required CatalogSource? Function(String sourceId) sourceFor,
  }) : _audio = audio,
       _host = host,
       _sourceFor = sourceFor,
       super(const CatalogPreviewState());

  final PreviewAudio _audio;
  final PreviewHost _host;
  final CatalogSource? Function(String sourceId) _sourceFor;
  var _request = 0;
  var _resumeHost = false;

  ValueListenable<double> get progress => _audio.progress;

  Future<void> toggle(CatalogTrack track) async {
    if (state.track == track.key) return stop();

    final request = ++_request;
    await _audio.stop();
    state = CatalogPreviewState(track: track.key, loading: true);
    if (_host.isPlaying) {
      _resumeHost = true;
      await _host.pause();
    }

    Uri? url;
    try {
      url = await _sourceFor(track.source)?.previewUrl(track.id);
    } on Object {
      url = null;
    }
    if (request != _request) return;
    if (url == null) return stop();

    try {
      await _audio.play(
        url,
        onDone: () {
          if (request == _request) unawaited(stop());
        },
      );
    } on Object {
      if (request == _request) await stop();
      return;
    }
    if (request != _request) return;
    state = CatalogPreviewState(track: track.key);
  }

  Future<void> stop({bool resumeHost = true}) async {
    _request++;
    state = const CatalogPreviewState();
    await _audio.stop();
    final resume = resumeHost && _resumeHost;
    _resumeHost = false;
    if (resume) await _host.resume();
  }

  void onHostStarted() {
    if (state.track == null) return;
    unawaited(stop(resumeHost: false));
  }

  @override
  void dispose() {
    _request++;
    _audio.dispose();
    if (_resumeHost) unawaited(_host.resume());
    super.dispose();
  }
}

class _PlaybackPreviewHost implements PreviewHost {
  _PlaybackPreviewHost(this._ref);

  final Ref _ref;

  @override
  bool get isPlaying => switch (_ref.read(playbackProvider).status) {
    PlaybackStatus.playing || PlaybackStatus.buffering => true,
    _ => false,
  };

  @override
  Future<void> pause() => _ref.read(playbackProvider.notifier).pause();

  @override
  Future<void> resume() => _ref.read(playbackProvider.notifier).resume();
}

final AutoDisposeStateNotifierProvider<
  CatalogPreviewNotifier,
  CatalogPreviewState
>
catalogPreviewProvider =
    StateNotifierProvider.autoDispose<
      CatalogPreviewNotifier,
      CatalogPreviewState
    >((ref) {
      final notifier = CatalogPreviewNotifier(
        audio: VideoPlayerPreviewAudio(),
        host: _PlaybackPreviewHost(ref),
        sourceFor: (id) => ref.read(catalogSourceProvider(id)),
      );
      ref.listen(
        playbackProvider.select((state) => state.status.isPlaying),
        (previous, playing) {
          if (playing) notifier.onHostStarted();
        },
      );
      return notifier;
    });
