import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_frame.dart';

void main() {
  group('encodeDiscordFrame', () {
    test('writes a little-endian opcode and length header', () {
      final frame = encodeDiscordFrame(DiscordOpcode.handshake, {'v': 1});
      final header = ByteData.sublistView(frame, 0, 8);
      final body = utf8.decode(Uint8List.sublistView(frame, 8));

      expect(header.getUint32(0, Endian.little), DiscordOpcode.handshake);
      expect(header.getUint32(4, Endian.little), body.length);
      expect(jsonDecode(body), {'v': 1});
    });
  });

  group('DiscordFrameReader', () {
    test('round-trips an encoded frame', () {
      final reader = DiscordFrameReader();
      final frames = reader.add(
        encodeDiscordFrame(DiscordOpcode.frame, {'evt': 'READY'}),
      );

      expect(frames, hasLength(1));
      expect(frames.single.opcode, DiscordOpcode.frame);
      expect(frames.single.payload, {'evt': 'READY'});
    });

    test('waits for the rest of a frame split across chunks', () {
      final reader = DiscordFrameReader();
      final encoded = encodeDiscordFrame(DiscordOpcode.ping, {'nonce': 'abc'});

      expect(reader.add(encoded.sublist(0, 4)), isEmpty);
      expect(reader.add(encoded.sublist(4, 10)), isEmpty);

      final frames = reader.add(encoded.sublist(10));
      expect(frames, hasLength(1));
      expect(frames.single.opcode, DiscordOpcode.ping);
      expect(frames.single.payload, {'nonce': 'abc'});
    });

    test('returns every frame delivered in one chunk', () {
      final reader = DiscordFrameReader();
      final chunk = [
        ...encodeDiscordFrame(DiscordOpcode.frame, {'evt': 'READY'}),
        ...encodeDiscordFrame(DiscordOpcode.ping, {'ping': 1}),
      ];

      final frames = reader.add(chunk);
      expect(frames.map((frame) => frame.opcode), [
        DiscordOpcode.frame,
        DiscordOpcode.ping,
      ]);
    });

    test('keeps trailing bytes buffered for the next chunk', () {
      final reader = DiscordFrameReader();
      final first = encodeDiscordFrame(DiscordOpcode.frame, {'a': 1});
      final second = encodeDiscordFrame(DiscordOpcode.frame, {'b': 2});

      expect(reader.add([...first, ...second.sublist(0, 3)]), hasLength(1));
      final frames = reader.add(second.sublist(3));
      expect(frames.single.payload, {'b': 2});
    });

    test('rejects an implausibly large frame', () {
      final reader = DiscordFrameReader();
      final header = Uint8List(8);
      ByteData.sublistView(header)
        ..setUint32(0, DiscordOpcode.frame, Endian.little)
        ..setUint32(4, 1 << 24, Endian.little);

      expect(() => reader.add(header), throwsFormatException);
    });

    test('reset drops a partial frame left by a dead connection', () {
      final reader = DiscordFrameReader();
      final encoded = encodeDiscordFrame(DiscordOpcode.frame, {'a': 1});

      expect(reader.add(encoded.sublist(0, 6)), isEmpty);
      reader.reset();

      final frames = reader.add(encoded);
      expect(frames.single.payload, {'a': 1});
    });
  });
}
