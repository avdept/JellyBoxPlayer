enum ForwardCacheWindow {
  min10(10),
  min15(15),
  min30(30),
  min45(45),
  min60(60);

  const ForwardCacheWindow(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}
