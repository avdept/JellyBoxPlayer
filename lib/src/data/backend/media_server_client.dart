import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/domain/models/models.dart';

/// A media server backend (Jellyfin, and eventually Navidrome/Subsonic).
///
/// Browsing/search/CRUD methods return the backend-agnostic
/// `LibraryItem`/`LibraryPage` domain model; each implementation maps its own
/// wire format onto it at the boundary (see `JellyfinClient`'s
/// `ItemDTOMapping`).
///
/// Stream/image URL resolution and playback-state reporting are also fully
/// backend-agnostic: those are exactly the places today's code used to
/// hand-build Jellyfin REST paths in multiple places, and centralizing them
/// here is what removes that duplication.
///
/// Login is intentionally NOT part of this interface: each backend has its
/// own credential shape and auth flow (e.g. `JellyfinClient.signIn`), chosen
/// by the caller once the server type has been probed.
abstract class MediaServerClient {
  Future<LibraryPage> getAlbums({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
    List<String> genreIds = const [],
  });

  Future<LibraryPage> getArtists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> getGenres({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  });

  Future<LibraryPage> getPlaylists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
  });

  Future<LibraryPage> getAllSongs({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  });

  /// A single album's tracklist.
  Future<LibraryPage> getSongs({
    required String userId,
    required String albumId,
  });

  /// The songs behind an artist or genre "play all" action.
  Future<LibraryPage> getSongsOfSet({
    required String userId,
    String? libraryId,
    List<String> artistIds = const [],
    List<String> genreIds = const [],
    String sortBy = 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
    String sortOrder = 'Ascending',
    String startIndex = '0',
    String limit = '300',
  });

  Future<LibraryPage> getPlaylistSongs({
    required String userId,
    required String playlistId,
  });

  Future<LibraryPage> getSimilarAlbums({
    required String userId,
    required String albumId,
    String limit = '12',
  });

  Future<LibraryPage> getLibraries({required String userId});

  Future<LibraryItem> getItem(String itemId);

  Future<LibraryPage> searchAlbums({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchArtists({
    required String userId,
    required String searchTerm,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchSongs({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchPlaylists({
    required String userId,
    required String searchTerm,
    required String libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<void> setFavorite(String itemId, {required bool favorite});

  Future<void> createPlaylist(PlaylistData values);

  Future<void> deletePlaylist(String playlistId);

  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> itemIds,
  });

  Future<void> removePlaylistItem({
    required String playlistId,
    required String entryId,
  });

  Future<LyricsDTO> getLyrics(String itemId);

  /// Resolves a playable source for [song]. When [preferHls] is false, the
  /// result is always a single-file progressive/direct stream (needed for
  /// downloads, which can't target an HLS playlist); when true (the default,
  /// used for live playback) a transcode-requiring source may come back as
  /// HLS instead.
  Future<StreamSource> resolveStreamSource(
    LibraryItem song, {
    required String playSessionId,
    bool preferHls = true,
  });

  String imageUrl({
    required String id,
    String? tagId,
    ImageKind kind = ImageKind.primary,
    int size = 420,
  });

  Future<void> reportPlaybackStarted(PlaybackReport report);

  Future<void> reportPlaybackProgress(PlaybackReport report);

  Future<void> reportPlaybackStopped(PlaybackReport report);

  /// A cheap authenticated call used to validate a restored session.
  Future<bool> validateSession();

  Future<void> signOut();
}
