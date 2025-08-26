enum PlaybackStatus {
  stopped,
  paused,
  playing,
  buffering,
  error;

  bool get isPlaying => this == playing;
  bool get isPaused => this == paused;
  bool get isStopped => this == stopped;
}
