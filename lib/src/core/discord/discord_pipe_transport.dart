import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';

typedef CreateFileWNative =
    Pointer<Void> Function(
      Pointer<Utf16>,
      Uint32,
      Uint32,
      Pointer<Void>,
      Uint32,
      Uint32,
      Pointer<Void>,
    );
typedef CreateFileWDart =
    Pointer<Void> Function(
      Pointer<Utf16>,
      int,
      int,
      Pointer<Void>,
      int,
      int,
      Pointer<Void>,
    );

typedef FileIoNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint32>,
      Pointer<Void>,
    );
typedef FileIoDart =
    int Function(
      Pointer<Void>,
      Pointer<Uint8>,
      int,
      Pointer<Uint32>,
      Pointer<Void>,
    );

typedef PeekNamedPipeNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint32>,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );
typedef PeekNamedPipeDart =
    int Function(
      Pointer<Void>,
      Pointer<Uint8>,
      int,
      Pointer<Uint32>,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );

typedef CloseHandleNative = Int32 Function(Pointer<Void>);
typedef CloseHandleDart = int Function(Pointer<Void>);

const _genericRead = 0x80000000;
const _genericWrite = 0x40000000;
const _openExisting = 3;
const _invalidHandleAddress = -1;
const _pollInterval = Duration(milliseconds: 250);

final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final CreateFileWDart _createFileW = _kernel32
    .lookupFunction<CreateFileWNative, CreateFileWDart>('CreateFileW');

final FileIoDart _readFile = _kernel32.lookupFunction<FileIoNative, FileIoDart>(
  'ReadFile',
);

final FileIoDart _writeFile = _kernel32
    .lookupFunction<FileIoNative, FileIoDart>('WriteFile');

final PeekNamedPipeDart _peekNamedPipe = _kernel32
    .lookupFunction<PeekNamedPipeNative, PeekNamedPipeDart>('PeekNamedPipe');

final CloseHandleDart _closeHandle = _kernel32
    .lookupFunction<CloseHandleNative, CloseHandleDart>('CloseHandle');

class DiscordPipeException implements Exception {
  const DiscordPipeException(this.message);

  final String message;

  @override
  String toString() => 'DiscordPipeException: $message';
}

Future<DiscordTransport?> openDiscordPipeTransport() async {
  for (var index = 0; index < 10; index++) {
    final path =
        r'\\.\pipe\discord-ipc-'
        '$index';
    final name = path.toNativeUtf16();
    try {
      final handle = _createFileW(
        name,
        _genericRead | _genericWrite,
        0,
        nullptr,
        _openExisting,
        0,
        nullptr,
      );
      if (handle.address != _invalidHandleAddress) {
        return _PipeTransport(handle);
      }
    } on Object catch (error) {
      debugPrint('[Discord] named pipe unavailable: $error');
      return null;
    } finally {
      calloc.free(name);
    }
  }
  return null;
}

class _PipeTransport implements DiscordTransport {
  _PipeTransport(this._handle) {
    _poll = Timer.periodic(_pollInterval, (_) => _drain());
  }

  final Pointer<Void> _handle;
  final _incoming = StreamController<List<int>>();

  late final Timer _poll;
  var _closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  void send(List<int> data) {
    if (_closed) throw const DiscordPipeException('pipe is closed');

    final buffer = calloc<Uint8>(data.length);
    final written = calloc<Uint32>();
    try {
      buffer.asTypedList(data.length).setAll(0, data);
      if (_writeFile(_handle, buffer, data.length, written, nullptr) == 0) {
        throw const DiscordPipeException('write failed');
      }
    } finally {
      calloc
        ..free(buffer)
        ..free(written);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _poll.cancel();
    _release();
    await _incoming.close();
  }

  void _drain() {
    final available = calloc<Uint32>();
    final read = calloc<Uint32>();
    try {
      while (!_closed) {
        if (_peekNamedPipe(_handle, nullptr, 0, nullptr, available, nullptr) ==
            0) {
          _fail('peek failed');
          return;
        }
        final pending = available.value;
        if (pending == 0) return;

        final buffer = calloc<Uint8>(pending);
        try {
          if (_readFile(_handle, buffer, pending, read, nullptr) == 0) {
            _fail('read failed');
            return;
          }
          final count = read.value;
          if (count == 0) return;
          _incoming.add(Uint8List.fromList(buffer.asTypedList(count)));
        } finally {
          calloc.free(buffer);
        }
      }
    } on Object catch (error) {
      _fail('$error');
    } finally {
      calloc
        ..free(available)
        ..free(read);
    }
  }

  void _fail(String reason) {
    if (_closed) return;
    _closed = true;
    _poll.cancel();
    _release();
    if (!_incoming.isClosed) {
      _incoming.addError(DiscordPipeException(reason));
      _incoming.close().ignore();
    }
  }

  void _release() {
    try {
      _closeHandle(_handle);
    } on Object catch (error) {
      debugPrint('[Discord] closing named pipe failed: $error');
    }
  }
}
