@Tags(['conductor'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/conductor/phoenix_socket.dart';

void main() {
  final endpoint = Uri.parse(
    Platform.environment['CONDUCTOR_URL'] ?? 'http://127.0.0.1:4010',
  );

  setUpAll(() async {
    final reachable = await _isReachable(endpoint);
    if (!reachable) {
      fail(
        'No conductor at $endpoint. Start it with `mix phx.server` in '
        'mibrarian/conductor, or set CONDUCTOR_URL.',
      );
    }
  });

  PhoenixSocket socketFor(String userId, String deviceId, {String? name}) =>
      PhoenixSocket(
        endpoint: endpoint,
        params: {
          'user_id': userId,
          'device_id': deviceId,
          'device_name': name ?? deviceId,
          'platform': 'test',
        },
      );

  var counter = 0;
  String nextUser() =>
      'test-user-${DateTime.now().millisecondsSinceEpoch}-${counter++}';

  test('joins a session and receives state plus the device registry', () async {
    final userId = nextUser();
    final socket = socketFor(userId, 'desktop', name: "Alex's Mac");
    addTearDown(socket.dispose);

    await socket.connect();
    expect(socket.isConnected, isTrue);

    final channel = socket.channel('session:$userId');

    final gotState = Completer<Map<String, dynamic>>();
    final gotPresence = Completer<Map<String, dynamic>>();
    channel.on('session:state', gotState.complete);
    channel.on('presence_state', gotPresence.complete);

    await channel.join();

    final state = await gotState.future.timeout(const Duration(seconds: 5));
    expect(state['revision'], 0);
    expect(state['renderer_id'], isNull);
    expect((state['doc'] as Map)['item_ids'], isEmpty);

    final presence = await gotPresence.future.timeout(
      const Duration(seconds: 5),
    );
    expect(presence.keys, contains('desktop'));
  });

  test('a state update from one device reaches the other', () async {
    final userId = nextUser();
    final desktop = socketFor(userId, 'desktop');
    final phone = socketFor(userId, 'phone');
    addTearDown(desktop.dispose);
    addTearDown(phone.dispose);

    await desktop.connect();
    await phone.connect();

    final desktopChannel = desktop.channel('session:$userId');
    final phoneChannel = phone.channel('session:$userId');

    await desktopChannel.join();
    await phoneChannel.join();

    final updates = <Map<String, dynamic>>[];
    final gotUpdate = Completer<Map<String, dynamic>>();
    phoneChannel.on('session:state', (payload) {
      updates.add(payload);
      if (payload['revision'] == 1 && !gotUpdate.isCompleted) {
        gotUpdate.complete(payload);
      }
    });

    final reply = await desktopChannel.push('state:update', {
      'doc': {
        'backend_ref': 'jellyfin-test',
        'item_ids': ['track-a', 'track-b'],
        'queue_position': 1,
        'track_position_ms': 90000,
        'playing': true,
      },
      'revision': 0,
    });
    expect(reply['revision'], 1);

    final received = await gotUpdate.future.timeout(const Duration(seconds: 5));
    final doc = received['doc'] as Map;
    expect(doc['track_position_ms'], 90000);
    expect(doc['item_ids'], ['track-a', 'track-b']);
    expect(doc['updated_by_device'], 'desktop');
  });

  test('handoff carries the state doc to the target device', () async {
    final userId = nextUser();
    final desktop = socketFor(userId, 'desktop');
    final phone = socketFor(userId, 'phone');
    addTearDown(desktop.dispose);
    addTearDown(phone.dispose);

    await desktop.connect();
    await phone.connect();

    final desktopChannel = desktop.channel('session:$userId');
    final phoneChannel = phone.channel('session:$userId');
    await desktopChannel.join();
    await phoneChannel.join();

    final handoff = Completer<Map<String, dynamic>>();
    phoneChannel.on('handoff:begin', (p) {
      if (!handoff.isCompleted) handoff.complete(p);
    });

    await desktopChannel.push('state:update', {
      'doc': {
        'item_ids': ['track-a'],
        'track_position_ms': 90000,
        'playing': true,
      },
      'revision': 0,
    });

    final sentAt = DateTime.now();
    await desktopChannel.push('handoff', {'to': 'phone'});

    final begin = await handoff.future.timeout(const Duration(seconds: 5));
    final wireLatency = DateTime.now().difference(sentAt);

    expect(begin['to'], 'phone');
    expect(begin['from'], 'desktop');
    expect(begin['renderer_id'], 'phone');
    expect((begin['doc'] as Map)['track_position_ms'], 90000);

    // ignore: avoid_print
    print('handoff message round trip: ${wireLatency.inMilliseconds}ms');
  });

  test('handoff to a device that is not connected is refused', () async {
    final userId = nextUser();
    final desktop = socketFor(userId, 'desktop');
    addTearDown(desktop.dispose);

    await desktop.connect();
    final channel = desktop.channel('session:$userId');
    await channel.join();

    await expectLater(
      channel.push('handoff', {'to': 'car-stereo'}),
      throwsA(
        isA<PhoenixError>().having(
          (e) => e.reason,
          'reason',
          'target device not connected',
        ),
      ),
    );
  });

  test('presence tells a device when a sibling appears and leaves', () async {
    final userId = nextUser();
    final desktop = socketFor(userId, 'desktop');
    addTearDown(desktop.dispose);

    await desktop.connect();
    final desktopChannel = desktop.channel('session:$userId');

    final joins = Completer<Map<String, dynamic>>();
    final leaves = Completer<Map<String, dynamic>>();
    desktopChannel.on('presence_diff', (payload) {
      final joined = (payload['joins'] as Map?) ?? {};
      final left = (payload['leaves'] as Map?) ?? {};
      if (joined.containsKey('phone') && !joins.isCompleted) {
        joins.complete(joined.cast<String, dynamic>());
      }
      if (left.containsKey('phone') && !leaves.isCompleted) {
        leaves.complete(left.cast<String, dynamic>());
      }
    });
    await desktopChannel.join();

    final phone = socketFor(userId, 'phone', name: 'Alex iPhone');
    await phone.connect();
    await phone.channel('session:$userId').join();

    final joined = await joins.future.timeout(const Duration(seconds: 5));
    final meta = ((joined['phone'] as Map)['metas'] as List).first as Map;
    expect(meta['device_name'], 'Alex iPhone');

    await phone.dispose();
    await leaves.future.timeout(const Duration(seconds: 5));
  });
}

Future<bool> _isReachable(Uri endpoint) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(endpoint.replace(path: '/health'));
    final response = await request.close();
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } on Object {
    return false;
  }
}
