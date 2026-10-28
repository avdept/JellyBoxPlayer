class MusicBrainzArtist {
  const MusicBrainzArtist({
    required this.id,
    required this.name,
    this.sortName,
    this.disambiguation,
  });

  factory MusicBrainzArtist.fromJson(Map<String, dynamic> json) =>
      MusicBrainzArtist(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        sortName: json['sort-name'] as String?,
        disambiguation: json['disambiguation'] as String?,
      );

  final String id;
  final String name;
  final String? sortName;
  final String? disambiguation;
}

class MusicBrainzArtistCredit {
  const MusicBrainzArtistCredit({
    required this.name,
    required this.artist,
    this.joinPhrase = '',
  });

  factory MusicBrainzArtistCredit.fromJson(Map<String, dynamic> json) =>
      MusicBrainzArtistCredit(
        name: json['name'] as String? ?? '',
        joinPhrase: json['joinphrase'] as String? ?? '',
        artist: MusicBrainzArtist.fromJson(
          json['artist'] as Map<String, dynamic>,
        ),
      );

  final String name;
  final String joinPhrase;
  final MusicBrainzArtist artist;
}

class MusicBrainzReleaseGroup {
  const MusicBrainzReleaseGroup({
    required this.id,
    required this.title,
    this.primaryType,
    this.secondaryTypes = const [],
  });

  factory MusicBrainzReleaseGroup.fromJson(Map<String, dynamic> json) =>
      MusicBrainzReleaseGroup(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        primaryType: json['primary-type'] as String?,
        secondaryTypes: [
          for (final type in json['secondary-types'] as List<dynamic>? ?? [])
            type as String,
        ],
      );

  final String id;
  final String title;
  final String? primaryType;
  final List<String> secondaryTypes;
}

class MusicBrainzMedium {
  const MusicBrainzMedium({this.format, this.trackCount});

  factory MusicBrainzMedium.fromJson(Map<String, dynamic> json) =>
      MusicBrainzMedium(
        format: json['format'] as String?,
        trackCount: (json['track-count'] as num?)?.toInt(),
      );

  final String? format;
  final int? trackCount;
}

class MusicBrainzLabelInfo {
  const MusicBrainzLabelInfo({
    this.catalogNumber,
    this.labelId,
    this.labelName,
  });

  factory MusicBrainzLabelInfo.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as Map<String, dynamic>?;
    return MusicBrainzLabelInfo(
      catalogNumber: json['catalog-number'] as String?,
      labelId: label?['id'] as String?,
      labelName: label?['name'] as String?,
    );
  }

  final String? catalogNumber;
  final String? labelId;
  final String? labelName;
}

class MusicBrainzRelease {
  const MusicBrainzRelease({
    required this.id,
    required this.title,
    required this.releaseGroup,
    this.status,
    this.disambiguation,
    this.date,
    this.country,
    this.barcode,
    this.packaging,
    this.artistCredits = const [],
    this.trackCount,
    this.media = const [],
    this.labels = const [],
    this.score,
  });

  factory MusicBrainzRelease.fromJson(Map<String, dynamic> json) =>
      MusicBrainzRelease(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        releaseGroup: MusicBrainzReleaseGroup.fromJson(
          json['release-group'] as Map<String, dynamic>,
        ),
        status: json['status'] as String?,
        disambiguation: json['disambiguation'] as String?,
        date: json['date'] as String?,
        country: json['country'] as String?,
        barcode: json['barcode'] as String?,
        packaging: json['packaging'] as String?,
        artistCredits: [
          for (final credit in json['artist-credit'] as List<dynamic>? ?? [])
            MusicBrainzArtistCredit.fromJson(credit as Map<String, dynamic>),
        ],
        trackCount: (json['track-count'] as num?)?.toInt(),
        media: [
          for (final medium in json['media'] as List<dynamic>? ?? [])
            MusicBrainzMedium.fromJson(medium as Map<String, dynamic>),
        ],
        labels: [
          for (final info in json['label-info'] as List<dynamic>? ?? [])
            MusicBrainzLabelInfo.fromJson(info as Map<String, dynamic>),
        ],
        score: (json['score'] as num?)?.toInt(),
      );

  final String id;
  final String title;
  final MusicBrainzReleaseGroup releaseGroup;
  final String? status;
  final String? disambiguation;
  final String? date;
  final String? country;
  final String? barcode;
  final String? packaging;
  final List<MusicBrainzArtistCredit> artistCredits;
  final int? trackCount;
  final List<MusicBrainzMedium> media;
  final List<MusicBrainzLabelInfo> labels;
  final int? score;

  bool get isOfficial => status == 'Official';

  bool get isBootleg => status == 'Bootleg' || status == 'Pseudo-Release';

  int? get year => int.tryParse(date?.split('-').first ?? '');

  MusicBrainzArtist? get primaryArtist => artistCredits.firstOrNull?.artist;

  String get artistName => [
    for (final credit in artistCredits) '${credit.name}${credit.joinPhrase}',
  ].join();
}

class MusicBrainzReleaseSearch {
  const MusicBrainzReleaseSearch({
    required this.count,
    required this.offset,
    required this.releases,
  });

  factory MusicBrainzReleaseSearch.fromJson(Map<String, dynamic> json) =>
      MusicBrainzReleaseSearch(
        count: (json['count'] as num?)?.toInt() ?? 0,
        offset: (json['offset'] as num?)?.toInt() ?? 0,
        releases: [
          for (final release in json['releases'] as List<dynamic>? ?? [])
            MusicBrainzRelease.fromJson(release as Map<String, dynamic>),
        ],
      );

  final int count;
  final int offset;
  final List<MusicBrainzRelease> releases;
}

class MusicBrainzReleaseMatch {
  const MusicBrainzReleaseMatch({
    required this.releaseGroup,
    required this.artist,
    required this.releases,
  });

  final MusicBrainzReleaseGroup releaseGroup;
  final MusicBrainzArtist artist;
  final List<MusicBrainzRelease> releases;

  String get releaseGroupId => releaseGroup.id;

  String get artistId => artist.id;
}
