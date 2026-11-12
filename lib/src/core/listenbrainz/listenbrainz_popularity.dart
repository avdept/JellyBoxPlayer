import 'package:jplayer/src/domain/models/models.dart';

class ListenBrainzRecording {
  const ListenBrainzRecording({
    required this.mbid,
    required this.name,
    this.listenCount = 0,
  });

  factory ListenBrainzRecording.fromJson(Map<String, Object?> json) =>
      ListenBrainzRecording(
        mbid: json['recording_mbid']?.toString() ?? '',
        name: json['recording_name']?.toString() ?? '',
        listenCount: (json['total_listen_count'] as num?)?.toInt() ?? 0,
      );

  final String mbid;
  final String name;
  final int listenCount;
}

const List<String> _recordingIdKeys = [
  ExternalIdProvider.musicBrainzRecording,
  ExternalIdProvider.musicBrainzTrack,
];

List<LibraryItem> rankByListenBrainz(
  List<LibraryItem> songs,
  List<ListenBrainzRecording> recordings,
) {
  final rankByMbid = <String, int>{};
  final rankByTitle = <String, int>{};
  for (var rank = 0; rank < recordings.length; rank++) {
    final recording = recordings[rank];
    if (recording.mbid.isNotEmpty) {
      rankByMbid.putIfAbsent(recording.mbid, () => rank);
    }
    final title = normalizeTitle(recording.name);
    if (title.isNotEmpty) rankByTitle.putIfAbsent(title, () => rank);
  }

  int? rankOf(LibraryItem song) {
    for (final key in _recordingIdKeys) {
      final rank = rankByMbid[song.externalIds[key]];
      if (rank != null) return rank;
    }
    return rankByTitle[normalizeTitle(song.name)];
  }

  final ranked = <int, LibraryItem>{};
  for (final song in songs) {
    final rank = rankOf(song);
    if (rank != null) ranked.putIfAbsent(rank, () => song);
  }
  return [for (final rank in ranked.keys.toList()..sort()) ranked[rank]!];
}

final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

String normalizeTitle(String title) =>
    title.toLowerCase().replaceAll(_nonWord, ' ').trim();
