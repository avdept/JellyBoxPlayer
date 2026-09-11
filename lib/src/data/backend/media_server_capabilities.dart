import 'package:jplayer/src/core/enums/enums.dart';

class MediaServerCapabilities {
  const MediaServerCapabilities({
    this.lyrics = true,
    this.similarAlbums = true,
    this.playlistSearch = true,
    this.artistScopes = const {ArtistScope.albumArtists},
  });

  final bool lyrics;
  final bool similarAlbums;
  final bool playlistSearch;
  final Set<ArtistScope> artistScopes;

  MediaServerCapabilities copyWith({
    bool? lyrics,
    bool? similarAlbums,
    bool? playlistSearch,
    Set<ArtistScope>? artistScopes,
  }) => MediaServerCapabilities(
    lyrics: lyrics ?? this.lyrics,
    similarAlbums: similarAlbums ?? this.similarAlbums,
    playlistSearch: playlistSearch ?? this.playlistSearch,
    artistScopes: artistScopes ?? this.artistScopes,
  );
}
