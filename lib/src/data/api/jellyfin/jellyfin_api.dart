import 'package:dio/dio.dart';
import 'package:jplayer/src/data/dto/album/album_dto.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'jellyfin_api.g.dart';

@RestApi(parser: Parser.JsonSerializable)
abstract class JellyfinApi {
  factory JellyfinApi(
    Dio client, {
    String baseUrl,
  }) = _JellyfinApi;

  // @POST('/users')
  // Future<HttpResponse<UserDTO>> signUp(
  //   @Body() UserDataWrapper data,
  // );

  @POST('/Users/AuthenticateByName')
  Future<HttpResponse<UserDTO>> signIn(
    @Body() Map<String, dynamic> credentials,
  );

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<SongsWrapper>> getSongs({@Path('userId') required String userId, @Query('ParentId') required String albumId});

  @GET('/Users/{userId}/Items')
  Future<HttpResponse<AlbumsWrapper>> getAlbums(
      {@Path('userId') required String userId,
      @Query('ParentId') required String libraryId,
      @Query('IncludeItemTypes') String type = 'MusicAlbum',
      @Query('StartIndex') String startIndex = '0',
      @Query('Limit') String limit = '100',
      @Query('SortBy') String soryBy = 'DateCreated,SortName',
      @Query('SortOrder') String sortOrder = 'Descending',
      @Query('Recursive') bool recursive = true});

  @GET('/Library/MediaFolders')
  Future<HttpResponse<Libraries>> getLibraries();
}
