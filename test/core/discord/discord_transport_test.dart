import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';

void main() {
  group('discordSocketPaths', () {
    test('probes ten sockets per directory', () {
      final paths = discordSocketPaths(
        environment: const {'XDG_RUNTIME_DIR': '/run/user/1000'},
      );

      expect(paths, contains('/run/user/1000/discord-ipc-0'));
      expect(paths, contains('/run/user/1000/discord-ipc-9'));
      expect(paths, isNot(contains('/run/user/1000/discord-ipc-10')));
    });

    test('covers flatpak and snap socket locations', () {
      final paths = discordSocketPaths(
        environment: const {'XDG_RUNTIME_DIR': '/run/user/1000'},
      );

      expect(
        paths,
        contains('/run/user/1000/app/com.discordapp.Discord/discord-ipc-0'),
      );
      expect(paths, contains('/run/user/1000/snap.discord/discord-ipc-0'));
    });

    test('always falls back to /tmp', () {
      final paths = discordSocketPaths(environment: const {});

      expect(paths, contains('/tmp/discord-ipc-0'));
    });

    test('normalises a trailing slash and de-duplicates directories', () {
      final paths = discordSocketPaths(
        environment: const {'TMPDIR': '/tmp/', 'TMP': '/tmp'},
      );

      expect(
        paths.where((path) => path == '/tmp/discord-ipc-0'),
        hasLength(1),
      );
    });
  });
}
