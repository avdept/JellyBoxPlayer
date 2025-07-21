import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/json_converters/json_converters.dart';

part 'songs_dto.freezed.dart';
part 'songs_dto.g.dart';

@freezed
abstract class SongDTO with _$SongDTO {
  const factory SongDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'RunTimeTicks') required int runTimeTicks,
    @JsonKey(name: 'IndexNumber') @Default(0) int indexNumber,
    @JsonKey(name: 'UserData') required SongUserData songUserData,
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'AlbumArtist') String? albumArtist,
    @JsonKey(name: 'PlaylistItemId') String? playlistItemId,
    @JsonKey(name: 'AlbumArtists') List<ArtistDTO>? albumArtists,
    @JsonKey(name: 'Album') String? albumName,
    @JsonKey(name: 'AlbumId') String? albumId,
    @JsonKey(name: 'Name') String? name,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _SongDTO;

  factory SongDTO.fromJson(Map<String, dynamic> json) =>
      _$SongDTOFromJson(json);
}

@freezed
abstract class SongsWrapper with _$SongsWrapper {
  const factory SongsWrapper({
    @JsonKey(name: 'Items') required List<SongDTO> items,
  }) = _SongsWrapper;

  factory SongsWrapper.fromJson(Map<String, dynamic> json) =>
      _$SongsWrapperFromJson(json);
}

@freezed
abstract class SongUserData with _$SongUserData {
  const factory SongUserData({
    @JsonKey(name: 'PlaybackPositionTicks') required int playbackPositionTicks,
    @JsonKey(name: 'PlayCount') required int playCount,
    @JsonKey(name: 'IsFavorite') required bool isFavorite,
    @JsonKey(name: 'Played') required bool played,
  }) = _SongUserData;

  factory SongUserData.fromJson(Map<String, dynamic> json) =>
      _$SongUserDataFromJson(json);
}

@Freezed(copyWith: false)
abstract class DownloadedSongDTO extends _SongDTO with _$DownloadedSongDTO {
  factory DownloadedSongDTO({
    required String id,
    required int runTimeTicks,
    @Default(0) int indexNumber,
    required SongUserData songUserData,
    required String type,
    String? albumArtist,
    String? playlistItemId,
    // @Default([]) List<ArtistDTO> albumArtists,
    String? albumName,
    String? albumId,
    String? name,
    @Default({}) Map<String, String> imageTags,
    DateTime? downloadDate,
    @JsonKey(name: 'FilePath') required String filePath,
    @JsonKey(name: 'SizeInBytes') required int sizeInBytes,
  }) = _DownloadedSongDTO;

  factory DownloadedSongDTO.fromJson(Map<String, dynamic> json) =>
      _$DownloadedSongDTOFromJson(json);

  factory DownloadedSongDTO.fromSong(
    SongDTO song, {
    DateTime? downloadDate,
    required String filePath,
    required int sizeInBytes,
  }) {
    return _DownloadedSongDTO(
      id: song.id,
      runTimeTicks: song.runTimeTicks,
      indexNumber: song.indexNumber,
      songUserData: song.songUserData,
      type: song.type,
      albumArtist: song.albumArtist,
      playlistItemId: song.playlistItemId,
      // albumArtists: album.albumArtists,
      albumName: song.albumName,
      albumId: song.albumId,
      name: song.name,
      imageTags: song.imageTags,
      downloadDate: downloadDate,
      filePath: filePath,
      sizeInBytes: sizeInBytes,
    );
  }

  DownloadedSongDTO._({
    required super.id,
    required super.runTimeTicks,
    required super.indexNumber,
    required super.type,
    required super.albumArtist,
    required super.playlistItemId,
    // required super.albumArtists,
    required super.albumName,
    required super.albumId,
    required super.name,
    required this.songUserData,
    required this.imageTags,
    DateTime? downloadDate,
  }) : downloadDate = downloadDate ?? DateTime.now(),
       super(songUserData: songUserData);

  @override
  @SongUserDataConverter()
  @JsonKey(name: 'UserData')
  final SongUserData songUserData;

  @override
  @TagsMapConverter()
  @Default({})
  @JsonKey(name: 'ImageTags')
  final Map<String, String> imageTags;

  @override
  @EpochDateTimeConverter()
  @JsonKey(name: 'DownloadDate')
  final DateTime downloadDate;
}
