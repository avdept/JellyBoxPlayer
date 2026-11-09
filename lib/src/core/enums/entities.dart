enum EntityFilter {
  sortName('Name', defaultDescending: false),
  albumArtist('Album Artist', defaultDescending: false),
  dateCreated('Date Added', defaultDescending: true),
  dateLastContentAdded('Recently Updated', defaultDescending: true),
  dateLiked('Date Liked', defaultDescending: true),
  random('Random', defaultDescending: false),
  rating('Rating', defaultDescending: true);

  const EntityFilter(this.label, {required this.defaultDescending});

  final String label;
  final bool defaultDescending;
}

enum ArtistFilter {
  sortName,
  dateCreated,
}
