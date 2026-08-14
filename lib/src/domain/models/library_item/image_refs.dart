import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_refs.freezed.dart';
part 'image_refs.g.dart';

/// Opaque image identifiers. Only the backend client that produced a
/// `LibraryItem` knows how to turn these tokens into a fetchable image URL.
@freezed
abstract class ImageRefs with _$ImageRefs {
  const factory ImageRefs({
    String? primary,
    String? albumPrimary,
    @Default([]) List<String> backdrops,
  }) = _ImageRefs;

  factory ImageRefs.fromJson(Map<String, dynamic> json) =>
      _$ImageRefsFromJson(json);
}
