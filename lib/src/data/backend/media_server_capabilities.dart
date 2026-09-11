class MediaServerCapabilities {
  const MediaServerCapabilities({
    this.lyrics = true,
    this.similarAlbums = true,
    this.playlistSearch = true,
  });

  final bool lyrics;
  final bool similarAlbums;
  final bool playlistSearch;
}
