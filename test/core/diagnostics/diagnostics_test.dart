import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';

void main() {
  late List<String> printed;
  late DebugPrintCallback original;

  setUp(() {
    printed = [];
    original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) printed.add(message);
    };
  });

  tearDown(() => debugPrint = original);

  test('- a breadcrumb goes through the debugPrint hook, not past it', () {
    const Diagnostics().trail('queue: Play accepted', category: 'upnp');

    expect(printed, ['[upnp] queue: Play accepted']);
  });

  test('- a capture and a report go through the same hook', () async {
    await const Diagnostics().capture(
      StateError('boom'),
      operation: 'upnp.queue.load',
    );
    await const Diagnostics().report('upnp device report');

    expect(printed.first, '[upnp.queue.load] Bad state: boom');
    expect(printed.last, startsWith('[report] upnp device report'));
  });
}
