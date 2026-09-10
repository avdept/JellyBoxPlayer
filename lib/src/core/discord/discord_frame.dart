import 'dart:convert';
import 'dart:typed_data';

abstract final class DiscordOpcode {
  static const handshake = 0;
  static const frame = 1;
  static const close = 2;
  static const ping = 3;
  static const pong = 4;
}

class DiscordFrame {
  const DiscordFrame(this.opcode, this.payload);

  final int opcode;
  final Map<String, Object?> payload;
}

Uint8List encodeDiscordFrame(int opcode, Map<String, Object?> payload) {
  final body = utf8.encode(jsonEncode(payload));
  final frame = Uint8List(_headerLength + body.length);
  ByteData.sublistView(frame, 0, _headerLength)
    ..setUint32(0, opcode, Endian.little)
    ..setUint32(4, body.length, Endian.little);
  frame.setRange(_headerLength, frame.length, body);
  return frame;
}

const int _headerLength = 8;
const int _maxFrameLength = 1 << 20;

class DiscordFrameReader {
  Uint8List _buffer = Uint8List(0);

  void reset() => _buffer = Uint8List(0);

  List<DiscordFrame> add(List<int> chunk) {
    if (chunk.isEmpty) return const [];
    _buffer = Uint8List(_buffer.length + chunk.length)
      ..setRange(0, _buffer.length, _buffer)
      ..setRange(_buffer.length, _buffer.length + chunk.length, chunk);

    final frames = <DiscordFrame>[];
    var offset = 0;
    while (_buffer.length - offset >= _headerLength) {
      final header = ByteData.sublistView(
        _buffer,
        offset,
        offset + _headerLength,
      );
      final opcode = header.getUint32(0, Endian.little);
      final length = header.getUint32(4, Endian.little);
      if (length > _maxFrameLength) {
        throw FormatException('Discord frame too large: $length bytes');
      }
      if (_buffer.length - offset - _headerLength < length) break;

      final start = offset + _headerLength;
      final body = utf8.decode(
        Uint8List.sublistView(_buffer, start, start + length),
      );
      offset = start + length;
      frames.add(DiscordFrame(opcode, _decodePayload(body)));
    }

    _buffer = offset == 0
        ? _buffer
        : Uint8List.fromList(_buffer.sublist(offset));
    return frames;
  }
}

Map<String, Object?> _decodePayload(String body) {
  if (body.isEmpty) return const {};
  final decoded = jsonDecode(body);
  return decoded is Map<String, Object?> ? decoded : const {};
}
