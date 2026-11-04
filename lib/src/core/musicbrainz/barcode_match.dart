import 'package:jplayer/src/core/musicbrainz/musicbrainz_models.dart';
import 'package:optional_features/catalog.dart';

String? normalizeBarcode(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8 || digits.length > 14) return null;
  final trimmed = digits.replaceFirst(RegExp('^0+'), '');
  return trimmed.isEmpty ? null : trimmed;
}

MusicBrainzReleaseMatch? pickReleaseMatch(
  List<MusicBrainzRelease> releases, {
  required String barcode,
  String? artistName,
}) {
  final wanted = normalizeBarcode(barcode);
  if (wanted == null) return null;

  var candidates = [
    for (final release in releases)
      if (!release.isBootleg &&
          release.artistCredits.isNotEmpty &&
          normalizeBarcode(release.barcode ?? '') == wanted)
        release,
  ];
  if (candidates.isEmpty) return null;

  if (artistName != null) {
    final name = normalizeCatalogName(artistName);
    candidates = [
      for (final release in candidates)
        if (_credits(release, name)) release,
    ];
    if (candidates.isEmpty) return null;
  }

  final groups = <String, List<MusicBrainzRelease>>{};
  for (final release in candidates) {
    groups.putIfAbsent(release.releaseGroup.id, () => []).add(release);
  }
  final ranked = groups.values.toList()
    ..sort((a, b) {
      final bySize = b.length.compareTo(a.length);
      if (bySize != 0) return bySize;
      final byStatus = _officialCount(b).compareTo(_officialCount(a));
      if (byStatus != 0) return byStatus;
      return (_earliestYear(a) ?? 9999).compareTo(_earliestYear(b) ?? 9999);
    });
  final chosen = ranked.first;
  final representative = chosen.firstWhere(
    (release) => release.isOfficial,
    orElse: () => chosen.first,
  );
  return MusicBrainzReleaseMatch(
    releaseGroup: representative.releaseGroup,
    artist: representative.primaryArtist!,
    releases: chosen,
  );
}

bool _credits(MusicBrainzRelease release, String normalizedName) {
  if (normalizeCatalogName(release.artistName) == normalizedName) return true;
  return release.artistCredits.any(
    (credit) =>
        normalizeCatalogName(credit.artist.name) == normalizedName ||
        normalizeCatalogName(credit.name) == normalizedName,
  );
}

int _officialCount(List<MusicBrainzRelease> releases) =>
    releases.where((release) => release.isOfficial).length;

int? _earliestYear(List<MusicBrainzRelease> releases) {
  int? earliest;
  for (final release in releases) {
    final year = release.year;
    if (year != null && (earliest == null || year < earliest)) earliest = year;
  }
  return earliest;
}
