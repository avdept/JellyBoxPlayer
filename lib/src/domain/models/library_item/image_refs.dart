import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_refs.freezed.dart';
part 'image_refs.g.dart';

@freezed
abstract class ImageRefs with _$ImageRefs {
  const factory ImageRefs({
    String? primary,
    String? primaryItemId,
    String? albumPrimary,
    @Default([]) List<String> backdrops,
  }) = _ImageRefs;

  const ImageRefs._();

  factory ImageRefs.fromJson(Map<String, dynamic> json) =>
      _$ImageRefsFromJson(json);

  bool get hasCover => primary != null || albumPrimary != null;

  bool get hasBackdrop => backdrops.isNotEmpty;
}
