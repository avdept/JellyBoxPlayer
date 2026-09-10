import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/discord/discord_pipe_transport.dart';

abstract interface class DiscordTransport {
  Stream<List<int>> get incoming;

  void send(List<int> data);

  Future<void> close();
}

Future<DiscordTransport?> openDiscordTransport() =>
    Platform.isWindows ? openDiscordPipeTransport() : _openDiscordSocket();

Future<DiscordTransport?> _openDiscordSocket() async {
  for (final path in discordSocketPaths()) {
    try {
      final socket = await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
        timeout: const Duration(seconds: 2),
      );
      return _SocketTransport(socket);
    } on Object catch (_) {
      continue;
    }
  }
  return null;
}

const _sandboxDirectories = [
  '',
  'app/com.discordapp.Discord',
  'app/com.discordapp.DiscordCanary',
  'app/com.discordapp.DiscordPTB',
  'snap.discord',
  'snap.discord-canary',
];

Iterable<String> discordSocketPaths({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final bases = <String>[
    ?env['XDG_RUNTIME_DIR'],
    ?env['TMPDIR'],
    ?env['TMP'],
    ?env['TEMP'],
    '/tmp',
  ];

  final paths = <String>{};
  for (final base in bases) {
    final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    if (root.isEmpty) continue;
    for (final directory in _sandboxDirectories) {
      final parent = directory.isEmpty ? root : '$root/$directory';
      for (var index = 0; index < 10; index++) {
        paths.add('$parent/discord-ipc-$index');
      }
    }
  }
  return paths;
}

class _SocketTransport implements DiscordTransport {
  _SocketTransport(this._socket);

  final Socket _socket;

  @override
  Stream<List<int>> get incoming => _socket;

  @override
  void send(List<int> data) => _socket.add(data);

  @override
  Future<void> close() async {
    try {
      await _socket.close();
    } on Object catch (error) {
      debugPrint('[Discord] socket close failed: $error');
    }
    _socket.destroy();
  }
}
