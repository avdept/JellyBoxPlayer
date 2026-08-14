import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_ref.freezed.dart';
part 'artist_ref.g.dart';

@freezed
abstract class ArtistRef with _$ArtistRef {
  const factory ArtistRef({required String id, required String name}) =
      _ArtistRef;

  factory ArtistRef.fromJson(Map<String, dynamic> json) =>
      _$ArtistRefFromJson(json);
}
