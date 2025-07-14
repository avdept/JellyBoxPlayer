import 'package:freezed_annotation/freezed_annotation.dart';

part 'downloaded_album_dto.freezed.dart';
part 'downloaded_album_dto.g.dart';

@freezed
abstract class DownloadedAlbumDTO with _$DownloadedAlbumDTO {
  const factory DownloadedAlbumDTO({
    required String id,
    required String name,
    required String? artistName,
    required Map<String, String> imageTags,
    required DateTime downloadDate,
    required int sizeInBytes,
  }) = _DownloadedAlbumDTO;

  factory DownloadedAlbumDTO.fromJson(Map<String, dynamic> json) =>
      _$DownloadedAlbumDTOFromJson(json);
}
