import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/domain/models/models.dart';

sealed class ScrobbleEvent {
  const ScrobbleEvent(this.listen);

  final Listen listen;
}

final class NowPlayingEvent extends ScrobbleEvent {
  const NowPlayingEvent(super.listen);
}

final class ListenedEvent extends ScrobbleEvent {
  const ListenedEvent(super.listen);
}

class ListenTracker {
  ListenTracker({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const maxCountedGap = Duration(seconds: 10);
  static const listenCap = Duration(minutes: 4);
  static const restartWindow = Duration(seconds: 5);

  final DateTime Function() _clock;
  Listen? _current;
  Duration _listened = Duration.zero;
  Duration? _lastPosition;
  var _submitted = false;
  var _announced = false;

  Listen? get current => _current;

  static Duration thresholdFor(LibraryItem song) {
    final duration = song.duration;
    if (duration <= Duration.zero) return listenCap;
    final half = duration ~/ 2;
    return half < listenCap ? half : listenCap;
  }

  void reset() {
    _current = null;
    _listened = Duration.zero;
    _lastPosition = null;
    _submitted = false;
    _announced = false;
  }

  List<ScrobbleEvent> update(PlaybackState state) {
    final index = state.currentMediaIndex;
    final song = index == null ? null : state.songs.elementAtOrNull(index);
    if (song == null) {
      reset();
      return const [];
    }

    final position = state.position;
    final last = _lastPosition;
    final restarted =
        last != null &&
        position < restartWindow &&
        last - position > restartWindow;
    var current = _current;
    if (current == null || song.id != current.song.id || restarted) {
      return _begin(song, state);
    }

    if (!state.status.isPlaying) {
      if (state.status.isPaused || state.status.isStopped) _announced = false;
      _lastPosition = position;
      return const [];
    }

    if (last != null) {
      final delta = position - last;
      if (delta > Duration.zero && delta <= maxCountedGap) _listened += delta;
    }
    _lastPosition = position;

    final events = <ScrobbleEvent>[];
    if (!_announced) {
      _announced = true;
      if (_listened == Duration.zero) {
        current = _current = _listenFor(song, state);
      }
      events.add(NowPlayingEvent(current));
    }
    if (!_submitted && _listened >= thresholdFor(song)) {
      _submitted = true;
      events.add(ListenedEvent(current));
    }
    return events;
  }

  List<ScrobbleEvent> _begin(LibraryItem song, PlaybackState state) {
    final listen = _current = _listenFor(song, state);
    _listened = Duration.zero;
    _lastPosition = state.position;
    _submitted = false;
    _announced = state.status.isPlaying;
    return _announced ? [NowPlayingEvent(listen)] : const [];
  }

  Listen _listenFor(LibraryItem song, PlaybackState state) =>
      Listen(song: song, album: state.album, listenedAt: _clock());
}
