// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jellyfin_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element

class _JellyfinApi implements JellyfinApi {
  _JellyfinApi(
    this._dio, {
    this.baseUrl,
  });

  final Dio _dio;

  String? baseUrl;

  @override
  Future<HttpResponse<UserDTO>> signIn(Map<String, dynamic> credentials) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(credentials);
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<UserDTO>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/AuthenticateByName',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = UserDTO.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<void> saveFavorite({
    required String userId,
    required String itemId,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/Users/${userId}/FavoriteItems/${itemId}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String itemId,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    await _dio.fetch<void>(_setStreamType<void>(Options(
      method: 'DELETE',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/Users/${userId}/FavoriteItems/${itemId}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        ))));
  }

  @override
  Future<HttpResponse<SongsWrapper>> getSongs({
    required String userId,
    required String albumId,
    String includeType = 'music',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ParentId': albumId,
      r'IncludeItemTypes': includeType,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<SongsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Items',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = SongsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> getAlbums({
    required String userId,
    required String libraryId,
    String type = 'MusicAlbum',
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ParentId': libraryId,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortBy': sortBy,
      r'ContributingArtistIds': contributingArtistIds,
      r'SortOrder': sortOrder,
      r'AlbumArtistIds': artistIds,
      r'Recursive': recursive,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Items',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> searchAlbums({
    required String userId,
    required String libraryId,
    required String searchTerm,
    String type = 'MusicAlbum',
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ParentId': libraryId,
      r'searchTerm': searchTerm,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortOrder': sortOrder,
      r'Recursive': recursive,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Items',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> getPlaylists({
    required String userId,
    required String libraryId,
    String type = 'Playlist',
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ParentId': libraryId,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortBy': sortBy,
      r'ContributingArtistIds': contributingArtistIds,
      r'SortOrder': sortOrder,
      r'AlbumArtistIds': artistIds,
      r'Recursive': recursive,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Items',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> searchPlaylists({
    required String userId,
    required String libraryId,
    required String searchTerm,
    String type = 'Playlist',
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'ParentId': libraryId,
      r'searchTerm': searchTerm,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortOrder': sortOrder,
      r'Recursive': recursive,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Items',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> getArtists({
    required String userId,
    List<String> fields = const ['BackdropImageTags', 'Overview'],
    bool includeArtists = true,
    String type = 'Artist',
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Descending',
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'userId': userId,
      r'Fields': fields,
      r'IncludeArtists': includeArtists,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortBy': sortBy,
      r'SortOrder': sortOrder,
      r'Recursive': recursive,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Artists',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<AlbumsWrapper>> searchArtists({
    required String userId,
    required String searchTerm,
    List<String> fields = const ['BackdropImageTags', 'Overview'],
    bool includeArtists = true,
    String type = 'Artist',
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
    bool recursive = true,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'userId': userId,
      r'searchTerm': searchTerm,
      r'Fields': fields,
      r'IncludeArtists': includeArtists,
      r'IncludeItemTypes': type,
      r'StartIndex': startIndex,
      r'Limit': limit,
      r'SortOrder': sortOrder,
      r'Recursive': recursive,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<AlbumsWrapper>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Artists',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = AlbumsWrapper.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<Libraries>> getLibraries({required String userId}) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<HttpResponse<Libraries>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/Users/${userId}/Views',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final _value = Libraries.fromJson(_result.data!);
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
