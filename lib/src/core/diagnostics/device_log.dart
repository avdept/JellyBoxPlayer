import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class DeviceLog {
  DeviceLog({
    required Future<Directory> Function() directory,
    Future<Directory?> Function()? adoptFrom,
    this.fileName = 'jellybox.log',
    this.maxBytes = 2 * 1024 * 1024,
    DateTime Function()? clock,
  }) : _directory = directory,
       _adoptFrom = adoptFrom,
       _clock = clock ?? DateTime.now;

  static DeviceLog? _current;

  static DeviceLog? get current => _current;

  static void configure(DeviceLog log, {String? header}) {
    _current = log;
    if (header != null) log.write('---- $header ----');
  }

  static void install() {
    final log = _current;
    if (log == null) return;
    final previous = debugPrint;
    if (log._wrappers.contains(previous)) return;
    void wrapper(String? message, {int? wrapWidth}) {
      previous(message, wrapWidth: wrapWidth);
      if (message != null) log.write(message);
    }

    log._wrappers.add(wrapper);
    debugPrint = wrapper;
  }

  final Future<Directory> Function() _directory;
  final Future<Directory?> Function()? _adoptFrom;
  final String fileName;
  final int maxBytes;
  final DateTime Function() _clock;
  final _wrappers = <DebugPrintCallback>{};
  final _buffer = StringBuffer();
  Future<void> _queue = Future<void>.value();
  File? _file;
  int _size = 0;
  var _broken = false;
  var _draining = false;

  String get rotatedFileName {
    final dot = fileName.lastIndexOf('.');
    return dot < 0
        ? '$fileName.1'
        : '${fileName.substring(0, dot)}.1${fileName.substring(dot)}';
  }

  void write(String message) {
    if (_broken) return;
    _buffer
      ..write(_stamp(_clock()))
      ..write(' ')
      ..writeln(message);
    if (_draining) return;
    _draining = true;
    _queue = _queue.then((_) => _drain());
  }

  Future<void> flush() => _queue;

  Future<Directory> get directory async => (await _open()).parent;

  Future<List<File>> files() async {
    await flush();
    final file = await _open();
    final rotated = File(
      '${file.parent.path}${Platform.pathSeparator}$rotatedFileName',
    );
    return [
      if (rotated.existsSync()) rotated,
      if (file.existsSync()) file,
    ];
  }

  Future<void> _drain() async {
    try {
      while (_buffer.isNotEmpty && !_broken) {
        final chunk = _buffer.toString();
        _buffer.clear();
        await _append(chunk);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _append(String chunk) async {
    try {
      final file = await _open();
      if (_size + chunk.length > maxBytes && _size > 0) {
        await _rotate(file);
      }
      await file.writeAsString(chunk, mode: FileMode.append, flush: true);
      if (_size == 0) await _makeReadable(file);
      _size += chunk.length;
    } on Object {
      _broken = true;
      _buffer.clear();
    }
  }

  Future<File> _open() async {
    final existing = _file;
    if (existing != null) return existing;
    final dir = await _directory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    if (!file.existsSync()) await _adopt(file);
    _size = file.existsSync() ? file.lengthSync() : 0;
    if (_size > 0) await _makeReadable(file);
    return _file = file;
  }

  Future<void> _makeReadable(File file) async {
    if (!Platform.isAndroid) return;
    try {
      await Process.run('chmod', ['644', file.path]);
    } on Object {
      return;
    }
  }

  Future<void> _adopt(File target) async {
    final adoptFrom = _adoptFrom;
    if (adoptFrom == null) return;
    try {
      final old = await adoptFrom();
      if (old == null) return;
      final previous = File('${old.path}${Platform.pathSeparator}$fileName');
      if (!previous.existsSync()) return;
      await previous.copy(target.path);
      await previous.delete();
    } on Object {
      return;
    }
  }

  Future<void> _rotate(File file) async {
    final rotated = File(
      '${file.parent.path}${Platform.pathSeparator}$rotatedFileName',
    );
    if (rotated.existsSync()) await rotated.delete();
    await file.rename(rotated.path);
    _size = 0;
  }

  static String _stamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    final millis = time.millisecond.toString().padLeft(3, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.$millis';
  }
}
