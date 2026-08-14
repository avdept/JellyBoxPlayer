/// Backend-agnostic "now playing" report, translated by each
/// `MediaServerClient` into whatever shape its server expects (Jellyfin's
/// `/Sessions/Playing*` payload, a Subsonic scrobble submission, etc).
class PlaybackReport {
  const PlaybackReport({
    required this.itemId,
    required this.playSessionId,
    this.mediaSourceId,
    this.position,
    this.isPaused,
    this.canSeek,
    this.queueItemIds = const [],
  });

  final String itemId;
  final String playSessionId;
  final String? mediaSourceId;
  final Duration? position;
  final bool? isPaused;
  final bool? canSeek;
  final List<String> queueItemIds;
}
