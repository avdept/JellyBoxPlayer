import 'package:flutter/foundation.dart';
import 'package:jplayer/src/domain/models/models.dart';

@immutable
class Listen {
  const Listen({required this.song, required this.listenedAt, this.album});

  factory Listen.fromJson(Map<String, Object?> json) => Listen(
    song: LibraryItem.fromJson(json['song']! as Map<String, dynamic>),
    album: switch (json['album']) {
      final Map<String, dynamic> album => LibraryItem.fromJson(album),
      _ => null,
    },
    listenedAt: DateTime.parse(json['listenedAt']! as String),
  );

  final LibraryItem song;
  final LibraryItem? album;
  final DateTime listenedAt;

  Map<String, Object?> toJson() => {
    'song': song.toJson(),
    'album': album?.toJson(),
    'listenedAt': listenedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Listen &&
      other.song.id == song.id &&
      other.album?.id == album?.id &&
      other.listenedAt.isAtSameMomentAs(listenedAt);

  @override
  int get hashCode =>
      Object.hash(song.id, album?.id, listenedAt.microsecondsSinceEpoch);
}
