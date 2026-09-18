enum ContentUpdateInterval {
  min1(Duration(minutes: 1)),
  min5(Duration(minutes: 5)),
  min15(Duration(minutes: 15)),
  min30(Duration(minutes: 30)),
  never(null);

  const ContentUpdateInterval(this.duration);

  final Duration? duration;
}
