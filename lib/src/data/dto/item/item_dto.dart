import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/json_converters/json_converters.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@freezed
sealed class ItemDTO with _$ItemDTO {
  const factory ItemDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'ServerId') required String serverId,
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'Overview') String? overview,
    @JsonKey(name: 'RunTimeTicks') required int? durationInTicks,
    @JsonKey(name: 'ProductionYear') int? productionYear,
    @JsonKey(name: 'AlbumArtist') String? albumArtist,
    @Default([]) @JsonKey(name: 'AlbumArtists') List<ArtistDTO> albumArtists,
    @Default([]) @JsonKey(name: 'BackdropImageTags') List<String> backdropImageTags,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _ItemDTO;

  const ItemDTO._();

  factory ItemDTO.fromJson(Map<String, dynamic> json) => _$ItemDTOFromJson(json);

  Duration get duration => durationInTicks == null ? Duration.zero : Duration(seconds: (durationInTicks! / 10000000).ceil());
}

@Freezed(copyWith: false)
abstract class DownloadedAlbumDTO extends _ItemDTO with _$DownloadedAlbumDTO {
  factory DownloadedAlbumDTO({
    required String id,
    required String name,
    required String serverId,
    required String type,
    String? overview,
    required int? durationInTicks,
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
      serverId: album.serverId,
      type: album.type,
      overview: album.overview,
      durationInTicks: album.durationInTicks,
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
    required super.serverId,
    required super.type,
    required super.overview,
    required super.durationInTicks,
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
