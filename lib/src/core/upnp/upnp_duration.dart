String formatUpnpDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

Duration? parseUpnpDuration(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  if (text.toUpperCase().contains('NOT_IMPLEMENTED')) return null;

  final negative = text.startsWith('-');
  final parts = (negative ? text.substring(1) : text).split(':');
  if (parts.isEmpty || parts.length > 3) return null;

  final numbers = <double>[];
  for (final part in parts) {
    final number = double.tryParse(part.trim());
    if (number == null) return null;
    numbers.add(number);
  }

  final padded = [...List<double>.filled(3 - numbers.length, 0), ...numbers];
  final micros =
      (padded[0] * Duration.microsecondsPerHour +
              padded[1] * Duration.microsecondsPerMinute +
              padded[2] * Duration.microsecondsPerSecond)
          .round();
  return Duration(microseconds: negative ? -micros : micros);
}
