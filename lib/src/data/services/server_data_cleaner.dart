import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';

typedef DownloadSummary = ({int songs, int bytes});

class ServerDataCleaner {
  ServerDataCleaner(String serverId, {DownloadDatabase? database})
    : _database = database ?? DownloadDatabase(serverId: serverId);

  final DownloadDatabase _database;

  bool get _scoped => _database.serverId.isNotEmpty;

  Future<DownloadSummary> downloads() async {
    if (!_scoped) return (songs: 0, bytes: 0);
    final songs = await _database.getDownloadedSongs();
    return (
      songs: songs.length,
      bytes: songs.fold(0, (sum, song) => sum + song.sizeInBytes),
    );
  }

  Future<void> deleteAll() async {
    if (!_scoped) return;
    await DownloadPaths.init();
    for (final playlist in await _database.getDownloadedPlaylists()) {
      await _database.deleteDownloadedPlaylist(playlist.item.id);
      await DownloadPaths.deleteAlbumDirectory(playlist.item.id);
    }
    for (final album in await _database.getDownloadedAlbums()) {
      await _database.deleteDownloadedAlbum(album.item.id);
      await DownloadPaths.deleteAlbumDirectory(album.item.id);
    }
    for (final song in await _database.getDownloadedSongs()) {
      await _database.deleteDownloadedSong(song.item.id);
    }
    await QueueCacheDatabase(_database).deleteAll();
    await InstantMixDatabase(_database).deleteAll();
  }
}

final ProviderFamily<ServerDataCleaner, String> serverDataCleanerProvider =
    Provider.family<ServerDataCleaner, String>(
      (ref, serverId) => ServerDataCleaner(serverId),
    );
