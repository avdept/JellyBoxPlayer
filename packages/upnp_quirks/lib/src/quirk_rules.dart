import 'package:upnp_quirks/src/device_fingerprint.dart';
import 'package:upnp_quirks/src/device_quirks.dart';

class QuirkRule {
  const QuirkRule({
    required this.name,
    required this.evidence,
    required this.apply,
    this.matchAny = const [],
    this.requireAll = const [],
  });

  final String name;
  final String evidence;
  final List<String> matchAny;
  final List<String> requireAll;
  final DeviceQuirks Function(DeviceQuirks base) apply;

  bool matches(DeviceFingerprint fingerprint) {
    final haystack = fingerprint.searchable;
    if (haystack.isEmpty) return false;
    if (matchAny.isNotEmpty && !matchAny.any(haystack.contains)) return false;
    return requireAll.every(haystack.contains);
  }
}

const quirkRules = <QuirkRule>[];

DeviceQuirks quirksFor(DeviceFingerprint fingerprint) {
  var quirks = DeviceQuirks.defaults;
  for (final rule in quirkRules) {
    if (rule.matches(fingerprint)) quirks = rule.apply(quirks);
  }
  return quirks;
}

List<QuirkRule> rulesFor(DeviceFingerprint fingerprint) => [
  for (final rule in quirkRules)
    if (rule.matches(fingerprint)) rule,
];
