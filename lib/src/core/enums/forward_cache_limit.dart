enum ForwardCacheLimit {
  off(0),
  mb500(500 * 1024 * 1024),
  gb1(1024 * 1024 * 1024),
  gb2(2 * 1024 * 1024 * 1024),
  gb4(4 * 1024 * 1024 * 1024),
  gb8(8 * 1024 * 1024 * 1024);

  const ForwardCacheLimit(this.bytes);

  final int bytes;

  bool get isEnabled => bytes > 0;
}
