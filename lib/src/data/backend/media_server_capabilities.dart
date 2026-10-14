import 'package:jplayer/src/core/enums/enums.dart';

class MediaServerCapabilities {
  const MediaServerCapabilities({
    this.lyrics = true,
    this.similarAlbums = true,
    this.playlistSearch = true,
    this.playlistFavourites = true,
    this.soundSearch = false,
    this.ratings = false,
    this.likedTimestamp = false,
    this.artistScopes = const {ArtistScope.albumArtists},
  });

  final bool lyrics;
  final bool similarAlbums;
  final bool playlistSearch;
  final bool playlistFavourites;
  final bool soundSearch;
  final bool ratings;
  final bool likedTimestamp;
  final Set<ArtistScope> artistScopes;

  MediaServerCapabilities copyWith({
    bool? lyrics,
    bool? similarAlbums,
    bool? playlistSearch,
    bool? playlistFavourites,
    bool? soundSearch,
    bool? ratings,
    bool? likedTimestamp,
    Set<ArtistScope>? artistScopes,
  }) => MediaServerCapabilities(
    lyrics: lyrics ?? this.lyrics,
    similarAlbums: similarAlbums ?? this.similarAlbums,
    playlistSearch: playlistSearch ?? this.playlistSearch,
    playlistFavourites: playlistFavourites ?? this.playlistFavourites,
    soundSearch: soundSearch ?? this.soundSearch,
    ratings: ratings ?? this.ratings,
    likedTimestamp: likedTimestamp ?? this.likedTimestamp,
    artistScopes: artistScopes ?? this.artistScopes,
  );
}
