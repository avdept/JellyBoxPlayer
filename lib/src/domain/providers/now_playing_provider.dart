import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

MediaItem mediaItemFor(
  LibraryItem song, {
  LibraryItem? album,
  ImageService? images,
}) {
  final audioSource = song.audioSources.firstOrNull;
  final artistId =
      song.albumArtists.firstOrNull?.id ?? album?.albumArtists.firstOrNull?.id;

  return MediaItem(
    id: song.id,
    album: song.albumName ?? album?.name,
    artist: song.albumArtist ?? album?.albumArtist,
    duration: song.duration,
    title: song.name,
    artUri: images == null
        ? null
        : images.itemUri(song) ??
              (album == null ? null : images.itemUri(album)),
    extras: {
      if (audioSource?.codec != null) 'codec': audioSource!.codec,
      if (audioSource?.bitRate != null) 'bitRate': audioSource!.bitRate,
      if (audioSource?.sampleRate != null)
        'sampleRate': audioSource!.sampleRate,
      'artistId': ?artistId,
    },
  );
}

final nowPlayingQueueProvider = Provider<List<MediaItem>>((ref) {
  final playback = ref.watch(playbackProvider);
  if (playback.songs.isEmpty) return const [];
  final images = ref.watch(imageServiceProvider);
  return [
    for (final song in playback.songs)
      mediaItemFor(song, album: playback.album, images: images),
  ];
});

final nowPlayingProvider = Provider<MediaItem?>((ref) {
  final index = ref.watch(playbackProvider.select((s) => s.currentMediaIndex));
  if (index == null || index < 0) return null;
  return ref.watch(nowPlayingQueueProvider).elementAtOrNull(index);
});

final hasQueueProvider = Provider<bool>(
  (ref) => ref.watch(playbackProvider.select((s) => s.songs.isNotEmpty)),
);
