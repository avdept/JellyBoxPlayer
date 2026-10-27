import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

@immutable
class HlsVariant {
  const HlsVariant({
    required this.url,
    this.width,
    this.height,
    this.bandwidth,
  });

  final Uri url;
  final int? width;
  final int? height;

  final int? bandwidth;

  @override
  String toString() => 'HlsVariant($width x $height, $bandwidth bps, $url)';
}

List<HlsVariant> parseHlsVariants(String playlist, {required Uri base}) {
  const marker = '#EXT-X-STREAM-INF:';
  final lines = const LineSplitter().convert(playlist);
  final variants = <HlsVariant>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith(marker)) continue;
    final uri = _uriAfter(lines, i + 1);
    if (uri == null) continue;
    final attributes = _attributes(line.substring(marker.length));
    final resolution = _resolution(attributes['RESOLUTION']);
    variants.add(
      HlsVariant(
        url: base.resolve(uri),
        width: resolution?.$1,
        height: resolution?.$2,
        bandwidth:
            int.tryParse(attributes['AVERAGE-BANDWIDTH'] ?? '') ??
            int.tryParse(attributes['BANDWIDTH'] ?? ''),
      ),
    );
  }
  return variants;
}

HlsVariant? pickHlsVariant(
  List<HlsVariant> variants, {
  required int targetWidth,
}) {
  final sized = variants.where((variant) => (variant.width ?? 0) > 0).toList();
  if (sized.isEmpty) return _cheapest(variants);
  final covering = sized.where((variant) => variant.width! >= targetWidth);
  final candidates = covering.isEmpty ? sized : covering;
  final width = covering.isEmpty
      ? candidates.map((variant) => variant.width!).reduce(max)
      : candidates.map((variant) => variant.width!).reduce(min);
  return _cheapest(candidates.where((variant) => variant.width == width));
}

HlsVariant? _cheapest(Iterable<HlsVariant> variants) {
  HlsVariant? cheapest;
  for (final variant in variants) {
    if (cheapest == null || _rate(variant) < _rate(cheapest)) {
      cheapest = variant;
    }
  }
  return cheapest;
}

int _rate(HlsVariant variant) => variant.bandwidth ?? 1 << 50;

String? _uriAfter(List<String> lines, int from) {
  for (var i = from; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    return line;
  }
  return null;
}

(int, int)? _resolution(String? value) {
  final parts = value?.toLowerCase().split('x');
  if (parts == null || parts.length != 2) return null;
  final width = int.tryParse(parts.first);
  final height = int.tryParse(parts.last);
  if (width == null || height == null) return null;
  return (width, height);
}

Map<String, String> _attributes(String source) {
  final attributes = <String, String>{};
  final buffer = StringBuffer();
  var quoted = false;

  void take() {
    final pair = buffer.toString();
    buffer.clear();
    final separator = pair.indexOf('=');
    if (separator <= 0) return;
    final key = pair.substring(0, separator).trim().toUpperCase();
    final value = pair.substring(separator + 1).trim();
    attributes[key] = value.length >= 2 && value.startsWith('"') &&
            value.endsWith('"')
        ? value.substring(1, value.length - 1)
        : value;
  }

  for (final rune in source.runes) {
    final character = String.fromCharCode(rune);
    if (character == '"') quoted = !quoted;
    if (character == ',' && !quoted) {
      take();
    } else {
      buffer.write(character);
    }
  }
  take();
  return attributes;
}
