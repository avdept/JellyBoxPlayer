import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/params/params.dart';

void main() {
  group('PlaystateData', () {
    test('serializes the fields Jellyfin needs to record a play', () {
      final json =
          jsonDecode(
                jsonEncode(
                  const PlaystateData(
                    playSessionId: 'session-1',
                    itemId: 'song-1',
                    mediaSourceId: 'song-1',
                    positionTicks: 30000000,
                    isPaused: false,
                    canSeek: true,
                    nowPlayingQueue: [
                      QueueItemData(id: 'song-1'),
                      QueueItemData(id: 'song-2'),
                    ],
                  ),
                ),
              )
              as Map<String, dynamic>;

      expect(json, {
        'PlaySessionId': 'session-1',
        'ItemId': 'song-1',
        'MediaSourceId': 'song-1',
        'PositionTicks': 30000000,
        'IsPaused': false,
        'CanSeek': true,
        'NowPlayingQueue': [
          {'Id': 'song-1'},
          {'Id': 'song-2'},
        ],
      });
    });

    test('omits optional fields that were not provided', () {
      final json =
          jsonDecode(
                jsonEncode(
                  const PlaystateData(
                    playSessionId: 'session-1',
                    itemId: 'song-1',
                  ),
                ),
              )
              as Map<String, dynamic>;

      expect(json.keys, unorderedEquals(['PlaySessionId', 'ItemId']));
    });
  });
}
