enum PinLongevity {
  days7(Duration(days: 7)),
  days14(Duration(days: 14)),
  days30(Duration(days: 30)),
  infinite(Duration(days: 36500));

  const PinLongevity(this.maxAge);

  final Duration maxAge;
}
