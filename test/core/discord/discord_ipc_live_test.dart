@Tags(['discord'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_activity.dart';
import 'package:jplayer/src/core/discord/discord_frame.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';

void main() {
  test('the running Discord client answers our handshake', () async {
    final transport = await openDiscordTransport();
    if (transport == null) {
      markTestSkipped('no Discord IPC socket; is the desktop client running?');
      return;
    }

    final reader = DiscordFrameReader();
    final frames = <DiscordFrame>[];
    final subscription = transport.incoming.listen(
      (chunk) => frames.addAll(reader.add(chunk)),
    );

    transport
      ..send(
        encodeDiscordFrame(DiscordOpcode.handshake, {
          'v': 1,
          'client_id': '000000000000000000',
        }),
      )
      ..send(
        encodeDiscordFrame(DiscordOpcode.frame, {
          'cmd': 'SET_ACTIVITY',
          'nonce': '1',
          'args': {
            'pid': 0,
            'activity': DiscordActivity.listening(
              title: 'Bloom',
              artist: 'Radiohead',
            ).toJson(),
          },
        }),
      );

    await Future<void>.delayed(const Duration(seconds: 2));
    await subscription.cancel();
    await transport.close();

    printOnFailure('frames: ${frames.map((f) => '${f.opcode}:${f.payload}')}');
    expect(frames, isNotEmpty);
    expect(frames.first.payload, isNotEmpty);
  });
}
