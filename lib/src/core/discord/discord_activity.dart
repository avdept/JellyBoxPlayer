import 'dart:convert';

import 'package:flutter/foundation.dart';

const discordListeningActivityType = 2;

const _maxFieldBytes = 128;
const _minFieldLength = 2;

@immutable
class DiscordActivity {
  const DiscordActivity({
    required this.details,
    this.state,
    this.largeImage,
    this.largeText,
    this.start,
    this.end,
  });

  factory DiscordActivity.listening({
    required String title,
    String? artist,
    String? album,
    String? largeImage,
    DateTime? start,
    DateTime? end,
  }) => DiscordActivity(
    details: discordActivityField(title) ?? 'Unknown track',
    state: discordActivityField(artist),
    largeImage: largeImage,
    largeText: discordActivityField(album),
    start: start,
    end: end,
  );

  final String details;
  final String? state;
  final String? largeImage;
  final String? largeText;
  final DateTime? start;
  final DateTime? end;

  Map<String, Object?> toJson() => {
    'type': discordListeningActivityType,
    'details': details,
    'state': ?state,
    if (largeImage case final image?)
      'assets': {'large_image': image, 'large_text': ?largeText},
    if (start != null || end != null)
      'timestamps': {
        if (start case final start?) 'start': start.millisecondsSinceEpoch,
        if (end case final end?) 'end': end.millisecondsSinceEpoch,
      },
  };

  @override
  bool operator ==(Object other) =>
      other is DiscordActivity &&
      other.details == details &&
      other.state == state &&
      other.largeImage == largeImage &&
      other.largeText == largeText &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode =>
      Object.hash(details, state, largeImage, largeText, start, end);
}

String? discordActivityField(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  var runes = trimmed.runes.toList();
  if (runes.length > _maxFieldBytes) {
    runes = runes.sublist(0, _maxFieldBytes);
  }
  while (runes.isNotEmpty &&
      utf8.encode(String.fromCharCodes(runes)).length > _maxFieldBytes) {
    runes.removeLast();
  }

  final clipped = String.fromCharCodes(runes).trimRight();
  if (clipped.isEmpty) return null;
  return clipped.length < _minFieldLength
      ? clipped.padRight(_minFieldLength)
      : clipped;
}
