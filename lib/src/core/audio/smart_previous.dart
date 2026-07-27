import 'package:just_audio/just_audio.dart';

/// Shared "previous" behaviour for every entry point (in-app button, media
/// keys, lock-screen / Now Playing controls) so they behave identically.
extension SmartPrevious on AudioPlayer {
  /// Media-control "previous": restart the current track if we're more than
  /// [threshold] into it (or there is no earlier track), otherwise skip to the
  /// previous track. Resumes playback if paused, matching the in-app button.
  Future<void> smartSeekToPrevious({
    Duration threshold = const Duration(seconds: 3),
  }) async {
    final hasPrev = (currentIndex ?? 0) > 0;
    if (position > threshold || !hasPrev) {
      await seek(Duration.zero);
    } else {
      await seekToPrevious();
    }
    if (!playing) await play();
  }
}
