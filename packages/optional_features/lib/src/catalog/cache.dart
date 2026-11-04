class CatalogCacheEntry {
  const CatalogCacheEntry({
    required this.json,
    required this.fetchedAt,
    required this.expires,
  });

  final String json;
  final DateTime fetchedAt;
  final DateTime expires;
}

abstract class CatalogCacheStore {
  Future<CatalogCacheEntry?> read(String source, String key);

  Future<void> write(
    String source,
    String key,
    String json, {
    required DateTime expires,
  });
}
