import 'package:dio/dio.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:retrofit/retrofit.dart';

part 'jellyfin_api.g.dart';

@RestApi(parser: Parser.JsonSerializable)
abstract class JellyfinApi {
  factory JellyfinApi(
    Dio client, {
    String baseUrl,
  }) = _JellyfinApi;

  @POST('/Users/AuthenticateByName')
  Future<HttpResponse<UserDTO>> signIn(
    @Body() Map<String, dynamic> credentials,
  );

  @POST('/Users/{userId}/FavoriteItems/{itemId}')
  Future<void> saveFavorite({
    @Path('userId') required String userId,
    @Path('itemId') required String itemId,
  });

  @DELETE('/Users/{userId}/FavoriteItems/{itemId}')
  Future<void> removeFavorite({
    @Path('userId') required String userId,
    @Path('itemId') required String itemId,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<SongsWrapper>> getSongs({
    @Path('userId') required String userId,
    @Query('ParentId') required String albumId,
    @Query('IncludeItemTypes') String includeType = 'music',
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<AlbumsWrapper>> getAlbums({
    @Path('userId') required String userId,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'MusicAlbum',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'DateCreated,SortName',
    @Query('ContributingArtistIds') String? contributingArtistIds,
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('AlbumArtistIds') List<String> artistIds = const [],
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<AlbumsWrapper>> searchAlbums({
    @Path('userId') required String userId,
    @Query('searchTerm') required String searchTerm,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'MusicAlbum',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<AlbumsWrapper>> getPlaylists({
    @Path('userId') required String userId,
    @Query('IncludeItemTypes') String type = 'Playlist',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'DateCreated,SortName',
    @Query('ContributingArtistIds') String? contributingArtistIds,
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('AlbumArtistIds') List<String> artistIds = const [],
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<AlbumsWrapper>> searchPlaylists({
    @Path('userId') required String userId,
    @Query('ParentId') required String libraryId,
    @Query('searchTerm') required String searchTerm,
    @Query('IncludeItemTypes') String type = 'Playlist',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Playlists/{playlistId}/Items')
  Future<HttpResponse<SongsWrapper>> getPlaylistSongs({
    @Path('playlistId') required String playlistId,
    @Query('userId') required String userId,
    @Query('IncludeItemTypes') String includeType = 'music',
  });

  @GET('/Items/{itemId}')
  Future<HttpResponse<ItemDTO>> getItem({
    @Path('itemId') required String itemId,
  });

  @POST('/Playlists')
  Future<void> createPlaylist(
    @Body() Map<String, dynamic> arguments,
  );

  @DELETE('/Items/{playlistId}')
  Future<void> deletePlaylist({
    @Path('playlistId') required String playlistId,
  });

  @POST('/Playlists/{playlistId}/Items')
  Future<void> addPlaylistItems({
    @Path('playlistId') required String playlistId,
    @Query('userId') required String userId,
    @Query('ids') required String entryIds,
  });

  @DELETE('/Playlists/{playlistId}/Items')
  Future<void> removePlaylistItem({
    @Path('playlistId') required String playlistId,
    @Query('EntryIds') required String entryIds,
  });

  @GET('/Artists')
  Future<HttpResponse<AlbumsWrapper>> getArtists({
    @Query('userId') required String userId,
    @Query('Fields')
    List<String> fields = const ['BackdropImageTags', 'Overview'],
    @Query('IncludeArtists') bool includeArtists = true,
    @Query('IncludeItemTypes') String type = 'Artist',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'SortName',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Artists')
  Future<HttpResponse<AlbumsWrapper>> searchArtists({
    @Query('userId') required String userId,
    @Query('searchTerm') required String searchTerm,
    @Query('Fields')
    List<String> fields = const ['BackdropImageTags', 'Overview'],
    @Query('IncludeArtists') bool includeArtists = true,
    @Query('IncludeItemTypes') String type = 'Artist',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Views')
  Future<HttpResponse<Libraries>> getLibraries({
    @Path('userId') required String userId,
  });
}
