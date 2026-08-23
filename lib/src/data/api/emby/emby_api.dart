import 'package:dio/dio.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:retrofit/retrofit.dart';

part 'emby_api.g.dart';

@RestApi(parser: Parser.JsonSerializable)
abstract class EmbyApi {
  factory EmbyApi(
    Dio client, {
    String baseUrl,
  }) = _EmbyApi;

  @GET('/System/Info/Public')
  Future<HttpResponse<PublicSystemInfoDTO>> getPublicSystemInfo();

  @POST('/Users/AuthenticateByName')
  Future<HttpResponse<SignInResultDTO>> signIn({
    @Body() required UserCredentials credentials,
  });

  @POST('/Users/{userId}/FavoriteItems/{itemId}')
  Future<HttpResponse<void>> saveFavorite({
    @Path('userId') required String userId,
    @Path('itemId') required String itemId,
  });

  @POST('/Users/{userId}/FavoriteItems/{itemId}/Delete')
  Future<HttpResponse<void>> removeFavorite({
    @Path('userId') required String userId,
    @Path('itemId') required String itemId,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> getSongs({
    @Path('userId') required String userId,
    @Query('ParentId') required String albumId,
    @Query('IncludeItemTypes') String includeType = 'Audio',
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> getAllSongs({
    @Path('userId') required String userId,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'Audio',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'SortName',
    @Query('SortOrder') String sortOrder = 'Ascending',
    @Query('Filters') List<String> filters = const [],
    @Query('Recursive') bool recursive = true,
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> getSongsOfSet({
    @Path('userId') required String userId,
    @Query('ParentId') String? libraryId,
    @Query('AlbumArtistIds') List<String> artistIds = const [],
    @Query('GenreIds') List<String> genreIds = const [],
    @Query('Filters') List<String> filters = const [],
    @Query('IncludeItemTypes') String type = 'Audio',
    @Query('SortBy')
    String sortBy = 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
    @Query('SortOrder') String sortOrder = 'Ascending',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '300',
    @Query('Recursive') bool recursive = true,
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> getAlbums({
    @Path('userId') required String userId,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'MusicAlbum',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'DateCreated,SortName',
    @Query('ContributingArtistIds') String? contributingArtistIds,
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('AlbumArtistIds') List<String> artistIds = const [],
    @Query('GenreIds') List<String> genreIds = const [],
    @Query('Filters') List<String> filters = const [],
    @Query('Ids') List<String> ids = const [],
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Albums/{albumId}/Similar')
  Future<HttpResponse<ItemsWrapper>> getSimilarAlbums({
    @Path('albumId') required String albumId,
    @Query('UserId') required String userId,
    @Query('Limit') String limit = '12',
  });

  @GET('/MusicGenres')
  Future<HttpResponse<ItemsWrapper>> getGenres({
    @Query('UserId') required String userId,
    @Query('ParentId') String? libraryId,
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'SortName',
    @Query('SortOrder') String sortOrder = 'Ascending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> searchSongs({
    @Path('userId') required String userId,
    @Query('SearchTerm') required String searchTerm,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'Audio',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> searchAlbums({
    @Path('userId') required String userId,
    @Query('SearchTerm') required String searchTerm,
    @Query('ParentId') String? libraryId,
    @Query('IncludeItemTypes') String type = 'MusicAlbum',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<ItemsWrapper>> getPlaylists({
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
  Future<HttpResponse<ItemsWrapper>> searchPlaylists({
    @Path('userId') required String userId,
    @Query('ParentId') required String libraryId,
    @Query('SearchTerm') required String searchTerm,
    @Query('IncludeItemTypes') String type = 'Playlist',
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Playlists/{playlistId}/Items')
  Future<HttpResponse<ItemsWrapper>> getPlaylistSongs({
    @Path('playlistId') required String playlistId,
    @Query('UserId') required String userId,
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Users/{userId}/Items/{itemId}')
  Future<HttpResponse<ItemDTO>> getItem({
    @Path('userId') required String userId,
    @Path('itemId') required String itemId,
    @Query('Fields') List<String> fields = const ['MediaSources'],
  });

  @GET('/Items/{itemId}/{mediaSourceId}/Subtitles/{index}/Stream.js')
  @DioResponseType(ResponseType.plain)
  Future<HttpResponse<String>> getSubtitleTrack({
    @Path('itemId') required String itemId,
    @Path('mediaSourceId') required String mediaSourceId,
    @Path('index') required int index,
  });

  @POST('/Playlists')
  Future<HttpResponse<void>> createPlaylist({
    @Body() required PlaylistData values,
    @Query('MediaType') String mediaType = 'Audio',
  });

  @POST('/Items/{playlistId}/Delete')
  Future<HttpResponse<void>> deletePlaylist({
    @Path('playlistId') required String playlistId,
  });

  @POST('/Playlists/{playlistId}/Items')
  Future<HttpResponse<void>> addPlaylistItems({
    @Path('playlistId') required String playlistId,
    @Query('UserId') required String userId,
    @Query('Ids') required String entryIds,
  });

  @POST('/Playlists/{playlistId}/Items/Delete')
  Future<HttpResponse<void>> removePlaylistItem({
    @Path('playlistId') required String playlistId,
    @Query('EntryIds') required String entryIds,
  });

  @GET('/Artists')
  Future<HttpResponse<ItemsWrapper>> getArtists({
    @Query('UserId') required String userId,
    @Query('Fields') List<String> fields = const ['Overview'],
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortBy') String sortBy = 'SortName',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
    @Query('Filters') List<String> filters = const [],
  });

  @GET('/Artists')
  Future<HttpResponse<ItemsWrapper>> searchArtists({
    @Query('UserId') required String userId,
    @Query('SearchTerm') required String searchTerm,
    @Query('Fields') List<String> fields = const ['Overview'],
    @Query('StartIndex') String startIndex = '0',
    @Query('Limit') String limit = '100',
    @Query('SortOrder') String sortOrder = 'Descending',
    @Query('Recursive') bool recursive = true,
  });

  @GET('/Users/{userId}/Views')
  Future<HttpResponse<ItemsWrapper>> getLibraries({
    @Path('userId') required String userId,
  });

  @POST('/Sessions/Playing')
  Future<HttpResponse<void>> playbackStarted({
    @Body() required PlaystateData values,
  });

  @POST('/Sessions/Playing/Progress')
  Future<HttpResponse<void>> playbackProgress({
    @Body() required PlaystateData values,
  });

  @POST('/Sessions/Playing/Stopped')
  Future<HttpResponse<void>> playbackStopped({
    @Body() required PlaystateData values,
  });

  @POST('/Sessions/Logout')
  Future<HttpResponse<void>> signOut();
}
