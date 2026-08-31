import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum HandoffStrategy {
  wholeQueue('Whole queue', 'Resolves every track before the first note'),

  trackFirst('Track first', 'Loads one track, starts, appends the rest after');

  const HandoffStrategy(this.label, this.blurb);

  final String label;
  final String blurb;
}

class HandoffSample {
  const HandoffSample({
    required this.resolveUs,
    required this.buildUs,
    required this.loadUs,
    required this.startUs,
    required this.platformAdvanceUs,
    required this.transcoded,
    required this.queueLength,
  });

  final int resolveUs;

  final int buildUs;

  final int loadUs;

  final int startUs;

  final int platformAdvanceUs;

  final bool transcoded;
  final int queueLength;

  int get readyUs => resolveUs + buildUs + loadUs;

  Map<String, Object?> toJson() => {
    'resolve_us': resolveUs,
    'build_us': buildUs,
    'load_us': loadUs,
    'start_us': startUs,
    'platform_advance_us': platformAdvanceUs,
    'ready_us': readyUs,
    'transcoded': transcoded,
    'queue_length': queueLength,
  };
}

class HandoffBenchPage extends ConsumerStatefulWidget {
  const HandoffBenchPage({required this.album, super.key});

  final LibraryItem album;

  static Route<void> route(LibraryItem album) => MaterialPageRoute(
    builder: (_) => HandoffBenchPage(album: album),
  );

  @override
  ConsumerState<HandoffBenchPage> createState() => _HandoffBenchPageState();
}

class _HandoffBenchPageState extends ConsumerState<HandoffBenchPage> {
  static const _phaseTimeout = Duration(seconds: 20);

  HandoffStrategy _strategy = HandoffStrategy.wholeQueue;
  var _seekSeconds = 90;
  var _iterations = 10;
  var _trackIndex = 0;
  var _forceTranscode = false;
  var _startAtHandoff = false;

