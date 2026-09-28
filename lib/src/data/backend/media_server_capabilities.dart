import 'package:jplayer/src/core/enums/enums.dart';

class MediaServerCapabilities {
  const MediaServerCapabilities({
    this.lyrics = true,
    this.similarAlbums = true,
    this.playlistSearch = true,
    this.playlistFavourites = true,
    this.artistScopes = const {ArtistScope.albumArtists},
  });

  final bool lyrics;
  final bool similarAlbums;
  final bool playlistSearch;
  final bool playlistFavourites;
  final Set<ArtistScope> artistScopes;

  MediaServerCapabilities copyWith({
    bool? lyrics,
    bool? similarAlbums,
    bool? playlistSearch,
    bool? playlistFavourites,
    Set<ArtistScope>? artistScopes,
  }) => MediaServerCapabilities(
    lyrics: lyrics ?? this.lyrics,
    similarAlbums: similarAlbums ?? this.similarAlbums,
    playlistSearch: playlistSearch ?? this.playlistSearch,
    playlistFavourites: playlistFavourites ?? this.playlistFavourites,
    artistScopes: artistScopes ?? this.artistScopes,
  );
}
