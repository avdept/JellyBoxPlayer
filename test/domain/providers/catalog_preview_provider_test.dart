import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optional_features/catalog.dart';
import 'package:jplayer/src/core/catalog/preview_audio.dart';
import 'package:jplayer/src/domain/providers/catalog_preview_provider.dart';

class _FakeAudio implements PreviewAudio {
  final played = <Uri>[];
  int stops = 0;
  VoidCallback? onDone;
  Exception? failWith;

  @override
  final ValueNotifier<double> progress = ValueNotifier(0);

  @override
  Future<void> play(Uri url, {required VoidCallback onDone}) async {
    if (failWith case final error?) throw error;
    played.add(url);
    this.onDone = onDone;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  void dispose() {}
}

class _FakeHost implements PreviewHost {
  _FakeHost({this.isPlaying = false});

  @override
  bool isPlaying;
  int pauses = 0;
  int resumes = 0;

  @override
  Future<void> pause() async {
    pauses++;
    isPlaying = false;
  }

  @override
  Future<void> resume() async {
    resumes++;
    isPlaying = true;
  }
}

class _FakeSource implements CatalogSource {
  final urls = <String, Uri?>{};
  final lookups = <String>[];
  Completer<Uri?>? pending;

  @override
  String get id => 'test';

  @override
  CatalogBrand get brand => const CatalogBrand(
    name: 'Test',
    color: 0xFFFFFFFF,
    logoSvg: '<svg/>',
    description: '',
  );

  @override
  Future<Uri?> previewUrl(String trackId) async {
    lookups.add(trackId);
    final gate = pending;
    if (gate != null) return gate.future;
    return urls[trackId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CatalogTrack _track(String id) => CatalogTrack(
  source: 'test',
  id: id,
  title: 'Song $id',
  duration: const Duration(minutes: 3),
  hasPreview: true,
);

void main() {
  late _FakeAudio audio;
  late _FakeHost host;
  late _FakeSource source;
  late CatalogPreviewNotifier notifier;

  void build({bool hostPlaying = false}) {
    audio = _FakeAudio();
    host = _FakeHost(isPlaying: hostPlaying);
    source = _FakeSource()
      ..urls['1'] = Uri.parse('https://cdn/1.mp3')
      ..urls['2'] = Uri.parse('https://cdn/2.mp3');
    notifier = CatalogPreviewNotifier(
      audio: audio,
      host: host,
      sourceFor: (id) => id == source.id ? source : null,
    );
  }

  test('pauses the music, plays the preview, then resumes the music', () async {
    build(hostPlaying: true);

    await notifier.toggle(_track('1'));

    expect(host.pauses, 1);
    expect(audio.played, [Uri.parse('https://cdn/1.mp3')]);
    expect(notifier.state.track, _track('1').key);
    expect(notifier.state.loading, isFalse);

    audio.onDone!();
    await pumpEventQueue();

    expect(notifier.state.track, isNull);
    expect(host.resumes, 1);
  });

  test('does not start music that was not playing', () async {
    build();

    await notifier.toggle(_track('1'));
    await notifier.stop();

    expect(host.pauses, 0);
    expect(host.resumes, 0);
  });

  test('tapping the playing preview again stops it', () async {
    build(hostPlaying: true);

    await notifier.toggle(_track('1'));
    await notifier.toggle(_track('1'));

    expect(notifier.state.track, isNull);
    expect(host.resumes, 1);
  });

  test(
    'switching previews keeps the music paused until the last one ends',
    () async {
      build(hostPlaying: true);

      await notifier.toggle(_track('1'));
      await notifier.toggle(_track('2'));

      expect(notifier.state.track, _track('2').key);
      expect(host.pauses, 1);
      expect(host.resumes, 0);

      audio.onDone!();
      await pumpEventQueue();
      expect(host.resumes, 1);
    },
  );

  test('fetches a fresh link on every play', () async {
    build();

    await notifier.toggle(_track('1'));
    await notifier.stop();
    await notifier.toggle(_track('1'));

    expect(source.lookups, ['1', '1']);
  });

  test('a finished earlier preview does not stop the current one', () async {
    build();

    await notifier.toggle(_track('1'));
    final staleDone = audio.onDone!;
    await notifier.toggle(_track('2'));
    staleDone();
    await pumpEventQueue();

    expect(notifier.state.track, _track('2').key);
  });

  test('a slow lookup overtaken by another tap is dropped', () async {
    build();
    final slow = Completer<Uri?>();
    source.pending = slow;

    final first = notifier.toggle(_track('1'));
    await pumpEventQueue();
    expect(notifier.state.loading, isTrue);

    source.pending = null;
    await notifier.toggle(_track('2'));
    slow.complete(Uri.parse('https://cdn/1.mp3'));
    await first;

    expect(audio.played, [Uri.parse('https://cdn/2.mp3')]);
    expect(notifier.state.track, _track('2').key);
  });

  test('a missing preview or a player error resumes the music', () async {
    build(hostPlaying: true);
    source.urls['1'] = null;

    await notifier.toggle(_track('1'));
    expect(notifier.state.track, isNull);
    expect(host.resumes, 1);

    audio.failWith = Exception('cannot open');
    await notifier.toggle(_track('2'));
    expect(notifier.state.track, isNull);
    expect(host.resumes, 2);
  });

  test(
    'starting the music yourself ends the preview without a second resume',
    () async {
      build(hostPlaying: true);

      await notifier.toggle(_track('1'));
      host.isPlaying = true;
      notifier.onHostStarted();
      await pumpEventQueue();

      expect(notifier.state.track, isNull);
      expect(host.resumes, 0);
    },
  );

  test('leaving the page resumes music the preview paused', () async {
    build(hostPlaying: true);

    await notifier.toggle(_track('1'));
    notifier.dispose();
    await pumpEventQueue();

    expect(host.resumes, 1);
  });
}
