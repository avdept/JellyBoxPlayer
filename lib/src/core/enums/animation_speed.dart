enum AnimationSpeed {
  none(0),
  slow(1),
  medium(2),
  fast(4);

  const AnimationSpeed(this.multiplier);

  final double multiplier;

  bool get isAnimated => multiplier > 0;
}
