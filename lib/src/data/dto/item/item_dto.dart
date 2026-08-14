import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/dto/media/media_source_dto.dart';

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
    // @JsonKey(name: 'ArtistItems') @Default([]) List<ArtistDTO> artists,
    @JsonKey(name: 'AlbumId') String? albumId,
    @JsonKey(name: 'AlbumPrimaryImageTag') String? albumPrimaryImageTag,
    @JsonKey(name: 'Album') String? albumName,
    @JsonKey(name: 'AlbumArtist') String? albumArtist,
    @JsonKey(name: 'AlbumArtists') @Default([]) List<ArtistDTO> albumArtists,
    @JsonKey(name: 'BackdropImageTags')
    @Default([])
    List<String> backdropImageTags,
    @JsonKey(name: 'ImageTags') @Default({}) Map<String, String> imageTags,
    @JsonKey(name: 'HasLyrics') @Default(false) bool hasLyrics,
    @JsonKey(name: 'UserData') @Default(UserData()) UserData userData,
    @JsonKey(name: 'MediaSources')
    @Default([])
    List<MediaSourceDTO> mediaSources,
  }) = _ItemDTO;

  const ItemDTO._();

  factory ItemDTO.fromJson(Map<String, dynamic> json) =>
      _$ItemDTOFromJson(json);

  Duration get duration => Duration(seconds: runTimeTicks ~/ 10000000);
}
