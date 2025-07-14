import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';

part 'downloaded_item_dto.freezed.dart';
part 'downloaded_item_dto.g.dart';

@freezed
abstract class DownloadedItemDTO with _$DownloadedItemDTO {
  const factory DownloadedItemDTO({
    required String id,
    required String? name,
    required String? albumId,
    required String? albumName,
    required String? artistName,
    required DateTime downloadDate,
    required String filePath,
    required int sizeInBytes,
  }) = _DownloadedItemDTO;

  factory DownloadedItemDTO.fromJson(Map<String, dynamic> json) =>
      _$DownloadedItemDTOFromJson(json);

  factory DownloadedItemDTO.fromSong(
    SongDTO song, {
    required String filePath,
    required int sizeInBytes,
  }) {
    return DownloadedItemDTO(
      id: song.id,
      name: song.name,
      albumId: song.albumId,
      albumName: song.albumName,
      artistName: song.albumArtist,
      downloadDate: DateTime.now(),
      filePath: filePath,
      sizeInBytes: sizeInBytes,
    );
  }
}
