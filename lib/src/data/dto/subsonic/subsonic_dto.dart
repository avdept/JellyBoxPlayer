import 'package:freezed_annotation/freezed_annotation.dart';

part 'subsonic_dto.freezed.dart';
part 'subsonic_dto.g.dart';

String subsonicIdFromJson(Object? value) => value?.toString() ?? '';

String? subsonicOptionalIdFromJson(Object? value) => value?.toString();

@freezed
abstract class SubsonicErrorDTO with _$SubsonicErrorDTO {
  const factory SubsonicErrorDTO({int? code, String? message}) =
      _SubsonicErrorDTO;

  factory SubsonicErrorDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicErrorDTOFromJson(json);
}

@freezed
abstract class SubsonicEnvelopeDTO with _$SubsonicEnvelopeDTO {
  const factory SubsonicEnvelopeDTO({
    @Default('') String status,
    String? version,
    String? type,
    String? serverVersion,
    bool? openSubsonic,
    SubsonicErrorDTO? error,
  }) = _SubsonicEnvelopeDTO;

  const SubsonicEnvelopeDTO._();

  factory SubsonicEnvelopeDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicEnvelopeDTOFromJson(json);

  static const key = 'subsonic-response';

  bool get isFailed => status == 'failed';
}

@freezed
abstract class SubsonicNamedDTO with _$SubsonicNamedDTO {
  const factory SubsonicNamedDTO({@Default('') String name}) =
      _SubsonicNamedDTO;

  factory SubsonicNamedDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicNamedDTOFromJson(json);
}

@freezed
abstract class SubsonicArtistRefDTO with _$SubsonicArtistRefDTO {
  const factory SubsonicArtistRefDTO({
    @JsonKey(fromJson: subsonicIdFromJson) @Default('') String id,
    @Default('') String name,
  }) = _SubsonicArtistRefDTO;

  factory SubsonicArtistRefDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistRefDTOFromJson(json);
}

@freezed
abstract class SubsonicChildDTO with _$SubsonicChildDTO {
  const factory SubsonicChildDTO({
    @JsonKey(fromJson: subsonicIdFromJson) required String id,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? parent,
    @Default(false) bool isDir,
    @Default('') String title,
    String? album,
    String? artist,
    int? track,
    int? year,
    String? genre,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt,
    int? size,
    String? contentType,
    String? suffix,
    String? transcodedContentType,
    String? transcodedSuffix,
    int? duration,
    int? bitRate,
    int? bitDepth,
    int? samplingRate,
    int? channelCount,
    String? path,
    int? discNumber,
    DateTime? created,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? albumId,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId,
    String? type,
    String? starred,
    @Default(0) int playCount,
    String? played,
    int? userRating,
    String? musicBrainzId,
    String? displayArtist,
    String? displayAlbumArtist,
    String? sortName,
    @Default([]) List<SubsonicNamedDTO> genres,
    @Default([]) List<SubsonicArtistRefDTO> artists,
    @Default([]) List<SubsonicArtistRefDTO> albumArtists,
  }) = _SubsonicChildDTO;

  factory SubsonicChildDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicChildDTOFromJson(json);
}

@freezed
abstract class SubsonicAlbumDTO with _$SubsonicAlbumDTO {
  const factory SubsonicAlbumDTO({
    @JsonKey(fromJson: subsonicIdFromJson) required String id,
    @Default('') String name,
    String? artist,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? artistId,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt,
    @Default(0) int songCount,
    int? duration,
    @Default(0) int playCount,
    DateTime? created,
    String? starred,
    int? year,
    String? genre,
    String? played,
    int? userRating,
    String? musicBrainzId,
    String? displayArtist,
    String? sortName,
    bool? isCompilation,
    @Default([]) List<SubsonicNamedDTO> genres,
    @Default([]) List<SubsonicArtistRefDTO> artists,
    @Default([]) List<SubsonicChildDTO> song,
  }) = _SubsonicAlbumDTO;

  factory SubsonicAlbumDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicAlbumDTOFromJson(json);
}

@freezed
abstract class SubsonicArtistDTO with _$SubsonicArtistDTO {
  const factory SubsonicArtistDTO({
    @JsonKey(fromJson: subsonicIdFromJson) required String id,
    @Default('') String name,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt,
    String? artistImageUrl,
    @Default(0) int albumCount,
    String? starred,
    String? musicBrainzId,
    String? sortName,
    int? userRating,
    @Default([]) List<SubsonicAlbumDTO> album,
  }) = _SubsonicArtistDTO;

  factory SubsonicArtistDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistDTOFromJson(json);
}

@freezed
abstract class SubsonicArtistInfoDTO with _$SubsonicArtistInfoDTO {
  const factory SubsonicArtistInfoDTO({
    String? biography,
    String? musicBrainzId,
    String? lastFmUrl,
    String? smallImageUrl,
    String? mediumImageUrl,
    String? largeImageUrl,
    @Default([]) List<SubsonicArtistDTO> similarArtist,
  }) = _SubsonicArtistInfoDTO;

  factory SubsonicArtistInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistInfoDTOFromJson(json);
}

@freezed
abstract class SubsonicIndexDTO with _$SubsonicIndexDTO {
  const factory SubsonicIndexDTO({
    @Default('') String name,
    @Default([]) List<SubsonicArtistDTO> artist,
  }) = _SubsonicIndexDTO;

  factory SubsonicIndexDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicIndexDTOFromJson(json);
}

@freezed
abstract class SubsonicArtistsDTO with _$SubsonicArtistsDTO {
  const factory SubsonicArtistsDTO({
    String? ignoredArticles,
    @Default([]) List<SubsonicIndexDTO> index,
  }) = _SubsonicArtistsDTO;

