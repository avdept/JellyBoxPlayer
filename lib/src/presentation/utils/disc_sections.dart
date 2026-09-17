import 'package:jplayer/src/domain/models/models.dart';

class DiscSection {
  const DiscSection({required this.discNumber, required this.songs});

  final int? discNumber;
  final List<LibraryItem> songs;
}

List<DiscSection> discSections(List<LibraryItem> songs) {
  final sections = <DiscSection>[];
  for (final song in songs) {
    final last = sections.lastOrNull;
    if (last != null && last.discNumber == song.discNumber) {
      last.songs.add(song);
    } else {
      sections.add(DiscSection(discNumber: song.discNumber, songs: [song]));
    }
  }
  return sections;
}
