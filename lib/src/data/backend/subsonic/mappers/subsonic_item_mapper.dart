import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

const subsonicAlbumArtPrefix = 'al-';
const subsonicArtistArtPrefix = 'ar-';
const subsonicPlaylistArtPrefix = 'pl-';

String? subsonicCodecForSuffix(String? suffix, {int? bitDepth}) {
  final normalized = suffix?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return switch (normalized) {
    'mp3' => 'mp3',
    'flac' => 'flac',
    'wav' || 'wave' || 'aiff' || 'aif' => 'pcm',
    'ogg' || 'oga' => 'vorbis',
    'opus' => 'opus',
    'aac' => 'aac',
    'm4a' || 'm4b' || 'mp4' => (bitDepth ?? 0) > 0 ? 'alac' : 'aac',
    'wv' => 'wavpack',
    'dsf' || 'dff' => 'dsd',
    _ => normalized,
  };
}

final _htmlTag = RegExp(r'<[^>]+>');

const _htmlEntities = <String, String>{
  '&amp;': '&',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&lt;': '<',
  '&gt;': '>',
  '&nbsp;': ' ',
};

String? subsonicPlainText(String? html) {
  if (html == null) return null;
  var text = html.replaceAll(_htmlTag, '');
  for (final entry in _htmlEntities.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return _presence(text);
}

String subsonicPlaylistEntryId(int index, String songId) => '$index:$songId';

({int index, String songId})? subsonicPlaylistEntryOf(String entryId) {
  final separator = entryId.indexOf(':');
  if (separator <= 0) return null;
  final index = int.tryParse(entryId.substring(0, separator));
  if (index == null || index < 0) return null;
  return (index: index, songId: entryId.substring(separator + 1));
}

String? _presence(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<ArtistRef> _artistRefs(
  List<SubsonicArtistRefDTO> refs, {
  String? fallbackId,
  String? fallbackName,
}) {
  final resolved = [
    for (final ref in refs)
      if (ref.id.isNotEmpty && ref.name.isNotEmpty)
        ArtistRef(id: ref.id, name: ref.name),
  ];
  if (resolved.isNotEmpty) return resolved;
  final id = _presence(fallbackId);
  final name = _presence(fallbackName);
  if (id == null || name == null) return const [];
  return [ArtistRef(id: id, name: name)];
}

List<String> _genreNames(List<SubsonicNamedDTO> genres, String? fallback) {
  final names = [for (final genre in genres) ?_presence(genre.name)];
  if (names.isNotEmpty) return names;
  final single = _presence(fallback);
  return single == null ? const [] : [single];
}

Map<String, String> _externalIds(String key, String? musicBrainzId) {
  final id = _presence(musicBrainzId);
  return id == null ? const {} : {key: id};
}

PlaybackUserData _userData({
  required int playCount,
  required String? starred,
}) => PlaybackUserData(
  playCount: playCount,
  played: playCount > 0,
  isFavorite: _presence(starred) != null,
);

extension SubsonicChildMapping on SubsonicChildDTO {
  LibraryItem toLibraryItem({
    String? playlistItemId,
    int? indexNumber,
    bool lyricsAvailable = true,
  }) {
    final container = _presence(suffix);
    final resolvedAlbumId = _presence(albumId);
    return LibraryItem(
      id: id,
      name: title,
      kind: ItemKind.song,
      indexNumber: indexNumber ?? track ?? 0,
      discNumber: discNumber,
      duration: Duration(seconds: duration ?? 0),
      path: path,
      playlistItemId: playlistItemId,
      productionYear: year,
      albumId: resolvedAlbumId,
      albumName: album,
      albumArtist:
          _presence(displayAlbumArtist) ??
          albumArtists.firstOrNull?.name ??
          _presence(artist),
      albumArtists: _artistRefs(
        albumArtists,
        fallbackId: artistId,
        fallbackName: artist,
      ),
      artists: _artistRefs(artists, fallbackId: artistId, fallbackName: artist),
      genres: _genreNames(genres, genre),
      images: ImageRefs(
        primary: _presence(coverArt),
        albumPrimary: resolvedAlbumId == null
            ? null
            : '$subsonicAlbumArtPrefix$resolvedAlbumId',
      ),
      hasLyrics: lyricsAvailable,
      userData: _userData(playCount: playCount, starred: starred),
      audioSources: [
        AudioSourceInfo(
          container: container,
          codec: subsonicCodecForSuffix(container, bitDepth: bitDepth),
          bitRate: bitRate == null ? null : bitRate! * 1000,
          sampleRate: samplingRate,
          bitDepth: (bitDepth ?? 0) > 0 ? bitDepth : null,
          channels: channelCount,
        ),
      ],
      externalIds: _externalIds(
        ExternalIdProvider.musicBrainzRecording,
        musicBrainzId,
      ),
    );
  }
}

extension SubsonicAlbumMapping on SubsonicAlbumDTO {
  LibraryItem toLibraryItem() {
    final albumArtists = _artistRefs(
      artists,
      fallbackId: artistId,
      fallbackName: artist,
    );
    return LibraryItem(
      id: id,
      name: name,
      kind: ItemKind.album,
      duration: Duration(seconds: duration ?? 0),
      productionYear: year,
      albumId: id,
      albumName: name,
      albumArtist: _presence(displayArtist) ?? _presence(artist),
      albumArtists: albumArtists,
      artists: albumArtists,
      genres: _genreNames(genres, genre),
      images: ImageRefs(
        primary: _presence(coverArt) ?? '$subsonicAlbumArtPrefix$id',
      ),
      userData: _userData(playCount: playCount, starred: starred),
      externalIds: _externalIds(
        ExternalIdProvider.musicBrainzAlbum,
        musicBrainzId,
      ),
    );
  }
}

extension SubsonicArtistMapping on SubsonicArtistDTO {
  LibraryItem toLibraryItem() => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.artist,
    images: ImageRefs(
      primary: _presence(coverArt) ?? '$subsonicArtistArtPrefix$id',
      backdrops: [?_presence(artistImageUrl)],
    ),
    userData: _userData(playCount: 0, starred: starred),
    externalIds: _externalIds(
      ExternalIdProvider.musicBrainzArtist,
      musicBrainzId,
    ),
  );
}

extension SubsonicPlaylistMapping on SubsonicPlaylistDTO {
  LibraryItem toLibraryItem() => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.playlist,
    duration: Duration(seconds: duration ?? 0),
    overview: _presence(comment),
    images: ImageRefs(
      primary: _presence(coverArt) ?? '$subsonicPlaylistArtPrefix$id',
    ),
  );
}

extension SubsonicGenreMapping on SubsonicGenreDTO {
  LibraryItem toLibraryItem() =>
      LibraryItem(id: value, name: value, kind: ItemKind.genre);
}

extension SubsonicMusicFolderMapping on SubsonicMusicFolderDTO {
  LibraryItem toLibraryItem() => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.library,
    collectionType: 'music',
  );
}
