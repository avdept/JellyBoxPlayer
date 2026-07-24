import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class CastController {
  CastController(this._ref);

  final Ref _ref;

  Stream<List<GoogleCastDevice>> get devicesStream =>
      GoogleCastDiscoveryManager.instance.devicesStream;

  Stream<GoogleCastSession?> get sessionStream =>
      GoogleCastSessionManager.instance.currentSessionStream;

  bool get isConnected =>
      GoogleCastSessionManager.instance.connectionState ==
      GoogleCastConnectState.connected;

  void startDiscovery() => GoogleCastDiscoveryManager.instance.startDiscovery();

  void stopDiscovery() => GoogleCastDiscoveryManager.instance.stopDiscovery();

  Future<void> connectAndCast(GoogleCastDevice device) async {
    await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    await _ref.read(playbackProvider.notifier).pause();
    await castCurrentTrack();
  }

  Future<void> disconnect() =>
      GoogleCastSessionManager.instance.endSessionAndStopCasting();

  Future<void> castCurrentTrack() async {
    final playback = _ref.read(playbackProvider);
    final index = playback.currentMediaIndex;
    final song = index != null ? playback.songs.elementAtOrNull(index) : null;
    final album = playback.album;
    if (song == null || album == null) return;

    final media = GoogleCastMediaInformation(
      contentId: song.id,
      streamType: CastMediaStreamType.buffered,
      contentType: 'audio/mp4',
      contentUrl: _streamUrl(song),
      metadata: GoogleCastMusicMediaMetadata(
        title: song.name,
        artist: song.albumArtist ?? album.albumArtist,
        albumName: song.albumName,
        images: _artImages(song, album),
      ),
    );
    await GoogleCastRemoteMediaClient.instance.loadMedia(media);
  }

  Uri _streamUrl(ItemDTO song) => Uri.parse(_ref.read(baseUrlProvider)!).replace(
    path: 'Audio/${song.id}/universal',
    queryParameters: {
      'UserId': _ref.read(currentUserProvider)!.userId,
      'api_key': _ref.read(currentUserProvider)!.token,
      'DeviceId': deviceId,
      'TranscodingProtocol': 'http',
      'TranscodingContainer': 'm4a',
      'AudioCodec': 'm4a',
      'Container': [
        'mp3,aac,m4a',
        'aac,m4b',
        'aac,flac,alac,m4a',
        'alac,m4b',
        'alac,wav,m4a,aiff,aif',
      ].join('|'),
    },
  );

  List<GoogleCastImage>? _artImages(ItemDTO song, ItemDTO album) {
    final songTag = song.imageTags['Primary'];
    final albumTag = album.imageTags['Primary'];
    final imageService = _ref.read(imageServiceProvider);
    if (songTag != null) {
      return [
        GoogleCastImage(
          url: Uri.parse(imageService.imagePath(tagId: songTag, id: song.id)),
        ),
      ];
    } else if (albumTag != null) {
      return [
        GoogleCastImage(
          url: Uri.parse(imageService.imagePath(tagId: albumTag, id: album.id)),
        ),
      ];
    }
    return null;
  }
}

final castControllerProvider = Provider<CastController>(CastController.new);
