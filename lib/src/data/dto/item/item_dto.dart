import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@freezed
class ItemDTO with _$ItemDTO {

  const factory ItemDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'ServerId') required String serverId,
    @JsonKey(name: 'RunTimeTicks') required int durationInTicks, @JsonKey(name: 'ProductionYear') int? productionYear,
    @JsonKey(name: 'AlbumArtist') String? albumArtist,
    @Default({}) @JsonKey(name: 'ImageTags') Map<String, String> imageTags,
  }) = _ItemDTO;
  const ItemDTO._();

  factory ItemDTO.fromJson(Map<String, dynamic> json) => _$ItemDTOFromJson(json);

  Duration get duration => Duration(seconds: (durationInTicks / 10000000).ceil());
}
