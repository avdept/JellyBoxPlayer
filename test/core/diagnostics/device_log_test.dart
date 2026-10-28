import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/device_log.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('device_log');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  File logFile([String name = 'jellybox.log']) =>
      File('${dir.path}${Platform.pathSeparator}$name');

  test('- appends stamped lines in order', () async {
    var tick = 0;
    final log = DeviceLog(
      directory: () async => dir,
      clock: () => DateTime(2026, 10, 13, 8, 5, 7, 40 + tick++),
    );

    log
      ..write('[LocalTarget] load failed: no network')
      ..write('[LocalTarget] retrying the queue, attempt 1');
    await log.flush();

    expect(
      await logFile().readAsLines(),
      [
        '2026-10-13 08:05:07.040 [LocalTarget] load failed: no network',
        '2026-10-13 08:05:07.041 [LocalTarget] retrying the queue, attempt 1',
      ],
    );
  });

  test('- keeps appending to a file left by the previous run', () async {
    await logFile().writeAsString('earlier run\n');
    final log = DeviceLog(directory: () async => dir);

    log.write('this run');
    await log.flush();

    final lines = await logFile().readAsLines();
    expect(lines.first, 'earlier run');
    expect(lines.last, endsWith('this run'));
  });

  test('- rotates once the file would outgrow its cap', () async {
    final log = DeviceLog(directory: () async => dir, maxBytes: 120);

    for (var i = 0; i < 6; i++) {
      log.write('line $i padded to make it longer');
      await log.flush();
    }

    final current = await logFile().readAsLines();
    final rotated = await logFile('jellybox.1.log').readAsLines();
    expect(current.map((line) => line.substring(24)), [
      'line 4 padded to make it longer',
      'line 5 padded to make it longer',
    ]);
    expect(rotated.map((line) => line.substring(24)), [
      'line 2 padded to make it longer',
      'line 3 padded to make it longer',
    ]);
  });

  test('- lists the rotated file before the current one', () async {
    final log = DeviceLog(directory: () async => dir, maxBytes: 120);

    expect(await log.files(), isEmpty);

    for (var i = 0; i < 6; i++) {
      log.write('line $i padded to make it longer');
      await log.flush();
    }

    expect((await log.files()).map((file) => file.path), [
      logFile('jellybox.1.log').path,
      logFile().path,
    ]);
  });

  test('- carries a file left in the old location over', () async {
    final old = await Directory.systemTemp.createTemp('device_log_old');
    addTearDown(() => old.delete(recursive: true));
    final previous = File('${old.path}${Platform.pathSeparator}jellybox.log');
    await previous.writeAsString('from the old place\n');
    final log = DeviceLog(
      directory: () async => dir,
      adoptFrom: () async => old,
    );

    log.write('new place');
    await log.flush();

    final lines = await logFile().readAsLines();
    expect(lines.first, 'from the old place');
    expect(lines.last, endsWith('new place'));
    expect(previous.existsSync(), isFalse);
  });

  test('- a broken destination silences the log instead of throwing', () async {
    final log = DeviceLog(
      directory: () async => throw const FileSystemException(),
    );

    log
      ..write('first')
      ..write('second');
    await log.flush();

    expect(logFile().existsSync(), isFalse);
  });
}
