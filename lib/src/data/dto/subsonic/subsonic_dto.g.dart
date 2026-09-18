// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subsonic_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubsonicErrorDTO _$SubsonicErrorDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicErrorDTO(
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$SubsonicErrorDTOToJson(_SubsonicErrorDTO instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};

_SubsonicEnvelopeDTO _$SubsonicEnvelopeDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicEnvelopeDTO(
      status: json['status'] as String? ?? '',
      version: json['version'] as String?,
      type: json['type'] as String?,
      serverVersion: json['serverVersion'] as String?,
      openSubsonic: json['openSubsonic'] as bool?,
      error: json['error'] == null
          ? null
          : SubsonicErrorDTO.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubsonicEnvelopeDTOToJson(
  _SubsonicEnvelopeDTO instance,
) => <String, dynamic>{
  'status': instance.status,
  'version': instance.version,
  'type': instance.type,
  'serverVersion': instance.serverVersion,
  'openSubsonic': instance.openSubsonic,
  'error': instance.error,
};

_SubsonicNamedDTO _$SubsonicNamedDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicNamedDTO(name: json['name'] as String? ?? '');

Map<String, dynamic> _$SubsonicNamedDTOToJson(_SubsonicNamedDTO instance) =>
    <String, dynamic>{'name': instance.name};

_SubsonicArtistRefDTO _$SubsonicArtistRefDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicArtistRefDTO(
  id: json['id'] == null ? '' : subsonicIdFromJson(json['id']),
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$SubsonicArtistRefDTOToJson(
  _SubsonicArtistRefDTO instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_SubsonicChildDTO _$SubsonicChildDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicChildDTO(
  id: subsonicIdFromJson(json['id']),
  parent: subsonicOptionalIdFromJson(json['parent']),
  isDir: json['isDir'] as bool? ?? false,
  title: json['title'] as String? ?? '',
  album: json['album'] as String?,
  artist: json['artist'] as String?,
  track: (json['track'] as num?)?.toInt(),
  year: (json['year'] as num?)?.toInt(),
  genre: json['genre'] as String?,
  coverArt: subsonicOptionalIdFromJson(json['coverArt']),
  size: (json['size'] as num?)?.toInt(),
  contentType: json['contentType'] as String?,
  suffix: json['suffix'] as String?,
  transcodedContentType: json['transcodedContentType'] as String?,
  transcodedSuffix: json['transcodedSuffix'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  bitRate: (json['bitRate'] as num?)?.toInt(),
  bitDepth: (json['bitDepth'] as num?)?.toInt(),
  samplingRate: (json['samplingRate'] as num?)?.toInt(),
  channelCount: (json['channelCount'] as num?)?.toInt(),
  path: json['path'] as String?,
  discNumber: (json['discNumber'] as num?)?.toInt(),
  created: json['created'] == null
      ? null
      : DateTime.parse(json['created'] as String),
  albumId: subsonicOptionalIdFromJson(json['albumId']),
  artistId: subsonicOptionalIdFromJson(json['artistId']),
  type: json['type'] as String?,
  starred: json['starred'] as String?,
  playCount: (json['playCount'] as num?)?.toInt() ?? 0,
  played: json['played'] as String?,
  userRating: (json['userRating'] as num?)?.toInt(),
  musicBrainzId: json['musicBrainzId'] as String?,
  displayArtist: json['displayArtist'] as String?,
  displayAlbumArtist: json['displayAlbumArtist'] as String?,
  sortName: json['sortName'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => SubsonicNamedDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => SubsonicArtistRefDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  albumArtists:
      (json['albumArtists'] as List<dynamic>?)
          ?.map((e) => SubsonicArtistRefDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicChildDTOToJson(_SubsonicChildDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent': instance.parent,
      'isDir': instance.isDir,
      'title': instance.title,
      'album': instance.album,
      'artist': instance.artist,
      'track': instance.track,
      'year': instance.year,
      'genre': instance.genre,
      'coverArt': instance.coverArt,
      'size': instance.size,
      'contentType': instance.contentType,
      'suffix': instance.suffix,
      'transcodedContentType': instance.transcodedContentType,
      'transcodedSuffix': instance.transcodedSuffix,
      'duration': instance.duration,
      'bitRate': instance.bitRate,
      'bitDepth': instance.bitDepth,
      'samplingRate': instance.samplingRate,
      'channelCount': instance.channelCount,
      'path': instance.path,
      'discNumber': instance.discNumber,
      'created': instance.created?.toIso8601String(),
      'albumId': instance.albumId,
      'artistId': instance.artistId,
      'type': instance.type,
      'starred': instance.starred,
      'playCount': instance.playCount,
      'played': instance.played,
      'userRating': instance.userRating,
      'musicBrainzId': instance.musicBrainzId,
      'displayArtist': instance.displayArtist,
      'displayAlbumArtist': instance.displayAlbumArtist,
      'sortName': instance.sortName,
      'genres': instance.genres,
      'artists': instance.artists,
      'albumArtists': instance.albumArtists,
    };

_SubsonicAlbumDTO _$SubsonicAlbumDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicAlbumDTO(
      id: subsonicIdFromJson(json['id']),
      name: json['name'] as String? ?? '',
      artist: json['artist'] as String?,
      artistId: subsonicOptionalIdFromJson(json['artistId']),
      coverArt: subsonicOptionalIdFromJson(json['coverArt']),
      songCount: (json['songCount'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt(),
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      starred: json['starred'] as String?,
      year: (json['year'] as num?)?.toInt(),
      genre: json['genre'] as String?,
      played: json['played'] as String?,
      userRating: (json['userRating'] as num?)?.toInt(),
      musicBrainzId: json['musicBrainzId'] as String?,
      displayArtist: json['displayArtist'] as String?,
      sortName: json['sortName'] as String?,
      isCompilation: json['isCompilation'] as bool?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => SubsonicNamedDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map(
                (e) => SubsonicArtistRefDTO.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      song:
          (json['song'] as List<dynamic>?)
              ?.map((e) => SubsonicChildDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicAlbumDTOToJson(_SubsonicAlbumDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'coverArt': instance.coverArt,
      'songCount': instance.songCount,
      'duration': instance.duration,
      'playCount': instance.playCount,
      'created': instance.created?.toIso8601String(),
      'starred': instance.starred,
      'year': instance.year,
      'genre': instance.genre,
      'played': instance.played,
      'userRating': instance.userRating,
      'musicBrainzId': instance.musicBrainzId,
      'displayArtist': instance.displayArtist,
      'sortName': instance.sortName,
      'isCompilation': instance.isCompilation,
      'genres': instance.genres,
      'artists': instance.artists,
      'song': instance.song,
    };

_SubsonicArtistDTO _$SubsonicArtistDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicArtistDTO(
      id: subsonicIdFromJson(json['id']),
      name: json['name'] as String? ?? '',
      coverArt: subsonicOptionalIdFromJson(json['coverArt']),
      artistImageUrl: json['artistImageUrl'] as String?,
      albumCount: (json['albumCount'] as num?)?.toInt() ?? 0,
      starred: json['starred'] as String?,
      musicBrainzId: json['musicBrainzId'] as String?,
      sortName: json['sortName'] as String?,
      userRating: (json['userRating'] as num?)?.toInt(),
      album:
          (json['album'] as List<dynamic>?)
              ?.map((e) => SubsonicAlbumDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicArtistDTOToJson(_SubsonicArtistDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'coverArt': instance.coverArt,
      'artistImageUrl': instance.artistImageUrl,
      'albumCount': instance.albumCount,
      'starred': instance.starred,
      'musicBrainzId': instance.musicBrainzId,
      'sortName': instance.sortName,
      'userRating': instance.userRating,
      'album': instance.album,
    };

_SubsonicIndexDTO _$SubsonicIndexDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicIndexDTO(
      name: json['name'] as String? ?? '',
      artist:
          (json['artist'] as List<dynamic>?)
              ?.map(
                (e) => SubsonicArtistDTO.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicIndexDTOToJson(_SubsonicIndexDTO instance) =>
    <String, dynamic>{'name': instance.name, 'artist': instance.artist};

_SubsonicArtistsDTO _$SubsonicArtistsDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicArtistsDTO(
      ignoredArticles: json['ignoredArticles'] as String?,
      index:
          (json['index'] as List<dynamic>?)
              ?.map((e) => SubsonicIndexDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicArtistsDTOToJson(_SubsonicArtistsDTO instance) =>
    <String, dynamic>{
      'ignoredArticles': instance.ignoredArticles,
      'index': instance.index,
    };

_SubsonicPlaylistDTO _$SubsonicPlaylistDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicPlaylistDTO(
      id: subsonicIdFromJson(json['id']),
      name: json['name'] as String? ?? '',
      comment: json['comment'] as String?,
      owner: json['owner'] as String?,
      public: json['public'] as bool? ?? false,
      songCount: (json['songCount'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt(),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      changed: json['changed'] == null
          ? null
          : DateTime.parse(json['changed'] as String),
      coverArt: subsonicOptionalIdFromJson(json['coverArt']),
      entry:
          (json['entry'] as List<dynamic>?)
              ?.map((e) => SubsonicChildDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicPlaylistDTOToJson(
  _SubsonicPlaylistDTO instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'comment': instance.comment,
  'owner': instance.owner,
  'public': instance.public,
  'songCount': instance.songCount,
  'duration': instance.duration,
  'created': instance.created?.toIso8601String(),
  'changed': instance.changed?.toIso8601String(),
  'coverArt': instance.coverArt,
  'entry': instance.entry,
};

_SubsonicPlaylistsDTO _$SubsonicPlaylistsDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicPlaylistsDTO(
  playlist:
      (json['playlist'] as List<dynamic>?)
          ?.map((e) => SubsonicPlaylistDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicPlaylistsDTOToJson(
  _SubsonicPlaylistsDTO instance,
) => <String, dynamic>{'playlist': instance.playlist};

_SubsonicGenreDTO _$SubsonicGenreDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicGenreDTO(
      value: json['value'] as String? ?? '',
      songCount: (json['songCount'] as num?)?.toInt() ?? 0,
      albumCount: (json['albumCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SubsonicGenreDTOToJson(_SubsonicGenreDTO instance) =>
    <String, dynamic>{
      'value': instance.value,
      'songCount': instance.songCount,
      'albumCount': instance.albumCount,
    };

_SubsonicGenresDTO _$SubsonicGenresDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicGenresDTO(
      genre:
          (json['genre'] as List<dynamic>?)
              ?.map((e) => SubsonicGenreDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicGenresDTOToJson(_SubsonicGenresDTO instance) =>
    <String, dynamic>{'genre': instance.genre};

_SubsonicMusicFolderDTO _$SubsonicMusicFolderDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicMusicFolderDTO(
  id: subsonicIdFromJson(json['id']),
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$SubsonicMusicFolderDTOToJson(
  _SubsonicMusicFolderDTO instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_SubsonicMusicFoldersDTO _$SubsonicMusicFoldersDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicMusicFoldersDTO(
  musicFolder:
      (json['musicFolder'] as List<dynamic>?)
          ?.map(
            (e) => SubsonicMusicFolderDTO.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicMusicFoldersDTOToJson(
  _SubsonicMusicFoldersDTO instance,
) => <String, dynamic>{'musicFolder': instance.musicFolder};

_SubsonicItemSetDTO _$SubsonicItemSetDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicItemSetDTO(
      artist:
          (json['artist'] as List<dynamic>?)
              ?.map(
                (e) => SubsonicArtistDTO.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      album:
          (json['album'] as List<dynamic>?)
              ?.map((e) => SubsonicAlbumDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      song:
          (json['song'] as List<dynamic>?)
              ?.map((e) => SubsonicChildDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicItemSetDTOToJson(_SubsonicItemSetDTO instance) =>
    <String, dynamic>{
      'artist': instance.artist,
      'album': instance.album,
      'song': instance.song,
    };

_SubsonicAlbumListDTO _$SubsonicAlbumListDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicAlbumListDTO(
  album:
      (json['album'] as List<dynamic>?)
          ?.map((e) => SubsonicAlbumDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicAlbumListDTOToJson(
  _SubsonicAlbumListDTO instance,
) => <String, dynamic>{'album': instance.album};

_SubsonicSongListDTO _$SubsonicSongListDTOFromJson(Map<String, dynamic> json) =>
    _SubsonicSongListDTO(
      song:
          (json['song'] as List<dynamic>?)
              ?.map((e) => SubsonicChildDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubsonicSongListDTOToJson(
  _SubsonicSongListDTO instance,
) => <String, dynamic>{'song': instance.song};

_SubsonicLyricLineDTO _$SubsonicLyricLineDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicLyricLineDTO(
  start: (json['start'] as num?)?.toInt(),
  value: json['value'] as String? ?? '',
);

Map<String, dynamic> _$SubsonicLyricLineDTOToJson(
  _SubsonicLyricLineDTO instance,
) => <String, dynamic>{'start': instance.start, 'value': instance.value};

_SubsonicStructuredLyricsDTO _$SubsonicStructuredLyricsDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicStructuredLyricsDTO(
  lang: json['lang'] as String?,
  synced: json['synced'] as bool? ?? false,
  offset: (json['offset'] as num?)?.toInt(),
  displayArtist: json['displayArtist'] as String?,
  displayTitle: json['displayTitle'] as String?,
  line:
      (json['line'] as List<dynamic>?)
          ?.map((e) => SubsonicLyricLineDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicStructuredLyricsDTOToJson(
  _SubsonicStructuredLyricsDTO instance,
) => <String, dynamic>{
  'lang': instance.lang,
  'synced': instance.synced,
  'offset': instance.offset,
  'displayArtist': instance.displayArtist,
  'displayTitle': instance.displayTitle,
  'line': instance.line,
};

_SubsonicLyricsListDTO _$SubsonicLyricsListDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicLyricsListDTO(
  structuredLyrics:
      (json['structuredLyrics'] as List<dynamic>?)
          ?.map(
            (e) =>
                SubsonicStructuredLyricsDTO.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicLyricsListDTOToJson(
  _SubsonicLyricsListDTO instance,
) => <String, dynamic>{'structuredLyrics': instance.structuredLyrics};

_SubsonicExtensionDTO _$SubsonicExtensionDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicExtensionDTO(
  name: json['name'] as String? ?? '',
  versions:
      (json['versions'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicExtensionDTOToJson(
  _SubsonicExtensionDTO instance,
) => <String, dynamic>{'name': instance.name, 'versions': instance.versions};

_SubsonicExtensionsDTO _$SubsonicExtensionsDTOFromJson(
  Map<String, dynamic> json,
) => _SubsonicExtensionsDTO(
  openSubsonicExtensions:
      (json['openSubsonicExtensions'] as List<dynamic>?)
          ?.map((e) => SubsonicExtensionDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubsonicExtensionsDTOToJson(
  _SubsonicExtensionsDTO instance,
) => <String, dynamic>{
  'openSubsonicExtensions': instance.openSubsonicExtensions,
};
