import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/domain/models/library_item/artist_ref.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';
import 'package:jplayer/src/domain/models/library_item/image_refs.dart';
import 'package:jplayer/src/domain/models/library_item/item_kind.dart';
import 'package:jplayer/src/domain/models/library_item/playback_user_data.dart';

part 'library_item.freezed.dart';

@freezed
abstract class LibraryItem with _$LibraryItem {
  const factory LibraryItem({
    required String id,
    required String name,
    required ItemKind kind,
    @Default(0) int indexNumber,
    @Default(Duration.zero) Duration duration,
    String? path,
    String? collectionType,
    String? playlistItemId,
    String? overview,
    int? productionYear,
    String? albumId,
    String? albumName,
    String? albumArtist,
    @Default([]) List<ArtistRef> albumArtists,
    @Default([]) List<String> genres,
    @Default(ImageRefs()) ImageRefs images,
    @Default(false) bool hasLyrics,
    @Default(PlaybackUserData()) PlaybackUserData userData,
    @Default([]) List<AudioSourceInfo> audioSources,
  }) = _LibraryItem;

  const LibraryItem._();

  String get primaryImageId => images.primaryItemId ?? id;

  // ignore: prefer_constructors_over_static_methods
  static LibraryItem fromJson(Map<String, dynamic> json) => LibraryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: ItemKind.values.byName(json['kind'] as String),
    indexNumber: json['indexNumber'] as int? ?? 0,
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    path: json['path'] as String?,
    collectionType: json['collectionType'] as String?,
    playlistItemId: json['playlistItemId'] as String?,
    overview: json['overview'] as String?,
    productionYear: json['productionYear'] as int?,
    albumId: json['albumId'] as String?,
    albumName: json['albumName'] as String?,
    albumArtist: json['albumArtist'] as String?,
    albumArtists: (json['albumArtists'] as List<dynamic>? ?? [])
        .map((e) => ArtistRef.fromJson(e as Map<String, dynamic>))
        .toList(),
    genres: (json['genres'] as List<dynamic>? ?? []).cast<String>(),
    images: json['images'] != null
        ? ImageRefs.fromJson(json['images'] as Map<String, dynamic>)
        : const ImageRefs(),
    hasLyrics: json['hasLyrics'] as bool? ?? false,
    userData: json['userData'] != null
        ? PlaybackUserData.fromJson(json['userData'] as Map<String, dynamic>)
        : const PlaybackUserData(),
    audioSources: (json['audioSources'] as List<dynamic>? ?? [])
        .map((e) => AudioSourceInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

extension LibraryItemJson on LibraryItem {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'indexNumber': indexNumber,
    'durationMs': duration.inMilliseconds,
    'path': path,
    'collectionType': collectionType,
    'playlistItemId': playlistItemId,
    'overview': overview,
    'productionYear': productionYear,
    'albumId': albumId,
    'albumName': albumName,
    'albumArtist': albumArtist,
    'albumArtists': albumArtists.map((artist) => artist.toJson()).toList(),
    'genres': genres,
    'images': images.toJson(),
    'hasLyrics': hasLyrics,
    'userData': userData.toJson(),
    'audioSources': audioSources.map((source) => source.toJson()).toList(),
  };
}
