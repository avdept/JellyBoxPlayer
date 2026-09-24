import 'package:meta/meta.dart';

enum PlayerCommand {
  play('play'),
  pause('pause'),
  next('next'),
  previous('previous'),
  seek('seek'),
  shuffle('shuffle'),
  repeat('repeat'),
  volume('volume'),
  skipTo('skip_to');

  const PlayerCommand(this.wire);

  final String wire;
}

const repeatModes = ['off', 'all', 'one'];

enum ConductorStatus {
  off,
  connecting,
  listening,
  rendering,
  reconnecting,
  error,
}

@immutable
class SessionDoc {
  const SessionDoc({
    this.backendRef,
    this.albumId,
    this.itemIds = const [],
    this.queuePosition = 0,
    this.trackPositionMs = 0,
    this.playing = false,
    this.shuffle = false,
    this.repeat = 'off',
    this.volume = 1,
  });

  final String? backendRef;
  final String? albumId;
  final List<String> itemIds;
  final int queuePosition;
  final int trackPositionMs;
  final bool playing;
  final bool shuffle;
  final String repeat;
  final double volume;

  bool get isEmpty => itemIds.isEmpty;

  String? get currentItemId =>
      queuePosition >= 0 && queuePosition < itemIds.length
      ? itemIds[queuePosition]
      : null;
}

@immutable
class ConductorDevice {
  const ConductorDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.isRenderer = false,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final String platform;
  final bool isRenderer;
  final bool isSelf;
}

@immutable
class ContinuityAccount {
  const ContinuityAccount({
    required this.serverUrl,
    required this.email,
    required this.userId,
    required this.token,
    this.serverName,
    this.libraryName,
    this.socketPath = '/conductor/socket',
  });

  final String serverUrl;
  final String email;
  final String userId;
  final String token;
  final String? serverName;
  final String? libraryName;
  final String socketPath;

  Uri get endpoint => Uri.parse(serverUrl);
}