  final _samples = <HandoffSample>[];
  final _trace = <String>[];
  var _running = false;
  String? _error;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Handoff bench')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.album.name,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            widget.album.albumArtist ?? '',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _numberField(
            label: 'Handoff position (seconds)',
            value: _seekSeconds,
            onChanged: (v) => setState(() => _seekSeconds = v),
          ),
          _numberField(
            label: 'Track index in album',
            value: _trackIndex,
            onChanged: (v) => setState(() => _trackIndex = v),
          ),
          _numberField(
            label: 'Iterations',
            value: _iterations,
            onChanged: (v) => setState(() => _iterations = v),
          ),
          CheckboxListTile(
            value: _forceTranscode,
            onChanged: _running
                ? null
                : (v) => setState(() => _forceTranscode = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Force transcode'),
            subtitle: const Text(
              'Takes the HLS path even when the source would direct-play, so '
              'the server has to spawn ffmpeg at the handoff offset. This is '
              'the risky cell — desktop never reaches it on its own.',
            ),
          ),
          CheckboxListTile(
            value: _startAtHandoff,
            onChanged: (_running || !_forceTranscode)
                ? null
                : (v) => setState(() => _startAtHandoff = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Start transcode at handoff point'),
            subtitle: const Text(
              'Sends StartTimeTicks so ffmpeg encodes FROM the handoff point '
              'instead of from zero. The stream then starts at 0, so the '
              'player does not seek. Transcode runs only.',
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<HandoffStrategy>(
            segments: [
              for (final strategy in HandoffStrategy.values)
                ButtonSegment(value: strategy, label: Text(strategy.label)),
            ],
            selected: {_strategy},
            onSelectionChanged: _running
                ? null
                : (selection) => setState(() => _strategy = selection.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_strategy.blurb, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _running ? null : _run,
            child: Text(_running ? _status : 'Run'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _running ? null : _runTrace,
            child: const Text('Trace one run (5s of raw events)'),
          ),
          if (_trace.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Raw playback events', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: SelectableText(
                _trace.join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Roboto Mono'],
                ),
              ),
            ),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_samples.isNotEmpty) ...[
            const SizedBox(height: 24),
            _summary(theme),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyJson,
              icon: const Icon(Icons.copy),
              label: const Text('Copy JSON'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextFormField(
      initialValue: '$value',
      enabled: !_running,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (raw) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed >= 0) onChanged(parsed);
      },
    ),
  );

  Widget _summary(ThemeData theme) {
    final usable = _samples;
    if (usable.isEmpty) return const SizedBox.shrink();

    List<int> sorted(int Function(HandoffSample) pick) =>
        usable.map(pick).toList()..sort();

    final advances =
        usable.map((s) => s.platformAdvanceUs).where((v) => v >= 0).toList()
          ..sort();

    final rows = <(String, List<int>)>[
      ('resolve', sorted((s) => s.resolveUs)),
      ('build', sorted((s) => s.buildUs)),
      ('load', sorted((s) => s.loadUs)),
      ('READY', sorted((s) => s.readyUs)),
      ('start', sorted((s) => s.startUs)),
      if (advances.isNotEmpty) ('~advance', advances),
    ];

    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Roboto Mono'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${usable.length} runs · '
          '${usable.first.transcoded ? 'transcode' : 'direct play'} · '
          'queue ${usable.first.queueLength}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text('phase        p50       p90       max', style: mono),
        for (final (name, values) in rows)
          Text(
            '${name.padRight(10)} '
            '${_ms(_percentile(values, 0.50)).padLeft(8)} '
            '${_ms(_percentile(values, 0.90)).padLeft(8)} '
            '${_ms(values.last).padLeft(8)}',
            style: mono,
          ),
        const SizedBox(height: 8),
        Text(
          'READY is the number that counts: resolved, opened, prebuffered and '
          'seeked. Decoder start sits on top and Dart cannot see it — '
          '~advance is a floor from platform event pushes, not a measurement.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _copyJson() async {
    final payload = {
      'album': widget.album.name,
      'strategy': _strategy.name,
      'force_transcode': _forceTranscode,
      'start_at_handoff': _startAtHandoff,
      'seek_seconds': _seekSeconds,
      'track_index': _trackIndex,
      'samples': _samples.map((s) => s.toJson()).toList(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied')));
    }
  }

  Future<void> _runTrace() async {
    setState(() {
      _running = true;
      _error = null;
      _trace.clear();
      _status = 'Tracing...';
    });

    final player = ref.read(playerProvider);
    final clock = Stopwatch();
    StreamSubscription<PlaybackEvent>? events;
    StreamSubscription<PlayerState>? states;

    try {
      await _runOnce(trace: (line) => _trace.add(line));

      events = player.playbackEventStream.listen((e) {
        _trace.add(
          '${_pad(clock.elapsedMilliseconds)}  event  '
          'state=${e.processingState.name} '
          'pos=${e.updatePosition.inMilliseconds}ms '
          'buffered=${e.bufferedPosition.inMilliseconds}ms '
          'index=${e.currentIndex}',
        );
      });
      states = player.playerStateStream.listen((s) {
        _trace.add(
          '${_pad(clock.elapsedMilliseconds)}  state  '
          'playing=${s.playing} ${s.processingState.name}',
        );
      });

      clock.start();
      unawaited(player.play());
      await Future<void>.delayed(const Duration(seconds: 5));
      _trace.add(
        '${_pad(clock.elapsedMilliseconds)}  final  '
        'position=${player.position.inMilliseconds}ms '
        'playing=${player.playing} ${player.processingState.name}',
      );
    } on Object catch (error) {
      _trace.add('ERROR $error');
    } finally {
      await events?.cancel();
      await states?.cancel();
      await player.stop();
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _samples.clear();
      _status = 'Warming up...';
    });

    try {
      await _runOnce();

      for (var i = 0; i < _iterations; i++) {
        if (!mounted) return;
        setState(() => _status = 'Run ${i + 1}/$_iterations');
        final sample = await _runOnce();
        if (!mounted) return;
        setState(() => _samples.add(sample));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      await ref.read(playerProvider).stop();
      if (mounted) setState(() => _running = false);
    }
  }

  Future<HandoffSample> _runOnce({void Function(String)? trace}) async {
    final player = ref.read(playerProvider);
    final client = ref.read(mediaServerClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('not signed in');

    await player.stop();

    final seek = Duration(seconds: _seekSeconds);
    final clock = Stopwatch()..start();

    final page = await client.getSongs(
      userId: user.userId,
      albumId: widget.album.id,
    );
    final songs = page.items;
    if (songs.isEmpty) throw StateError('album has no tracks');
    final resolveUs = clock.elapsedMicroseconds;

    final index = _trackIndex.clamp(0, songs.length - 1);
    final handoffTrack = songs[index];

    var mark = clock.elapsedMicroseconds;
    final queue = switch (_strategy) {
      HandoffStrategy.wholeQueue => songs,
      HandoffStrategy.trackFirst => [handoffTrack],
    };
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final sources = await Future.wait([
      for (final song in queue) _sourceFor(client, song, stamp, seek),
    ]);
    final buildUs = clock.elapsedMicroseconds - mark;

    mark = clock.elapsedMicroseconds;
    final playerStart = _offloadSeekToServer ? Duration.zero : seek;
    await player.setAudioSources(
      sources,
      initialIndex: _strategy == HandoffStrategy.trackFirst ? 0 : index,
      initialPosition: playerStart,
      preload: true,
    );
    final loadUs = clock.elapsedMicroseconds - mark;

    mark = clock.elapsedMicroseconds;
    final started = player.playerStateStream
        .firstWhere(
          (s) => s.playing && s.processingState == ProcessingState.ready,
        )
        .then((_) => clock.elapsedMicroseconds - mark)
        .timeout(_phaseTimeout, onTimeout: () => -1);
    final advanced = player.playbackEventStream
        .firstWhere(
          (e) =>
              e.updatePosition > playerStart + const Duration(milliseconds: 20),
        )
        .then((_) => clock.elapsedMicroseconds - mark)
        .timeout(_phaseTimeout, onTimeout: () => -1);

    if (trace != null) {
      trace(
        '${_pad(0)}  loaded  ready in ${(clock.elapsedMicroseconds - mark) ~/ 1000}ms, '
        'player at ${player.position.inMilliseconds}ms, '
        'state=${player.processingState.name}',
      );
      unawaited(started);
      unawaited(advanced);
      return HandoffSample(
        resolveUs: resolveUs,
        buildUs: buildUs,
        loadUs: loadUs,
        startUs: -1,
        platformAdvanceUs: -1,
        transcoded: _forceTranscode,
        queueLength: songs.length,
      );
    }

    unawaited(player.play());
    final startUs = await started;
    final platformAdvanceUs = await advanced;

    await player.pause();

    if (_strategy == HandoffStrategy.trackFirst && songs.length > 1) {
      final rest = [
        for (var i = 0; i < songs.length; i++)
          if (i != index) songs[i],
      ];
      await player.addAudioSources([
        for (final song in rest) await _sourceFor(client, song, stamp, seek),
      ]);
    }

    final profileSource = handoffTrack.audioSources.firstOrNull;
    return HandoffSample(
      resolveUs: resolveUs,
      buildUs: buildUs,
      loadUs: loadUs,
      startUs: startUs,
      platformAdvanceUs: platformAdvanceUs,
      transcoded:
          (await client.resolveStreamSource(
            handoffTrack,
            playSessionId: 'probe',
            forceTranscode: _forceTranscode,
            startPosition: _offloadSeekToServer ? seek : null,
          )).isHls ||
          profileSource == null,
      queueLength: songs.length,
    );
  }

  bool get _offloadSeekToServer => _forceTranscode && _startAtHandoff;

  Future<AudioSource> _sourceFor(
    MediaServerClient client,
    LibraryItem song,
    String stamp,
    Duration seek,
  ) async {
    final downloaded =
        !_forceTranscode &&
        await ref
            .read(downloadManagerProvider.notifier)
            .isSongDownloaded(song.id);

    final tag = MediaItem(
      id: song.id,
      title: song.name,
      album: song.albumName,
      artist: song.albumArtist,
      duration: song.duration,
    );

    if (downloaded) {
      final path = await ref
          .read(downloadDatabaseProvider)
          .getDownloadedSongPath(song.id);
      if (path != null) return AudioSource.uri(Uri.file(path), tag: tag);
    }

    final resolved = await client.resolveStreamSource(
      song,
      playSessionId: '$stamp-${song.id}',
      forceTranscode: _forceTranscode,
      startPosition: _offloadSeekToServer ? seek : null,
    );
    return resolved.isHls
        ? HlsAudioSource(resolved.uri, tag: tag)
        : AudioSource.uri(resolved.uri, tag: tag);
  }
}

int _percentile(List<int> sorted, double fraction) {
  if (sorted.isEmpty) return 0;
  return sorted[((sorted.length - 1) * fraction).round()];
}

String _pad(int ms) => ms.toString().padLeft(5);

String _ms(int microseconds) => '${(microseconds / 1000).toStringAsFixed(0)}ms';
