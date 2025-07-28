import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/json_converters/json_converters.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@freezed
abstract class ItemDTO with _$ItemDTO {
  const factory ItemDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'IndexNumber') @Default(0) int indexNumber,
    @JsonKey(name: 'RunTimeTicks') @Default(0) int runTimeTicks,
    @JsonKey(name: 'Path') String? path,
    @JsonKey(name: 'CollectionType') String? collectionType,
    @JsonKey(name: 'PlaylistItemId') String? playlistItemId,
    @JsonKey(name: 'Overview') String? overview,
    @JsonKey(name: 'ProductionYear') int? productionYear,
    @JsonKey(name: 'AlbumId') String? albumId,
    @JsonKey(name: 'Album') String? albumName,
    @JsonKey(name: 'AlbumArtist') String? albumArtist,
    @JsonKey(name: 'AlbumArtists') @Default([]) List<ArtistDTO> albumArtists,
    @JsonKey(name: 'BackdropImageTags') @Default([]) List<String> backdropImageTags,
    @JsonKey(name: 'ImageTags') @Default({}) Map<String, String> imageTags,
    @JsonKey(name: 'UserData') @Default(UserData()) UserData userData,
  }) = _ItemDTO;

  const ItemDTO._();

  factory ItemDTO.fromJson(Map<String, dynamic> json) => _$ItemDTOFromJson(json);

  Duration get duration => Duration(seconds: runTimeTicks ~/ 10000000);
}

@Freezed(copyWith: false)
abstract class DownloadedAlbumDTO extends _ItemDTO with _$DownloadedAlbumDTO {
  factory DownloadedAlbumDTO({
    required String id,
    required String name,
    required String type,
    required int runTimeTicks,
    String? overview,
    int? productionYear,
    String? albumArtist,
    // @Default([]) List<ArtistDTO> albumArtists,
    @Default([]) List<String> backdropImageTags,
    @Default({}) Map<String, String> imageTags,
    DateTime? downloadDate,
    @JsonKey(name: 'SizeInBytes') required int sizeInBytes,
  }) = _DownloadedAlbumDTO;

  factory DownloadedAlbumDTO.fromJson(Map<String, dynamic> json) =>
      _$DownloadedAlbumDTOFromJson(json);

  factory DownloadedAlbumDTO.fromAlbum(
    ItemDTO album, {
    DateTime? downloadDate,
    required int sizeInBytes,
  }) {
    return _DownloadedAlbumDTO(
      id: album.id,
      name: album.name,
      runTimeTicks: album.runTimeTicks,
      type: album.type,
      overview: album.overview,
      productionYear: album.productionYear,
      albumArtist: album.albumArtist,
      // albumArtists: album.albumArtists,
      backdropImageTags: album.backdropImageTags,
      imageTags: album.imageTags,
      downloadDate: downloadDate,
      sizeInBytes: sizeInBytes,
    );
  }

  DownloadedAlbumDTO._({
    required super.id,
    required super.name,
    required super.runTimeTicks,
    required super.type,
    required super.overview,
    required super.productionYear,
    required super.albumArtist,
    // required super.albumArtists,
    required this.backdropImageTags,
    required this.imageTags,
    DateTime? downloadDate,
  }) : downloadDate = downloadDate ?? DateTime.now();

  @override
  @TagsListConverter()
  @JsonKey(name: 'BackdropImageTags')
  final List<String> backdropImageTags;

  @override
  @TagsMapConverter()
  @Default({}) @JsonKey(name: 'ImageTags')
  final Map<String, String> imageTags;

  @override
  @EpochDateTimeConverter()
  @JsonKey(name: 'DownloadDate')
  final DateTime downloadDate;
}

@Freezed(copyWith: false)
abstract class DownloadedSongDTO extends _ItemDTO with _$DownloadedSongDTO {
  factory DownloadedSongDTO({
    required String id,
    required String name,
    required int runTimeTicks,
    @Default(0) int indexNumber,
    required UserData userData,
    required String type,
    String? albumArtist,
    String? playlistItemId,
    // @Default([]) List<ArtistDTO> albumArtists,
    String? albumName,
    String? albumId,
    @Default({}) Map<String, String> imageTags,
    DateTime? downloadDate,
    @JsonKey(name: 'FilePath') required String filePath,
    @JsonKey(name: 'SizeInBytes') required int sizeInBytes,
  }) = _DownloadedSongDTO;

  factory DownloadedSongDTO.fromJson(Map<String, dynamic> json) =>
      _$DownloadedSongDTOFromJson(json);

  factory DownloadedSongDTO.fromSong(
      ItemDTO song, {
        DateTime? downloadDate,
        required String filePath,
        required int sizeInBytes,
      }) {
    return _DownloadedSongDTO(
      id: song.id,
      runTimeTicks: song.runTimeTicks,
      indexNumber: song.indexNumber,
      userData: song.userData,
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
    required this.userData,
    required this.imageTags,
    DateTime? downloadDate,
  }) : downloadDate = downloadDate ?? DateTime.now(),
        super(userData: userData);

  @override
  @UserDataConverter()
  @JsonKey(name: 'UserData')
  final UserData userData;

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
