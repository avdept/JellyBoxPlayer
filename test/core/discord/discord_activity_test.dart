import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_activity.dart';

void main() {
  group('DiscordActivity.toJson', () {
    test('describes a listening activity', () {
      final start = DateTime.fromMillisecondsSinceEpoch(1000);
      final end = DateTime.fromMillisecondsSinceEpoch(241000);
      final activity = DiscordActivity.listening(
        title: 'Bloom',
        artist: 'Radiohead',
        album: 'The King of Limbs',
        largeImage: 'jellybox',
        start: start,
        end: end,
      );

      expect(activity.toJson(), {
        'type': 2,
        'details': 'Bloom',
        'state': 'Radiohead',
        'assets': {
          'large_image': 'jellybox',
          'large_text': 'The King of Limbs',
        },
        'timestamps': {'start': 1000, 'end': 241000},
      });
    });

    test('omits absent artist, artwork and timestamps', () {
      final activity = DiscordActivity.listening(title: 'Bloom');

      expect(activity.toJson(), {'type': 2, 'details': 'Bloom'});
    });

    test('compares by value so repeat updates can be skipped', () {
      final start = DateTime.fromMillisecondsSinceEpoch(1000);

      expect(
        DiscordActivity.listening(title: 'Bloom', artist: 'a', start: start),
        DiscordActivity.listening(title: 'Bloom', artist: 'a', start: start),
      );
      expect(
        DiscordActivity.listening(title: 'Bloom', start: start),
        isNot(DiscordActivity.listening(title: 'Codex', start: start)),
      );
    });
  });

  group('discordActivityField', () {
    test('drops empty values', () {
      expect(discordActivityField(null), isNull);
      expect(discordActivityField('   '), isNull);
    });

    test('pads a single character to the two Discord requires', () {
      expect(discordActivityField('X'), 'X ');
    });

    test('clips long values to 128 bytes', () {
      final field = discordActivityField('a' * 400);

      expect(field, hasLength(128));
    });

    test('clips multi-byte values without splitting a rune', () {
      final field = discordActivityField('é' * 100);

      expect(field, isNotNull);
      expect(field!.runes.every((rune) => rune == 'é'.runes.first), isTrue);
      expect(field.runes.length, lessThanOrEqualTo(64));
    });

    test('keeps emoji intact', () {
      final field = discordActivityField('🎵' * 40);

      expect(field, isNotNull);
      expect(field!.contains('�'), isFalse);
      expect(field.runes.every((rune) => rune == '🎵'.runes.first), isTrue);
    });
  });
}
