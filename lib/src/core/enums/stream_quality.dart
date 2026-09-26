enum StreamQuality {
  original(null),
  kbps320(320),
  kbps256(256),
  kbps192(192),
  kbps128(128),
  kbps96(96),
  kbps64(64);

  const StreamQuality(this.maxBitRate);

  final int? maxBitRate;
}
