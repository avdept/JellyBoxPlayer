enum CatalogReleaseType { album, ep, single, compilation }

typedef CatalogKey = ({String source, String id});

class CatalogArtist {
  const CatalogArtist({
    required this.source,
    required this.id,
    required this.name,
    this.pictureUrl,
    this.fans = 0,
    this.url,
    this.additionalData = const {},
  });

  factory CatalogArtist.fromJson(Map<String, dynamic> json) => CatalogArtist(
    source: json['source'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    pictureUrl: json['pictureUrl'] as String?,
    fans: (json['fans'] as num?)?.toInt() ?? 0,
    url: _uri(json['url']),
    additionalData: _data(json['additionalData']),
  );

  final String source;
  final String id;
  final String name;
  final String? pictureUrl;
  final int fans;
  final Uri? url;
  final Map<String, Object?> additionalData;

  CatalogKey get key => (source: source, id: id);

  Map<String, Object?> toJson() => {
    'source': source,
    'id': id,
    'name': name,
    'pictureUrl': pictureUrl,
    'fans': fans,
    'url': url?.toString(),
    'additionalData': additionalData,
  };
}

class CatalogAlbum {
  const CatalogAlbum({
    required this.source,
    required this.id,
    required this.title,
    required this.releaseType,
    this.coverUrl,
    this.releaseDate,
    this.artistName,
    this.upc,
    this.url,
    this.additionalData = const {},
  });

  factory CatalogAlbum.fromJson(Map<String, dynamic> json) => CatalogAlbum(
    source: json['source'] as String,
    id: json['id'] as String,
    title: json['title'] as String,
    releaseType: CatalogReleaseType.values.byName(
      json['releaseType'] as String,
    ),
    coverUrl: json['coverUrl'] as String?,
    releaseDate: DateTime.tryParse(json['releaseDate'] as String? ?? ''),
    artistName: json['artistName'] as String?,
    upc: json['upc'] as String?,
    url: _uri(json['url']),
    additionalData: _data(json['additionalData']),
  );

  final String source;
  final String id;
  final String title;
  final CatalogReleaseType releaseType;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String? artistName;
  final String? upc;
  final Uri? url;
  final Map<String, Object?> additionalData;

  CatalogKey get key => (source: source, id: id);

  Map<String, Object?> toJson() => {
    'source': source,
    'id': id,
    'title': title,
    'releaseType': releaseType.name,
    'coverUrl': coverUrl,
    'releaseDate': releaseDate?.toIso8601String(),
    'artistName': artistName,
    'upc': upc,
    'url': url?.toString(),
    'additionalData': additionalData,
  };
}

class CatalogTrack {
  const CatalogTrack({
    required this.source,
    required this.id,
    required this.title,
    required this.duration,
    this.artistName,
    this.trackNumber,
    this.discNumber,
    this.isrc,
    this.hasPreview = false,
    this.additionalData = const {},
  });

  factory CatalogTrack.fromJson(Map<String, dynamic> json) => CatalogTrack(
    source: json['source'] as String,
    id: json['id'] as String,
    title: json['title'] as String,
    duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
    artistName: json['artistName'] as String?,
    trackNumber: (json['trackNumber'] as num?)?.toInt(),
    discNumber: (json['discNumber'] as num?)?.toInt(),
    isrc: json['isrc'] as String?,
    hasPreview: json['hasPreview'] as bool? ?? false,
    additionalData: _data(json['additionalData']),
  );

  final String source;
  final String id;
  final String title;
  final Duration duration;
  final String? artistName;
  final int? trackNumber;
  final int? discNumber;
  final String? isrc;
  final bool hasPreview;
  final Map<String, Object?> additionalData;

  CatalogKey get key => (source: source, id: id);

  Map<String, Object?> toJson() => {
    'source': source,
    'id': id,
    'title': title,
    'durationMs': duration.inMilliseconds,
    'artistName': artistName,
    'trackNumber': trackNumber,
    'discNumber': discNumber,
    'isrc': isrc,
    'hasPreview': hasPreview,
    'additionalData': additionalData,
  };
}

class CatalogAlbumDetail {
  const CatalogAlbumDetail({required this.album, required this.tracks});

  factory CatalogAlbumDetail.fromJson(Map<String, dynamic> json) =>
      CatalogAlbumDetail(
        album: CatalogAlbum.fromJson(json['album'] as Map<String, dynamic>),
        tracks: [
          for (final track in json['tracks'] as List<dynamic>)
            CatalogTrack.fromJson(track as Map<String, dynamic>),
        ],
      );

  final CatalogAlbum album;
  final List<CatalogTrack> tracks;

  Map<String, Object?> toJson() => {
    'album': album.toJson(),
    'tracks': [for (final track in tracks) track.toJson()],
  };
}

String normalizeCatalogName(String value) => value
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

Uri? _uri(Object? value) => value is String ? Uri.tryParse(value) : null;

Map<String, Object?> _data(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};
