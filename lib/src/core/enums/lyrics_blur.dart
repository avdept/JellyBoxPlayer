enum LyricsBlur {
  off,
  medium,
  hard;

  double sigmaFor(int distance) => switch (this) {
    LyricsBlur.off => 0,
    LyricsBlur.medium => (0.2 + 0.3 * distance).clamp(0.0, 1.5),
    LyricsBlur.hard => (0.3 + 0.7 * distance).clamp(0.0, 4.0),
  };
}