  factory SubsonicArtistsDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistsDTOFromJson(json);
}

@freezed
abstract class SubsonicPlaylistDTO with _$SubsonicPlaylistDTO {
  const factory SubsonicPlaylistDTO({
    @JsonKey(fromJson: subsonicIdFromJson) required String id,
    @Default('') String name,
    String? comment,
    String? owner,
    @Default(false) bool public,
    @Default(0) int songCount,
    int? duration,
    DateTime? created,
    DateTime? changed,
    @JsonKey(fromJson: subsonicOptionalIdFromJson) String? coverArt,
    @Default([]) List<SubsonicChildDTO> entry,
  }) = _SubsonicPlaylistDTO;

  factory SubsonicPlaylistDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicPlaylistDTOFromJson(json);
}

@freezed
abstract class SubsonicPlaylistsDTO with _$SubsonicPlaylistsDTO {
  const factory SubsonicPlaylistsDTO({
    @Default([]) List<SubsonicPlaylistDTO> playlist,
  }) = _SubsonicPlaylistsDTO;

  factory SubsonicPlaylistsDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicPlaylistsDTOFromJson(json);
}

@freezed
abstract class SubsonicGenreDTO with _$SubsonicGenreDTO {
  const factory SubsonicGenreDTO({
    @Default('') String value,
    @Default(0) int songCount,
    @Default(0) int albumCount,
  }) = _SubsonicGenreDTO;

  factory SubsonicGenreDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicGenreDTOFromJson(json);
}

@freezed
abstract class SubsonicGenresDTO with _$SubsonicGenresDTO {
  const factory SubsonicGenresDTO({
    @Default([]) List<SubsonicGenreDTO> genre,
  }) = _SubsonicGenresDTO;

  factory SubsonicGenresDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicGenresDTOFromJson(json);
}

@freezed
abstract class SubsonicMusicFolderDTO with _$SubsonicMusicFolderDTO {
  const factory SubsonicMusicFolderDTO({
    @JsonKey(fromJson: subsonicIdFromJson) required String id,
    @Default('') String name,
  }) = _SubsonicMusicFolderDTO;

  factory SubsonicMusicFolderDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicMusicFolderDTOFromJson(json);
}

@freezed
abstract class SubsonicMusicFoldersDTO with _$SubsonicMusicFoldersDTO {
  const factory SubsonicMusicFoldersDTO({
    @Default([]) List<SubsonicMusicFolderDTO> musicFolder,
  }) = _SubsonicMusicFoldersDTO;

  factory SubsonicMusicFoldersDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicMusicFoldersDTOFromJson(json);
}

@freezed
abstract class SubsonicItemSetDTO with _$SubsonicItemSetDTO {
  const factory SubsonicItemSetDTO({
    @Default([]) List<SubsonicArtistDTO> artist,
    @Default([]) List<SubsonicAlbumDTO> album,
    @Default([]) List<SubsonicChildDTO> song,
  }) = _SubsonicItemSetDTO;

  factory SubsonicItemSetDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicItemSetDTOFromJson(json);
}

@freezed
abstract class SubsonicAlbumListDTO with _$SubsonicAlbumListDTO {
  const factory SubsonicAlbumListDTO({
    @Default([]) List<SubsonicAlbumDTO> album,
  }) = _SubsonicAlbumListDTO;

  factory SubsonicAlbumListDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicAlbumListDTOFromJson(json);
}

@freezed
abstract class SubsonicSongListDTO with _$SubsonicSongListDTO {
  const factory SubsonicSongListDTO({
    @Default([]) List<SubsonicChildDTO> song,
  }) = _SubsonicSongListDTO;

  factory SubsonicSongListDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicSongListDTOFromJson(json);
}

@freezed
abstract class SubsonicLyricLineDTO with _$SubsonicLyricLineDTO {
  const factory SubsonicLyricLineDTO({int? start, @Default('') String value}) =
      _SubsonicLyricLineDTO;

  factory SubsonicLyricLineDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicLyricLineDTOFromJson(json);
}

@freezed
abstract class SubsonicStructuredLyricsDTO with _$SubsonicStructuredLyricsDTO {
  const factory SubsonicStructuredLyricsDTO({
    String? lang,
    @Default(false) bool synced,
    int? offset,
    String? displayArtist,
    String? displayTitle,
    @Default([]) List<SubsonicLyricLineDTO> line,
  }) = _SubsonicStructuredLyricsDTO;

  factory SubsonicStructuredLyricsDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicStructuredLyricsDTOFromJson(json);
}

@freezed
abstract class SubsonicLyricsListDTO with _$SubsonicLyricsListDTO {
  const factory SubsonicLyricsListDTO({
    @Default([]) List<SubsonicStructuredLyricsDTO> structuredLyrics,
  }) = _SubsonicLyricsListDTO;

  factory SubsonicLyricsListDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicLyricsListDTOFromJson(json);
}

@freezed
abstract class SubsonicExtensionDTO with _$SubsonicExtensionDTO {
  const factory SubsonicExtensionDTO({
    @Default('') String name,
    @Default([]) List<int> versions,
  }) = _SubsonicExtensionDTO;

  factory SubsonicExtensionDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicExtensionDTOFromJson(json);
}

@freezed
abstract class SubsonicExtensionsDTO with _$SubsonicExtensionsDTO {
  const factory SubsonicExtensionsDTO({
    @Default([]) List<SubsonicExtensionDTO> openSubsonicExtensions,
  }) = _SubsonicExtensionsDTO;

  factory SubsonicExtensionsDTO.fromJson(Map<String, dynamic> json) =>
      _$SubsonicExtensionsDTOFromJson(json);
}
