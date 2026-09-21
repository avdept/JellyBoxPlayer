enum AnimationSpeed {
  none(0),
  slow(0.5),
  medium(1),
  fast(2);

  const AnimationSpeed(this.multiplier);

  final double multiplier;

  bool get isAnimated => multiplier > 0;
}
