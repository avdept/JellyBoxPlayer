class LidarrException implements Exception {
  const LidarrException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'LidarrException: $message';
}

class LidarrSystem {
  const LidarrSystem({required this.version, this.appName, this.instanceName});

  factory LidarrSystem.fromJson(Map<String, dynamic> json) => LidarrSystem(
    version: json['version'] as String? ?? '',
    appName: json['appName'] as String?,
    instanceName: json['instanceName'] as String?,
  );

  final String version;
  final String? appName;
  final String? instanceName;
}

class LidarrRootFolder {
  const LidarrRootFolder({
    required this.id,
    required this.path,
    this.name,
    this.defaultQualityProfileId = 0,
    this.defaultMetadataProfileId = 0,
    this.accessible = true,
    this.freeSpace,
  });

  factory LidarrRootFolder.fromJson(Map<String, dynamic> json) =>
      LidarrRootFolder(
        id: (json['id'] as num).toInt(),
        path: json['path'] as String? ?? '',
        name: json['name'] as String?,
        defaultQualityProfileId:
            (json['defaultQualityProfileId'] as num?)?.toInt() ?? 0,
        defaultMetadataProfileId:
            (json['defaultMetadataProfileId'] as num?)?.toInt() ?? 0,
        accessible: json['accessible'] as bool? ?? true,
        freeSpace: (json['freeSpace'] as num?)?.toInt(),
      );

  final int id;
  final String path;
  final String? name;
  final int defaultQualityProfileId;
  final int defaultMetadataProfileId;
  final bool accessible;
  final int? freeSpace;

  String get label => name?.isNotEmpty ?? false ? name! : path;
}

class LidarrProfile {
  const LidarrProfile({required this.id, required this.name});

  factory LidarrProfile.fromJson(Map<String, dynamic> json) => LidarrProfile(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
  );

  final int id;
  final String name;
}

class LidarrAddDefaults {
  const LidarrAddDefaults({
    required this.rootFolderPath,
    required this.qualityProfileId,
    required this.metadataProfileId,
  });

  final String rootFolderPath;
  final int qualityProfileId;
  final int metadataProfileId;
}

class LidarrArtist {
  const LidarrArtist({
    required this.foreignArtistId,
    required this.name,
    this.id = 0,
    this.disambiguation,
    this.overview,
    this.monitored = false,
    this.qualityProfileId = 0,
    this.metadataProfileId = 0,
    this.rootFolderPath,
    this.albumCount = 0,
    this.trackFileCount = 0,
    this.json = const {},
  });

  factory LidarrArtist.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] as Map<String, dynamic>?;
    return LidarrArtist(
      id: (json['id'] as num?)?.toInt() ?? 0,
      foreignArtistId: json['foreignArtistId'] as String? ?? '',
      name: json['artistName'] as String? ?? '',
      disambiguation: json['disambiguation'] as String?,
      overview: json['overview'] as String?,
      monitored: json['monitored'] as bool? ?? false,
      qualityProfileId: (json['qualityProfileId'] as num?)?.toInt() ?? 0,
      metadataProfileId: (json['metadataProfileId'] as num?)?.toInt() ?? 0,
      rootFolderPath:
          json['rootFolderPath'] as String? ?? json['path'] as String?,
      albumCount: (stats?['albumCount'] as num?)?.toInt() ?? 0,
      trackFileCount: (stats?['trackFileCount'] as num?)?.toInt() ?? 0,
      json: json,
    );
  }

  final int id;
  final String foreignArtistId;
  final String name;
  final String? disambiguation;
  final String? overview;
  final bool monitored;
  final int qualityProfileId;
  final int metadataProfileId;
  final String? rootFolderPath;
  final int albumCount;
  final int trackFileCount;
  final Map<String, dynamic> json;

  bool get isAdded => id > 0;
}

class LidarrAlbum {
  const LidarrAlbum({
    required this.foreignAlbumId,
    required this.title,
    this.id = 0,
    this.artistId = 0,
    this.albumType,
    this.disambiguation,
    this.releaseDate,
    this.monitored = false,
    this.artist,
    this.trackCount = 0,
    this.trackFileCount = 0,
    this.percentOfTracks = 0,
    this.json = const {},
  });

  factory LidarrAlbum.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] as Map<String, dynamic>?;
    final artist = json['artist'] as Map<String, dynamic>?;
    return LidarrAlbum(
      id: (json['id'] as num?)?.toInt() ?? 0,
      artistId: (json['artistId'] as num?)?.toInt() ?? 0,
      foreignAlbumId: json['foreignAlbumId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      albumType: json['albumType'] as String?,
      disambiguation: json['disambiguation'] as String?,
      releaseDate: DateTime.tryParse(json['releaseDate'] as String? ?? ''),
      monitored: json['monitored'] as bool? ?? false,
      artist: artist == null ? null : LidarrArtist.fromJson(artist),
      trackCount: (stats?['totalTrackCount'] as num?)?.toInt() ?? 0,
      trackFileCount: (stats?['trackFileCount'] as num?)?.toInt() ?? 0,
      percentOfTracks: (stats?['percentOfTracks'] as num?)?.toDouble() ?? 0,
      json: json,
    );
  }

  final int id;
  final int artistId;
  final String foreignAlbumId;
  final String title;
  final String? albumType;
  final String? disambiguation;
  final DateTime? releaseDate;
  final bool monitored;
  final LidarrArtist? artist;
  final int trackCount;
  final int trackFileCount;
  final double percentOfTracks;
  final Map<String, dynamic> json;

  bool get isAdded => id > 0;

  bool get isDownloaded => trackFileCount > 0 && percentOfTracks >= 100;
}

class LidarrQueueItem {
  const LidarrQueueItem({
    required this.id,
    required this.title,
    this.artistId,
    this.albumId,
    this.size = 0,
    this.sizeLeft = 0,
    this.status,
    this.downloadState,
  });

  factory LidarrQueueItem.fromJson(Map<String, dynamic> json) =>
      LidarrQueueItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        artistId: (json['artistId'] as num?)?.toInt(),
        albumId: (json['albumId'] as num?)?.toInt(),
        size: (json['size'] as num?)?.toDouble() ?? 0,
        sizeLeft: (json['sizeleft'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String?,
        downloadState: json['trackedDownloadState'] as String?,
      );

  final int id;
  final String title;
  final int? artistId;
  final int? albumId;
  final double size;
  final double sizeLeft;
  final String? status;
  final String? downloadState;

  double get progress => size <= 0 ? 0 : ((size - sizeLeft) / size).clamp(0, 1);
}
