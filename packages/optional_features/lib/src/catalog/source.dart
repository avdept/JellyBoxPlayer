import 'package:optional_features/src/catalog/models.dart';

class CatalogBrand {
  const CatalogBrand({
    required this.name,
    required this.color,
    required this.logoSvg,
    required this.description,
  });

  final String name;
  final int color;
  final String logoSvg;
  final String description;
}

abstract class CatalogSource {
  String get id;

  CatalogBrand get brand;

  Future<CatalogArtist?> findArtist(
    String name, {
    Iterable<String> albumTitles = const [],
  });

  Future<CatalogArtist?> artist(String id);

  Future<List<CatalogArtist>> relatedArtists(String artistId, {int limit = 20});

  Future<List<CatalogAlbum>> albums(String artistId);

  Future<CatalogAlbumDetail?> album(String id);

  Future<Uri?> previewUrl(String trackId);
}
